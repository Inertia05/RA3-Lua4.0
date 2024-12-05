-- Celestial_Artillery_table
---@class FCS_Distributed
---@field artillery_table UnitCollection
---@field range integer
---@field target_allocated_dict table<UnitID, integer>
---@field forbidden_target_dict table<UnitID, boolean>
---@field friendly_exclusion_radius integer
---@field friendly_exclusion_radius_static integer
---@field enemy_in_range_dict table<UnitID, Delayed_Boolean>
---@field system_display_dict table<UnitID, Delayed_Boolean>
---@field artillery_to_target_ratio integer
---@field canAllocateTarget fun(self: FCS_Distributed, target: StandardUnitType): boolean
---@field allocateTarget fun(self: FCS_Distributed, artillery: StandardUnitType, target: StandardUnitType)
---@field canAllocateArtillery fun(self: FCS_Distributed, artillery: StandardUnitType): boolean

---@class Delayed_Boolean
---@field bool "true"| "false"
---@field falseCountDown  integer
---@field new fun(bool: "true" | "false"): Delayed_Boolean
---@field setToTrue fun(self: Delayed_Boolean)
---@field setToFalse fun(self: Delayed_Boolean)


---@type Delayed_Boolean
Delayed_Boolean = {
    bool = "false",
    falseCountDown  = 0,
        --- Creates a new instance of Delayed_Boolean
    ---@return Delayed_Boolean
    new = function(bool)
        local countdown = 0
        if bool == "true" then
            countdown = 15
        end
        return {
            bool = bool or "false", -- Default to "false" if not provided
            falseCountDown = countdown, -- Default to 0 if not provided
            setToTrue = Delayed_Boolean.setToTrue,
            setToFalse = Delayed_Boolean.setToFalse,
        }
    end,
    setToTrue = function(self)
        self.bool = "true"
        self.falseCountDown  = 15
    end,
    setToFalse = function(self)
        if self.falseCountDown  > 0 then
            self.falseCountDown  = self.falseCountDown  - 1
        else
            self.bool = "false"
        end
    end
}

--- @type FCS_Distributed
FCS_D_CA = {
    artillery_table = Celestial_Artillery_table,
    range = 1300,
    target_allocated_dict = {},
    forbidden_target_dict = {},
    friendly_exclusion_radius = 300,
    friendly_exclusion_radius_static = 100,
    enemy_in_range_dict = {}, --- no reset since player won't built 1000s of artillery
    system_display_dict = {},

    artillery_to_target_ratio = 3,
    canAllocateTarget = function (self, target)
        if self.forbidden_target_dict[ObjectGetId(target)] then
            return false
        end
        if (not FCS_Running_Data:isTargetVisiblePVE(target)) then
            return false
        end
        local target_id = ObjectGetId(target)
        local allocated_artillery_count = self.target_allocated_dict[target_id]
        if not allocated_artillery_count then
            return true
        else
            return allocated_artillery_count < self.artillery_to_target_ratio
        end
    end,

    allocateTarget = function(self, artillery, target)
        UnitAttackTarget(artillery, target)
        local target_id = ObjectGetId(target)
        if not target_id then
            _ALERT("Target ID is nil in FCS_Distributed:allocateTarget")
        else
            if not self.target_allocated_dict[target_id] then
                self.target_allocated_dict[target_id] = 1
            else
                self.target_allocated_dict[target_id] = self.target_allocated_dict[target_id] + 1
            end
        end
    end,

    canAllocateArtillery = function(self, artillery)
        ---@type Delayed_Boolean
        local delayed_boolean = self.enemy_in_range_dict[ObjectGetId(artillery)]
        if delayed_boolean.bool  == "false" then
            if tolerant_int_mod(GetFrame(), 15) ~= 0 then
                return false
            end
        end
        local current_target = ObjectFindTarget(artillery)
        if current_target then
            local target_id = ObjectGetId(current_target)
            if self.forbidden_target_dict[target_id] then
                if ObjectGetDelayedStance(artillery) == "GUARD" then
                    ObjectSetStance_Slow(artillery, "HOLD_FIRE")
                    ObjectSetStance_Slow(artillery, "GUARD")
                elseif ObjectGetDelayedStance(artillery) == "HOLD_POSITION" then
                    ObjectSetStance_Slow(artillery, "HOLD_FIRE")
                    ObjectSetStance_Slow(artillery, "HOLD_POSITION")
                end
                return true
            end
            return false            
        end
        if ObjectGetDelayedStance(artillery) == "GUARD" then
            return not ObjectTestModelCondition(artillery, "MOVING")
        elseif ObjectGetDelayedStance(artillery) == "HOLD_POSITION" then
            return true
        else
            return false
        end
    end
}


Celestial_Melee_Mech_table = CreateUnitTable({"CelestialAntiVehicleVehicleTech4"})

--- @class FCS_D
--- @field enemy_in_range_for_player table<integer, boolean>
--- @field runFCS_D fun(self: FCS_D)
--- @field searchAndAllocateTargets fun(self: FCS_D, player_index: integer, fcs_d: FCS_Distributed)
--- @field allocateArtilleryToTargets fun(self: FCS_D, fcs_d: FCS_Distributed, artillery: StandardUnitType, targetList: StandardUnitType[], targetCount: integer): boolean

--- @type FCS_D
FCS_D = {
    
    enemy_in_range_for_player = {
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false,
        [6] = false,
    },
    runFCS_D = function(self) --- This is being called per frame. 15 frames per second
        
        for player_index = 1, 6, 1 do
            if self.enemy_in_range_for_player[player_index] then
                IFF:markForbiddenTargets(player_index, FCS_D_CA)
                self:searchAndAllocateTargets(player_index, FCS_D_CA)
                FCS_D_CA.forbidden_target_dict = {}
            else
                if tolerant_int_mod(GetFrame(), 15) == 0 then 
                    self:searchAndAllocateTargets(player_index, FCS_D_CA)
                end
            end
        end
        if tolerant_int_mod(GetFrame(), 30) == 0 then --- allow fire power to double on same target every 15 frames
            --_ALERT("Frame = "..GetFrame())
            FCS_D_CA.target_allocated_dict = {}
        end
    end,

    ---@param self FCS_D
    ---@param player_index integer
    ---@param fcs_d FCS_Distributed
    searchAndAllocateTargets = function (self, player_index, fcs_d)
        local rebuild_table = false
        local enemy_in_range_for_player = false
        local artillery_table = fcs_d.artillery_table
        local size = artillery_table[player_index].size
        local range = fcs_d.range

        for i = 1, size, 1 do
            local current = artillery_table[player_index][i]
            if not ObjectIsAlive(current) then
                artillery_table[player_index][i] = nil
                rebuild_table = true
            else
                local artillery_id = ObjectGetId(current)
                local delayed_boolean = fcs_d.enemy_in_range_dict[artillery_id]
                local system_displayed = fcs_d.system_display_dict[artillery_id]
                if not delayed_boolean then
                    if artillery_id then
                        fcs_d.enemy_in_range_dict[artillery_id] = Delayed_Boolean.new("true")
                        --- default to true. will go to false if there are no targets for 1 second
                        delayed_boolean = fcs_d.enemy_in_range_dict[artillery_id]
                    end
                end
                if not system_displayed then
                    if artillery_id then
                        fcs_d.system_display_dict[artillery_id] = Delayed_Boolean.new("true")
                        system_displayed = fcs_d.system_display_dict[artillery_id]
                    end
                end
                
                local inFCSStance = ObjectGetDelayedStance(current) == "GUARD" or ObjectGetDelayedStance(current) == "HOLD_POSITION"
                if ObjectStatusIs(current, "NO_AUTO_ACQUIRE") then
                    -- do nothing
                    if not inFCSStance then
                        ObjectSetObjectStatus_Slow(current, "NO_AUTO_ACQUIRE", false)
                    end
                else
                    if inFCSStance then
                        ObjectSetObjectStatus(current, "NO_AUTO_ACQUIRE")
                    end
                end
                if fcs_d:canAllocateArtillery(current) then
                    local x,y,z = ObjectGetIntPosition(current)
                    local matchedArtillery, artilleyCount = Unit_enemy_artillery_search(current, range)

                    local target_assigned = self:allocateArtilleryToTargets(fcs_d, current, matchedArtillery, artilleyCount)
                    local target_count = 0
                    if not target_assigned then
                        local matchedObjects, count = Unit_enemy_search_surface_only(current, range)
                        target_count = count
                        target_assigned = self:allocateArtilleryToTargets(fcs_d, current, matchedObjects, count)
                    end
                    if not enemy_in_range_for_player and target_assigned then
                        enemy_in_range_for_player = true
                    end
                    
                    
                    if artilleyCount > 0 or target_count > 0 then
                        delayed_boolean:setToTrue()
                        if system_displayed.bool == "false" then
                            UnitShowInfoBox(current, "CASCS-ACTIVE", 3)
                            system_displayed:setToTrue()
                        end
                    else
                        delayed_boolean:setToFalse()
                    end
                end
                system_displayed:setToFalse()
                
            end
        end

        if rebuild_table then
            _Rebuild_Table_with_Nils_Removed(artillery_table, player_index)
            if DEBUG_CORONA_INE then
                _ALERT("Rebuilt table".." player index = "..player_index..
                ", size = "..artillery_table[player_index].size..", size reduced by "..size - artillery_table[player_index].size)
            end
        end
        self.enemy_in_range_for_player[player_index] = enemy_in_range_for_player

    end,

    allocateArtilleryToTargets = function(self, fcs_d, artillery, targetList, targetCount)
        for target_index = 1, targetCount, 1 do
            local target = targetList[target_index]
            local target_id = ObjectGetId(target)
            if not target_id then
                _ALERT("Target ID is nil")
            else
                if fcs_d:canAllocateTarget(target) then
                    fcs_d:allocateTarget(artillery, target)
                    return true
                end
            end
        end
        return false
    end,
}


IFF = {
    markForbiddenTargets = function(self, player_index, fcs_d)
        local rebuild_table = false
        local friendly_table = Celestial_Melee_Mech_table
        local size = friendly_table[player_index].size
        for i = 1, size, 1 do
            local current = friendly_table[player_index][i]
            if not ObjectIsAlive(current) then
                friendly_table[player_index][i] = nil
                rebuild_table = true
            else
                if ObjectTestModelCondition(current, "ENGAGED") then
                    local dangerCloseList, dangerCloseCount = Unit_enemy_search_surface_only(current, fcs_d.friendly_exclusion_radius)
                    for j = 1, dangerCloseCount, 1 do
                        local target = dangerCloseList[j]
                        local target_id = ObjectGetId(target)
                        if target_id then
                            if ObjectTestModelCondition(target, "MOVING") then
                                fcs_d.forbidden_target_dict[target_id] = true
                            else
                                local danger = tolerant_floor(ObjectsDistance3D(current, target)) < fcs_d.friendly_exclusion_radius_static
                                if danger then
                                    fcs_d.forbidden_target_dict[target_id] = true
                                end
                            end
                            
                        end
                    end
                end
            end
        end
        if rebuild_table then
            _Rebuild_Table_with_Nils_Removed(friendly_table, player_index)
            if DEBUG_CORONA_INE then
                _ALERT("Rebuilt table".." player index = "..player_index..
                ", size = "..friendly_table[player_index].size..", size reduced by "..size - friendly_table[player_index].size)
            end
        end
    end,

}