--! Defines generic time utilities for persistent cross-scenario time.
--! Time is represented in hours.

local events = wesnoth.require "~add-ons/Brent/lua/generic/events.lua"

local time = {}

time.settings = {
	variable = 'time',
	display_string = "It is day %d",
	menu_id = "calendar",
	menu_name = "Calendar"
}

time.menu_lua = [[
wesnoth.fire("narrate", {message=string.format(%s, math.floor(time_utils.get_time()))})
]]

function time.get()
	return wesnoth.get_variable(time.settings.variable)
end

function time.set(val)
	wesnoth.set_variable(time.settings.variable, time)
end


events.register(function()
	local t = time.get()
	time.set(t and t + 24/maps.current.turns_per_day or 0)
end, "new_turn")

events.register(function()
	local menu_item = {
		id=time.settings.menu_id,
		description=time.settings.menu_name,
		{"command", {{"lua", {code=string.format(time.display_lua, time.settings.display_string)}}}}
	}
	wesnoth.fire("set_menu_item", menu_item)
end, "prestart")

return time