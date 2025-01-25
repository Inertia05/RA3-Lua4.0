
--- @meta
--- This file is for type definition only, it is not executable code.
--- It is used to define the types of the functions and variables used in the code.


--- @class StandardUnitType
--- @field GUID UnitID The GUID of the unit, which is unique and invariant for the unit
-- ---Note this field name is just for illustration, the actual field name is hidden away.
-- This represents a standard unit type used across the game, details are hidden away.
-- This is actually a table that hold the unit's GUID which is unique and invariant for the unit.
-- The table retrived from game engine(ex: through ) however is not invariant and can change over time.
-- Assume this class handles all unit interactions and is referenced across multiple functions.


--- @class UnitID
--- The actual value stored in the StandardUnitType table
--- This is the GUID of the unit, which is unique and invariant for the unit.
--- This is the actual value stored in the StandardUnitType table.
--- Value can be retrived by ObjectGetId(unit) function.

--- 未完整列出
--- @alias KindOfList
--- | KindOf
--- | "SHIP SUBMARINE"
--- | "STRUCTURE AIRCRAFT"
--- | "STRUCTURE AIRCRAFT INFANTRY"
--- | "STRUCTURE AIRCRAFT INFANTRY EGG"
--- | "STRUCTURE AIRCRAFT INFANTRY SHIP SUBMARINE"
--- | "STRUCTURE INFANTRY SHIP"
--- | "STRUCTURE INFANTRY SHIP SUBMARINE"
--- | "HARVESTER AIRCRAFT INFANTRY"


--- 未完整列出
--- @alias ObjectStatusList
--- | ObjectStatus
--- | "AIRBORNE_TARGET SUBMERGED"
--- | "DAMAGED REALLYDAMAGED HAS_SECONDARY_DAMAGE"
--- | "AIRBORNE_TARGET UNDER_IRON_CURTAIN"
--- | "IGNORING_POWER_DOWN UNCONTROLLABLY_SCARED INAUDIBLE AIRBORNE_TARGET"

--- @class FilterParams
--- @field Relationship "ENEMIES"|"NEUTRAL"|"ALLIES"|"SAME_PLAYER"|nil Optional. The relationship between the objects
--- @field IncludeThing (CombatUnitName|StructureName|SpecialUnitName|number)[] Optional. Array of things to include, which could be names or hashed values.
--- @field ExcludeThing (CombatUnitName|StructureName|number)[]|nil Optional. Array of things to exclude, must be used with IncludeThing.
--- @field Exclude KindOfList|nil Optional. Defines objects KindOf to exclude. Directly reduce search space.
--- @field Rule "ANY"|"ALL"|nil Optional. The filter rule, either "ANY" or "ALL".
--- @field Include KindOfList|nil Optional. Defines objects KindOf to include, such as "SMALL_MISSILE", "AIRCRAFT", "SHIP", etc.
--- @field StatusBitFlags ObjectStatusList|nil Optional. Defines the status flags to include, such as "IGNORING_POWER_DOWN", "SHRUNK".
--- @field StatusBitFlagsExclude ObjectStatusList|nil Optional. Defines the status flags to exclude, such as "IGNORING_POWER_DOWN", "SHRUNK".

--- @class ObjectFilter
-- This represents a filter object, which is used to filter specific units or objects based on some criteria.
-- The details of how the filter works are hidden away.
-- This filter is returned by the CreateObjectFilter function using the FilterParams table.

--- @class AreaParams
--- @field X number The X coordinate.
--- @field Y number The Y coordinate.
--- @field Z number The Z coordinate.
--- @field Radius number The radius of the area.
--- @field DistType "CENTER_2D" The type of distance calculation (e.g., "CENTER_2D").

--- @class Coordinate
--- @field X integer The X coordinate.
--- @field Y integer The Y coordinate.
--- @field Z integer The Z coordinate.

--- JapanMissileMechaAdvanced 
---     TRANSFORMER VEHICLE
--- JapanInterceptorAircraft
---     SUBMARINE VEHICLE
--- 炮兵和重轰炸舰, 变形单位, 基地防御塔

--- FIGHTER_AIRCRAFT (包括3阵营6种飞机，不包括心神和樱花)
--- 未完整列出
--- @alias KindOf
--- | "SELECTABLE"
--- | "STRUCTURE"
--- | "AIRCRAFT"
--- | "FIGHTER_AIRCRAFT"
--- | "INFANTRY"
--- | "SHIP"
--- | "SUBMARINE"
--- | "VEHICLE"
--- | "SIEGE_WEAPON" 
--- | "TRANSFORMER" 
--- | "FS_BASE_DEFENSE"
--- | "EGG"

--- 未完整列出
--- @alias ObjectStatus
--- | "IMMOBILE"
--- | "IGNORE_AI_COMMAND"
--- | "REPAIR_ALLIES_WHEN_IDLE"
--- | "CLEARED_FOR_LANDING"
--- | "WATER_LOCOMOTOR_ACTIVE"
--- | "IS_FIRING_WEAPON"
--- | "IS_RELOADING_WEAPON"
--- | "UNSELECTABLE" 
--- | "WEAPON_UPGRADED_03"
--- | "NO_AUTO_ACQUIRE"
--- | "WEAPON_UPGRADED_01"
--- | "WEAPON_UPGRADED_02"
--- | "AIRBORNE_TARGET"
--- | "HIJACKED"
--- | "STEALTHED"
--- | "NO_COLLISIONS"
--- | "OVERCHARGING_WEAPON"
--- | "SUBMERGED"
--- | "SHROUD_REVEAL_TO_ALL"
--- | "SPECIALABILITY_ACTIVE"
--- | "DAMAGED"
--- | "REALLYDAMAGED"
--- | "HAS_SECONDARY_DAMAGE"
--- | "OVER_WATER"
--- | "POINT_DEFENSE_DRONE_ATTACHED"

--- 未完整列出
--- @alias SpecialPower
--- | "SpecialPower_AlliedFutureTankLaserWeapon"
--- | "SpecialPower_ShrinkRay"
--- | "SpecialPower_AANSTier3IceMissile"
--- | "SpecialPower_AlliedGunshipAircraftHyperSpaceMove"
--- | "SpecialPower_JAIV_Transform"

--- 未完整列出
--- @alias Weapon
--- | "SovietBomberAircraftDeathWeapon"
--- | "AlliedAntiStructureAttackDrones"
--- | "AlliedAntiNavyShipTech1DepthCharge"
--- | "AlliedSupportAircraftIceMissile"

--- 未完整列出
--- @alias ModelStatus 
--- | "ENGAGED" 
--- | "PREATTACK_E" 
--- | "SELECTED" 
--- | "RELOADING_A"
--- | "MOVING"
--- | "ATTACK_MOVING"
--- | "OVER_WATER"

--- @alias Comparison
--- | "<" 
--- | "LT" 
--- | "<=" 
--- | "LE" 
--- | ">"  
--- | "GT"
--- | ">="
--- | "GE" 
--- | "=="
--- | "EQ" 
--- | "~="
--- | "!="
--- | "NE" 

--- 未完整列出
--- @alias Player
--- |"<1st Human Player's Allies incl Self>"
--- |"<All Players>"
--- | "PlyrCivilian"
--- | "PlyrCreeps"
--- | "Player_1"
--- | "Player_2"
--- | "Player_3"
--- | "Player_4"
--- | "Player_5"
--- | "Player_6"

--- @alias CombatUnitName
--- | AlliedAirUnitName 
--- | AlliedNavalUnitName 
--- | AlliedGroundUnitName 
--- | CelestialAirUnitName
--- | CelestialNavalUnitName
--- | CelestialGroundUnitName
--- | JapanAirUnitName
--- | JapanNavalUnitName
--- | JapanGroundUnitName
--- | SovietAirUnitName
--- | SovietNavalUnitName
--- | SovietGroundUnitName
--- | InfantryUnitName

---@alias StructureName
--- | AlliedStructureName
--- | CelestialStructureName
--- | JapanStructureName
--- | SovietStructureName

--- @class CEDSUnitTable
--- @field size integer The number of units for the player
--- @field time number[] A table to track cooldown times (leave empty if not needed)
--- @field unit_id UnitID[] A table to track the unit IDs (leave empty if not needed)
--- @field evac_dict table<UnitID, boolean> A table to track if the unit is in evac state (leave empty if not needed)
--- @field cooldown_dict table<UnitID, number> A table to track the cooldown for each unit (leave empty if not needed)
--- @field [integer] StandardUnitType The actual units in the player's table


--- @class HumanPlayerUnitCollection
--- @field [1] CEDSUnitTable
--- @field [2] CEDSUnitTable
--- @field [3] CEDSUnitTable
--- @field [4] CEDSUnitTable
--- @field [5] CEDSUnitTable
--- @field [6] CEDSUnitTable
--- @field filter_friendly ObjectFilter The friendly filter
--- @field filter_neutral ObjectFilter The neutral filter
--- @field unit_name? string The name of the unit collection

--- @class UnitClassTable
--- @field size integer The number of units for the player
--- @field units StandardUnitType[] The actual units
--- @field ids UnitID[] A table to track the unit IDs

--- @class UnitClassCollection
--- @field unit_class_name string
--- @field unit_added_dict table<UnitID, boolean> A table to track if the unit is added to the collection
--- @field filter_friendly ObjectFilter
--- @field filter_neutral ObjectFilter
--- @field Player_1 UnitClassTable
--- @field Player_2 UnitClassTable
--- @field Player_3 UnitClassTable
--- @field Player_4 UnitClassTable
--- @field Player_5 UnitClassTable
--- @field Player_6 UnitClassTable
--- @field PlyrCivilian UnitClassTable
--- @field PlyrCreeps UnitClassTable

--- note:
--- static vs dynamic error checking
--- The IDE can only check for static errors, which are errors that can be detected at compile time.
--- Dynamic errors are runtime errors that can only be detected when the code is executed.
--- ex: 
--- CEDSUnitTable.wrongtime = {} 
---     wrongtime is an invalid field and will be detected by the IDE
--- HumanPlayerUnitCollection[100] = {} 
---     100 is out of designed index range for HumanPlayerUnitCollection-->(1-6)
---     The IDE will not detect this error because it is a dynamic error that can only be detected at runtime.



--- @class EES_Base
--- Base class for all Evacuation Systems (e.g., HEES, FighterEvac)
--- @field _MAX_COOLDOWN integer The maximum cooldown value
--- @field _EVAC_UNIT_TABLE UnitClassCollection The unit collection for evacuation
--- @field _EVAC_TIME_DICT table<UnitID, integer > The dictionary to store the timestamp for each unit
--- @field _EVAC_INFO EvacInfo The evacuation information
--- @field isEvacuating fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit is evacuating
--- @field isEvacAllowedByStatus fun(self: EES_Base, unit:StandardUnitType, player:Player):boolean Function to check if the unit can evacuate based on status
--- @field canEvacuate fun(self: EES_Base, unit:StandardUnitType, id:UnitID, player:Player):boolean Function to check if the unit can evac by checking unit cooldown timer
--- @field shouldEvacuateConservative fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit should evacuate, conservative approach
--- @field shouldEvacuateAggressive   fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit should evacuate, aggressive approach
--- @field isEvacAllowedByStance      fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit can evacuate based on stance
--- @field isEvacAllowedByStanceDefensive fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit can evacuate based on more defensive stance
--- @field evacuateUnit          fun(self: EES_Base, unit:StandardUnitType, player: Player, player_start: string) Function to evacuate the unit
--- @field canCompleteEvacuation fun(self: EES_Base, unit:StandardUnitType, id:UnitID):boolean Function to check if the evacuation can be completed
--- @field completeEvacuation    fun(self: EES_Base, unit:StandardUnitType) Function to complete the evacuation

--- Structure that holds multiple target lists and their sizes
---@class TargetLists
---@field size integer              -- Total number of target lists
---@field target_list_sizes integer[] -- Array storing the size of each target list
---@field [integer] StandardUnitType[]        -- Each index holds a target list (array of targets)
---@field all_potential_targets StandardUnitType[] -- Array of all potential targets for the group
---@field all_potential_targets_size integer -- Size of the all_potential_targets array


--- FCS Name Enum
--- @alias FCSName "AOLSCS"|"CSFAS"|"ATFACS"|"STBMFAS"|"CASCS"|"ECMICS"|"STEIAS"

--- @alias Stance "AGGRESSIVE"|"GUARD"|"HOLD_POSITION"|"HOLD_FIRE"|"OTHER" -- Stance enum, 0: Other, 1: Aggressive, 2: Guard, 3: HoldPosition, 4: HoldFire


--- General Fire Control System (FCS) type
---@class FCS
---@field name FCSName The name of the FCS system
---@field artillery_to_target_ratio integer The ratio of artillery to target
---@field isPrecisionStrike boolean Flag to indicate if the FCS is a precision strike system
---@field isFullOverride boolean Flag to indicate if the FCS is a full override system on Unit Target Acquisition
---@field hp_threshold_LVT  integer The low value target (LVT) HP threshold for precision strike
---@field isHighValueTargetFn fun(target: StandardUnitType): boolean Function to check if the target is a high-value target
---@field isLowValueTarget fun(self: FCS, target: StandardUnitType): boolean Function to check if the target is a low-value target
---@field artillery_table HumanPlayerUnitCollection The table of artillery units
---@field artillery_range integer The range of the artillery
---@field artillery_grouping_range_threshold integer The threshold for grouping the artillery
---@field target_allocated_dict table<UnitID, integer> Dictionary to store allocated targets
---@field artillery_allocated_dict table<UnitID, boolean> Dictionary to store artillery that has been assigned to a target
---@field artillery_to_target_dict table<UnitID, StandardUnitType> Dictionary to store the target for the artillery
---@field artillery_stance_dict table<UnitID, Stance> Dictionary to store the stance of the artillery
---@field canAllocateTarget fun(self: FCS, target: StandardUnitType): boolean Function to check if the target can be allocated
---@field _calculateTargetAllocationLimit fun(self: FCS, target: StandardUnitType): integer Function to calculate the target allocation limit
---@field canAllocateArtillery fun(self: FCS, artillery: StandardUnitType): boolean Function to check status of artillery to determine if it can be allocated
---@field _stanceAllowArtilleyAllocation fun(self: FCS, artillery: StandardUnitType): boolean Function to check if the artillery stance allows allocation
---@field canAllocateArtilleryToTarget fun(self: FCS, artillery: StandardUnitType, target: StandardUnitType): boolean Function to check if the artillery can be allocated to the target
---@field allocateArtilleryToTarget fun(self: FCS, artillery: StandardUnitType, target: StandardUnitType) Function to allocate artillery to a target
---@field _assignTargetByID fun(self: FCS, targetID: UnitID) Function to assign a target to one or multiple artillery units
---@field shouldReallocateArtillery fun(self: FCS, artillery: StandardUnitType): boolean Function to check if the artillery should be reallocated
---@field resetArtilleryAllocation fun(self: FCS, artillery: StandardUnitType) Function to reset the artillery allocation
---@field isTargetAllocated fun(self: FCS, target: StandardUnitType): boolean Function to check if the target is already allocated
---@field isArtilleryAllocated fun(self: FCS, artillery: StandardUnitType): boolean Function to check if the artillery is already allocated
---@field _orderAttack fun(self: FCS, artillery: StandardUnitType, target: StandardUnitType) Function to order the artillery to attack the target
---@field handleArtilleryFCSOverride fun(self: FCS, artillery: StandardUnitType) Function to handle FCS override

--- FCS_Running_Data class definition
---@class FCS_Running_Data
---@field _global_timer integer The global timer for all systems, counts down from 60 to 0
---@field _GLOBAL_TIMER_MAX integer The maximum value for the global timer before it resets
---@field _TARGET_ALLOCATION_RESET_INTERVAL table<FCSName, integer> Constant values for target allocation reset intervals (in seconds)
---@field _ARTILLERY_STANCE_RESET_INTERVAL table<FCSName, integer> Constant values for artillery stance reset intervals (in seconds)
---@field AOLSCS FCS The FCS object for AOLSCS
---@field CSFAS FCS The FCS object for CSFAS
---@field ATFACS FCS The FCS object for ATFACS
---@field STBMFAS FCS The FCS object for STBMFAS
---@field CASCS FCS The FCS object for CASCS
---@field ECMICS FCS The FCS object for ECMICS
---@field STEIAS FCS The FCS object for STEIAS
---@field updateTimers fun(self: FCS_Running_Data) Function to update the global timer
---@field getGlobalTimer fun(self: FCS_Running_Data): number Function to retrieve the current value of the global timer
---@field isTimeToResetTargetAllocation fun(self: FCS_Running_Data, fcs: FCSName): boolean Function to check if it's time to reset target allocation
---@field resetTargetAllocation fun(self: FCS_Running_Data, fcs: FCSName) Function to reset target allocation
---@field isTargetVisiblePVE fun (self: FCS_Running_Data, target: StandardUnitType): boolean Function to check if the target is visible for human players in PVE
---@field _findAndGroupNearbyUnits fun(self: FCS_Running_Data, current: StandardUnitType, grouping_range_threshold: number, artillery_grouped: table<string, boolean>, player_index: integer, fcs: FCSName, artillery_table: HumanPlayerUnitCollection): StandardUnitType[], integer Function to find and group nearby units
---@field _prioritizeTargetsForGroup fun(self: FCS_Running_Data, fcs_group: StandardUnitType[], fcs_group_size: integer, current: StandardUnitType, player_index: integer, fcs: FCSName): TargetLists Function to prioritize targets for a group of artillery units
---@field _allocateTargetsToGroup fun(self: FCS_Running_Data, fcs_group: StandardUnitType[], fcs_group_size: integer, current: StandardUnitType, player_index: integer, fcs: FCSName, target_lists: TargetLists) Function to allocate targets to a group of artillery units
---@field groupArtilleryAndAllocateTargets fun(self: FCS_Running_Data, player_index: integer, fcs: FCSName) Function to group and allocate targets for the artillery
---@field _calculate_FCS_Group_center fun(self: FCS_Running_Data, fcs_group: StandardUnitType[], fcs_group_size: integer): integer, integer, integer Function to calculate the center of the artillery group
---@field _calculate_FCS_Group_radius fun(self: FCS_Running_Data, fcs_group: StandardUnitType[], fcs_group_size: integer): integer Function to calculate the radius of the artillery group
---@field runFCS fun(self: FCS_Running_Data, fcs_name: FCSName) Function to run the FCS system



--- @class FilterBuff
--- @field filterAircraftToBuff ObjectFilter
--- @field filterBaseDefenseToBuff ObjectFilter
--- @field filterNavyToBuff ObjectFilter
--- @field filterArmyVehicleToBuff ObjectFilter
--- @field filterInfantryToBuff ObjectFilter
--- @field filterTransformersToBuff ObjectFilter
--- @field filterUnselectableToBuff ObjectFilter
--- @field filterOtherSelectableToBuff ObjectFilter
--- @field filterROF2X ObjectFilter
--- @field filterROF20 ObjectFilter
--- @field filterRange20 ObjectFilter
--- @field filterSAVVT4 ObjectFilter
--- @field filterSHAAMT ObjectFilter
--- @field filterSHAVI ObjectFilter
--- @field filterAAAVT1 ObjectFilter
--- @field filterSTHeli ObjectFilter
--- @field filterFortressShip ObjectFilter
--- @field filterRange50 ObjectFilter
--- @field filterRange50_Alt ObjectFilter


--- @class AttributeModifier

--- @class ModifierBuff
--- @field mod_range5 AttributeModifier
--- @field mod_rof2X AttributeModifier
--- @field mod_rof3X AttributeModifier
--- @field mod_rof15 AttributeModifier
--- @field mod_rof20 AttributeModifier
--- @field mod_range50 AttributeModifier
--- @field mod_range50_alt AttributeModifier
--- @field mod_range2X AttributeModifier
--- @field mod_range25 AttributeModifier
--- @field mod_vision AttributeModifier

--- @alias Upgrade
--- | TechUpgrade

--- @alias TechUpgrade
--- |"Upgrade_AlliedTech2"| "Upgrade_AlliedTech3"|"Upgrade_AlliedTech4"|"Upgrade_CelestialAirfield"

--- @alias Command
--- | "Command_Upgrade_CelestialAirfield"
--- | "Command_AlliedGunshipAircraftHyperSpaceMove"
--- | "Command_AlliedFighterAircraftReturnToAirfield"
--- | "Command_CelestialFighterAircraftReturnToAirfield"
--- | "Command_SovietFighterAircraftReturnToAirfield"
--- | "Command_AlliedAntiGroundAircraftReturnToAirfield"
--- | "Command_JAIV_Transform"

--- @alias AlliedAirUnitName
--- | "AlliedFighterAircraft"
--- | "AlliedInterceptorAircraft"
--- | "AlliedAntiGroundAircraft"
--- | "AlliedSupportAircraft"
--- | "AlliedBomberAircraft"
--- | "AlliedGunshipAircraft"

--- @alias AlliedNavalUnitName
---| "AlliedAntiNavalScout"
---| "AlliedAntiAirShip"
---| "AlliedAntiInfantryVehicle"
---| "AlliedAntiNavyShipTech1"
---| "AlliedAntiNavyShipTech3"
---| "AlliedAntiStructureShip"

--- @alias AlliedGroundUnitName
---| "AlliedAntiInfantryVehicle_Ground"
---| "AlliedAntiAirVehicleTech1"
---| "AlliedAntiVehicleVehicleTech1"
---| "PrismTank"
---| "AlliedAntiStructureVehicle"
---| "AlliedAntiVehicleVehicleTech3"
---| "AlliedFutureTank"

--- CelestialFighterAircraft have special build command: Command_Constructfenghuang 
--- @alias CelestialAirUnitName
--- | "CelestialFighterAircraft" 
--- | "CelestialSupportAircraft"
--- | "CelestialInterceptorAircraft"
--- | "CelestialAttackerAircraft"
--- | "CelestialBomberAircraft"
--- | "CelestialAdvanceAircraftTech4"

--- @alias CelestialNavalUnitName
--- | "CelestialAntiNavyShipTech1"
--- | "CelestialAntiAirShip_Water"
--- | "CelestialAlmightlyShip"
--- | "CelestialAntiNavyShipTech3"
--- | "CelestialAntiStructureShip"

--- @alias CelestialGroundUnitName
--- | "CelestialAntiAirShip"
--- | "CelestialAntiInfantryVehicle_B"
--- | "CelestialLongRangeMissileVehicle_B"
--- | "CelestialAntiVehicleVehicleTech1"
--- | "CelestialAntiVehicleVehicleTech3"
--- | "CelestialAntiStructureVehicle"
--- | "CelestialAntiVehicleVehicleTech4"

--- These transformer units are built from warfactory but can transform into aircraft.
--- @alias JapanAirUnitName
---| "JapanAntiInfantryVehicle"
---| "JapanMissileMechaAdvanced"
---| "JapanInterceptorAircraft_Ground"

--- Japan antiair ship and interceptor aircraft are built from shipyard but can transform into aircraft.
--- JapanFortressShip are built from construction yard but can transform into ship and aircraft
--- @alias JapanNavalUnitName
---| "JapanNavyScoutShip"
---| "JapanAntiVehicleVehicleTech1_Naval"
---| "JapanAntiAirShip"
---| "JapanAntiVehicleShip"
---| "JapanInterceptorAircraft"
---| "JapanAntiNavyShipTech3"
---| "JapanAntiStructureShip"
---| "JapanFortressShip"

--- Japan antiair vehicle can transform into helicopter.
--- @alias JapanGroundUnitName
---| "JapanAntiVehicleVehicleTech1"
---| "JapanAntiAirVehicleTech1"
---| "JapanSentinelVehicle"
---| "JapanAntiStructureVehicle"
---| "JapanAntiVehicleVehicleTech3"
---| "JapanMechaX"

--- @alias SovietAirUnitName
--- | "SovietFighterAircraft"
--- | "SovietInterceptorAircraft"
--- | "SovietAntiGroundAircraft"
--- | "SovietAntiGroundAttacker"
--- | "SovietBomberAircraft"
--- | "SovietTransportAircraft"

--- @alias SovietNavalUnitName
--- | "SovietAntiAirShip"
--- | "SovietAntiNavyShipTech1"
--- | "SovietAntiNavyShipTech2"
--- | "SovietAntiNavyShipTech3"
--- | "SovietAntiStructureShip"

--- @alias SovietGroundUnitName
--- | "SovietScoutVehicle"
--- | "SovietAntiInfantryVehicle"
--- | "SovietAntiAirShip_Ground"
--- | "SovietHeavyAntiVehicleVehicleTech1"
--- | "SovietSledgehammerSPG"
--- | "SovietAntiStructureVehicle"
--- | "SovietAntiVehicleVehicleTech3"
--- | "SovietAntiVehicleVehicleTech4"

--- @alias NonCombatUnitName
---| "AlliedMiner"
---| "AlliedMCV"
---| "CelestialMiner"
---| "CelestialMCV"
---| "JapanLightTransportVehicle"
---| "JapanMiner"
---| "JapanMCV"
---| "SovietMiner"
---| "SovietMCV"
---| "SovietSurveyor"

--- @alias CampaignUnitName
---| "AlliedArtilleryVehicle"
---| "CelestialAntiAirVehicle"
---| "DefenderAntiVehicleVehicleTech1"
---| "OverlordTank"
---| "SovietAntiAirVehicle"
---| "SovietGrinderVehicle"
---| "SovietAntiVehicleVehicleTech1"
---| "tankdestroyer"

--- NO CONSTRUCT COMMAND, NOTE Celestrial HJ-10 doesn't even have a name, nor a construct command
--- @alias SpecialUnitName 
---| "AlliedGaintAircraftCarrier"  
---| "AlliedHumveeVehicle" 
---| "CelestialEngineerRepairDrone"
---| "SovietAK130Turret"
---| "SovietShipMissileTurret"
---| "AlliedPhalanxTurret"
---| "AlliedMissileTurret"
---| "alliedantistructurevehiclecannoneffect"
---| "alliedantistructurevehiclecannoneffect_vet"
---| "AlliedAntiStructureVehicleCannonEffect_Enhanced"
---| "AlliedAntiStructureVehicleCannonEffect_EnhancedVet"
---| "SovietHeavyAntiAirMissileTurret"


--- @alias InfantryUnitName
--- | "SovietHeavyAntiVehicleInfantry"
--- | "SovietAntiVehicleInfantry"
--- | "AlliedAntiVehicleInfantry"
--- | "AlliedCryoLegionnaire"
--- | "SovietEngineer"


--- @alias AlliedStructureName
--- | "AlliedAirfield"
--- | "AlliedNavalYard"
--- | "AlliedWarFactory"

--- @alias CelestialStructureName
--- | "CelestialAirfield"
--- | "CelestialNavalYard"
--- | "CelestialWarFactory"

--- @alias JapanStructureName
--- | "JapanNavalYard"
--- | "JapanWarFactory"

--- @alias SovietStructureName
--- | "SovietAirfield"
--- | "SovietNavalYard"
--- | "SovietWarFactory"
--- 


---@alias MapTeamWarfactory
---| "AlliedWarFactoryT1"
---| "AlliedWarFactoryT2"
---| "AlliedWarFactoryT3"
---| "CelestialWarFactoryT1"
---| "CelestialWarFactoryT2"
---| "CelestialWarFactoryT3"
---| "JapanWarFactoryT1"
---| "JapanWarFactoryT2"
---| "JapanWarFactoryT3"
---| "SovietWarFactoryT1"
---| "SovietWarFactoryT2"
---| "SovietWarFactoryT3"
---| "JapanAirfield"


---@alias MapTeamAirfield
---| "AlliedAirfieldFighter"
---| "AlliedAirfieldBomber"
---| "AlliedAirfieldSupport"
---| "CelestialAirfieldFighter"
---| "CelestialAirfieldBomber"
---| "CelestialAirfieldSupport"
---| "SovietAirfieldFighter"
---| "SovietAirfieldBomber"
---| "SovietAirfieldSupport"

---@alias MapTeamNavalYard
---| "AlliedNavalYardBoat"
---| "AlliedNavalYardShip"
---| "AlliedNavalYardFlagship"
---| "CelestialNavalYardBoat"
---| "CelestialNavalYardShip"
---| "CelestialNavalYardFlagship"
---| "JapanNavalYardBoat"
---| "JapanNavalYardShip"
---| "JapanNavalYardFlagship"
---| "SovietNavalYardBoat"
---| "SovietNavalYardShip"
---| "SovietNavalYardFlagship"
----

-- 海豚/激流/水翼船10秒，突击20，波塞冬30，航母40
-- 樱花5秒，小潜艇，海啸10秒，海翼11秒，剃刀20，太刀30，将军40
-- 猎船/防空船10秒，计萌20，玄冥30，玄武40
-- 快艇/牛蛙10秒，电鱼10秒，阿库拉20秒，光荣30秒，无畏40秒

-- 阿波罗10秒，维和/冰冻/阿瑞斯15秒，世纪25秒, 先锋35秒

-- 米格10秒，双刃/苏霍伊15秒，伊尔20秒，基洛夫35秒
-- 凤凰10秒，朱雀/毕方/重明15秒，金乌25秒，摇光40秒，龙船2分钟

--     炸毁大电不影响苏联空军T2
    
-- ACV/多功能/守护者10秒，
-- 磁弩/凌波/麒麟10秒，
-- 天狗9秒，VX 10秒， 海啸10秒，心神16秒
-- 蜘蛛5秒，牛蛙/镰刀10秒
--- 重锤，光棱，青峰，浪人，15秒
