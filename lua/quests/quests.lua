local helper = wesnoth.require("lua/helper.lua")
local interface = modular.require("interface")
local markup = modular.require("markup")
local _ = wesnoth.textdomain("wesnoth-Brent")


--! Base class and functions for dealing with cross-scenario objectives.
local quests = {}


--! Global container for all loaded quests.
quests.quests = {}


quests.display = function()
	--! Displays a menu which allows the user to choose quests and view their
	--! objectives.
	local quest_choices = {}
	local quest_list = {}
	
	for i, quest in ipairs(quests.quests) do
		if quest:is_active() then
			table.insert(quest_choices, quest.name)
			table.insert(quest_list, quest)
		end
	end
	if next(quest_choices) == nil then
		interface.message(_("There are no active quests."))
		return
	end
	local choice = helper.get_user_choice({message=_("Active quests:"}, quest_choices)
	quest_list[choice]:display_objectives()
end


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
		
		local objective_string = markup.concat(m.big(self.name), "\n")
		if success_string ~= "" then
			objective_string = markup.concat(m.big(_("Success:")), "\n", success_string)
		end
		if failure_string ~= "" then
			objective_string = markup.concat(m.big(_("Failure:")), "\n", failure_string)
		end
		if note_string ~= "" then
			objective_string = markup.concat(m.big(_("Notes:")), "\n", note_string)
		end
		return tostring(objective_string)
	end,
	
	_build_objective_list_string = function(self, objective_list, r, g, b)
		--! Helper method to return a properly-formatted string for the
		--! ``objective_list``, with each entry colored using the given
		--! (r, g, b) values.
		local built_string = ""
		for i, objective in ipairs(objective_list) do
			local status_text = objective:get_status_text()
			local objective_text = objective.description
			if status_text ~= "" then
				objective_text = markup.concat(objective_text, " (", status_text, ")")
			end
			built_string = markup.concat(built_string, markup.bullet, objective_text, "\n")
		end
		return markup.color(r, g, b, built_string)
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
			if not objective:conditions_met() then
				active = true
				break
			end
		end
		if active then
			for i, objective in ipairs(self.success_objectives) do
				if objective:conditions_met() then
					active = false
					break
				end
			end
		end
		return active
	end
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
	
	--! The displayed description of the objective. This will probably be set on
	--! initialization. It must be set at some point.
	description = nil,
	
	
	--! Methods !--
	
	new = function(cls, cfg)
		local new_cls = cfg or {}
		setmetatable(new_cls, cls)
		new_cls.__index = new_cls
		return new_cls
	end,
	
	init = function(cls, description)
		local instance = {
			description = description
		}
		setmetatable(instance, cls)
		return instance
	end,
	
	should_display = function(self)
		--! Returns ``true`` if the objective should be displayed and ``false``
		--! otherwise. By default, returns ``true``.
		return true
	end,
	
	conditions_met = function(self)
		--! Returns ``true`` if the objective's conditions have been met and
		--! ``false`` otherwise. By default, returns ``true``.
		return true
	end,
	
	get_status_text = function(self)
		--! Returns some sort of text representation of the status of the
		--! objective. By default, returns "Complete" if ``self.conditions_met``
		--! returns ``true`` and an empty string otherwise.
		if self:conditions_met() then
			return _("Complete")
		end
		return ""
	end,
}
quests.objectives.base.__index = quests.objectives.base


--! Add the "Quest Objectives" menu item.
events.register(function()
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
end, "prestart")


return quests
