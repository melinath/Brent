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
})


return quest
