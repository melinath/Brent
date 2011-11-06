local quests = modular.require("quests/quests", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local kill_count_objective = quests.objectives.kill_count:new({
	description = _("Kill 5 Forest Beasts"),
	total_count = 5,
	filter_second = {side = 1},
	maps = {'Alden_Forest'},
})

local quest = quests.quest:new({
	id = "forest_beasts",
	name = _("Forest Beasts"),

	success_objectives = {
		kill_count_objective,
		quests.objectives.visit_location:new({
			description = _("Return to Marensdell"),
			filters = {
				World_Map = {x=52, y=39}
			},
			prerequisites = {kill_count_objective}
		})
		-- TODO:: Add objective requiring return to village by turn 24 *after* 
		-- completing the kill_count objective.
	},
	notes = {
		quests.objectives.note:new({
			description = _("Be careful!")
		})
	}
})

return quest