#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LOCAL_CONFIG=$SOURCE_DIR/ups-monitor.conf
BACKUP_ROOT=/var/backups/raspi-ups-monitor
UPSMON_CONF=/etc/nut/upsmon.conf
BEGIN_MARKER='# BEGIN RASPI UPS MONITOR'
END_MARKER='# END RASPI UPS MONITOR'

TARGETS=(
    /usr/local/sbin/raspi-ups-monitor
    /usr/local/sbin/raspi-ups-event-hook
    /etc/raspi-ups-monitor/ups-monitor.conf
    /etc/systemd/system/raspi-ups-monitor.service
    /etc/systemd/system/raspi-ups-monitor.timer
    /etc/systemd/system/raspi-ups-monitor.path
    /etc/nut/upsmon.conf
)

usage() {
    cat >&2 <<'EOF'
Usage:
  sudo ./install-ups-monitor.sh --check
  sudo ./install-ups-monitor.sh --apply
  sudo ./install-ups-monitor.sh --rollback /var/backups/raspi-ups-monitor/YYYYMMDD-HHMMSS

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

validate_config() {
    local config=$1 key value integer offset
    local UPS_NAME="" UPS_DRIVER_SERVICE="" NUT_SERVER_SERVICE="" NUT_MONITOR_SERVICE=""
    local COMM_FAILURE_CHECKS="" BATTERY_UPDATE_SECONDS=""
    local RUNTIME_ESTIMATE_WINDOW_SECONDS="" RUNTIME_ESTIMATE_MIN_SAMPLES=""
    local RUNTIME_ESTIMATE_MIN_SPAN_SECONDS="" RUNTIME_ESTIMATE_MIN_DROP_VOLTS=""
    local RUNTIME_ESTIMATE_MAX_SECONDS="" COMM_REMINDER_OFFSETS_SECONDS=""
    local COMM_MONTHLY_REMINDER_SECONDS=""

    [[ -r "$config" ]] || { echo "Cannot read $config" >&2; return 1; }
    while IFS='=' read -r key value || [[ -n "${key:-}${value:-}" ]]; do
        key=${key%$'\r'}; value=${value%$'\r'}
        [[ -z "$key" || "$key" == \#* ]] && continue
        case "$key" in
            UPS_NAME|UPS_DRIVER_SERVICE|NUT_SERVER_SERVICE|NUT_MONITOR_SERVICE|\
            COMM_FAILURE_CHECKS|BATTERY_UPDATE_SECONDS|\
            RUNTIME_ESTIMATE_WINDOW_SECONDS|RUNTIME_ESTIMATE_MIN_SAMPLES|\
            RUNTIME_ESTIMATE_MIN_SPAN_SECONDS|RUNTIME_ESTIMATE_MIN_DROP_VOLTS|\
            RUNTIME_ESTIMATE_MAX_SECONDS|COMM_REMINDER_OFFSETS_SECONDS|\
            COMM_MONTHLY_REMINDER_SECONDS) printf -v "$key" '%s' "$value" ;;
            *) echo "Unknown setting in $config: $key" >&2; return 1 ;;
        esac
    done <"$config"

    [[ "$UPS_NAME" =~ ^[A-Za-z0-9_.-]+(@[A-Za-z0-9_.:-]+)?$ ]] || { echo "Invalid UPS_NAME" >&2; return 1; }
    for value in "$UPS_DRIVER_SERVICE" "$NUT_SERVER_SERVICE" "$NUT_MONITOR_SERVICE"; do
        [[ "$value" =~ ^[A-Za-z0-9@_.:-]+\.service$ ]] || { echo "Invalid systemd service name: $value" >&2; return 1; }
    done
    for integer in COMM_FAILURE_CHECKS BATTERY_UPDATE_SECONDS \
        RUNTIME_ESTIMATE_WINDOW_SECONDS RUNTIME_ESTIMATE_MIN_SAMPLES \
        RUNTIME_ESTIMATE_MIN_SPAN_SECONDS RUNTIME_ESTIMATE_MAX_SECONDS \
        COMM_MONTHLY_REMINDER_SECONDS; do
        [[ -n "${!integer}" && "${!integer}" =~ ^[1-9][0-9]*$ ]] || { echo "Invalid positive integer: $integer" >&2; return 1; }
    done
    [[ "$RUNTIME_ESTIMATE_MIN_DROP_VOLTS" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "Invalid RUNTIME_ESTIMATE_MIN_DROP_VOLTS" >&2; return 1; }
    [[ -n "$COMM_REMINDER_OFFSETS_SECONDS" ]] || { echo "COMM_REMINDER_OFFSETS_SECONDS is empty" >&2; return 1; }
    for offset in $COMM_REMINDER_OFFSETS_SECONDS; do
        [[ "$offset" =~ ^[1-9][0-9]*$ ]] || { echo "Invalid reminder offset: $offset" >&2; return 1; }
    done
    printf '%s' "$UPS_NAME"
}

without_managed_block() {
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin {if (inside) exit 2; inside=1; next}
        $0 == end {if (!inside) exit 2; inside=0; next}
        !inside {print}
        END {if (inside) exit 2}
    ' "$UPSMON_CONF"
}

check_nut_conflicts() {
    local clean=$1
    if grep -Eiq '^[[:space:]]*NOTIFYCMD[[:space:]]+' "$clean"; then
        echo "Existing NOTIFYCMD found outside this installer's managed block." >&2
        echo "Review and migrate that integration manually before continuing." >&2
        return 1
    fi
    if grep -Eiq '^[[:space:]]*NOTIFYFLAG[[:space:]]+(ONLINE|ONBATT|LOWBATT|FSD|SHUTDOWN|COMMBAD|COMMOK|NOCOMM|REPLBATT)[[:space:]]+' "$clean"; then
        echo "Existing UPS NOTIFYFLAG entries found outside the managed block." >&2
        echo "Review and migrate them manually before continuing." >&2
        return 1
    fi
}

validate_sources() {
    local command file clean ups_name
    for command in awk bash cat chmod cp date dirname flock getent grep head hostname install logger mktemp mv readlink rm runuser sed sync systemctl systemd-analyze upsc; do
        command -v "$command" >/dev/null 2>&1 || { echo "Required command is missing: $command" >&2; return 1; }
    done
    for file in raspi-ups-monitor raspi-ups-event-hook raspi-ups-monitor.service raspi-ups-monitor.timer raspi-ups-monitor.path; do
        [[ -f "$SOURCE_DIR/$file" ]] || { echo "Required source file is missing: $file" >&2; return 1; }
    done
    bash -n "$SOURCE_DIR/raspi-ups-monitor"
    bash -n "$SOURCE_DIR/raspi-ups-event-hook"
    bash -n "$SOURCE_DIR/install-ups-monitor.sh"
    ups_name=$(validate_config "$LOCAL_CONFIG") || return 1
    [[ -x /usr/local/sbin/raspi-notify ]] || { echo "Install src/notify first; /usr/local/sbin/raspi-notify is missing" >&2; return 1; }
    [[ -r "$UPSMON_CONF" ]] || { echo "Cannot read $UPSMON_CONF" >&2; return 1; }
    getent group nut >/dev/null || { echo "The nut group does not exist" >&2; return 1; }
    clean=$(mktemp); without_managed_block >"$clean" || { rm -f -- "$clean"; echo "Malformed managed block in $UPSMON_CONF" >&2; return 1; }
    check_nut_conflicts "$clean" || { rm -f -- "$clean"; return 1; }
    rm -f -- "$clean"
    upsc "$ups_name" >/dev/null 2>&1 || { echo "Cannot read configured UPS: $ups_name" >&2; return 1; }
}

show_plan() {
    cat <<EOF
Validation passed. No files were changed.

The apply mode will:
  1. Back up existing managed files under $BACKUP_ROOT/.
  2. Install the monitor, NUT event hook, local configuration and systemd units.
  3. Append one marked notification block to $UPSMON_CONF.
  4. Reload systemd metadata and verify the installed units.

It will not enable a unit, restart NUT, change UPS state or send a test email.
EOF
}

create_backup() {
    local stamp target backup_dir
    stamp=$(date +%Y%m%d-%H%M%S); backup_dir=$BACKUP_ROOT/$stamp
    [[ ! -e "$backup_dir" ]] || backup_dir=$BACKUP_ROOT/$stamp-$$
    install -d -o root -g root -m 700 "$backup_dir"
    : >"$backup_dir/existing-files"; : >"$backup_dir/absent-files"
    for target in "${TARGETS[@]}"; do
        if [[ -e "$target" ]]; then printf '%s\n' "$target" >>"$backup_dir/existing-files"; cp -a --parents "$target" "$backup_dir"
        else printf '%s\n' "$target" >>"$backup_dir/absent-files"; fi
    done
    printf '%s' "$backup_dir"
}

is_managed_target() {
    local candidate=$1 target
    for target in "${TARGETS[@]}"; do [[ "$candidate" == "$target" ]] && return 0; done
    return 1
}

restore_backup() {
    local requested=$1 root backup target
    root=$(readlink -f -- "$BACKUP_ROOT"); backup=$(readlink -f -- "$requested") || { echo "Cannot resolve backup: $requested" >&2; return 1; }
    case "$backup" in "$root"/*) :;; *) echo "Refusing backup outside $root" >&2; return 1;; esac
    [[ -f "$backup/existing-files" && -f "$backup/absent-files" ]] || { echo "Backup manifest is missing" >&2; return 1; }
    while IFS= read -r target; do [[ -z "$target" ]] && continue; is_managed_target "$target" || return 1; rm -f -- "$target"; done <"$backup/absent-files"
    while IFS= read -r target; do
        [[ -z "$target" ]] && continue; is_managed_target "$target" || return 1
        [[ -e "$backup$target" ]] || { echo "Backup is missing $target" >&2; return 1; }
        install -d -o root -g root -m 755 "$(dirname -- "$target")"; cp -a -- "$backup$target" "$target"
    done <"$backup/existing-files"
    systemctl daemon-reload
}

if [[ $mode == rollback ]]; then
    restore_backup "$rollback_dir"
    echo "Restored managed files from $rollback_dir"
    echo "Runtime state, queued notifications and NUT service state were left unchanged."
    exit 0
fi

validate_sources
[[ $mode == apply ]] || { show_plan; exit 0; }

backup_dir=$(create_backup); rollback_needed=1
rollback_on_error() {
    local status=$?; trap - ERR
    if (( rollback_needed == 1 )); then echo "Installation failed; restoring $backup_dir" >&2; restore_backup "$backup_dir" || true; fi
    exit "$status"
}
trap rollback_on_error ERR

install -d -o root -g root -m 755 /etc/raspi-ups-monitor
install -d -o root -g nut -m 710 /var/lib/raspi-ups-monitor
install -d -o root -g nut -m 2770 /var/lib/raspi-ups-monitor/events
install -o root -g root -m 600 "$LOCAL_CONFIG" /etc/raspi-ups-monitor/ups-monitor.conf
install -o root -g root -m 755 "$SOURCE_DIR/raspi-ups-monitor" /usr/local/sbin/raspi-ups-monitor
install -o root -g root -m 755 "$SOURCE_DIR/raspi-ups-event-hook" /usr/local/sbin/raspi-ups-event-hook
install -o root -g root -m 644 "$SOURCE_DIR/raspi-ups-monitor.service" /etc/systemd/system/raspi-ups-monitor.service
install -o root -g root -m 644 "$SOURCE_DIR/raspi-ups-monitor.timer" /etc/systemd/system/raspi-ups-monitor.timer
install -o root -g root -m 644 "$SOURCE_DIR/raspi-ups-monitor.path" /etc/systemd/system/raspi-ups-monitor.path

new_conf=$(mktemp)
without_managed_block >"$new_conf"
cat >>"$new_conf" <<'EOF'

# BEGIN RASPI UPS MONITOR
NOTIFYCMD "/usr/local/sbin/raspi-ups-event-hook"
NOTIFYFLAG ONLINE   SYSLOG+WALL+EXEC
NOTIFYFLAG ONBATT   SYSLOG+WALL+EXEC
NOTIFYFLAG LOWBATT  SYSLOG+WALL+EXEC
NOTIFYFLAG FSD      SYSLOG+WALL+EXEC
NOTIFYFLAG SHUTDOWN SYSLOG+WALL+EXEC
NOTIFYFLAG COMMBAD  SYSLOG+EXEC
NOTIFYFLAG COMMOK   SYSLOG+EXEC
NOTIFYFLAG NOCOMM   SYSLOG+EXEC
NOTIFYFLAG REPLBATT SYSLOG+EXEC
# END RASPI UPS MONITOR
EOF
install -o root -g nut -m 640 "$new_conf" "$UPSMON_CONF"
rm -f -- "$new_conf"

systemctl daemon-reload
systemd-analyze verify /etc/systemd/system/raspi-ups-monitor.service /etc/systemd/system/raspi-ups-monitor.timer /etc/systemd/system/raspi-ups-monitor.path

rollback_needed=0; trap - ERR
echo "UPS monitor files installed. Previous managed files: $backup_dir"
echo "No unit was enabled and NUT was not restarted. Continue with the documented review and tests."
