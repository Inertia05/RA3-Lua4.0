-- **********************************Important**********************************
-- This function override the LUA interal error handling function and redirect the error message to the debug console
-- This is critical for debugging runtime error in the game
function _ALERT(s)
  ExecuteAction("DEBUG_STRING", "Lua Alert: " .. (s or "no debug message"))
end
-- *****************************************************************************
--注意LUA全局变量需要退出当前游戏才会重置，游戏内直接点击重新开始游戏不会重置
--多个代码文件的执行顺序和地编中脚本执行顺序相同，上面的先执行，下面的后执行

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

Duration3600S = 108000 -- 3600s = 60min = 108000frames
--地编中的核弹无畏实现方式
--在无畏的导弹上刷一个物体(527)，这个物体会跟随无畏的导弹移动。当无畏的导弹被摧毁时，在刷出的物体上刷个核弹

INITIATOR_OBJECT_NEUTRAL = GetObjectByScriptName("LUA-INITIATOR")

Century_bomb_filter = CreateObjectFilter({
  IncludeThing={
    "CenturyBomber_HugeBombProjectile",
    --"SovietBomberAircraftBombProjectile",
    },
  })

Missile_table = {
  size = 0,
  positions = {},
  is_dead = {}
}

Athena_laser_table = {
  size = 0,
  positions = {},
  duration = {},
  id = {},
  team = {},
  ori = {}
}



Celestial_satellite_cannon_table = {
  cannons = {},
  targets = {},
  size = 0
}
--  AIRCRAFT INFANTRY SHIP SUBMARINE VEHICLE"
FilterSelectable = {
  Rule="ANY",
  Include="SELECTABLE"
}

FilterAircraft = {
  Rule="ANY",
  Include="AIRCRAFT"
}

FilterVehicle = {
  Rule="ANY",
  Include="VEHICLE"
}

FilterNavy = {
  Rule="ANY",
  Include="SHIP SUBMARINE"
}

FilterEnemySelectable = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ENEMIES",
    Include = "SELECTABLE",
    IncludeThing = {}
})

FilterEnemySelectableSurfaceOnly = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ENEMIES",
    Include = "SELECTABLE",
    StatusBitFlagsExclude = "AIRBORNE_TARGET SUBMERGED",
    IncludeThing = {}
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


-- This function should only be called once per radius value, per id, per team, per frame
function _Spawn_Athena_laser_in_triangle(x,y,z,id, dur, radius, team, ori)
  if radius == nil then
    radius = 50
  end
  if team == nil then
    team = "/team"
  end
  local ran = ori
  if ran == nil then
    ran = floor(GetRandomNumber()*4)+1
  end
  if ran > 4 then
    ran = 4
  end
  if ran < 1 then
    ran = 1
  end
  local offsets = {
  {
    { x = radius, y = 0 },                            -- 0 degrees
    { x = -radius * 0.5, y = radius * 0.866 },        -- 120 degrees
    { x = -radius * 0.5, y = -radius * 0.866 },       -- 240 degrees
    { x = 0, y = 0 }                                  -- center
  },
  {
    { x = radius * 0.866, y = radius * 0.5 },         -- 30 degrees
    { x = -radius * 0.866, y = radius * 0.5 },        -- 150 degrees
    { x = 0, y = -radius },                           -- 270 degrees
    { x = 0, y = 0 }                                  -- center
  },
  {
    { x = radius * 0.5, y = radius * 0.866 },         -- 60 degrees
    { x = -radius, y = 0 },                           -- 180 degrees
    { x = radius * 0.5, y = -radius * 0.866 },        -- 300 degrees
    { x = 0, y = 0 }                                  -- center
  },
  {
    { x = 0, y = radius },                            -- 90 degrees
    { x = -radius * 0.866, y = -radius * 0.5 },       -- 210 degrees
    { x = radius * 0.866, y = -radius * 0.5 },        -- 330 degrees
    { x = 0, y = 0 }                                  -- center
  }
  }

  for j = 1, 4, 1 do
    local spawn_name = "SpawnedSatelliteLaser-"..tostring(id).."-"..tostring(dur)..tostring(radius).."-"..tostring(j)
    local dx = offsets[ran][j].x -- (GetRandomNumber()-0.5)*100
    local dy = offsets[ran][j].y -- (GetRandomNumber()-0.5)*100
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",spawn_name,
  "alliedantistructurevehiclecannoneffect",--
  --"cryosatelliteeffectlvl2",
  --"alliedantistructurevehiclecannoneffect_vet",
  --"Player_2/teamPlayer_2", --"PlyrNeutral/teamPlyrNeutral" doesn't work
  --"SkirmishAllies/teamSkirmishAllies", doesn't work
  --"/team", --TEMP solution, need to make sure Civilian have no alliedantistructurevehicle
  team,
  { X=x+dx, Y=y+dy, Z=z }, -- 位置
  30 -- 朝向
    )
    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", spawn_name, "OVERCHARGING_WEAPON", "true")
  end
end


--Function for debug, spawn a JapanAntiVehicleInfantryTech3 at position (x,y,z)
function Debug_spawn_at_position(x,y,z)
  ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",
  "",
  "JapanAntiVehicleInfantryTech3",
  "Player_1/teamPlayer_1", 
  { X=x, Y=y, Z=z }, -- 位置
  30 -- 朝向
  )
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


function Area_enemy_search_surface_only(x,y,z, radius, ref_object)
  local matchedObjects, count = ObjectFindObjects(ref_object, 
  {X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"}, 
  FilterEnemySelectableSurfaceOnly)
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
function Map_filter_search_radius_limited(x,y,z, radius, filter)
  local matchedObjects, count = Map_filter_search(filter)
  local newArray = {}  -- This will store the filtered elements
  local newSize = 0     -- This will store the new size of the filtered array
  
  for i = 1, count, 1 do
    local cx, cy, cz = ObjectGetPosition(matchedObjects[i])
    local distance = ((cx-x)^2 + (cy-y)^2 + (cz-z)^2)^0.5
    if distance < radius then
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
      if ObjectTestTargetObjectWithFilter(INITIATOR_OBJECT_NEUTRAL, matchedObjects[i], filter) then
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
  local x,y,z = ObjectGetPosition(current)
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


-- This function remove the object at the given index from the Celestial_satellite_cannon_table
-- and updated the table size
function Remove_Celesital_satellite_cannon_from_table(index)
  for i = index, Celestial_satellite_cannon_table.size-1, 1 do
    Celestial_satellite_cannon_table.cannons[i] = Celestial_satellite_cannon_table.cannons[i+1]
    Celestial_satellite_cannon_table.targets[i] = Celestial_satellite_cannon_table.targets[i+1]
  end
  Celestial_satellite_cannon_table.size = Celestial_satellite_cannon_table.size - 1
end

-- ***********************************************************************************
-- *************注意EvaluateCondition 和ExecuteAction的计算成本是LUA的100倍*************
-- *******************************尽量减少这两个函数的调用次数**************************
-- ***********************************************************************************

-- This function check if the object is lightly damaged(health bar is yellow)
function ObjectStatusIsDamaged_Slow(current)
  return EvaluateCondition("UNIT_HAS_OBJECT_STATUS", current, "DAMAGED")
end

--100-66绿血， 65-33黄血， 32-0红血
function ObjectStatusIsDamaged(current)
  local health = ObjectGetCurrentHealth(current) -- 当前血量
  local initialHealth = ObjectGetInitialHealth(current) -- 初始血量
  local healthPercentage = health / initialHealth -- 血量百分比
  return healthPercentage <= 0.65
end

-- This function check if the object is really damaged(health bar is red)
function ObjectStatusIsReallyDamaged_Slow(current)
  return EvaluateCondition("UNIT_HAS_OBJECT_STATUS", current, "REALLYDAMAGED")
end

--100-66绿血， 65-33黄血， 32-0红血
function ObjectStatusIsReallyDamaged(current)
  local health = ObjectGetCurrentHealth(current) -- 当前血量
  local initialHealth = ObjectGetInitialHealth(current) -- 初始血量
  local healthPercentage = health / initialHealth -- 血量百分比
  return healthPercentage <= 0.32
end

-- This function check if the object is using the hold position stance
function ObjectStanceIsHoldPosition_Slow(current)
  return EvaluateCondition("UNIT_USING_STANCE", current, "HOLD_POSITION")
end

function ObjectStanceIsHoldFire_Slow(current)
  return EvaluateCondition("UNIT_USING_STANCE", current, "HOLD_FIRE")
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

-- This function check if a unit is sighted by the first human player and his allies
function UnitSightedbyHumanPlayer_PVE_Slow(current)
  return EvaluateCondition("NAMED_DISCOVERED", "<1st Human Player's Allies incl Self>", current)
end

function UnitStop(current)
  ExecuteAction("NAMED_STOP", current)
end

-- Most object in game can have InfoBox, including map objects, trees, buildings, units, etc
-- Named waypoint cannot have InfoBox
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
function _Rebuild_Table_with_Nils_Removed(table, player_index)
-- Example Table Design:
-- Athena_table = {
--   [1] = {size = 0},  -- Player 1
--   [2] = {size = 0},  -- Player 2
--   [3] = {size = 0},  -- Player 3
--   [4] = {size = 0},  -- Player 4
--   [5] = {size = 0},  -- Player 5
--   [6] = {size = 0},  -- Player 6
--   filter_friendly = CreateObjectFilter({
--     Rule="ANY",
--     Relationship = "ALLIES",
--     IncludeThing={
--       "AlliedAntiStructureVehicle",
--     },
--   }),
--   filter_neutral = CreateObjectFilter({
--     IncludeThing={
--       "AlliedAntiStructureVehicle",
--     },
--   }),
-- }
  local new_table = {}
  local new_time_table = nil
  if table[player_index] == nil then
    _ALERT("_Rebuild_Table_with_Nils_Removed: table[player_index] is nil. player_index = "..tostring(player_index))
    return
  end
  -- Check if the 'time' table exists for this type of Unit 
  if table[player_index].time then
    new_time_table = {}
  end

  local new_size = 0
  local size = table[player_index].size
  for i = 1, size, 1 do
    local current = table[player_index][i]
    if current then
      new_size = new_size + 1
      new_table[new_size] = current
      if new_time_table then
        new_time_table[new_size] = table[player_index].time[i]
      end
    end
  end
  table[player_index] = new_table
  if new_time_table then
    table[player_index].time = new_time_table
  end
  table[player_index].size = new_size
end

function _Rebuild_Dict_in_Table_with_Nils_Removed(table, player_count)
  local new_dict = {}
  local new_size = 0
  if not player_count then
    player_count = 6
  end
  if table.dict_is_in_group then
    for i = 1, player_count, 1 do
      local size = table[i].size
      if size == nil then
        _ALERT("_Rebuild_Dict_in_Table_with_Nils_Removed: player "..tostring(i).." table size is nil")
        return
      end
      for j = 1, size, 1 do
        local current = table[i][j]
        if current then
          local unit_id = ObjectGetId(current)
          new_dict[unit_id] = table.dict_is_in_group[unit_id]
        end
      end
    end
    table.dict_is_in_group = new_dict
  end
end


function _Calculate_FCS_Group_center(fcs_group, fcs_group_size)
  local x = 0
  local y = 0
  local z = 0
  for i = 1, fcs_group_size, 1 do
    local cx, cy, cz = ObjectGetPosition(fcs_group[i])
    x = x + cx
    y = y + cy
    z = z + cz
  end
  x = x / fcs_group_size
  y = y / fcs_group_size
  z = z / fcs_group_size
  return x, y, z
end


-- This function calculate the radius of the group
-- Time complexity: O(n) where n is fcs_group_size
function _Calculate_FCS_Group_radius(fcs_group, fcs_group_size)
  local cx, cy, cz = _Calculate_FCS_Group_center(fcs_group, fcs_group_size)
  local group_radius = 0
  for i = 1, fcs_group_size, 1 do
    local unit = fcs_group[i]
    local x, y, z = ObjectGetPosition(unit)
    local distance_to_center_2D = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy))
    if distance_to_center_2D > group_radius then
      group_radius = distance_to_center_2D
    end
  end
  return group_radius
end

