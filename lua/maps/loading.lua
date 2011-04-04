local game_events = wesnoth.game_events
local map_utils = wesnoth.require "~add-ons/Brent/lua/maps/utils.lua"
local helper = wesnoth.require "lua/helper.lua"
local items = wesnoth.require "lua/wml/items.lua"


map = {
	id = nil,
	turns_per_day = 6,
	
	config = function(self, cfg)
		self.turns_per_day = cfg.turns_per_day or self.turns_per_day
		self.id = cfg.id
	end,
	dump = function(self)
		return {
			turns_per_day = self.turns_per_day,
			id = self.id
		}
	end,
	get_timedelta = function(self)
		-- timedelta is the local time change per turn
		return 24/self.turns_per_day
	end
}

interactions = {}

--! Interaction base class
local interaction = {
	new = function(self, cfg)
			o = cfg or {}
			setmetatable(o, self)
			self.__index = self
			table.insert(interactions, o)
			return o
		end,
	
	setup = function(self, cfg)
		self.cfg = cfg
		local filter = helper.get_child(cfg, "filter")
		if (filter == nil) then error("~wml:[interaction] expects a [filter] child", 0) end
		local command = helper.get_child(cfg, "command")
		if (command == nil) then error("~wml:[interaction] expects a [command] child", 0) end
		self.filter = helper.literal(filter)
		self.command = helper.literal(command)
		
		local setup = helper.get_child(cfg, "setup")
		if setup ~= nil then
			setup.name = "prestart"
			wesnoth.fire("event", setup)
		end
		
		self.x = cfg.x
		self.y = cfg.y
		self.image = cfg.image
		
		local old_on_event = game_events.on_event
		function game_events.on_event(name)
			if old_on_event then old_on_event(name) end
			self:on_event(name)
		end
	end,
	
	on_event = function(self, name)
		if (name == "moveto") then
			local c = wesnoth.current.event_context
			local u = wesnoth.get_unit(c.x1, c.y1)
			if (wesnoth.match_unit(u, self.filter)) then
				self:activate()
			end
		elseif name == "prestart" and self.image and self.x and self.y then
			items.place_image(self.x, self.y, self.image)
		end
	end,
	activate = function(self)
		for i=1,#self.command do
			local v = self.command[i]
			wesnoth.fire(v[1], v[2])
		end
	end,
	
	dump = function(self)
		return self.cfg
	end,
	
	cfg = nil,
	filter = nil,
	x = nil,
	y = nil,
	image = nil,
	command = nil,
}


local old_on_load = game_events.on_load
function game_events.on_load(cfg)
	for i=#cfg,1,-1 do
		local v = cfg[i]
		if v[1] == "map" then
			local v2 = v[2]
			map:config(v2)
			table.remove(cfg, i)
		elseif v[1] == "interaction" then
			local v2 = v[2]
			local interaction = interaction:new()
			interaction:setup(v2)
			table.remove(cfg, i)
		end
	end
	old_on_load(cfg)
end


local old_on_save = game_events.on_save
function game_events.on_save()
	cfg = old_on_save()
	table.insert(cfg, {"map", map:dump()})
	for i=1,#interactions do
		table.insert(cfg, {"interaction", interactions[i]:dump()})
	end
	return cfg
end


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
