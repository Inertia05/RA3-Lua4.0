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

-- AOLSCS-ACTIVE
-- "盟军轨道激光打击协调系统(AOLSCS)已启动, 警戒模式攻击优先，固守模式移动优先，侵略模式系统关闭"
-- END

-- STBMFAS-ACTIVE
-- "苏军战术弹道导弹火力分配系统(STBMFAS)已启动, 警戒模式攻击优先，固守模式移动优先，侵略模式系统关闭"
-- END

-- CSFAS-ACTIVE
-- "神州亚轨道火力分配系统(CSFAS)已启动, 退出固守模式以关闭"
-- END

-- ATFACS-ACTIVE
-- "盟军战术火力分配与协调系统(ATFACS)已启动, 退出固守模式以关闭"
-- END

-- CASCS-ACTIVE
-- "神州火炮打击协调系统(CASCS)已启动, 警戒模式攻击优先，固守模式移动优先，侵略模式系统关闭"
-- END

-- ECMICS-ACTIVE
-- “帝国巡航导弹集成指挥系统(ECMICS)已启动，取消固守模式以关闭”
-- END
-- Empire Cruise Missile Integrated Command System (ECMICS)

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
        artillery_to_target_ratio = 1, --- the ratio of artillery to target. default is 1:1 
        isPrecisionStrike = true, --- differentiate between precision strike and saturation strike
        isFullOverride = true, --- if true, the FCS will override all target allocation when it's active
        --- we can basically assume all targets are moving target and change target reset cycle accordingly in Global1FCS.lua
        --- No need to design special logic for moving target
        hp_threshold_LVT  = 250, --- target with hp lower than this will be skipped in guaranteed radius target allocation
        --- ex: all infantry units except commando infantry have less than 250 hp
        isHighValueTargetFn = function(target) --- used for precision strike FCS. This is to be passed as a variable 
            if ObjectIsKindOf(target, "SIEGE_WEAPON") then
                return true
            end
            return false
        end,

        isLowValueTarget = function(self, target) --- these are targets that will be considered last in precision strike FCS
            if self.isHighValueTargetFn(target) then
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

            if (not FCS_Running_Data:isTargetVisiblePVE(target)) then
                return false
            end
            if (not self:isTargetAllocated(target)) then
                return true
            else
                local target_id = ObjectGetId(target)
                if target_id == nil then
                    _ALERT("FCS_Running_Data."..self.name..":canAllocateTarget: target_id is nil")
                    return false
                end
                local limit = self:_calculateTargetAllocationLimit(target)
                return self.target_allocated_dict[target_id] < limit
            end

        end,

        _calculateTargetAllocationLimit = function(self, _)
            return self.artillery_to_target_ratio
        end,
            

        --- Checks if the artillery can be allocated
        canAllocateArtillery = function (self, artillery)
            DEBUG_assert(artillery, "FCS_Running_Data."..self.name..":canAllocateArtillery: artillery is nil")
            if self.isPrecisionStrike then --- prevent FCS from overriding direct ordered precision strike
                local ordered_target = ObjectFindTarget(artillery)
                if ordered_target ~= nil then
                    return false
                end
            end
            local ret = self:_stanceAllowArtilleyAllocation(artillery)
            return ret
        end,

        _stanceAllowArtilleyAllocation = function(_, artillery)
            local stance = ObjectGetDelayedStance(artillery)
            if stance == "GUARD" and not ObjectTestModelCondition(artillery, "MOVING") then
                return true
            elseif stance == "HOLD_POSITION" then
                return true
            else
                return false
            end
        end,

        --- Checks if the artillery can be allocated to the target
        --- To decouple the logic of checking if the artillery can be allocated and if the target can be allocated
        canAllocateArtilleryToTarget = function(self, artillery, target)
            local ret = self:canAllocateArtillery(artillery) and self:canAllocateTarget(target)
            if not ret then
                return false
            end
            if ObjectIsKindOf(target, "SIEGE_WEAPON") then
                local distance = tolerant_floor(ObjectsDistance3D(artillery, target))
                return distance <= self.artillery_range + 50
            else
                return ret
            end
            
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
            local out_of_range = distance > self.artillery_range
            -- if out_of_range then
            ---- Do nothing, let other system handle stop of chasing target
            -- end
            return out_of_range
        end,

        --- Resets the target allocation
        --- @param self FCS
        --- @param artillery StandardUnitType
        resetArtilleryAllocation = function (self, artillery)
            local alert_msg = "FCS_Running_Data."..self.name..":resetArtilleryAllocation: artillery_id is nil"
            DEBUG_assert(artillery, alert_msg)
            local artillery_id = ObjectGetId(artillery)
            if artillery_id == nil then
                _ALERT(alert_msg)
                DEBUG_error(alert_msg)
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

        handleArtilleryFCSOverride = function(self, artillery)
            if not self.isFullOverride then
                return
            end
            local stance = ObjectGetDelayedStance(artillery)
            if (stance == "HOLD_POSITION") or (stance == "GUARD") then
                ObjectSetObjectStatus(artillery, "NO_AUTO_ACQUIRE")
                --- prevent the artillery from acquiring new target by itself to avoid waste of precision strike
            else
                if ObjectStatusIs(artillery, "NO_AUTO_ACQUIRE") then
                    ObjectSetObjectStatus_Slow(artillery, "NO_AUTO_ACQUIRE", false)
                end
            end
        end,

        

        _orderAttack = function(_, artillery, target)
            ---UnitShowInfoBox(target, "Attack", 1)
            ObjectSetAssignedTarget(artillery, target)
        end,

    }
    return fcs
end

Athena_table = CreateUnitTable({"AlliedAntiStructureVehicle"})


local AOLSCS = createFCS("Allied Orbital Laser Strike Coordination System (AOLSCS)", 
1450,200, Athena_table)
AOLSCS.artillery_to_target_ratio = 2
AOLSCS._calculateTargetAllocationLimit = function(self, target)
    local initial_health = ObjectGetInitialIntHealth(target)
    if initial_health < 1000 then
        return 1
    end
    local health = ObjectGetCurrentIntHealth(target)
    if health < 200 then --- minimum damage done, towards very fast, small target
        return 1
    end
    local speed = ObjectCalculateIntSpeed(target)
    if speed > 70 and initial_health > 3000 then
        return self.artillery_to_target_ratio + 1
    end
    return self.artillery_to_target_ratio
end
FCS_Running_Data.AOLSCS = AOLSCS

Celestial_Artillery_table = CreateUnitTable({"CelestialAntiStructureVehicle"})
local CASCS = createFCS("Celestial Artillery Strike Coordination System (CASCS)",
700,200, Celestial_Artillery_table)
CASCS.isPrecisionStrike = false
CASCS.artillery_to_target_ratio = 5
FCS_Running_Data.CASCS = CASCS

Celestial_Advanced_Bomber_table = CreateUnitTable({"CelestialAdvanceAircraftTech4"})

-- FilterCAAT4Target = CreateObjectFilter({
--     IncludeThing={
--         "CelestialAdvanceAircraftTech4Target"
--     },
-- })
local CSFAS = createFCS("Celestial Suborbital Fire Allocation System (CSFAS)",
1050,200, Celestial_Advanced_Bomber_table)
-- 3D range = 750, buffed to 1125(750*1.5)
-- 2D range = 700, buffed to 1050(700*1.5)
CSFAS.hp_threshold_LVT = 1000
CSFAS.canAllocateArtillery = function(_, artillery)
    if not ObjectStatusIs(artillery, "IMMOBILE") then
        return false
    end
    if ObjectStatusIs(artillery, "IGNORE_AI_COMMAND") then
        return false
    end

    if ObjectGetDelayedStance(artillery) == "HOLD_POSITION" then -- "HoldPosition"
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

CSFAS._orderAttack = function(_, artillery, target)
    --ObjectSetAssignedTarget(artillery, nil)
    UnitAttackTarget(artillery, target)
end

FCS_Running_Data.CSFAS = CSFAS



V4_table = CreateUnitTable({"SovietAntiStructureVehicle"})
local STBMFAS = createFCS("Soviet Tactical Ballistic Missile Fire Allocation System (STBMFAS)",
1450,200, V4_table)
--- time based target allocation
--- current allocation logic:
--- 1 missile per target per cycle (reload = 10 second)
--- TODO:
--- 1 missile per MOVING target per second
--- 1 missile per static target per cycle
FCS_Running_Data.STBMFAS = STBMFAS





-- Future_Tank_table = CreateUnitTable({"AlliedFutureTank"})
-- local ATFACS = createFCS("Allied Tactical Fire Allocation and Coordination System(ATFACS)",
-- 350,100, Future_Tank_table)
-- ATFACS.canAllocateArtillery = function(self, artillery)
--     return (
--     (not ObjectStatusIs(artillery, "IGNORE_AI_COMMAND"))
--     and ObjectGetDelayedStance(artillery) == "HOLD_POSITION" 
--     and UnitSpecialPowerReady_Slow(artillery, "SpecialPower_AlliedFutureTankLaserWeapon")
--     -- do not allocate unit that's not ready to fire
--     )
-- end
-- ATFACS._orderAttack = function(self, artillery, target)
--     UnitUseAbilityOnTarget(artillery, "Command_AlliedFutureTankLaserWeapon", target)
-- end
-- ATFACS.isPrecisionStrike = false
-- ATFACS.isFullOverride = false
-- FCS_Running_Data.ATFACS = ATFACS


Terror_Drone_table = CreateUnitTable({"SovietScoutVehicle"})
local STEIAS = createFCS("Soviet Tactical Electro-Interference Allocation System",
475,100, Terror_Drone_table)
STEIAS.canAllocateArtillery = function(self, artillery)
    local ordered_target = ObjectFindTarget(artillery)
    if ordered_target ~= nil then
        return false
    end
    if not ObjectStatusIs(artillery, "WEAPON_UPGRADED_02") then
        return false
    end
    return self:_stanceAllowArtilleyAllocation(artillery)
end
STEIAS.isPrecisionStrike = false
STEIAS.canAllocateTarget = function(self, target)
    if not ObjectTestTargetObjectWithFilter(nil, target, FilterVehicleSurfaceOnly) then
        return false
    end
    return not self:isTargetAllocated(target)
end
FCS_Running_Data.STEIAS = STEIAS


--japaninterceptoraircraft
Japan_Cruise_Missile_table = CreateUnitTable({"JapanInterceptorAircraft"})
local ECMICS = createFCS("Empire Cruise Missile Integrated Command System (ECMICS)",
500,200, Japan_Cruise_Missile_table)
ECMICS.artillery_to_target_ratio = 1
ECMICS._stanceAllowArtilleyAllocation = function(_, artillery)
    if not ObjectStatusIs(artillery, "AIRBORNE_TARGET") then
        return false
    end
    if ObjectStatusIs(artillery, "IGNORE_AI_COMMAND") then
        return false
    end
    local stance = ObjectGetDelayedStance(artillery) 
    if stance == "GUARD" and not ObjectTestModelCondition(artillery, "MOVING") then
        return true
    elseif stance == "HOLD_POSITION" then
        return true
    else
        return false
    end
end
FCS_Running_Data.ECMICS = ECMICS