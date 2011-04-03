local time_utils = {}
local _ = wesnoth.textdomain "wesnoth-help"


local time_variable = 'time'


function time_utils.get_time()
	return wesnoth.get_variable(time_variable) or 0
end


function time_utils.set_time(time)
	wesnoth.set_variable(time_variable, time)
end


return time_utils