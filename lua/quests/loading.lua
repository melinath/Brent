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
local quest = {
	new = function(self, cfg)
		local o = {}
		setmetatable(o, self)
		self.__index = self
		o:setup(cfg)
		table.insert(quests, o)
		return o
	end,
	
	setup = function(self, cfg)
		self.cfg = cfg
		self.name = cfg.name
		self.id = cfg.id
		self.portrait = cfg.portrait
		
		for obj in helper.child_range(cfg, "map") do
			if obj.id ~= nil and obj.id == map.id then
				local c = helper.get_child(obj, "command")
				for i=1,#c do
					local v = c[i]
					wesnoth.fire(v[1], v[2])
				end
			end
		end
	end,
	
	dump = function(self)
		return self.cfg
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
	
	display_objectives = function(self)
		quest_utils.message(self.portrait, self:generate_objectives())
	end,
	
	cfg = nil,
	id = nil,
	name = nil,
	portrait = nil,
	is_active = function(self) return false end,
	
	-- Contains a mapping of scenario ids and quest center keys to functions.
	scenarios = {}
}


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