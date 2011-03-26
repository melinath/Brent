local helper = wesnoth.require "lua/helper.lua"
local game_events = wesnoth.game_events


--! Quest center class
local quest_center = {
	new = function(self, id)
			if type(id) == "string" and id ~= "base" then
				filename = string.format("~add-ons/Brent/lua/quests/quest_centers/%s.lua", id)
				success, o = pcall(wesnoth.require, filename)
				if success ~= true then o = {} end
			else
				o = {}
			end
			setmetatable(o, self)
			self.__index = self
			return o
		end,
	
	setup = function(self, cfg)
			self.cfg = cfg
			local filter = helper.get_child(cfg, "filter")
			if (filter == nil) then error("~wml:[quest_center] expects a [filter] child", 0) end
			if (cfg.id == nil) then error("~wml:[quest_center] must declare an id", 0) end
			self.filter = helper.literal(filter)
			self.id = cfg.id
			
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
					self:activate(u)
				end
			end
		end,
	activate = function(self, unit)
			wesnoth.message(string.format("You've stepped on me! You are at %d, %d", unit.x, unit.y))
		end,
	
	dump = function(self)
			return self.cfg
		end,
	
	cfg = nil,
	filter = nil,
	id = nil,
}
return quest_center