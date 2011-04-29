local game_events = wesnoth.game_events
local _ = wesnoth.textdomain "wesnoth-Brent"


-- NOTE:: Time is represented in hours.


function current_time_display()
	quest_utils.message(string.format("It is day %d.", math.floor(time_utils.get_time())))
end


local old_on_event = game_events.on_event
function game_events.on_event(name)
	if name == "new turn" then
		local time = time_utils.get_time()
		local new_time
		if time == nil then
			new_time = 0
		else
			new_time = time + map:get_timedelta()
		end
		time_utils.set_time(new_time)
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