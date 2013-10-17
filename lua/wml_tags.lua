local helper = wesnoth.require "lua/helper.lua"
local wlp_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/wlp_utils.lua"
_ = wesnoth.textdomain "wesnoth-Brent"


-- CHARACTERISTIC TAGS --

--! [faction_shift]

-- given a paired faction/number list, shifts the player's faction rating
-- by that number.
-- Factions: dwarves, faeries, flame 

local function faction_shift(args)
	local args = args.__parsed
	for f,v in pairs(args) do
		o=wesnoth.get_variable('factions.'..f) or 0
		wesnoth.set_variable("factions."..f,o+v)
	end
	wesnoth.set_variable("unit_store")
end

wesnoth.wml_actions.faction_shift = faction_shift

--! [alignment_shift]

-- type=good moves it up, type=bad moves it down, type=neutral moves it towards the
-- center. Takes a filter for the unit(s). value= is the amount. Range is -1000-1000.

local function alignment_shift(args)
	local args = args.__parsed
	local filter = helper.get_child(args, "filter")
	local shift = args.type
	local val = args.value
	local units = wesnoth.get_units(filter)
	
	for i=1,#units do
		local vars = units[i].variables
		local align = vars.alignment
		if shift=='good' then
			align = math.min(align + val, 1000)
		elseif shift=='bad' then
			align = math.max(align - val, -1000)
		elseif shift=='neutral' then
			if align > 0 then
				align = math.max(align - val, 0)
			elseif align < 0 then
				align = math.min(align + val, 0)
			end
		end
		vars.alignment = align
	end
end
wesnoth.wml_actions.alignment_shift = alignment_shift

-- END CHARACTERISTIC TAGS --


-- SCENARIO TAGS --

--! [wandering_monsters]
-- sets certain sides to have their units move randomly within their maximum
-- movement.

local function wandering_monsters()
    wesnoth.fire("store_unit", {
    [1] = { "filter", {side=wesnoth.get_variable("side_number")} },
    variable = "unit_store",
        kill = true
    })
    for i = 0, wesnoth.get_variable("unit_store.length") - 1 do
    local u = wesnoth.get_variable("unit_store[" .. i .. "]")
    wesnoth.fire("store_locations",{
        {"and",{x=u.x,y=u.y,radius=u.max_moves}},
        {"not",{x=u.x,y=u.y}},
        variable="possible_gotos"
        })
    local r=math.random(0,wesnoth.get_variable("possible_gotos.length")-1)
    local target=wesnoth.get_variable("possible_gotos["..r.."]")
    
    wesnoth.set_variable("unit_store[" .. i .. "].goto_x",target.x)
    wesnoth.set_variable("unit_store[" .. i .. "].goto_y",target.y)
    wesnoth.fire("unstore_unit", {
        variable = "unit_store[" .. i .. "]",
        find_vacant = false
        })
    end
    wesnoth.set_variable("unit_store")
    wesnoth.set_variable("possible_gotos")
end
wesnoth.wml_actions.wandering_monsters = wandering_monsters


-- END SCENARIO TAGS --


-- UNIT TAGS --


--! [pronouns], given a unit filter (takes first unit) or a gender, sets the
-- given variable accordingly.
--
-- Example:
-- [pronouns]
--     [filter]
--         name=Scott
--     [/filter]
--     variable=nose
-- [/pronouns]
--
-- The "nose" variable would then be structured as follows:
-- nose.nom :: The nominative pronoun
-- nose.acc :: The accusative pronoun
-- nose.pos :: The possessive pronoun
-- nose.uc  :: A copy of nose with the first letter of each pronoun capitalized
--
-- TODO: replace nose.uc with a helper capfirst function.
local function pronouns(args)
	local args=args.__parsed
	local filter = helper.get_child(args,"filter")
	if filter == nil then error("~wml:[pronouns] missing required filter child.") end
	local variable = args.variable
	if variable == nil then error("~wml:[pronouns] missing required variable= attribute.") end
	local u = wesnoth.get_units(filter)[1]
	wesnoth.set_variable(variable, units.get_pronouns(u))
end
wesnoth.wml_actions.pronouns = pronouns

-- END UNIT TAGS --