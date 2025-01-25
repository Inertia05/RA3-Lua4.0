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
  [8] = "FS_BASE_DEFENSE",
  [9] = "INFANTRY",
  [10] = "SELECTABLE"   --  AIRCRAFT INFANTRY SHIP SUBMARINE VEHICLE"

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

Filter = {
  Unit = CreateObjectFilter({
    Rule="ANY",
    Exclude="STRUCTURE",
    Include="SELECTABLE",
    IncludeThing={}
  }),
  AlliedAirfield = CreateObjectFilter({IncludeThing = {"AlliedAirfield",}}),
  CelestialAirfield = CreateObjectFilter({IncludeThing = {"CelestialAirfield",}}),
  SovietAirfield = CreateObjectFilter({IncludeThing = {"SovietAirfield",}}),
  Airfield = CreateObjectFilter({IncludeThing = {"AlliedAirfield","CelestialAirfield","SovietAirfield",}}),
  Navalyard = CreateObjectFilter({IncludeThing = {"AlliedNavalYard","CelestialNavalYard","JapanNavalYard","SovietNavalYard",}}),
  Warfactory = CreateObjectFilter({IncludeThing = {"AlliedWarFactory","CelestialWarFactory","JapanWarFactory","SovietWarFactory",}}),
  AlliedProduction = CreateObjectFilter({IncludeThing = {"AlliedWarFactory","AlliedNavalYard","AlliedAirfield",}}),
  CelestialProduction = CreateObjectFilter({IncludeThing = {"CelestialWarFactory","CelestialNavalYard","CelestialAirfield",}}),
  JapanProduction = CreateObjectFilter({IncludeThing = {"JapanWarFactory","JapanNavalYard",}}),
  SovietProduction = CreateObjectFilter({IncludeThing = {"SovietWarFactory","SovietNavalYard","SovietAirfield",}}),
}






---@class FilterObjectStatus
---@field createStatusFilter fun(status: ObjectStatus): ObjectFilter
---@field createStatusFilterExclude fun(status: ObjectStatus): ObjectFilter
---@field getFilter fun(status: ObjectStatus): ObjectFilter
---@field getFilterExclude fun(status: ObjectStatus): ObjectFilter


---@type FilterObjectStatus
FilterObjectStatus = {
  createStatusFilter = function(status)
    return CreateObjectFilter({
      Rule="ALL",
      IncludeThing={},
      StatusBitFlags = status,
    })
  end,
  createStatusFilterExclude = function(status)
    return CreateObjectFilter({
      Rule="ALL",
      IncludeThing={},
      StatusBitFlagsExclude = status,
    })
  end,
  getFilter = function(_) return CreateObjectFilter({IncludeThing={}}) end,
  getFilterExclude = function(_) return CreateObjectFilter({IncludeThing={}}) end,
}


function FilterObjectStatus.getFilter(status)
  local filter = FilterObjectStatus[status]
  if not filter then
    if status then
      error("FilterObjectStatus.getFilter: Invalid status = "..status)
    else
      error("FilterObjectStatus.getFilter: status is nil")
    end
  end
  return filter
end

function FilterObjectStatus.getFilterExclude(status)
  local filter = FilterObjectStatus["NOT_"..status]
  if not filter then
    if status then
      error("FilterObjectStatus.getFilterExclude: Invalid status = "..status)
    else
      error("FilterObjectStatus.getFilterExclude: status is nil")
    end
  end
  return filter
end

--- @type ObjectStatus[]
local objectStatusList = {
  "IMMOBILE","IGNORE_AI_COMMAND","REPAIR_ALLIES_WHEN_IDLE","CLEARED_FOR_LANDING","WATER_LOCOMOTOR_ACTIVE",
  "IS_FIRING_WEAPON","IS_RELOADING_WEAPON","UNSELECTABLE","WEAPON_UPGRADED_03","NO_AUTO_ACQUIRE",
  "WEAPON_UPGRADED_01","WEAPON_UPGRADED_02",
  "AIRBORNE_TARGET",
  "HIJACKED",
  "STEALTHED",
  "NO_COLLISIONS","OVERCHARGING_WEAPON",
  "SUBMERGED",
  "SHROUD_REVEAL_TO_ALL",
  "SPECIALABILITY_ACTIVE",
  "DAMAGED",
  "REALLYDAMAGED",
  "HAS_SECONDARY_DAMAGE",
  "OVER_WATER",
  "POINT_DEFENSE_DRONE_ATTACHED",
}

for i = 1, getn(objectStatusList), 1 do
  local status = objectStatusList[i]
  FilterObjectStatus[status] = FilterObjectStatus.createStatusFilter(status)
  FilterObjectStatus["NOT_"..status] = FilterObjectStatus.createStatusFilterExclude(status)
end


---@param x integer
---@param y integer
---@param z integer
---@param radius integer
---@param kindof KindOf
---@param iff_object StandardUnitType
---@return StandardUnitType[], integer
function Area_Enemy_Kindof_search(x, y, z, radius, kindof, iff_object)
  local area = {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}
  return Area_filter_search(area, FilterEnemyKindOf[kindof], iff_object)

end

---@param unit StandardUnitType
---@param radius integer
---@param filter ObjectFilter
---@return StandardUnitType[], integer
function Unit_surrounding_search(unit, radius, filter)
  local ref_object = unit
  local x, y, z = ObjectGetIntPosition(ref_object)
  local area = {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}
  local matchedObjects, count = ObjectFindObjects(ref_object, area, filter)
  if type(count)~="number" or type(matchedObjects)~="table" then
    _ALERT("Unit_surrounding_search: Error in ObjectFindObjects")
    return {}, 0
  end
  return matchedObjects, count
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


--- 2500 ns per call
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
    if GlobalSecond - delayed_stance.time_stamp <= 1 then
      return delayed_stance.stance
    end
  end
  local stance = "OTHER"
  if ObjectStanceIsGuard_Slow(unit) then
    stance = "GUARD"
  elseif ObjectStanceIsHoldPosition_Slow(unit) then
    stance = "HOLD_POSITION"
  end

  UnitStanceDict[unit_id] = {time_stamp = GlobalSecond, stance=stance}
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
    if Object.isStructure(unit) then
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


---@param object StandardUnitType
---@param target StandardUnitType
function ObjectGarrisonObjectInstantly(object, target)
  local id = ObjectGetId(target)
  ExecuteAction("SET_UNIT_REFERENCE", id, target)
  ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", object, id)
end


--- @class SpatialGroup:Group
--- @field size integer
--- @field center Coordinate
--- @field radius integer
--- @field members StandardUnitType[]
--- @field is_damaged boolean
--- @field is_idle boolean
--- @field is_idle_known boolean

--- This function group units based on their spatial proximity
--- @param unit_list StandardUnitType[]
--- @param list_size integer
--- @param max_radius integer
--- @param friendly_filter ObjectFilter
--- @return SpatialGroup[], integer
function FormSpatialGroups(unit_list, list_size, max_radius, friendly_filter)
  local groups = {}
  local groups_count = 0
  local grouped_dict = {}
  for unit_index = 1, list_size, 1 do
    local current_unit = unit_list[unit_index]
    local unit_id = ObjectGetId(current_unit)
    if grouped_dict[unit_id] or not ObjectIsAlive(current_unit) then
      --- already grouped or dead, skip
    else
      local x, y, z = ObjectGetIntPosition(current_unit)
      --- @type SpatialGroup
      local group = {
        size = 0,
        center = {X=0, Y=0, Z=0},
        radius = 10,
        members = {},
        is_damaged = false,
        is_idle = false,
        is_idle_known = false
      }
      local area = {X=x, Y=y, Z=z, Radius=max_radius, DistType="CENTER_2D"}
      local matched_friendly, matched_friendly_count = Area_filter_search(area, friendly_filter, current_unit)
      --- this search will return the current unit itself
      if matched_friendly_count > 0 then
        local total_x, total_y, total_z = 0, 0, 0
        for friendly_index = 1, matched_friendly_count, 1 do
          local friendly_unit = matched_friendly[friendly_index]
          local friendly_unit_id = ObjectGetId(friendly_unit)
          if friendly_unit_id and ObjectIsAlive(friendly_unit) and not grouped_dict[friendly_unit_id] then
            group.size = group.size + 1
            group.members[group.size] = friendly_unit
            grouped_dict[friendly_unit_id] = true
            local fx, fy, fz = ObjectGetIntPosition(friendly_unit)
            total_x = total_x + fx
            total_y = total_y + fy
            total_z = total_z + fz
            if ObjectIsDamaged(friendly_unit) then
              group.is_damaged = true
            end
          end
        end
        if group.size > 0 then
          group.center.X = tolerant_floor(total_x/group.size)
          group.center.Y = tolerant_floor(total_y/group.size)
          group.center.Z = tolerant_floor(total_z/group.size)
        end
        local radius_sqr = 0
        for friendly_index = 1, group.size, 1 do
          local fx, fy, fz = ObjectGetIntPosition(group.members[friendly_index])
          local distanceSqr = (fx - group.center.X)^2 + (fy - group.center.Y)^2 + (fz - group.center.Z)^2
          if distanceSqr > radius_sqr then
            radius_sqr = distanceSqr
          end
        end
        group.radius = tolerant_floor(sqrt(radius_sqr)) + 50
  
        groups_count = groups_count + 1
        groups[groups_count] = group
      end
      
    end
  end
  return groups, groups_count
end


---Cost = 1.5-2 us per call
---@param unit StandardUnitType
---@param disable_type "UNDERPOWERED"|"EMP"
---@param disabled boolean
function UnitSetDisabled_Slow(unit, disable_type, disabled)
  ExecuteAction("NAMED_SET_DISABLED", unit, disable_type, disabled)
end


--- @class Group
--- @field size integer
--- @field members StandardUnitType[]

Group = {}

--- 单纯处理每个成员的方法
---@param group Group
---@param processFunction fun(member: StandardUnitType)
function Group.forEachMember(group, processFunction)
    for index = 1, group.size, 1 do
        local member = group.members[index]
        if ObjectIsAlive(member) then
            processFunction(member)
        end
    end
end

--- 对每个成员处理并返回布尔值的方法
---@param group Group
---@param checkFunction fun(member: StandardUnitType): boolean
function Group.anyMemberMatches(group, checkFunction)
    for index = 1, group.size do
        local member = group.members[index]
        if ObjectIsAlive(member) and checkFunction(member) then
            return true  -- 如果有成员满足条件，返回 true
        end
    end
    return false  -- 如果没有成员满足条件，返回 false
end



Object = {
  player_list = {
    Player_1 = true,
    Player_2 = true,
    Player_3 = true,
    Player_4 = true,
    Player_5 = true,
    Player_6 = true,
  }
}
---@param object StandardUnitType
---@return boolean
function Object.belongToMapAI(object)
  return  ObjectPlayerScriptName(object) == "PlyrCivilian" or ObjectPlayerScriptName(object) == "PlyrCreeps"
end

function Object.belongToMapPlayer(object)
  local player_name = ObjectPlayerScriptName(object)
  if player_name then
    return Object.player_list[player_name]
  end
  return false
end

function Object.isUnit(object)
  return ObjectTestTargetObjectWithFilter(nil, object, Filter.Unit)
end

--- Checks if the object is structure
--- @param object StandardUnitType The object to check.
--- @return boolean True if the object is structure, false otherwise.
function Object.isStructure(object)
  return ObjectIsKindOf(object, "STRUCTURE")
end


---@param object StandardUnitType
---@param nation_code "A"|"C"|"S"|nil
---@return boolean
function Object.isStructureAirfield(object, nation_code)
  if not nation_code then
    return ObjectTestTargetObjectWithFilter(nil, object, Filter.Airfield)
  else 
    if nation_code == "A" then
      return ObjectTestTargetObjectWithFilter(nil, object, Filter.AlliedAirfield)
    elseif nation_code == "C" then
      return ObjectTestTargetObjectWithFilter(nil, object, Filter.CelestialAirfield)
    elseif nation_code == "S" then
      return ObjectTestTargetObjectWithFilter(nil, object, Filter.SovietAirfield)
    end
    _ALERT("Object.isStructureAirfield: Invalid nation code = "..nation_code)
    return false
  end
end


--- @param object StandardUnitType
--- @param upgrade Upgrade 
--- @return boolean
function Object.hasUpgrade(object, upgrade)
  return EvaluateCondition("UNIT_HAS_UPGRADE", object, upgrade)
end

function Object.expUpgrade(unit)
  if not Object.isUnit(unit) then
    _ALERT("Object.expUpgrade: target is not a unit")
    return
  end
  ExecuteAction("UNIT_GAIN_LEVEL", unit, false) --- false means not show level up effect
end

Object.CreatedUnitClassCollections = {
  count = 0,
  repeat_creation_check = {}
}

---@param class_name string
---@return UnitClassCollection
function Object.CreateUnitClassCollection(class_name)
  if not class_name then
    error("Object.CreateUnitClassCollection: class_name is nil")
  end
  if Object.CreatedUnitClassCollections.repeat_creation_check[class_name] then
    error("Object.CreateUnitClassCollection: Collection already created for "..class_name)
  end
  Object.CreatedUnitClassCollections.repeat_creation_check[class_name] = true
  --- @type UnitClassCollection
  local collection = {
  unit_class_name = class_name,
  filter_friendly = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    IncludeThing = {class_name},
  }),
  filter_neutral = CreateObjectFilter({
    IncludeThing = {class_name},
  }),
  Player_1 = { size = 0, ids = {}, units = {} },
  Player_2 = { size = 0, ids = {}, units = {} },
  Player_3 = { size = 0, ids = {}, units = {} },
  Player_4 = { size = 0, ids = {}, units = {} },
  Player_5 = { size = 0, ids = {}, units = {} },
  Player_6 = { size = 0, ids = {}, units = {} },
  PlyrCivilian = { size = 0, ids = {}, units = {} },
  PlyrCreeps = { size = 0, ids = {}, units = {} },
  unit_added_dict = {},
  }
  local count = Object.CreatedUnitClassCollections.count
  Object.CreatedUnitClassCollections.count = count + 1
  Object.CreatedUnitClassCollections[count + 1] = collection
  return collection
end

---@param collection UnitClassCollection
---@param unit StandardUnitType
---@return boolean
function Object.AddToUnitClassCollection(collection, unit)
  if not ObjectIsAlive(unit) then
    _ALERT("Object.AddToUnitClassCollection: Unit is dead")
    return false
  end
  if not ObjectTestTargetObjectWithFilter(nil, unit, collection.filter_neutral) then
    _ALERT("Object.AddToUnitClassCollection: Unit does not belong to the class")
    return false
  end
  local id = ObjectGetId(unit)
  if collection.unit_added_dict[id] then
    _ALERT("Object.AddToUnitClassCollection: Unit already added")
    return false
  end
  local player_name = ObjectPlayerScriptName(unit)
  if player_name then
    local player_collection = collection[player_name]
    if player_collection then
      player_collection.size = player_collection.size + 1
      player_collection.ids[player_collection.size] = id
      player_collection.units[player_collection.size] = unit
      --UnitShowInfoBox(unit, "txt",10)
      if id then
        collection.unit_added_dict[id] = true
      end
      return true
    end
  end
  return false
end


---@param collection UnitClassCollection
function Object.RebuildUnitClassCollection(collection)
  local new_unit_added_dict = {}
  local nil_id_count = 0
  local total_before = 0
  for i = 1, 8, 1 do
    local player_name = Player_list[i]
    local player_collection = collection[player_name]
    total_before = total_before + player_collection.size
  end
  for i = 1, 8, 1 do
    local player_name = Player_list[i]
    local player_collection = collection[player_name]
    local new_size = 0
    local new_ids = {}
    local new_units = {}
    for j = 1, player_collection.size, 1 do
      local unit = player_collection.units[j]
      if ObjectIsAlive(unit) then
        new_size = new_size + 1
        local id = ObjectGetId(unit)
        new_ids[new_size] = id
        new_units[new_size] = unit
        if id then
          new_unit_added_dict[id] = true
        else
          nil_id_count = nil_id_count + 1
        end
      end
    end
    player_collection.size = new_size
    player_collection.ids = new_ids
    player_collection.units = new_units
  end
  collection.unit_added_dict = new_unit_added_dict
  local total_after = 0
  for i = 1, 8, 1 do
    local player_name = Player_list[i]
    local player_collection = collection[player_name]
    total_after = total_after + player_collection.size
  end
  if nil_id_count > 0 then
    local name = collection.unit_class_name
    _ALERT("Object.RebuildUnitClassCollection: "..nil_id_count.." units have nil id when rebuilding Collection for "..name)
  end
  return total_before - total_after
end

function Object.RebuildAllCollections()
  if tolerant_int_mod(GlobalSecond, 60) == 0 then
    local allCollection = Object.CreatedUnitClassCollections
    local count = allCollection.count
    local total_removed = 0
    for i = 1, count, 1 do
      local collection = allCollection[i]
      total_removed = total_removed +
      Object.RebuildUnitClassCollection(collection)
    end
    if total_removed > 0 then
      --_ALERT("Object.RebuildAllCollections: "..total_removed.." units removed")
    end
  end
end



--- Define the common unit table structure. old function for CEDS, FCS and FCSs
--- @param include_one_thing string[]
--- @return HumanPlayerUnitCollection
function CreateUnitTable(include_one_thing)
  --- @type HumanPlayerUnitCollection
  return {
      -- unit_id and evac_dict is mainly for inter-system communication
      -- so other system know if a unit is evacuating
      -- if we don't store the unit_id, when the unit is dead, 
      -- we will lose the unit_id and can't remove it from the evac_dict
      -- unit in the system is refered by index in the table
      -- ex: ret[1][1] is the first unit of player 1
      --- @type CEDSUnitTable
      [1] = {size = 0, time = {}, unit_id = {}, evac_dict = {}, cooldown_dict = {}}, -- Player 1
      [2] = {size = 0, time = {}, unit_id = {}, evac_dict = {}, cooldown_dict = {}}, -- Player 2
      [3] = {size = 0, time = {}, unit_id = {}, evac_dict = {}, cooldown_dict = {}}, -- Player 3
      [4] = {size = 0, time = {}, unit_id = {}, evac_dict = {}, cooldown_dict = {}}, -- Player 4
      [5] = {size = 0, time = {}, unit_id = {}, evac_dict = {}, cooldown_dict = {}}, -- Player 5
      [6] = {size = 0, time = {}, unit_id = {}, evac_dict = {}, cooldown_dict = {}}, -- Player 6
      filter_friendly = CreateObjectFilter({
          Rule = "ANY",
          Relationship = "SAME_PLAYER",
          IncludeThing = include_one_thing,
      }),
      filter_neutral = CreateObjectFilter({
          IncludeThing = include_one_thing,
      }),
      unit_name = include_one_thing[1]
  }
end