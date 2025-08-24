-- DeerItems-GlassMagnifier
-- Предмет увеличивает базовый урон: +3 за первый стак и +2 за каждый последующий.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/GlassMagnifier", PATH.."assets/sprites/items/sWhiteItems/GlassMagnifier.png", 1, 16, 16)

-- Создание нового предмета с названием "GlassMagnifier" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "GlassMagnifier")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Обработка пересчёта статистики при получении предмета
item:onStatRecalc(function(actor, stack)
    -- Увеличение урона: +3 базово и +2 за каждый стак
    actor.damage = actor.damage + 3 + (2 * stack)
end)
