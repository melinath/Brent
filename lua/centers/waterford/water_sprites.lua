local interface = modular.require "interface"

local centers = modular.require("centers", "Brent")


local fetch_water_sprites = modular.require("quests/faeries/01_fetch_water_sprites", "Brent")
local faeries_reward = modular.require("quests/faeries/02_faeries_reward", "Brent")


local center = centers.center:init({
	id = "waterford_water_sprites",
	filters = {
		filter = {
			side = 1,
			{"filter_adjacent", {
				count = 1,
				canrecruit = true,
				side = 2,
			}},
		}
	},

	lyra = wesnoth.create_unit({
		type = "Water_Shyde",
		name = "Lyra",
		id = "Lyra",
		canrecruit = true,
		side = 2
	}),

	lellanila = wesnoth.create_unit({
		type = "Undine",
		name = "Lellanila",
		id = "Lellanila",
		canrecruit=true,
		side = 2
	}),

	setup = function(self)
		local leader = self:get_leader()
		local x, y = wesnoth.find_vacant_tile(13, 12, leader)
		wesnoth.put_unit(x, y, leader)
	end,

	get_leader = function(self)
		if fetch_water_sprites.status == 'completed' then
			return self.lellanila
		end
		return self.lyra
	end,

	on_match = function(self)
		if fetch_water_sprites.status == "active" then
			fetch_water_sprites:outro(self.lyra, self.lellanila)
		else
			local leader = self:get_leader()
			interface.message(nil, "You have no business here. Please leave.", leader.id)
		end
	end,
})
