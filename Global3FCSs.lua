--- @module "Global1FCS"
--- @module "Global3FCSs"
if Global0VarFun == nil then
    if exMessageAppendToMessageArea then
        exMessageAppendToMessageArea("CRITICAL ERROR: Global0VarFun.lua is missing, reported by Global3FCSs.lua")
    else
        _ALERT("CRITICAL ERROR: Global0VarFun.lua is missing, reported by Global3FCSs.lua")
    end
end
if DEBUG_CORONA_INE then
    if not LOADED_FILES[2] then
        _ALERT("ERROR: Global2CEDS.lua must be loaded before Global3FCSs.lua")
    else
        LOADED_FILES[3] = true
        _ALERT("All global files loaded in order: Global1VarFun.lua, Global2CEDS.lua, Global3FCSs.lua")
    end
end
--- A function that check if an object is not moving by checking its delta position
function ObjectIsNotMoving(object)
    if not ObjectIsAlive(object) then
        _ALERT("ObjectIsNotMoving: object is not alive")
        return false
    end
    local x, y, z = ObjectGetIntPosition(object)
    local last_x, last_y, last_z = ObjectGetPreviousPosition(object)
    local dx2, dy2, dz2 = tolerant_floor((x - last_x)^2), tolerant_floor((y - last_y)^2), tolerant_floor((z - last_z)^2)
    local threshold = 1
    return dx2 < threshold and dy2 < threshold and dz2 < threshold
end



--- 
--- Initializes a new FCS object
--- @param name string The name of the FCS system
--- @param artillery_range number The range of the artillery
--- @param artillery_grouping_range_threshold number The threshold for grouping the artillery
--- @param artillery_table table The table of artillery units
--- @return FCS A new FCS object
local createFCS = function(name, artillery_range, artillery_grouping_range_threshold, artillery_table)
    --- @type FCS
    local fcs = {

        name = name or "Unnamed FCS",
        isPrecisionStrike = true,
        hp_threshold_LVT  = 250, --- target with hp lower than this will be skipped in guaranteed radius target allocation
        --- ex: all infantry units except commando infantry have less than 250 hp
        isHighValueTarget = function(self, target) --- used for precision strike FCS
            if ObjectIsKindOf(target, "SIEGE_WEAPON") then
                return true
            end
            return false
        end,

        isLowValueTarget = function(self, target) --- these are targets that will be considered last in precision strike FCS
            if self:isHighValueTarget(target) then
                return false
            end
            if ObjectGetCurrentIntHealth(target) < self.hp_threshold_LVT then
                return true
            end
            return false
        end,
        ---- Example priority order for target allocation
        ---- 1. Structure(in guaranteed radius), highest priority
        ---- 2. High value target(in guaranteed radius), ex: siege weapon
        ---- 3. Other non low value target(in guaranteed radius)
        ---- 4. Remaining targets(in full radius, not guaranteed), ), ex: low value target
        
        artillery_table = artillery_table,
        artillery_range = artillery_range,
        artillery_grouping_range_threshold = artillery_grouping_range_threshold,

        target_allocated_dict = {},

        artillery_allocated_dict = {},

        artillery_to_target_dict = {},

        artillery_stance_dict = {},




        --- Checks if the target can be allocated (detected and not already allocated)
        canAllocateTarget = function(self, target)
            DEBUG_assert(target, "FCS_Running_Data."..self.name..":canAllocateTarget: target is nil")
            return not self:isTargetAllocated(target) and FCS_Running_Data:isTargetVisiblePVE(target)
        end,

        --- Checks if the artillery can be allocated
        canAllocateArtillery = function (self, artillery)
            DEBUG_assert(artillery, "FCS_Running_Data."..self.name..":canAllocateArtillery: artillery is nil")
            --- if not ObjectStatusIsNotMoving(artillery) then
            if ObjectTestModelCondition(artillery, "MOVING") then -- 默认模型状态是同步的
                return false
            end
            local stance = self:_getArtilleryStance(artillery) 
            --- this function will prevent the artillery in HoldPosition stance
            --- from acquiring new target by itself to avoid waste of precision strike
            if self.isPrecisionStrike then --- prevent FCS from overriding direct ordered precision strike
                local ordered_target = ObjectFindTarget(artillery)
                if ordered_target ~= nil then
                    return false
                end
            end
            return stance == 3 -- "HoldPosition"
        end,

        --- Checks if the artillery can be allocated to the target
        --- To decouple the logic of checking if the artillery can be allocated and if the target can be allocated
        canAllocateArtilleryToTarget = function(self, artillery, target)
            return self:canAllocateArtillery(artillery) and self:canAllocateTarget(target)
        end,

        --- Allocates the artillery to the target
        ---@param self FCS
        ---@param artillery StandardUnitType The artillery unit to be allocated to the target
        ---@param target StandardUnitType The target to be allocated to one or more artillery units
        allocateArtilleryToTarget = function(self, artillery, target)
            local target_id = ObjectGetId(target)
            if target_id == nil then
                _ALERT("FCS_Running_Data."..self.name..":allocateArtilleryToTarget: target_id is nil")
                return
            end
            local artillery_id = ObjectGetId(artillery)
            if artillery_id == nil then
                _ALERT("FCS_Running_Data."..self.name..":allocateArtilleryToTarget: artillery_id is nil")
                return
            end
            self:_assignTargetByID(target_id)
            self.artillery_allocated_dict[artillery_id] = true
            self.artillery_to_target_dict[artillery_id] = target -- store the target for the artillery to check target status later
            self:_orderAttack(artillery, target)
        end,


        --- Assign target to one or more artillery units
        --- @param self FCS
        --- @param targetID UnitID The ID of target to be allocated to one or more artillery units
        _assignTargetByID = function(self, targetID)
            local count = self.target_allocated_dict[targetID]
            if count == nil then
                self.target_allocated_dict[targetID] = 1
            else
                self.target_allocated_dict[targetID] = count + 1
            end
        end,

        --- Checks if the artillery should reallocate to another target
        ---@param self FCS
        ---@param artillery StandardUnitType
        shouldReallocateArtillery = function (self, artillery)
            local artillery_id = ObjectGetId(artillery)
            if artillery_id == nil then
                _ALERT("FCS_Running_Data."..self.name..":shouldReallocateArtillery: artillery_id is nil")
                return false
            end
            if not self:isArtilleryAllocated(artillery) then
                return false
            end
            local current_target = self.artillery_to_target_dict[artillery_id]
            if current_target == nil then -- meaning artillery is not allocated to any target
                return false
            end
            if not ObjectIsAlive(current_target) then
                return true
            end
            local distance = tolerant_floor(ObjectsDistance3D(artillery, current_target))
            return distance > self.artillery_range
        end,

        --- Resets the target allocation
        --- @param self FCS
        --- @param artillery StandardUnitType
        resetArtilleryAllocation = function (self, artillery)
            DEBUG_assert(artillery, "FCS_Running_Data."..self.name..":resetArtilleryAllocation: artillery is nil")
            local artillery_id = ObjectGetId(artillery)
            if artillery_id == nil then
                DEBUG_error("FCS_Running_Data."..self.name..":resetArtilleryAllocation: artillery_id is nil")
                return
            end
            self.artillery_allocated_dict[artillery_id] = nil
            self.artillery_to_target_dict[artillery_id] = nil
        end,

        --- Checks if the target is already allocated
        ---@param self FCS
        ---@param target StandardUnitType The target to check
        ---@return boolean True if the target is allocated, false otherwise
        isTargetAllocated = function(self, target)
            local target_id = ObjectGetId(target)
            if target_id == nil then
                _ALERT("FCS_Running_Data."..self.name..":isTargetAllocated: target_id is nil")
                return false
            end
            return self.target_allocated_dict[target_id] ~= nil
        end,

        --- Checks if the artillery is already allocated to a target
        --- @param self FCS
        --- @param artillery StandardUnitType The artillery unit to check
        --- @return boolean True if the artillery is allocated, false otherwise
        isArtilleryAllocated = function(self, artillery)
            DEBUG_assert(artillery, "FCS_Running_Data."..self.name..":isArtilleryAllocated: artillery is nil")
            local artillery_id = ObjectGetId(artillery)
            if artillery_id == nil then
                _ALERT("FCS_Running_Data."..self.name..":isArtilleryAllocated: artillery_id is nil")
                return false
            end
            return self.artillery_allocated_dict[artillery_id] ~= nil
        end,

        --- Get artillery stored stance
        --- @param self FCS
        --- @param artillery StandardUnitType The artillery unit to check
        --- @return Stance The stance of the artillery
        _getArtilleryStance = function(self, artillery)
            DEBUG_assert(artillery, "FCS_Running_Data."..self.name..":_getArtilleryStance: artillery is nil")
            local artillery_id = ObjectGetId(artillery)
            local stance = self.artillery_stance_dict[artillery_id]
            if stance == nil then -- if the stance is not stored, store it
            -- stance will be cleared periodically by FCS_Running_Data
                if ObjectStanceIsHoldPosition_Slow(artillery) then
                    stance = 3 -- "HoldPosition"
                elseif ObjectStanceIsHoldFire_Slow(artillery) then
                    stance = 4 -- "HoldFire"
                else
                    stance = 0 -- "Other"
                end
                if artillery_id ~= nil then
                    self.artillery_stance_dict[artillery_id] = stance
                end
            end
            if self.isPrecisionStrike then
                if stance == 3 then
                    ObjectSetObjectStatus(artillery, "NO_AUTO_ACQUIRE")
                    --- prevent the artillery from acquiring new target by itself to avoid waste of precision strike
                else
                    if ObjectStatusIs(artillery, "NO_AUTO_ACQUIRE") then
                        ObjectSetObjectStatus_Slow(artillery, "NO_AUTO_ACQUIRE", false)
                    end
                end
            end
            return stance
        end,

        _orderAttack = function(self, artillery, target)
            UnitAttackTarget(artillery, target)
        end,

    }
    return fcs
end

Athena_table = CreateUnitTable({"AlliedAntiStructureVehicle"})


local AOLSCS = createFCS("Allied Orbital Laser Strike Coordination System (AOLSCS)", 
1050,200, Athena_table)
AOLSCS.canAllocateTarget = function(self, target)
    -- if (not FCS_Running_Data:isTargetVisiblePVE(target)) then --- TODO, 视野函数还是有BUG
    --     return false
    -- end
    if (not self:isTargetAllocated(target)) then
        return true
    else
        return self.target_allocated_dict[ObjectGetId(target)] < 2
    end
end
FCS_Running_Data.AOLSCS = AOLSCS

Celestial_Artillery_table = CreateUnitTable({"CelestialAntiStructureVehicle"})
local CASCS = createFCS("Celestial Artillery Strike Coordination System (CASCS)",
700,200, Celestial_Artillery_table)
CASCS.isPrecisionStrike = false
CASCS.canAllocateTarget = function(self, target)
    if (not FCS_Running_Data:isTargetVisiblePVE(target)) then
        return false
    end
    if (not self:isTargetAllocated(target)) then
        return true
    else
        return self.target_allocated_dict[ObjectGetId(target)] < 5
    end
end
FCS_Running_Data.CASCS = CASCS

Celestial_Advanced_Bomber_table = CreateUnitTable({"CelestialAdvanceAircraftTech4"})

FilterCAAT4Target = CreateObjectFilter({
    IncludeThing={
        "CelestialAdvanceAircraftTech4Target"
    },
})
local CSFAS = createFCS("Celestial Suborbital Fire Allocation System (CSFAS)",
1050,200, Celestial_Advanced_Bomber_table)
-- 3D range = 750, buffed to 1125(750*1.5)
-- 2D range = 700, buffed to 1050(700*1.5)
CSFAS.hp_threshold_LVT = 1000
CSFAS.canAllocateArtillery = function(self, artillery)
    if not ObjectStatusIs(artillery, "IMMOBILE") then
        return false
    end
    if ObjectStatusIs(artillery, "IGNORE_AI_COMMAND") then
        return false
    end

    if self:_getArtilleryStance(artillery) == 3 then -- "HoldPosition"
    -- 无法命令期：
    -- IS_RELOADING_WEAPON 存在 或 IGNORE_AI_COMMAND 存在
        -- 非无法命令期
        local preE = ObjectTestModelCondition(artillery, "PREATTACK_E")
        local engaged = ObjectTestModelCondition(artillery, "ENGAGED")
        local state_after_lift_off_before_ready = preE and engaged
        return not state_after_lift_off_before_ready
        -- not (ObjectStatusIs(artillery, "IS_RELOADING_WEAPON") or ObjectStatusIs(artillery, "IGNORE_AI_COMMAND"))
    else
        return false
    end
end
CSFAS.canAllocateArtilleryToTarget = function(self, artillery, target)
    if not self:canAllocateArtillery(artillery) then
        return false
    end
    if not self:canAllocateTarget(target) then
        return false
    end
    local distance = tolerant_floor(ObjectsDistance3D(artillery, target))
    if distance > 350 then
        --UnitStop(artillery) 这一行不知怎么卡住了摇光。。 停火模式会比固守更卡一点，有些摇光会落后，但是仍然能完成攻击。加了这一行，摇光会被卡住，任务会无法完成。
        --UnitShowInfoBox(target, "Target out of range", 5)
        return true
    else
        return false
    end
    -- special case for Celestial Suborbital Railgun
    -- the railgun should only target units that are far away to avoid friendly fire
end

FCS_Running_Data.CSFAS = CSFAS



V4_table = CreateUnitTable({"SovietAntiStructureVehicle"})
local STBMFAS = createFCS("Soviet Tactical Ballistic Missile Fire Allocation System (STBMFAS)",
1050,200, V4_table)
FCS_Running_Data.STBMFAS = STBMFAS





Future_Tank_table = CreateUnitTable({"AlliedFutureTank"})
local ATFACS = createFCS("Allied Tactical Fire Allocation and Coordination System(ATFACS)",
350,100, Future_Tank_table)
ATFACS.canAllocateArtillery = function(self, artillery)
    return (
    (not ObjectStatusIs(artillery, "IGNORE_AI_COMMAND"))
    and self:_getArtilleryStance(artillery) == 3 -- "HoldPosition"
    and UnitSpecialAbilityReady_Slow(artillery, "SpecialPower_AlliedFutureTankLaserWeapon")
    -- do not allocate unit that's not ready to fire
    )
end
ATFACS._orderAttack = function(self, artillery, target)
    UnitUseAbilityOnTarget(artillery, "Command_AlliedFutureTankLaserWeapon", target)
end
ATFACS.isPrecisionStrike = false
FCS_Running_Data.ATFACS = ATFACS

--japaninterceptoraircraft
Japan_Cruise_Missile_table = CreateUnitTable({"JapanInterceptorAircraft"})
local ECMICS = createFCS("Empire Cruise Missile Integrated Command System (ECMICS)",
2000,1000, Japan_Cruise_Missile_table)
ECMICS.canAllocateTarget = function(self, target)
    return not self:isTargetAllocated(target)
end
ECMICS.canAllocateArtillery = function(self, artillery)
    if self.isPrecisionStrike then
        local ordered_target = ObjectFindTarget(artillery)
        if ordered_target ~= nil then
            return false
        end
    end
    return (
    (not ObjectStatusIs(artillery, "IGNORE_AI_COMMAND") and not ObjectStatusIs(artillery, "WATER_LOCOMOTOR_ACTIVE"))
    and self:_getArtilleryStance(artillery) == 3 -- "HoldPosition"
    )
end
FCS_Running_Data.ECMICS = ECMICS