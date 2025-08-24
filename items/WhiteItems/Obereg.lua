-- DeerItems-Obereg
-- Даёт +30 брони за стак, если здоровье персонажа ≤ 50% от максимума.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/Obereg", PATH.."assets/sprites/items/sWhiteItems/Obereg.png", 1, 16, 16)

-- Создание предмета Obereg
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("DeerItems", "Obereg")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- Пересчёт брони после базового расчёта статистики
item:onPostStatRecalc(function(actor, stack)
    -- Если текущее здоровье ≤ 50% от максимального — даём бонус к броне
    if actor.hp <= actor.maxhp * 0.50 then
        actor.armor = actor.armor + (30 * stack)
    end
end)
