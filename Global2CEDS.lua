--- @module "Global0VarFun"
--- @module "Global2CEDS"
---@diagnostic disable: unused-local
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
-- This code design is an example of Mark-And-Rebuild
-- It's simplistic and easy to understand, good for average tasks in bug-sensitive environments.
-- Maintainability and readability are the main advantages of this design.
-- For more complex tasks that involve local filter search for each unit, it's better to put more effort into optimization.
--- 神奇bug，当循环攻击前进在一个地方时，被友军强制攻击的话会不接受撤退命令，但是如果是被敌军攻击就可以撤退


Gunship_table = Object.CreateUnitClassCollection("AlliedGunshipAircraft")

Allied_Interceptor_table = Object.CreateUnitClassCollection("AlliedInterceptorAircraft")

Celestial_Interceptor_table = Object.CreateUnitClassCollection("CelestialInterceptorAircraft")

Soviet_Interceptor_table = Object.CreateUnitClassCollection("SovietInterceptorAircraft")


Allied_Heavy_Bomber_table = Object.CreateUnitClassCollection("AlliedAntiStructureBomberAircraft")

Allied_Light_Bomber_table = Object.CreateUnitClassCollection("AlliedAntiGroundAircraft")

Celestial_Bomber_table = Object.CreateUnitClassCollection("CelestialBomberAircraft")

Soviet_Bomber_table = Object.CreateUnitClassCollection("SovietAntiGroundAttacker")


Japan_Fighter_table = Object.CreateUnitClassCollection("JapanAntiInfantryVehicle")

-- CelestialBomberAircraft
-- SovietAntiGroundAttacker

--- Command_AlliedGunshipAircraftHyperSpaceMove
--- SpecialPower_AlliedGunshipAircraftHyperSpaceMove
--- ObjectStatusIs( unit, "SPECIALABILITY_ACTIVE" )

--- @class EvacInfo
--- @field unit_table UnitClassCollection
--- @field evac_command string
--- @field evac_text string
--- @field evac_power SpecialPower|nil

--- @class EvacInfoCollection
--- @field FilterCEDS_LightlyDamaged ObjectFilter
--- @field AlliedGunshipAircraft EvacInfo
--- @field AlliedInterceptorAircraft EvacInfo
--- @field CelestialInterceptorAircraft EvacInfo
--- @field SovietInterceptorAircraft EvacInfo
--- @field AlliedAntiStructureBomberAircraft EvacInfo
--- @field AlliedAntiGroundAircraft EvacInfo
--- @field CelestialBomberAircraft EvacInfo
--- @field SovietAntiGroundAttacker EvacInfo
--- @field JapanAntiInfantryVehicle EvacInfo


--- @type EvacInfoCollection
EvacInfoCollection = {
    FilterCEDS_LightlyDamaged = CreateObjectFilter({
        Rule="ALL",
        IncludeThing={},
        StatusBitFlags = "DAMAGED REALLYDAMAGED HAS_SECONDARY_DAMAGE", 
    }),
    AlliedGunshipAircraft = {
        unit_table = Gunship_table,
        evac_command = "Command_AlliedGunshipAircraftHyperSpaceMove",
        evac_text = "HEES-ACTIVE",
        evac_power = "SpecialPower_AlliedGunshipAircraftHyperSpaceMove",
    },
    AlliedInterceptorAircraft = {
        unit_table = Allied_Interceptor_table,
        evac_command = "Command_AlliedFighterAircraftReturnToAirfield",
        evac_text = "IEES-ACTIVE",
        evac_power = nil,
    },
    CelestialInterceptorAircraft = {
        unit_table = Celestial_Interceptor_table,
        evac_command = "Command_CelestialFighterAircraftReturnToAirfield",
        evac_text = "IEES-ACTIVE",
        evac_power = nil,
    },
    SovietInterceptorAircraft = {
        unit_table = Soviet_Interceptor_table,
        evac_command = "Command_SovietFighterAircraftReturnToAirfield",
        evac_text = "SEES-ACTIVE",
        evac_power = nil,
    },
    AlliedAntiStructureBomberAircraft = {
        unit_table = Allied_Heavy_Bomber_table,
        evac_command = "Command_AlliedAntiGroundAircraftReturnToAirfield",
        evac_text = "BEES-ACTIVE",
        evac_power = nil,
    },
    AlliedAntiGroundAircraft = {
        unit_table = Allied_Light_Bomber_table,
        evac_command = "Command_AlliedAntiGroundAircraftReturnToAirfield",
        evac_text = "BEES-ACTIVE",
        evac_power = nil,
    },
    CelestialBomberAircraft = {
        unit_table = Celestial_Bomber_table,
        evac_command = "Command_CelestialFighterAircraftReturnToAirfield",
        evac_text = "BEES-ACTIVE",
        evac_power = nil,
    },
    SovietAntiGroundAttacker = {
        unit_table = Soviet_Bomber_table,
        evac_command = "Command_SovietFighterAircraftReturnToAirfield",
        evac_text = "BEES-ACTIVE",
        evac_power = nil,
    },
    JapanAntiInfantryVehicle = {
        unit_table = Japan_Fighter_table,
        evac_command = "Command_JAIV_Transform",
        evac_text = "TEES-ACTIVE",
        evac_power = "SpecialPower_JAIV_Transform",
    },

}

--- This function creates an instance of the IEES system with the given parameters.
--- @param evac_info EvacInfo
--- @return EES_Base
function CreateEES(evac_info)
  --- The Interceptor Emergency Evaculation System, specific to Interceptor units by default
  --- @type EES_Base
  local IEES = {
    _MAX_COOLDOWN = 30,
    _EVAC_UNIT_TABLE = evac_info.unit_table,
    _EVAC_TIME_DICT = {},
    _EVAC_INFO = evac_info,

    isEvacuating = function(self, unit)
        return ObjectStatusIs(unit, "CLEARED_FOR_LANDING")
    end,

    isEvacAllowedByStatus = function(self, unit, player)
        return ObjectTestTargetObjectWithFilter(nil, unit, EvacInfoCollection.FilterCEDS_LightlyDamaged)
    end,

    canEvacuate = function(self, unit, id, player)
        local evac_time = self._EVAC_TIME_DICT[id]
        if evac_time and GlobalSecond - evac_time < self._MAX_COOLDOWN then
            return false
        end
        if not self:isEvacAllowedByStatus(unit, player) then
            return false
        end
        if self:isEvacuating(unit) then
            return false
        end
        return true
    end,

    shouldEvacuateConservative = function(self, unit)
        return ObjectStatusIsAtLeastLightlyDamaged(unit)
    end,

    shouldEvacuateAggressive = function(self, unit)
        return ObjectStatusIsReallyDamaged(unit)
    end,

    isEvacAllowedByStance = function(self, unit)
        return ObjectStanceIsGuard_Slow(unit) or ObjectStanceIsHoldPosition_Slow(unit)
    end,

    isEvacAllowedByStanceDefensive = function(self, unit)
        return ObjectStanceIsHoldPosition_Slow(unit)
    end,

    evacuateUnit = function(self, unit, player, player_start)
        local id = ObjectGetId(unit)
        if not id then
            _ALERT("EES_Running_Data.EES.evacuateUnit: unit_id is nil")
            return
        end
        local evac_beacon = EES_Running_Data.evac_beacon[player]
        if evac_beacon and not ObjectIsAlive(evac_beacon) then
            evac_beacon = nil
            EES_Running_Data.evac_beacon[player] = nil
        end
        if evac_beacon then
            local x,y,z = ObjectGetIntPosition(evac_beacon)
            exObjectMoveTo(id, x, y, z)
        else
            UnitMoveToNamedWaypoint(unit, player_start)
        end
        -- In case there is no airport to return to, the unit will head back to the starting point
        if self._EVAC_INFO.evac_power then
            if UnitSpecialPowerReady_Slow(unit, self._EVAC_INFO.evac_power) then
                UnitUseAbility(unit, self._EVAC_INFO.evac_command)
            end
        else
            UnitUseAbility(unit, self._EVAC_INFO.evac_command)
        end
        UnitShowInfoBox(unit, self._EVAC_INFO.evac_text,5)
        ObjectSetObjectStatusUnselectable_Slow(unit, true)
        self._EVAC_TIME_DICT[id] = GlobalSecond
    end,

    canCompleteEvacuation = function(self, unit, id)
        local evac_time = self._EVAC_TIME_DICT[id]
        if not evac_time then --- have not evacuated
            return false
        end
        local time_since_evac = GlobalSecond - evac_time
        return time_since_evac > 30
    end,

    completeEvacuation = function(self, unit)
        ObjectSetObjectStatusUnselectable_Slow(unit, false)
        local id = ObjectGetId(unit)
        if not id then
            _ALERT("EES_Running_Data.EES.completeEvacuation: unit_id is nil")
            return
        end
        self._EVAC_TIME_DICT[id] = nil
    end,

    }
    local evac_text = evac_info.evac_text
    if (evac_text == "BEES-ACTIVE") or (evac_text == "SEES-ACTIVE") then
        IEES.isEvacAllowedByStance = function(self, unit)
            return true -- always allow evacuation
        end
        IEES.isEvacAllowedByStanceDefensive = function(self, unit)
            return not ObjectStanceIsAggressive_Slow(unit)
        end
    end
    if (evac_text == "TEES-ACTIVE") then
        IEES.isEvacAllowedByStatus = function(self, unit, player)
            return not ObjectStatusIs(unit, "POINT_DEFENSE_DRONE_ATTACHED")
        end
        IEES.isEvacuating = function(self, unit)
            return not ObjectStatusIs(unit, "AIRBORNE_TARGET")
        end
        IEES.shouldEvacuateConservative = function(self, unit)
            return true
        end
        IEES.shouldEvacuateAggressive = function(self, unit)
            return ObjectStatusIsAtLeastLightlyDamaged(unit)
        end
    end
    if (evac_text == "HEES-ACTIVE") then
        IEES._MAX_COOLDOWN = 60
        IEES.isEvacuating = function(self, unit)
            -- if not UnitSpecialPowerReady_Slow(unit, evac_info.evac_power) then
            --     return true
            -- end
            return ObjectStatusIs(unit, "SPECIALABILITY_ACTIVE")
        end
    end
  return IEES
end


--- @class EES_Running_Data
EES_Running_Data = {
    --- Data related to the HEES system (Hyperspace Emergency Evacuation System)

    HEES = CreateEES(EvacInfoCollection.AlliedGunshipAircraft),
    AIEES = CreateEES(EvacInfoCollection.AlliedInterceptorAircraft),
    CIEES = CreateEES(EvacInfoCollection.CelestialInterceptorAircraft),
    SIEES = CreateEES(EvacInfoCollection.SovietInterceptorAircraft),
    AHBEES = CreateEES(EvacInfoCollection.AlliedAntiStructureBomberAircraft),
    ALBEES = CreateEES(EvacInfoCollection.AlliedAntiGroundAircraft),
    CBEES = CreateEES(EvacInfoCollection.CelestialBomberAircraft),
    SBEES = CreateEES(EvacInfoCollection.SovietAntiGroundAttacker),
    JFEES = CreateEES(EvacInfoCollection.JapanAntiInfantryVehicle),


    evac_beacon = {
        Player_1 = nil,
        Player_2 = nil,
        Player_3 = nil,
        Player_4 = nil,
        Player_5 = nil,
        Player_6 = nil
    },

    runCEDS = function(self)
        local frame = GetFrame()
        if tolerant_int_mod(frame, 5) == 0 then
            self:processEvacuationDecision(self.HEES)
            self:processEvacuationDecision(self.AIEES)
            self:processEvacuationDecision(self.CIEES)
            self:processEvacuationDecision(self.SIEES)
            self:processEvacuationDecision(self.AHBEES)
            self:processEvacuationDecision(self.ALBEES)
            self:processEvacuationDecision(self.CBEES)
            self:processEvacuationDecision(self.SBEES)
            self:processEvacuationDecision(self.JFEES)
        end
    end,

  --- Function to manage the evacuation system for units (e.g., gunships, fighters)
  --- This function is called every second to process the evacuation decision for each unit.
  --- @param self EES_Running_Data (automatically passed when using ':').
  --- @param evac_system EES_Base The spcific evacuation system (e.g., EES_Running_Data.HEES)
  processEvacuationDecision = function (self, evac_system)
    -- Evacuation System Data
    local evac_data = evac_system
    local unit_table_collection = evac_system._EVAC_UNIT_TABLE

    -- Iterate through players (assumed to be 6 players)
    for player_index = 1, 6, 1 do
        local player_start = "Player_"..player_index.."_Start"
        local player = "Player_"..player_index
        local unlocked = Unlocked.CEDS[player]
        --- @type UnitClassTable
        local unit_class_table = unit_table_collection[player]
        local size = unit_class_table.size
        if unlocked then
            --print("CEDS: Player "..player_index.." is unlocked for"..evac_data._EVAC_UNIT_TABLE.unit_class_name)
            -- Iterate through the player's units
            for i = 1, size, 1 do
                
                local current = unit_class_table.units[i]
                local unit_id = unit_class_table.ids[i]
                
                -- Check if the unit is alive
                if not ObjectIsAlive(current) or (not unit_id) then
                    -- Skip, let other systems handle dead units
                else
                    -- Check if the evacuation system can evacuate the unit
                    if evac_data:canEvacuate(current, unit_id, player) then
                        -- Handle evacuation based on the unit's status
                        -- exObjectShowTextAtTop(unit_id, "content"..GlobalSecond, 0, 255)
                        -- exObjectUpdateTextAtTop(unit_id, "can evac"..GlobalSecond, 0, 255)
                        if evac_data:shouldEvacuateAggressive(current) then
                            -- if unit is heavily damaged, it's obviously lightly damaged too
                            -- exObjectShowTextAtTop(unit_id, "content"..GlobalSecond, 0, 255)
                            -- exObjectUpdateTextAtTop(unit_id, "should evac agg"..GlobalSecond, 0, 255)
                            if evac_data:isEvacAllowedByStance(current) then
                                -- checking stance is slow so only do it when necessary
                                evac_data:evacuateUnit(current, player, player_start)
                            end
                        elseif evac_data:shouldEvacuateConservative(current) then
                            -- exObjectShowTextAtTop(unit_id, "content"..GlobalSecond, 0, 255)
                            -- exObjectUpdateTextAtTop(unit_id, "should evac con"..GlobalSecond, 0, 255)
                            if evac_data:isEvacAllowedByStanceDefensive(current) then
                                -- only evacuate if stance is more defensive, keep the unit in the fight if not in a defensive stance
                                evac_data:evacuateUnit(current, player, player_start)
                            end
                        end
                    end
                    if evac_data:canCompleteEvacuation(current, unit_id) then
                        -- exObjectShowTextAtTop(unit_id, "content"..GlobalSecond, 0, 255)
                        -- exObjectUpdateTextAtTop(unit_id, "can complete evac"..GlobalSecond, 0, 255)
                        evac_data:completeEvacuation(current)
                    end
                end
            end
        end
    end
  end,
}




