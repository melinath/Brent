local game_events = wesnoth.game_events
local quest = wesnoth.require "~/add-ons/Brent/lua/quests/quests/base.lua"
local quest_center = wesnoth.require "~/add-ons/Brent/lua/quests/quest_centers/base.lua"


-- Declare global variables "quests" and "quest_centers" which will be populated
-- each time the campaign starts up.
quests = {}
quest_centers = {}


-- load/save overrides
local old_on_load = game_events.on_load
function game_events.on_load(cfg)
	local scenario_id = cfg.id
	for i=#cfg,1,-1 do
		local v = cfg[i]
		if v[1] == "quest_center" then
			local v2 = v[2]
			local q = quest_center:new(v2.id)
			q:setup(v2)
			quest_centers[q.id] = q
			table.remove(cfg, i)
		end
		if v[1] == "quest" then
			local v2 = v[2]
			local q = quest:new(v2.id)
			q:setup(v2, scenario_id)
			quests[q.id] = q
			table.remove(cfg, i)
		end
	end
	old_on_load(cfg)
end

local old_on_save = game_events.on_save
function game_events.on_save(cfg)
	local custom_cfg = old_on_save()
	for i,v in pairs(quest_centers) do
		table.insert(custom_cfg, {"quest_center", v:dump()})
	end
	for i,v in pairs(quests) do
		table.insert(custom_cfg, {"quest", v:dump()})
	end
	return custom_cfg
end