

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
    ---@class AOLSCS
    AOLSCS = {
        --- Name of the FCS system
        ---@type string
        name = "AOLSCS",

        --- Dictionary to store allocated targets
        ---@type table<number, boolean>
        target_allocated_dict = {},

        --- Checks if the target can be allocated (detected and not already allocated)
        ---@param self AOLSCS
        ---@param target any The target to be checked for allocation
        ---@return boolean True if the target can be allocated, false otherwise
        canAllocateTarget = function(self, target)
            return not self:isTargetAllocated(target) and UnitSightedbyHumanPlayer_PVE_Slow(target)
        end,

        --- Allocates the target
        ---@param self AOLSCS
        ---@param target any The target to allocate
        allocateTarget = function(self, target)
            local target_id = ObjectGetId(target)
            self.target_allocated_dict[target_id] = true
        end,

        --- Checks if the target is already allocated
        ---@param self AOLSCS
        ---@param target any The target to check
        ---@return boolean True if the target is allocated, false otherwise
        isTargetAllocated = function(self, target)
            local target_id = ObjectGetId(target)
            return self.target_allocated_dict[target_id] ~= nil
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
        if self[fcs] and self[fcs].target_allocated_dict then
            self[fcs].target_allocated_dict = {}
        else
            _ALERT("FCS_Running_Data.resetTargetAllocation: Invalid FCS = " .. fcs)
        end
    end
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
