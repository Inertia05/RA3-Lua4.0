Unit_visibility_data = {}
GlobalSecond = 0

---@class Temp_visibility_objects
Temp_visibility_objects = {
  size = 0,
  --- @type StandardUnitType[]
  objects = {},
  --- @type integer[]
  time_stamp = {},
  --- Rebuild Temp_visibility_objects
  --- @param self Temp_visibility_objects
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
  ---@param self Temp_visibility_objects
  ---@param obj StandardUnitType
  _add = function(self, obj)
    self.size = self.size + 1
    self.objects[self.size] = obj
    self.time_stamp[self.size] = GlobalSecond
  end,
}
--EvaluateCondition("NAMED_DISCOVERED", "<1st Human Player's Allies incl Self>", temp_name_stored)
--ExecuteAction("NAMED_DELETE", temp_name_stored)
--- This function check if a unit is sighted by the first human player and his allies
--- One should not call this function repeatedly on the same unit in the same frame
--- @param current StandardUnitType
--- @return boolean
function UnitSightedbyHumanPlayer_PVE_Slow(current)
  local sighted = false
  local unit_id = ObjectGetId(current)
  if not unit_id then
    _ALERT("UnitSightedbyHumanPlayer_PVE_Slow: id is nil")
    return false
  end
  if not ObjectTestTargetObjectWithFilter(nil, current, FilterSelectable) then
    DEBUG_error("UnitSightedbyHumanPlayer_PVE_Slow: Object is not selectable")
    return false
  end
  if ObjectIsStructure(current) then
    sighted = EvaluateCondition("NAMED_DISCOVERED", "<1st Human Player's Allies incl Self>", current)
    return sighted
  else
    local current_instance_name = "TEMP-VISIBLE-" .. unit_id .. "-" .. GlobalSecond  -- Unique per second

    -- Initialize unit data if it doesn't exist
    if not Unit_visibility_data[unit_id] then
      Unit_visibility_data[unit_id] = {
            current_instance = nil,
            previous_instance = nil,
            is_visible = false,
            last_checked_time = 0
        }
    end
    
    -- Reference to the unit's data
    local data = Unit_visibility_data[unit_id]
    
    -- Get unit position for spawning
    local x, y, z = ObjectGetIntPosition(current)
    local class_name = "DummyEngineer"
    local team = "/team"
    local current_instance = nil
    -- Spawn a new dummy object with a unique name for this second, ex: "TEMP-VISIBLE-001-60", GlobalSecond is 60
    if not data.current_instance then
      ObjectSpawnNamed_Slow(current_instance_name, class_name, team, x, y, z, 30)
      current_instance = GetObjectByScriptName(current_instance_name)
      Temp_visibility_objects:_add(current_instance) -- Add to the list for garbage collection
    end
    -- Check visibility of the previous instance if it exists
    if data.previous_instance then
      if data.last_checked_time == GlobalSecond - 1 then
        data.is_visible = EvaluateCondition("NAMED_DISCOVERED",
        "<1st Human Player's Allies incl Self>", data.previous_instance)
        -- Delete the previous temporary object, ex: "TEMP-VISIBLE-001-59"
        ObjectDelete_Slow(data.previous_instance) --- delete it asap to avoid massive deletion in Temp_visibility_objects:_rebuild()
        data.previous_instance = nil
      else
        -- if data.last_checked_time ~= GlobalSecond then
          
        --   ExecuteAction("NAMED_DELETE", data.previous_instance)
        --   data.previous_instance = nil
        -- end
      end
    end
    
    -- Update unit data for tracking
    -- if data.previous_instance and ObjectIsAlive(data.previous_instance) then
    --   ExecuteAction("NAMED_DELETE", data.previous_instance)
    -- end
    data.previous_instance = data.current_instance  -- Move current to previous

    -- if data.current_instance and ObjectIsAlive(data.current_instance) then
    --   ExecuteAction("NAMED_DELETE", data.current_instance)
    -- end
    if current_instance then
      data.current_instance = current_instance -- Update to new current instance
    end
    data.last_checked_time = GlobalSecond -- This line prevent the data from being updated again in the same second. 
    -- ex: when GlobalSecond is 60, it will not update again until GlobalSecond is 61
    
    -- Return the stored visibility result (from the previous second’s evaluation)
    return data.is_visible
  end
  
  --- GARBAGE COLLECTION
  --- Units may die and the tracking for the spawned instances will be lost
  --- need an external function to clean up the orphaned data
  --- see Temp_visibility_objects:_rebuild()
end