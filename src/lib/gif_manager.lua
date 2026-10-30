local Utils = require('lib.utils')

---@class GifResource
---@field frames Image[]
---@field framerate number

---@class Gif
---@field resource GifResource
---@field cur_frame integer
---@field last_frame_time? number
local Gif = {}
Gif.__index = Gif

---@param resource GifResource
---@return Gif
function Gif.new(resource)
  return setmetatable({
    resource = resource,
    cur_frame = 0,
    last_frame_time = nil
  } --[[@as Gif]], Gif)
end

---@nodiscard
---@param now number
---@return boolean discard true means the gif needs to be dropped.
function Gif:update(now)
  if self.last_frame_time and now - self.last_frame_time > 1 / self.resource.framerate then
    self.cur_frame = self.cur_frame + 1
    -- Drop gif when the last frame ends
    if self.cur_frame > #self.resource.frames then
      return true
    end
  end
  self.last_frame_time = now
  return false
end

---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function Gif:render(x, y, w, h)
  local image = self.resource.frames[self.cur_frame]
  d2d.image(image, x, y, w, h)
end

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

PositionalGif.update = Gif.update

---@param camera_pos Vector3f
---@return nil
function PositionalGif:render(camera_pos)
  local screen_pos = draw.world_to_screen(self.position)
  if not screen_pos then return end

  local d = (camera_pos - self.position):length()
  local size = 100 / d ^ 2
  local hsize = size / 2

  self.gif:render(screen_pos.x - hsize, screen_pos.y - hsize, hsize, hsize)
end

---@class GifManager
---@field private camera_tf? REManagedObject
---@field private gifs PositionalGif[]
local GifManager = {}
GifManager.__index = GifManager

---@return GifManager
function GifManager.new()
  return setmetatable({
    camera_tf = nil,
    gifs = {},
  } --[[@as GifManager]], GifManager)
end

---@nodiscard
---@private
---@return boolean initialized
function GifManager:_init()
  if self.camera_tf then return true end

  local tf = Utils.get_camera_transform()
  if not tf then return false end

  self.camera_tf = tf
  return true
end

---@param resource GifResource
---@param position Vector3f
---@return nil
function GifManager:instance(resource, position)
  self.gifs[#self.gifs + 1] = PositionalGif.new(resource, position)
end

---@param now number
---@return nil
function GifManager:update(now)
  if not self:_init() then return end

  ---@type integer[]
  local to_remove = {}

  for i, gif in ipairs(self.gifs) do
    if gif:update(now) then
      to_remove[#to_remove + 1] = i
    end
  end

  for _, i in ipairs(to_remove) do
    table.remove(self.gifs, i)
  end
end

---@return nil
function GifManager:render()
  if not self:_init() then return end

  local camera_pos = self.camera_tf:call("get_Position")
  for _, gif in ipairs(self.gifs) do
    gif:render(camera_pos)
  end
end

return GifManager
