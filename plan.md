Plan: macOS Periodic Wallpaper Updater with Hammerspoon

Create a standalone Hammerspoon Lua module that automatically downloads, crops with random positioning, and sets wallpaper images on unlock and hourly intervals, using pure Lua with Hammerspoon APIs.

Steps
- Create wallpaper_updater.lua with construct_img_url(timestamp) function using os.time(), math for 10-minute subtraction and rounding, and string.format() for URL construction
- Implement image download with hs.http.asyncGet() saving to data/current.jpg, overwriting previous file on each successful download, with error logging but no retries
- Add cropping logic: read display dimensions via hs.screen:fullFrame(), calculate crop width for aspect ratio match, generate random x-offset with math.random(), and crop with hs.image:crop()
- Implement wallpaper setting for all displays by iterating hs.screen.allScreens() and calling screen:desktopImageURL() with file URL to data/current.jpg
- Set up event triggers using hs.caffeinate.watcher for unlock events and hs.timer.doEvery(3600) for hourly execution, both calling main update function
- Add logging with hs.logger to track downloads, crop calculations, wallpaper updates, and errors
- Create README.md with instructions to install Hammerspoon and add require("wallpaper_updater") to user's ~/.hammerspoon/init.lua, plus instructions to symlink or copy this module to Hammerspoon config directory