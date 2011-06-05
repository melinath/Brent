--! Modular!
local function req(str)
	return wesnoth.require(string.format("~add-ons/Brent/lua/generic/%s.lua", str))
end

capture = req('capture')
events = req('events')
exits = req('exits')
interactions = req('interactions')
interface = req('interface')
maps = req('maps')
quests = req('quests')
storyboard = req('storyboard')
time = req('time')
units = req('units')

--! General
wesnoth.dofile "~add-ons/Brent/lua/wml_tags.lua"

-- load some files for debugging purposes
debug_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/debug_utils.lua"