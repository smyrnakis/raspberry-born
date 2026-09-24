#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BACKUP_ROOT=/var/backups/raspi-update-policy

TARGETS=(
    /etc/apt/apt.conf.d/20auto-upgrades
    /etc/apt/apt.conf.d/52unattended-upgrades-security
    /usr/local/sbin/raspi-update-report
    /usr/local/sbin/raspi-configure-auto-reboot
    /usr/local/share/raspi-maintenance/53unattended-upgrades-auto-reboot
    /etc/systemd/system/raspi-update-reboot-alert.service
    /etc/systemd/system/raspi-update-reboot-alert.path
    /etc/systemd/system/raspi-update-weekly-report.service
    /etc/systemd/system/raspi-update-weekly-report.timer
)

apt_value() {
    local key=$1 dump=$2
    sed -n "s/^${key//:/\\:} \"\(.*\)\";$/\1/p" <<<"$dump" | tail -n 1
}

validate_reboot_policy() {
    local dump=$1 reboot with_users reboot_time
    reboot=$(apt_value 'Unattended-Upgrade::Automatic-Reboot' "$dump")
    with_users=$(apt_value 'Unattended-Upgrade::Automatic-Reboot-WithUsers' "$dump")
    reboot_time=$(apt_value 'Unattended-Upgrade::Automatic-Reboot-Time' "$dump")
    if [[ $reboot == false ]]; then
        return 0
    fi
    [[ $reboot == true && $with_users == false && $reboot_time == 04:45 ]] || {
        echo "Automatic reboot is neither disabled nor using the approved 04:45 profile" >&2
        return 1
    }
}

usage() {
    cat >&2 <<'EOF'
Usage:
  sudo ./install-updates.sh --check
  sudo ./install-updates.sh --apply
  sudo ./install-updates.sh --rollback /var/backups/raspi-update-policy/YYYYMMDD-HHMMSS

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

[[ $EUID -eq 0 ]] || { echo "Run this installer with sudo" >&2; exit 1; }

validate_apt_sources() {
    local combined dump optional_combined optional_dump
    combined=$(mktemp)
    dump=$(mktemp)
    cat "$SOURCE_DIR/20auto-upgrades" \
        "$SOURCE_DIR/52unattended-upgrades-security" >"$combined"
    if ! apt-config -c "$combined" dump >"$dump"; then
        rm -f -- "$combined" "$dump"
        return 1
    fi
    grep -Fq 'label=Debian-Security' "$dump" || {
        echo "Source policy does not select Debian-Security" >&2
        rm -f -- "$combined" "$dump"
        return 1
    }
    if grep -E '^(Unattended-Upgrade::Origins-Pattern::|Unattended-Upgrade::Allowed-Origins::)' "$dump" | grep -Fvq 'label=Debian-Security'; then
        echo "Source policy permits an origin outside Debian-Security" >&2
        rm -f -- "$combined" "$dump"
        return 1
    fi
    grep -Eq 'Unattended-Upgrade::Automatic-Reboot[[:space:]]+"false"' "$dump" || {
        echo "Source policy does not disable automatic reboot" >&2
        rm -f -- "$combined" "$dump"
        return 1
    }
    grep -Eq 'APT::Periodic::Unattended-Upgrade[[:space:]]+"1"' "$dump" || {
        echo "Source policy does not enable unattended upgrades" >&2
        rm -f -- "$combined" "$dump"
        return 1
    }

    optional_combined=$(mktemp)
    optional_dump=$(mktemp)
    cat "$combined" "$SOURCE_DIR/53unattended-upgrades-auto-reboot.example" >"$optional_combined"
    if ! apt-config -c "$optional_combined" dump >"$optional_dump"; then
        rm -f -- "$combined" "$dump" "$optional_combined" "$optional_dump"
        return 1
    fi
    validate_reboot_policy "$(<"$optional_dump")" || {
        rm -f -- "$combined" "$dump" "$optional_combined" "$optional_dump"
        return 1
    }
    rm -f -- "$combined" "$dump" "$optional_combined" "$optional_dump"
}

validate_sources() {
    local command file package package_status
    for command in apt-config apt-get awk bash cat chmod cp date df dirname dpkg-query flock grep head hostname install logger mktemp mv readlink rm sed sort systemctl systemd-analyze tail unattended-upgrade wc who; do
        command -v "$command" >/dev/null 2>&1 || {
            echo "Required command is missing: $command" >&2
            return 1
        }
    done
    for file in \
        20auto-upgrades \
        52unattended-upgrades-security \
        53unattended-upgrades-auto-reboot.example \
        configure-auto-reboot.sh \
        raspi-update-report \
        raspi-update-reboot-alert.service \
        raspi-update-reboot-alert.path \
        raspi-update-weekly-report.service \
        raspi-update-weekly-report.timer; do
        [[ -f "$SOURCE_DIR/$file" ]] || {
            echo "Required source file is missing: $file" >&2
            return 1
        }
    done
    [[ -d /etc/apt/apt.conf.d ]] || { echo "/etc/apt/apt.conf.d is missing" >&2; return 1; }
    for package in unattended-upgrades reboot-notifier; do
        package_status=$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)
        [[ "$package_status" == installed ]] || {
            echo "Required package is not installed: $package" >&2
            return 1
        }
    done
    [[ -x /usr/local/sbin/raspi-notify ]] || {
        echo "Install src/notify first; /usr/local/sbin/raspi-notify is missing" >&2
        return 1
    }
    bash -n "$SOURCE_DIR/raspi-update-report"
    bash -n "$SOURCE_DIR/configure-auto-reboot.sh"
    bash -n "$SOURCE_DIR/install-updates.sh"
    validate_apt_sources
}

show_plan() {
    cat <<EOF
Validation passed. No files were changed.

The apply mode will:
  1. Back up existing managed files under $BACKUP_ROOT/.
  2. Install the security-only APT policy, report command, systemd units and
     optional automatic-reboot helper.
  3. Reload systemd metadata and verify the installed units and APT policy.

It will not install a package, enable or start a timer, restart a service,
send a notification, run apt-get update, perform an upgrade or reboot.

The optional helper is installed for later use. Automatic reboot remains
disabled unless it was already enabled with the approved 04:45 profile.

If apt-daily-upgrade.timer is already active, the new policy will control its
next unattended run after installation.
EOF
}

create_backup() {
    local stamp target backup_dir
    stamp=$(date +%Y%m%d-%H%M%S)
    backup_dir=$BACKUP_ROOT/$stamp
    [[ ! -e "$backup_dir" ]] || backup_dir=$BACKUP_ROOT/$stamp-$$
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
    local candidate=$1 target
    for target in "${TARGETS[@]}"; do
        [[ "$candidate" == "$target" ]] && return 0
    done
    return 1
}

restore_backup() {
    local requested=$1 root backup target
    root=$(readlink -f -- "$BACKUP_ROOT")
    backup=$(readlink -f -- "$requested") || {
        echo "Cannot resolve backup: $requested" >&2
        return 1
    }
    case "$backup" in
        "$root"/*) ;;
        *) echo "Refusing backup outside $root" >&2; return 1 ;;
    esac
    [[ -f "$backup/existing-files" && -f "$backup/absent-files" ]] || {
        echo "Backup manifest is missing" >&2
        return 1
    }
    while IFS= read -r target; do
        [[ -z "$target" ]] && continue
        is_managed_target "$target" || return 1
        rm -f -- "$target"
    done <"$backup/absent-files"
    while IFS= read -r target; do
        [[ -z "$target" ]] && continue
        is_managed_target "$target" || return 1
        [[ -e "$backup$target" ]] || {
            echo "Backup is missing $target" >&2
            return 1
        }
        install -d -o root -g root -m 755 "$(dirname -- "$target")"
        cp -a -- "$backup$target" "$target"
    done <"$backup/existing-files"
    systemctl daemon-reload
}

if [[ $mode == rollback ]]; then
    restore_backup "$rollback_dir"
    echo "Restored managed files from $rollback_dir"
    echo "Timer state, APT metadata, notifications and installed packages were unchanged."
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

install -o root -g root -m 644 "$SOURCE_DIR/20auto-upgrades" /etc/apt/apt.conf.d/20auto-upgrades
install -o root -g root -m 644 "$SOURCE_DIR/52unattended-upgrades-security" /etc/apt/apt.conf.d/52unattended-upgrades-security
install -o root -g root -m 755 "$SOURCE_DIR/raspi-update-report" /usr/local/sbin/raspi-update-report
install -o root -g root -m 755 "$SOURCE_DIR/configure-auto-reboot.sh" /usr/local/sbin/raspi-configure-auto-reboot
install -d -o root -g root -m 755 /usr/local/share/raspi-maintenance
install -o root -g root -m 644 "$SOURCE_DIR/53unattended-upgrades-auto-reboot.example" /usr/local/share/raspi-maintenance/53unattended-upgrades-auto-reboot
install -o root -g root -m 644 "$SOURCE_DIR/raspi-update-reboot-alert.service" /etc/systemd/system/raspi-update-reboot-alert.service
install -o root -g root -m 644 "$SOURCE_DIR/raspi-update-reboot-alert.path" /etc/systemd/system/raspi-update-reboot-alert.path
install -o root -g root -m 644 "$SOURCE_DIR/raspi-update-weekly-report.service" /etc/systemd/system/raspi-update-weekly-report.service
install -o root -g root -m 644 "$SOURCE_DIR/raspi-update-weekly-report.timer" /etc/systemd/system/raspi-update-weekly-report.timer
install -d -o root -g root -m 700 /var/lib/raspi-update-report

systemctl daemon-reload
systemd-analyze verify \
    /etc/systemd/system/raspi-update-reboot-alert.service \
    /etc/systemd/system/raspi-update-reboot-alert.path \
    /etc/systemd/system/raspi-update-weekly-report.service \
    /etc/systemd/system/raspi-update-weekly-report.timer

effective=$(apt-config dump)
grep -Fq 'label=Debian-Security' <<<"$effective"
if grep -E '^(Unattended-Upgrade::Origins-Pattern::|Unattended-Upgrade::Allowed-Origins::)' <<<"$effective" | grep -Fvq 'label=Debian-Security'; then
    echo "Installed policy permits an origin outside Debian-Security" >&2
    false
fi
validate_reboot_policy "$effective"
grep -Eq 'APT::Periodic::Unattended-Upgrade[[:space:]]+"1"' <<<"$effective"

rollback_needed=0
trap - ERR
echo "Automatic security update policy installed. Previous files: $backup_dir"
echo "No timer or path unit was enabled or started. Continue with the documented review."
