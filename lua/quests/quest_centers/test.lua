local test = {
	activate = function(self, unit)
		wesnoth.message(string.format("This is a test. This is only a test. You are at %d, %d.", unit.x, unit.y))
	end
}
return test