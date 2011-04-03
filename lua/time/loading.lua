local game_events = wesnoth.game_events
local time_utils = wesnoth.require "~/add-ons/Brent/lua/time/utils.lua"
local _ = wesnoth.textdomain "wesnoth-Brent"


function current_time_display()
	quest_utils.message(string.format("It is day %d.", math.floor(time_utils.get_time())))
end


local old_on_event = game_events.on_event
function game_events.on_event(name)
	if name == "new turn" then
		local time = time_utils.get_time()
		time_utils.set_time(time + map:get_timedelta())
	elseif name == "prestart" then
		menu_item = {
			id="calendar",
			description = _ "Calendar",
			{"command", {{"lua", {code="current_time_display()"}}}}
		}
		wesnoth.fire("set_menu_item", menu_item)
	end
	if old_on_event ~= nil then old_on_event(name) end
end