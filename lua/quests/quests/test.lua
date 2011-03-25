local quest_utils = wesnoth.require "~add-ons/Brent/lua/quests/utils.lua"


local test_quest = {
    "name" = "Test Quest",
    "objectives" = {
        "success" = {
            "Test success 1",
            "Test success 2"
        },
        "failure" = {
            "Test failure 1",
            "Test failure 2"
        }
    },
    -- is_active is a method that returns true or false
    "is_active" = function() return true end,
    
    -- intro is called to introduce a quest segment.
    "intro" = nil,
    
    -- resolve is called to resolve a quest segment.
    "resolve" = nil,
    
    -- scenario_setup contains a mapping of scenario names to functions that
    -- set the quest conditions for that map.
    "scenario_setup" = {
    }
}
quest_utils.register_quest("test", test_quest)