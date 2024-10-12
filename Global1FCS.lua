

-- AOLSCS-ACTIVE
-- "盟军轨道激光打击协调系统(AOLSCS)运行中"
-- END

-- STBMFAS-ACTIVE
-- "苏军战术弹道导弹火力分配系统(STBMFAS)工作中"
-- END

--- FCS_Running_Data manages the timing and target allocation for different FCS systems.
---@class FCS_Running_Data
FCS_Running_Data = {
    --- Global timer for all systems, resets every second
    ---@type number
    _global_timer = 0,

    --- The maximum value for the global timer before it resets
    ---@type number
    _GLOBAL_TIMER_MAX = 60,

    --- Constant values for target allocation reset intervals (in seconds)
    ---@type table<string, number>
    _TARGET_ALLOCATION_RESET_INTERVAL = {AOLSCS = 10, STBMFAS = 10},



    --- Data related to the AOLSCS system (Allied Orbital Laser Strike Coordination System)
    ---@class AOLSCS:FCS
    AOLSCS = {
        --- Name of the FCS system
        ---@type string
        name = "AOLSCS",

        --- Dictionary to store allocated targets
        ---@type table<UnitID, boolean>
        target_allocated_dict = {},
        --- Dictionary to store artillery that has been assigned to a target
        --- @type table<UnitID, boolean>
        artillery_allocated_dict = {},

        --- Checks if the target can be allocated (detected and not already allocated)
        ---@param self AOLSCS
        ---@param target any The target to be checked for allocation
        ---@return boolean True if the target can be allocated, false otherwise
        canAllocateTarget = function(self, target)
            return not self:isTargetAllocated(target) and UnitSightedbyHumanPlayer_PVE_Slow(target)
        end,

        --- Checks if the artillery can be allocated to the target
        --- @param self AOLSCS
        --- @param artillery StandardUnitType The artillery unit to be checked
        --- @param target StandardUnitType The target to be checked
        --- @return boolean True if the artillery can be allocated, false otherwise
        canAllocateArtilleryToTarget = function(self, artillery, target)
            -- TODO
            return true
            -- return not self:isArtilleryAllocated(artillery) and self:canAllocateTarget(target)
        end,

        --- Allocates the target
        ---@param self AOLSCS
        ---@param artillery StandardUnitType The artillery unit to be allocated to the target
        ---@param target StandardUnitType The target to be allocated to one or more artillery units
        allocateArtilleryToTarget = function(self, artillery, target)
            local target_id = ObjectGetId(target)
            if target_id == nil then
                _ALERT("FCS_Running_Data.AOLSCS.allocateTarget: Invalid target")
                return
            end
            local artillery_id = ObjectGetId(artillery)
            if artillery_id == nil then
                _ALERT("FCS_Running_Data.AOLSCS.allocateTarget: Invalid artillery")
                return
            end
            self.target_allocated_dict[target_id] = true
            self.artillery_allocated_dict[artillery_id] = true
            UnitAttackTarget(artillery, target)
        end,

        --- Checks if the target is already allocated
        ---@param self AOLSCS
        ---@param target any The target to check
        ---@return boolean True if the target is allocated, false otherwise
        isTargetAllocated = function(self, target)
            local target_id = ObjectGetId(target)
            if target_id == nil then
                _ALERT("FCS_Running_Data.AOLSCS.isTargetAllocated: Invalid target")
                return false
            end
            return self.target_allocated_dict[target_id] ~= nil
        end,

        --- Checks if the artillery is already allocated to a target
        --- @param self AOLSCS
        --- @param artillery StandardUnitType The artillery unit to check
        --- @return boolean True if the artillery is allocated, false otherwise
        isArtilleryAllocated = function(self, artillery)
            local artillery_id = ObjectGetId(artillery)
            if artillery_id == nil then
                _ALERT("FCS_Running_Data.AOLSCS.isArtilleryAllocated: Invalid artillery")
                return false
            end
            return self.artillery_allocated_dict[artillery_id] ~= nil
        end
    },



    --- Updates the global timer, resetting it if it reaches 0
    ---@param self FCS_Running_Data
    updateTimers = function(self)
        if self._global_timer <= 0 then
            self._global_timer = self._GLOBAL_TIMER_MAX
        else
            self._global_timer = self._global_timer - 1
        end
    end,

    --- Retrieves the current value of the global timer
    ---@param self FCS_Running_Data
    ---@return number The current global timer value
    getGlobalTimer = function(self)
        return self._global_timer
    end,

    --- Checks if it's time to reset the target allocation for the given FCS
    ---@param self FCS_Running_Data
    ---@param fcs string The FCS system to check (e.g., "AOLSCS", "STBMFAS")
    ---@return boolean True if it's time to reset target allocation, false otherwise
    isTimeToResetTargetAllocation = function(self, fcs)
        local interval = self._TARGET_ALLOCATION_RESET_INTERVAL[fcs]

        if interval == nil then
            _ALERT("FCS_Running_Data.isTimeToResetTargetAllocation: Invalid FCS = " .. fcs)
            return false
        end

        -- Check if the global timer is divisible by the reset interval
        if interval > 0 and (self._global_timer / interval) == floor(self._global_timer / interval) then
            return true
        end
        

        return false
    end,

    --- Resets the target allocation for a given FCS system
    ---@param self FCS_Running_Data
    ---@param fcs string The FCS system to reset (e.g., "AOLSCS", "STBMFAS")
    resetTargetAllocation = function(self, fcs)
        if self[fcs] then
            self[fcs].target_allocated_dict = {}
            self[fcs].artillery_allocated_dict = {}
        else
            _ALERT("FCS_Running_Data.resetTargetAllocation: Invalid FCS = " .. fcs)
        end
    end,

    --- This function find and group nearby units
    --- @param self FCS_Running_Data
    --- @param current StandardUnitType
    --- @param grouping_range_threshold number
    --- @param artillery_grouped table a dictionary that record if an artillery is already grouped
    --- @param player_index integer the index of the player
    --- @param fcs string the name of the FCS
    --- @param artillery_table UnitCollection the table of artillery
    --- @return StandardUnitType[] the array of grouped units
    --- @return integer the size of the array
    _findAndGroupNearbyUnits = function (self, current, grouping_range_threshold, artillery_grouped, player_index, fcs, artillery_table)
        local radius = grouping_range_threshold
        local matchedObjects, count = Area_Friendly_Unit_filter_search(current, radius, artillery_table.filter_friendly)
        local fcs_group = {}
        local fcs_group_size = 0

        if count > 1 then
            for j = 1, count, 1 do
                local current_artillery = matchedObjects[j]
                if ObjectIsAlive(current_artillery) then
                    local current_artillery_id = ObjectGetId(current_artillery)
                    if current_artillery_id ~= nil then
                        artillery_grouped[current_artillery_id] = true
                        if ObjectStanceIsHoldPosition_Slow(current_artillery) then
                            fcs_group_size = fcs_group_size + 1
                            fcs_group[fcs_group_size] = current_artillery
                            if FCS_Active_Display:isDisplayAllowed(player_index, fcs) then
                                FCS_Active_Display:displayOnUnit(current_artillery, player_index, fcs)
                            end
                        end
                    end
                end
            end
        end

        return fcs_group, fcs_group_size
    end,

    --- Function to search for targets and allocate to the artillery
    --- @param self FCS_Running_Data
    --- @param fcs_group StandardUnitType[] the array of grouped units
    --- @param fcs_group_size integer the size of the array
    --- @param artillery_range integer the range of the artillery
    --- @param current StandardUnitType
    --- @param player_index integer
    --- @param fcs string
    _searchAndAllocateTargets = function (self, fcs_group, fcs_group_size, artillery_range, current, player_index, fcs)
        local group_radius = FCS_Running_Data:_calculate_FCS_Group_radius(fcs_group, fcs_group_size)
        local guaranteed_radius = artillery_range - group_radius
        local cx, cy, cz = FCS_Running_Data:_calculate_FCS_Group_center(fcs_group, fcs_group_size)
        local matchedTargets, target_count = Area_enemy_search_surface_only(cx, cy, cz, guaranteed_radius, current)
        --- @type FCS
        local fcs_data = FCS_Running_Data[fcs]
        local target_marked_count = 0
        -- allocate one target in guaranteed_radius to each artillery
        for artillery_index = 1, fcs_group_size, 1 do
            local artillery = fcs_group[artillery_index]
            local artillery_x, artillery_y, artillery_z = ObjectGetPosition(artillery)
            for target_index = 1, target_count, 1 do
                local target = matchedTargets[target_index]
                if fcs_data:canAllocateTarget(target) then
                    fcs_data:allocateArtilleryToTarget(artillery, target)
                    target_marked_count = target_marked_count + 1
                    break
                end
            end
            if target_marked_count == target_count then
                break
            end
        end

        if target_marked_count < fcs_group_size then
            -- Some units still need targets, search individually
            for artillery_index = target_marked_count + 1, fcs_group_size, 1 do
                local artillery = fcs_group[artillery_index]
                local artillery_x, artillery_y, artillery_z = ObjectGetPosition(artillery)
                local matchedTargets, target_count = Area_enemy_search_surface_only(artillery_x, artillery_y, artillery_z, artillery_range, current)
                for target_index = 1, target_count, 1 do
                    local target = matchedTargets[target_index]
                    if fcs_data:canAllocateTarget(target) then
                        fcs_data:allocateArtilleryToTarget(artillery, target)
                        break
                    end
                end
            end
        end
    end,

    --- Group and allocate targets for the artillery
    --- @param self FCS_Running_Data
    --- @param artillery_table UnitCollection
    --- @param player_index integer
    --- @param artillery_grouping_range_threshold any
    --- @param artillery_range any
    --- @param fcs any
    groupAndAllocateTargets = function (self, artillery_table, player_index, artillery_grouping_range_threshold, artillery_range, fcs)
        local size = artillery_table[player_index].size
        local rebuild_table = false
        local artillery_grouped = {}
        local fcs_data = FCS_Running_Data[fcs]
        for i = 1, size, 1 do
            local current = artillery_table[player_index][i]
            if not ObjectIsAlive(current) then
                artillery_table[player_index][i] = nil
                rebuild_table = true
            else
                local artillery_id = ObjectGetId(current)
                local is_in_group = artillery_grouped[artillery_id]
                local is_allocated = FCS_Running_Data[fcs]:isArtilleryAllocated(current)
                local current_target = ObjectFindTarget(current)

                if (not is_allocated) and (not is_in_group) then
                    local fcs_group, fcs_group_size = self:_findAndGroupNearbyUnits(current, 
                    artillery_grouping_range_threshold, artillery_grouped, 
                    player_index, fcs, artillery_table)
                    
                    if fcs_group_size > 1 then
                        self:_searchAndAllocateTargets(fcs_group, fcs_group_size, artillery_range, current, player_index, fcs)
                    else
                        if ObjectStanceIsHoldPosition_Slow(current) then
                            local x, y, z = ObjectGetPosition(current)
                            local matchedTargets, target_count = Area_enemy_search_surface_only(x, y, z, artillery_range, current)
                            for target_index = 1, target_count, 1 do
                                local target = matchedTargets[target_index]
                                if fcs_data:canAllocateTarget(target) then
                                    fcs_data:allocateArtilleryToTarget(current, target)
                                    if FCS_Active_Display:isDisplayAllowed(player_index, fcs) then
                                        FCS_Active_Display:displayOnUnit(current, player_index, fcs)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        if rebuild_table then
            _Rebuild_Table_with_Nils_Removed(artillery_table, player_index)
        end
    end,

    --- Calculate the center of the group
    --- Time complexity: O(n) where n is fcs_group_size
    --- @param fcs_group table<number, StandardUnitType> The group of units
    --- @param fcs_group_size number The size of the group
    --- @return number, number, number The x, y, z coordinates of the group center
    _calculate_FCS_Group_center = function(self, fcs_group, fcs_group_size)
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
    end,
  
  
    --- This function calculate the radius of the group
    --- Time complexity: O(n) where n is fcs_group_size
    --- @param fcs_group table<number, StandardUnitType> The group of units
    --- @param fcs_group_size number The size of the group
    --- @return number The radius of the group
    _calculate_FCS_Group_radius = function(self, fcs_group, fcs_group_size)
        local cx, cy, cz = self:_calculate_FCS_Group_center(fcs_group, fcs_group_size)
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
    end,
  
  

}



--- FCS_Active_Display manages the display of various FCS systems (AOLSCS, STBMFAS)
---@class FCS_Active_Display
FCS_Active_Display = {
    --- Cooldown time in seconds (constant)
    ---@type table<string, number>
    _COOLDOWN = {HEES = 5, AOLSCS = 4, STBMFAS = 4},

    --- Display duration in seconds (constant)
    ---@type table<string, number>
    _DURATION = {HEES = 2, AOLSCS = 2, STBMFAS = 2},

    --- Player-specific FCS data
    ---@type table<number, table<string, any>>
    [1] = {HEES = true, AOLSCS = {timer = 0}, STBMFAS = {timer = 0}},  -- Player 1
    [2] = {HEES = true, AOLSCS = {timer = 0}, STBMFAS = {timer = 0}},  -- Player 2
    [3] = {HEES = true, AOLSCS = {timer = 0}, STBMFAS = {timer = 0}},  -- Player 3
    [4] = {HEES = true, AOLSCS = {timer = 0}, STBMFAS = {timer = 0}},  -- Player 4
    [5] = {HEES = true, AOLSCS = {timer = 0}, STBMFAS = {timer = 0}},  -- Player 5
    [6] = {HEES = true, AOLSCS = {timer = 0}, STBMFAS = {timer = 0}},  -- Player 6

    --- Displays FCS information on the unit's info box
    ---@param self FCS_Active_Display
    ---@param unit any Unit to display the info box on
    ---@param player_index number The index of the player
    ---@param FCS string The name of the FCS system (e.g., "HEES", "AOLSCS", "STBMFAS")
    displayOnUnit = function(self, unit, player_index, FCS)
        local current = unit
        if current == nil then
            _ALERT("FCS_Active_Display: unit is nil")
            return
        end
        if FCS == "HEES" then
            UnitShowInfoBox(current, "HEES-READY", self._DURATION.HEES)
        elseif FCS == "AOLSCS" then
            UnitShowInfoBox(current, "AOLSCS-ACTIVE", self._DURATION.AOLSCS)
        elseif FCS == "STBMFAS" then
            UnitShowInfoBox(current, "STBMFAS-ACTIVE", self._DURATION.STBMFAS)
        else
            _ALERT("FCS_Active_Display: Invalid FCS")
        end
    end,

    --- Checks if display is allowed for a specific FCS system
    ---@param self FCS_Active_Display
    ---@param player_index number The index of the player
    ---@param FCS string The name of the FCS system (e.g., "HEES", "AOLSCS", "STBMFAS")
    ---@return boolean True if display is allowed, false otherwise
    isDisplayAllowed = function(self, player_index, FCS)
        if FCS == nil then
            _ALERT("isDisplayAllowed: FCS is nil")
            return false
        end
        if FCS == "HEES" then
            return self[player_index].HEES
        elseif FCS == "AOLSCS" then
            return self[player_index].AOLSCS.timer == 0
        elseif FCS == "STBMFAS" then
            return self[player_index].STBMFAS.timer == 0
        else
            _ALERT("isDisplayAllowed: Invalid FCS")
            return false
        end
    end,

    --- Updates timers for each FCS system for all players, reducing the timer by 1 each second.
    ---@param self FCS_Active_Display
    updateTimers = function(self)
        for player_index = 1, 6, 1 do
            -- Update AOLSCS timer
            if self[player_index].AOLSCS.timer > 0 then
                self[player_index].AOLSCS.timer = self[player_index].AOLSCS.timer - 1
            else
                -- Timer is 0, reset to the cooldown
                self[player_index].AOLSCS.timer = self._COOLDOWN.AOLSCS
            end

            -- Update STBMFAS timer
            if self[player_index].STBMFAS.timer > 0 then
                self[player_index].STBMFAS.timer = self[player_index].STBMFAS.timer - 1
            else
                -- Timer is 0, reset to the cooldown
                self[player_index].STBMFAS.timer = self._COOLDOWN.STBMFAS
            end
        end
    end
}



--- @type UnitCollection Athena_table
Athena_table = {
    [1] = {size = 0, time = {}, unit_id = {}, evac_dict = {}}, -- Player 1
    [2] = {size = 0, time = {}, unit_id = {}, evac_dict = {}}, -- Player 2
    [3] = {size = 0, time = {}, unit_id = {}, evac_dict = {}}, -- Player 3
    [4] = {size = 0, time = {}, unit_id = {}, evac_dict = {}}, -- Player 4
    [5] = {size = 0, time = {}, unit_id = {}, evac_dict = {}}, -- Player 5
    [6] = {size = 0, time = {}, unit_id = {}, evac_dict = {}}, -- Player 6

    filter_friendly = CreateObjectFilter({
    Rule="ANY",
    Relationship = "ALLIES",
    IncludeThing={
        "AlliedAntiStructureVehicle",
    },
    }),
    filter_neutral = CreateObjectFilter({
    IncludeThing={
        "AlliedAntiStructureVehicle",
    },
    }),
}




-- TODO
function FireControlSystem(unit_table, unit_range, grouping_range_threshold, 
  player_count, filter_friendly, enemy_search_func, target_action_func, rebuild_func, fcs_display_func)
    -- Iterate over all players
    if player_count == nil then
        player_count = 6 -- Default to 6 players 
        --since game allow max 6 independent human/AI players with 2 more map dependent AI players.
    end
    for player_index = 1, player_count, 1 do
        local size = unit_table[player_index].size
        local rebuild_table = false
        local target_marked = {}
        local unit_grouped = {}
        local active_display_allowed = true

        -- First pass: detect dead units and process each alive unit
        -- TODO

        if not active_display_allowed then
            -- Disable active display
            fcs_display_func(player_index, false)
        end

        -- Second pass: rebuild table if necessary
        if rebuild_table then
            rebuild_func(unit_table, player_index)
        end
    end
end



-- -- example
-- -- FireControlSystem(Athena_table, 1000, 200, 6, Athena_table.filter_friendly, 
-- --                   Area_enemy_search_surface_only, UnitAttackTarget, 
-- --                   _Rebuild_Table_with_Nils_Removed, FCS_Active_Display_Allowed)



-- -- FireControlSystem(MissileLauncher_table, 2000, 500, 6, MissileLauncher_table.filter_friendly, 
-- --                   Area_enemy_search_surface_only, UnitAttackTarget, 
-- --                   _Rebuild_Table_with_Nils_Removed, FCS_Active_Display_Allowed)
