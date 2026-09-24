#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TEMPLATE=/usr/local/share/raspi-maintenance/53unattended-upgrades-auto-reboot
TARGET=/etc/apt/apt.conf.d/53unattended-upgrades-auto-reboot
BACKUP_ROOT=/var/backups/raspi-auto-reboot

usage() {
    cat >&2 <<'EOF'
Usage:
  sudo raspi-configure-auto-reboot --check
  sudo raspi-configure-auto-reboot --enable
  sudo raspi-configure-auto-reboot --disable
  sudo raspi-configure-auto-reboot --rollback /var/backups/raspi-auto-reboot/YYYYMMDD-HHMMSS

--check is the default and does not change the system.
EOF
    exit 2
}

mode=check
rollback_dir=""
case $# in
    0) ;;
    1) [[ $1 == --check || $1 == --enable || $1 == --disable ]] || usage; mode=${1#--} ;;
    2) [[ $1 == --rollback ]] || usage; mode=rollback; rollback_dir=$2 ;;
    *) usage ;;
esac

[[ $EUID -eq 0 ]] || { echo "Run this command with sudo" >&2; exit 1; }

apt_value() {
    local key=$1 dump=$2
    sed -n "s/^${key//:/\\:} \"\(.*\)\";$/\1/p" <<<"$dump" | tail -n 1
}

validate_safe_enabled_policy() {
    local dump reboot with_users reboot_time
    dump=$(apt-config dump)
    reboot=$(apt_value 'Unattended-Upgrade::Automatic-Reboot' "$dump")
    with_users=$(apt_value 'Unattended-Upgrade::Automatic-Reboot-WithUsers' "$dump")
    reboot_time=$(apt_value 'Unattended-Upgrade::Automatic-Reboot-Time' "$dump")
    [[ $reboot == true && $with_users == false && $reboot_time == 04:45 ]] || {
        echo "Effective automatic-reboot policy is not the approved safe profile" >&2
        return 1
    }
}

validate_disabled_policy() {
    local dump reboot
    dump=$(apt-config dump)
    reboot=$(apt_value 'Unattended-Upgrade::Automatic-Reboot' "$dump")
    [[ $reboot == false ]] || {
        echo "Automatic reboot remains enabled by another APT configuration file" >&2
        return 1
    }
}

show_status() {
    local dump reboot with_users reboot_time
    dump=$(apt-config dump)
    reboot=$(apt_value 'Unattended-Upgrade::Automatic-Reboot' "$dump")
    with_users=$(apt_value 'Unattended-Upgrade::Automatic-Reboot-WithUsers' "$dump")
    reboot_time=$(apt_value 'Unattended-Upgrade::Automatic-Reboot-Time' "$dump")
    printf 'Managed file: %s\n' "$([[ -e $TARGET ]] && echo present || echo absent)"
    printf 'Automatic-Reboot: %s\n' "${reboot:-not set}"
    printf 'Automatic-Reboot-WithUsers: %s\n' "${with_users:-not set}"
    printf 'Automatic-Reboot-Time: %s\n' "${reboot_time:-not set}"
    printf 'Reboot-required flag: %s\n' "$([[ -e /run/reboot-required ]] && echo present || echo absent)"
    echo "Logged-in sessions:"
    who || true
    echo "Relevant timers:"
    systemctl list-timers apt-daily.timer apt-daily-upgrade.timer --no-pager

    if [[ $reboot == false ]]; then
        echo "Result: automatic reboot is disabled"
    elif [[ $reboot == true && $with_users == false && $reboot_time == 04:45 ]]; then
        echo "Result: conditional automatic reboot is enabled for 04:45"
    else
        echo "Result: automatic reboot has an unexpected or unsafe effective configuration" >&2
        return 1
    fi
}

create_backup() {
    local stamp backup_dir
    stamp=$(date +%Y%m%d-%H%M%S)
    backup_dir=$BACKUP_ROOT/$stamp
    [[ ! -e $backup_dir ]] || backup_dir=$BACKUP_ROOT/$stamp-$$
    install -d -o root -g root -m 700 "$backup_dir"
    if [[ -e $TARGET ]]; then
        cp -a -- "$TARGET" "$backup_dir/53unattended-upgrades-auto-reboot"
        : >"$backup_dir/was-present"
    else
        : >"$backup_dir/was-absent"
    fi
    printf '%s' "$backup_dir"
}

restore_backup() {
    local requested=$1 root backup
    root=$(readlink -f -- "$BACKUP_ROOT")
    backup=$(readlink -f -- "$requested") || {
        echo "Cannot resolve backup: $requested" >&2
        return 1
    }
    case "$backup" in
        "$root"/*) ;;
        *) echo "Refusing backup outside $root" >&2; return 1 ;;
    esac
    if [[ -f $backup/was-present && -f $backup/53unattended-upgrades-auto-reboot ]]; then
        install -o root -g root -m 644 \
            "$backup/53unattended-upgrades-auto-reboot" "$TARGET"
    elif [[ -f $backup/was-absent ]]; then
        rm -f -- "$TARGET"
    else
        echo "Backup manifest is incomplete" >&2
        return 1
    fi
}

if [[ $mode == check ]]; then
    show_status
    exit 0
fi

if [[ $mode == rollback ]]; then
    restore_backup "$rollback_dir"
    echo "Restored automatic-reboot configuration from $rollback_dir"
    show_status
    exit 0
fi

if [[ $mode == enable ]]; then
    [[ -f $TEMPLATE ]] || { echo "Missing installed template: $TEMPLATE" >&2; exit 1; }
fi
backup_dir=$(create_backup)
rollback_needed=1
rollback_on_error() {
    local status=$?
    trap - ERR
    if (( rollback_needed == 1 )); then
        echo "Change failed; restoring $backup_dir" >&2
        restore_backup "$backup_dir" || true
    fi
    exit "$status"
}
trap rollback_on_error ERR

if [[ $mode == enable ]]; then
    install -o root -g root -m 644 "$TEMPLATE" "$TARGET"
    validate_safe_enabled_policy
    echo "Conditional automatic reboot enabled for 04:45. Backup: $backup_dir"
    if [[ -e /run/reboot-required ]]; then
        echo "WARNING: a reboot-required flag already exists; a future unattended-upgrade run may schedule the reboot."
    fi
else
    rm -f -- "$TARGET"
    validate_disabled_policy
    echo "Automatic reboot disabled. Backup: $backup_dir"
fi

rollback_needed=0
trap - ERR
show_status
