GlobalSecond = 0

---@type KindOf[]
local includes = {
  [1] = "AIRCRAFT",
  [2] = "VEHICLE",
  [3] = "SHIP", --- 很多船只同时属于VEHICLE和SHIP
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

FilterEnemyKindOf = {}
local count = getn(includes)
for i = 1, count, 1 do
  local key = includes[i]
  FilterEnemyKindOf[key] = CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include=key,
    IncludeThing={}
  })
end


---@param x integer
---@param y integer
---@param z integer
---@param radius integer
---@param kindof KindOf
---@param iff_object StandardUnitType
---@return StandardUnitType[], integer
function Area_Enemy_Kindof_search(x, y, z, radius, kindof, iff_object)
  return ObjectFindObjects(iff_object, 
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  FilterEnemyKindOf[kindof])
end

function Unit_enemy_artillery_search(unit, range)
  local ref_object = unit
  local x, y, z = ObjectGetIntPosition(ref_object)
  local radius = range
  return ObjectFindObjects(ref_object, 
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  FilterEnemyKindOf["SIEGE_WEAPON"])
end

function Unit_enemy_search_surface_only(unit, range)
  local ref_object = unit
  local x, y, z = ObjectGetIntPosition(ref_object)
  local radius = range
  return Area_enemy_search_surface_only(x, y, z, radius, ref_object)
end


---@param unit StandardUnitType
---@param stance Stance
function ObjectSetStance_Slow(unit, stance)
  ExecuteAction("UNIT_SET_STANCE", unit, stance)
end

---@class DelayedStance
---@field time_stamp integer
---@field stance Stance

---@type table<UnitID, DelayedStance>
UnitStanceDict = {}

--- This function only check for Guard and Hold Position, other stances are considered as "OTHER"
---@param unit StandardUnitType
---@return Stance
function ObjectGetDelayedStance(unit)
  local unit_id = ObjectGetId(unit)
  if not unit_id then
    _ALERT("Unit ID is nil in ObjectGetDelayedStance")
    return "OTHER"
  end
  local delayed_stance = UnitStanceDict[unit_id]
  if delayed_stance then
    if GlobalSecond - delayed_stance.time_stamp <= 5 then
      return delayed_stance.stance
    end
  end
  local stance = "OTHER"
  if ObjectStanceIsGuard_Slow(unit) then
    stance = "GUARD"
  elseif ObjectStanceIsHoldPosition_Slow(unit) then
    stance = "HOLD_POSITION"
  end

  UnitStanceDict[unit_id] = {time_stamp=GlobalSecond, stance=stance}
  return stance
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
      if time > (GlobalSecond - 2) then
        if ObjectIsAlive(obj) then
          new_size = new_size + 1
          new_objects[new_size] = self.objects[i]
          new_time_stamp[new_size] = self.time_stamp[i]
        end
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
--- note false ~= nil is false
--- TODO- add visibility dict for each observer
--- @class VisiblitySystem
VisiblitySystem = {
  time = 0,
  current_dict = {},
  previous_dict = {},
  ---@type table<UnitID, boolean>
  visibility_dict = {},
  garbage_collector = visibility_objects_garbage_collection,

  ---@param self VisiblitySystem
  ---@param unit StandardUnitType
  ---@param observer Player
  is_visible = function(self, unit, observer)
    local unit_id = ObjectGetId(unit)
    if not unit_id then
      _ALERT("Unit ID is nil in VisiblitySystem:is_visible")
      return false
    end
    local visible = self.visibility_dict[unit_id]
    if visible then
      return visible
    end
    --- visibility unknown for this second, start checking
    if ObjectIsStructure(unit) then
      visible = EvaluateCondition("NAMED_DISCOVERED", observer, unit)
      self.visibility_dict[unit_id] = visible
      return visible
    else
      local observed = self.previous_dict[unit_id]
      if observed then
        visible = EvaluateCondition("NAMED_DISCOVERED", observer, observed)
      else
        visible = EvaluateCondition("NAMED_DISCOVERED", observer, unit) -- only accurate if unit is not moving
        if not self.current_dict[unit_id] then
          local visibility_obj = self:_spawn_visibility_obj(unit)
          self.current_dict[unit_id] = visibility_obj
        end
      end
      self.visibility_dict[unit_id] = visible
      return visible
    end
  end,
  ---@param unit StandardUnitType
  _spawn_visibility_obj = function(self, unit)
    local x, y, z = ObjectGetIntPosition(unit)
    local class_name = "DummyEngineer"
    local team = "/team"
    local id = ObjectGetId(unit)
    local current_instance_name = "TEMP-VISIBLE-" .. id .. "-" .. GlobalSecond  -- Unique per second
    local current_instance = GetObjectByScriptName(current_instance_name)
    if current_instance then
      _ALERT("Visibility object already exists")
      return current_instance
    end
    ObjectSpawnNamed_Slow(current_instance_name, class_name, team, x, y, z, 30)
    current_instance = GetObjectByScriptName(current_instance_name)
    self.garbage_collector:_add(current_instance) -- Add to the list for garbage collection
    return current_instance
  end,

  ---@param self VisiblitySystem
  update = function(self) --- This function should be called every second
    self.time = GlobalSecond
    self.previous_dict = self.current_dict
    self.current_dict = {}
    self.visibility_dict = {}
    if tolerant_int_mod(self.time, 5) == 0 then
      self.garbage_collector:_rebuild()
    end
  end

}

function ObjectCalculateIntSpeed(object)
  local x, y, z = ObjectGetPosition(object)
  local px, py, pz = ObjectGetPreviousPosition(object)
  if not px or not py or not pz then
    return 0
  end
  local dx = (x - px)*15
  local dy = (y - py)*15
  local dz = (z - pz)*15
  return tolerant_floor(tolerant_floor(sqrt(dx * dx + dy * dy + dz * dz))/2)
end

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

---@param player Player ex: "PlyrCreeps" | "PlyrCivilian"
---@param team string ex: "teamPlyrCreeps" | "teamPlyrCivilian" | "JapanWarFactoryT2"
---@param unit_class_name AlliedAirUnitName | AlliedGroundUnitName | AlliedNavalUnitName
function TeamUseAbility(player, team, unit_class_name)
  local team = player .. "/" .. team
  local ability = "Command_Construct"..unit_class_name
  ExecuteAction("TEAM_USE_COMMANDBUTTON_ABILITY", team, ability)
end


---@param object StandardUnitType
---@param target StandardUnitType
function ObjectGarrisonObjectInstantly(object, target)
  local id = ObjectGetId(target)
  ExecuteAction("SET_UNIT_REFERENCE", id, target)
  ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", object, id)
end




