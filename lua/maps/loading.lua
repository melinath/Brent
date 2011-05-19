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
		self.schedule = cfg.schedule
		self:set_schedule()
	end,
	dump = function(self)
		return {
			turns_per_day = self.turns_per_day,
			id = self.id,
			schedule = self.schedule
		}
	end,
	get_timedelta = function(self)
		-- timedelta is the local time change per turn
		return 24/self.turns_per_day
	end,
	
	set_schedule = function(self)
		local schedule_string = self.schedule
		local s = {}
		if schedule_string == nil then
			s = self:make_schedule()
		else
			for value in string.gmatch(schedule_string, "[^%s,][^,]*") do
				table.insert(s, value)
			end
		end
		local schedule = {}
		for i=1,#s do
			local new = map_utils.schedules[s[i]]
			if new ~= nil then
				if new.illuminated ~= nil then
					table.insert(schedule, {"illuminated_time", new.illuminated})
					table.remove(new, "illuminated")
				end
				table.insert(schedule, {"time", new})
			end
		end
		wesnoth.fire("replace_schedule", schedule)
	end,
	
	make_schedule = function(self)
		local t = self.turns_per_day
		local s = {}
		for i=1,t do
			if i < t/6 then
				table.insert(s, "dawn")
			elseif i < 2*t/6 then
				table.insert(s, "morning")
			elseif i < 3*t/6 then
				table.insert(s, "afternoon")
			elseif i < 4*t/6 then
				table.insert(s, "dusk")
			elseif i < 5*t/6 then
				table.insert(s, "first_watch")
			else
				table.insert(s, "second_watch")
			end
		end
		return s
	end
}

interactions = {}

--! Interaction base class
local interaction = {
	new = function(self, cfg)
			local o = cfg or {}
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
		if name == "moveto" then
			local c = wesnoth.current.event_context
			local u = wesnoth.get_unit(c.x1, c.y1)
			if u ~= nil and wesnoth.match_unit(u, self.filter) then
				wesnoth.fire("store_unit", {{"filter", {id=u.id}}, variable="unit", kill=false})
				wesnoth.set_variable("x1", c.x1)
				wesnoth.set_variable("x2", c.x2)
				wesnoth.set_variable("y1", c.y1)
				wesnoth.set_variable("y2", c.y2)
				for i=1,#self.command do
					local v = self.command[i]
					wesnoth.fire(v[1], v[2])
				end
				wesnoth.set_variable("unit")
				wesnoth.set_variable("x1")
				wesnoth.set_variable("x2")
				wesnoth.set_variable("y1")
				wesnoth.set_variable("y2")
			end
		elseif name == "prestart" and self.image and self.x and self.y then
			items.place_image(self.x, self.y, self.image)
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

exits = {}
exit_cancelers = {}

--! Exit base class
local exit = {
	new = function(self, cfg)
		local o = cfg or {}
		setmetatable(o, self)
		self.__index = self
		table.insert(exits, o)
		return o
	end,
	setup = function(self, cfg)
		self.cfg = cfg
		local filter = helper.get_child(cfg, "filter")
		if filter == nil then error("~wml:[exit] expects a [filter] child", 0) end
		self.filter = helper.literal(filter)
		self.start_x = cfg.start_x
		self.start_y = cfg.start_y
		self.scenario = cfg.scenario
	end,
	dump = function(self)
		return self.cfg
	end,
	is_active = function(self)
		local c = wesnoth.current.event_context
		local u = wesnoth.get_unit(c.x1, c.y1)
		return wesnoth.match_unit(u, self.filter)
	end,
	activate = function(self)
		local c = wesnoth.current.event_context
		wesnoth.set_variable("start_x", self.start_x)
		wesnoth.set_variable("start_y", self.start_y)
		wesnoth.fire_event("exit", c.x1, c.y1, c.x2, c.y2)
		local e = {
			name = "victory",
			save = true,
			carryover_report = false,
			carryover_percentage = 100,
			linger_mode = false,
			bonus = false,
			next_scenario = self.scenario
		}
		wesnoth.fire("endlevel", e)
	end
}

--! Exit canceler base class
local exit_canceler = {
	new = function(self, cfg)
		local o = cfg or {}
		setmetatable(o, self)
		self.__index = self
		table.insert(exit_cancelers, o)
		return o
	end,
	setup = function(self, cfg)
		self.cfg = cfg
		local filter = helper.get_child(cfg, "filter")
		if filter == nil then error("~wml:[cancel_exit] expects a [filter] child", 0) end
		self.filter = helper.literal(filter)
		
		local cancel_if = helper.get_child(cfg, "cancel_if")
		if cancel_if ~= nil then
			local lua = helper.get_child(cancel_if, "lua")
			if lua ~= nil then
				self.should_cancel = loadstring(lua.code)
			end
		end
		self.cancel_if = helper.literal(cancel_if)
		
		self.command = helper.get_child(cfg, "command")
	end,
	should_cancel = function(self)
		local c = wesnoth.current.event_context
		local u = wesnoth.get_unit(c.x1, c.y1)
		
		if not wesnoth.match_unit(u, self.filter) then return false end
		if self.cancel_if == nil then return true end
		
		local lua = helper.get_child(self.cancel_if, "lua")
		if lua ~= nil then
			return loadstring(lua.code)()
		end
		return wesnoth.eval_conditional(self.cancel_if)
	end,
	run_commands = function(self)
		if self.command ~= nil then
			for i=1,#self.command do
				local v = self.command[i]
				wesnoth.fire(v[1], v[2])
			end
		end
	end,
	dump = function(self)
		return self.cfg
	end,
}


local function cancel_exit(cfg)
	local exit_canceler = exit_canceler:new()
	exit_canceler:setup(cfg)
end
wesnoth.register_wml_action("cancel_exit", cancel_exit)


local old_on_load = game_events.on_load
function game_events.on_load(cfg)
	for i=#cfg,1,-1 do
		local v = cfg[i]
		local v2 = v[2]
		if v[1] == "map" then
			map:config(v2)
			table.remove(cfg, i)
		elseif v[1] == "interaction" then
			local interaction = interaction:new()
			interaction:setup(v2)
			table.remove(cfg, i)
		elseif v[1] == "exit" then
			local exit = exit:new()
			exit:setup(v2)
			table.remove(cfg, i)
		elseif v[1] == "cancel_exit" then
			cancel_exit(v2)
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
	for i=1, #exits do
		table.insert(cfg, {"exit", exits[i]:dump()})
	end
	for i=1,#exit_cancelers do
		table.insert(cfg, {"exit", exit_cancelers[i]:dump()})
	end
	return cfg
end


local old_on_event = game_events.on_event
function game_events.on_event(name)
	if map.id ~= nil then
		if name == "prestart" then
			map_utils.mark_visited(map.id)
			map_utils.mark_known(map.id)
			map_utils.load_shroud(map.id)
			-- Set starting position.
			local start_x = wesnoth.get_variable("start_x")
			local start_y = wesnoth.get_variable("start_y")
			local main_id = wesnoth.get_variable("main.id")
			if start_x ~= nil and start_y ~= nil and main_id ~= nil then
				local unit = wesnoth.get_units{id=main_id}[1]
				wesnoth.put_unit(start_x, start_y, unit)
				wesnoth.scroll_to_tile(start_x, start_y)
				wesnoth.set_variable("start_x", nil)
				wesnoth.set_variable("start_y", nil)
			end
			-- Storyboard messages
			local msgs = helper.get_variable_array("story_message")
			for i=1,#msgs do
				wesnoth.fire("narrate", msgs[i])
			end
			wesnoth.set_variable "story_message"
		elseif name == "victory" or name == "defeat" then
			map_utils.store_shroud(map.id)
		elseif name == "moveto" then
			for i=1,#exits do
				if exits[i]:is_active() then
					local activate = true
					for j=1, #exit_cancelers do
						if exit_cancelers[j]:should_cancel() then
							activate = false
							exit_cancelers[j]:run_commands()
							break
						end
					end
					if activate then exits[i]:activate() end
				end
			end
		end
	end
	if old_on_event ~= nil then old_on_event(name) end
end
