#!/bin/bash

BOARD_CONFIG="$1"
HUIOS_GENERIC_CONFIG_FOLDER="huios/configs"
HUIOS_PROFILES_FOLDER="huios/profiles"
TEMP_CONFIG=".tmpconfig"

declare -A config
shopt -s nullglob

merge_config() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "Error: Unable to generate a defconfig as the $file does not exist"
        rm ".config"
        exit -1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)\+\=(\"([^\"]*)\"|([^[:space:]]+))$ ]]; then
            key="${BASH_REMATCH[1]}"
            if [[ -n "${BASH_REMATCH[3]}" ]]; then
                value="${BASH_REMATCH[3]}"
            else
                value="${BASH_REMATCH[4]}"
            fi
            if [[ -n "${config[$key]}" ]]; then
                prev_value="${config[$key]}"
                prev_value="${prev_value:1:-1}"
                config[$key]="\"${prev_value}${value}\""
            else
                config[$key]="\"$value\""
            fi
        elif [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(\"([^\"]*)\"|([^[:space:]]+))$ ]]; then
            key="${BASH_REMATCH[1]}"
            if [[ -n "${BASH_REMATCH[3]}" ]]; then
                value="\"${BASH_REMATCH[3]}\""
            else
                value="${BASH_REMATCH[4]}"
            fi
            config[$key]="$value"
        fi
    done < "$file"
}

#arguments validation
if [ -z "$BOARD_CONFIG" ]; then
    echo "Error! Usage: genconfig.sh [board defconfig] [fragmented config 1] [fragmented config 1]"
    exit 1
fi

if [ ! -e "configs/$BOARD_CONFIG" ]; then
    echo "Error: defconfig not found"
    exit 1
fi

for arg in "${@:2}"; do
    echo $arg
    if [ -z arg ]; then
        continue;
    fi
    if [ ! -e "huios/profiles/$arg" ]; then
        echo "Error: \"$arg\" profile was not found at \"huios/profiles/\" folder"
        exit 1
    fi
done

merge_config configs/$BOARD_CONFIG
for file in "$HUIOS_GENERIC_CONFIG_FOLDER"/*; do
    echo "Merging $file"
    merge_config $file
done

for arg in "${@:2}"; do
    echo "Merging $file"
    merge_config "huios/profiles/$arg"
done

echo Writing everything to .config

: > "$TEMP_CONFIG"
for key in "${!config[@]}"; do
    value="${config[$key]}"
    if [ -z "$value" ]; then
        echo "$key=\"\"" >> "$TEMP_CONFIG"
    else
        echo "$key=$value" >> "$TEMP_CONFIG"
    fi
done

make KCONFIG_ALLCONFIG="$TEMP_CONFIG" alldefconfig
rm "$TEMP_CONFIG"
