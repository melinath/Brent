local interface = modular.require "interface"

local centers = modular.require("centers", "Brent")


local quest_list = {
	fetch_water_sprites = modular.require("quests/faeries/fetch_water_sprites", "Brent")
}


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
			interface.message(nil, "This sure is a big tree!", unit.id)
			self:show_leader()
			interface.message(nil, "Ah, it's good to find a human who appreciates nature.", self.ylliana.id)
			interface.message(nil, "Whoa!", unit.id)
			interface.message(nil, "<i>Ylliana laughs</i>", self.ylliana.id)
		else
			self:show_leader()
			interface.message(nil, "Hello, mortal.", self.ylliana.id)
		end

		wesnoth.extract_unit(self.ylliana)

		centers.center.on_match(self)
	end,
})

return center
