local helper = wesnoth.require("lua/helper.lua")
local interface = modular.require("interface")
local markup = modular.require("markup")
local events = modular.require("events")
local maps = modular.require("maps")
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
		if quest:is_active() then
			table.insert(quest_choices, quest.name)
			table.insert(quest_list, quest)
		end
	end
	if #quest_choices == 0 then
		interface.message(_("There are no active quests."))
		return
	end
	local choice = helper.get_user_choice({message=_("Active quests:")}, quest_choices)
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
	
	--! The [\w+] id of the quest. This will be used as a variable container
	--! for holding quest variables. Must be defined by subclasses.
	id = nil,
	
	--! The portrait to be used when displaying information about the quest.
	--! Default: The wesnoth logo.
	portrait = 'wesnoth-icon.png',
	
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
	
	
	--! Methods !--
	
	new = function(cls, cfg)
		local new_cls = cfg or {}
		setmetatable(new_cls, cls)
		new_cls.__index = new_cls
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
		interface.message(self.portrait, self:build_objective_string())
	end,
	
	build_objective_string = function(self)
		--! Builds and returns a completely marked-up and translated string for
		--! this quest's objectives.
		local success_string = self:_build_objective_list_string(self.success_objectives, 0, 255, 0)
		local failure_string = self:_build_objective_list_string(self.failure_objectives, 255, 0, 0)
		local note_string = self:_build_objective_list_string(self.notes, 255, 255, 255)
		
		local objective_string = markup.concat(markup.big(self.name), "\n")
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
	
	is_active = function(self)
		--! Returns ``true`` if this quest is considered "active" i.e. ongoing
		--! and ``false`` otherwise. By default, a quest is considered "active"
		--! if at least one of the ``self.success_objectives`` returns ``false``
		--! from ``conditions_met`` and none of the ``self.failure_objectives``
		--! return ``true`` from ``conditions_met``.
		local active = false
		for i, objective in ipairs(self.success_objectives) do
			if not objective:conditions_met(self) then
				active = true
				break
			end
		end
		if active then
			for i, objective in ipairs(self.failure_objectives) do
				if objective:conditions_met(self) then
					active = false
					break
				end
			end
		end
		return active
	end,

	register_events = function(self)
		--! This function will be run during preload to register events with
		--! the events framework. By default, runs the registration of events
		--! for all of the quest's objectives.
		for i, objective in ipairs(self.success_objectives) do
			objective:register_events(self)
		end
		for i, objectives in ipairs(self.failure_objectives) do
			objective:register_events(self)
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
		--! the events framework. By default, does nothing.
	end,
}
quests.objectives.base.__index = quests.objectives.base


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
				-- Only increment the kill count 
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
					if not wesnoth.match_unit(second_unit, self.filter_second) then
						should_increment = false
					end
				end
				if should_increment then
					self:increment(quest)
				end
			end)
		end
	end,
})


--! Add the "Quest Objectives" menu item.
events.register("prestart", function()
	-- Add the quests menu item
	menu_item = {
		id="Quest Objectives",
		description = _ "Display Quest Objectives",
		{"command", {{"lua", {code=[[
			local quests = modular.require("quests/quests", "Brent")
			quests.display()
		]]}}}}
	}
	wesnoth.fire("set_menu_item", menu_item)
end)


return quests
