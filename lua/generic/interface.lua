--! Functions etc. related to the user interface.

local helper = wesnoth.require "lua/helper.lua"

local interface = {}

interface.markup = {
	bullet = "&#8226; ",
	color_prefix = function(r, g, b)
		-- cribbed from lua/wml/objectives.lua
		return string.format('<span foreground="#%02x%02x%02x">', r, g, b)
	end,
	color_suffix = function() return "</span>" end,
	concat = function(...)
		-- Concatanate strings and userdata.
		local s = ""
		for i=1,#arg do
			s = s .. arg[i]
		end
		return s
	end,
	message = function(image, message, speaker)
		if message == nil and speaker == nil then
			message = image
			image = "wesnoth-icon.png"
		end
		if speaker == nil then speaker = 'narrator' end
		wesnoth.fire("message", {speaker=speaker, image=image, message=message})
	end,
	dialog = function(cfg, options)
		-- cfg is an (img, msg, speaker) table; options is a table of tables
		-- containing an option and a function.
		local o = {}
		local f = {}
		for i=1,#options do
			table.insert(o, _(options[i].opt))
			table.insert(f, options[i].func)
		end
		choice = helper.get_user_choice(cfg, o)
		f[choice]()
	end
}
local m = interface.markup

function m.tag(name, str) return m.concat("<", name, ">", str, "</", name, ">") end
function m.small(str) return m.tag("small", str) end
function m.big(str) return m.tag("big", str) end
function m.color(r, g, b, ...) return m.concat(m.color_prefix(r,g,b), m.concat(arg), m.color_suffix()) end

interface.message