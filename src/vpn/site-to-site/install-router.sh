#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH=${BASH_SOURCE[0]}
[[ $SCRIPT_PATH == */* ]] || SCRIPT_PATH="./$SCRIPT_PATH"
SCRIPT_DIR=$(cd -- "${SCRIPT_PATH%/*}" && pwd)
DEFAULT_CONFIG="$SCRIPT_DIR/site.conf"
TEMPLATE_FILE="$SCRIPT_DIR/vpn-site-router.nft.template"
SYSCTL_SOURCE="$SCRIPT_DIR/90-vpn-site-router.conf"

MAIN_CONFIG=/etc/nftables.conf
INCLUDE_DIR=/etc/nftables.d
INCLUDE_LINE='include "/etc/nftables.d/*.nft"'
RULE_FILE="$INCLUDE_DIR/vpn-site-router.nft"
SYSCTL_FILE=/etc/sysctl.d/90-vpn-site-router.conf

VPN_INTERFACE=
LAN_INTERFACE=
VPN_SUBNET=
LAN_SUBNET=
TEMP_DIR=
BACKUP_DIR=

usage() {
    cat <<'EOF'
Usage:
  sudo ./install-router.sh --check [site.conf]
  sudo ./install-router.sh --apply [site.conf]
  sudo ./install-router.sh --rollback /var/backups/vpn-site-router-TIMESTAMP

Without arguments, --check with ./site.conf is used. --check makes no
persistent or runtime change. --apply changes sysctl and nftables state.
EOF
}

die() {
    echo "Error: $*" >&2
    exit 1
}

cleanup() {
    if [[ -n ${TEMP_DIR:-} && -d $TEMP_DIR ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}
trap cleanup EXIT

require_root() {
    [[ $EUID -eq 0 ]] || die "Run with sudo."
}

require_commands() {
    local command_name
    for command_name in nft systemctl sysctl ip install grep sed mktemp \
        realpath stat date; do
        command -v "$command_name" >/dev/null 2>&1 \
            || die "Required command is missing: $command_name"
    done
}

read_config() {
    local config_file=$1
    local line key value

    [[ -f $config_file ]] || die "Configuration not found: $config_file"

    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ -z ${line//[[:space:]]/} ]] && continue
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ $line =~ ^([A-Z_]+)=([^[:space:]]+)$ ]] \
            || die "Invalid configuration line: $line"

        key=${BASH_REMATCH[1]}
        value=${BASH_REMATCH[2]}

        case "$key" in
            VPN_INTERFACE) VPN_INTERFACE=$value ;;
            LAN_INTERFACE) LAN_INTERFACE=$value ;;
            VPN_SUBNET) VPN_SUBNET=$value ;;
            LAN_SUBNET) LAN_SUBNET=$value ;;
            *) die "Unknown configuration key: $key" ;;
        esac
    done <"$config_file"

    [[ -n $VPN_INTERFACE ]] || die "VPN_INTERFACE is required."
    [[ -n $LAN_INTERFACE ]] || die "LAN_INTERFACE is required."
    [[ -n $VPN_SUBNET ]] || die "VPN_SUBNET is required."
    [[ -n $LAN_SUBNET ]] || die "LAN_SUBNET is required."
}

validate_config() {
    local interface_name subnet

    [[ $VPN_INTERFACE != "$LAN_INTERFACE" ]] \
        || die "VPN_INTERFACE and LAN_INTERFACE must differ."
    [[ $VPN_SUBNET != "$LAN_SUBNET" ]] \
        || die "VPN_SUBNET and LAN_SUBNET must differ."

    for interface_name in "$VPN_INTERFACE" "$LAN_INTERFACE"; do
        [[ $interface_name =~ ^[A-Za-z0-9_.:-]+$ ]] \
            || die "Invalid interface name: $interface_name"
        [[ ${#interface_name} -le 15 ]] \
            || die "Interface name is longer than Linux permits: $interface_name"
        ip link show dev "$interface_name" >/dev/null 2>&1 \
            || die "Interface does not exist: $interface_name"
    done

    for subnet in "$VPN_SUBNET" "$LAN_SUBNET"; do
        [[ $subnet =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]] \
            || die "Expected an IPv4 CIDR subnet, got: $subnet"
    done
}

render_rules() {
    local output_file=$1

    sed \
        -e "s|@VPN_INTERFACE@|$VPN_INTERFACE|g" \
        -e "s|@LAN_INTERFACE@|$LAN_INTERFACE|g" \
        -e "s|@VPN_SUBNET@|$VPN_SUBNET|g" \
        -e "s|@LAN_SUBNET@|$LAN_SUBNET|g" \
        "$TEMPLATE_FILE" >"$output_file"

    nft -c -f "$output_file"
}

show_plan() {
    local rendered_file=$1

    echo "Proposed site-to-site router configuration"
    echo "  VPN interface: $VPN_INTERFACE"
    echo "  LAN interface: $LAN_INTERFACE"
    echo "  VPN subnet: $VPN_SUBNET"
    echo "  LAN subnet: $LAN_SUBNET"
    echo
    echo "Current IPv4 forwarding: $(sysctl -n net.ipv4.ip_forward)"
    echo "nftables enabled: $(systemctl is-enabled nftables 2>/dev/null || true)"
    echo "nftables active: $(systemctl is-active nftables 2>/dev/null || true)"
    echo
    echo "Rendered nftables rules:"
    cat "$rendered_file"
    echo
    echo "Current live nftables ruleset:"
    nft list ruleset
}

write_state() {
    local old_forward=$1 old_enabled=$2 old_active=$3
    local had_rule=$4 had_sysctl=$5

    cat >"$BACKUP_DIR/state" <<EOF
OLD_FORWARD=$old_forward
OLD_ENABLED=$old_enabled
OLD_ACTIVE=$old_active
HAD_RULE=$had_rule
HAD_SYSCTL=$had_sysctl
EOF
    chmod 600 "$BACKUP_DIR/state"
}

restore_backup() {
    local backup_dir=$1
    local OLD_FORWARD OLD_ENABLED OLD_ACTIVE HAD_RULE HAD_SYSCTL

    backup_dir=$(realpath -e -- "$backup_dir") \
        || die "Cannot resolve backup directory: $backup_dir"
    [[ -d $backup_dir ]] || die "Backup directory not found: $backup_dir"
    [[ $backup_dir == /var/backups/vpn-site-router-* ]] \
        || die "Unexpected backup directory name: $backup_dir"
    [[ -f $backup_dir/state && -f $backup_dir/nftables.conf ]] \
        || die "Incomplete backup directory: $backup_dir"
    [[ $(stat -c %u "$backup_dir") == 0 && \
       $(stat -c %u "$backup_dir/state") == 0 ]] \
        || die "Backup directory and state file must be owned by root."

    # The state file is generated by this root-owned installer and contains
    # only simple values captured from sysctl and systemctl.
    # shellcheck disable=SC1090
    source "$backup_dir/state"

    cp -a -- "$backup_dir/nftables.conf" "$MAIN_CONFIG"

    if [[ $HAD_RULE == 1 ]]; then
        cp -a -- "$backup_dir/vpn-site-router.nft" "$RULE_FILE"
    else
        rm -f -- "$RULE_FILE"
    fi

    if [[ $HAD_SYSCTL == 1 ]]; then
        cp -a -- "$backup_dir/90-vpn-site-router.conf" "$SYSCTL_FILE"
    else
        rm -f -- "$SYSCTL_FILE"
    fi

    nft -c -f "$MAIN_CONFIG"
    nft delete table inet vpn_site_forward >/dev/null 2>&1 || true
    nft delete table ip vpn_site_nat >/dev/null 2>&1 || true
    nft -f "$MAIN_CONFIG"
    sysctl -q -w "net.ipv4.ip_forward=$OLD_FORWARD"

    if [[ $OLD_ENABLED == enabled ]]; then
        systemctl enable nftables >/dev/null
    else
        systemctl disable nftables >/dev/null 2>&1 || true
    fi

    if [[ $OLD_ACTIVE == active ]]; then
        systemctl restart nftables
    else
        systemctl stop nftables >/dev/null 2>&1 || true
    fi

    echo "Restored site-to-site routing state from: $backup_dir"
}

rollback_on_error() {
    local exit_code=$?
    trap - ERR
    echo "Installation failed; restoring the previous state." >&2
    restore_backup "$BACKUP_DIR" || true
    exit "$exit_code"
}

apply_configuration() {
    local rendered_file=$1
    local timestamp old_forward old_enabled old_active
    local had_rule=0 had_sysctl=0

    timestamp=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR=$(mktemp -d "/var/backups/vpn-site-router-$timestamp-XXXXXX")
    chmod 700 "$BACKUP_DIR"

    old_forward=$(sysctl -n net.ipv4.ip_forward)
    old_enabled=$(systemctl is-enabled nftables 2>/dev/null || true)
    old_active=$(systemctl is-active nftables 2>/dev/null || true)

    cp -a "$MAIN_CONFIG" "$BACKUP_DIR/nftables.conf"

    if [[ -e $RULE_FILE ]]; then
        had_rule=1
        cp -a "$RULE_FILE" "$BACKUP_DIR/vpn-site-router.nft"
    fi
    if [[ -e $SYSCTL_FILE ]]; then
        had_sysctl=1
        cp -a "$SYSCTL_FILE" "$BACKUP_DIR/90-vpn-site-router.conf"
    fi

    write_state "$old_forward" "$old_enabled" "$old_active" \
        "$had_rule" "$had_sysctl"
    trap rollback_on_error ERR

    install -d -o root -g root -m 755 "$INCLUDE_DIR"
    install -o root -g root -m 600 "$rendered_file" "$RULE_FILE"
    install -o root -g root -m 644 "$SYSCTL_SOURCE" "$SYSCTL_FILE"

    if ! grep -Fqx "$INCLUDE_LINE" "$MAIN_CONFIG"; then
        printf '\n%s\n' "$INCLUDE_LINE" >>"$MAIN_CONFIG"
    fi

    nft -c -f "$MAIN_CONFIG"
    sysctl -q -p "$SYSCTL_FILE"
    systemctl enable nftables >/dev/null
    systemctl restart nftables

    if [[ $(sysctl -n net.ipv4.ip_forward) != 1 ]]; then
        echo "IPv4 forwarding did not become active." >&2
        false
    fi
    nft list table inet vpn_site_forward >/dev/null
    nft list table ip vpn_site_nat >/dev/null

    trap - ERR
    echo "Site-to-site routing is active."
    echo "Rollback backup: $BACKUP_DIR"
}

main() {
    local mode=${1:---check}
    local argument=${2:-$DEFAULT_CONFIG}
    local rendered_file

    if [[ $mode == --help || $mode == -h ]]; then
        usage
        exit 0
    fi

    require_root
    require_commands

    case "$mode" in
        --check|--apply)
            [[ -f $MAIN_CONFIG ]] \
                || die "Missing nftables configuration: $MAIN_CONFIG"
            [[ -f $TEMPLATE_FILE ]] \
                || die "Missing rules template: $TEMPLATE_FILE"
            [[ -f $SYSCTL_SOURCE ]] \
                || die "Missing sysctl file: $SYSCTL_SOURCE"

            read_config "$argument"
            validate_config
            TEMP_DIR=$(mktemp -d)
            rendered_file="$TEMP_DIR/vpn-site-router.nft"
            render_rules "$rendered_file"
            show_plan "$rendered_file"

            if [[ $mode == --check ]]; then
                echo
                echo "Check completed. No configuration was changed."
            else
                apply_configuration "$rendered_file"
            fi
            ;;
        --rollback)
            [[ $# -eq 2 ]] || die "--rollback requires a backup directory."
            restore_backup "$argument"
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
}

main "$@"
