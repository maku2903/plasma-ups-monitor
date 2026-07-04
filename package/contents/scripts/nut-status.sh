#!/usr/bin/env sh
set -eu

UPS_NAME="${1:-eaton@localhost}"
LAST_ONBATT_FILE="/var/lib/ups/last-onbatt-epoch"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/plasma-ups-monitor"
LOCAL_LAST_ONBATT_FILE="${STATE_DIR}/last-onbatt-epoch"
LOCAL_PREV_ONBATT_FILE="${STATE_DIR}/previous-onbatt"

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_number_or_null() {
    case "${1-}" in
        "")
            printf 'null'
            ;;
        *)
            printf '%s' "$1"
            ;;
    esac
}

read_first_existing_timestamp() {
    for candidate in "$LOCAL_LAST_ONBATT_FILE" "$LAST_ONBATT_FILE"; do
        if [ -r "$candidate" ]; then
            timestamp="$(tr -cd '0-9' < "$candidate" | head -c 16)"
            if [ -n "$timestamp" ]; then
                printf '%s' "$timestamp"
                return 0
            fi
        fi
    done
    return 1
}

if ! output="$(upsc "$UPS_NAME" 2>&1)"; then
    err="$(json_escape "$output")"
    printf '{'
    printf '"ok":false,'
    printf '"upsName":"%s",' "$(json_escape "$UPS_NAME")"
    printf '"error":"%s"' "$err"
    printf '}\n'
    exit 0
fi

get_value() {
    printf '%s\n' "$output" | sed -n "s/^$1: //p" | head -n 1
}

status="$(get_value 'ups.status')"
model="$(get_value 'ups.model')"
charge="$(get_value 'battery.charge')"
watts="$(get_value 'ups.realpower')"
voltage="$(get_value 'output.voltage')"
runtime="$(get_value 'battery.runtime')"
load="$(get_value 'ups.load')"
alarm="$(get_value 'ups.alarm')"
last_onbatt=""
last_onbatt_epoch=""
previous_onbatt=false

if [ -z "$voltage" ]; then
    voltage="$(get_value 'output.voltage.nominal')"
fi

on_battery=false
case "$status" in
    *OB*)
        on_battery=true
        ;;
esac

mkdir -p "$STATE_DIR"

if [ -r "$LOCAL_PREV_ONBATT_FILE" ] && [ "$(cat "$LOCAL_PREV_ONBATT_FILE" 2>/dev/null)" = "true" ]; then
    previous_onbatt=true
fi

if [ "$on_battery" = true ] && [ "$previous_onbatt" != true ]; then
    date +%s > "$LOCAL_LAST_ONBATT_FILE"
fi

if [ "$on_battery" = true ]; then
    printf 'true' > "$LOCAL_PREV_ONBATT_FILE"
else
    printf 'false' > "$LOCAL_PREV_ONBATT_FILE"
fi

if last_onbatt_epoch="$(read_first_existing_timestamp)"; then
    last_onbatt="$(date -d "@$last_onbatt_epoch" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || true)"
fi

printf '{'
printf '"ok":true,'
printf '"upsName":"%s",' "$(json_escape "$UPS_NAME")"
printf '"model":"%s",' "$(json_escape "$model")"
printf '"status":"%s",' "$(json_escape "$status")"
printf '"onBattery":%s,' "$on_battery"
printf '"batteryPercent":'
json_number_or_null "$charge"
printf ','
printf '"powerWatts":'
json_number_or_null "$watts"
printf ','
printf '"outputVoltage":'
json_number_or_null "$voltage"
printf ','
printf '"runtimeSeconds":'
json_number_or_null "$runtime"
printf ','
printf '"loadPercent":'
json_number_or_null "$load"
printf ','
printf '"alarm":"%s",' "$(json_escape "$alarm")"
printf '"lastPowerLoss":"%s",' "$(json_escape "$last_onbatt")"
printf '"error":""'
printf '}\n'
