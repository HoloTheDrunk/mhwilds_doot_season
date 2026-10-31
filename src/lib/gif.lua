local Logger = require('lib.logger')

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
  if not self.resource then
    Logger:log("error", "Missing resource", "Gif:update")
    return true
  end

  if self.last_frame_time then
    Logger:log("debug", string.format("%f - %f > %f", now, self.last_frame_time, 1 / self.resource.framerate))
  end
  if not self.last_frame_time then
    self.last_frame_time = now
  elseif now - self.last_frame_time > 1 / self.resource.framerate then
    self.cur_frame = self.cur_frame + 1
    -- Drop gif when the last frame ends
    if self.cur_frame > #self.resource.frames then
      Logger:log("warn", "GIF end reached", "Gif:update")
      return true
    end
    self.last_frame_time = now
  end

  return false
end

---@param x number
---@param y number
---@param w number
---@param h number
---@return nil
function Gif:render(x, y, w, h)
  if not self.resource then
    Logger:log("error", "Missing resource", "Gif:render")
    return
  end

  local image = self.resource.frames[self.cur_frame]
  d2d.image(image, x, y, w, h)
end

return Gif
