--! Functions etc. related to cross-scenario objectives.

local events = modular.require "events"
local interface = modular.require "interface"
local maps = modular.require "maps"
local helper = wesnoth.require "lua/helper.lua"


local quests = {}


--! Quest class
quests.quest = events.tag:new("quest", {
	persist = true,
	init = function(self, cfg)
		local o = self:get_parent().init(self, cfg)
		
		o.cfg = cfg
		o.name = cfg.name
		o.id = cfg.id
		o.portrait = cfg.portrait
		o.objectives = cfg.objectives
		o.status = cfg.status
		
		o:fire_map_events()
		return o
	end,
	
	fire_map_events = function(self)
		for m in helper.child_range(self.cfg, "map") do
			if m.id == nil or m.id == maps.current.id then
				for i=1,#m do
					local v = m[i]
					wesnoth.fire(v[1], v[2])
				end
			end
		end
	end,
	
	mark_complete = function(self)
		self.status = 'complete'
		reward = helper.get_child(self.cfg, "reward")
		if reward ~= nil then
			if reward.experience then
				local main_id = wesnoth.get_variable('main.id')
				local u = wesnoth.get_units{id=main_id}[1]
				u.experience = u.experience + reward.experience
			end
		end
		self:clean()
	end,
	is_complete = function(self)
		return self.status == 'complete'
	end,
	
	mark_failed = function(self)
		self.status = 'failed'
		self:clean()
	end,
	is_failed = function(self)
		return self.status == 'failed'
	end,
	
	is_active = function(self)
		return not (self.is_complete() or self.is_failed())
	end,
	
	clean = function(self)
		self.cfg = {
			id = self.id,
			name = self.name,
			portrait = self.portrait,
			objectives = self:generate_objectives(),
			status = self.status
		}
		local qs = helper.get_variable_array("quest")
		for i=1,#qs do
			if qs[i].id == self.id then
				qs[i] = self:dump()
				helper.set_variable_array("quest", qs)
				break
			end
		end
		self:set_var("complete", true)
	end,
	
	get_var_name = function(self, key, namespace)
		if key == nil then error("key is nil; expected string.") end
		if namespace == nil then namespace = self.id end
		return string.format("quests.%s.%s", namespace, key)
	end,
	
	get_var = function(self, key, namespace)
		return wesnoth.get_variable(self:get_var_name(key, namespace))
	end,
	
	set_var = function(self, key, value, namespace)
		wesnoth.set_variable(self:get_var_name(key, namespace), value)
	end,
	
	display_objectives = function(self)
		objectives = self.objectives or self:generate_objectives()
		quest_utils.message(self.portrait, objectives)
	end,
	
	generate_objectives = function(self)
		local objectives = ""
		local success_objectives = ""
		local fail_objectives = ""
		local notes = ""
		
		local success_string = self.cfg.success_string or _ "Success:"
		local fail_string = self.cfg.fail_string or _ "Failure:"
		local notes_string = self.cfg.notes_string or _ "Notes:"
		
		local m = interface.markup
		local cat = m.concat
		
		-- Each objective can have show_if and also a code="" to hold lua code...
		-- The lua code should return a string which is the status of the quest.
		for obj in helper.child_range(self.cfg, "objective") do
			local show_if = helper.get_child(obj, "show_if")
			if not show_if or wesnoth.eval_conditional(show_if) then
				local condition = obj.condition
				-- for day counter, cp objectives turn counter.
				
				local caption = obj.caption or ""
				if caption ~= "" then
					caption = caption .. "\n"
				end
				
				local description = obj.description
				if obj.code then
					local code = loadstring(obj.code)
					local r = code()
					if r ~= nil then
						description = cat(description, " (", r, ")")
					end
				end
				
				if condition == "succeed" then
					success_objectives = cat(success_objectives, caption, m.color(0, 255, 0, m.bullet, description), "\n")
				elseif condition == "fail" then
					fail_objectives = cat(fail_objectives, caption, m.color(255, 0, 0, m.bullet, description), "\n")
				else
					wesnoth.message "Unknown condition, ignoring."
				end
			end
		end
		
		for note in helper.child_range(self.cfg, "note") do
			if note.description then
				notes = cat(notes, m.color(255, 255, 255, m.bullet, m.small(note.description)), "\n")
			end
		end
		
		local name = self.cfg.name
		if name then
			objectives = cat(m.big(name), "\n")
		end
		if success_objectives ~= "" then
			objectives = cat(objectives, m.big(success_string), "\n", success_objectives)
		end
		if fail_objectives ~= "" then
			objectives = cat(objectives, m.big(fail_string), "\n", fail_objectives)
		end
		if notes ~= "" then
			objectives = cat(objectives, notes_string, "\n", notes)
		end
		return string.sub(tostring(objectives), 1, -2)
	end,
	
	cfg = nil,
	id = nil,
	name = nil,
	portrait = nil,
	status = nil,
})


function quests.display()
	-- it should be possible to have a "display all" option.
	local o = {}
	local q = {}
	for k,v in ipairs(quests) do
		if not v:get_var("complete") then
			table.insert(o, v.name)
			table.insert(q, v)
		end
	end
	if next(o) == nil then
		interface.message("There are no active quests")
		return
	end
	choice = helper.get_user_choice({message=_ "Active quests:"}, o)
	q[choice]:display_objectives()
end
-- TODO: This should be done with a dialog and an actual function, not code strings.
quests.display_objectives_code = [[
	local quests = modular.require("quests", "Brent")
	quests.display()
]]


events.register(function()
	-- Add the quests menu item
	menu_item = {
		id="Quest Objectives",
		description = _ "Display Quest Objectives",
		{"command", {{"lua", {code=quests.display_objectives_code}}}}
	}
	wesnoth.fire("set_menu_item", menu_item)
end, "prestart")