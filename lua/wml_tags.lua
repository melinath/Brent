local helper = wesnoth.require "lua/helper.lua"
local wlp_utils = wesnoth.require "~add-ons/Wesnoth_Lua_Pack/wlp_utils.lua"
_ = wesnoth.textdomain "wesnoth-Brent"


-- CHARACTERISTIC TAGS --

--! [faction_shift]

-- given a paired faction/number list, shifts the player's faction rating
-- by that number.
-- Factions: dwarves, faeries, flame 

local function faction_shift(args)
    local args = args.__parsed
    for f,v in pairs(args) do
        o=wesnoth.get_variable('factions.'..f) or 0
        wesnoth.set_variable("factions."..f,o+v)
    end
    wesnoth.set_variable("unit_store")
end

wesnoth.register_wml_action("faction_shift",faction_shift)

--! [alignment_shift]

-- type=good moves it up, type=bad moves it down, type=neutral moves it towards the
-- center. Takes a filter for the unit(s). value= is the amount. Range is -1000-1000.

local function alignment_shift(args)
    args = args.__parsed
    local filter = helper.get_child(args, "filter")
    local shift = args.type
    local val = args.value
    wesnoth.fire("store_unit", {
        [1] = { "filter", filter },
        variable = "unit_store",
        kill = true
    })
    for i=0,wesnoth.get_variable("unit_store.length")-1 do
        local alignment=wesnoth.get_variable("unit_store["..i.."].variables.alignment")
        if(shift=='good') then
            alignment = alignment + val
            if alignment>1000 then alignment=1000 end
        end
        if(shift=='bad') then
            alignment = alignment - val
            if alignment<-1000 then alignment=-1000 end
        end
        if(shift=='neutral') then
            if(alignment>0) then
                alignment = alignment - val
                if alignment < 0 then alignment = 0 end
            end
            if(alignment<0) then
                alignment = alignment + val
                if alignment > 0 then alignment = 0 end
            end
        end
        wesnoth.set_variable("unit_store["..i.."].variables.alignment",alignment)
        wesnoth.fire("unstore_unit", {
            variable = "unit_store[" .. i .. "]",
            find_vacant = false
        })
    end
    wesnoth.set_variable("unit_store")
end
wesnoth.register_wml_action("alignment_shift",alignment_shift)

-- END CHARACTERISTIC TAGS --


-- SCENARIO TAGS --

--! [wandering_monsters]
-- sets certain sides to have their units move randomly within their maximum
-- movement.

local function wandering_monsters()
    wesnoth.fire("store_unit", {
    [1] = { "filter", {side=wesnoth.get_variable("side_number")} },
    variable = "unit_store",
        kill = true
    })
    for i = 0, wesnoth.get_variable("unit_store.length") - 1 do
    local u = wesnoth.get_variable("unit_store[" .. i .. "]")
    wesnoth.fire("store_locations",{
        {"and",{x=u.x,y=u.y,radius=u.max_moves}},
        {"not",{x=u.x,y=u.y}},
        variable="possible_gotos"
        })
    local r=math.random(0,wesnoth.get_variable("possible_gotos.length")-1)
    local goto=wesnoth.get_variable("possible_gotos["..r.."]")
    
    wesnoth.set_variable("unit_store[" .. i .. "].goto_x",goto.x)
    wesnoth.set_variable("unit_store[" .. i .. "].goto_y",goto.y)
    wesnoth.fire("unstore_unit", {
        variable = "unit_store[" .. i .. "]",
        find_vacant = false
        })
    end
    wesnoth.set_variable("unit_store")
    wesnoth.set_variable("possible_gotos")
end
wesnoth.register_wml_action("wandering_monsters",wandering_monsters)


-- END SCENARIO TAGS --


-- UNIT TAGS --


--! [pronouns], given a unit filter (takes first unit) or a gender, sets the
-- prounoun variable accordingly.
--
-- Example:
-- [pronouns]
--     [filter]
--         name=Scott
--     [/filter]
-- [/pronouns]
--
-- The pronoun variable is structured as follows:
-- pronoun.nom :: The nominative pronoun
-- pronoun.acc :: The accusative pronoun
-- pronoun.pos :: The possessive pronoun
-- pronoun.uc  :: A copy of pronoun with the first letter of each pronoun capitalized
--
-- TODO: This should allow a variable name to be chosen.
local function pronouns(args)
    local args=args.__parsed
    local gender = args.gender
    local filter = helper.get_child(args,"filter")
    if type(filter) == "table" then
        wesnoth.fire("store_unit", {
            [1] = { "filter", filter },
            variable = "unit_store",
            kill = true
            })
        gender=wesnoth.get_variable("unit_store[0].gender")
        wesnoth.set_variable("unit_store")
    end
    if gender == 'male' then
    wesnoth.set_variable("pronoun", {
        nom='he',acc='him',pos='his',
        {'uc', {nom='He',acc='him',pos='His'}}
    })
    elseif gender == 'female' then
    wesnoth.set_variable("pronoun", {
        nom='she',acc='her',pos='hers',
        {'uc', {nom='She',acc='Her',pos='Hers'}}
    })
    else
    wesnoth.set_variable("pronoun", {
        nom='ze',acc='hir',pos='hirs',
        {'uc', {nom='Ze',acc='Hir',pos='Hirs'}}
    })
    
    end
end
wesnoth.register_wml_action("pronouns",pronouns)

-- END UNIT TAGS --