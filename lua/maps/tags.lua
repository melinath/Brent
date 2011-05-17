local helper = wesnoth.require "lua/helper.lua"


local function story_message(cfg)
	if cfg.message then
		local msgs = helper.get_variable_array("story_message")
		table.insert(msgs, cfg)
		helper.set_variable_array("story_message", msgs)
	end
end
wesnoth.register_wml_action("story_message", story_message)