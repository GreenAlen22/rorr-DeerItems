-- DeerItems-ShieldGenerator
-- Увеличивает максимальный щит персонажа на 5% от максимального HP за стак (с базой +5%).

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/ShieldGenerator", PATH.."assets/sprites/items/sWhiteItems/ShieldGenerator.png", 1, 16, 16)

-- Создание предмета ShieldGenerator
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("DeerItems", "ShieldGenerator")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- Перерасчёт щита при изменении стаков
item:onStatRecalc(function(actor, stack)
    -- Бонусный щит = (5% + 5% за стак) от максимального HP
    actor.maxshield = actor.maxshield + (actor.maxhp * (0.05 + 0.05 * stack))
end)
