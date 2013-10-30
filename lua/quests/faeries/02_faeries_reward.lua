local interface = modular.require("interface")
local strings = modular.require("strings")
local time = modular.require("time")
local units = modular.require("units")

local objectives = modular.require("objectives", "Brent")
local quests = modular.require("quests", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local fetch_water_sprites = modular.require("quests/faeries/01_fetch_water_sprites", "Brent")


local return_to_ylliana = objectives.manual:init({
    description = "Return to Lady Ylliana in Alden Forest for your reward.",

    get_map_events = function(self, quest)
        return {
            Alden_Forest = {
                {"side 2 turn", function()
                    local unit_list = wesnoth.get_units({
                        side = 1,
                        x = "21,22,23",
                        y="14-15,13-15,14-15",
                    })
                    if #unit_list > 0 then
                        local messages = {
                            {
                                {"Lyra", "...and this time we should wipe them out!"},
                                {"Ylliana", "No! Just..."},
                            },
                            {
                                {"Lyra", "...if you look at the water levels, you'll see that..."},
                            },
                            {
                                {"Ylliana", "...dangerous. But if we..."}
                            },
                            {
                                {"Lyra", "...that game we played as children?"},
                                {"Ylliana", "Of course I do. Elle melle mira mai..."},
                            },
                        }
                        local message = messages[math.random(1, #messages)]
                        for i=1,#message do
                            wesnoth.fire("message", {
                                speaker = narrator,
                                caption = message[i][1],
                                message = message[i][2],
                                image = "portraits/bfw-logo.png",
                            })
                        end
                    end
                end},
                {"side 1 turn", function()
                    local unit_list = wesnoth.get_units({
                        side = 1,
                        x = "21,22,23",
                        y="14-15,13-15,14-15",
                    })
                    if #unit_list > 0 and not quest:is_waiting() then
                        local center = modular.require("centers/alden_forest/faeries", "Brent")
                        quest:outro(center)
                    end
                end},
            }
        }
    end,
})


local quest = quests.quest:init({
    id = "faeries_reward",
    path = "faeries/02_faeries_reward",
    name = _("Faerie's Reward"),
    portrait = "portraits/dryad.png",

    success_objectives = {
        return_to_ylliana
    },

    rewards = {
        experience = 20,
    },

    start = function(self)
        self:set_var("start_time", time.get())
        quests.quest.start(self)
    end,

    get_time_left = function(self)
        -- Wait five days before letting this go through.
        return (self:get_var("start_time") + 5 * 24) - time.get()
    end,
    is_waiting = function(self)
        return self:get_time_left() > 0
    end,
    waiting = function(self)
        interface.message("You are stopped at the base of the tree by a guard.")
        local time_left = self:get_time_left()
        local time_msg
        if time_left > 2 * 24 then
            time_msg = "in " .. math.floor(time_left / 24) .. " days"
        elseif time_left > 24 then
            time_msg = "tomorrow"
        else
            time_msg = "later today"
        end

        interface.message("portraits/elves/transparent/fighter.png", "Elvish Guard", "They do not wish to be disturbed right now. They'll probably be done " .. time_msg .. ".")
        interface.message("In the distance, you can hear snips of conversation...")
    end,

    outro = function(self, center)
        center:show_leader()
        local ylliana = center.ylliana
        local hero_id = wesnoth.get_variable("main.id")
        local hero = wesnoth.get_units({id=hero_id})[1]
        local pronouns = units.get_pronouns(hero)
        interface.message(ylliana, "Ah, you've come for your reward, I see.")
        interface.message(ylliana, "<i>Ylliana lays her hands on " .. hero.name .. "'s head. " ..
                                   strings.capfirst(pronouns.nom) .. " shivers as a slight chill runs " ..
                                   "through " .. pronouns.acc .. ".</i>")
        return_to_ylliana:mark_complete(self)

        interface.message(ylliana, "If you wish to continue aiding us, go south to the battlefield. The " ..
                                   "commander there can tell you what to do.")
    end,
})


return quest
