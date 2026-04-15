#!/usr/bin/env bash
# =============================================================================
# Plugin: weather
# Description: Display weather information with automatic fallback
# Primary API: Open-Meteo (free, no API key, reliable, uses IP-based geolocation)
# Fallback API: wttr.in (supports custom locations and formats)
# Dependencies: curl
# =============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=src/utils.sh
. "$ROOT_DIR/../utils.sh"
# shellcheck source=src/cache.sh
. "$ROOT_DIR/../cache.sh"

# =============================================================================
# Plugin Configuration
# =============================================================================

# shellcheck disable=SC2034
plugin_weather_icon=$(get_tmux_option "@theme_plugin_weather_icon" " ")
# shellcheck disable=SC2034
plugin_weather_accent_color=$(get_tmux_option "@theme_plugin_weather_accent_color" "blue7")
# shellcheck disable=SC2034
plugin_weather_accent_color_icon=$(get_tmux_option "@theme_plugin_weather_accent_color_icon" "blue0")

# Plugin-specific options
# Note: @theme_plugin_weather_location only applies to wttr.in fallback
# Open-Meteo (primary) uses IP-based geolocation automatically
plugin_weather_location=$(get_tmux_option "@theme_plugin_weather_location" "")
plugin_weather_unit=$(get_tmux_option "@theme_plugin_weather_unit" "")
plugin_weather_format=$(get_tmux_option "@theme_plugin_weather_format" "%t H:%h")

# Cache TTL in seconds (default: 900 seconds = 15 minutes)
WEATHER_CACHE_TTL=$(get_tmux_option "@theme_plugin_weather_cache_ttl" "900")
WEATHER_CACHE_KEY="weather"
WEATHER_LOCATION_CACHE_KEY="weather_location"
WEATHER_LOCATION_CACHE_TTL="3600" # 1 hour for location

export plugin_weather_icon plugin_weather_accent_color plugin_weather_accent_color_icon

# =============================================================================
# Helper Functions
# =============================================================================

# -----------------------------------------------------------------------------
# Check if curl is available
# Returns: 0 if available, 1 otherwise
# -----------------------------------------------------------------------------
weather_check_dependencies() {
    command -v curl &>/dev/null
}

# -----------------------------------------------------------------------------
# Detect location via IP (cached separately with longer TTL)
# Returns: Location string
# -----------------------------------------------------------------------------
weather_detect_location() {
    local cached_location

    # Try cache first (location doesn't change often)
    if cached_location=$(cache_get "$WEATHER_LOCATION_CACHE_KEY" "$WEATHER_LOCATION_CACHE_TTL"); then
        printf '%s' "$cached_location"
        return 0
    fi

    # Need jq for location detection
    if ! command -v jq &>/dev/null; then
        printf ''
        return 1
    fi

    local location
    location=$(curl -s --connect-timeout 5 --max-time 10 https://ip-api.com/json 2>/dev/null |
        jq -r '"\(.city), \(.country)"' 2>/dev/null)

    if [[ -n "$location" && "$location" != "null, null" && "$location" != ", " ]]; then
        cache_set "$WEATHER_LOCATION_CACHE_KEY" "$location"
        printf '%s' "$location"
        return 0
    fi

    printf ''
    return 1
}

# -----------------------------------------------------------------------------
# Detect location via IP for fallback API
# Returns: Latitude,Longitude or empty string
# -----------------------------------------------------------------------------
weather_detect_coordinates() {
    local cached_coords
    local coords_cache_key="weather_coordinates"

    # Try cache first (coordinates don't change often)
    if cached_coords=$(cache_get "$coords_cache_key" "$WEATHER_LOCATION_CACHE_TTL"); then
        printf '%s' "$cached_coords"
        return 0
    fi

    # Fetch coordinates from IP geolocation using ipinfo.io
    local coords
    coords=$(curl -s --connect-timeout 5 --max-time 10 https://ipinfo.io/loc 2>/dev/null | tr -d '\n')

    if [[ -n "$coords" && "$coords" =~ ^-?[0-9]+\.?[0-9]*,-?[0-9]+\.?[0-9]*$ ]]; then
        cache_set "$coords_cache_key" "$coords"
        printf '%s' "$coords"
        return 0
    fi

    printf ''
    return 1
}

# -----------------------------------------------------------------------------
# Fetch weather from Open-Meteo (fallback API, no key required)
# Arguments:
#   $1 - Latitude,Longitude (optional)
# Returns: Weather string in same format as wttr.in
# -----------------------------------------------------------------------------
weather_fetch_openmeteo() {
    local coords="$1"

    # If no coordinates provided, try to detect
    if [[ -z "$coords" ]]; then
        coords=$(weather_detect_coordinates)
    fi

    # If still no coordinates, can't fetch
    if [[ -z "$coords" ]]; then
        printf 'N/A'
        return 1
    fi

    local lat="${coords%,*}"
    local lon="${coords#*,}"

    # Fetch current weather from Open-Meteo
    local response
    response=$(curl -sL --connect-timeout 5 --max-time 10 \
        "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m&temperature_unit=celsius" 2>/dev/null)

    if [[ -z "$response" ]]; then
        printf 'N/A'
        return 1
    fi

    # Parse temperature and humidity using sed
    local temp
    local humidity
    temp=$(echo "$response" | sed -n 's/.*"temperature_2m":\([^,}]*\).*/\1/p' | tail -1)
    humidity=$(echo "$response" | sed -n 's/.*"relative_humidity_2m":\([^,}]*\).*/\1/p' | tail -1)

    if [[ -z "$temp" || -z "$humidity" ]]; then
        printf 'N/A'
        return 1
    fi

    # Format output to match wttr.in style (handle unit conversion if needed)
    local temp_display
    if [[ "$plugin_weather_unit" == "u" ]]; then
        # Convert Celsius to Fahrenheit
        temp_display=$(awk "BEGIN {printf \"%.0f°F\", ($temp * 9/5) + 32}")
    else
        temp_display=$(printf "%.0f°C" "$temp")
    fi

    printf '%s H:%s%%' "$temp_display" "$humidity"
}

# -----------------------------------------------------------------------------
# Fetch weather data from wttr.in
# Arguments:
#   $1 - Location (optional)
# Returns: Weather string
# -----------------------------------------------------------------------------
weather_fetch_wttr() {
    local location="$1"
    local url

    # Build URL - if no location, wttr.in uses IP-based location
    if [[ -n "$location" ]]; then
        # URL encode the location properly using simple sed replacement
        local encoded_location
        encoded_location=$(printf '%s' "$location" | sed 's/ /%20/g; s/,/%2C/g')
        url="https://wttr.in/${encoded_location}?"
    else
        url="https://wttr.in/?"
    fi

    # Add unit parameter if specified
    [[ -n "$plugin_weather_unit" ]] && url+="${plugin_weather_unit}&"

    # URL encode the format string more thoroughly
    local encoded_format
    encoded_format=$(printf '%s' "$plugin_weather_format" | sed 's/%/%25/g; s/ /%20/g; s/:/%3A/g; s/+/%2B/g')
    url+="format=${encoded_format}"

    local weather
    weather=$(curl -sL --connect-timeout 5 --max-time 10 "$url" 2>/dev/null)

    # Validate response
    if [[ -z "$weather" || "$weather" == *"Unknown"* || "$weather" == *"ERROR"* || ${#weather} -gt 50 ]]; then
        printf 'N/A'
        return 1
    fi

    printf '%s' "$weather"
}

# -----------------------------------------------------------------------------
# Fetch weather with fallback strategy
# Arguments:
#   $1 - Location (optional, only used for wttr.in fallback)
# Returns: Weather string
# -----------------------------------------------------------------------------
weather_fetch() {
    local location="$1"
    local result

    # Try Open-Meteo first (more reliable)
    result=$(weather_fetch_openmeteo "")

    # If Open-Meteo succeeded, return result
    if [[ "$result" != "N/A" ]]; then
        printf '%s' "$result"
        return 0
    fi

    # Open-Meteo failed, try wttr.in as fallback
    result=$(weather_fetch_wttr "$location")

    printf '%s' "$result"
    [[ "$result" != "N/A" ]] && return 0 || return 1
}

# =============================================================================
# Main Plugin Logic
# =============================================================================

load_plugin() {
    # Check dependencies - fail silently if curl is not available
    if ! weather_check_dependencies; then
        return 0
    fi

    # Try cache first
    local cached_value
    if cached_value=$(cache_get "$WEATHER_CACHE_KEY" "$WEATHER_CACHE_TTL"); then
        # Don't return cached N/A
        if [[ "$cached_value" != "N/A" ]]; then
            printf '%s' "$cached_value"
            return 0
        fi
    fi

    # Determine location - only use configured location, otherwise let wttr.in auto-detect
    local location=""
    if [[ -n "$plugin_weather_location" ]]; then
        location="$plugin_weather_location"
    fi

    # Fetch weather
    local result
    result=$(weather_fetch "$location")

    # Cache and output
    cache_set "$WEATHER_CACHE_KEY" "$result"
    printf '%s' "$result"
}

load_plugin
