# Uetliberg Lockscreen - Hammerspoon Wallpaper Updater

Automatically downloads and sets a recent Uetliberg webcam image as your macOS wallpaper. Updates occur every hour and whenever you unlock your screen.

Generated almost entirely by Copilot. Use with care.

## Features

- **Automatic Updates**: Refreshes wallpaper hourly and on screen unlock
- **Smart Cropping**: Randomly crops images to fit your display(s)
- **Multi-Display Support**: Works with multiple monitors
- **Pure Lua**: Lightweight implementation using only Hammerspoon APIs
- **Logging**: Track downloads and updates via Hammerspoon console

## Prerequisites

- macOS (tested on recent versions)
- [Hammerspoon](https://www.hammerspoon.org/) installed

## Installation

### 1. Install Hammerspoon

If you haven't already:

```bash
brew install --cask hammerspoon
```

Or download directly from [hammerspoon.org](https://www.hammerspoon.org/)

### 2. Set Up the Module

You have two options:

#### Option A: Symlink (Recommended)

This keeps the module in your project directory while making it accessible to Hammerspoon:

```bash
# Create Hammerspoon config directory if it doesn't exist
mkdir -p ~/.hammerspoon

# Symlink the module
ln -s "/path/to/wallpaper_updater.lua" ~/.hammerspoon/wallpaper_updater.lua
```

#### Option B: Copy

```bash
cp wallpaper_updater.lua ~/.hammerspoon/
```

### 3. Configure Hammerspoon

Add the following line to your `~/.hammerspoon/init.lua` file:

```lua
require("wallpaper_updater")
```

If the file doesn't exist, create it:

```bash
echo 'require("wallpaper_updater")' > ~/.hammerspoon/init.lua
```

### 4. Reload Hammerspoon

Click the Hammerspoon menu bar icon and select "Reload Config", or press `⌘ + ⌥ + R` if you have the default key bindings.

## How It Works

1. **URL Construction**: Calculates the correct webcam image URL based on current time (rounded to 10-minute intervals)
2. **Download**: Fetches the image using `hs.http.asyncGet()`
3. **Crop**: Randomly crops the image to match your display's aspect ratio
4. **Set**: Updates wallpaper on all connected displays
5. **Schedule**: Repeats hourly and on screen unlock events

## Image Source

Images are sourced from the Uetliberg webcam in Zürich, Switzerland: [uetliberg.roundshot.com](https://uetliberg.roundshot.com/#/)

## Data Storage

Downloaded and cropped images are stored in:
```
~/.hammerspoon/wallpaper_data/
```

This directory is automatically created when the module initializes.

## Logging

View logs in the Hammerspoon console:
1. Click the Hammerspoon menu bar icon
2. Select "Console"
3. Look for entries prefixed with `wallpaper_updater`

## Troubleshooting

### Wallpaper not updating

1. Check Hammerspoon console for errors
2. Verify internet connectivity
3. Ensure the webcam URL is accessible
4. Check that `~/.hammerspoon/wallpaper_data/` directory exists and is writable

### Module not loading

1. Confirm `wallpaper_updater.lua` is in `~/.hammerspoon/`
2. Check `init.lua` contains `require("wallpaper_updater")`
3. Reload Hammerspoon configuration

### Permission Issues

Hammerspoon may need accessibility permissions:
1. Go to System Preferences → Security & Privacy → Privacy
2. Select "Accessibility" from the left sidebar
3. Ensure Hammerspoon is checked

## Customization

You can modify these variables in `wallpaper_updater.lua`:

- `IMAGE_URL_BASE`: Change the webcam source
- Update frequency: Modify the `3600` (seconds) in `hs.timer.doEvery(3600, ...)`
- Logging level: Change `'info'` to `'debug'`, `'warning'`, or `'error'` in `hs.logger.new()`

## Uninstallation

1. Remove the `require("wallpaper_updater")` line from `~/.hammerspoon/init.lua`
2. Delete the module: `rm ~/.hammerspoon/wallpaper_updater.lua`
3. Optionally delete cached images: `rm -rf ~/.hammerspoon/wallpaper_data/`
4. Reload Hammerspoon

## License

Free to use and modify as needed.

## Credits

Webcam images courtesy of [https://uetliberg.roundshot.com/#/](https://uetliberg.roundshot.com/#/)
