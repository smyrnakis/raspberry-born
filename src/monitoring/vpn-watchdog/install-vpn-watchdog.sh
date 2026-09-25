#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LOCAL_CONFIG=$SOURCE_DIR/vpn-watchdog.conf
BACKUP_ROOT=/var/backups/raspi-vpn-watchdog

TARGETS=(
    /usr/local/sbin/raspi-vpn-watchdog
    /etc/raspi-vpn-watchdog/vpn-watchdog.conf
    /etc/systemd/system/raspi-vpn-watchdog.service
    /etc/systemd/system/raspi-vpn-watchdog.timer
)

usage() {
    cat >&2 <<'EOF'
Usage:
  sudo ./install-vpn-watchdog.sh --check
  sudo ./install-vpn-watchdog.sh --apply
  sudo ./install-vpn-watchdog.sh --rollback /var/backups/raspi-vpn-watchdog/YYYYMMDD-HHMMSS

Create the ignored vpn-watchdog.conf beside this installer first.
--check is the default and does not change the system.
EOF
    exit 2
}

mode=check
rollback_dir=
case $# in
    0) ;;
    1) [[ $1 == --check || $1 == --apply ]] || usage; mode=${1#--} ;;
    2) [[ $1 == --rollback ]] || usage; mode=rollback; rollback_dir=$2 ;;
    *) usage ;;
esac

[[ $EUID -eq 0 ]] || { echo "Run this installer with sudo" >&2; exit 1; }

validate_sources() {
    local command file
    for command in awk bash cat cp curl date find flock grep hostname install ip logger \
        ping readlink rm sleep ss sync systemctl systemd-analyze timeout who; do
        command -v "$command" >/dev/null 2>&1 || {
            echo "Required command is missing: $command" >&2
            return 1
        }
    done
    for file in raspi-vpn-watchdog raspi-vpn-watchdog.service raspi-vpn-watchdog.timer; do
        [[ -f $SOURCE_DIR/$file ]] || { echo "Required source file is missing: $file" >&2; return 1; }
    done
    [[ -f $LOCAL_CONFIG ]] || {
        echo "Create $LOCAL_CONFIG from one of the role examples and review every value" >&2
        return 1
    }
    [[ -x /usr/local/sbin/raspi-notify ]] || {
        echo "Install src/notify first; /usr/local/sbin/raspi-notify is missing" >&2
        return 1
    }
    bash -n "$SOURCE_DIR/raspi-vpn-watchdog"
    bash -n "$SOURCE_DIR/install-vpn-watchdog.sh"
    RASPI_VPN_WATCHDOG_CONFIG=$LOCAL_CONFIG "$SOURCE_DIR/raspi-vpn-watchdog" --validate-config
}

show_plan() {
    cat <<EOF
Validation passed. No files were changed.

The apply mode will:
  1. Back up existing managed files under $BACKUP_ROOT/.
  2. Install the watchdog command, reviewed local configuration and systemd units.
  3. Create the persistent reboot-rate-limit state directory.
  4. Reload systemd metadata and verify the installed units.

It will not enable or start the timer, run a health check, restart OpenVPN,
send a notification or reboot.
EOF
}

create_backup() {
    local stamp target backup_dir
    stamp=$(date +%Y%m%d-%H%M%S)
    backup_dir=$BACKUP_ROOT/$stamp
    [[ ! -e $backup_dir ]] || backup_dir=$BACKUP_ROOT/$stamp-$$
    install -d -o root -g root -m 700 "$backup_dir"
    : >"$backup_dir/existing-files"
    : >"$backup_dir/absent-files"
    for target in "${TARGETS[@]}"; do
        if [[ -e $target ]]; then
            printf '%s\n' "$target" >>"$backup_dir/existing-files"
            cp -a --parents "$target" "$backup_dir"
        else
            printf '%s\n' "$target" >>"$backup_dir/absent-files"
        fi
    done
    printf '%s' "$backup_dir"
}

is_managed_target() {
    local candidate=$1 target
    for target in "${TARGETS[@]}"; do
        [[ $candidate == "$target" ]] && return 0
    done
    return 1
}

restore_backup() {
    local requested=$1 root backup target
    root=$(readlink -f -- "$BACKUP_ROOT")
    backup=$(readlink -f -- "$requested") || { echo "Cannot resolve backup: $requested" >&2; return 1; }
    case "$backup" in "$root"/*) ;; *) echo "Refusing backup outside $root" >&2; return 1 ;; esac
    [[ -f $backup/existing-files && -f $backup/absent-files ]] || {
        echo "Backup manifest is missing" >&2; return 1;
    }
    while IFS= read -r target; do
        [[ -z $target ]] && continue
        is_managed_target "$target" || return 1
        rm -f -- "$target"
    done <"$backup/absent-files"
    while IFS= read -r target; do
        [[ -z $target ]] && continue
        is_managed_target "$target" || return 1
        [[ -e $backup$target ]] || { echo "Backup is missing $target" >&2; return 1; }
        install -d -o root -g root -m 755 "$(dirname -- "$target")"
        cp -a -- "$backup$target" "$target"
    done <"$backup/existing-files"
    systemctl daemon-reload
}

if [[ $mode == rollback ]]; then
    restore_backup "$rollback_dir"
    echo "Restored managed files from $rollback_dir"
    echo "Timer state, OpenVPN state, runtime state and queued notifications were unchanged."
    exit 0
fi

validate_sources
[[ $mode == apply ]] || { show_plan; exit 0; }

backup_dir=$(create_backup)
rollback_needed=1
rollback_on_error() {
    local status=$?
    trap - ERR
    if (( rollback_needed == 1 )); then
        echo "Installation failed; restoring $backup_dir" >&2
        restore_backup "$backup_dir" || true
    fi
    exit "$status"
}
trap rollback_on_error ERR

install -d -o root -g root -m 755 /etc/raspi-vpn-watchdog
install -d -o root -g root -m 700 /var/lib/raspi-vpn-watchdog
install -o root -g root -m 600 "$LOCAL_CONFIG" /etc/raspi-vpn-watchdog/vpn-watchdog.conf
install -o root -g root -m 755 "$SOURCE_DIR/raspi-vpn-watchdog" /usr/local/sbin/raspi-vpn-watchdog
install -o root -g root -m 644 "$SOURCE_DIR/raspi-vpn-watchdog.service" /etc/systemd/system/raspi-vpn-watchdog.service
install -o root -g root -m 644 "$SOURCE_DIR/raspi-vpn-watchdog.timer" /etc/systemd/system/raspi-vpn-watchdog.timer
systemctl daemon-reload
systemd-analyze verify /etc/systemd/system/raspi-vpn-watchdog.service \
    /etc/systemd/system/raspi-vpn-watchdog.timer

rollback_needed=0
trap - ERR
echo "VPN watchdog files installed. Previous managed files: $backup_dir"
echo "The timer was not enabled or started. OpenVPN was not restarted."
