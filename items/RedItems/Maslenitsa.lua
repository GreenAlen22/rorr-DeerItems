-- DeerItems-Maslenitsa
-- Защитный предмет, который учитывает предметы из заданного списка при расчёте брони.
-- Даёт 15 брони за стак. Дополнительно даёт +2 (+3 за стак) брони за каждый предмет из списка “защитных”, начиная со второго стака.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/Maslenitsa", PATH.."assets/sprites/items/sRedItems/Maslenitsa.png", 1, 16, 16)

-- Создание предмета Maslenitsa
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("DeerItems", "Maslenitsa")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- Очистка старых коллбеков
item:clear_callbacks()

-- ленивый кэш ссылок на предметы: ищем один раз при первом пересчёте
-- (на загрузке часть предметов ещё может быть не зарегистрирована)
local bonus_items

-- Перерасчёт брони
item:onStatRecalc(function(actor, stack)
    -- Список предметов, усиливающих бонус (ищем один раз и кэшируем)
    if not bonus_items then
        bonus_items = {
            Item.find("ror", "toughTimes"),
            Item.find("ror", "repulsionArmor"),
            Item.find("ror", "colossalKnurl"),
            Item.find("DeerItems", "Obereg"),
            Item.find("DeerItems", "ShadowShield"),
            Item.find("DeerItems", "FacetedJade"),
            Item.find("DeerItems", "NewtonsMechanism")
        }
    end

    -- Подсчёт количества этих предметов у игрока
    local bonusCount = 0
    for _, it in ipairs(bonus_items) do
        bonusCount = bonusCount + actor:item_stack_count(it, Item.STACK_KIND.normal)
    end

    -- Базовая броня: +15 за стак
    -- Дополнительная броня: +2 (+3 за стак) за каждый предмет из списка на каждый стак после первого
    actor.armor = actor.armor + (15 * stack) + bonusCount * (1 +(2* (stack - 1)))
end)
