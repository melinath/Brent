local events = wesnoth.require "~add-ons/Brent/lua/generic/events.lua"

local capture = {}

capture.settings = {
	disallow_sides = {1=true}
}

capture.villages = {}
function capture.add_village(x, y)
	if capture.villages[x] == nil then villages[x] = {} end
	villages[x][y] = wesnoth.get_village_owner(x, y)
end

events.register(function()
	local c = wesnoth.current.event_context
	local u = wesnoth.get_unit(c.x1, c.y1)
	
	if u == nil then
		capture.add_village(c.x1, c.y1)
	elseif capture.settings.disallow_sides[u.side] then
		if villages[c.x1] ~= nil then
			wesnoth.set_village_owner(c.x1, c.y1, villages[c.x1][c.y1])
		end
	end
end, "capture")

events.register(function()
	for i, loc in ipairs(wesnoth.get_locations{terrain="*^V*"}) do
		capture.add_village(unpack(loc))
	end
end, "preload")

return capture