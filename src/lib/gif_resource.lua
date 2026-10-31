local Logger = require("lib.logger")

---@class GifResource
---@field frames Image[]
---@field framerate number
local GifResource = {}
GifResource.__index = GifResource

---Must be called from within the init_fn of d2d.register.
---@param path string Path to the folder containing the GIF frames.
---@param framerate number
---@return GifResource
function GifResource.from_folder(path, framerate)
  local frames = {}
  while true do
    local image_path = path .. string.format("/frame_%02d.png", #frames)
    local image = d2d.Image.new(image_path)
    if image then
      Logger:log("info", string.format("Loaded frame %d from: '%s'", #frames, image_path))
    else
      Logger:log("warn", string.format("Failed to load frame %d from: '%s'", #frames, image_path))
      break
    end
    frames[#frames + 1] = image
  end

  return setmetatable({
    frames = frames,
    framerate = framerate,
  } --[[@as GifResource]], GifResource)
end

return GifResource
