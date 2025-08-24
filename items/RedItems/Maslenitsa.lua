-- DeerItems-Maslenitsa
-- DeerItems-Obereg
-- DeerItems-ShadowShield
-- ror-toughTimes
-- ror-repulsionArmor
-- ror-colossalKnurl
-- Даёт 25 брони за стак. Дополнительно даёт +2 брони за каждый предмет из списка “защитных”, начиная со второго стака.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/Maslenitsa", PATH.."assets/sprites/items/sRedItems/Maslenitsa.png", 1, 16, 16)

-- Создание предмета Maslenitsa
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("DeerItems", "Maslenitsa")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_survive)

-- Очистка старых коллбеков
item:clear_callbacks()

-- Перерасчёт брони
item:onStatRecalc(function(actor, stack)
    -- Список предметов, усиливающих бонус
    local bonus_items = {
        Item.find("ror", "toughTimes"),
        Item.find("ror", "repulsionArmor"),
        Item.find("ror", "colossalKnurl"),
        Item.find("DeerItems", "Obereg"),
        Item.find("DeerItems", "ShadowShield")
    }

    -- Подсчёт количества этих предметов у игрока
    local bonusCount = 0
    for _, it in ipairs(bonus_items) do
        bonusCount = bonusCount + actor:item_stack_count(it, Item.STACK_KIND.owned)
    end

    -- Базовая броня: +25 за стак
    -- Дополнительная броня: +2 за каждый предмет из списка на каждый стак после первого
    actor.armor = actor.armor + (25 * stack) + bonusCount * (2 * (stack - 1))
end)
