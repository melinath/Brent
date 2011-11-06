local helper = wesnoth.require("lua/helper.lua")
local interface = modular.require("interface")
local markup = modular.require("markup")
local events = modular.require("events")
local maps = modular.require("maps")
local markup = modular.require("markup")
local _ = wesnoth.textdomain("wesnoth-Brent")


--! Base class and functions for dealing with cross-scenario objectives.
local quests = {}


quests.display = function()
	--! Displays a menu which allows the user to choose quests and view their
	--! objectives.
	local quest_choices = {}
	local quest_list = {}
	
	for i, quest_tag in ipairs(events.tags["quest"].instances) do
		local quest = quest_tag.quest
		local name = quest.name
		if quest.status == 'completed' then
			name = markup.concat(name, " (", _("Complete"), ")")
		elseif quest.status == 'failed' then
			name = markup.concat(name, " (", _("Failed"), ")")
		end
		table.insert(quest_choices, name)
		table.insert(quest_list, quest)
	end
	if #quest_choices == 0 then
		interface.message(_("There are no active quests."))
		return
	end
	local choice = helper.get_user_choice(
		{
			speaker = 'narrator',
			caption = _("Quest Log"),
			image = "portraits/story/journal.png"
		},
		quest_choices
	)
	quest_list[choice]:display_objectives()
end


quests.quest_tag = events.tag:new("quest", {
	persist = true,

	init = function(cls, cfg)
		--! The quest tag expects a single variable in its cfg: ``path``,
		--! which is the shortened path to the quest. For example, a path
		--! of "faeries/0" would translate to loading a quest at
		--! "~add-ons/Brent/lua/quests/faeries/0.lua".
		local obj = cls:get_parent().init(cls, cfg)
		obj.path = "quests/" .. cfg.path
		obj.quest = modular.dofile(obj.path, "Brent")
		obj.quest:register_events()
		return obj
	end
})


quests.quest = {
	--! The base class for quests. This should be extended by calling
	--! ``quests.quest:new(cfg)``, where ``cfg`` is a table defining overriding
	--! behavior for the subclass.
	
	
	--! Attributes !--
	
	--! The displayed name of the quest. Must be defined by subclasses.
	name = nil,

	--! A longer description of the quest, describing (for example) who
	--! originally assigned the quest.
	description = nil,
	
	--! The [\w+] id of the quest. This will be used as a variable container
	--! for holding quest variables. Must be defined by subclasses.
	id = nil,
	
	--! The portrait to be used when displaying information about the quest.
	--! Default: no portrait.
	portrait = nil,
	
	--! A table of ``quests.objective`` instances which must be satisfied in
	--! order for the quest to be considered "complete".
	success_objectives = {},
	
	--! A table of ``quests.objective`` instances which, if triggered, will
	--! mark a quest as "failed".
	failure_objectives = {},
	
	--! A table of ``quests.objective`` instances which have no bearing on the
	--! success or failure of the quest, instead simply displaying extra
	--! information.
	notes = {},

	--! A cached value of the quest's status. This will either be ``active``,
	--! ``completed``, or ``failed``.
	status = nil,


	--! Methods !--
	
	new = function(cls, cfg)
		local new_cls = cfg or {}
		setmetatable(new_cls, cls)
		new_cls.__index = new_cls
		new_cls.status = new_cls:get_status()
		return new_cls
	end,
	
	get_var_name = function(self, key, namespace)
		if key == nil then error("key is nil; expected string.") end
		if namespace == nil then namespace = self.id end
		return string.format("quests.%s.%s", namespace, key)
	end,
	
	get_var = function(self, key, namespace)
		return wesnoth.get_variable(self:get_var_name(key, namespace))
	end,
	
	set_var = function(self, key, value, namespace)
		wesnoth.set_variable(self:get_var_name(key, namespace), value)
	end,
	
	
	display_objectives = function(self)
		wesnoth.fire("message", {
			caption = self.name,
			image = self.portrait,
			message = self:build_objective_string(),
			speaker = 'narrator'
		})
	end,
	
	build_objective_string = function(self)
		--! Builds and returns a completely marked-up and translated string for
		--! this quest's objectives.
		local success_string = self:_build_objective_list_string(self.success_objectives, 0, 255, 0)
		local failure_string = self:_build_objective_list_string(self.failure_objectives, 255, 0, 0)
		local note_string = self:_build_objective_list_string(self.notes, 255, 255, 255)
		
		local objective_string = ""
		if self.description ~= nil then 
			objective_string = markup.concat(objective_string, self.description, "\n")
		end
		if success_string ~= "" then
			objective_string = markup.concat(objective_string, markup.big(_("Success:")), "\n", success_string, "\n")
		end
		if failure_string ~= "" then
			objective_string = markup.concat(objective_string, markup.big(_("Failure:")), "\n", failure_string, "\n")
		end
		if note_string ~= "" then
			objective_string = markup.concat(objective_string, markup.big(_("Notes:")), "\n", note_string, "\n")
		end
		return tostring(objective_string)
	end,
	
	_build_objective_list_string = function(self, objective_list, r, g, b)
		--! Helper method to return a properly-formatted string for the
		--! ``objective_list``, with each entry colored using the given
		--! (r, g, b) values.
		local built_string = ""
		for i, objective in ipairs(objective_list) do
			if objective:should_display() then
				local status_text = objective:get_status_text(self)
				local objective_text = objective.description
				if status_text ~= "" then
					objective_text = markup.concat(objective_text, " (", status_text, ")")
				end
				built_string = markup.concat(built_string, markup.bullet, objective_text, "\n")
			end
		end
		if built_string ~= "" then
			built_string = markup.color(r, g, b, built_string)
		end
		return built_string
	end,
	
	on_success = function(self)
		--! Hook to run code (such as rewards) when a quest is successfully
		--! completed. By default, does nothing.
	end,
	
	on_failure = function(self)
		--! Hook to run code (such as punishments) when a quest is failed. By
		--! default, does nothing.
	end,

	objective_completed = function(self, objective)
		self.status = self:get_status()
		if self.status == 'completed' then
			self:on_success()
		elseif self.status == 'failed' then
			self:on_failure()
		end
	end,

	get_status = function(self)
		--! Returns the status of the quest. This will either be ``completed``,
		--! ``failed``, or ``active``. A quest is considered ``completed`` if
		--! all of its success objectives have been completed, ``failed`` if any
		--! of its failure objectives have been completed, and ``active``
		--! otherwise.
		local status = 'completed'
		for i, objective in ipairs(self.success_objectives) do
			if not objective:conditions_met(self) then
				status = 'active'
				break
			end
		end
		if status == 'active' then
			for i, objective in ipairs(self.failure_objectives) do
				if objective:conditions_met(self) then
					status = 'failed'
					break
				end
			end
		end
		return status
	end,

	register_events = function(self)
		--! This function will be run during preload to register events with
		--! the events framework. By default, runs the registration of events
		--! for all of the quest's incomplete objectives.
		for i, objective in ipairs(self.success_objectives) do
			if not objective:conditions_met(self) then
				objective:register_events(self)
			end
		end
		for i, objectives in ipairs(self.failure_objectives) do
			if not objective:conditions_met(self) then
				objective:register_events(self)
			end
		end
	end,
}
quests.quest.__index = quests.quest


--! Subcontainer for the base objective class and its subclasses.
quests.objectives = {}


quests.objectives.base = {
	--! The base class for objectives. This can be extended by calling
	--! ``quests.objectives.base:new(cfg)``, where ``cfg`` is a table defining
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
quests.objectives.base.__index = quests.objectives.base


--! Base class for notes. Always return ``false`` for conditions_met.
quests.objectives.note = quests.objectives.base:new({
	conditions_met = function(self, quest) return false end
})


--! Base class for objectives which involve getting a certain count of things.
quests.objectives.count = quests.objectives.base:new({
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
		local current_count = math.min(self:get_count(quest), self.total_count)
		return string.format("%d/%d", current_count, self.total_count)
	end,
})


--! Base class for quests which involve killing a certain number of things.
quests.objectives.kill_count = quests.objectives.count:new({
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
				if (self:prerequisites_met(quest) and
					not self:conditions_met(quest)) then
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
quests.objectives.visit_location = quests.objectives.base:new({
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
					if (self:prerequisites_met(quest) and
						not self:conditions_met(quest)) then
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


--! Add the "Quest Objectives" menu item.
events.register("prestart", function()
	-- Add the quests menu item
	menu_item = {
		id="Quest Log",
		description = _("Quest Log"),
		{"command", {{"lua", {code=[[
			local quests = modular.require("quests/quests", "Brent")
			quests.display()
		]]}}}}
	}
	wesnoth.fire("set_menu_item", menu_item)
end)


return quests
