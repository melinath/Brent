local interface = modular.require "interface"
local units = modular.require "units"
local maps = modular.require "maps"
local quests = modular.require("quests/quests", "Brent")
local objectives = modular.require("quests/objectives", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local kill_forest_beasts = objectives.kill_count:init({
	description = _("Kill 5 Forest Beasts"),
	total_count = 5,
	map_filters = {Alden_Forest = {filter_second = {side = 1}}},
	register_events = function(self, quest)
		objectives.kill_count.register_events(self, quest)
		if maps.current and maps.current.id == "Alden_Forest" and not self:conditions_met(quest) then
			local objective = self
			maps.add_exit_handler("World_Map", "cancel", maps.exit_handler:init({
				matches = function(self)
					return self.class.matches(self) and not objective:conditions_met(quest)
				end,
				on_match = function(self)
					local unit = wesnoth.get_units({side=1, canrecruit=true})[1]
					interface.message(nil,
						  			  "Hmm...I can't go back yet. I have to catch more game.",
									  unit.id)
				end,
			}))
			maps.add_exit_handler("Faerie_Battlefield", "cancel", maps.exit_handler.init({
				on_match = function(self)
					local unit = wesnoth.get_units({side=1, canrecruit=true})[1]
					interface.message(nil,
									  "I shouldn't go too far into the forest right now. Maybe another day.",
									  unit.id)
				end,
			}))
		end
	end,
})

local return_to_marensdell = objectives.visit_location:init({
	description = _("Return to Marensdell"),
	map_filters = {
		World_Map = {filter = {x=52, y=39}}
	},
	prerequisites = {kill_forest_beasts},
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

local quest = quests.quest:init({
	id = "forest_beasts",
	name = _("Forest Beasts"),
	description = _("You're to hunt for food in Alden Forest, then return with the slain beasts to the village of Marensdell."),

	success_objectives = {
		kill_forest_beasts,
		return_to_marensdell,
	},
	notes = {
		objectives.note:init({
			description = _("Be careful!")
		})
	}
})

return quest