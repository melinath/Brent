local helper = wesnoth.require("lua/helper.lua")

local interface = modular.require("interface")

local objectives = modular.require("objectives", "Brent")
local quests = modular.require("quests", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local find_water_sprites = objectives.manual:init({
	description = _("Find the Water Sprites by the North River"),
	get_map_events = function(self, quest)
		return {
			Waterford = {
				{"moveto", function()
					local visited_town = quest:get_var("visited_town")
					if not visited_town then
						local c = wesnoth.current.event_context
						local unit = wesnoth.get_unit(c.x1, c.y1)
						if wesnoth.match_unit(unit, {side=1, x="26-31", y="19-22"}) then
							interface.message(unit, "This is a human town... we won't find the water sprites here...")
						end
					end
				end},
				{"sighted", function()
					local c = wesnoth.current.event_context
					-- primary is the unit being seen.
					-- secondary is the unit doing the seeing.
					local unit = wesnoth.get_unit(c.x1, c.y1)
					local second = wesnoth.get_unit(c.x2, c.y2)
					if wesnoth.match_unit(unit, {side=2}) and wesnoth.match_unit(second, {side=1}) then
						interface.message(second, "Over there!")
					end
				end}
			}
		}
	end,
})

local pia_dies = objectives.kill_count:init({
	description = _("Pia dies"),
	filter = {
		id = "Pia"
	},
	total_count = 1
})


local quest = quests.quest:init({
	id = "fetch_water_sprites",
	path = "faeries/01_fetch_water_sprites",
	name = _("Fetch the Water Sprites"),
	portrait = "portraits/dryad.png",
	description = _("The battle between the forest sprites and the creatures of flame is going poorly. Escort Pia to the Northern River, by Waterford, and find the water sprites so that she can deliver her message and enlist their aid."),

	success_objectives = {
		find_water_sprites,
	},
	failure_objectives = {
		pia_dies,
	},

	pia = wesnoth.create_unit({
		id = "Pia",
		type = "wisp",
		name = "Pia",
		side = 1,
		gender = "female",
		role = "helper",
	}),

	intro = function(self, speaker1, speaker2)
		-- speaker1 is the (id of the) unit taking the quest.
		-- speaker2 is the (id of the) speaker giving the quest.

		local menu
		local response = self:get_var("response")

		if response == nil then
			menu = interface.menu:init({
				speaker=speaker2,
				message="Tell me, human, would you like to help the Faeries of the Wood? We would be glad to compensate you.",
				options={
					{"Yes! What can I do for you?", function() self:offer(speaker1, speaker2) end},
					{"Well, sure, but I have to finish hunting first.", function()
						self:set_var("response", "later")
						interface.message(speaker2, "Very well. Come back when you can.")
					end},
					{"N-no. I mean, I'm honored, but I can't.", function()
						self:set_var("response", "reject")
						interface.message(speaker2, "Hmm... it seems I misjudged you. Very well, human. Perhaps we shall meet again.")
					end},
				}
			})
		elseif response == 'reject' then
			menu = interface.menu:init({
				speaker=speaker2,
				message="What do you want, human?",
				options={
					{"I want to help you.", function()
						interface.message(speaker2, "Hmm. All right.")
						self:offer()
					end},
					{"I'm just passing through.", function()
						interface.message(speaker2, "Do so.")
					end},
				}
			})
		elseif response == 'later' then
			menu = interface.menu:init({
				speaker=speaker2,
				message="Hello again, human. Are you finished with your other business?",
				options={
					{"Yes.", function()
						interface.message(speaker2, "Ah, wonderful.")
						self:offer()
					end},
					{"Not quite yet.", function()
						interface.message(speaker2, "Well, just don't take too long if you want to help. The situation is serious.")
					end},
				}
			})
		elseif response == 'too hard' then
			menu = interface.menu:init({
				speaker=speaker2,
				message= "Greetings, human. Are you feeling up to our task now?",
				options={
					{"Yes.", function()
						interface.message(speaker2, "Ah, wonderful.")
						self:offer()
					end},
					{"Not quite yet.", function()
						interface.message(speaker2, "We're not asking you to fight a yeti, you know.")
					end},
				}
			})
		end

		menu:display()
	end,

	offer = function(self, speaker1, speaker2)
		-- speaker1 is the (id of the) unit taking the quest.
		-- speaker2 is the (id of the) speaker giving the quest.

		interface.message(speaker2, "The forest is being attacked by vile creatures of flame! We need the assistence of our brethren, the water sprites.")
		interface.message(speaker2, "Unfortunately, we are bound to these trees, so we have to send wisps as our messagers. They are not especially strong, nor... the most reliable messengers.")
		interface.message(speaker2, "I'm sure that if you go along with one of our wisps, you can keep her mind on task and make sure she gets to the Northern River to contact the water sprites.")

		interface.menu:init({
			speaker=speaker2,
			message="Do you accept the quest?",
			options = {
				{"Gladly.", function()
					interface.message(speaker2, "Very well.")
					local x, y = wesnoth.find_vacant_tile(22, 14, self.pia)
					wesnoth.put_unit(x, y, self.pia)
					wesnoth.fire("animate_unit", {flag="recruited", {"filter", {id=self.pia.id}}})

					interface.message(speaker2, "This is Pia, the messenger. Fare well, human!")
					interface.message(self.pia, "Hello!")

					interface.message(speaker1, "All right! Let's get going!")

					self:start()
				end},
				{"No thanks.", function()
					self:set_var("response", "reject")
					interface.message(speaker2, "Hmm... it seems I misjudged you. Very well, human. Perhaps we shall meet again.")
				end},
				{"Gee, that sounds too hard for me right now...", function()
					self:set_var("response", "too hard")
					interface.message(speaker2, "Perhaps another time, then.")
				end},
			}
		}):display()
	end,

    outro = function(self, lyra, lellanila)
        interface.message("Pia", "Greetings, Lady Lyra. I bear tidings from Lady Ylliana of the Forest.")
        interface.message(lyra, "Greetings, wisp. What may these tidings be?")
        interface.message("Pia", "Flame spirits have once more besieged the forest. We request your help.")
        interface.message(lyra, "The friendship between our peoples is strong. We will honor your request. And this young human?")

        local hero = wesnoth.get_units({id="Brent"})[1]
        local pronouns = units.get_pronouns(hero)
        interface.message("Pia", "Ylliana chose " .. pronouns.acc .. " to guide me here.")
        interface.message(lyra, "I see... well, that's a great honor, human. No doubt she'll want to reward you. I suggest you return to her soon.")
        interface.message(lyra, "I'm certain we shall meet again, human.")

        local x, y = wesnoth.find_vacant_tile(13, 12, lellanila)
        wesnoth.put_unit(x, y, lellanila)
        wesnoth.fire("animate_unit", {flag="recruited", {"filter", {id=lellanila.id}}})

        interface.message(lyra, "Lellanila, take my place here.")
        interface.message(lellanila, "Yes, my lady.")

        interface.message(lyra, "Now, my fellow sprites – we leave at once!")

        local unit_types = {"Water_Dryad", "Water_Nymph"}
        for i=1,4 do
            local unit_type = unit_types[math.random(1, #unit_types)]
            local unit = wesnoth.create_unit({side=2, type=unit_type})
            local x, y = wesnoth.find_vacant_tile(13, 12, unit)
            wesnoth.put_unit(x, y, unit)
            wesnoth.fire("animate_unit", {flag="recruited", {"filter", {id=unit.id}}})
        end

        local unit_list = wesnoth.get_units({side=2, {"not", {id=lellanila.id}}})
        for i, unit in ipairs(unit_list) do
            helper.move_unit_fake({id=unit.id}, 24, 33)
        end
        for i, unit in ipairs(unit_list) do
            wesnoth.put_unit(unit.x, unit.y)
        end
        helper.move_unit_fake({id=lellanila.id}, 13, 12)
        find_water_sprites:mark_complete(self)
        modular.require("quests/faeries/02_faeries_reward", "Brent"):start()
    end,
})

return quest