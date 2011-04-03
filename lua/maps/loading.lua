local game_events = wesnoth.game_events
local map_utils = wesnoth.require "~add-ons/Brent/lua/maps/utils.lua"
local helper = wesnoth.require "lua/helper.lua"


local old_on_event = game_events.on_event
function game_events.on_event(name)
	if name == "prestart" then
		map_utils.mark_visited(map.id)
		map_utils.mark_known(map.id)
		map_utils.load_shroud(map.id)
		-- Set starting position.
		local start_x = wesnoth.get_variable("start_x")
		local start_y = wesnoth.get_variable("start_y")
		local main_id = wesnoth.get_variable("main_id")
		if start_x ~= nil and start_y ~= nil and main_id ~= nil then
			local unit = wesnoth.get_unit(main_id)
			wesnoth.put_unit(start_x, start_y, unit)
			wesnoth.scroll_to_tile(start_x, start_y)
			wesnoth.set_variable("start_x", nil)
			wesnoth.set_variable("start_y", nil)
		end
		-- Storyboard messages
		local msgs = helper.get_variable_array("story_message")
		for i=1,#msgs do
			wesnoth.fire("narrate", {message=msgs[i].message})
		end
		helper.set_variable_array("story_message", {})
	elseif name == "victory" or name == "defeat" then
		map_utils.store_shroud(map.id)
	end
	if old_on_event ~= nil then old_on_event(name) end
end
