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
			prerequisites = {kill_count_objective}
		})
	},
	notes = {
		objectives.note:new({
			description = _("Be careful!")
		})
	}
})

return quest