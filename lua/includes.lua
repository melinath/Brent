-- load some files for debugging purposes
debug_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/debug_utils.lua"
modular = wesnoth.require "~add-ons/ModularLua/modular.lua"
inspect = modular.require "inspect"

maps = modular.require "maps"
markup = modular.require "markup"
units = modular.require "units"
modular.require_tags("exits", "interaction")

--! General
quests = modular.require("quests/quests", "Brent")
modular.require("storyboard", "Brent")
modular.require("wml_tags", "Brent")