local water_sprites_accepted = "quests.water_sprites_accepted"
local ylliana = {
	["type"] = "Faerie Dryad",
	canrecruit = true,
	name = "Ylliana",
	id = "Ylliana",
	side = 2,
	animate = true
}
local _ = wesnoth.textdomain "wesnoth-Brent"

local ylliana_message = function(msg)
	wesnoth.message(ylliana.name, _(msg))
end

local accept_water_sprites = function()
end

local postpone_water_sprites = function()
end

local reject_water_sprites = function()
	ylliana_message("Hmm... it seems I misjudged you. Very well, human. Perhaps we shall meet again.")
	wesnoth.fire("faction_shift", {id = main.id, faeries = -25})
end

local water_sprites_init = function()
	local x, y = 22, 14
	wesnoth.scroll_to_tile(x, y)
	wesnoth.message(main.name, _ "This sure is a big tree!")
	wesnoth.put_unit(x, y, ylliana)
	ylliana_message("Ah, it's good to find a human who appreciates nature.")
	wesnoth.message(main.name, _ "Whoa!")
	quest_utils.message(string.format("%s laughs.", ylliana.name))
	quest_utils.dialog(
		{
			speaker = ylliana.id,
			message = _ "Tell me, human, would you like to help the Faeries of the Wood? We would be glad to compensate you."
		},
		{
			opt = _ "Yes! What can I do for you?",
			func = accept_water_sprites
		},
		{
			opt = _ "Well, sure, but I have to finish hunting first.",
			func = postpone_water_sprites
		},
		{
			opt = _ "N-no. I mean, I'm honored, but I can't.",
			func = reject_water_sprites
		}
	)
	wesnoth.put_unit(x, y)
end

local water_sprites_quest = function()
	ylliana_message("The forest is being attacked by vile creatures of flame! We need the assistence of our brethren, the water sprites.")
	ylliana_message("Unfortunately, we are bound to these trees, so we have to send wisps as our messagers. They are not especially strong, nor... the most reliable messengers.")
	ylliana_message("I'm sure that if you go along with one of our wisps, you can keep her mind on task and make sure she gets to the Northern River to contact the water sprites.")
	quest_utils.dialog(
		{
			speaker = ylliana.id,
			message = _ "Do you accept the quest?"
		},
		{
			opt = _ "Gladly.",
			func = accept_water_sprites
		},
		{
			opt = _ "No thanks.",
			func = reject_water_sprites
		}
		{
			opt = _ "Gee, that sounds too hard for me right now...",
			func = postpone_water_sprites
		}
	)
end

if not wesnoth.get_variable(water_sprites_accepted) then
end