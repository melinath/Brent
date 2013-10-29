local helper = wesnoth.require("lua/helper.lua")

local interface = modular.require("interface")
local units = modular.require("units")

local objectives = modular.require("objectives", "Brent")
local quests = modular.require("quests", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local fetch_water_sprites = modular.require("quests/faeries/01_fetch_water_sprites", "Brent")


local return_to_ylliana = objectives.manual:init({
    description = "Return to Lady Ylliana in Alden Forest for your reward.",

})


local quest = quests.quest:init({
    id = "faeries_reward",
    path = "faeries/02_faeries_reward",
    name = _("Faerie's Reward"),
    portrait = "portraits/dryad.png",

    success_objectives = {
        return_to_ylliana
    },

    intro = function(self, lyra, lellanila)
        local pia_message = function(msg) interface.message(nil, msg, "Pia") end
        local lyra_message = function(msg) interface.message(nil, msg, lyra.id) end
        local lellanila_message = function(msg) interface.message(nil, msg, lellanila.id) end
        pia_message("Greetings, Lady Lyra. I bear tidings from Lady Ylliana of the Forest.")
        lyra_message("Greetings, wisp. What may these tidings be?")
        pia_message("Flame spirits have once more besieged the forest. We request your help.")
        lyra_message("The friendship between our peoples is strong. We will honor your request. And this young human?")

        local hero = wesnoth.get_units({id="Brent"})[1]
        local pronouns = units.get_pronouns(hero)
        pia_message("Ylliana chose " .. pronouns.acc .. " to guide me here.")
        lyra_message("I see... well, that's a great honor, human. No doubt she'll want to reward you. I suggest you return to her soon.")
        lyra_message("I'm certain we shall meet again, human.")

        local x, y = wesnoth.find_vacant_tile(13, 12, lellanila)
        wesnoth.put_unit(x, y, lellanila)
        wesnoth.fire("animate_unit", {flag="recruited", {"filter", {id=lellanila.id}}})

        lyra_message("Lellanila, take my place here.")
        lellanila_message("Yes, my lady.")

        lyra_message("Now, my fellow sprites – we leave at once!")

        local unit_types = {"Water_Dryad", "Water_Nymph"}
        for i=1,4 do
            local unit_type = unit_types[math.random(1, #unit_types)]
            local unit = wesnoth.create_unit({side=2, type=unit_type})
            local x, y = wesnoth.find_vacant_tile(13, 12, unit)
            wesnoth.put_unit(x, y, unit)
            wesnoth.fire("animate_unit", {flag="recruited", {"filter", {id=unit.id}}})
        end

        local unit_list = wesnoth.get_units({side=2, {"not", {id=lellanila.id}}})
        for i, unit in ipairs(unit_list) do
            helper.move_unit_fake({id=unit.id}, 24, 33)
        end
        for i, unit in ipairs(unit_list) do
            wesnoth.put_unit(unit.x, unit.y)
        end
        helper.move_unit_fake({id=lellanila.id}, 13, 12)
        fetch_water_sprites.success_objectives[1]:mark_complete(fetch_water_sprites)
        self:start()
    end,
})


return quest
