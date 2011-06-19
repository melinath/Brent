local units = modular.require "units"


function units.get_pronouns(unit)
	gender = unit.__cfg.gender
	if gender == "male" then
		return {nom='he',acc='him',pos='his'}
	elseif gender == "female" then
		return {nom='she',acc='her',pos='hers'}
	else
		return {nom='ze',acc='hir',pos='hirs'}
	end
end


return units