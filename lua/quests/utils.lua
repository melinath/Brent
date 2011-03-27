local _ = wesnoth.textdomain "wesnoth-Brent"
local helper = wesnoth.require "lua/helper.lua"
local quest_utils = {}


quest_utils.message = function(image, message, speaker)
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


return quest_utils