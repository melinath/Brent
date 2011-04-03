local game_events = wesnoth.game_events


map = {
	id = nil,
	turns_per_day = 6,
	
	config = function(self, cfg)
		self.turns_per_day = cfg.turns_per_day or self.turns_per_day
		self.id = cfg.id
	end,
	dump = function(self)
		return {
			turns_per_day = self.turns_per_day,
			id = self.id
		}
	end,
	get_timedelta = function(self)
		-- timedelta is the local time change per turn
		return 24/self.turns_per_day
	end
}


local old_on_load = game_events.on_load
function game_events.on_load(cfg)
	for i=#cfg,1,-1 do
		local v = cfg[i]
		if v[1] == "map" then
			local v2 = v[2]
			map:config(v2)
			table.remove(cfg, i)
		end
	end
	old_on_load(cfg)
end


local old_on_save = game_events.on_save
function game_events.on_save()
	cfg = old_on_save()
	table.insert(cfg, {"map", map:dump()})
	return cfg
end