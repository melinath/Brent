local helper = wesnoth.require("lua/helper.lua")

local interface = modular.require("interface")
local units = modular.require("units")

local objectives = modular.require("objectives", "Brent")
local quests = modular.require("quests", "Brent")
local _ = wesnoth.textdomain("wesnoth-Brent")


local return_bones = objectives.manual:init({
    description = _("Return Laeren Markner's bones to his family in Port Meiren"),
})


local quest = quests.quest:init({
    id = "return_bones",
    path = "skeleton_note/01_return_bones",
    name = _("Last Request"),
    portrait = "portraits/story/bones.png",
    reward = {
        experience = 8,
        gold = 20
    },

    success_objectives = {
        return_bones,
    },

    read_journal = function(self)
        self:set_var("has_read")
        local c = wesnoth.current.event_context
        local unit = wesnoth.get_unit(c.x1, c.y1)
        interface.message("portraits/story/journal.png",
                          string.format("It seems to be some sort of journal... %s begins reading", unit.name))
        interface.message("portraits/story/journal.png",
                          "The bones belong to an explorer named Laeran Markner. According to his journal, he has spent decades searching for his wife, who disappeared under mysterious circumstances.")
        interface.message("portraits/story/journal.png",
                          "His last entry reads, 'I've fallen and my leg snapped like a twig. I'm too old. The wolves are coming. Please, if you find my remains, take them back to my family in Port Meiren.'")
        interface.message("portraits/story/journal.png",
                          string.format("The script is hasty and hard to read, and looking down, %s notices gnaw marks on the bones.", unit.name))
    end,

    intro = function(self)
        local c = wesnoth.current.event_context
        local unit = wesnoth.get_unit(c.x1, c.y1)
        local has_read = self:get_var("has_read")
        local has_seen = self:get_var("has_seen")
        if not has_seen then
            self:set_var("has_seen")
            interface.message("portraits/story/backpack.png",
                              string.format("%s finds a tattered oilskin backpack among the scattered bones.",
                                            unit.name))
            interface.message("portraits/story/backpack.png",
                              "There's a book inside.")
            if units.has_advance(unit, "reading") then
                self:read_journal()
                self:offer()
            else
                interface.message("portraits/story/confusion.png",
                                  string.format("Unable to read the book, %s puts it back.", unit.name))
            end
        else
            if has_read then
                interface.message("portraits/story/backpack.png",
                                  "Laeran Markner's backpack is lying here among his bones.")
                interface.message("portraits/story/bones.png",
                                  string.format("They seem a bit more scattered and gnawed-on than %s remembers.", unit.name))
                self:offer()
            else
                interface.message("portraits/story/backpack.png",
                                  "The tattered oilskin backpack is still lying here among scattered bones.")
                interface.message("portraits/story/backpack.png",
                                  string.format("%s pulls the book out of the backpack.", unit.name))
                if units.has_advance(unit, "reading") then
                    self:read_journal()
                    self:offer()
                else
                    interface.message("portraits/story/confusion.png",
                                      string.format("Unable to read the book, %s puts it back.", unit.name))
                end
            end
        end
    end,

    offer = function(self)
        local c = wesnoth.current.event_context
        local unit = wesnoth.get_unit(c.x1, c.y1)

        interface.menu:init({
            message="Do you take his bones?",
            options = {
                {"Yes, I'll take his bones.", function()
                    self:start()
                    local center = modular.require("centers/alden_forest/skeleton", "Brent")
                    center:setup()
                end},
                {"I don't have time right now!", function()
                    interface.message(string.format("%s puts the book back.", unit.name))
                end},
                {"I'd like to look at the journal again.", function()
                    self:read_journal()
                    self:offer()
                end},
            }
        }):display()
    end,
})

return quest