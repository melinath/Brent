--! Defines functions and tags for handling fake storyboards.
local events = wesnoth.require "~add-ons/Brent/lua/modular/events.lua"
local helper = wesnoth.require "lua/helper.lua"


local storyboard = {}


function storyboard.story_message(cfg)
	local cfg = cfg.__parsed
	if cfg.message then
		local msgs = helper.get_variable_array("story_message")
		table.insert(msgs, cfg)
		helper.set_variable_array("story_message", msgs)
	end
end
wesnoth.register_wml_action("story_message", story_message)


events.register(function()
	local msgs = helper.get_variable_array("story_message")
	for i=1,#msgs do
		wesnoth.first("narrate", msgs[i])
	end
	wesnoth.set_variable "story_message"
end, "prestart")


return storyboard