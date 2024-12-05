--- Update: 2024/11/29
--- @module "Global-1TypeDef"
--- @module "Global0VarFun"
DEBUG_CORONA_INE = false
Global0VarFun = 1
-- exMessageAppendToMessageArea("Global0VarFun.lua loading started")
-- **********************************Important**********************************
-- This function override the LUA interal error handling function and redirect the error message to the debug console
-- This is critical for debugging runtime error in the game
function _ALERT(s)
  if exMessageAppendToMessageArea then
    -- Alert function in new version of Corona mod. It directly print the message to the message area in the game
    exMessageAppendToMessageArea("LUA ALERT: " .. s)
  end
  if exPrintln then
    -- Alert function in new version of Corona mod. It directly print the message to the debug console
    exPrintln("LUA exPrintln ALERT: " .. s)
  end
    -- Alert function in old version of Corona mod. It print the message to the debug console
    ExecuteAction("DEBUG_STRING", "Lua Alert: " .. (s or "no debug message"))
end

function DEBUG_error(s)
  if DEBUG_CORONA_INE then
    error(s)
  end
end

function DEBUG_assert(condition, s)
  if DEBUG_CORONA_INE then
    assert(condition, s)
  end
end

--- Performs a floor operation with tolerance for floating-point inconsistencies across different CPUs.
--- This function adjusts for minor floating-point errors near the boundaries of integer, ensuring
--- consistent integer results across platforms.
--- Values with fractional parts close to 0.9 or below 0.1 are rounded appropriately to avoid discrepancies.
--- @param float number The floating-point number to be floored with tolerance.
--- @return integer The floored integer, adjusted for cross-platform floating-point accuracy.
function tolerant_floor(float)
    local fractional_part = float - floor(float)
    if fractional_part >= 0.9 or fractional_part < 0.1 then
        return floor(float + 0.5)
    else
        return floor(float)
    end
end

function tolerant_int_mod(a, b)
  a = tolerant_floor(a)
  b = tolerant_floor(b)
  if b == 0 then
    error("Division by zero in mod operation")
  end
  return a - tolerant_floor(a / b) * b
end


--- This function is used to get the position of an object in integer
---@param object StandardUnitType
---@return integer
---@return integer
---@return integer
function ObjectGetIntPosition(object)
  local x,y,z = ObjectGetPosition(object)
  return tolerant_floor(x), tolerant_floor(y), tolerant_floor(z)
end

function ObjectGetCurrentIntHealth(object)
  return tolerant_floor(ObjectGetCurrentHealth(object))
end

function ObjectGetInitialIntHealth(object)
  return tolerant_floor(ObjectGetInitialHealth(object))
end




LOADED_FILES = {
  [0] = false, -- Global0VarFun.lua
  [1] = false, -- Global1FCS.lua
  [2] = false, -- Global2CEDS.lua
  [3] = false, -- Global3FCSs.lua
}
if DEBUG_CORONA_INE then
  _ALERT("Loading Global0VarFun.lua")
  LOADED_FILES[0] = true
end
--- *****************************************************************************************
--- 注意LUA全局变量需要退出当前游戏才会确保重置，游戏内直接点击重新开始游戏有概率不会重置
--- *****疑似需要退出房间重新进入才会重置*****
--- 多个代码文件的执行顺序和地编中脚本执行顺序相同，上面的先执行，下面的后执行
--- *****************************************************************************************
--- *******!!!注意,已确认逆天EA把LUA4.0的 == operator覆写了， false == nil 会返回true !!!!!!!!**
--- *****************************************************************************************
--- 注意浮点数计算在不同的计算机上可能会有不同的结果，尽量避免浮点数计算
--- ^ 这个power操作符在lua中会调用math library，注意浮点数计算的微小误差
--- 来源，公主：
--- lua 的问题在于
--- 他调用的一些数学函数，例如三角函数
--- 不是 lua 自己写的
--- 也不是写死的汇编
--- 而是调用微软 VC++ 库的函数
--- 无法保证每个玩家电脑上装的 VC++ 库的版本是一致的
--- 所以计算结果会有细微的差别
--- 然后很不巧，lua里的所有数学函数，包括三角函数，甚至 ceil 和 floor，都是 VC++ 库提供的
--- 其他的例子如arm cpu用户能上战网联机，但是一联机就会不同步，因为arm cpu和x86 cpu的浮点数计算结果不同
--- 
--注意全局变量的SCOPE包含了整张地图，所有上下级的文件夹内的LUA文件都共享同一个SCOPE，所以要注意变量名的冲突
--Everything without a local keyword is global!!!!!!
-- loop control variable i in loop is the only exception, it is local by default

--Remember to install LUA extension for Visual Studio Code to catch Global variable usage


--[[
filter = CreateObjectFilter({ --bad example, this filter is global, it will affect other lua files
    IncludeThing={
      "alliedinterceptoraircrafttech3protonmissileprojectile"
    },
  })
--]]

--- This function spawn a unit at position (x,y,z) with a given orientation
--- @param class_name string example JapanAntiVehicleInfantryTech3
--- @param team string example "Player_1/teamPlayer_1" or "/team" or "PlyrCreeps/teamPlyrCreeps"
--- @param x number
--- @param y number
--- @param z number
--- @param orientation number
function ObjectSpawnUnnamed_Slow(class_name,team, x, y, z, orientation)
  x = tolerant_floor(x)
  y = tolerant_floor(y)
  z = tolerant_floor(z)
  if orientation == nil then
    orientation = 30
  end
  ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",
  "",
  class_name,
  team,
  { X=x, Y=y, Z=z }, -- 位置
  orientation -- 朝向
  )
end


--- This function spawn a NAMED unit at position (x,y,z) with a given orientation
--- Note: team like  --"Player_2/teamPlayer_2" works but
--- "PlyrNeutral/teamPlyrNeutral" doesn't work
--- "SkirmishAllies/teamSkirmishAllies", doesn't work
---@param instance_name string must be unique, example "SpawnedUnit-1"
---@param class_name string example JapanAntiVehicleInfantryTech3
---@param team string example "Player_1/teamPlayer_1" or "/team" or "PlyrCreeps/teamPlyrCreeps"
---@param x number
---@param y number
---@param z number
---@param orientation number
function ObjectSpawnNamed_Slow(instance_name, class_name, team, x, y, z, orientation)
  x = tolerant_floor(x)
  y = tolerant_floor(y)
  z = tolerant_floor(z)
  if orientation == nil then
    orientation = 30
  end
  ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",
  instance_name,
  class_name,
  team,
  { X=x, Y=y, Z=z }, -- 位置
  orientation -- 朝向
  )
end

function _CalculateTriangleOffsets (radius)
  local offsets = {
    [1] = {
      [1] = { x = radius, y = 0 },                            -- 0 degrees
      [2] = { x = -radius * 0.5, y = radius * 0.866 },        -- 120 degrees
      [3] = { x = -radius * 0.5, y = -radius * 0.866 },       -- 240 degrees
      [4] = { x = 0, y = 0 }                                  -- center
    },
    [2] = {
      [1] = { x = radius * 0.866, y = radius * 0.5 },         -- 30 degrees
      [2] = { x = -radius * 0.866, y = radius * 0.5 },        -- 150 degrees
      [3] = { x = 0, y = -radius },                           -- 270 degrees
      [4] = { x = 0, y = 0 }                                  -- center
    },
    [3] = {
      [1] = { x = radius * 0.5, y = radius * 0.866 },         -- 60 degrees
      [2] = { x = -radius, y = 0 },                           -- 180 degrees
      [3] = { x = radius * 0.5, y = -radius * 0.866 },        -- 300 degrees
      [4] = { x = 0, y = 0 }                                  -- center
    },
    [4] = {
      [1] = { x = 0, y = radius },                            -- 90 degrees
      [2] = { x = -radius * 0.866, y = -radius * 0.5 },       -- 210 degrees
      [3] = { x = radius * 0.866, y = -radius * 0.5 },        -- 330 degrees
      [4] = { x = 0, y = 0 }                                  -- center
    }
  }
  for i = 1, 4, 1 do
    for j = 1, 4, 1 do
      offsets[i][j].x = tolerant_floor(offsets[i][j].x)
      offsets[i][j].y = tolerant_floor(offsets[i][j].y)
    end
  end
  return offsets
end

Duration3600S = 108000 -- 3600s = 60min = 108000frames
--地编中的核弹无畏实现方式
--在无畏的导弹上刷一个物体(527)，这个物体会跟随无畏的导弹移动。当无畏的导弹被摧毁时，在刷出的物体上刷个核弹

Century_bomb_filter = CreateObjectFilter({
  IncludeThing={
    "CenturyBomber_HugeBombProjectile",
    --"SovietBomberAircraftBombProjectile",
    },
  })

Missile_table = {
  size = 0,
  positions = {},
  is_dead = {},
  id = {}
}

Athena_laser_table = {
  size = 0,
  positions = {},
  duration = {},
  id = {},
  team = {},
  ori = {}
}


--  AIRCRAFT INFANTRY SHIP SUBMARINE VEHICLE"
FilterSelectable = CreateObjectFilter({
  Rule="ANY",
  Include="SELECTABLE",
  IncludeThing={}
})

FilterStructure = CreateObjectFilter({
  Rule="ANY",
  Include="STRUCTURE",
  IncludeThing={}
})

FilterEnemySelectable = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ENEMIES",
    Include = "SELECTABLE",
    IncludeThing = {}
})

FilterEnemyStructure = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ENEMIES",
    Include = "STRUCTURE",
    IncludeThing = {}
})

FilterEnemySelectableSurfaceOnly = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ENEMIES",
    Exclude = "AIRCRAFT",
    Include = "SELECTABLE",
    StatusBitFlagsExclude = "AIRBORNE_TARGET SUBMERGED",
    IncludeThing = {}
})

FilterEnemyUnitSurfaceOnly = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ENEMIES",
    Exclude = "STRUCTURE AIRCRAFT",
    StatusBitFlagsExclude = "AIRBORNE_TARGET SUBMERGED",
    Include = "SELECTABLE",
    IncludeThing = {}
})

FilterEnemyVehicleSurfaceOnly = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ENEMIES",
    Exclude = "STRUCTURE AIRCRAFT INFANTRY",
    StatusBitFlagsExclude = "AIRBORNE_TARGET SUBMERGED",
    Include = "SELECTABLE",
    IncludeThing = {},
})

FilterVehicleSurfaceOnly = CreateObjectFilter({
  Rule="ANY",
  Exclude = "STRUCTURE AIRCRAFT INFANTRY",
  StatusBitFlagsExclude = "AIRBORNE_TARGET SUBMERGED",
  Include = "SELECTABLE",
  IncludeThing = {},
})


FilterFriendlySelectable = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ALLIES",
    Include = "SELECTABLE",
    IncludeThing = {}
})

function Missile_position_from_location_table(index)
  return Missile_table.positions[index][1], Missile_table.positions[index][2], Missile_table.positions[index][3]
end

function Athena_laser_position_from_location_table(index)
  return Athena_laser_table.positions[index][1], Athena_laser_table.positions[index][2], Athena_laser_table.positions[index][3]
end

function Remove_missile_from_table(index)
  for i = index, Missile_table.size-1, 1 do
    Missile_table[i] = Missile_table[i+1]
    Missile_table.positions[i] = Missile_table.positions[i+1]
    Missile_table.is_dead[i] = Missile_table.is_dead[i+1]
    Missile_table.id[i] = Missile_table.id[i+1]
  end
  Missile_table.size = Missile_table.size - 1
end

function Remove_Athena_laser_from_table(index)
  for i = index, Athena_laser_table.size-1, 1 do
    Athena_laser_table[i] = Athena_laser_table[i+1]
    Athena_laser_table.positions[i] = Athena_laser_table.positions[i+1]
    Athena_laser_table.duration[i] = Athena_laser_table.duration[i+1]
    Athena_laser_table.id[i] = Athena_laser_table.id[i+1]
    Athena_laser_table.team[i] = Athena_laser_table.team[i+1]
    Athena_laser_table.ori[i] = Athena_laser_table.ori[i+1]
  end
  Athena_laser_table.size = Athena_laser_table.size - 1
end




Athena_Offsets = _CalculateTriangleOffsets(50)

-- This function should only be called once per radius value, per id, per team, per frame
function _Spawn_Athena_laser_in_triangle(x,y,z,id, dur, radius, team, ori, offsets)
  if radius == nil then
    radius = 50
  end
  if team == nil then
    team = "/team"
  end
  local ran = ori
  if ran == nil then
    ran = tolerant_floor(GetRandomNumber()*4)+1
  end
  if ran > 4 then
    ran = 4
  end
  if ran < 1 then
    ran = 1
  end


  for j = 1, 4, 1 do
    local spawn_name = "SpawnedSatelliteLaser-"..tostring(id).."-"..tostring(dur)..tostring(radius).."-"..tostring(j)
    local dx = offsets[ran][j].x -- (GetRandomNumber()-0.5)*100
    local dy = offsets[ran][j].y -- (GetRandomNumber()-0.5)*100
    ObjectSpawnNamed_Slow(spawn_name, "alliedantistructurevehiclecannoneffect", 
    team, x+dx, y+dy, z, 30)
    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", spawn_name, "OVERCHARGING_WEAPON", "true")
  end
end





--- Function for debug, spawn a JapanAntiVehicleInfantryTech3 at position (x,y,z)
--- @param x number
--- @param y number
--- @param z number
function Debug_spawn_at_position(x,y,z)
  ObjectSpawnUnnamed_Slow("JapanAntiVehicleInfantryTech3","Player_1/teamPlayer_1", x, y, z, 30)
end

--- Function for debug, spawn an enemy unit at position (x,y,z)
--- @param x number
--- @param y number
--- @param z number
--- @param unit_name string
function Debug_spawn_enemy_at_position(x,y,z, unit_name)
  ObjectSpawnUnnamed_Slow(unit_name, "PlyrCreeps/teamPlyrCreeps", x, y, z, 30)
end




-- This function find everything in an area, including tree, building, unit, missile, drone, etc
function Area_search(x,y,z, radius)
  local matchedObjects, count = ObjectFindObjects(nil, 
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  nil)
  return matchedObjects, count
end

-- This function find all enemy selectable units and buildings in an area.
-- Units and building found are enemy of the reference object(relatively)
function Area_enemy_search(x,y,z, radius, ref_object)
  local matchedObjects, count = ObjectFindObjects(ref_object, 
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  FilterEnemySelectable)
  return matchedObjects, count
end

-- This function find all enemy surface selectable units and buildings in an area.
---@param x number 
---@param y number 
---@param z number 
---@param radius number The radius of the area, centered at (x,y,z)
---@param iff_ref_object StandardUnitType The reference object for Identifying Friend or Foe (IFF)
---@return StandardUnitType[]
---@return number
function Area_enemy_search_surface_only(x,y,z, radius, iff_ref_object)
  local matchedObjects, count = ObjectFindObjects(iff_ref_object,
  {X = x, Y = y, Z = z, Radius = radius, DistType = "CENTER_2D"},
  FilterEnemySelectableSurfaceOnly)
  return matchedObjects, count
end

function Area_enemy_structure_search(x,y,z, radius, ref_object)
  local matchedObjects, count = ObjectFindObjects(ref_object, 
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  FilterEnemyStructure)
  return matchedObjects, count
end

function Area_enemy_surface_unit_search(x,y,z, radius, ref_object)
  local matchedObjects, count = ObjectFindObjects(ref_object, 
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  FilterEnemyUnitSurfaceOnly)
  return matchedObjects, count
end

-- This function find everything in the map, including tree, building, unit, missile, drone, etc
function Map_search()
  local matchedObjects, count = ObjectFindObjects(nil, nil, nil)
  return matchedObjects, count
end

-- This function find everything in the map that match the filter
-- Filter should not contain relationship since this function do not take in unit as reference for relationship check
function Map_filter_search(filter)
  local matchedObjects, count = ObjectFindObjects(nil, nil, filter)
  return matchedObjects, count
end


-- This function output debug string to debug console when the game is running
function ShowDebugString(str)
  ExecuteAction("DEBUG_STRING", str)
end



-- This function search for objects in the map that match the filter, and then filter the result by distance to a point
---- Warning: Desync risk due to searching everything in the map
function Map_filter_search_radius_limited(x,y,z, radius, filter)
  local matchedObjects, count = Map_filter_search(filter)
  local newArray = {}  -- This will store the filtered elements
  local newSize = 0     -- This will store the new size of the filtered array
  local radius_sqr = tolerant_floor(radius * radius)
  for i = 1, count, 1 do
    local cx, cy, cz = ObjectGetIntPosition(matchedObjects[i])
    local distance_sqr = tolerant_floor(((cx-x)^2 + (cy-y)^2 + (cz-z)^2))
    if distance_sqr < radius_sqr then
        newSize = newSize + 1
        newArray[newSize] = matchedObjects[i]
    end
  end
  
  return newArray, newSize
end



-- This function search for everything in an area, and then filter the result by the filter(ignore relationship)
function Area_filter_search(x,y,z, radius, filter)
  local matchedObjects, count = Area_search(x,y,z, radius)
  local newArray = {}  -- This will store the filtered elements
  local newSize = 0     -- This will store the new size of the filtered array
  --ShowDebugString("count: "..count)
  
  for i = 1, count, 1 do
      if ObjectTestTargetObjectWithFilter(nil, matchedObjects[i], filter) then
          --ShowDebugString("matchedObjects[i] found, i = "..i)
          newSize = newSize + 1
          newArray[newSize] = matchedObjects[i]
      end
  end
  --ShowDebugString("newSize: "..newSize)
  
  return newArray, newSize
end

-- This function search for units that are friendly to the reference object in an area
-- The filter must contain relationship to filter out enemy units
function Area_Friendly_Unit_filter_search(current, radius, filter_friendly)
  if current == nil then
    _ALERT("Area_Friendly_Unit_filter_search: current is nil")
    return {}, 0
  end
  if radius == nil then
    _ALERT("Area_Friendly_Unit_filter_search: radius is nil")
    return {}, 0
  end
  if filter_friendly == nil then
    _ALERT("Area_Friendly_Unit_filter_search: filter_friendly is nil")
    return {}, 0
  end
  local x,y,z = ObjectGetIntPosition(current)
  local matchedObjects, count = ObjectFindObjects(current,
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  filter_friendly)
  return matchedObjects, count
end




ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "AlliedAirfield","FactoryList")
ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "AlliedNavalYard", "FactoryList")
ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "AlliedWarFactory", "FactoryList")
ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "AlliedBarracks", "FactoryList")
ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "JapanConstructionYard", "FactoryList")
ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "JapanNavalYard", "FactoryList")
ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "JapanWarFactory", "FactoryList")
ExecuteAction("OBJECTLIST_ADDOBJECTTYPE", "JapanBarracks", "FactoryList")




ExistingObjects = {size = 0}

-- Define a function to check if the newly found object is an existing object
-- ExistingObjects must have a size field
function IsNewObject(existingObjects, newObject, size)
  -- Iterate through the list of existing objects up to the given size
  if size == nil then
    size = existingObjects.size
  end
  for i = 1, size, 1 do
      -- Use the provided function to check if the objects are the same
      local existingObject = existingObjects[i]
      if existingObject then
        if ObjectsIsSame(existingObjects[i], newObject) then
            -- If they are the same, return false (the object already exists)
            return false
        end
      end
  end
  -- If no match was found, return true (the object is new)
  return true
end


-- ***********************************************************************************
-- *************注意EvaluateCondition 和ExecuteAction的计算成本是LUA的100倍*************
-- *******************************尽量减少这两个函数的调用次数**************************
-- ***********************************************************************************
--- ************Rule of thumb: Limit the use of EvaluateCondition and ExecuteAction to
--- ************less than 10 calls per frame per managed player unit************
--- lua里通过 ExecuteAction 调用地编函数，比直接调用专用lua API要慢很多倍
--- 原因是ExecuteAction / EvaluateCondition 这些 lua 函数，调用地编脚本的原理是通过在一个巨大的字符串数组（1000个）里
--- 依次进行字符串比较，再根据字符串来找到对应的脚本数字 id，再拿着脚本数字 id调用地编脚本
--- 此外，传入的各种字符串形式的参数（比如说单位状态、模型状态等）也需要从字符串转为实际的enum，这些都有开销
--- 而专用的 lua API 显然不需要进行上百次字符串比较，直接转到对应 C++ 函数处理了
--- 所以尽量减少这两个函数的调用次数，尤其是在循环里
--- 确保每个单位在每帧处理时只调用总计大约10次以下的ExecuteAction / EvaluateCondition（预期上百个单位）
--- 如果是只会出现少量的大型单位，可以适当放宽这个限制


--- This function check if the object has the status
--- The status is a string, such as "DAMAGED", "REALLYDAMAGED", "REPAIR_ALLIES_WHEN_IDLE"
--- @param current StandardUnitType
--- @param status ObjectStatus
--- @return boolean
function ObjectStatusIs(current, status)
  local filter = CreateObjectFilter({
    Rule="ALL",
    IncludeThing = {},
    StatusBitFlags = status, -- Ex: "REPAIR_ALLIES_WHEN_IDLE",
  })
  return ObjectTestTargetObjectWithFilter(nil, current, filter)
end

-- This function check if the object is damaged(health bar is not full)
---@param current StandardUnitType
function ObjectIsDamaged(current)
  local health = ObjectGetCurrentIntHealth(current) -- 当前血量
  local initialHealth = ObjectGetInitialIntHealth(current) -- 初始血量
  return health < initialHealth
end

-- This function check if the object is lightly damaged(health bar is yellow)
---@param current StandardUnitType
function ObjectStatusIsLightlyDamaged_Slow(current)
  return EvaluateCondition("UNIT_HAS_OBJECT_STATUS", current, "DAMAGED")
end

--100-66绿血， 65-33黄血， 32-0红血
---@param current StandardUnitType
function ObjectStatusIsLightlyDamaged(current)
  return ObjectStatusIs(current, "DAMAGED")
end

-- This function check if the object is really damaged(health bar is red)
---@param current StandardUnitType
function ObjectStatusIsReallyDamaged_Slow(current)
  return EvaluateCondition("UNIT_HAS_OBJECT_STATUS", current, "REALLYDAMAGED")
end

--100-66绿血， 65-33黄血， 32-0红血
---@param current StandardUnitType
function ObjectStatusIsReallyDamaged(current)
  return ObjectStatusIs(current, "REALLYDAMAGED")
end

--- Checks if the object is of a specific unit type.
--- @param object StandardUnitType The object to check.
--- @param single_unit_filter ObjectFilter The filter to match the unit type.
--- @return boolean True if the object is of the specified unit type, false otherwise.
function ObjectIsUnitOfType(object, single_unit_filter)
  return ObjectTestTargetObjectWithFilter(nil, object, single_unit_filter)
end

--- Checks if the object is kindOf
---@param object StandardUnitType The object to check.
---@param kindOf KindOf
---@return boolean
function ObjectIsKindOf(object, kindOf)
  local filter = FilterKindOf[kindOf]
  if filter == nil then
    _ALERT("ObjectIsKindOf: the kindOf is not defined in FilterKindOf")
    return false
  end
  return ObjectTestTargetObjectWithFilter(nil, object, filter)
end

--- Checks if the object is structure
--- @param object StandardUnitType The object to check.
--- @return boolean True if the object is structure, false otherwise.
function ObjectIsStructure(object)
  return ObjectIsKindOf(object, "STRUCTURE")
end

function ObjectStanceIsAggressive_Slow(current)
  return EvaluateCondition("UNIT_USING_STANCE", current, "AGGRESSIVE")
end

-- This function check if the object is in GUARD stance
--- @param current StandardUnitType
--- @return boolean
function ObjectStanceIsGuard_Slow(current)
  return EvaluateCondition("UNIT_USING_STANCE", current, "GUARD")
end
-- This function check if the object is in HOLD POSITION stance
--- @param current StandardUnitType
--- @return boolean
function ObjectStanceIsHoldPosition_Slow(current)
  return EvaluateCondition("UNIT_USING_STANCE", current, "HOLD_POSITION")
end

-- This function check if the object is in HOLD FIRE stance
--- @param current StandardUnitType
--- @return boolean
function ObjectStanceIsHoldFire_Slow(current)
  return EvaluateCondition("UNIT_USING_STANCE", current, "HOLD_FIRE")
end

-- This function set Object Status of the object
--- @param current StandardUnitType
--- @param status ObjectStatus
--- @param bool boolean
function ObjectSetObjectStatus_Slow(current, status, bool)
  ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", current, status, bool)
end
--- @param current StandardUnitType
function ObjectDelete_Slow(current)
  ExecuteAction("NAMED_DELETE", current)
end

--- Deprecated, since it requires at least 1 frame between the two STATUS change to work
--- Hence to deselect a unit, a outside timer is needed.
--- Therefore it's impossible to use this function to deselect a unit in a single frame
--  This function deselect the unit from player's selection
--- function UnitDeselect_Slow(current)
--   ObjectSetObjectStatus_Slow(current, "UNSELECTABLE", true)
--   ObjectSetObjectStatus_Slow(current, "UNSELECTABLE", false)
-- end

-- This function set the Object Status of the object to UNSELECTABLE
---@param current StandardUnitType
---@param bool boolean
function ObjectSetObjectStatusUnselectable_Slow(current, bool)
  ObjectSetObjectStatus_Slow(current, "UNSELECTABLE", bool)
end


function UnitMoveToNamedWaypoint(current, existing_waypoint_name_on_map)
  ExecuteAction("MOVE_NAMED_UNIT_TO", current, existing_waypoint_name_on_map)
end

function UnitAttackTarget(current, target)
  if target == nil then
    _ALERT("UnitAttackTarget: target is nil")
    return
  end
  ExecuteAction("NAMED_ATTACK_NAMED", current, target)
end

function UnitForceAttackTarget(current, target)
  if target == nil then
    _ALERT("UnitForceAttackTarget: target is nil")
    return
  end
  ExecuteAction("NAMED_FORCE_ATTACK_NAMED", current, target)
end





function UnitStop(current)
  ExecuteAction("NAMED_STOP", current)
end

-- Most object in game can have InfoBox, including map objects, trees, buildings, units, etc
-- Named waypoint cannot have InfoBox
--- @param current StandardUnitType
--- @param text_reference_name string
--- @param time number
function UnitShowInfoBox(current, text_reference_name, time)
  if time == nil then
    time = 5
  end
  if text_reference_name == nil then
    text_reference_name = "SCRIPT:CRANE-FRIEND"
  end
  ExecuteAction("NAMED_SHOW_INFOBOX", current, text_reference_name, time, "???")
end


-- This function show a info box with text keep changing per call
-- Maybe due to the "BUG:" in the text
-- Each time this is called it create a new object and it won't get removed
-- This will cause huge lag if called in a loop in tens of seconds
function __DebugUnitShowInfoBox_HugeLagInLoop(current,time)
  UnitShowInfoBox(current, "DEBUG", time)
  -- make sure the text in map.str is like these below
  -- the string start with BUG: and followed by some text with no space
  --  COOL-DOWN-BUG
  -- "BUG:mytext"
  -- END

  -- COOL-DOWN-BUG2
  -- "BUG:冷却时间小于0"
  -- END
end

function UnitUseAbility(current, ability_name)
  ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", current, ability_name)
end

function UnitUseAbilityOnTarget(current, ability_name, target)
  -- Command_AlliedFutureTankLaserWeapon
  --local object_reference = ObjectGetId(current)
  local target_reference = ObjectGetId(target)
  ExecuteAction("SET_UNIT_REFERENCE", target_reference, target)
  
  ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY_ON_NAMED", current, ability_name, target_reference)
end

--- This function check if the unit is ready to use the special ability
--- @param current StandardUnitType
--- @param special_ability_name "SpecialPower_AlliedFutureTankLaserWeapon"
function UnitSpecialAbilityReady_Slow(current, special_ability_name)
  return EvaluateCondition("UNIT_SPECIAL_POWER_READY", current, special_ability_name)
end


-- 这个函数只在ObjectTestTargetObjectWithFilter的if语句中使用，用于将当前单位加入到对应的Global table中
function _Add_Current_to_Table(table, current)
  local player_index = nil
  if not current then
    _ALERT("_Add_Current_to_Table: current is nil")
    return
  end
  local unit_id = ObjectGetId(current)
  if ObjectPlayerScriptName(current) == "Player_1" then
    player_index = 1
  elseif ObjectPlayerScriptName(current) == "Player_2" then
    player_index = 2
  elseif ObjectPlayerScriptName(current) == "Player_3" then
    player_index = 3
  elseif ObjectPlayerScriptName(current) == "Player_4" then
    player_index = 4
  elseif ObjectPlayerScriptName(current) == "Player_5" then
    player_index = 5
  elseif ObjectPlayerScriptName(current) == "Player_6" then
    player_index = 6
  end
  if player_index then
    if table[player_index] == nil then
      _ALERT("_Add_Current_to_Table: table[player_index] is nil")
      return
    end
    local size = table[player_index].size
    if size == nil then
      _ALERT("_Add_Current_to_Table: table[player_index].size is nil")
      return
    end
    table[player_index].size = size + 1
    local unit_index = size + 1
    table[player_index][unit_index] = current
    if table[player_index].time == nil then
      -- The 'time' table doesn't exist for this player, assume the unit doesn't need to track time
      return  -- Exit if time tracking isn't necessary
    else
      -- The 'time' table exists, set the time for the "current" unit with the index "unit_index"
      table[player_index].time[unit_index] = 0
    end


  end
end



-- This function is mainly used to remove dead units from a table after one full iteration of the table
-- table[player_index] is expected to be a table with a 'size' field and a list of units for the player
-- When a unit is dead, it's expected to be set to nil in the table.
-- For example table[player_index][unit_index] = nil means the unit is marked as dead but not removed from the table
-- Time complexity: O(n) where n is the size of the table
---@param table UnitCollection
---@param player_index integer
---@return nil
function _Rebuild_Table_with_Nils_Removed(table, player_index)
  --- @type PlayerUnitTable
  local new_table = {
    size = 0,
    time = {},
    unit_id = {},
    evac_dict = {},
    cooldown_dict = {}
  }
  if table[player_index] == nil then
    _ALERT("_Rebuild_Table_with_Nils_Removed: UnitCollection is nil. player_index = "..tostring(player_index))
    return
  end

  local new_size = 0
  local size = table[player_index].size
  for i = 1, size, 1 do
    local current = table[player_index][i]
    if current then
      new_size = new_size + 1
      new_table[new_size] = current
      new_table.time[new_size] = table[player_index].time[i]
      ---@type UnitID|nil
      local unit_id = table[player_index].unit_id[i]
      new_table.unit_id[new_size] = unit_id
      if unit_id then
        local evac = table[player_index].evac_dict[unit_id]
        if evac then
          new_table.evac_dict[unit_id] = evac
        end
        local cooldown = table[player_index].cooldown_dict[unit_id]
        if cooldown then
          new_table.cooldown_dict[unit_id] = cooldown
        end
      end
    end
  end
  table[player_index] = new_table
  table[player_index].size = new_size
end

-- exMessageAppendToMessageArea("Global0VarFun.lua loading completed")


