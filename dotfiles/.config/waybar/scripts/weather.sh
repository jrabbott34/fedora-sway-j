#!/usr/bin/env bash
# Fetches weather from wttr.in for Louisville, KY
# Returns JSON for waybar custom module

LOCATION="Louisville,KY"
WEATHER=$(curl -sf "https://wttr.in/${LOCATION}?format=j1" 2>/dev/null)

if [[ -z "$WEATHER" ]]; then
    echo '{"text": "󰖙 --°F", "tooltip": "Weather unavailable", "class": "unknown"}'
    exit 0
fi

TEMP=$(echo "$WEATHER"     | jq -r '.current_condition[0].temp_F')
FEELS=$(echo "$WEATHER"    | jq -r '.current_condition[0].FeelsLikeF')
DESC=$(echo "$WEATHER"     | jq -r '.current_condition[0].weatherDesc[0].value')
HUMIDITY=$(echo "$WEATHER" | jq -r '.current_condition[0].humidity')
WIND=$(echo "$WEATHER"     | jq -r '.current_condition[0].windspeedMiles')
CODE=$(echo "$WEATHER"     | jq -r '.current_condition[0].weatherCode')

case $CODE in
    113)                              ICON="󰖙" ;;  # Clear/Sunny
    116)                              ICON="󰖕" ;;  # Partly cloudy
    119|122)                          ICON="󰖐" ;;  # Cloudy/Overcast
    143|248|260)                      ICON="󰖑" ;;  # Fog/Mist
    176|263|266|293|296|353)          ICON="󰖗" ;;  # Light rain
    299|302|305|308|356|359)          ICON="󰖖" ;;  # Heavy rain
    179|182|185|281|284|311|314|\
    317|320|323|326|374|377)          ICON="󰖘" ;;  # Sleet/Freezing rain
    227|230|329|332|335|338|350|\
    368|371)                          ICON="󰖒" ;;  # Snow
    200|386|389|392|395)              ICON="󰖓" ;;  # Thunder
    *)                                ICON="󰖙" ;;
esac

TEXT="${ICON} ${TEMP}°F"
TOOLTIP="${DESC}\\nFeels like: ${FEELS}°F\\nHumidity: ${HUMIDITY}%\\nWind: ${WIND} mph"

printf '{"text": "%s", "tooltip": "%s", "class": "weather"}\n' "$TEXT" "$TOOLTIP"
