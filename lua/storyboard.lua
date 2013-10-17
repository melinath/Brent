--! Defines functions and tags for handling fake storyboards.
local events = modular.require "events"
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
wesnoth.wml_actions.story_message = storyboard.story_message


events.register(function()
	local msgs = helper.get_variable_array("story_message")
	for i=1,#msgs do
		wesnoth.fire("narrate", msgs[i])
	end
	wesnoth.set_variable "story_message"
end, "prestart")


return storyboard