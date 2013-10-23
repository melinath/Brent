local helper = wesnoth.require("lua/helper.lua")

local events = modular.require("events")
local interface = modular.require("interface")
local markup = modular.require("markup")
local scenario = modular.require("scenario")
local utils = modular.require("utils")

local _ = wesnoth.textdomain("wesnoth-Brent")


--! Base class and functions for dealing with cross-scenario objectives.
local quests = {}


-- List of quest instances.
quests.quests = {}


quests.quest = utils.class:subclass({
	--! The base class for quests. In general, this should just be
	--! instantiated, not subclassed.

	
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
	--! Default: Wesnoth icon.
	portrait = "portraits/bfw-logo.png",
	
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
	
	init = function(cls, cfg)
		local instance = utils.class.init(cls, cfg)
		instance.status = instance:get_status()
		table.insert(quests.quests, instance)
		return instance
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
		--! completed. By default, fires off a print.
		wesnoth.fire("print", {
			text = markup.concat(_("Quest completed: "), self.name),
			green = 255,
			size = 20,
			duration = 200
		})
	end,
	
	on_failure = function(self)
		--! Hook to run code (such as punishments) when a quest is failed. By
		--! default, fires off a print.
		wesnoth.fire("print", {
			text = markup.concat(_("Quest failed: "), self.name),
			red = 255,
			size = 20,
			duration = 200
		})
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
		--! the events framework. By default, if the quest is active, runs the 
		--! registration of events for all of the quest's incomplete objectives.
		for i, objective in ipairs(self.success_objectives) do
			objective:register_events(self)
		end
		for i, objectives in ipairs(self.failure_objectives) do
			objective:register_events(self)
		end
	end,
})


--! Quest tag
scenario.tag:subclass({
	name = "quest",
	persist = true,
	init = function(cls, cfg)
		local instance = scenario.tag.init(cls, cfg)
		--! The quest tag expects a single variable in its cfg: ``path``,
		--! which is the shortened path to the quest. For example, a path
		--! of "faeries/0" would translate to loading a quest at
		--! "~add-ons/Brent/lua/quests/faeries/0.lua".
		local path = "quests/" .. instance.wml.path
		local quest = modular.require(path, "Brent")
		quest:register_events()
		return instance
	end
})


--! Add the "Quest Log" menu item.
events.register("prestart", function()
	wesnoth.fire("set_menu_item", {
		id="Quest Log",
		description = _("Quest Log"),
		{"command", {{"lua", {code=[[
			local quests = modular.require("quests", "Brent")
			quests.display()
		]]}}}}
	})
end)


quests.display = function()
	--! Displays a menu which allows the user to choose quests and view their
	--! objectives.
	if #quests.quests == 0 then
		interface.message("portraits/story/journal.png", _("There are no active quests."))
		return
	end

	local options = {}
	
	for i, quest in ipairs(quests.quests) do
		local name = quest.name
		if quest.status == 'completed' then
			name = markup.concat(name, " (", _("Complete"), ")")
		elseif quest.status == 'failed' then
			name = markup.concat(name, " (", _("Failed"), ")")
		end
		table.insert(options, {name, function() quest:display_objectives() end})
	end

	local menu = interface.menu:init({
		title = _("Quest Log"),
		image = "portraits/story/journal.png",
		options = options
	})
	menu:display()
end


return quests
