local interface = modular.require "interface"

local centers = modular.require("centers", "Brent")


local fetch_water_sprites = modular.require("quests/faeries/01_fetch_water_sprites", "Brent")
local faeries_reward = modular.require("quests/faeries/02_faeries_reward", "Brent")


local center = centers.center:init({
	id = "alden_forest_faeries",

	filters = {
		filter = {
			x="21,22,23",
			y="14-15,13-15,14-15",
			side=1
		}
	},

	ylliana = wesnoth.create_unit({
		type = "Faerie Dryad",
		canrecruit = true,
		name = "Ylliana",
		id = "Ylliana",
		side = 2
	}),

	show_leader = function(self)
		local leader = self.ylliana
		local x, y = wesnoth.find_vacant_tile(22, 14, leader)
		wesnoth.put_unit(x, y, leader)
		wesnoth.fire("animate_unit", {flag="recruited", {"filter", {id=leader.id}}})
	end,

	on_match = function(self)
		local c = wesnoth.current.event_context
		local unit = wesnoth.get_unit(c.x1, c.y1)

		if not self:is_visited() then
			wesnoth.scroll_to_tile(c.x1, c.y1)
			interface.message(unit, "This sure is a big tree!")
			self:show_leader()
			interface.message(self.ylliana, "Ah, it's good to find a human who appreciates nature.")
			interface.message(unit, "Whoa!")
			interface.message(self.ylliana, "<i>Ylliana laughs.</i>")
		elseif faeries_reward.status == 'active' then
			if faeries_reward:is_waiting() then
				faeries_reward:waiting()
			else
				faeries_reward:outro(self)
			end
		else
			self:show_leader()
			interface.message(self.ylliana, "Hello, human.")

			if fetch_water_sprites:is_available() then
				fetch_water_sprites:intro(unit.id, self.ylliana.id)
			end
		end

		wesnoth.extract_unit(self.ylliana)

		centers.center.on_match(self)
	end,
})

return center
