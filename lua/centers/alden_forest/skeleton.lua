local items = wesnoth.require "lua/wml/items.lua"

local interface = modular.require "interface"

local centers = modular.require("centers", "Brent")

local return_bones = modular.require("quests/skeleton_note/01_return_bones", "Brent")

local center_x, center_y = 17, 24

local center = centers.center:init({
	id = "alden_forest_skeleton_note",

	filters = {
		filter = {
			x=center_x,
			y=center_y,
			side=1
		}
	},

	setup = function(self)
		items.remove(center_x, center_y)
		local image
		if return_bones:is_available() then
			image = "items/knapsack_bones.png"
		else
			image = "items/knapsack.png"
		end
		items.place_image(center_x, center_y, image)
	end,

	on_match = function(self)
		if return_bones:is_available() then
			return_bones:intro()
		end
		centers.center.on_match(self)
	end,
})

return center
