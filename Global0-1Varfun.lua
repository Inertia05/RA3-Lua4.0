GlobalSecond = 0

---@type KindOf[]
local includes = {
  [1] = "AIRCRAFT",
  [2] = "VEHICLE",
  [3] = "SHIP",
  [4] = "SUBMARINE",
  [5] = "STRUCTURE",
  [6] = "SIEGE_WEAPON",
  [7] = "TRANSFORMER",

}
---@type table<KindOf, ObjectFilter>
FilterKindOf = {}
local count = getn(includes)
for i = 1, count, 1 do
  local key = includes[i]
  FilterKindOf[key] = CreateObjectFilter({
    Rule="ANY",
    Include=key,
    IncludeThing={}
  })
end

---@class Visibility_objects_garbage_collection
local visibility_objects_garbage_collection = {
  size = 0,
  --- @type StandardUnitType[]
  objects = {},
  --- @type integer[]
  time_stamp = {},
  --- Rebuild visibility_objects_garbage_collection
  --- @param self Visibility_objects_garbage_collection
  _rebuild = function(self)
    local new_objects = {}
    local new_time_stamp = {}
    local new_size = 0
    for i = 1, self.size,1 do
      local obj = self.objects[i]
      local time = self.time_stamp[i]
      if time > (GlobalSecond - 2) and ObjectIsAlive(obj) then
        new_size = new_size + 1
        new_objects[new_size] = self.objects[i]
        new_time_stamp[new_size] = self.time_stamp[i]
      else
        if ObjectIsAlive(obj) then
          ObjectDelete_Slow(obj)
        end
      end
    end
    self.objects = new_objects
    self.time_stamp = new_time_stamp
    self.size = new_size
  end,

  ---Add a temp visibility object to the list
  ---@param self Visibility_objects_garbage_collection
  ---@param obj StandardUnitType
  _add = function(self, obj)
    self.size = self.size + 1
    self.objects[self.size] = obj
    self.time_stamp[self.size] = GlobalSecond
  end,
}

VisiblitySystem = {
  time = 0,
  current_dict = {},
  previous_dict = {},
  visibility_dict = {},
  garbage_collector = visibility_objects_garbage_collection,
  is_visible = function(self, unit, observer)
    local visible = self.visibility_dict[unit]
    if visible then
      return visible
    end
    --- visibility unknown for this second, start checking
    if ObjectIsStructure(unit) then
      visible = EvaluateCondition("NAMED_DISCOVERED", observer, unit)
      self.visibility_dict[unit] = visible
      return visible
    else
      local observed = self.previous_dict[unit]
      if observed then
        visible = EvaluateCondition("NAMED_DISCOVERED", observer, observed)
      else
        visible = EvaluateCondition("NAMED_DISCOVERED", observer, unit) -- only accurate if unit is not moving
        local visibility_obj = self:_spawn_visibility_obj(unit)
        self.current_dict[unit] = visibility_obj
      end
      self.visibility_dict[unit] = visible
      return visible
    end
  end,
  _spawn_visibility_obj = function(self, unit)
    local x, y, z = ObjectGetIntPosition(unit)
    local class_name = "DummyEngineer"
    local team = "/team"
    local current_instance_name = "TEMP-VISIBLE-" .. unit .. "-" .. GlobalSecond  -- Unique per second
    ObjectSpawnNamed_Slow(current_instance_name, class_name, team, x, y, z, 30)
    local current_instance = GetObjectByScriptName(current_instance_name)
    self.garbage_collector:_add(current_instance) -- Add to the list for garbage collection
    return current_instance
  end,

  update = function(self) --- This function should be called every second
    self.time = GlobalSecond
    self.previous_dict = self.current_dict
    self.current_dict = {}
    self.visibility_dict = {}
    if mod(self.time, 5) == 0 then
      self.garbage_collector:_rebuild()
    end
  end

}


--EvaluateCondition("NAMED_DISCOVERED", "<1st Human Player's Allies incl Self>", temp_name_stored)
--ExecuteAction("NAMED_DELETE", temp_name_stored)
--- This function check if a unit is sighted by the first human player and his allies
--- One should not call this function repeatedly on the same unit in the same frame
--- @param current StandardUnitType
--- @return boolean
function UnitSightedbyHumanPlayer_PVE_Slow(current)
  return VisiblitySystem:is_visible(current, "<1st Human Player's Allies incl Self>")
end

--- This function split an StandardUnitType array into two arrays based on a condition check on each StandardUnit object
--- @param array StandardUnitType[]
--- @param size integer
--- @param condition fun(current: StandardUnitType): boolean
--- @return StandardUnitType[], integer, StandardUnitType[], integer
function SplitArray(array, size, condition)
  local true_array = {}
  local false_array = {}
  local true_size = 0
  local false_size = 0
  for i = 1, size, 1 do
    local current = array[i]
    if condition(current) then
      true_size = true_size + 1
      true_array[true_size] = current
    else
      false_size = false_size + 1
      false_array[false_size] = current
    end
  end
  if (true_size + false_size) ~= size then
    _ALERT("SplitArray: Size mismatch")
    DEBUG_error("SplitArray: Size mismatch")
  end
  return true_array, true_size, false_array, false_size
end