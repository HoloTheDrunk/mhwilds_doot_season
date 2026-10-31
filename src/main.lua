local Utils = require("lib.utils")

local Logger = require("lib.logger")
Logger:set_name("doot_season")

local GifResource = require("lib.gif_resource")

local GifManager = require("lib.gif_manager")
local gif_manager = GifManager.new()

local horn_handling = sdk.find_type_definition("app.cHunterWp05Handling")
local horn_attack_hook = horn_handling and horn_handling:get_method("doOnHit_AttackPre")

---@type GifResource?
local doot = nil

---@type REManagedObject?
local hunter_character = nil

local _initialized = false
local debug = { enabled = true }

d2d.register(
  function()
    doot = GifResource.from_folder("doot_season", 6.6)
  end,
  function()
    if not _initialized then return end

    local success, err = pcall(gif_manager.render, gif_manager)
    if not success then
      Logger:log("error", err or "Unknown error", "GifManager:render")
    end
  end
)

local function init()
  if not horn_attack_hook then return end
  if not doot then return end

  local player_mgr = sdk.get_managed_singleton("app.PlayerManager")
  local player = player_mgr and player_mgr:call("getMasterPlayer") --[[@as REManagedObject?]]
  hunter_character = player and player:call("get_Character") --[[@as REManagedObject?]]

  if not hunter_character then return end

  sdk.hook(
    horn_attack_hook,
    function(args)
      local this = sdk.to_managed_object(args[2])
      if not this then return end
      if this:call("get_Hunter") ~= hunter_character then return end

      local hit_info = sdk.to_managed_object(args[3])
      if not hit_info then return end

      local pos = hit_info:call("get_Position")

      Logger:log("debug", "Hit", "horn_attack_hook")

      gif_manager:instance(doot, pos)

      debug.hit_position = pos
    end
  )

  re.on_frame(function()
    gif_manager:update(os.clock())
    -- if debug.hit_position then
    --   local sp = draw.world_to_screen(debug.hit_position)
    --   if sp then
    --     draw.filled_circle(sp.x, sp.y, 10, 0xffffffff, 32)
    --   end
    -- end
  end)

  _initialized = true
end


re.on_draw_ui(function()
  if not imgui.tree_node("Doot") then return end

  if imgui.button("Flush logs to console") then
    Logger:flush()
  end

  if not _initialized then
    local success, err = pcall(init)
    if not success then
      debug.error = err
    end
  end

  local last_error = d2d.detail.get_last_error()
  if last_error ~= "" then
    imgui.text("Last D2D Error:")
    imgui.text_colored(last_error, 0xFF0000FF)
  end

  if debug.error then
    imgui.text("Last Script Error:")
    imgui.text_colored(debug.error, 0xffff0000)
  end

  if doot then
    imgui.text("Doot:" .. Utils.dump(doot, true))
  end

  gif_manager:on_draw_ui()

  Logger:on_draw_ui()

  imgui.tree_pop()
end)
