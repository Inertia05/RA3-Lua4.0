
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


--- @alias UnitID number
--- The actual value stored in the StandardUnitType table
--- This is the GUID of the unit, which is unique and invariant for the unit.
--- This is the actual value stored in the StandardUnitType table.
--- Value can be retrived by ObjectGetId(unit) function.

--- @class FilterParams
--- @field Relationship string|nil Optional. Defines relationships like "ENEMIES", "NEUTRAL", or "ALLIES".
--- @field IncludeThing (string|number)[] Optional. Array of things to include, which could be names or hashed values.
--- @field ExcludeThing (string|number)[]|nil Optional. Array of things to exclude, must be used with IncludeThing.
--- @field Exclude string|nil Optional. UNTESTED. Defines the kinds of objects to exclude.
--- @field Rule "ANY"|"ALL"|nil Optional. The filter rule, either "ANY" or "ALL".
--- @field Include string|nil Optional. Defines the kinds of objects to include, such as "SMALL_MISSILE", "AIRCRAFT", "SHIP", etc.
--- @field StatusBitFlags string|nil Optional. Defines the status flags to include, such as "IGNORING_POWER_DOWN", "SHRUNK".
--- @field StatusBitFlagsExclude string|nil Optional. Defines the status flags to exclude, such as "IGNORING_POWER_DOWN", "SHRUNK".



--- @class ObjectFilter
-- This represents a filter object, which is used to filter specific units or objects based on some criteria.
-- The details of how the filter works are hidden away.
-- This filter is returned by the CreateObjectFilter function using the FilterParams table.

--- A type representing 3D coordinates.
--- @class Position
--- @field x number The x-coordinate.
--- @field y number The y-coordinate.
--- @field z number The z-coordinate.


--- @class AreaParams
--- @field X number The X coordinate.
--- @field Y number The Y coordinate.
--- @field Z number The Z coordinate.
--- @field Radius number The radius of the area.
--- @field DistType "CENTER_2D" The type of distance calculation (e.g., "CENTER_2D").

--- @class PlayerUnitTable
--- @field size integer The number of units for the player
--- @field time number[] A table to track cooldown times (leave empty if not needed)
--- @field unit_id UnitID[] A table to track the unit IDs (leave empty if not needed)
--- @field evac_dict table<UnitID, boolean> A table to track if the unit is in evac state (leave empty if not needed)
--- @field cooldown_dict table<UnitID, number> A table to track the cooldown for each unit (leave empty if not needed)
--- @field [number] StandardUnitType The actual units in the player's table


--- @class UnitCollection
--- @field [1] PlayerUnitTable
--- @field [2] PlayerUnitTable
--- @field [3] PlayerUnitTable
--- @field [4] PlayerUnitTable
--- @field [5] PlayerUnitTable
--- @field [6] PlayerUnitTable
--- @field filter_friendly ObjectFilter The friendly filter
--- @field filter_neutral ObjectFilter The neutral filter
--- @field unit_name? string The name of the unit collection


--- note:
--- static vs dynamic error checking
--- The IDE can only check for static errors, which are errors that can be detected at compile time.
--- Dynamic errors are runtime errors that can only be detected when the code is executed.
--- ex: 
--- PlayerUnitTable.wrongtime = {} 
---     wrongtime is an invalid field and will be detected by the IDE
--- UnitCollection[100] = {} 
---     100 is out of designed index range for UnitCollection-->(1-6)
---     The IDE will not detect this error because it is a dynamic error that can only be detected at runtime.



--- @class EES_Base
--- Base class for all Evacuation Systems (e.g., HEES, FighterEvac)
--- @field name string The name of the evacuation system
--- @field evac_text string The text to display when evacuating
--- @field standby_text string The text to display when in standby
--- @field _display_cooldown number The current cooldown for UI display
--- @field _DISPLAY_DURATION number The duration for UI display
--- @field _MAX_COOLDOWN_UI number The maximum cooldown for UI display
--- @field _MAX_COOLDOWN number The maximum cooldown value
--- @field _EVAC_UNIT_TABLE UnitCollection The unit collection for evacuation
--- @field _EVAC_COMMAND string The evacuation command
--- @field shouldDisplaySystemUI fun(self: EES_Base):boolean Function to check if the UI should be displayed
--- @field displaySystemUI fun(self: EES_Base, unit:StandardUnitType) Function to display the UI
--- @field updateCooldownUI fun(self: EES_Base) Function to update the UI cooldown
--- @field canEvacuate fun(self: EES_Base, player_index: number, unit_index_in_table: number):boolean Function to check if the unit can evac by checking unit cooldown timer
--- @field shouldEvacuateConservative fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit should evacuate, conservative approach
--- @field shouldEvacuateAggressive   fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit should evacuate, aggressive approach
--- @field isEvacAllowedByStance      fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit can evacuate based on stance
--- @field isEvacAllowedByStanceDefensive fun(self: EES_Base, unit:StandardUnitType):boolean Function to check if the unit can evacuate based on more defensive stance
--- @field evacuateUnit          fun(self: EES_Base, unit:StandardUnitType, player_index: number, player_start: string, unit_index_in_table: number) Function to evacuate the unit
--- @field canCompleteEvacuation fun(self: EES_Base, unit:StandardUnitType, player_index: number):boolean Function to check if the evacuation can be completed
--- @field completeEvacuation    fun(self: EES_Base, unit:StandardUnitType, player_index: number, unit_index_in_table:number) Function to complete the evacuation
--- @field updateCooldown        fun(self: EES_Base, player_index: number, unit_index_in_table: number) Function to update the evacuation cooldown for the unit
--- @field _resetCooldown        fun(self: EES_Base, player_index: number, unit_index_in_table: number) Function to reset the evacuation cooldown for the unit
--- @field _getUnitIDFromTable   fun(self: EES_Base, player_index: number, unit_index_in_table: number):UnitID|nil Function to get the stored unit ID
--- @field _updateEvacStatus     fun(self: EES_Base, player_index: number, unit_id: UnitID|nil, value:boolean) Function to set the evac dictionary value
--- @field getUnitEvacStatus     fun(self: EES_Base, player_index: number, unit_id: UnitID|nil):boolean|nil Function to get the evac status of the unit


--- FCS Name Enum
--- @alias FCSName "AOLSCS"|"CSFAS"|"ATFACS"|"STBMFAS"|

--- @alias Stance 0|1|2|3|4 -- Stance enum, 0: Other, 1: Aggressive, 2: Guard, 3: HoldPosition, 4: HoldFire

--- General Fire Control System (FCS) type
---@class FCS
---@field name FCSName The name of the FCS system
---@field artillery_table UnitCollection The table of artillery units
---@field artillery_range number The range of the artillery
---@field artillery_grouping_range_threshold number The threshold for grouping the artillery
---@field target_allocated_dict table<UnitID, boolean> Dictionary to store allocated targets
---@field artillery_allocated_dict table<UnitID, boolean> Dictionary to store artillery that has been assigned to a target
---@field artillery_stance_dict table<UnitID, Stance> Dictionary to store the stance of the artillery
---@field canAllocateTarget fun(self: FCS, target: any): boolean Function to check if the target can be allocated
---@field canAllocateArtillery fun(self: FCS, artillery: StandardUnitType, current_target: StandardUnitType|nil): boolean Function to check status of artillery to determine if it can be allocated
---@field allocateArtilleryToTarget fun(self: FCS, artillery: StandardUnitType, target: StandardUnitType) Function to allocate artillery to a target
---@field isTargetAllocated fun(self: FCS, target: any): boolean Function to check if the target is already allocated
---@field isArtilleryAllocated fun(self: FCS, artillery: StandardUnitType): boolean Function to check if the artillery is already allocated
---@field _getArtilleryStance fun(self: FCS, artillery: StandardUnitType): Stance Function to get the stance of the artillery and update it if it is not in the dictionary
---@field _orderAttack fun(self: FCS, artillery: StandardUnitType, target: StandardUnitType) Function to order the artillery to attack the target



--- FCS_Running_Data class definition
---@class FCS_Running_Data
---@field _global_timer number The global timer for all systems, counts down from 60 to 0
---@field _GLOBAL_TIMER_MAX number The maximum value for the global timer before it resets
---@field _TARGET_ALLOCATION_RESET_INTERVAL table<FCSName, number> Constant values for target allocation reset intervals (in seconds)
---@field _ARTILLERY_STANCE_RESET_INTERVAL table<FCSName, number> Constant values for artillery stance reset intervals (in seconds)
---@field AOLSCS FCS The FCS object for AOLSCS
---@field CSFAS FCS The FCS object for CSFAS
---@field ATFACS FCS The FCS object for ATFACS
---@field STBMFAS FCS The FCS object for STBMFAS
---@field updateTimers fun(self: FCS_Running_Data) Function to update the global timer
---@field getGlobalTimer fun(self: FCS_Running_Data): number Function to retrieve the current value of the global timer
---@field isTimeToResetArtilleryStanceInfo fun(self: FCS_Running_Data, fcs: FCSName): boolean Function to check if it's time to reset artillery stance info
---@field resetArtilleryStanceInfo fun(self: FCS_Running_Data, fcs_name: FCSName) Function to reset artillery stance info
---@field isTimeToResetTargetAllocation fun(self: FCS_Running_Data, fcs: FCSName): boolean Function to check if it's time to reset target allocation
---@field resetTargetAllocation fun(self: FCS_Running_Data, fcs: FCSName) Function to reset target allocation
---@field _findAndGroupNearbyUnits fun(self: FCS_Running_Data, current: StandardUnitType, grouping_range_threshold: number, artillery_grouped: table<string, boolean>, player_index: integer, fcs: FCSName, artillery_table: UnitCollection): StandardUnitType[], integer Function to find and group nearby units
---@field _allocateTargetsToGroup fun(self: FCS_Running_Data, fcs_group: StandardUnitType[], fcs_group_size: integer, artillery_range: integer, current: StandardUnitType, player_index: integer, fcs: FCSName) Function to allocate targets to a group of artillery units
---@field groupArtilleryAndAllocateTargets fun(self: FCS_Running_Data, player_index: integer, fcs: FCSName) Function to group and allocate targets for the artillery
---@field _calculate_FCS_Group_center fun(self: FCS_Running_Data, fcs_group: StandardUnitType[], fcs_group_size: integer): number, number, number Function to calculate the center of the artillery group
---@field _calculate_FCS_Group_radius function fun(self: FCS_Running_Data, fcs_group: StandardUnitType[], fcs_group_size: integer): number Function to calculate the radius of the artillery group
---@field runFCS fun(self: FCS_Running_Data, fcs_name: FCSName) Function to run the FCS system