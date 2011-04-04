local utils = {}

local function get_var(id, var)
	return string.format("maps.%s.%s", id, var)
end

function utils.mark_known(id)
	wesnoth.set_variable(get_var(id, "known"), true)
end

function utils.is_known(id)
	return wesnoth.get_variable(get_var(id, "known"))
end

function utils.mark_visited(id)
	wesnoth.set_variable(get_var(id, "visited"), true)
end

function utils.was_visited(id)
	return wesnoth.get_variable(get_var(id, "visited"))
end


function utils.store_shroud(id)
	wesnoth.fire("store_shroud", {side=1, variable=get_var(id, "shroud")})
end

function utils.load_shroud(id)
	shroud_data = wesnoth.get_variable(get_var(id, "shroud"))
	if shroud_data ~= nil then
		wesnoth.fire("set_shroud", {side=1, shroud_data=shroud_data})
	end
end

local _ = wesnoth.textdomain "wesnoth-help"
utils.schedules = {
	dawn = {
		id=dawn,
		name= _ "Dawn",
		image="misc/schedule-dawn.png",
		red=-20,
		green=-20,
		sound="ambient/morning.ogg",
	},
	morning = {
		id=morning,
		name= _ "Morning",
		image="misc/schedule-morning.png",
		lawful_bonus=25
	},
	afternoon = {
		id=afternoon,
		name= _ "Afternoon",
		image="misc/schedule-afternoon.png",
		lawful_bonus=25
	},
	dusk = {
		id=dusk,
		name= _ "Dusk",
		image="misc/schedule-dusk.png",
		green=-20,
		blue=-20,
		sound="ambient/night.ogg",
	},
	first_watch = {
		id=first_watch,
		name= _ "First Watch",
		image="misc/schedule-firstwatch.png",
		lawful_bonus=-25,
		red=-45,
		green=-35,
		blue=-10,
	},
	second_watch = {
		id=second_watch,
		name= _ "Second Watch",
		image="misc/schedule-secondwatch.png",
		lawful_bonus=-25,
		red=-45,
		green=-35,
		blue=-10
	},
	indoors = {
		id=indoors,
		name= _ "Indoors",
		image="misc/schedule-indoors.png",
		lighter=indoors_illum,
		illuminated = {
			id=indoors_illum,
			name= _ "Indoors",
			image="misc/schedule-indoors.png",
			lawful_bonus=25
		}
	},
	underground = {
		id=underground,
		name= _ "Underground",
		image="misc/schedule-underground.png",
		lawful_bonus=-25,
		red=-45,
		green=-35,
		blue=-10,
		illuminated = {
			id=underground_illum,
			name= _ "Underground",
			image="misc/schedule-underground-illum.png",
		}
	},
	deep_underground = {
		id=deep_underground,
		name= _ "Deep Underground",
		image="misc/schedule-underground.png",
		lawful_bonus=-30,
		red=-40,
		green=-45,
		blue=-15,
		illuminated = {
			id=deep_underground_illum,
			name= _ "Deep Underground",
			image="misc/schedule-underground-illum.png"
		}
	}
}
--utils.default_schedule = {"dawn", "morning", "afternoon", "dusk", "first_watch", "second_watch"}

return utils