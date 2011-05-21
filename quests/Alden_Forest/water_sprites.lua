local c = wesnoth.current.event_context
local x, y = c.x1, c.y1
local response_var = "quests.water_sprites_response"
local response = wesnoth.get_variable(response_var)

if response ~= nil and (x ~= 22 or y ~= 14) then
	return
end

local ylliana = {
	["type"] = "Faerie Dryad",
	canrecruit = true,
	name = "Ylliana",
	id = "Ylliana",
	side = 2,
	animate = true,
	x = 22,
	y = 14
}
local _ = wesnoth.textdomain "wesnoth-Brent"

local ylliana_message = function(msg)
	quest_utils.message(nil, msg, ylliana.id)
end

local too_hard = function()
	wesnoth.set_variable(response_var, "too_hard")
	ylliana_message("Perhaps another time, then.")
	wesnoth.fire("faction_shift", {faeries = -1})
end

local later = function()
	wesnoth.set_variable(response_var, "later")
	ylliana_message("Very well. Come back when you can.")
	wesnoth.fire("faction_shift", {faeries = -1})
end

local reject = function()
	wesnoth.set_variable(response_var, "reject")
	ylliana_message("Hmm... it seems I misjudged you. Very well, human. Perhaps we shall meet again.")
	wesnoth.fire("faction_shift", {faeries = -5})
end

local function accept()
	wesnoth.set_variable(response_var)
	wesnoth.fire_event("accept_water_sprites")
	wesnoth.fire("faction_shift", {faeries=5})
end

local function transition(message, func)
	local function wrapped()
		ylliana_message(message)
		func()
	end
	return wrapped
end

local spiel = function()
	ylliana_message("The forest is being attacked by vile creatures of flame! We need the assistence of our brethren, the water sprites.")
	ylliana_message("Unfortunately, we are bound to these trees, so we have to send wisps as our messagers. They are not especially strong, nor... the most reliable messengers.")
	ylliana_message("I'm sure that if you go along with one of our wisps, you can keep her mind on task and make sure she gets to the Northern River to contact the water sprites.")
	quest_utils.dialog(
		{
			speaker = ylliana.id,
			message = "Do you accept the quest?"
		},
		{
			{
				opt = "Gladly.",
				func = accept
			},
			{
				opt = "No thanks.",
				func = reject
			},
			{
				opt = "Gee, that sounds too hard for me right now...",
				func = too_hard
			}
		}
	)
end

if response == nil then
	local main_id = wesnoth.get_variable("main.id")
	wesnoth.scroll_to_tile(x, y)
	quest_utils.message(nil, "This sure is a big tree!", main_id)
	wesnoth.fire("unit", ylliana)
	ylliana_message("Ah, it's good to find a human who appreciates nature.")
	quest_utils.message(nil, "Whoa!", main_id)
	quest_utils.message(string.format("%s laughs.", ylliana.name))
else
	wesnoth.fire("unit", ylliana)
end
ylliana = wesnoth.get_units({id=ylliana.id})[1]

local intro_message = nil
local opts = {}

local function add_opt(opt, func)
	table.insert(opts, {opt=opt, func=func})
end


if response == nil then
	intro_message = "Tell me, human, would you like to help the Faeries of the Wood? We would be glad to compensate you."
	add_opt("Yes! What can I do for you?", spiel)
	add_opt("Well, sure, but I have to finish hunting first.", later)
	add_opt("N-no. I mean, I'm honored, but I can't.", reject)
elseif response == 'reject' then
	intro_message = "What do you want, human?"
	add_opt("I want to help you.", transition("Hmm. All right.", spiel))
	add_opt("I'm just passing through.", transition("Do so.", reject))
elseif response == 'later' then
	intro_message = "Hello again, human. Are you finished with your other business?"
	add_opt("Yes.", transition("Ah, wonderful.", spiel))
	add_opt("Not quite yet.", transition("Well, just don't take too long if you want to help. The situation is serious.", later))
elseif response == "too_hard" then
	intro_message = "Greetings, human. Are you feeling up to our task now?"
	add_opt("Yes.", transition("Ah, wonderful.", spiel))
	add_opt("Not quite yet.", transition("We're not asking you to fight a yeti, you know.", too_hard))
end


quest_utils.dialog(
	{
		speaker = ylliana.id,
		message = intro_message
	},
	opts
)
wesnoth.put_unit(ylliana.x, ylliana.y)