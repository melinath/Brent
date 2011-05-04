local function story_message(cfg)
	if cfg.message then
		local msgs = wesnoth.get_variable_array("story_message")
		table.insert(msgs, cfg.message)
		wesnoth.set_variable_array("story_message", msgs)
	end
end
wesnoth.register_wml_action("story_message", story_message)