-- DeerItems-GearFeather
-- Этот предмет увеличивает максимальную скорость персонажа (pVmax) на 7% за каждый стак.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/GearFeather", PATH.."assets/sprites/items/sWhiteItems/GearFeather.png", 1, 16, 16)

-- Создание нового предмета с названием "GearFeather" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("GearFeather")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Обработка пересчёта статистики при получении предмета
item:onStatRecalc(function(actor, stack)
    -- Увеличение максимальной скорости (pVmax) на 7% за стак
    actor.pVmax = actor.pVmax + (actor.pVmax * (0.07 * stack))
end)