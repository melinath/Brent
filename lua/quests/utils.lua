local utils = {}
local helper = wesnoth.require "lua/helper.lua"
_ = wesnoth.textdomain "wesnoth-Brent"

-- Declare a global variable "quests" which must be loaded each time the campaign
-- starts up.
quests = {}


function utils.register_quest(key, quest)
    quests[key] = quest
end


--! [include_quests]
--  Takes a single argument, path, which is interpreted as relative to the
--  lua quests directory, not including ".lua". The file is then run; the file
--  itself is responsible for registering any quests.
local function include_quests(args)
    local path = "~add-ons/Brent/lua/quests/quests/"..args.__parsed.path..".lua"
    wesnoth.dofile(path)
end
wesnoth.register_wml_action("include_quests", include_quests)


--! [quest_center]
--  declares a quest center at a particular location. Subtags include
--  the quests that the center manages and a filter tag indicating which units
--  activate the center (a standard unit filter).
local function quest_center(args)
    local filter = helper.get_child(args, "filter")
    if (filter == nil) then error("~wml:[quest_center] expects a [filter] child", 0) end
    filter = filter.__parsed
    local registry = {}
    registry[0] = {cue = "hi"}
    local i = 0
    for q in helper.child_range(args, "quest") do
        quest = quests[q.key]
        cue = q.cue
        registry[i] = {cue=cue, quest=quest}
        i = i + 1
    end
    local old_on_event = wesnoth.game_events.on_event
    function wesnoth.game_events.on_event(name)
        if old_on_event then old_on_event(name) end
        if (name == "moveto") then
            local c = wesnoth.current.event_context
            unit = wesnoth.get_unit(c.x1, c.y1)
            if (wesnoth.match_unit(unit, filter)) then
                for i, q in ipairs(registry) do
                    wesnoth.message(string.format("Quest cue: %s", q.cue))
                end
            end
        end
    end
end
wesnoth.register_wml_action("quest_center", quest_center)


return utils