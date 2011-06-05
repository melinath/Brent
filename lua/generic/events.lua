--! A module which allows simple, efficient registration of new scenario-level
--! tags and new event handlers.
local game_events = wesnoth.game_events
local helper = wesnoth.require "lua/helper.lua"


local events = {}

--! Scenario-level tag handling
events.tags = {}
events.tag = {
	new = function(self, name, cfg)
		local cls = cfg or {}
		cls.__index = cls
		setmetatable(cls, self)
		cls.instances = {}
		events.tags[name] = cls
		wesnoth.register_wml_action(name, function(cfg) cls:init(cfg) end)
		return cls
	end,
	init = function(cls, cfg)
		local obj = {}
		setmetatable(obj, cls)
		table.insert(cls.instances, obj)
		obj.cfg = cfg
		return obj
	end,
	get_parent = function(self)
		return getmetatable(self)
	end,
	dump = function(self)
		return self.cfg
	end
}
events.tag.__index = events.tag


local old_on_load = game_events.on_load
function game_events.on_load(cfg)
	for i=#cfg,1,-1 do
		local tag = cfg[i]
		for name, cls in pairs(events.tags) do
			if name == tag[1] then
				cls:init(tag[2])
				break
			end
		end
	end
end

local old_on_save = game_events.on_save
function game_events.on_save()
	cfg = old_on_save()
	for name, cls in pairs(events.tags) do
		for i=1,#cls.instances do
			table.insert(cfg, {name, cls.instances[i]:dump()})
		end
	end
	return cfg
end


--! Event handling
events.events = {}
function events.register(func, ...)
	for i, name in ipairs(arg) do
		if events.events[name] == nil then events.events[name] = {} end
		table.insert(events.events[name], func)
	end
end

local old_on_event = game_events.on_event
function game_events.on_event(name)
	local funcs = events.events[name]
	if funcs ~= nil then
		for i,f in ipairs(funcs) do
			f()
		end
	end
	if old_on_event ~= nil then old_on_event(name) end
end


events.register(function()
	-- At the end of the scenario, save tags that should persist.
	for name, cls in pairs(events.tags) do
		if cls.persist then
			local arr = {}
			for i=1,#cls.instances do
				table.insert(arr, cls.instances[i]:dump())
			end
			helper.set_variable_array(name, arr)
		end
	end
end, "victory", "defeat")

events.register(function()
	-- When the scenario starts, load tags that have persisted.
	for name, cls in pairs(events.tags) do
		if cls.persist then
			local arr = helper.get_variable_array("name")
			for i=1,#arr do
				quest:init(arr[i])
			end
		end
	end
end, "prestart")