#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LOCAL_CONFIG=$SOURCE_DIR/notify.conf
BACKUP_ROOT=/var/backups/raspi-notify

TARGETS=(
    /usr/local/sbin/raspi-notify
    /usr/local/sbin/raspi-notify-dispatcher
    /etc/raspi-notify/notify.conf
    /etc/systemd/system/raspi-notify-dispatcher.service
    /etc/systemd/system/raspi-notify-dispatcher.timer
)

usage() {
    cat >&2 <<'EOF'
Usage:
  ./install-notify.sh --check
  sudo ./install-notify.sh --apply
  sudo ./install-notify.sh --rollback /var/backups/raspi-notify/YYYYMMDD-HHMMSS

--check is the default and does not change the system.
EOF
    exit 2
}

mode=check
rollback_dir=""
case $# in
    0) ;;
    1)
        [[ $1 == --check || $1 == --apply ]] || usage
        mode=${1#--}
        ;;
    2)
        [[ $1 == --rollback ]] || usage
        mode=rollback
        rollback_dir=$2
        ;;
    *) usage ;;
esac

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Run this mode with sudo" >&2
        exit 1
    fi
}

validate_config() {
    local config=$1
    local key value
    local mail_from="" mail_to="" mail_from_name="" msmtp_account=""

    [[ -r "$config" ]] || {
        echo "Cannot read $config" >&2
        return 1
    }

    while IFS='=' read -r key value || [[ -n "${key:-}${value:-}" ]]; do
        key=${key%$'\r'}
        value=${value%$'\r'}
        [[ -z "$key" || "$key" == \#* ]] && continue
        case "$key" in
            MAIL_FROM) mail_from=$value ;;
            MAIL_TO) mail_to=$value ;;
            MAIL_FROM_NAME) mail_from_name=$value ;;
            MSMTP_ACCOUNT) msmtp_account=$value ;;
            *) echo "Unknown setting in $config: $key" >&2; return 1 ;;
        esac
    done <"$config"

    if [[ -z "$mail_from" || -z "$mail_to" || -z "$mail_from_name" || -z "$msmtp_account" ]]; then
        echo "All notification settings must be present in $config" >&2
        return 1
    fi
    if [[ "$mail_from" == *example.invalid || "$mail_to" == *example.invalid ]]; then
        echo "Replace the example addresses in $config" >&2
        return 1
    fi
    if [[ "$mail_from" == *[[:space:]]* || "$mail_from" != *@* ||
          "$mail_to" == *[[:space:]]* || "$mail_to" != *@* ||
          ! "$msmtp_account" =~ ^[A-Za-z0-9_.-]+$ ]]; then
        echo "Invalid address or account setting in $config" >&2
        return 1
    fi
}

validate_sources() {
    local command file
    for command in bash date flock hostname install logger mktemp msmtp readlink systemctl systemd-analyze timeout; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Required command is missing: $command" >&2
            return 1
        fi
    done
    for file in \
        raspi-notify \
        raspi-notify-dispatcher \
        raspi-notify-dispatcher.service \
        raspi-notify-dispatcher.timer; do
        [[ -f "$SOURCE_DIR/$file" ]] || {
            echo "Required source file is missing: $file" >&2
            return 1
        }
    done
    bash -n "$SOURCE_DIR/raspi-notify"
    bash -n "$SOURCE_DIR/raspi-notify-dispatcher"
    bash -n "$SOURCE_DIR/install-notify.sh"
    validate_config "$LOCAL_CONFIG"
    [[ -r /etc/msmtprc ]] || {
        echo "Cannot read /etc/msmtprc" >&2
        return 1
    }
}

show_plan() {
    cat <<EOF
Validation passed. No files were changed.

The apply mode will:
  1. Back up existing managed files under $BACKUP_ROOT/.
  2. Install the two commands, local notification configuration and systemd units.
  3. Create the root-only persistent queue under /var/spool/raspi-notify/.
  4. Reload systemd metadata and verify the installed units.

It will not enable or restart the retry timer and will not alter /etc/msmtprc.
EOF
}

create_backup() {
    local stamp target backup_dir
    stamp=$(date +%Y%m%d-%H%M%S)
    backup_dir=$BACKUP_ROOT/$stamp
    if [[ -e "$backup_dir" ]]; then
        backup_dir=$BACKUP_ROOT/$stamp-$$
    fi
    install -d -o root -g root -m 700 "$backup_dir"
    : >"$backup_dir/existing-files"
    : >"$backup_dir/absent-files"

    for target in "${TARGETS[@]}"; do
        if [[ -e "$target" ]]; then
            printf '%s\n' "$target" >>"$backup_dir/existing-files"
            cp -a --parents "$target" "$backup_dir"
        else
            printf '%s\n' "$target" >>"$backup_dir/absent-files"
        fi
    done
    printf '%s' "$backup_dir"
}

is_managed_target() {
    local candidate=$1 managed
    for managed in "${TARGETS[@]}"; do
        [[ "$candidate" == "$managed" ]] && return 0
    done
    return 1
}

restore_backup() {
    local requested_dir=$1 backup_dir backup_root target
    backup_root=$(readlink -f -- "$BACKUP_ROOT") || {
        echo "Cannot resolve $BACKUP_ROOT" >&2
        return 1
    }
    backup_dir=$(readlink -f -- "$requested_dir") || {
        echo "Cannot resolve backup directory: $requested_dir" >&2
        return 1
    }
    case "$backup_dir" in
        "$backup_root"/*) ;;
        *) echo "Refusing backup path outside $backup_root" >&2; return 1 ;;
    esac
    [[ -f "$backup_dir/existing-files" && -f "$backup_dir/absent-files" ]] || {
        echo "Backup manifest is missing from $backup_dir" >&2
        return 1
    }

    while IFS= read -r target; do
        [[ -z "$target" ]] && continue
        is_managed_target "$target" || {
            echo "Backup manifest contains an unmanaged path: $target" >&2
            return 1
        }
        rm -f -- "$target"
    done <"$backup_dir/absent-files"

    while IFS= read -r target; do
        [[ -z "$target" ]] && continue
        is_managed_target "$target" || {
            echo "Backup manifest contains an unmanaged path: $target" >&2
            return 1
        }
        [[ -e "$backup_dir$target" ]] || {
            echo "Backup is missing $target" >&2
            return 1
        }
        install -d -o root -g root -m 755 "$(dirname -- "$target")"
        cp -a -- "$backup_dir$target" "$target"
    done <"$backup_dir/existing-files"

    systemctl daemon-reload
}

if [[ $mode == rollback ]]; then
    require_root
    restore_backup "$rollback_dir"
    echo "Restored managed files from $rollback_dir"
    echo "Queued messages and SMTP configuration were left unchanged."
    exit 0
fi

validate_sources

if [[ $mode == check ]]; then
    show_plan
    exit 0
fi

require_root
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

install -d -o root -g root -m 755 /etc/raspi-notify
install -d -o root -g root -m 700 /var/spool/raspi-notify
install -d -o root -g root -m 700 /var/spool/raspi-notify/queue
install -d -o root -g root -m 700 /var/spool/raspi-notify/tmp
install -d -o root -g root -m 700 /var/spool/raspi-notify/bad

install -o root -g root -m 600 "$LOCAL_CONFIG" /etc/raspi-notify/notify.conf
install -o root -g root -m 755 "$SOURCE_DIR/raspi-notify" /usr/local/sbin/raspi-notify
install -o root -g root -m 755 "$SOURCE_DIR/raspi-notify-dispatcher" /usr/local/sbin/raspi-notify-dispatcher
install -o root -g root -m 644 "$SOURCE_DIR/raspi-notify-dispatcher.service" /etc/systemd/system/raspi-notify-dispatcher.service
install -o root -g root -m 644 "$SOURCE_DIR/raspi-notify-dispatcher.timer" /etc/systemd/system/raspi-notify-dispatcher.timer

systemctl daemon-reload
systemd-analyze verify \
    /etc/systemd/system/raspi-notify-dispatcher.service \
    /etc/systemd/system/raspi-notify-dispatcher.timer

rollback_needed=0
trap - ERR

echo "Durable notification queue installed."
echo "Previous managed files: $backup_dir"
echo "The retry timer was not enabled or restarted. Follow the documented tests first."
