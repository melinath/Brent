quest_utils = wesnoth.require "~add-ons/Brent/lua/quests/utils.lua"
time_utils = wesnoth.require "~add-ons/Brent/lua/time/utils.lua"

--! General
wesnoth.dofile "~add-ons/Brent/lua/wml_tags.lua"

--! Quests
wesnoth.dofile "~add-ons/Brent/lua/quests/loading.lua"

--! Maps
--  This needs to come after quests so that the map is defined before quests are parsed.
wesnoth.dofile "~add-ons/Brent/lua/maps/loading.lua"

--! Time
wesnoth.dofile "~add-ons/Brent/lua/time/loading.lua"

-- load some files for debugging purposes
debug_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/debug_utils.lua"