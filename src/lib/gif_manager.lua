local Utils = require('lib.utils')
local Logger = require('lib.logger')
local PositionalGif = require('lib.positional_gif')

---@class GifManager
---@field private camera_tf? REManagedObject
---@field private gifs PositionalGif[]
---@field private max_update_rate number
---@field private last_update_time? number
local GifManager = {}
GifManager.__index = GifManager

---@return GifManager
function GifManager.new()
  return setmetatable({
    camera_tf = nil,
    gifs = {},
    max_update_rate = 30,
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

  if self.last_update_time and now - self.last_update_time < 1 / self.max_update_rate then
    return
  end
  self.last_update_time = now

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
  if not self:_init() then
    Logger:log("warn", "Failed to init GifManager", "GifManager:render")
    return
  end

  local camera_pos = self.camera_tf:call("get_Position")
  for _, gif in ipairs(self.gifs) do
    gif:render(camera_pos)
  end
end

---@return nil
function GifManager:on_draw_ui()
  if not self:_init() then
    Logger:log("warn", "Failed to init GifManager", "GifManager:on_draw_ui")
    return
  end

  imgui.text("gif_manager:" .. Utils.dump(self, true))
end

return GifManager
