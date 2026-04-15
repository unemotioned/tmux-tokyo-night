#!/usr/bin/env bash
# =============================================================================
# Plugin: weather
# Description: Display weather information using Open-Meteo API
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
plugin_weather_unit=$(get_tmux_option "@theme_plugin_weather_unit" "")

# Cache TTL in seconds (default: 900 seconds = 15 minutes)
WEATHER_CACHE_TTL=$(get_tmux_option "@theme_plugin_weather_cache_ttl" "900")
WEATHER_CACHE_KEY="weather"
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
# Detect coordinates via IP
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
    coords=$(curl -s --connect-timeout 3 --max-time 5 https://ipinfo.io/loc 2>/dev/null | tr -d '\n')

    if [[ -n "$coords" && "$coords" =~ ^-?[0-9]+\.?[0-9]*,-?[0-9]+\.?[0-9]*$ ]]; then
        cache_set "$coords_cache_key" "$coords"
        printf '%s' "$coords"
        return 0
    fi

    printf ''
    return 1
}

# -----------------------------------------------------------------------------
# Fetch weather from Open-Meteo API
# Arguments:
#   $1 - Latitude,Longitude (optional)
# Returns: Weather string
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
    response=$(curl -sL --connect-timeout 3 --max-time 5 \
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

    # Format output with unit conversion if needed
    local temp_display
    if [[ "$plugin_weather_unit" == "u" ]]; then
        temp_display="$(((${temp%.*} * 9 / 5) + 32))°F"
    else
        temp_display="${temp%.*}°C"
    fi

    printf '%s H:%s%%' "$temp_display" "$humidity"
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

    # Fetch weather from Open-Meteo
    local result
    result=$(weather_fetch_openmeteo "")

    # Cache and output
    cache_set "$WEATHER_CACHE_KEY" "$result"
    printf '%s' "$result"
}

load_plugin
