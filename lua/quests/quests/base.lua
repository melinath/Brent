-- Quest class
local quest = {
	new = function(self, id)
			if type(id) == "string" and id ~= "base" then
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
	
	cfg = nil,
	id = nil,
	name = nil,
	is_active = function(self) return false end,
	
	-- Contains a mapping of scenario ids and quest center keys to functions.
	scenarios = {}
}
return quest