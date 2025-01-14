#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

##################
# INITIALIZATION #
##################

# Exit if /config is not mounted
if [ ! -d /config ]; then
    exit 0
fi

# Define slug
slug="${HOSTNAME}"

# Check type of config folder
if [ ! -f /config/configuration.yaml ] && [ ! -f /config/configuration.json ]; then
    # New config location
    CONFIGLOCATION="/config"
    CONFIGFILEBROWSER="/addon_configs/$slug/${HOSTNAME#*-}.sh"
else
    # Legacy config location
    slug="${HOSTNAME#*-}"
    CONFIGLOCATION="/config/addons_autoscripts"
    CONFIGFILEBROWSER="/homeassistant/addons_config/${slug}/${slug}.sh"
fi

# Default location
mkdir -p "$CONFIGLOCATION" || true
CONFIGSOURCE="$CONFIGLOCATION/${HOSTNAME#*-}.sh"

bashio::log.green "Execute $CONFIGFILEBROWSER if existing"
bashio::log.green "Wiki here : github.com/alexbelgium/hassio-addons/wiki/Add-ons-feature-:-customisation"

# Download template if no script found and exit
if [ ! -f "$CONFIGSOURCE" ]; then
    TEMPLATESOURCE="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/script.template"
    curl -f -L -s -S "$TEMPLATESOURCE" --output "$CONFIGSOURCE" || true
    exit 0
fi

# Convert scripts to linux
dos2unix "$CONFIGSOURCE" &>/dev/null || true
chmod +x "$CONFIGSOURCE"

# Check if there is actual commands
while IFS= read -r line
do
    # Remove leading and trailing whitespaces
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Check if line is not empty and does not start with #
    if [[ -n "$line" ]] && [[ ! "$line" =~ ^# ]]; then
        bashio::log.green "... script found, executing"
        /."$CONFIGSOURCE"
        exit 0
    fi
done < "$CONFIGSOURCE"
