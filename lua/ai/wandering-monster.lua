return {
	init = function(ai)
		local new_ai = {}

		function new_ai:wander_units_eval(score)
            local units = wesnoth.get_units({
                side = wesnoth.current.side,
                formula = '$this_unit.moves > 0'
            })

            local any_reach = false

        	for i, unit in ipairs(units) do
        		local reach = wesnoth.find_reach(unit)
        		if reach[1] then
        			any_reach = true
        			break
        		end
            end
            if any_reach then return score end
            return 0
		end

		function new_ai:wander_units_exec()
            local units = wesnoth.get_units({
                side = wesnoth.current.side,
                formula = '$this_unit.moves > 0'
            })
            for i, unit in ipairs(units) do
            	local reach = wesnoth.find_reach(unit)
            	local min_moves_left = unit.max_moves
            	local max_triples = {}
            	for j, triple in ipairs(reach) do
            		if triple[3] < min_moves_left then
            			max_triples = {}
            			min_moves_left = triple[3]
            		end
            		if triple[3] == min_moves_left then
            			table.insert(max_triples, triple)
            		end
            	end

            	if #max_triples > 0 then
            		local k = math.random(1, #max_triples)
            		local x, y = max_triples[k][1], max_triples[k][2]
            		ai.move_full(unit, x, y)
            	end
            end
		end

		return new_ai
	end
}