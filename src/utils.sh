#!/usr/bin/env bash
# =============================================================================
# Utility Functions for tmux-tokyo-night
# =============================================================================

# -----------------------------------------------------------------------------
# Get tmux option value with fallback default
# Arguments:
#   $1 - Option name
#   $2 - Default value
# Output:
#   Option value or default
# -----------------------------------------------------------------------------
get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value

    option_value=$(tmux show -gqv "$option")

    if [[ -z "$option_value" ]]; then
        printf '%s' "$default_value"
    else
        printf '%s' "$option_value"
    fi
}

function generate_left_side_string() {
    local session_icon=$(get_tmux_option "@theme_session_icon" " ")
    local left_separator=$(get_tmux_option "@theme_left_separator" "")

    if [ "$transparent" = "true" ]; then
        printf '%s' "#[bg=default]#{?client_prefix,#[fg=${palette_yellow}],#[fg=${palette_green}]}${left_separator:?}#[none]#[fg=${palette_fg_gutter},bold]#{?client_prefix,#[bg=${palette_yellow}],#[bg=${palette_green}]} ${session_icon} #S #[bg=default]#{?client_prefix,#[fg=${palette_yellow}],#[fg=${palette_green}]}${left_separator:?}#[none]"
    else
        printf '%s' "#[fg=${palette_fg_gutter},bold]#{?client_prefix,#[bg=${palette_yellow}],#[bg=${palette_green}]} ${session_icon} #S #[bg=${palette_bg_highlight}]#{?client_prefix,#[fg=${palette_yellow}],#[fg=${palette_green}]}${left_separator:?}#[none]"
    fi
}

function generate_inactive_window_string() {
    local inactive_window_icon=$(get_tmux_option "@theme_plugin_inactive_window_icon" " ")
    local zoomed_window_icon=$(get_tmux_option "@theme_plugin_zoomed_window_icon" " ")
    local left_separator=$(get_tmux_option "@theme_left_separator" "")
    local inactive_window_title=$(get_tmux_option "@theme_inactive_window_title" "#W ")

    if [ "$transparent" = "true" ]; then
        local left_separator_inverse=$(get_tmux_option "@theme_transparent_left_separator_inverse" "")
        printf '%s' "#[bg=default,fg=${palette_dark5}]${left_separator_inverse}#[bg=${palette_dark5},fg=${palette_bg_highlight}]#[fg=${palette_white}]#I#[bg=${palette_dark3},fg=${palette_dark5}]${left_separator:?}#[none]#[fg=${palette_white}] #{?window_zoomed_flag,$zoomed_window_icon,$inactive_window_icon}${inactive_window_title}#[bg=default,fg=${palette_dark3}]${left_separator:?}#[none]"
    else
        printf '%s' "#[bg=${palette_dark5},fg=${palette_bg_highlight}]${left_separator:?}#[none]#[fg=${palette_white}]#I#[bg=${palette_dark3},fg=${palette_dark5}]${left_separator:?}#[none]#[fg=${palette_white}] #{?window_zoomed_flag,$zoomed_window_icon,$inactive_window_icon}${inactive_window_title}#[bg=${palette_bg_highlight},fg=${palette_dark3}]${left_separator:?}#[none]"
    fi
}

function generate_active_window_string() {
    local active_window_icon=$(get_tmux_option "@theme_plugin_active_window_icon" " ")
    local zoomed_window_icon=$(get_tmux_option "@theme_plugin_zoomed_window_icon" " ")
    local pane_synchronized_icon=$(get_tmux_option "@theme_plugin_pane_synchronized_icon" "✵")
    local left_separator=$(get_tmux_option "@theme_left_separator" "")
    local active_window_title=$(get_tmux_option "@theme_active_window_title" "#W ")

    if [ "$transparent" = "true" ]; then
        local left_separator_inverse=$(get_tmux_option "@theme_transparent_left_separator_inverse" "")
        printf '%s' "#[bg=default,fg=${palette_magenta}]${left_separator_inverse}#[bg=${palette_magenta},fg=${palette_bg_highlight}]#[fg=${palette_white}]#I#[bg=${palette_purple},fg=${palette_magenta}]${left_separator:?}#[none]#[fg=${palette_white}] #{?window_zoomed_flag,$zoomed_window_icon,$active_window_icon}${active_window_title}#{?pane_synchronized,$pane_synchronized_icon,}#[bg=default,fg=${palette_purple}]${left_separator:?}#[none]#[none]"
    else
        printf '%s' "#[bg=${palette_magenta},fg=${palette_bg_highlight}]${left_separator:?}#[none]#[fg=${palette_white}]#I#[bg=${palette_purple},fg=${palette_magenta}]${left_separator:?}#[none]#[fg=${palette_white}] #{?window_zoomed_flag,$zoomed_window_icon,$active_window_icon}${active_window_title}#{?pane_synchronized,$pane_synchronized_icon,}#[bg=${palette_bg_highlight},fg=${palette_purple}]${left_separator:?}#[none]#[none]"
    fi
}
