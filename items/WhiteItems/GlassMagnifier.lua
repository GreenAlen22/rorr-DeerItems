-- DeerItems-GlassMagnifier
-- Increases drone base damage.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/GlassMagnifier", PATH.."assets/sprites/items/sWhiteItems/GlassMagnifier.png", 1, 16, 16)

local GUID = _ENV["!guid"]
local oP = gm.constants.oP

local DRONE_DMG_BASE = 1
local DRONE_DMG_STACK = 3
local DRONE_RADIUS = 100000

local g_team_stack = {}

local function recalc_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP then
            char:recalculate_stats()
        end
    end
end

-- Создание нового предмета с названием "GlassMagnifier" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "GlassMagnifier")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Keep owner stacks available for drone stat recalculation.
item:onStatRecalc(function(actor, stack)
    if stack > 0 then g_team_stack[actor.team] = stack end
end)

item:onAcquire(function(actor, stack)
    g_team_stack[actor.team] = stack
    recalc_drones(actor)
end)

item:onRemove(function(actor, stack)
    if stack <= 1 then g_team_stack[actor.team] = nil end
end)

item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    g_team_stack[actor.team] = stack

    local data = actor:get_data("GlassMagnifier", GUID)
    if data.gm_last_stack ~= stack then
        data.gm_last_stack = stack
        recalc_drones(actor)
    end
end)

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end
    self.damage = self.damage + DRONE_DMG_BASE + DRONE_DMG_STACK * s
end)
