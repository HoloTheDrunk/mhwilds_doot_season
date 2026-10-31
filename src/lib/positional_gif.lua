local Gif = require("lib.gif")

---@class PositionalGif
---@field gif Gif
---@field position Vector3f
local PositionalGif = {}
PositionalGif.__index = PositionalGif

---@param resource GifResource
---@param position Vector3f
---@return PositionalGif
function PositionalGif.new(resource, position)
  return setmetatable({
    gif = Gif.new(resource),
    position = position
  } --[[@as PositionalGif]], PositionalGif)
end

---@param now number
---@return boolean discard true means the gif needs to be dropped.
function PositionalGif:update(now)
  return self.gif:update(now)
end

---@param camera_pos Vector3f
---@return nil
function PositionalGif:render(camera_pos)
  local screen_pos = draw.world_to_screen(self.position)
  if not screen_pos then return end

  local d = (camera_pos - self.position):length()
  local size = 100
  -- local size = 100
  local hsize = size / 2

  self.gif:render(screen_pos.x - hsize, screen_pos.y - hsize, size, size)

  -- self.gif:render(100, 100, 100, 100)
end

return PositionalGif
