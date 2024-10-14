--- @module "Global0VarFun" 
-- AOLSCS-ACTIVE
-- "盟军轨道激光打击协调系统(AOLSCS)运行中"
-- END

-- STBMFAS-ACTIVE
-- "苏军战术弹道导弹火力分配系统(STBMFAS)工作中"
-- END



--- FCS_Running_Data manages the timing and target allocation for different FCS systems.
---@type FCS_Running_Data
FCS_Running_Data = {
    --- Global timer for all systems, count down from 60 to 0
    _global_timer = 0,

    --- The maximum value for the global timer before it resets
    _GLOBAL_TIMER_MAX = 60,

    --- Constant values for target allocation reset intervals (in seconds)
    _TARGET_ALLOCATION_RESET_INTERVAL = {AOLSCS = 10, STBMFAS = 10, CSFAS = 10, ATFACS = 15},

    --- Constant values for artillery stance info reset intervals (in seconds)

    _ARTILLERY_STANCE_RESET_INTERVAL = {AOLSCS = 15, STBMFAS = 15, CSFAS = 30, ATFACS = 30},


    -- assigned in Global3FCSs.lua
    --- @type FCS
    AOLSCS = nil,
    --- @type FCS
    CSFAS = nil,
    --- @type FCS
    ATFACS = nil,



    --- Updates the global timer, resetting it if it reaches 0
    updateTimers = function(self)
        if self._global_timer <= 0 then
            self._global_timer = self._GLOBAL_TIMER_MAX
        else
            self._global_timer = self._global_timer - 1
        end
    end,

    --- Retrieves the current value of the global timer
    getGlobalTimer = function(self)
        return self._global_timer
    end,

    --- Checks if it's time to reset artillery stance info for the given FCS
    isTimeToResetArtilleryStanceInfo = function(self, fcs)
        local interval = self._ARTILLERY_STANCE_RESET_INTERVAL[fcs]

        if interval == nil then
            _ALERT("FCS_Running_Data.isTimeToResetArtilleryStanceInfo: Invalid FCS = " .. fcs ..
                " or _ARTILLERY_STANCE_RESET_INTERVAL not defined")
            return false
        end

        -- Check if the global timer is divisible by the reset interval
        if interval > 0 and (self._global_timer / interval) == floor(self._global_timer / interval) then
            return true
        end

        return false
    end,

    --- Resets the artillery stance info for a given FCS system
    resetArtilleryStanceInfo = function(self, fcs_name)
        --- @type FCS
        local fcs = self[fcs_name]
        if fcs then
            fcs.artillery_stance_dict = {}
        else
            _ALERT("FCS_Running_Data.resetArtilleryStanceInfo: Invalid FCS = " .. fcs_name)
        end
    end,

    --- Checks if it's time to reset the target allocation for the given FCS
    isTimeToResetTargetAllocation = function(self, fcs)
        local interval = self._TARGET_ALLOCATION_RESET_INTERVAL[fcs]

        if interval == nil then
            _ALERT("FCS_Running_Data.isTimeToResetTargetAllocation: Invalid FCS = " .. fcs ..
                " or _TARGET_ALLOCATION_RESET_INTERVAL not defined")
            return false
        end

        -- Check if the global timer is divisible by the reset interval
        if interval > 0 and (self._global_timer / interval) == floor(self._global_timer / interval) then
            return true
        end
        

        return false
    end,

    --- Resets the target allocation for a given FCS system
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
    --- @param fcs FCSName the name of the FCS
    --- @param artillery_table UnitCollection the table of artillery
    --- @return StandardUnitType[] the array of grouped units
    --- @return integer the size of the array
    _findAndGroupNearbyUnits = function (self, current, grouping_range_threshold,
        artillery_grouped, player_index, fcs, artillery_table)
        local radius = grouping_range_threshold
        local matchedObjects, count = Area_Friendly_Unit_filter_search(current, radius, artillery_table.filter_friendly)
        local fcs_group = {}
        local fcs_group_size = 0
        --- @type FCS
        local fcs_data = FCS_Running_Data[fcs]
        if count > 1 then
            for j = 1, count, 1 do
                local current_artillery = matchedObjects[j]
                if ObjectIsAlive(current_artillery) then
                    local current_artillery_id = ObjectGetId(current_artillery)
                    if current_artillery_id ~= nil then
                        -- Grouped is to make sure we travserse each artillery only once
                        artillery_grouped[current_artillery_id] = true
                        -- Only add artillery that can be allocated and are in hold position to the group
                        local current_target = ObjectFindTarget(current_artillery)
                        if fcs_data:canAllocateArtillery(current_artillery, current_target) then
                            fcs_group_size = fcs_group_size + 1
                            fcs_group[fcs_group_size] = current_artillery
                            if (FCS_Active_Display:isDisplayAllowed(player_index, fcs)) then
                                --and j == 1) then
                                FCS_Active_Display:displayOnUnit(current_artillery, player_index, fcs)
                            end
                        else
                            -- _ALERT("FCS_Running_Data:_findAndGroupNearbyUnits: artillry in group range but cannot be allocated")
                        end
                    end
                end
            end
        end

        return fcs_group, fcs_group_size
    end,

    --- Function to allocate targets to a group of artillery units
    --- @param self FCS_Running_Data
    --- @param fcs_group StandardUnitType[] the array of grouped units
    --- @param fcs_group_size integer the size of the array
    --- @param artillery_range integer the range of the artillery
    --- @param current StandardUnitType
    --- @param player_index integer
    --- @param fcs FCSName
    _allocateTargetsToGroup  = function (self, fcs_group, 
        fcs_group_size, artillery_range, current, player_index, fcs)
        local group_radius = FCS_Running_Data:_calculate_FCS_Group_radius(fcs_group, fcs_group_size)
        local guaranteed_radius = artillery_range - group_radius
        local max_radius = artillery_range + group_radius

        local cx, cy, cz = FCS_Running_Data:_calculate_FCS_Group_center(fcs_group, fcs_group_size)
        local matchedTargets, target_count = Area_enemy_search_surface_only(cx, cy, cz, max_radius, current)
        if target_count == 0 then
            return -- no targets to allocate. Time to relax 
        end
        matchedTargets, target_count = Area_enemy_search_surface_only(cx, cy, cz, guaranteed_radius, current)
        --- @type FCS
        local fcs_data = FCS_Running_Data[fcs]
        local target_marked_count = 0
        -- allocate one target in guaranteed_radius to each artillery
        for artillery_index = 1, fcs_group_size, 1 do
            local artillery = fcs_group[artillery_index]
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

        -- Handle any leftover artillery that didn't receive a target
        if target_marked_count < fcs_group_size then
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
    groupArtilleryAndAllocateTargets = function (self, player_index, fcs)
        local rebuild_table = false
        local artillery_grouped = {}
        --- @type FCS
        local fcs_data = FCS_Running_Data[fcs]
        local artillery_table = fcs_data.artillery_table
        local size = artillery_table[player_index].size
        if DEBUG_CORONA_INE and size > 1 then
            _ALERT("groupArtilleryAndAllocateTargets: player_index = "..player_index..", fcs = "..fcs)
        end
        local artillery_range = fcs_data.artillery_range
        local artillery_grouping_range_threshold = fcs_data.artillery_grouping_range_threshold
        for i = 1, size, 1 do
            local current = artillery_table[player_index][i]
            if not ObjectIsAlive(current) then
                artillery_table[player_index][i] = nil
                rebuild_table = true
            else
                local artillery_id = ObjectGetId(current)
                artillery_table[player_index].unit_id[i] = artillery_id
                local is_in_group = artillery_grouped[artillery_id]
                local is_allocated = fcs_data:isArtilleryAllocated(current)
                if (not is_allocated) and (not is_in_group) then
                    -- form a group
                    local fcs_group, fcs_group_size = self:_findAndGroupNearbyUnits(current, 
                    artillery_grouping_range_threshold, artillery_grouped, 
                    player_index, fcs, artillery_table)
                    
                    if fcs_group_size > 1 then
                        -- process the group
                        self:_allocateTargetsToGroup (fcs_group, fcs_group_size, artillery_range, current, player_index, fcs)
                    else
                        -- process the individual unit(size 1 group)
                        local current_target = ObjectFindTarget(current)
                        if fcs_data:canAllocateArtillery(current, current_target) then
                            local x, y, z = ObjectGetPosition(current)
                            local matchedTargets, target_count = Area_enemy_search_surface_only(x, y, z, artillery_range, current)
                            if FCS_Active_Display:isDisplayAllowed(player_index, fcs) then
                                FCS_Active_Display:displayOnUnit(current, player_index, fcs)
                            end
                            for target_index = 1, target_count, 1 do
                                local target = matchedTargets[target_index]
                                if fcs_data:canAllocateTarget(target) then
                                    fcs_data:allocateArtilleryToTarget(current, target)
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
            if DEBUG_CORONA_INE then
                _ALERT("Rebuilt table".." player index = "..player_index..
                ", size = "..artillery_table[player_index].size..", size reduced by "..size - artillery_table[player_index].size)
            end
        end
    end,

    --- Calculate the center of the group
    --- Time complexity: O(n) where n is fcs_group_size
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

--- @type FCSName[]
local fcs_list = {
    "AOLSCS",
    --"STBMFAS",
    "CSFAS",
    "ATFACS",
}

local fcs_list_size = getn(fcs_list)

---@return table<FCSName, table<string, number>>
local createFCSTimerTable = function(fcs_list, size)
    local timer_table = {}
    for i = 1, size, 1 do
        local fcs = fcs_list[i]
        timer_table[fcs] = {timer = 0, should_reset = false}
    end
    return timer_table
end

local cooldown_list = {}
local duration_list = {}
for i = 1, fcs_list_size, 1 do
    local fcs = fcs_list[i]
    cooldown_list[fcs] = 30
    duration_list[fcs] = 5
end


--- FCS_Active_Display manages the display of various FCS systems (AOLSCS, STBMFAS) on the unit's info box.
---@class FCS_Active_Display
---@field _COOLDOWN table<FCSName, number> Cooldown time in seconds (constant)
---@field _DURATION table<FCSName, number> Display duration in seconds (constant)
FCS_Active_Display = {
    _fcs_list = fcs_list,
    _size = fcs_list_size,
    _COOLDOWN = cooldown_list,
    _DURATION = duration_list,
    --- system will be displayed instantly when it is activated
    --- (when system detected that player have changed the stance to allow the system to activate)
    --- detection interval every 15-30 seconds
    

    [1] = createFCSTimerTable(fcs_list, fcs_list_size),
    [2] = createFCSTimerTable(fcs_list, fcs_list_size),
    [3] = createFCSTimerTable(fcs_list, fcs_list_size),
    [4] = createFCSTimerTable(fcs_list, fcs_list_size),
    [5] = createFCSTimerTable(fcs_list, fcs_list_size),
    [6] = createFCSTimerTable(fcs_list, fcs_list_size),



    --- Displays FCS information on the unit's info box
    ---@param self FCS_Active_Display
    ---@param unit StandardUnitType Unit to display the info box on
    ---@param player_index number The index of the player
    ---@param FCS FCSName The name of the FCS system (e.g., "HEES", "AOLSCS", "STBMFAS")
    displayOnUnit = function(self, unit, player_index, FCS)
        local current = unit
        if current == nil then
            _ALERT("FCS_Active_Display: unit is nil")
            return
        end
        if self._DURATION[FCS] then
            UnitShowInfoBox(unit, FCS .. "-ACTIVE", self._DURATION[FCS])
            self[player_index][FCS].should_reset = true
        else
            _ALERT("FCS_Active_Display: Invalid FCS")
        end
    end,

    --- Checks if display is allowed for a specific FCS system
    ---@param self FCS_Active_Display
    ---@param player_index number The index of the player
    ---@param FCS FCSName The name of the FCS system (e.g., "HEES", "AOLSCS", "STBMFAS")
    ---@return boolean True if display is allowed, false otherwise
    isDisplayAllowed = function(self, player_index, FCS)
        if FCS == nil then
            _ALERT("isDisplayAllowed: FCS is nil")
            return false
        end
        local player_fcs_data = self[player_index][FCS]
        if player_fcs_data then
            return player_fcs_data.timer == 0
        else
            _ALERT("isDisplayAllowed: Invalid FCS")
            return false
        end
    end,

    --- Helper function to update a specific FCS timer for a player
    ---@param self FCS_Active_Display
    ---@param player_index number The index of the player
    ---@param fcs FCSName The name of the FCS system
    _updateFCSTimer = function(self, player_index, fcs)
        local fcs_data = self[player_index][fcs]
        if fcs_data.timer > 0 then
            fcs_data.timer = fcs_data.timer - 1
        else
            if fcs_data.timer < 0 then
                fcs_data.timer = 0
                _ALERT("FCS_Active_Display: Negative timer value")
            end
            if fcs_data.should_reset then
                fcs_data.timer = self._COOLDOWN[fcs]  -- Reset to cooldown
                fcs_data.should_reset = false
            end
        end
    end,

    --- Updates timers for each FCS system for all players, reducing the timer by 1 each second.
    ---@param self FCS_Active_Display
    updateTimers = function(self)
        for player_index = 1, 6, 1 do
            for i = 1, self._size, 1 do
                --- @type FCSName
                local fcs = self._fcs_list[i]
                self:_updateFCSTimer(player_index, fcs)
            end
        end
    end,
}









