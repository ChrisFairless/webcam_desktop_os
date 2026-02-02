-- Wallpaper Updater for Hammerspoon
-- Automatically downloads, crops, and sets wallpaper images on unlock and hourly

local logger = hs.logger.new('wallpaper_updater', 'info')

-- Module table
local M = {}

-- Configuration
local IMAGE_URL_BASE = "https://storage2.roundshot.com/53aacd05e65407.10715840/"
local DATA_DIR = hs.configdir .. "/wallpaper_data"

-- Create data directory if it doesn't exist
hs.fs.mkdir(DATA_DIR)

-- Extract filename from URL
local function get_filename_from_url(url)
    return url:match("([^/]+)$")
end

-- Get full path for a given URL
local function get_full_path_from_url(url)
    local filename = get_filename_from_url(url)
    return DATA_DIR .. "/" .. filename
end

-- Check if file exists
local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Clean up old image files, keeping only the specified file
local function cleanup_old_files(keep_path)
    local keep_filename = keep_path:match("([^/]+)$")
    logger.i("Cleaning up old files, keeping: " .. keep_filename)
    
    local files_iter, dir_obj = hs.fs.dir(DATA_DIR)
    if not files_iter then
        logger.w("Could not open directory for cleanup: " .. DATA_DIR)
        return
    end
    
    for file in files_iter, dir_obj do
        if file ~= "." and file ~= ".." and file ~= keep_filename and not file:match("^current") then
            local full_path = DATA_DIR .. "/" .. file
            local success = os.remove(full_path)
            if success then
                logger.i("Removed old file: " .. file)
            else
                logger.w("Failed to remove: " .. file)
            end
        end
    end
end

-- Construct image URL for a given timestamp
-- Rounds down to nearest 20 minutes and subtracts 7 minutes (image interval is 10 minutes by day and 20 by night)
local function construct_img_url(timestamp)
    -- Subtract 7 minutes (420 seconds)
    local adjusted_time = timestamp - 420
    
    -- Round down to nearest 20 minutes
    local rounded_time = math.floor(adjusted_time / 1200) * 1200
    
    -- Format timestamp as date components
    local date_table = os.date("*t", rounded_time)
    
    -- Construct URL in format: YYYY/MM/DD/HHmm_hu.jpg
    local url = string.format("%s%04d-%02d-%02d/%02d-%02d-00/%04d-%02d-%02d-%02d-%02d-00_full.jpg",
        IMAGE_URL_BASE,
        date_table.year,
        date_table.month,
        date_table.day,
        date_table.hour,
        date_table.min,
        date_table.year,
        date_table.month,
        date_table.day,
        date_table.hour,
        date_table.min
    )
    
    return url
end

-- Download image from URL
local function download_image(url, callback)
    local file_path = get_full_path_from_url(url)
    local filename = get_filename_from_url(url)
    
    -- Check if file already exists
    if file_exists(file_path) then
        logger.i("Image already exists: " .. filename)
        if callback then callback(true, file_path) end
        return
    end
    
    logger.i("Downloading image from: " .. url)
    
    hs.http.asyncGet(url, nil, function(status, body, headers)
        if status == 200 and body then
            -- Write image data to file
            local file = io.open(file_path, "wb")
            if file then
                file:write(body)
                file:close()
                logger.i("Image downloaded successfully: " .. filename)
                
                -- Clean up old files after successful download
                cleanup_old_files(file_path)
                
                if callback then callback(true, file_path) end
            else
                logger.e("Failed to write image file")
                if callback then callback(false, nil) end
            end
        else
            logger.e("Failed to download image. Status: " .. tostring(status))
            if callback then callback(false, nil) end
        end
    end)
end

-- Crop image with random x-offset to match display aspect ratio
local function crop_and_set_wallpaper(image_path)
    -- Load the image
    local image = hs.image.imageFromPath(image_path)
    if not image then
        logger.e("Failed to load image from: " .. image_path)
        return false
    end
    
    local image_size = image:size()
    logger.i(string.format("Original image size: %.0fx%.0f", image_size.w, image_size.h))
    
    -- Get all screens and process each
    local screens = hs.screen.allScreens()
    for _, screen in ipairs(screens) do
        local screen_frame = screen:fullFrame()
        local screen_aspect = screen_frame.w / screen_frame.h
        
        logger.i(string.format("Screen: %s (%.0fx%.0f, aspect: %.2f)",
            screen:name(), screen_frame.w, screen_frame.h, screen_aspect))
        
        -- Calculate crop dimensions to match screen aspect ratio
        local crop_height = image_size.h
        local crop_width = crop_height * screen_aspect
        
        -- Ensure crop width doesn't exceed image width
        if crop_width > image_size.w then
            crop_width = image_size.w
            crop_height = crop_width / screen_aspect
        end
        
        -- Generate random x-offset (ensure crop stays within image bounds)
        local max_x_offset = image_size.w - crop_width
        local x_offset = math.random(0, math.floor(max_x_offset))
        
        -- Center crop vertically
        local y_offset = (image_size.h - crop_height) / 2
        
        logger.i(string.format("Crop: offset=(%.0f,%.0f) size=(%.0fx%.0f)",
            x_offset, y_offset, crop_width, crop_height))
        
        -- Create cropped image
        local crop_rect = {
            x = x_offset,
            y = y_offset,
            w = crop_width,
            h = crop_height
        }
        
        local cropped_image = image:croppedCopy(crop_rect)
        
        -- Save cropped image temporarily
        local cropped_path = DATA_DIR .. "/current_cropped_" .. screen:getUUID() .. ".jpg"
        local save_success =cropped_image:saveToFile(cropped_path)
        
        -- Set as wallpaper
        if not save_success then
            logger.e("Failed to save cropped image for screen: " .. screen:name())
        else
            -- Set as wallpaper with verification
            local success = screen:desktopImageURL("file://" .. cropped_path)
            if success then
                logger.i("New wallpaper set for screen: " .. screen:name())
            else
                logger.e("Failed to set new wallpaper for screen: " .. screen:name())
            end
        end
    end
    
    return true
end

-- Main update function
local function update_wallpaper()
    logger.i("=== Starting wallpaper update ===")
    
    -- Get current time in Zürich timezone
    local zurich_tz = hs.execute("TZ='Europe/Zurich' date +%s"):gsub("%s+", "")
    local current_time = tonumber(zurich_tz)
    local url = construct_img_url(current_time)
    
    download_image(url, function(success, file_path)
        if success and file_path then
            -- Small delay to ensure file is written
            hs.timer.doAfter(1.5, function()
                crop_and_set_wallpaper(file_path)
            end)
        else
            logger.e("Wallpaper update failed")
        end
    end)
end

-- Set up unlock watcher
local function setup_unlock_watcher()
    M.caffeinate_watcher = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.screensDidUnlock then
            logger.i("Screen unlocked - triggering wallpaper update")
            update_wallpaper()
        end
    end)
    M.caffeinate_watcher:start()
    logger.i("Unlock watcher started")
end

-- Set up hourly timer
local function setup_hourly_timer()
    M.hourly_timer = hs.timer.doEvery(3600, function()
        logger.i("Hourly timer triggered")
        update_wallpaper()
    end)
    logger.i("Hourly timer started")
end

-- Initialize the module
function M.init()
    logger.i("Initializing Wallpaper Updater")
    
    -- Set up watchers and timers
    setup_unlock_watcher()
    setup_hourly_timer()
    
    -- Do initial update
    update_wallpaper()
    
    logger.i("Wallpaper Updater initialized successfully")
end

-- Cleanup function
function M.stop()
    if M.caffeinate_watcher then
        M.caffeinate_watcher:stop()
    end
    if M.hourly_timer then
        M.hourly_timer:stop()
    end
    logger.i("Wallpaper Updater stopped")
end

-- Auto-initialize when module is loaded
M.init()

return M
