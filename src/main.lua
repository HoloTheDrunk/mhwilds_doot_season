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

local logs = {}

d2d.register(
  function()
    local frames = {}
    while true do
      local path = string.format("doot_season/frame_%02d.png", #frames)
      local image = d2d.Image.new(path)
      logs[#logs + 1] = { type = "info", msg = string.format("Loading frame %d from: %s", #frames, path) }
      if not image then
        logs[#logs + 1] = { type = "warn", msg = "FAILED" }
        break
      end
      frames[#frames + 1] = image
    end

    doot = {
      frames = frames,
      framerate = 6.6,
    }
  end,
  function()
    if not _initialized then return end

    gif_manager:render()
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

      gif_manager:instance(doot, pos)

      debug.hit_position = pos
    end
  )

  re.on_frame(function()
    gif_manager:update(os.clock())
    if debug.hit_position then
      local sp = draw.world_to_screen(debug.hit_position)
      if sp then
        draw.filled_circle(sp.x, sp.y, 25, 0xffffffff, 8)
      end
    end
  end)

  _initialized = true
end


re.on_draw_ui(function()
  if not imgui.tree_node("Doot") then return end

  if imgui.button("Flush logs") then
    for _, entry in ipairs(logs) do
      log[entry.type](entry.msg)
    end
    logs = {}
  end

  if not _initialized then
    local success, err = pcall(init)
    if not success then
      debug.error = err
    end
  end

  if debug.error then
    imgui.text_colored(debug.error, 0xffff0000)
  end

  imgui.tree_pop()
end)
