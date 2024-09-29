--- 全部是类型定义，不需要执行，仅负责帮助IDE识别类型并提供代码提示


--- @class StandardUnitType
-- This represents a standard unit type used across the game, details are hidden away.
-- This is actually a table that hold the unit's GUID which is unique and invariant for the unit.
-- The table retrived from game engine however is not invariant and can change over time.
-- Assume this class handles all unit interactions and is referenced across multiple functions.

--- @class ObjectFilter
-- This represents a filter object, which is used to filter specific units or objects based on some criteria.
-- The details of how the filter works are hidden away.


--- @class PlayerUnitTable
--- @field size number The number of units for the player
--- @field time table<number, number> An optional table to track cooldown times (optional)
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
--- @field _display_cooldown number The current cooldown for UI display
--- @field _MAX_COOLDOWN number The maximum cooldown value
local EES_Base = {
    --- Function to check if the UI should be displayed
    --- @return boolean
    shouldDisplaySystemUI = function(self) return false end,

    --- Function to update the UI cooldown
    updateCooldownUI = function(self) end,

    --- Function to check if the unit can evacuate
    --- @param self EES_Base
    --- @param player_index number
    --- @param unit_index_in_table number
    --- @return boolean
    canEvacuate = function(self, player_index, unit_index_in_table) return false end,

    --- Function to evacuate the unit
    --- @param self EES_Base
    --- @param unit any
    --- @param player_index number
    --- @param player_start string
    --- @param unit_index_in_table number
    evacuateUnit = function(self, unit, player_index, player_start, unit_index_in_table) end,

    --- Function to update the evacuation cooldown
    --- @param self EES_Base
    --- @param player_index number
    --- @param unit_index_in_table number
    updateCooldown = function(self, player_index, unit_index_in_table) end
}
