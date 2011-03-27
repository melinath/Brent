local _ = wesnoth.textdomain "wesnoth-Brent"
local helper = wesnoth.require "lua/helper.lua"


-- cribbed from lua/wml/objectives.lua
local function color_prefix(r, g, b)
	return string.format('<span foreground="#%02x%02x%02x">', r, g, b)
end


-- Quest class
local quest = {
	new = function(self, id)
			if type(id) == "string" and id ~= "base" then
				if id:find("..", 1, true) then error("~wml:[quest] ids cannot contain the string `..`") end
				filename = string.format("~add-ons/Brent/lua/quests/quests/%s.lua", id)
				success, o = pcall(wesnoth.require, filename)
				if success ~= true then o = {} end
			else
				o = {}
			end
			setmetatable(o, self)
			self.__index = self
			return o
		end,
	
	setup = function(self, cfg, scenario_id)
		self.cfg = cfg
		self.name = cfg.name
		self.id = cfg.id
		self.portrait = cfg.portrait
		for k,v in pairs(self.scenarios) do
			if type(k) == "number" and type(v) == "function" then
				v()
			elseif type(k) == "string" and type(v) == "table" and k == scenario_id then
				for j,u in pairs(v) do
					if type(j) == "number" and type(u) == "function" then
						u()
					elseif type(j) == "string" and type(u) == "table" then
						for i, t in quest_centers do
							if j == i then
								for h, s in u do
									s()
								end
							end
						end
					end
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
		
		for obj in helper.child_range(self.cfg, "objective") do
			local show_if = helper.get_child(obj, "show_if")
			if not show_if or wesnoth.eval_conditional(show_if) then
				local condition = obj.condition
				-- for day counter, cp objectives turn counter.
				
				local caption = obj.caption or ""
				if caption ~= "" then
					caption = caption .. "\n"
				end
				
				if condition == "succeed" then
					success_objectives = success_objectives .. caption .. color_prefix(0, 255, 0) .. bullet .. obj.description .. "</span>" .. "\n"
				elseif condition == "fail" then
					fail_objectives = fail_objectives .. caption .. color_prefix(255, 0, 0) .. bullet .. obj.description .. "</span>" .. "\n"
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
return quest