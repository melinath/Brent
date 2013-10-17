local interface = modular.require "interface"
local units = modular.require "units"
local quests = modular.require("quests/quests", "Brent")
local objectives = modular.require("quests/objectives", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local kill_count_objective = objectives.kill_count:new({
	description = _("Kill 5 Forest Beasts"),
	total_count = 5,
	filter_second = {side = 1},
	maps = {'Alden_Forest'},
})

local quest = quests.quest:new({
	id = "forest_beasts",
	name = _("Forest Beasts"),
	description = _("You're to hunt for food in Alden Forest, then return with the slain beasts to the village of Marensdell."),

	success_objectives = {
		kill_count_objective,
		objectives.visit_location:new({
			description = _("Return to Marensdell"),
			filters = {
				World_Map = {x=52, y=39}
			},
			prerequisites = {kill_count_objective},
			on_completion = function(self, quest)
				local c = wesnoth.current.event_context
				-- We already know that the triggering unit matched the filter.
				local unit = wesnoth.get_unit(c.x1, c.y1)
				local pronouns = units.get_pronouns(unit)
				interface.message(string.format("%s's mother was glad %s made it back all right, but a restlessness had grown within %s.", unit.name, pronouns.nom, pronouns.acc))
				interface.message(unit.__cfg.profile, string.format("%s had barely gotten home when %s decided to head out and explore the world.", pronouns.nom:gsub("^%l", string.upper), pronouns.nom))
				objectives.visit_location.on_completion(self, quest)
			end
		})
	},
	notes = {
		objectives.note:new({
			description = _("Be careful!")
		})
	}
})

return quest