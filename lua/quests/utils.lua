local _ = wesnoth.textdomain "wesnoth-Brent"
local helper = wesnoth.require "lua/helper.lua"
local quest_utils = {}


quest_utils.message = function(image, message, speaker)
	if message == nil and speaker == nil then
		message = image
		image = "wesnoth-icon.png"
	end
	if speaker == nil then speaker = 'narrator' end
	wesnoth.fire("message", {speaker=speaker, image=image, message=_(message)})
end


quest_utils.has_advance = function(unit, advance_id)
	local mods = helper.get_child(unit.__cfg, "modifications")
	for i=1,#mods do
		if mods[i][1] == "advance" then
			if mods[i][2].id == advance_id then return true end
		end
	end
	return false
end


quest_utils.dialog = function(cfg, options)
	-- cfg is an (img, msg, speaker) table; options is a table of tables
	-- containing an option and a function.
	local o = {}
	local f = {}
	for i=1,#options do
		table.insert(o, options[i].opt)
		table.insert(f, options[i].func)
	end
	choice = helper.get_user_choice(cfg, o)
	f[choice]()
end


quest_utils.display_objectives = function()
	-- it should be possible to have a "display all" option.
	if next(quests) == nil then
		quest_utils.message("There are no active quests")
		return
	end
	local o = {}
	local q = {}
	for k,v in pairs(quests) do
		table.insert(o, v.name)
		table.insert(q, v)
	end
	choice = helper.get_user_choice({message=_ "Active quests:"}, o)
	q[choice]:display_objectives()
end


return quest_utils