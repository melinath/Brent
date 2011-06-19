-- load some files for debugging purposes
debug_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/debug_utils.lua"
modular = wesnoth.require "~add-ons/ModularLua/modular.lua"

maps = modular.require "maps"

--! General
quests = modular.require("quests", "Brent")
modular.require("storyboard", "Brent")
modular.require("units", "Brent")
modular.require("wml_tags", "Brent")