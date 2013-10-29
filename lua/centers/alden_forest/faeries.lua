local interface = modular.require "interface"

local centers = modular.require("centers", "Brent")


local fetch_water_sprites = modular.require("quests/faeries/01_fetch_water_sprites", "Brent")


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

		local function unit_message(msg) interface.message(nil, msg, unit.id) end
		local function leader_message(msg) interface.message(nil, msg, self.ylliana.id) end

		if not self:is_visited() then
			wesnoth.scroll_to_tile(c.x1, c.y1)
			unit_message("This sure is a big tree!")
			self:show_leader()
			leader_message("Ah, it's good to find a human who appreciates nature.")
			unit_message("Whoa!")
			leader_message("<i>Ylliana laughs.</i>")
		else
			self:show_leader()
			leader_message("Hello, human.")
		end

		if fetch_water_sprites:is_available() then
			fetch_water_sprites:intro(unit.id, self.ylliana.id)
		end

		wesnoth.extract_unit(self.ylliana)

		centers.center.on_match(self)
	end,
})

return center
