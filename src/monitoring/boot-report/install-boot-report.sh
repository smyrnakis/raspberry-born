#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LOCAL_CONFIG=$SOURCE_DIR/boot-report.conf
EXAMPLE_CONFIG=$SOURCE_DIR/boot-report.conf.example
BACKUP_ROOT=/var/backups/raspi-boot-report

TARGETS=(
    /usr/local/sbin/raspi-boot-report
    /etc/raspi-boot-report/boot-report.conf
    /etc/systemd/system/raspi-boot-report.service
)

usage() {
    cat >&2 <<'EOF'
Usage:
  ./install-boot-report.sh --check
  sudo ./install-boot-report.sh --apply
  sudo ./install-boot-report.sh --rollback /var/backups/raspi-boot-report/YYYYMMDD-HHMMSS

--check is the default and does not change the system.
EOF
    exit 2
}

mode=check
rollback_dir=""
case $# in
    0) ;;
    1) [[ $1 == --check || $1 == --apply ]] || usage; mode=${1#--} ;;
    2) [[ $1 == --rollback ]] || usage; mode=rollback; rollback_dir=$2 ;;
    *) usage ;;
esac

require_root() {
    [[ $EUID -eq 0 ]] || { echo "Run this mode with sudo" >&2; exit 1; }
}

selected_config() {
    if [[ -f $LOCAL_CONFIG ]]; then
        printf '%s' "$LOCAL_CONFIG"
    else
        printf '%s' "$EXAMPLE_CONFIG"
    fi
}

validate_config() {
    local config=$1 key value public_lookup="" public_url="" wait_seconds=""
    local services="" peers="" service pair label target
    [[ -r $config ]] || { echo "Cannot read $config" >&2; return 1; }
    while IFS='=' read -r key value || [[ -n ${key:-}${value:-} ]]; do
        key=${key%$'\r'}
        value=${value%$'\r'}
        [[ -z $key || $key == \#* ]] && continue
        case "$key" in
            PUBLIC_IP_LOOKUP) public_lookup=$value ;;
            PUBLIC_IP_URL) public_url=$value ;;
            NETWORK_WAIT_SECONDS) wait_seconds=$value ;;
            CHECK_SERVICES) services=$value ;;
            CHECK_PEERS) peers=$value ;;
            *) echo "Unknown setting in $config: $key" >&2; return 1 ;;
        esac
    done <"$config"

    [[ $public_lookup == true || $public_lookup == false ]] || {
        echo "PUBLIC_IP_LOOKUP must be true or false" >&2; return 1;
    }
    [[ $wait_seconds =~ ^[0-9]+$ ]] && (( wait_seconds <= 300 )) || {
        echo "NETWORK_WAIT_SECONDS must be an integer from 0 to 300" >&2; return 1;
    }
    if [[ $public_lookup == true ]]; then
        [[ $public_url =~ ^https://[^[:space:]]+$ ]] || {
            echo "PUBLIC_IP_URL must be an HTTPS URL without spaces" >&2; return 1;
        }
    fi
    for service in $services; do
        [[ $service =~ ^[A-Za-z0-9_.@-]+$ ]] || {
            echo "Invalid systemd unit name: $service" >&2; return 1;
        }
    done
    for pair in $peers; do
        [[ $pair == *=* ]] || { echo "Invalid peer check: $pair" >&2; return 1; }
        label=${pair%%=*}
        target=${pair#*=}
        [[ $label =~ ^[A-Za-z0-9_.-]+$ && $target =~ ^[A-Za-z0-9_.:-]+$ ]] || {
            echo "Invalid peer check: $pair" >&2; return 1;
        }
    done
}

validate_sources() {
    local command file config
    for command in awk bash curl cut date df free getent grep head hostname install ip logger paste ping readlink sed sleep sort systemctl systemd-analyze timedatectl uname uptime; do
        command -v "$command" >/dev/null 2>&1 || {
            echo "Required command is missing: $command" >&2
            return 1
        }
    done
    for file in raspi-boot-report raspi-boot-report.service boot-report.conf.example; do
        [[ -f $SOURCE_DIR/$file ]] || { echo "Required source file is missing: $file" >&2; return 1; }
    done
    [[ -x /usr/local/sbin/raspi-notify ]] || {
        echo "Install src/notify first; /usr/local/sbin/raspi-notify is missing" >&2
        return 1
    }
    bash -n "$SOURCE_DIR/raspi-boot-report"
    bash -n "$SOURCE_DIR/install-boot-report.sh"
    config=$(selected_config)
    validate_config "$config"
    echo "Configuration selected: $config"
}

show_plan() {
    cat <<EOF
Validation passed. No files were changed.

The apply mode will:
  1. Back up existing managed files under $BACKUP_ROOT/.
  2. Install the boot-report command, selected configuration and systemd unit.
  3. Reload systemd metadata and verify the installed unit.

It will not enable or start the service, send a notification, restart a
service or reboot. Public-IP lookup occurs only when the report command runs.
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
    backup=$(readlink -f -- "$requested") || {
        echo "Cannot resolve backup: $requested" >&2; return 1;
    }
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
    require_root
    restore_backup "$rollback_dir"
    echo "Restored managed files from $rollback_dir"
    echo "Service state and queued notifications were unchanged."
    exit 0
fi

validate_sources
[[ $mode == apply ]] || { show_plan; exit 0; }
require_root

config=$(selected_config)
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

install -d -o root -g root -m 755 /etc/raspi-boot-report
install -o root -g root -m 600 "$config" /etc/raspi-boot-report/boot-report.conf
install -o root -g root -m 755 "$SOURCE_DIR/raspi-boot-report" /usr/local/sbin/raspi-boot-report
install -o root -g root -m 644 "$SOURCE_DIR/raspi-boot-report.service" /etc/systemd/system/raspi-boot-report.service
systemctl daemon-reload
systemd-analyze verify /etc/systemd/system/raspi-boot-report.service

rollback_needed=0
trap - ERR
echo "Boot report installed. Previous managed files: $backup_dir"
echo "The service was not enabled or started. Continue with the documented tests."
