local quests = modular.require("quests/quests", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local quest = quests.quest:new({
	id = "forest_beasts",

	success_objectives = {
		quests.objectives.kill_count:new({
			total_count = 5,
			filter = {side = 1},
			maps = {'Alden_Forest'},
			description = _("Kill 5 Forest Beasts")
		})
	},
})

return quest