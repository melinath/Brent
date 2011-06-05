--! Defines an interface for common map manipulations for wesnoth rpgs,
--! including automatic shroud loading and saving, etc.

local events = wesnoth.require "~add-ons/Brent/lua/generic/events.lua"


local maps = {}


maps.settings = {
	require_map = true,
	remember_shroud = true,
	mark_visited = true,
	mark_known = true,
	shroud_sides = {1},
}
maps.defaults = {
	turns_per_day = 6,
}


local _ = wesnoth.textdomain "wesnoth-help"
maps.schedules = {
	schedules = {
		dawn = {
			id=dawn,
			name= _ "Dawn",
			image="misc/schedule-dawn.png",
			red=-20,
			green=-20,
			sound="ambient/morning.ogg",
		},
		morning = {
			id=morning,
			name= _ "Morning",
			image="misc/schedule-morning.png",
			lawful_bonus=25
		},
		afternoon = {
			id=afternoon,
			name= _ "Afternoon",
			image="misc/schedule-afternoon.png",
			lawful_bonus=25
		},
		dusk = {
			id=dusk,
			name= _ "Dusk",
			image="misc/schedule-dusk.png",
			green=-20,
			blue=-20,
			sound="ambient/night.ogg",
		},
		first_watch = {
			id=first_watch,
			name= _ "First Watch",
			image="misc/schedule-firstwatch.png",
			lawful_bonus=-25,
			red=-45,
			green=-35,
			blue=-10,
		},
		second_watch = {
			id=second_watch,
			name= _ "Second Watch",
			image="misc/schedule-secondwatch.png",
			lawful_bonus=-25,
			red=-45,
			green=-35,
			blue=-10
		},
		indoors = {
			id=indoors,
			name= _ "Indoors",
			image="misc/schedule-indoors.png",
			lighter=indoors_illum,
			{
				"illuminated_time", {
					id=indoors_illum,
					name= _ "Indoors",
					image="misc/schedule-indoors.png",
					lawful_bonus=25
				}
			}
		},
		underground = {
			id=underground,
			name= _ "Underground",
			image="misc/schedule-underground.png",
			lawful_bonus=-25,
			red=-45,
			green=-35,
			blue=-10,
			{
				"illuminated_time", {
					id=underground_illum,
					name= _ "Underground",
					image="misc/schedule-underground-illum.png",
				}
			}
		},
		deep_underground = {
			id=deep_underground,
			name= _ "Deep Underground",
			image="misc/schedule-underground.png",
			lawful_bonus=-30,
			red=-40,
			green=-45,
			blue=-15,
			{
				"illuminated_time", {
					id=deep_underground_illum,
					name= _ "Deep Underground",
					image="misc/schedule-underground-illum.png"
				}
			}
		}
	},
	from_str = function(schedule_str)
		local s = {}
		for value in string.gmatch(schedule_string, "[^%s,][^,]*") do
			table.insert(s, value)
		end
		return s
	end,
	generate = function(turns_per_day)
		local t = turns_per_day
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


--! Generic map-related functions.


maps.vars = {
	get_name = function(map_id, var)
		return string.format("maps.%s.%s", map_id, var)
	end,
	get = function(map_id, var, default)
		local v = maps.vars.get_name(map_id, var)
		return wesnoth.get_variable(v) or default
	end,
	set = function(map_id, var, value)
		local v = maps.vars.get_name(map_id, var)
		wesnoth.set_variable(v, value)
	end
}


--! A map class. For now there will only be one instance of it, located
--! at maps.current.
maps.map = events.tag:new("map", {
	id = nil,
	--map_data = nil,
	init = function(self, cfg)
		if maps.current ~= nil then error("~wml:Only one [map] tag is permitted.") end
		
		local o = self:get_parent().init(self, cfg)
		
		o.id = cfg.id
		if o.id == nil then error("~wml:[map] tag must specify an id.") end
		o.turns_per_day = cfg.turns_per_day or maps.defaults.turns_per_day
		
		if cfg.schedule == nil then
			o.schedule = maps.schedules.generate(o.turns_per_day)
		else
			o.schedule = maps.schedules.from_str(cfg.schedule)
		end
		maps.current = o
		return o
	end,
	
	set_schedule = function(self)
		local s = {}
		for i=1,#self.schedule do
			local time = maps.schedules[self.schedule[i]]
			if time ~= nil then
				table.insert(s, {"time", time})
			end
		end
		wesnoth.fire("replace_schedule", s)
	end,
	
	is_known = function(self)
		return maps.vars.get(self.id, "known")
	end,
	mark_known = function(self)
		-- Marks the map as "known"
		maps.vars.set(self.id, "known", true)
	end,
	
	is_visited = function(self)
		return maps.vars.get(self.id, "visited")
	end,
	mark_visited = function(self)
		-- Marks the map as "visited"
		maps.vars.set(self.id, "visited", true)
	end,
	
	load_shroud = function(self)
		if maps.settings.remember_shroud then
			for i, side in ipairs(map.settings) do
				local var = string.format("shroud%d", side)
				local data = maps.vars.get(self.id, var)
				if data ~= nil then wesnoth.fire("set_shroud", {side=side, shroud_data=data}) end
			end
		end
	end,
	save_shroud = function(self)
		if maps.settings.remember_shroud then
			for i, side in ipairs(map.settings.shroud_sides) do
				local var = maps.vars.get_name(self.id, string.format("shroud%d", side))
				wesnoth.fire("store_shroud", {side=side, variable=var})
			end
		end
	end,
})


--! Event registrations
events.register(function()
	local map = maps.current
	if map then
		if maps.settings.mark_visited then map:mark_visited() end
		if maps.settings.mark_known then map:mark_known() end
		if maps.settings.remember_shroud then map:load_shroud() end
	end
end, "prestart")
events.register(function()
	local map = maps.current
	if map then
		if maps.settings.remember_shroud then map:save_shroud() end
	end
end, "victory", "defeat")


return maps