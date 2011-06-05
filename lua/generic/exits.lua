--! Defines generic exits from one scenario to another, with custom
--! start locations.

local events = wesnoth.require "~add-ons/Brent/lua/generic/events.lua"

local exits = {}

exits.settings = {
	start_x_var = "start_x",
	start_y_var = "start_y",
	sides = {1}
}

--! Exit class
exits.exit = events.tag:new("exit", {
	init = function(self, cfg)
		local o = self:get_parent().init(self, cfg)
		
		local filter = helper.get_child(cfg, "filter")
		if filter == nil then error("~wml:[exit] expects a [filter] child", 0) end
		
		o.filter = helper.literal(filter)
		o.start_x = cfg.start_x
		o.start_y = cfg.start_y
		o.scenario = cfg.scenario
		
		return o
	end,
	is_active = function(self)
		local c = wesnoth.current.event_context
		local u = wesnoth.get_unit(c.x1, c.y1)
		if u == nil then return false end
		return wesnoth.match_unit(u, self.filter)
	end,
	activate = function(self)
		local c = wesnoth.current.event_context
		wesnoth.set_variable(exits.settings.start_x_var, self.start_x)
		wesnoth.set_variable(exits.settings.start_y_var, self.start_y)
		wesnoth.fire_event("exit", c.x1, c.y1, c.x2, c.y2)
		local e = {
			name = "victory",
			save = true,
			carryover_report = false,
			carryover_percentage = 100,
			linger_mode = false,
			bonus = false,
			next_scenario = self.scenario
		}
		wesnoth.fire("endlevel", e)
	end
})

--! Exit canceler class
exits.exit_canceler = events.tag:new("cancel_exit", {
	init = function(self, cfg)
		local o = self:get_parent().init(self, cfg)
		
		local filter = helper.get_child(cfg, "filter")
		if filter == nil then error("~wml:[cancel_exit] expects a [filter] child", 0) end
		o.filter = helper.literal(filter)
		
		local cancel_if = helper.get_child(cfg, "cancel_if")
		if cancel_if ~= nil then
			local lua = helper.get_child(cancel_if, "lua")
			if lua ~= nil then
				o.should_cancel = loadstring(lua.code)
			end
		end
		o.cancel_if = helper.literal(cancel_if)
		
		o.command = helper.get_child(cfg, "command")
	end,
	should_cancel = function(self)
		local c = wesnoth.current.event_context
		local u = wesnoth.get_unit(c.x1, c.y1)
		
		if not wesnoth.match_unit(u, self.filter) then return false end
		if self.cancel_if == nil then return true end
		
		local lua = helper.get_child(self.cancel_if, "lua")
		if lua ~= nil then
			return loadstring(lua.code)()
		end
		return wesnoth.eval_conditional(self.cancel_if)
	end,
	run_commands = function(self)
		if self.command ~= nil then
			for i=1,#self.command do
				local v = self.command[i]
				wesnoth.fire(v[1], v[2])
			end
		end
	end,
})

events.register(function()
	-- Set starting position.
	local x = wesnoth.get_variable(exits.settings.start_x_var)
	local y = wesnoth.get_variable(exits.settings.start_y_var)
	
	if x ~= nil and y ~= nil then
		local units = wesnoth.get_units{side=exits.settings.sides}
		local var = "Lua_store_unit"
		for i,u in ipairs(units) do
			wesnoth.set_variable(var, u.__cfg)
			wesnoth.put_unit(u.x, u.y)
			wesnoth.fire("unstore_unit", {variable=var, find_vacant=true})
		end
		wesnoth.set_variable(var)
		wesnoth.scroll_to_tile(start_x, start_y)
	end
	
	wesnoth.set_variable(exits.settings.start_x_var)
	wesnoth.set_variable(exits.settings.start_y_var)
end, "prestart")

events.register(function()
	local es = exits.exit.instances
	for i=1,#es do
		if es[i]:is_active() then
			local activate = true
			local cs = exits.exit_canceler.instances
			for j=1,#cs do
				if cs[j]:should_cancel() then
					activate = false
					cs[j]:run_commands()
					break
				end
			end
			if activate then es[i]:activate() end
		end
	end
end, "moveto")


return exits