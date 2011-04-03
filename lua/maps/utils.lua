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

return utils