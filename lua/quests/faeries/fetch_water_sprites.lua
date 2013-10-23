local objectives = modular.require("objectives", "Brent")
local quests = modular.require("quests", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local find_water_sprites = objectives.visit_location:init({
	description = _("Find the Water Sprites by the North River"),
	map_filters = {
		Waterford = {
			side = 1,
			x = "12-14,13",
			y = "11-12,13"
		}
	}
})

local pia_dies = objectives.kill_count:init({
	description = _("Pia dies"),
	filter = {
		id = "Pia"
	},
	total_count = 1
})


local quest = quests.quest:init({
	id = "water_sprites",
	name = _("Fetch the Water Sprites"),
	image = "portraits/dryad.png",
	description = _("The battle between the forest sprites and the creatures of flame is going poorly. Escort Pia to the Northern River, by Waterford, and find the water sprites so that she can deliver her message and enlist their aid."),

	success_objectives = {
		find_water_sprites,
	},
	failure_objectives = {
		pia_dies,
	}
})

return quest