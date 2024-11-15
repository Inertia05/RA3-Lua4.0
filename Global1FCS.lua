--- @module "Global0VarFun" 
--- @module "Global1FCS"
if Global0VarFun == nil then
    if exMessageAppendToMessageArea then
        exMessageAppendToMessageArea("CRITICAL ERROR: Global0VarFun.lua is missing, reported by Global1FCS.lua")
    else
        _ALERT("CRITICAL ERROR: Global0VarFun.lua is missing, reported by Global1FCS.lua")
    end
end
if DEBUG_CORONA_INE then
    if not LOADED_FILES[0] then
        _ALERT("ERROR: Global0VarFun.lua must be loaded before Global1FCS.lua")
    else
        LOADED_FILES[1] = true
    end
end
DEBUG_ATFACS_ACTIVE = false
DEBUG_CSFAS_ACTIVE = false
-- AOLSCS-ACTIVE
-- "盟军轨道激光打击协调系统(AOLSCS)已启动, 取消固守模式以关闭"
-- END

-- STBMFAS-ACTIVE
-- "苏军战术弹道导弹火力分配系统(STBMFAS)已启动, 取消固守模式以关闭"
-- END

-- CSFAS-ACTIVE
-- "神州亚轨道火力分配系统(CSFAS)已启动, 进入侵略或警戒模式以关闭"
-- END

-- ATFACS-ACTIVE
-- "盟军战术火力分配与协调系统(ATFACS)已启动, 取消固守模式以关闭"
-- END

-- CASCS-ACTIVE
-- "神州火炮打击协调系统(CASCS)已启动, 取消固守模式以关闭"
-- END

-- ECMICS-ACTIVE
-- “帝国巡航导弹集成指挥系统(ECMICS)已启动，取消固守模式以关闭”
-- END
-- Empire Cruise Missile Integrated Command System (ECMICS)

--- @type FCSName[]
local fcs_list = {}
fcs_list[1] = "AOLSCS"
fcs_list[2] = "STBMFAS"
fcs_list[3] = "CSFAS"
fcs_list[4] = "ATFACS"
fcs_list[5] = "CASCS"
fcs_list[6] = "ECMICS"

local fcs_list_size = getn(fcs_list)

--- FCS_Running_Data manages the timing and target allocation for different FCS systems.
---@type FCS_Running_Data
FCS_Running_Data = {
    --- Global timer for all systems, count down from 60 to 0
    _global_timer = 0,

    --- The maximum value for the global timer before it resets
    _GLOBAL_TIMER_MAX = 60,

    --- Constant values for target allocation reset intervals (in seconds)
    _TARGET_ALLOCATION_RESET_INTERVAL = {
        AOLSCS = 10, -- Laser attack interval is 10 seconds
        STBMFAS = 10, 
        CSFAS = 10, 
        ATFACS = 5, -- Reload is 15 seconds, but we want to search for new targets every 5 seconds
        CASCS = 10,
        ECMICS = 10
    },

    --- Constant values for artillery stance info reset intervals (in seconds)
    _ARTILLERY_STANCE_RESET_INTERVAL = { -- Max system activation/deactivation reaction time
    -- ex, for reset interval = 15
    -- if stance change to active at t = 14, then the system will be activated at t = 15, reaction time = 1
    -- if stance change to active at t = 1, then the system will still be activated at t = 15, reaction time = 14
        -- AOLSCS = 15, STBMFAS = 15, CSFAS = 30, ATFACS = 30
        AOLSCS = 15, STBMFAS = 15, CSFAS = 15, ATFACS = 15, CASCS = 15, ECMICS = 15
    },

    pve_target_visibility_dict = {},

    -- assigned in Global3FCSs.lua
    --- @type FCS
    AOLSCS = nil,
    --- @type FCS
    CSFAS = nil,
    --- @type FCS
    ATFACS = nil,
    --- @type FCS
    STBMFAS = nil,
    --- @type FCS
    CASCS = nil,
    --- @type FCS
    ECMICS = nil,


    --- Updates the global timer, resetting it if it reaches 0
    updateTimers = function(self)
        if self._global_timer <= 0 then
            self._global_timer = self._GLOBAL_TIMER_MAX
        else
            self._global_timer = self._global_timer - 1
        end

        --- Reset visibility dictionary every second
        -- if (self._global_timer / 5) == floor(self._global_timer / 5) then
            self.pve_target_visibility_dict = {}
        --end
    end,

    --- Retrieves the current value of the global timer
    getGlobalTimer = function(self)
        return self._global_timer
    end,

    --- Checks if it's time to reset artillery stance info for the given FCS
    isTimeToResetArtilleryStanceInfo = function(self, fcs)
        local interval = tolerant_floor(self._ARTILLERY_STANCE_RESET_INTERVAL[fcs])
        local time = tolerant_floor(self._global_timer)
        if interval == nil then
            _ALERT("FCS_Running_Data.isTimeToResetArtilleryStanceInfo: Invalid FCS = " .. fcs ..
                " or _ARTILLERY_STANCE_RESET_INTERVAL not defined")
            return false
        end
        
        if time < interval then
            return false
        end

        -- Check if the global timer is divisible by the reset interval
        if interval > 0 and mod(time, interval) == 0 then
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
        local interval = tolerant_floor(self._TARGET_ALLOCATION_RESET_INTERVAL[fcs])
        local time = tolerant_floor(self._global_timer)

        if interval == nil then
            _ALERT("FCS_Running_Data.isTimeToResetTargetAllocation: Invalid FCS = " .. fcs ..
                " or _TARGET_ALLOCATION_RESET_INTERVAL not defined")
            return false
        end

        if time < interval then
            return false
        end

        -- Check if the global timer is divisible by the reset interval
        if interval > 0 and mod(time, interval) == 0 then
            return true
        end
        

        return false
    end,

    --- Resets the target allocation for a given FCS system
    resetTargetAllocation = function(self, fcs)
        --- @type FCS
        local fcs_data = self[fcs]
        if self[fcs] then
            fcs_data.target_allocated_dict = {}
            fcs_data.artillery_allocated_dict = {}
            fcs_data.artillery_to_target_dict = {}
        else
            _ALERT("FCS_Running_Data.resetTargetAllocation: Invalid FCS = " .. fcs)
        end
    end,

    --- Function to check if a target is visible to the player
    --- *****Currently only supports PVE visibility for human player*****
    --- @param self FCS_Running_Data
    --- @param target StandardUnitType The target to check
    --- @return boolean True if the target is visible, false otherwise
    isTargetVisiblePVE = function(self, target)
        local target_id = ObjectGetId(target)
        if target_id == nil then
            _ALERT("FCS_Running_Data.isTargetVisible: Invalid target")
            return false
        end
        local target_visibility = self.pve_target_visibility_dict[target_id]
        if target_visibility == nil then
            target_visibility = UnitSightedbyHumanPlayer_PVE_Slow(target)
            self.pve_target_visibility_dict[target_id] = target_visibility
        end
        return target_visibility
    end,

    --- This function find and group nearby units
    --- @param self FCS_Running_Data
    --- @param current StandardUnitType
    --- @param grouping_range_threshold integer
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
        if count > 1 then --- no need to manage artillery that's alone
            for j = 1, count, 1 do
                local current_artillery = matchedObjects[j]
                if ObjectIsAlive(current_artillery) then
                    local current_artillery_id = ObjectGetId(current_artillery)
                    if (current_artillery_id ~= nil and 
                        not fcs_data:isArtilleryAllocated(current_artillery)) then
                        -- Grouped is to make sure we traverse each artillery only once
                        artillery_grouped[current_artillery_id] = true
                        -- Only add artillery that can be allocated(due to commander setting) to the group
                        if fcs_data:canAllocateArtillery(current_artillery) then --- @TODO
                            fcs_group_size = fcs_group_size + 1
                            fcs_group[fcs_group_size] = current_artillery
                            if (FCS_Active_Display:isDisplayAllowed(player_index, fcs)) then
                                --and j == 1) then
                                FCS_Active_Display:displayOnUnit(current_artillery, player_index, fcs)
                            end
                        else
                            -- _ALERT("FCS_Running_Data:_findAndGroupNearbyUnits: artillery in group range but cannot be allocated")
                        end
                    end
                end
            end
        end

        return fcs_group, fcs_group_size
    end,

    --- Function to search and prioritize targets for a group of artillery units
    --- @param self FCS_Running_Data
    --- @param fcs_group StandardUnitType[] the array of grouped units
    --- @param fcs_group_size integer the size of the array
    --- @param current StandardUnitType
    --- @param player_index integer
    --- @param fcs FCSName
    --- @return TargetLists
    _prioritizeTargetsForGroup = function (self, 
        fcs_group, fcs_group_size, 
        current, player_index, fcs)
        --- @type FCS
        local fcs_data = FCS_Running_Data[fcs]
        local artillery_range = fcs_data.artillery_range
        local guaranteed_radius = artillery_range
        local max_radius = artillery_range
        if fcs_group_size > 1 then
            local group_radius = FCS_Running_Data:_calculate_FCS_Group_radius(fcs_group, fcs_group_size)
            guaranteed_radius = artillery_range - group_radius
            max_radius = artillery_range + group_radius
        end
        local cx, cy, cz = FCS_Running_Data:_calculate_FCS_Group_center(fcs_group, fcs_group_size)
        local allPotentialTargets, allPotentialTargetsCount = Area_enemy_search_surface_only(cx, cy, cz, max_radius, current)

        --- @type TargetLists
        local target_lists = {size = 0, target_list_sizes = {},
        all_potential_targets = allPotentialTargets, all_potential_targets_size = allPotentialTargetsCount}
        if allPotentialTargetsCount == 0 then
            return target_lists
        end
        local guaranteedTargetsCount = 0
        if fcs_data.isPrecisionStrike then
            --- prioritize static structures over surface units 
            target_lists.size = 3
            local matchedStructureTargets, structureTargetCount = Area_enemy_structure_search(cx, cy, cz, guaranteed_radius, current)
            target_lists[1] = matchedStructureTargets
            target_lists.target_list_sizes[1] = structureTargetCount
            
            local matchedSurfaceUnitTargets, surfaceUnitTargetCount = Area_enemy_surface_unit_search(cx, cy, cz, guaranteed_radius, current)
            local true_arr, true_count, false_arr, false_count = SplitArray(matchedSurfaceUnitTargets, surfaceUnitTargetCount, 
            fcs_data.isHighValueTarget)
            target_lists[2] = true_arr
            target_lists.target_list_sizes[2] = true_count

            target_lists[3] = false_arr
            target_lists.target_list_sizes[3] = false_count

            guaranteedTargetsCount = structureTargetCount + surfaceUnitTargetCount
        else
            local matchedGenericTargets, genericTargetCount = Area_enemy_search_surface_only(cx, cy, cz, guaranteed_radius, current)
            target_lists.size = 1
            target_lists[1] = matchedGenericTargets
            target_lists.target_list_sizes[1] = genericTargetCount

            guaranteedTargetsCount = genericTargetCount
        end
        if DEBUG_CORONA_INE and guaranteedTargetsCount == 0 then
            _ALERT("_prioritizeTargetsForGroup: There is "..allPotentialTargetsCount.." potential targets but no guaranteed targets, "
            ..fcs..", player index = "..player_index)
        end
        return target_lists

    end,

    --- Function to allocate targets to a group of artillery units
    --- @param self FCS_Running_Data
    --- @param fcs_group StandardUnitType[] the array of grouped units
    --- @param fcs_group_size integer the size of the array
    --- @param current StandardUnitType
    --- @param player_index integer
    --- @param fcs FCSName
    --- @param target_lists TargetLists
    _allocateTargetsToGroup  = function (self,
        fcs_group, fcs_group_size,
        current, player_index, fcs,
        target_lists)
        local number_of_target_lists = target_lists.size
        if number_of_target_lists == 0 then
            if DEBUG_CORONA_INE then
                _ALERT("_allocateTargetsToGroup: No targets to allocate, exiting. fcs = "
                ..fcs..", player index = "..player_index)
            end
            return --- no targets to allocate
        end
        --- @type FCS
        local fcs_data = FCS_Running_Data[fcs]
        local artillery_allocated_count = 0
        for i = 1, number_of_target_lists, 1 do
            local current_target_list = target_lists[i]
            local target_count = target_lists.target_list_sizes[i]
            local targets_allocated_count  = 0
            if target_count > 0 then 
                -- allocate one target in guaranteed_radius to each artillery
                for target_index = 1, target_count, 1 do
                    local target = current_target_list[target_index]
                    if fcs_data:canAllocateTarget(target) then
                        if fcs_data.isPrecisionStrike and (not ObjectIsStructure(target)) and
                            fcs_data:isLowValueTarget(target) then
                            -- skip low value targets for precision strike in guaranteed_radius target allocation
                        else
                            for artillery_index = artillery_allocated_count + 1, fcs_group_size, 1 do
                                local artillery = fcs_group[artillery_index]
                                if fcs_data:canAllocateArtilleryToTarget(artillery, target) then 
                                    fcs_data:allocateArtilleryToTarget(artillery, target)
                                    targets_allocated_count  = targets_allocated_count  + 1
                                    artillery_allocated_count = artillery_allocated_count + 1
                                    if not fcs_data:canAllocateTarget(target) then
                                        break --- target allocated, move to next target
                                    end
                                end
                            end
                        end
                    end
                    if artillery_allocated_count == fcs_group_size then
                        --- all artillery units have been allocated
                        if DEBUG_CORONA_INE then
                            _ALERT("_allocateTargetsToGroup: All "..fcs_group_size.." artillery units have been allocated, "..
                            "to "..targets_allocated_count.." targets in guaranteed radius, "..
                            "fcs = "..fcs..", player index = "..player_index)   
                        end
                        return --- end target allocation for this group
                    end
                    if DEBUG_CORONA_INE then
                        _ALERT("_allocateTargetsToGroup: No valid targets found in list "..i.." for fcs = "..fcs..", player index = "..player_index)
                    end
                end
            end
            if artillery_allocated_count == fcs_group_size then
                --- all artillery units have been allocated
                if DEBUG_CORONA_INE then
                    _ALERT("_allocateTargetsToGroup: All "..fcs_group_size.." artillery units have been allocated, "..
                    "to "..targets_allocated_count.." targets in guaranteed radius, "..
                    "fcs = "..fcs..", player index = "..player_index)   
                end
                return --- end target allocation for this group
            end
        end

        -- Handle any leftover artillery that didn't receive a target
        --- assume 
        --- p = remaining artillery count = p
        --- k = remaining target count (outside guaranteed_radius but inside max_radius)
        --- n = average target count returned by Area_enemy_search_surface_only
        --- N = total unit count on the map
        --- time complexity:
        --- if we allocate targets by doing a search for each artillery unit,
        ---     O(p * (n+log(N))
        --- if we instead allocate targets by group, 
        ---     O(p * k)
        --- if k is much smaller than n(ex: target rich environment), then the second approach is more efficient
        if artillery_allocated_count < fcs_group_size then
            local all_potential_targets = target_lists.all_potential_targets
            local all_potential_targets_size = target_lists.all_potential_targets_size
            local all_guaranteed_target_count = 0
            for i = 1, number_of_target_lists, 1 do
                all_guaranteed_target_count = all_guaranteed_target_count + target_lists.target_list_sizes[i]
            end
            if all_guaranteed_target_count == all_potential_targets_size then
                if DEBUG_CORONA_INE then
                    _ALERT("_allocateTargetsToGroup: No remaining targets to allocate after guaranteed targets. fcs = "..fcs..", player index = "..player_index)
                end
            end
            if DEBUG_CORONA_INE then
                local p = fcs_group_size - artillery_allocated_count
                local k = all_potential_targets_size - all_guaranteed_target_count
                _ALERT("_allocateTargetsToGroup: Allocating ".. p .." artillery units to "..k.." targets outside guaranteed radius, "..
                "fcs = "..fcs..", player index = "..player_index)
            end
            for target_index = 1, all_potential_targets_size, 1 do
                local target = all_potential_targets[target_index]
                if fcs_data:canAllocateTarget(target) then
                    for artillery_index = artillery_allocated_count + 1, fcs_group_size, 1 do
                        local artillery = fcs_group[artillery_index]
                        local distance = tolerant_floor(ObjectsDistance3D(artillery, target))
                        if distance <= fcs_data.artillery_range then
                            if fcs_data:canAllocateArtilleryToTarget(artillery, target) then
                                fcs_data:allocateArtilleryToTarget(artillery, target)
                                artillery_allocated_count = artillery_allocated_count + 1
                                if not fcs_data:canAllocateTarget(target) then
                                    break --- target allocated, move to next target
                                end
                            else
                                -- if DEBUG_CORONA_INE then
                                --     _ALERT("_allocateTargetsToGroup: Artillery unit "..artillery_index..
                                --     " could not be allocated to target "..target_index..
                                --     " due to allocation constraints. fcs = "..fcs..", player index = "..player_index)
                                -- end
                            end
                        else
                            -- if DEBUG_CORONA_INE then
                            --     _ALERT("_allocateTargetsToGroup: Target "..target_index..
                            --     " is outside of range of artillery unit "..artillery_index..
                            --     ", fcs = "..fcs..", player index = "..player_index)
                            -- end
                        end
                    end
                end
            end
        end

        if artillery_allocated_count < fcs_group_size then
            --- some artillery units are not allocated due to lack of targets
            if DEBUG_CORONA_INE then
                _ALERT("_allocateTargetsToGroup: ".. (fcs_group_size - artillery_allocated_count) ..
                " artillery units left unallocated due to lack of valid targets. fcs = "..fcs..", player index = "..player_index)
            end
        end
    end,

    --- Group and allocate targets for the artillery
    groupArtilleryAndAllocateTargets = function (self, player_index, fcs)
        local rebuild_table = false
        local artillery_grouped = {}
        local debug_system_active = false
        --- @type FCS
        local fcs_data = FCS_Running_Data[fcs]
        local artillery_table = fcs_data.artillery_table
        local size = artillery_table[player_index].size
        -- if DEBUG_CORONA_INE and size > 1 then
        --     _ALERT("groupArtilleryAndAllocateTargets: player_index = "..player_index..", fcs = "..fcs)
        -- end
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
                --- 3. Target Reallocation System
                --- when target is destroyed, either by artillery itself or by other means
                if fcs_data:shouldReallocateArtillery(current) then
                    fcs_data:resetArtilleryAllocation(current)
                    --- basically allow immediate reallocation after current target is destroyed
                    if DEBUG_CORONA_INE then
                        _ALERT("Artillery reallocated, player index = "..player_index..", fcs = "..fcs)
                    end
                end
                local is_allocated = fcs_data:isArtilleryAllocated(current)
                if (not is_allocated) and (not is_in_group) then
                    -- form a group
                    local fcs_group, fcs_group_size = self:_findAndGroupNearbyUnits(current, 
                    artillery_grouping_range_threshold, artillery_grouped, 
                    player_index, fcs, artillery_table)
                    if fcs_group_size > 0 then
                        -- process the group
                        --- 1. Target Prioritization System
                        local target_lists = self:_prioritizeTargetsForGroup(fcs_group, fcs_group_size, 
                        current, player_index, fcs)
                        --- 2. Fire Allocation and Deconfliction System
                        self:_allocateTargetsToGroup (fcs_group, fcs_group_size, 
                        current, player_index, fcs, target_lists)
                        if DEBUG_CORONA_INE then 
                            if not DEBUG_ATFACS_ACTIVE and fcs == "ATFACS" then
                                _ALERT(fcs.."System activated for group size = "..fcs_group_size..", player index = "..player_index)
                                DEBUG_ATFACS_ACTIVE = true
                            end
                            if not DEBUG_CSFAS_ACTIVE and fcs == "CSFAS" then
                                _ALERT(fcs.."System activated for group size = "..fcs_group_size..", player index = "..player_index)
                                DEBUG_CSFAS_ACTIVE = true
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
            local cx, cy, cz = ObjectGetIntPosition(fcs_group[i])
            x = x + cx
            y = y + cy
            z = z + cz
        end
        x = tolerant_floor(x / fcs_group_size)
        y = tolerant_floor(y / fcs_group_size)
        z = tolerant_floor(z / fcs_group_size)
        return x, y, z
    end,
  
  
    --- This function calculate the radius of the group
    --- Time complexity: O(n) where n is fcs_group_size
    --- @param fcs_group table<number, StandardUnitType> The group of units
    --- @param fcs_group_size integer The size of the group
    --- @return integer The radius of the group
    _calculate_FCS_Group_radius = function(self, fcs_group, fcs_group_size)
        local cx, cy, cz = self:_calculate_FCS_Group_center(fcs_group, fcs_group_size)
        local group_radius_sqr = 0
        for i = 1, fcs_group_size, 1 do
            local unit = fcs_group[i]
            local x, y, z = ObjectGetIntPosition(unit)
            local distance_to_center_2D_sqr = (x - cx)^2 + (y - cy)^2
            if distance_to_center_2D_sqr > group_radius_sqr then
                group_radius_sqr = distance_to_center_2D_sqr
            end
        end
        return tolerant_floor(sqrt(group_radius_sqr))
    end,

    --- Main function to run the FCS system
    --- @param self FCS_Running_Data
    --- @param fcs FCSName
    runFCS = function (self, fcs)
        if self:isTimeToResetTargetAllocation(fcs) then
            self:resetTargetAllocation(fcs)
            -- if DEBUG_CORONA_INE then
            --     _ALERT("Target allocation reset for " .. fcs)
            -- end
        end
        if self:isTimeToResetArtilleryStanceInfo(fcs) then
            self:resetArtilleryStanceInfo(fcs)
            -- if DEBUG_CORONA_INE then
            --     _ALERT("Artillery stance info reset for " .. fcs)
            -- end
        end
        for player_index = 1, 6, 1 do
            self:groupArtilleryAndAllocateTargets(player_index, fcs)
        end
    end
}



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
---@field _COOLDOWN table<FCSName, integer> Cooldown time in seconds (constant)
---@field _DURATION table<FCSName, integer> Display duration in seconds (constant)
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
    ---@param player_index integer The index of the player
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
    ---@param player_index integer The index of the player
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
    ---@param player_index integer The index of the player
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






