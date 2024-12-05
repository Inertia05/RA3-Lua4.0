--- @module "Global0VarFun"
--- @module "Global2CEDS"
if Global0VarFun == nil then
    if exMessageAppendToMessageArea then
        exMessageAppendToMessageArea("CRITICAL ERROR: Global0VarFun.lua is missing, reported by Global2CEDS.lua")
    else
        _ALERT("CRITICAL ERROR: Global0VarFun.lua is missing, reported by Global2CEDS.lua")
    end
end
if DEBUG_CORONA_INE then
    if not LOADED_FILES[1] then
        _ALERT("ERROR: Global1FCS.lua must be loaded before Global2CEDS.lua")
    else
        LOADED_FILES[2] = true
    end
end
--- Conditional Evacuation and Deselection System (CEDS)
--- Two components: Conditional Evacuation System (CES) and Conditional Deselection System (CDS) 



--- Define the common unit table structure
--- @param include_one_thing string[]
--- @return UnitCollection
function CreateUnitTable(include_one_thing)
    --- @type UnitCollection
    return {
        -- unit_id and evac_dict is mainly for inter-system communication
        -- so other system know if a unit is evacuating
        -- if we don't store the unit_id, when the unit is dead, 
        -- we will lose the unit_id and can't remove it from the evac_dict
        -- unit in the system is refered by index in the table
        -- ex: ret[1][1] is the first unit of player 1
        --- @type PlayerUnitTable
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

--- @type UnitCollection
Gunship_table = CreateUnitTable({"AlliedGunshipAircraft"})

--- @type UnitCollection
Allied_Interceptor_table = CreateUnitTable({"AlliedInterceptorAircraft"})

--- @type UnitCollection
Celestial_Interceptor_table = CreateUnitTable({"CelestialInterceptorAircraft"})

--- @type UnitCollection
Soviet_Interceptor_table = CreateUnitTable({"SovietInterceptorAircraft"})

--- @type UnitCollection
Allied_Heavy_Bomber_table = CreateUnitTable({"AlliedAntiStructureBomberAircraft"})

--- @type UnitCollection
Allied_Light_Bomber_table = CreateUnitTable({"AlliedAntiGroundAircraft"})

--- @type UnitCollection
Celestial_Bomber_table = CreateUnitTable({"CelestialBomberAircraft"})

--- @type UnitCollection
Soviet_Bomber_table = CreateUnitTable({"SovietAntiGroundAttacker"})

-- CelestialBomberAircraft
-- SovietAntiGroundAttacker

---------- @class HEES : EES_Base -- there is no check on if HEES have function as required by EES_Base, 
-----------Hence we use type instead of class so EmmyLua can still provide some help
--- The Hyperspace Emergency Evacuation System, specific to Gunship units.
--- @type EES_Base
local HEES = {
    name = "HEES",
    evac_text = "HEES-ACTIVE",
    standby_text = "HEES-STANDBY",
    _display_cooldown = 0,
    _DISPLAY_DURATION = 2,
    _MAX_COOLDOWN_UI = 10,
    _MAX_COOLDOWN = 60,
    _EVAC_UNIT_TABLE = Gunship_table, --- global variable should be used AFTER they are defined since this code file run only once
    _EVAC_COMMAND = "Command_AlliedGunshipAircraftHyperSpaceMove",
    --- Check if the system's UI should be displayed.
    --- @param self EES_Base
    --- @return boolean
    shouldDisplaySystemUI = function(self)
        return self._display_cooldown == 0
    end,

    --- Display the system's UI.
    --- @param self EES_Base
    --- @param unit StandardUnitType
    --- @return nil
    --- @usage evac_data:displaySystemUI(unit, 5)
    displaySystemUI = function(self, unit)
        UnitShowInfoBox(unit, self.standby_text, self._DISPLAY_DURATION)
    end,

    --- Update the system's UI cooldown.
    --- @param self EES_Base
    --- @return nil
    updateCooldownUI = function(self)
        if self._display_cooldown > 0 then
            self._display_cooldown = self._display_cooldown - 1
        else
            self._display_cooldown = self._MAX_COOLDOWN_UI
        end
    end,

    --- Check if the unit can evacuate.
    --- @param player_index integer
    --- @param unit_index_in_table integer
    --- @return boolean
    canEvacuate = function(self, player_index, unit_index_in_table)
        local hyper_space_cool_down = self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table]
        return hyper_space_cool_down == 0
    end,

    --- Check if the unit should evacuate conservatively.
    --- @param unit StandardUnitType
    --- @return boolean
    shouldEvacuateConservative = function(self, unit)
        return ObjectStatusIsLightlyDamaged(unit) or ObjectStatusIsReallyDamaged(unit)
    end,

    --- Check if the unit should evacuate aggressively.
    --- @param unit StandardUnitType
    --- @return boolean
    shouldEvacuateAggressive = function(self, unit)
        return ObjectStatusIsReallyDamaged(unit)
    end,

    --- Check if the unit is in a stance that allows evacuation.
    --- @param unit StandardUnitType
    --- @return boolean
    isEvacAllowedByStance = function(self, unit)
        return not ObjectStanceIsAggressive_Slow(unit)
    end,

    --- Check if the unit is in a stance that allows evacuation (defensive).
    --- @param unit StandardUnitType
    --- @return boolean
    isEvacAllowedByStanceDefensive = function(self, unit)
        --- best suitted when gunship are being intercepted by enemy fighters
        return ObjectStanceIsHoldFire_Slow(unit)
    end,

    --- Evacuate the unit.
    --- @param unit StandardUnitType
    --- @param player_index integer
    --- @param player_start string
    --- @param unit_index_in_table integer
    evacuateUnit = function(self, unit, player_index, player_start, unit_index_in_table)
        UnitMoveToNamedWaypoint(unit, player_start)
        UnitUseAbility(unit, self._EVAC_COMMAND)
        self:_resetCooldown(player_index, unit_index_in_table)
        UnitShowInfoBox(unit, self.evac_text, 5)
    end,

    --- Check if the evacuation can be completed.
    --- @param player_index integer
    --- @param unit StandardUnitType
    --- @return boolean
    canCompleteEvacuation = function(self, unit, player_index)
        return true -- always allow completion for HEES
        --return not ObjectStatusIsDamaged(unit)
    end,
    

    --- Complete the evacuation process for the unit.
    --- @param unit StandardUnitType
    --- @param player_index integer
    --- @param unit_index_in_table integer
    completeEvacuation = function(self, unit, player_index, unit_index_in_table)
        -- no additional action needed for HEES
    end,

    --- Update the system's cooldown for the unit.
    --- @param player_index integer
    --- @param unit_index_in_table integer
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
    end,

    --- Reset the system's cooldown for the unit.
    --- @param player_index integer
    --- @param unit_index_in_table integer
    _resetCooldown = function(self, player_index, unit_index_in_table)
        self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table] = self._MAX_COOLDOWN
    end,

    --- Get the stored unit ID.
    --- @param player_index integer
    --- @param unit_index_in_table integer
    --- @return UnitID
    _getUnitIDFromTable = function(self, player_index, unit_index_in_table)
        return self._EVAC_UNIT_TABLE[player_index].unit_id[unit_index_in_table]
    end,

    --- Set the evac dictionary value.
    --- @param player_index integer
    --- @param unit_id UnitID
    --- @param value boolean
    _updateEvacStatus = function(self, player_index, unit_id, value)
        if unit_id == nil then
            _ALERT("FCS_Running_Data.HEES._updateEvacStatus: unit_id is nil")
        else
            self._EVAC_UNIT_TABLE[player_index].evac_dict[unit_id] = value
        end
    end,

    --- Retrieve the evacuation status of a unit by its unit_id.
    --- @param player_index integer
    --- @param unit_id UnitID
    --- @return boolean | nil
    getUnitEvacStatus = function(self, player_index, unit_id)
        return nil -- HEES does not track unit evacuation status
    end

}


--- This function creates an instance of the IEES system with the given parameters.
--- @param evac_table UnitCollection
--- @param evac_command string
--- @param unit_type string | nil
--- @return EES_Base
function CreateEES(evac_table, evac_command, unit_type)
  --- The Intercept Emergency Evaculation System, specific to Interceptor units by default
  --- @type EES_Base
  local IEES = {
    name = "IEES",
    evac_text = "IEES-ACTIVE",
    standby_text = "IEES-STANDBY",
    _display_cooldown = 0,
    _DISPLAY_DURATION = 3,
    _MAX_COOLDOWN = 30,
    _MAX_COOLDOWN_UI = 10,
    _EVAC_UNIT_TABLE = evac_table,
    _EVAC_COMMAND = evac_command,

    --- @return boolean
    shouldDisplaySystemUI = function(self)
        return self._display_cooldown == 0
    end,

    --- @return nil
    displaySystemUI = function(self, unit)
        UnitShowInfoBox(unit, self.standby_text, self._DISPLAY_DURATION)
    end,

    --- @return nil
    updateCooldownUI = function(self)
        if self._display_cooldown > 0 then
            self._display_cooldown = self._display_cooldown - 1
        else
            self._display_cooldown = self._MAX_COOLDOWN_UI
        end
    end,

    canEvacuate = function(self, player_index, unit_index_in_table)
        local evac_cool_down = self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table]
        local unit = self._EVAC_UNIT_TABLE[player_index][unit_index_in_table]
        local cleared_for_landing = ObjectStatusIs( unit, "CLEARED_FOR_LANDING" )
        return evac_cool_down == 0 and (not cleared_for_landing)
    end,

    shouldEvacuateConservative = function(self, unit)
        return ObjectIsDamaged(unit)
    end,

    shouldEvacuateAggressive = function(self, unit)
        return ObjectStatusIsLightlyDamaged(unit) or ObjectStatusIsReallyDamaged(unit)
    end,

    isEvacAllowedByStance = function(self, unit)
        return ObjectStanceIsGuard_Slow(unit) or ObjectStanceIsHoldPosition_Slow(unit)
    end,

    isEvacAllowedByStanceDefensive = function(self, unit)
        return ObjectStanceIsHoldPosition_Slow(unit)
    end,

    evacuateUnit = function(self, unit, player_index, player_start, unit_index_in_table)
        UnitMoveToNamedWaypoint(unit, player_start)
        -- In case there is no airport to return to, the unit will head back to the starting point
        UnitUseAbility(unit, self._EVAC_COMMAND)
        self:_resetCooldown(player_index, unit_index_in_table)
        UnitShowInfoBox(unit, self.evac_text, 5)
        ObjectSetObjectStatusUnselectable_Slow(unit, true)
        local unit_id = self:_getUnitIDFromTable(player_index, unit_index_in_table)
        self:_updateEvacStatus(player_index, unit_id, true)
    end,

    canCompleteEvacuation = function(self, unit, player_index)
        return not ObjectIsDamaged(unit)
    end,

    completeEvacuation = function(self, unit, player_index, unit_index_in_table)
        local unit_id = self:_getUnitIDFromTable(player_index, unit_index_in_table)
        self:_updateEvacStatus(player_index, unit_id, false)
        ObjectSetObjectStatusUnselectable_Slow(unit, false)
    end,

    updateCooldown = function(self, player_index, unit_index_in_table)
        local evac_cool_down = self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table]
        if evac_cool_down == 0 then
            return
        end
        if evac_cool_down > 0 then
            self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table] = evac_cool_down - 1
        else
            self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table] = 0
            _ALERT("FCS_Running_Data.IEES.updateCooldown: evac_cool_down < 0 bug detected")
        end
    end,

    _resetCooldown = function(self, player_index, unit_index_in_table)
        self._EVAC_UNIT_TABLE[player_index].time[unit_index_in_table] = self._MAX_COOLDOWN
    end,

    _getUnitIDFromTable = function(self, player_index, unit_index_in_table)
        return self._EVAC_UNIT_TABLE[player_index].unit_id[unit_index_in_table]
    end,

    _updateEvacStatus = function(self, player_index, unit_id, value)
        if unit_id == nil then
            _ALERT("FCS_Running_Data.IEES._updateEvacStatus: unit_id is nil")
        else
            self._EVAC_UNIT_TABLE[player_index].evac_dict[unit_id] = value
        end
    end,


    --- Retrieve the evacuation status of a unit by its unit_id.
    --- @param player_index integer The index of the player (1-6)
    --- @param unit_id UnitID The unique ID of the unit to check
    --- @return boolean | nil The evacuation status of the unit, or nil if the unit is not found
    getUnitEvacStatus = function(self, player_index, unit_id)
        if unit_id == nil then
            _ALERT("FCS_Running_Data.IEES.getUnitEvacStatus: unit_id is nil for player_index " .. player_index)
            return nil
        end

        local evac_status = self._EVAC_UNIT_TABLE[player_index].evac_dict[unit_id]

        return evac_status
    end

    }

    if (unit_type == "Sukhoi") then --- "Sukhoi" has no hold_position stance
        IEES.evac_text = "SEES-ACTIVE"
        IEES.standby_text = "SEES-STANDBY"

        IEES.shouldEvacuateConservative = function(self, unit)
            return ObjectStatusIsLightlyDamaged(unit) or ObjectStatusIsReallyDamaged(unit)
        end

        IEES.shouldEvacuateAggressive = function(self, unit)
            return ObjectStatusIsReallyDamaged(unit)
        end

        IEES.isEvacAllowedByStance = function(self, unit)
            return true -- always allow evacuation
        end

        IEES.isEvacAllowedByStanceDefensive = function(self, unit)
            return ObjectStanceIsGuard_Slow(unit)
        end
    end

    if (unit_type == "Heavy_Bomber") or (unit_type == "Light_Bomber") then
        IEES.evac_text = "BEES-ACTIVE"
        IEES.standby_text = "BEES-STANDBY"
        IEES.isEvacAllowedByStance = function(self, unit)
            return true -- always allow evacuation
        end
        IEES.isEvacAllowedByStanceDefensive = function(self, unit)
            return not ObjectStanceIsAggressive_Slow(unit)
        end
    end

    if unit_type == "Heavy_Bomber" then
        IEES.shouldEvacuateAggressive = function(self, unit)
            return ObjectStatusIsReallyDamaged(unit)
        end
        IEES.shouldEvacuateConservative = function(self, unit)
            return ObjectStatusIsLightlyDamaged(unit) or ObjectStatusIsReallyDamaged(unit)
        end
    elseif unit_type == "Light_Bomber" then
        IEES.shouldEvacuateAggressive = function(self, unit)
            return ObjectStatusIsLightlyDamaged(unit) or ObjectStatusIsReallyDamaged(unit)
        end
        IEES.shouldEvacuateConservative = function(self, unit)
            return ObjectIsDamaged(unit)
        end
    end
  return IEES
end


--- @class EES_Running_Data
EES_Running_Data = {
  --- Data related to the HEES system (Hyperspace Emergency Evacuation System)
  --- @type EES_Base
  HEES = HEES,

  AIEES = CreateEES(Allied_Interceptor_table, "Command_AlliedFighterAircraftReturnToAirfield", nil),

  CIEES = CreateEES(Celestial_Interceptor_table, "Command_CelestialFighterAircraftReturnToAirfield", nil),

  SIEES = CreateEES(Soviet_Interceptor_table, "Command_SovietFighterAircraftReturnToAirfield", "Sukhoi"),

  AHBEES = CreateEES(Allied_Heavy_Bomber_table, "Command_AlliedAntiGroundAircraftReturnToAirfield", "Heavy_Bomber"),

  ALBEES = CreateEES(Allied_Light_Bomber_table, "Command_AlliedAntiGroundAircraftReturnToAirfield", "Light_Bomber"),

  CBEES = CreateEES(Celestial_Bomber_table, "Command_CelestialFighterAircraftReturnToAirfield", "Light_Bomber"),
  
  SBEES = CreateEES(Soviet_Bomber_table, "Command_SovietFighterAircraftReturnToAirfield", "Light_Bomber"),
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
  --- This function is called every second to process the evacuation decision for each unit.
  --- @param self EES_Running_Data (automatically passed when using ':').
  --- @param evac_system EES_Base The spcific evacuation system (e.g., EES_Running_Data.HEES)
  --- @param unit_table UnitCollection The table containing the units (e.g., Gunship_table).
  processEvacuationDecision = function (self, evac_system, unit_table)
    -- Evacuation System Data
    local debug = false
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
            if debug then
                --UnitShowInfoBox(current, evac_system_name, 2)
            end
            -- Check if the unit is alive
            if not ObjectIsAlive(current) then
                -- Mark the unit for removal
                unit_table[player_index][i] = nil
                rebuild_table = true
            else
                -- Register this unit's ID to the System
                local unit_id = ObjectGetId(current)
                if unit_id == nil then
                    _ALERT("System "..evac_system_name.." found an Alive unit with nil ID when processing player "..player_index.." table")
                else
                    -- only store the unit_id if engine doesn't glitch(ie. unit_id is nil for alive unit)
                    unit_table[player_index].unit_id[i] = unit_id
                end

                -- Check if the evacuation system can evacuate the unit
                if evac_data:canEvacuate(player_index, i) then
                    -- System only shows UI when in hold fire or hold position
                    if evac_data:shouldDisplaySystemUI() then
                        if evac_data:isEvacAllowedByStance(current) then
                            evac_data:displaySystemUI(current)
                        else
                            -- UnitShowInfoBox(current, evac_system_name .. "-INACTIVE", 2) -- Optionally show inactive state
                        end
                    end

                    -- Handle evacuation based on the unit's status
                    if evac_data:shouldEvacuateAggressive(current) then
                        -- if unit is heavily damaged, it's obviously lightly damaged too
                        if evac_data:isEvacAllowedByStance(current) then
                            -- checking stance is slow so only do it when necessary
                            evac_data:evacuateUnit(current, player_index, player_start, i)
                        end
                    elseif evac_data:shouldEvacuateConservative(current) then
                        if evac_data:isEvacAllowedByStanceDefensive(current) then
                            -- only evacuate if stance is more defensive, keep the unit in the fight if not in a defensive stance
                            evac_data:evacuateUnit(current, player_index, player_start, i)
                        end
                    end
                end
                if evac_data:canCompleteEvacuation(current, player_index) then
                    evac_data:completeEvacuation(current, player_index, i)
                end
                
                -- Update the cooldown for the evacuation system
                evac_data:updateCooldown(player_index, i)
            end
        end

        -- Rebuild the table with the nils(dead units) removed
        if rebuild_table then
            if debug then
                _ALERT("Debug msg: System "..evac_system_name.." is rebuilding player "..player_index.." table with size "..size)
            end
            --- @type PlayerUnitTable
            local new_table = {
                size = 0,
                time = {},
                unit_id = {},
                evac_dict = {},
                cooldown_dict = {}
            }
            local new_time_table = {}
            local new_evac_dict = {}
            local new_size = 0
            for unit_index = 1, size, 1 do
                local current = unit_table[player_index][unit_index]
                -- if current is nil or false, then it will be assumed to be dead
                if current then
                    if ObjectIsAlive(current) then
                        -- Only add alive and correctly structured units to the new table
                        new_size = new_size + 1
                        new_table[new_size] = current
                        new_time_table[new_size] = unit_table[player_index].time[unit_index]
                        local unit_id = evac_data:_getUnitIDFromTable(player_index, unit_index)
                        if unit_id == nil then
                            _ALERT("System "..evac_system_name.." found an Alive unit with nil ID when rebuilding player "..player_index.." table")
                        end
                        local is_evac = evac_data:getUnitEvacStatus(player_index, unit_id)
                        if is_evac and unit_id then
                            new_evac_dict[unit_id] = is_evac
                        end
                        -- Evacuation state is only stored if necessary; otherwise, it's left as nil to reduce memory usage.
                    else
                        _ALERT("System "..evac_system_name.." added a dead unit when rebuilding player "..player_index.." table")
                    end
                end
            end
            
            new_table.time = new_time_table
            new_table.size = new_size
            new_table.evac_dict = new_evac_dict

            unit_table[player_index] = new_table
            if debug then
                _ALERT("Debug msg: System "..evac_system_name.." finished rebuilding player "..player_index.." table with size "..new_size)
            end
        end
    end

  end,

}




