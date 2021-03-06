-- load some files for debugging purposes
debug_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/debug_utils.lua"
modular = wesnoth.require "~add-ons/ModularLua/modular.lua"
inspect = modular.require "inspect"
dbg = modular.require "dbg"

maps = modular.require "maps"
markup = modular.require "markup"
units = modular.require "units"
modular.require "interactions"
modular.require "time"

--! General
quests = modular.require("quests", "Brent")
modular.require("centers", "Brent")
modular.require("storyboard", "Brent")
modular.require("wml_tags", "Brent")