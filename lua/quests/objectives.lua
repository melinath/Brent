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

	register_events = function(self, quest)
		--! This function will be run during preload to register events with
		--! the events framework. By default, does nothing. Note: it is
		--! important that the registered events only have an effect if the
		--! objective's prerequisites have been met and if the objective itself
		--! has not been completed. Events should also call
		--! ``self:on_completion(quest)`` if they complete the objective's
		--! goals.  See the kill_count objective for an example implementation.
	end,

	on_completion = function(self, quest)
		--! Hook which should be run when the objective is considered
		--! completed. By default, simply calls
		--! ``quest:objective_completed(self)``.
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
	
	--! Standard unit filter for the units which are dying, or ``nil`` for any
	--! unit.
	filter = nil,
	
	--! Standard unit filter for the units which are killing, or ``nil`` for
	--! any unit.
	filter_second = nil,
	
	--! A table of map ids for which the kill count should increment or ``nil``
	--! if it can increment on any map.
	maps = nil,
	
	register_events = function(self, quest)
		-- Only register the event if it is valid for the current map.
		local should_register = true
		if self.maps ~= nil then
			should_register = false
			if maps.current ~= nil then
				for i, map_id in ipairs(self.maps) do
					if map_id == maps.current.id then
						should_register = true
						break
					end
				end
			end
		end
		if should_register then
			events.register("die", function()
				if quest.status == 'active' and self:prerequisites_met(quest) and not self:conditions_met(quest) then
					-- Only increment the kill count if both filters match.
					local c = wesnoth.current.event_context
					local should_increment = true
					if self.filter ~= nil then
						local unit = wesnoth.get_unit(c.x1, c.y1)
						if not wesnoth.match_unit(unit, self.filter) then
							should_increment = false
						end
					end
					if should_increment and self.filter_second ~= nil then
						local second_unit = wesnoth.get_unit(c.x2, c.y2)
						if not wesnoth.match_unit(second_unit,
												  self.filter_second) then
							should_increment = false
						end
					end
					if should_increment then
						self:increment(quest)
					end
					if self:conditions_met(quest) then
						self:on_completion(quest)
					end
				end
			end)
		end
	end,
})


--! Base class for objectives which involve going to a location on a certain
--! map.
objectives.visit_location = objectives.base:new({
	--! A table mapping map ids to standard unit filters representing valid
	--! movements which would fulfill this objective.
	filters = {},

	--! Wesnoth variable which is used to track whether this location has been
	--! visited.
	variable_name = 'location_visited',

	conditions_met = function(self, quest)
		return quest:get_var(self.variable_name)
	end,

	mark_visited = function(self, quest)
		quest:set_var(self.variable_name, true)
	end,

	register_events = function(self, quest)
		if maps.current ~= nil then
			local filter = self.filters[maps.current.id]
			if filter ~= nil then
				events.register("moveto", function()
					if quest.status == 'active' and self:prerequisites_met(quest) and not self:conditions_met(quest) then
						local c = wesnoth.current.event_context
						local unit = wesnoth.get_unit(c.x1, c.y1)
						if wesnoth.match_unit(unit, filter) then
							self:mark_visited(quest)
							self:on_completion(quest)
						end
					end
				end)
			end
		end
	end,
})

return objectives