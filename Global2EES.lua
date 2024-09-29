-- HEES-READY
-- "超时空避险系统(HEES)已就绪"
-- END
--- @type UnitCollection Gunship_table
Gunship_table = { --- global variable should be defined BEFORE they are used since this code file run only once
  [1] = {size = 0, time = {}},  -- Player 1
  [2] = {size = 0, time = {}},  -- Player 2
  [3] = {size = 0, time = {}},  -- Player 3
  [4] = {size = 0, time = {}},  -- Player 4
  [5] = {size = 0, time = {}},  -- Player 5
  [6] = {size = 0, time = {}},  -- Player 6

  filter_friendly = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ALLIES",
    IncludeThing={
      "AlliedGunshipAircraft",
    },
  }),

  filter_neutral = CreateObjectFilter({
    IncludeThing={
      "AlliedGunshipAircraft",
    },
  })
}

--- @type UnitCollection Interceptor_table
Interceptor_table = {
  [1] = {size = 0, time = {}},  -- Player 1
  [2] = {size = 0, time = {}},  -- Player 2
  [3] = {size = 0, time = {}},  -- Player 3
  [4] = {size = 0, time = {}},  -- Player 4
  [5] = {size = 0, time = {}},  -- Player 5
  [6] = {size = 0, time = {}},  -- Player 6
  filter_friendly = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ALLIES",
    IncludeThing={
        "AlliedInterceptorAircraft",
        "CelestialInterceptorAircraft",
        "SovietInterceptorAircraft",
    },
  }),
  filter_neutral = CreateObjectFilter({
    IncludeThing={
        "AlliedInterceptorAircraft",
        "CelestialInterceptorAircraft",
        "SovietInterceptorAircraft",
    },
  }),
}
---------- @class HEES : EES_Base -- there is no check on if HEES have function as required by EES_Base, 
-----------Hence we use type instead of class so EmmyLua can still provide some help
--- The Hyperspace Emergency Evacuation System, specific to Gunship units.
--- @type EES_Base
local HEES = {
  name = "HEES",
  _display_cooldown = 0,
  _MAX_COOLDOWN = 10,
  _EVAC_UNIT_TABLE = Gunship_table, --- global variable should be used AFTER they are defined since this code file run only once

  --- Check if the system's UI should be displayed.
  --- @return boolean
  shouldDisplaySystemUI = function(self)
      return self._display_cooldown == 0
  end,

  --- Update the system's UI cooldown.
  updateCooldownUI = function(self)
      if self._display_cooldown > 0 then
          self._display_cooldown = self._display_cooldown - 1
      else
          self._display_cooldown = self._MAX_COOLDOWN
      end
  end,

  --- Check if the unit can evacuate.
  --- @param player_index number
  --- @param unit_index_in_table number
  --- @return boolean
  canEvacuate = function(self, player_index, unit_index_in_table)
      local hyper_space_cool_down = self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table]
      return hyper_space_cool_down == 0
  end,

  --- Evacuate the unit.
  --- @param unit any
  --- @param player_index number
  --- @param player_start string
  --- @param unit_index_in_table number
  evacuateUnit = function(self, unit, player_index, player_start, unit_index_in_table)
      UnitMoveToNamedWaypoint(unit, player_start)
      UnitUseAbility(unit, "Command_AlliedGunshipAircraftHyperSpaceMove")
      self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table] = 60
      UnitShowInfoBox(unit, "HEES-ACTIVE", 5)
  end,

  --- Update the system's cooldown.
  --- @param player_index number
  --- @param unit_index_in_table number
  updateCooldown = function(self, player_index, unit_index_in_table)
      local hyper_space_cool_down = self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table]
      if hyper_space_cool_down == 0 then
          return
      end
      if hyper_space_cool_down > 0 then
          self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table] = hyper_space_cool_down - 1
      else
          self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table] = 0
          _ALERT("FCS_Running_Data.HEES.updateCooldown: hyper_space_cool_down < 0 bug detected")
      end
  end
}




--- The Interceptor Emergency Evacuation System, specific to Interceptor units.
--- @type EES_Base
local IEES = {
  name = "IEES",
  _display_cooldown = 0,
  _MAX_COOLDOWN = 10,
  _EVAC_UNIT_TABLE = Interceptor_table, 
  

}


--- @class EES_Running_Data
EES_Running_Data = {
  --- Data related to the HEES system (Hyperspace Emergency Evacuation System)
  
  --- @type EES_Base
  HEES = HEES,


  --- Cooldown Update:
  --- evac_data:updateCooldownUI() updates the system's cooldown display.
  --- 
  --- Evacuation Check:
  --- For each unit, evac_data:canEvacuate() determines if the unit is eligible for evacuation.
  --- 
  --- UI Display:
  --- If evacuation is possible, evac_data:shouldDisplaySystemUI() checks if the system's UI should be displayed. 
  --- If true, and the unit's stance is "hold fire" or "hold position," the system status is shown.
  --- System is designed to only be active when the unit is in these stances.

  --- Evacuation Execution:
  --- evac_data:evacuateUnit() evacuates the unit if it's damaged and meets the correct stance requirements.

  --- Cooldown Update for Units:
  --- After processing, evac_data:updateCooldown() adjusts the cooldown for each unit.

  --- Function to manage the evacuation system for units (e.g., gunships, fighters)
  --- This function is called every scond to process the evacuation decision for each unit.
  --- @param self EES_Running_Data (automatically passed when using ':').
  --- @param evac_system EES_Base The spcific evacuation system (e.g., EES_Running_Data.HEES)
  --- @param unit_table UnitCollection The table containing the units (e.g., Gunship_table).
  processEvacuationDecision = function (self, evac_system, unit_table)
      -- Evacuation System Data
      local evac_data = evac_system
      local evac_system_name = evac_data.name
      -- Update the system's cooldown UI
      evac_data:updateCooldownUI()
      -- Iterate through players (assumed to be 6 players)
      for player_index = 1, 6, 1 do
        local size = unit_table[player_index].size
        local player_start = "Player_"..tostring(player_index).."_Start"
        local rebuild_table = false
        
        -- Iterate through the player's units
        for i = 1, size, 1 do
            local current = unit_table[player_index][i]
            
            -- Check if the unit is alive
            if not ObjectIsAlive(current) then
                -- Mark the unit for removal
                unit_table[player_index][i] = nil
                unit_table[player_index].time[i] = nil
                rebuild_table = true
            else
                -- Check if the evacuation system can evacuate the unit
                if evac_data:canEvacuate(player_index, i) then
                    -- System only shows UI when in hold fire or hold position
                    if evac_data:shouldDisplaySystemUI() then
                        if ObjectStanceIsHoldFire_Slow(current) or ObjectStanceIsHoldPosition_Slow(current) then
                            UnitShowInfoBox(current, evac_system_name .. "-READY", 2)
                        else
                            -- UnitShowInfoBox(current, evac_system_name .. "-INACTIVE", 2) -- Optionally show inactive state
                        end
                    end

                    -- Handle evacuation based on the unit's status
                    if ObjectStatusIsReallyDamaged(current) then
                        local stance_hold_fire = ObjectStanceIsHoldFire_Slow(current)
                        local stance_hold_position = ObjectStanceIsHoldPosition_Slow(current)
                        if stance_hold_fire or stance_hold_position then
                            evac_data:evacuateUnit(current, player_index, player_start, i)
                        end
                    elseif ObjectStatusIsDamaged(current) then
                        if ObjectStanceIsHoldFire_Slow(current) then
                            evac_data:evacuateUnit(current, player_index, player_start, i)
                        end
                    end
                end
                
                -- Update the cooldown for the evacuation system
                evac_data:updateCooldown(player_index, i)
            end
        end

        -- Rebuild the table with the nils(dead units) removed
        if rebuild_table then
            local new_table = {}
            local new_time_table = {}
            local new_size = 0
            for i = 1, size, 1 do
                local current = unit_table[player_index][i]
                -- if current is nil or false, then it will be assumed to be dead
                if current then
                  if ObjectIsAlive(current) then
                    -- Only add alive and correctly structured units to the new table
                    new_size = new_size + 1
                    new_table[new_size] = unit_table[player_index][i]
                    new_time_table[new_size] = unit_table[player_index].time[i]
                  else
                    _ALERT("System "..evac_system_name.." added a dead unit when rebuilding player "..player_index.." table")
                  end
                end
            end
            unit_table[player_index] = new_table
            unit_table[player_index].time = new_time_table
            unit_table[player_index].size = new_size
        end
      end

  end,

}





