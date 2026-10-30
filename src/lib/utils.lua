local Utils = {}

---@return REManagedObject?
function Utils.get_camera_transform()
  local camera = sdk.get_primary_camera()
  if not camera then return nil end

  local obj = camera:call("get_GameObject")
  if not obj then return nil end

  local tf = obj:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
  if not tf then return nil end

  return tf
end

return Utils
