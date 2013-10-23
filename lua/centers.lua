local events = modular.require "events"
local scenario = modular.require "scenario"
local utils = modular.require "utils"


local centers = {}


centers.centers = {}


centers.center = utils.matcher:subclass({
	--! Basic quest center class. This should be instantiated by calling
	--! ``centers.center:init(cfg)``, where ``cfg`` is a table defining
	--! overriding behavior for the instance.

	init = function(cls, cfg)
		local instance = utils.matcher.init(cls, cfg)
		table.insert(centers.centers, instance)
		return instance
	end,
	
	get_var_name = function(self, key, namespace)
		if key == nil then error("key is nil; expected string.") end
		if namespace == nil then namespace = self.id end
		return string.format("quest_centers.%s.%s", namespace, key)
	end,
	
	get_var = function(self, key, namespace)
		return wesnoth.get_variable(self:get_var_name(key, namespace))
	end,
	
	set_var = function(self, key, value, namespace)
		wesnoth.set_variable(self:get_var_name(key, namespace), value)
	end,
	
	-- Whether the player knows that the center exists.
	is_known = function(self) return self:get_var("known") end,
	mark_known = function(self) self:set_var("known", true) end,
	
	-- Whether the player has actually been to the center.
	is_visited = function(self) return self:get_var("visited") end,
	mark_visited = function(self) self:set_var("visited", true) end,

	setup = function(self)
		-- Hook for prestart behavior.
	end,

	on_match = function(self)
		-- Hook for behavior when the center is activated.
		if not self:is_known() then self:mark_known() end
		if not self:is_visited() then self:mark_visited() end
	end
})


centers.center_tag = scenario.tag:subclass({
	name = "quest_center",
	init = function(cls, cfg)
		local instance = scenario.tag.init(cls, cfg)
		local path = "centers/" .. instance.wml.path
		modular.require(path, "Brent")
		return instance
	end,
})


events.register("moveto", function()
	for i, center in ipairs(centers.centers) do
		if center:matches() then
			center:on_match()
		end
	end
end)


events.register("prestart", function()
	for i, center in ipairs(centers.centers) do
		center:setup()
	end
end)


return centers
