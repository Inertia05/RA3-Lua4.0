
Unit_visibility_data = {}
G0GlobalSecond = 0
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
  if ObjectIsStructure(current) then
    sighted = EvaluateCondition("NAMED_DISCOVERED", "<1st Human Player's Allies incl Self>", current)
    return sighted
  else
    local current_instance_name = "TEMP-VISIBLE-" .. unit_id .. "-" .. G0GlobalSecond  -- Unique per second

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
    
    -- Spawn a new dummy object with a unique name for this second, ex: "TEMP-VISIBLE-001-60", G0GlobalSecond is 60
    if not data.current_instance then
      ObjectSpawnNamed_Slow(current_instance_name, class_name, team, x, y, z, 30)
    end
    -- Check visibility of the previous instance if it exists
    if data.previous_instance and data.last_checked_time == G0GlobalSecond - 1 then
        data.is_visible = EvaluateCondition("NAMED_DISCOVERED",
        "<1st Human Player's Allies incl Self>", data.previous_instance)
        
        -- Delete the previous temporary object, ex: "TEMP-VISIBLE-001-59"
        ExecuteAction("NAMED_DELETE", data.previous_instance)
        
    end
    
    -- Update unit data for tracking
    data.previous_instance = data.current_instance  -- Move current to previous
    data.current_instance = current_instance_name   -- Update to new current instance
    data.last_checked_time = G0GlobalSecond -- This line prevent the data from being updated again in the same second. 
    -- ex: when G0GlobalSecond is 60, it will not update again until G0GlobalSecond is 61
    
    -- Return the stored visibility result (from the previous second’s evaluation)
    return data.is_visible
  end
end