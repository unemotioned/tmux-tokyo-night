<div align="center">
  <h1>🌃 Tokyo Night Tmux Theme</h1>

  <h4>A clean, elegant tmux theme inspired by the popular Tokyo Night color scheme</h4>

  <p>
    <a href="#features"><img src="https://img.shields.io/badge/Features-blue?style=flat-square" alt="Features"></a>
    <a href="#screenshots"><img src="https://img.shields.io/badge/Screenshots-purple?style=flat-square" alt="Screenshots"></a>
    <a href="#installation"><img src="https://img.shields.io/badge/Install-green?style=flat-square" alt="Install"></a>
    <a href="#configuration"><img src="https://img.shields.io/badge/Config-orange?style=flat-square" alt="Configuration"></a>
    <a href="#plugins"><img src="https://img.shields.io/badge/Plugins-red?style=flat-square" alt="Plugins"></a>
  </p>

> A minimal tmux theme with Tokyo Night Storm colors and weather plugin.

---

</div>

## ✨ Features

- 🎨 **Tokyo Night Storm** color scheme
- 🌤️ **Weather plugin** using Open-Meteo API (free, no API key required)
- 🪟 **Transparency support** with customizable separators
- 📊 **Double bar layout** option for separating windows and plugins
- ⚡ **Smart caching system** for improved performance (configurable TTL)

## 📸 Screenshots

### Tokyo Night - Default Variation

| Inactive                                          | Active                                                 |
| ------------------------------------------------- | ------------------------------------------------------ |
| ![Tokyo Night Inactive](./assets/tokyo-night.png) | ![Tokyo Night Active](./assets/tokyo-night-active.png) |

## 📦 Installation

### Using TPM (recommended)

Add the plugin to your `~/.tmux.conf`:

```bash
set -g @plugin 'fabioluciano/tmux-tokyo-night'
```

Press <kbd>prefix</kbd> + <kbd>I</kbd> to install.

### Manual Installation

```bash
git clone https://github.com/fabioluciano/tmux-tokyo-night.git ~/.tmux/plugins/tmux-tokyo-night
```

Add to your `~/.tmux.conf`:

```bash
run-shell ~/.tmux/plugins/tmux-tokyo-night/tmux-tokyo-night.tmux
```

## ⚙️ Configuration

### Theme Options

| Option                          | Description                               | Values                          | Default            |
| ------------------------------- | ----------------------------------------- | ------------------------------- | ------------------ |
| `@theme_plugins`                | Comma-separated list of plugins to enable | `weather`                      | `weather`          |
| `@theme_disable_plugins`        | Disable all plugins                       | `0`, `1`                        | `0`                |
| `@theme_bar_layout`             | Status bar layout mode                    | `single`, `double`              | `single`           |
| `@theme_transparent_status_bar` | Enable transparency                       | `true`, `false`                 | `false`            |

### Appearance Options

| Option                              | Description                     | Default   |
| ----------------------------------- | ------------------------------- | --------- |
| `@theme_active_pane_border_style`   | Active pane border color        | `#737aa2` |
| `@theme_inactive_pane_border_style` | Inactive pane border color      | `#292e42` |
| `@theme_left_separator`             | Left powerline separator        | ``        |
| `@theme_right_separator`            | Right powerline separator       | ``        |
| `@theme_window_with_activity_style` | Style for windows with activity | `italics` |
| `@theme_status_bell_style`          | Style for bell alerts           | `bold`    |

### Transparency Options

When `@theme_transparent_status_bar` is enabled:

| Option                                       | Description                              | Default |
| -------------------------------------------- | ---------------------------------------- | ------- |
| `@theme_transparent_left_separator_inverse`  | Inverse left separator for transparency  | ``      |
| `@theme_transparent_right_separator_inverse` | Inverse right separator for transparency | ``      |

### Bar Layout

The `@theme_bar_layout` option controls how the status bar is displayed:

- **`single`** (default): Traditional single status bar with session, windows, and plugins
- **`double`**: Two status lines - one for session/windows, another for plugins

```bash
# Enable double bar layout
set -g @theme_bar_layout 'double'
```

### Available Colors

You can use these colors for any `accent_color` or `accent_color_icon` option:

| Color          | Hex       | Color    | Hex       |
| -------------- | --------- | -------- | --------- |
| `bg`           | `#1a1b26` | `blue`   | `#7aa2f7` |
| `bg_dark`      | `#16161e` | `blue0`  | `#3d59a1` |
| `bg_highlight` | `#292e42` | `blue1`  | `#2ac3de` |
| `fg`           | `#c0caf5` | `blue2`  | `#0db9d7` |
| `fg_dark`      | `#a9b1d6` | `cyan`   | `#7dcfff` |
| `red`          | `#f7768e` | `green`  | `#9ece6a` |
| `red1`         | `#db4b4b` | `green1` | `#73daca` |
| `orange`       | `#ff9e64` | `green2` | `#41a6b5` |
| `yellow`       | `#e0af68` | `teal`   | `#1abc9c` |
| `magenta`      | `#bb9af7` | `purple` | `#9d7cd8` |
| `magenta2`     | `#ff007c` | `white`  | `#ffffff` |

---

## 🔌 Plugins

Enable plugins by adding them to the `@theme_plugins` option:

```bash
set -g @theme_plugins 'weather'
```

### Weather

Displays current weather information using Open-Meteo API. Requires `curl` and `jq`.

| Option                                    | Description                                             | Default       |
| ----------------------------------------- | ------------------------------------------------------- | ------------- |
| `@theme_plugin_weather_icon`              | Plugin icon                                             | ` `           |
| `@theme_plugin_weather_accent_color`      | Background color                                        | `blue7`       |
| `@theme_plugin_weather_accent_color_icon` | Icon background color                                   | `blue0`       |
| `@theme_plugin_weather_unit`              | Unit system: `u` (Fahrenheit), empty (Celsius)          | Celsius       |
| `@theme_plugin_weather_cache_ttl`         | Cache TTL in seconds                                    | `900`         |

---

## 📋 Example Configuration

```bash
# ~/.tmux.conf

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'fabioluciano/tmux-tokyo-night'

# Tokyo Night Theme Configuration
set -g @theme_plugins 'weather'

# Initialize TPM (keep this at the bottom)
run '~/.tmux/plugins/tpm/tpm'
```

## 🎨 Transparency Example

Enable transparency with custom separators:

```bash
# Enable transparency
set -g @theme_transparent_status_bar 'true'

# Optional: Custom separators for transparency
set -g @theme_left_separator ''
set -g @theme_right_separator ''
set -g @theme_transparent_left_separator_inverse ''
set -g @theme_transparent_right_separator_inverse ''
```

![Transparency Example](https://github.com/user-attachments/assets/56287ccb-9be9-4aa5-a2ab-ec48d2b2d08a)

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features or plugins
- Submit pull requests

---

## 🗂️ Cache Management

Weather data is cached to reduce API calls. Clear the cache if you experience issues:

```bash
rm -rf ~/.cache/tmux-tokyo-night/
```

| Plugin  | Option                            | Default        |
| ------- | --------------------------------- | -------------- |
| Weather | `@theme_plugin_weather_cache_ttl` | `900` (15 min) |

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

<div align="center">
  <p>Made with ❤️ by <a href="https://github.com/fabioluciano">Fábio Luciano</a></p>
</div>
