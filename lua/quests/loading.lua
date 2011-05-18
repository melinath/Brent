local game_events = wesnoth.game_events
local quest_utils = wesnoth.require "~/add-ons/Brent/lua/quests/utils.lua"
local helper = wesnoth.require "lua/helper.lua"
local quest = quest_utils.quest
local _ = wesnoth.textdomain "wesnoth-Brent"


-- Declare global variable "quests" which will be populated
-- each time the campaign starts up.
quests = {}


-- cribbed from lua/wml/objectives.lua
local function color_prefix(r, g, b)
	return string.format('<span foreground="#%02x%02x%02x">', r, g, b)
end


--! Quest class
local quest_mt = {}
local quest = {
	new = function(self, cfg)
		local o = {}
		setmetatable(o, quest_mt)
		
		o.cfg = cfg
		o.name = cfg.name
		o.id = cfg.id
		o.portrait = cfg.portrait
		o.objectives = cfg.objectives
		
		for obj in helper.child_range(cfg, "map") do
			if obj.id ~= nil and obj.id == map.id then
				local c = helper.get_child(obj, "command")
				for i=1,#c do
					local v = c[i]
					wesnoth.fire(v[1], v[2])
				end
			end
		end
		table.insert(quests, o)
		quests[o.id] = o
		return o
	end,
	
	mark_complete = function(self)
		self.cfg = {
			id = self.id,
			name = self.name,
			portrait = self.portrait,
			objectives = self:generate_objectives(),
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
	
	dump = function(self)
		return self.cfg
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
		
		local bullet = "&#8226; "
		
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
						description = description .. " (" .. r .. ")"
					end
				end
				
				if condition == "succeed" then
					success_objectives = success_objectives .. caption .. color_prefix(0, 255, 0) .. bullet .. description .. "</span>" .. "\n"
				elseif condition == "fail" then
					fail_objectives = fail_objectives .. caption .. color_prefix(255, 0, 0) .. bullet .. description .. "</span>" .. "\n"
				else
					wesnoth.message "Unknown condition, ignoring."
				end
			end
		end
		
		for note in helper.child_range(self.cfg, "note") do
			if note.description then
				notes = notes .. color_prefix(255, 255, 255) .. bullet .. "<small>" .. note.description .. "</small></span>\n"
			end
		end
		
		local name = self.cfg.name
		if name then
			objectives = "<big>" .. name .. "</big>\n"
		end
		if success_objectives ~= "" then
			objectives = objectives .. "<big>" .. success_string .. "</big>\n" .. success_objectives
		end
		if fail_objectives ~= "" then
			objectives = objectives .. "<big>" .. fail_string .. "</big>\n" .. fail_objectives
		end
		if notes ~= "" then
			objectives = objectives .. notes_string .. "\n" .. notes
		end
		return string.sub(tostring(objectives), 1, -2)
	end,
	
	cfg = nil,
	id = nil,
	name = nil,
	portrait = nil,
	complete = false,
}
quest_mt.__index = quest


local function create_quest(cfg)
	local q = quest:new(cfg)
	local qs = helper.get_variable_array("quest")
	table.insert(qs, q:dump())
	helper.set_variable_array("quest", qs)
end
wesnoth.register_wml_action("quest", create_quest)


-- load/save overrides
local old_on_load = game_events.on_load
function game_events.on_load(cfg)
	local qs = helper.get_variable_array("quest")
	for i=1,#qs do
		local q = quest:new(qs[i])
	end
	menu_item = {
		id="Quest Objectives",
		description = _ "Display Quest Objectives",
		{"command", {{"lua", {code="quest_utils.display_objectives()"}}}}
	}
	wesnoth.fire("set_menu_item", menu_item)
	old_on_load(cfg)
end