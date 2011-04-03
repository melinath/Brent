local game_events = wesnoth.game_events
local map_utils = wesnoth.require "~add-ons/Brent/lua/maps/utils.lua"


local old_on_event = game_events.on_event
function game_events.on_event(name)
	if name == "prestart" then
		map_utils.mark_visited(map.id)
		map_utils.mark_known(map.id)
		map_utils.load_shroud(map.id)
	elseif name == "victory" or name == "defeat" then
		map_utils.store_shroud(map.id)
	end
	if old_on_event ~= nil then old_on_event(name) end
end
