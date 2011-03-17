local helper=wesnoth.require "lua/helper.lua"
local wlp_utils=wesnoth.require "~add-ons/Wesnoth_Lua_Pack/wlp_utils.lua"
local brent_utils=wesnoth.require "~add-ons/Brent/utils/brent_utils.lua"
_=wesnoth.textdomain "wesnoth-Brent"

--! [quest_objectives]
-- fires a message containing the objectives for all active quests.
local function quest_objectives_display()
    local line_list=wesnoth.get_variable("quest_line_list")
    local quest_objectives = ""
    if line_list~=nil then
        for line in string.gmatch(line_list,"([A-Z]+),") do
            local x = wesnoth.get_variable("quests."..line..".length")
    	    for i=0,x-1 do
    	        if wesnoth.get_variable("quests."..line..'['..i..'].active')==1 then
		    quest_objectives = quest_objectives..wesnoth.get_variable("quests."..line..'['..i..'].objectives')
	        end
	    end
        end
    end
    if quest_objectives=="" then quest_objectives=_"You aren't on any quests" end
    wesnoth.fire("narrate",{image="wesnoth-icon.png",message=quest_objectives})
end
wesnoth.register_wml_action("quest_objectives",quest_objectives_display)


--! [quest_dialogue]
-- [message] with some stuff added
local function quest_dialog_command(args)
    local args=args.__parsed
    wesnoth.fire("message",{id=args.id,message=args.reaction})
    wesnoth.set_variable("quests."..args.line..'['..args.num..'].response',args.value)
    if(args.value==true or args.value=="yes") then wesnoth.set_variable("quests."..args.line..'['..args.num..'].active',1) end
    local quest_vars = helper.get_child(args,"quest_vars")
    if(quest_vars~=nil) then
        wlp_utils.remove_child(args,"quest_vars")
        for k,v in pairs(quest_vars) do
	    if(k=="objectives") then wesnoth.fire("narrate",{image="wesnoth-icon.png",message="<span foreground='green'>You have new Quest Objectives.</span>\
They are accessible through the right-click menu."}) end
	    wesnoth.set_variable("quests."..args.line..'['..args.num..'].'..k,v)
	end
    end
    for i=1,#args do
	wesnoth.fire(args[i][1],args[i][2])
    end
end
wesnoth.register_wml_action("quest_dialog_command",quest_dialog_command)

local function quest_dialog(args)
    local args=args.__literal
    local line=args.line
    local num=args.num
    local msg=args.message or _"Do you accept the quest?"
    local new_args = {id=args.id,message=msg}
    local command = helper.get_child(args,"option")
    while command~=nil do
	command.line=args.line
	command.num=args.num
	command.id=args.id
	local show_if=helper.get_child(command,"show_if")
	if show_if~=nil then
	    wlp_utils.remove_child(command,"show_if")
	    table.insert(new_args,
	        {"option",
                    {message=command.message,
		        {"show_if",show_if},
		        {"command",{{"quest_dialog_command",command}}}
		    }
		})
	else
	    table.insert(new_args,{"option",
                    {message=command.message,
	                {"command",{{"quest_dialog_command",command}}}
		    }
	        })
	end
	command=wlp_utils.remove_child(args,"option")
	command=helper.get_child(args,"option")
    end
    wesnoth.fire("message",new_args)
end
wesnoth.register_wml_action("quest_dialog",quest_dialog)

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

--! Preps the day length for a scenario. Takes day=, which is the number of turns in
-- the day.
local function set_day(args)
    local turn_length = 24/args.day
    wesnoth.set_variable("turn_length",turn_length)
    wesnoth.fire("modify_turns",{current=math.ceil(wesnoth.get_variable("global_TOD")/turn_length)})
end
wesnoth.register_wml_action("set_day",set_day)

--! [pronouns], given a unit filter (takes first unit) or a gender, sets the
-- prounoun variable accordingly.
--
-- Example:
-- [pronouns]
--     [filter]
--         name=Scott
--     [/filter]
-- [/pronoun]
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