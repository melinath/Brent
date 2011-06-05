--! Defines functions and tags for handling generic "interactions" from e.g.
--! stepping on a particular location.
local events = wesnoth.require "~add-ons/Brent/lua/generic/events.lua"
local items = wesnoth.require "lua/wml/items.lua"


local interactions = {}

--! Interaction class
interactions.interaction = events.tag:new("interaction", {
	init = function(self, cfg)
		local o = self:get_parent().init(self, cfg)
		
		local filter = helper.get_child(cfg, "filter")
		if (filter == nil) then error("~wml:[interaction] expects a [filter] child", 0) end
		local command = helper.get_child(cfg, "command")
		if (command == nil) then error("~wml:[interaction] expects a [command] child", 0) end
		
		o.filter = helper.literal(filter)
		o.command = helper.literal(command)
		o.setup = helper.get_child(cfg, "setup")
		o.x = cfg.x
		o.y = cfg.y
		o.image = cfg.image
		
		local old_on_event = game_events.on_event
		function game_events.on_event(name)
			if old_on_event then old_on_event(name) end
			self:on_event(name)
		end
	end,
	
	cfg = nil,
	filter = nil,
	x = nil,
	y = nil,
	image = nil,
	command = nil
})


events.register(function()
	local c = wesnoth.current.event_context
	local u = wesnoth.get_unit(c.x1, c.y1)
	if u ~= nil then
		local ints = interactions.interaction.instances
		for i=1,#ints do
			local int = ints[i]
			if wesnoth.match_unit(u, int.filter) then
			wesnoth.fire("store_unit", {{"filter", {id=u.id}}, variable="unit", kill=false})
			wesnoth.set_variable("x1", c.x1)
			wesnoth.set_variable("x2", c.x2)
			wesnoth.set_variable("y1", c.y1)
			wesnoth.set_variable("y2", c.y2)
			for i=1,#int.command do
				local v = int.command[i]
				wesnoth.fire(v[1], v[2])
			end
			wesnoth.set_variable("unit")
			wesnoth.set_variable("x1")
			wesnoth.set_variable("x2")
			wesnoth.set_variable("y1")
			wesnoth.set_variable("y2")
		end
	end
end, "moveto")

events.register(function()
	local ints = interactions.interaction.instances
	for i=1,#ints do
		local int = ints[i]
		if int.image and int.x and int.y then
			items.place_image(int.x, int.y, int.image)
		end
		if int.setup ~= nil then
			for j=1,#int.setup do
				wesnoth.fire(int.setup[j][1], int.setup[j][2])
			end
		end
	end
end, "prestart")