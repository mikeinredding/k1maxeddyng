#!/bin/bash

# Configuration
SOURCE_DATA="/usr/data/k1maxeddyng/files"
TARGET_DIR="/usr/share/klipper/klippy"
BACKUP_DIR="$HOME/klipper_backups"
LOG_FILE="/var/log/klipper_update.log"

# Ensure backup directory and log exist
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

FILES=(
    "clocksync.py" "inventory.csv" "mcu.py" "serialhdl.py" "stepper.py"
    "extras/adxl345.py" "extras/axis_twist_compensation.py" "extras/bed_mesh.py"
    "extras/bulk_sensor.py" "extras/bus.py" "extras/gcode_shell_command.py"
    "extras/ldc1612.py" "extras/ldc1612_ng.py" "extras/manual_probe.py"
    "extras/neopixel.py" "extras/probe.py" "extras/probe_eddy_current.py"
    "extras/probe_eddy_ng.py" "extras/screws_tilt_adjust.py" "extras/temperature_mcu.py"
    "extras/temperature_probe.py" "extras/tmc.py" "extras/tmc2130.py"
    "extras/tmc_uart.py" "extras/virtual_pins.py"
)

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

if [[ $EUID -ne 0 ]]; then
   echo "Please run as root (sudo)."
   exit 1
fi

usage() {
    echo "Usage: $0 {update|restore [backup_file]}"
    echo "  update  - Backs up current files, then overwrites from $SOURCE_DATA"
    echo "  restore - Restores files from a specific .tar.gz backup"
    exit 1
}

case "$1" in
    update)
        BACKUP_FILE="$BACKUP_DIR/klipper_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        log_msg "Starting Update: Backing up system files..."
        
        FULL_PATHS=()
        for f in "${FILES[@]}"; do [ -f "$TARGET_DIR/$f" ] && FULL_PATHS+=("$TARGET_DIR/$f"); done

        if [ ${#FULL_PATHS[@]} -gt 0 ]; then
            tar -czf "$BACKUP_FILE" "${FULL_PATHS[@]}" && log_msg "Backup saved: $BACKUP_FILE"
        fi

        log_msg "Overwriting files from $SOURCE_DATA..."
        for FILE in "${FILES[@]}"; do
            SRC="$SOURCE_DATA/$FILE"
            DEST="$TARGET_DIR/$FILE"
            if [ -f "$SRC" ]; then
                mkdir -p "$(dirname "$DEST")"
                cp "$SRC" "$DEST" && log_msg "Updated: $FILE"
            fi
        done
        systemctl restart klipper && log_msg "Klipper restarted."
        ;;

    restore)
        if [ -z "$2" ]; then
            log_msg "ERROR: No backup file specified for restore."
            usage
        fi
        log_msg "Starting Restore from $2..."
        if tar -xzf "$2" -C /; then
            log_msg "Restore successful."
            systemctl restart klipper && log_msg "Klipper restarted."
        else
            log_msg "ERROR: Restore failed."
        fi
        ;;

    *)
        usage
        ;;
esac
