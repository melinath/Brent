local events = modular.require("events")
local maps = modular.require("maps")
local _ = wesnoth.textdomain("wesnoth-Brent")


--! Container for the base objective class and its subclasses.
objectives = {}


objectives.base = {
	--! The base class for objectives. This can be extended by calling
	--! ``objectives.base:new(cfg)``, where ``cfg`` is a table defining
	--! overriding behavior for the subclass. Instances of subclasses are meant
	--! to be used to populate a quest's objective tables.
	
	
	--! Attributes !--
	
	--! The displayed description of the objective. It must be set at some
	--! point.
	description = nil,

	--! A table of objectives which must be completed before this objective. It
	--! is up to the authors of custom objectives to honor this list when
	--! registering events.
	prerequisites = {},


	--! Methods !--
	
	new = function(cls, cfg)
		local new_cls = cfg or {}
		setmetatable(new_cls, cls)
		new_cls.__index = new_cls
		return new_cls
	end,
	
	should_display = function(self)
		--! Returns ``true`` if the objective should be displayed and ``false``
		--! otherwise. By default, returns ``true``.
		return true
	end,
	
	prerequisites_met = function(self, quest)
		--! Returns ``true`` if the objective's prerequisites have been met and
		--! ``false`` otherwise.
		for i, prerequisite in ipairs(self.prerequisites) do
			if not prerequisite:conditions_met(quest) then
				return false
			end
		end
		return true
	end,
	
	conditions_met = function(self, quest)
		--! Returns ``true`` if the objective's conditions have been met and
		--! ``false`` otherwise. By default, returns ``true``.
		return true
	end,

	get_status_text = function(self, quest)
		--! Returns some sort of text representation of the status of the
		--! objective. By default, returns "Complete" if ``self.conditions_met``
		--! returns ``true`` and an empty string otherwise.
		if self:conditions_met(quest) then
			return _("Complete")
		end
		return ""
	end,

	get_map_events = function(self, quest)
		--! A table mapping map ids to {event_name, function} tuples.
		--! If the current map matches one of the map ids, the defined
		--! functions will be registered at the given event names. The
		--! functions should be related to this objective - for
		--! example, setting up the objective, or preventing the
		--! player from continuing until the objective has been met.
		--! The special value "*" can be used to match all map ids.
		--! Events should also call ``self:on_completion(quest)`` if
		--! they complete the objective's goals.  See the kill_count
		--! objective for an example implementation.
		return {}
	end,

	_register_event = function(self, quest, event_name, func)
		events.register(event_name, function()
			if quest.status == 'active' and self:prerequisites_met(quest) and not self:conditions_met(quest) then
				func(self)
			end
		end)
	end,

	register_events = function(self, quest)
		--! This function will be run during preload to register events with
		--! the events framework. By default, registers the given map_events
		--! if and only if the conditions of the objective have *not* been met.
		if quest.status == "active" and not self:conditions_met(quest) then
			local map_events = self:get_map_events(quest)
			if maps.current ~= nil and map_events[maps.current.id] then
				for i=1, #map_events[maps.current.id] do
					local event_name, func = table.unpack(map_events[maps.current.id][i])
					self:_register_event(quest, event_name, func)
				end
			end
			if map_events["*"] then
				for i=1, #map_events["*"] do
					local event_name, func = table.unpack(map_events["*"][i])
					self:_register_event(quest, event_name, func)
				end
			end
		end
	end,

	on_completion = function(self, quest)
		--! Hook which should be run when the objective is considered
		--! completed. By default, displays a message and calls
		--! ``quest:objective_completed(self)``.
		wesnoth.fire("print", {
			green = 255,
			text = markup.concat(_("Objective completed: "), self.description),
			size = 20,
			duration = 200
		})
		quest:objective_completed(self)
	end,
}
objectives.base.__index = objectives.base


--! Base class for notes. Always return ``false`` for conditions_met.
objectives.note = objectives.base:new({
	conditions_met = function(self, quest) return false end
})


--! Base class for objectives which involve getting a certain count of things.
objectives.count = objectives.base:new({
	--! The total count which must be reached to satisfy the objective.
	total_count = nil,
	
	--! Wesnoth variable which is used to store the count for this objective.
	variable_name = nil,
	
	--! Integer by which to increment the count.
	increment_by = 1,

	get_count = function(self, quest)
		--! Returns the current count for this objective, as stored in the
		--! quest's variables as ``self.variable_name``. This may be higher
		--! than the total count.
		return quest:get_var(self.variable_name) or 0
	end,

	increment = function(self, quest)
		local count = self:get_count(quest)
		quest:set_var(self.variable_name, count + self.increment_by)
	end,
	
	conditions_met = function(self, quest)
		return self:get_count(quest) >= self.total_count
	end,
	
	get_status_text = function(self, quest)
		if self.total_count == 1 then
			return quest.objectives.base.get_status_text(self, quest)
		else
			local current_count = math.min(self:get_count(quest), self.total_count)
			return string.format("%d/%d", current_count, self.total_count)
		end
	end,
})


--! Base class for quests which involve killing a certain number of things.
objectives.kill_count = objectives.count:new({
	variable_name = 'kill_count',

	--! Mapping of map IDs to filters for the kill event. The filters which can be
	--! provided are SUF keyed in as "filter" and "filter_second". The special string
	--! "*" can be used to match all map IDs.
	--!
	--! Example: map_filters = {["*"] = {filter = {side = 1}}}
	map_filters = {},

	get_map_events = function(self, quest)
		local map_events = {}
		for map_id, filters in ipairs(self.map_filters) do
			map_events[map_id] = {{"die", function()
				local filter, filter_second = filters["filter"], filters["filter_second"]
				local c = wesnoth.current.event_context
				local should_increment = true
				if filter ~= nil then
					local unit = wesnoth.get_unit(c.x1, c.y1)
					if not wesnoth.match_unit(unit, filter) then
						should_increment = false
					end
				end
				if should_increment and filter_second ~= nil then
					local second_unit = wesnoth.get_unit(c.x2, c.y2)
					if not wesnoth.match_unit(second_unit,
											  filter_second) then
						should_increment = false
					end
				end
				if should_increment then
					self:increment(quest)
				end
				if self:conditions_met(quest) then
					self:on_completion(quest)
				end
			end}}
		end
		return map_events
	end,
})


--! Base class for objectives which involve going to a location on a certain
--! map.
objectives.visit_location = objectives.base:new({
	variable_name = 'location_visited',
	--! Mapping of map IDs to filters for the moveto event. "filter" (an SUF)
	--! and "filter_location" are currently supported. The special string "*"
	--! can be used to match all map IDs.
	--!
	--! Example: map_filters = {"*" = {"filter" = {"side" = 1}}}
	map_filters = {},

	conditions_met = function(self, quest)
		return quest:get_var(self.variable_name)
	end,

	mark_visited = function(self, quest)
		quest:set_var(self.variable_name, true)
	end,

	get_map_events = function(self, quest)
		local map_events = {}
		for map_id, filters in ipairs(self.map_filters) do
			map_events[map_id] = {{"moveto", function()
				local c = wesnoth.current.event_context
				local filter, filter_location = filters["filter"], filters["filter_location"]
				local matched = true
				if filter_location ~= nil then
					if not wesnoth.match_location(c.x1, c.x2, filter_location) then
						matched = false
					end
				end
				if filter ~= nil then
					local unit = wesnoth.get_unit(c.x1, c.y1)
					if not wesnoth.match_unit(unit, filter) then
						matched = false
					end
				end
				if matched then
					self:mark_visited(quest)
					self:on_completion(quest)
				end
			end}}
		end
		return map_events
	end,
})

return objectives