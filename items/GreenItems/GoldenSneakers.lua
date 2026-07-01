-- DeerItems-GoldenSneakers
-- Даёт бонус к скорости движения в зависимости от текущего золота: до +50% при достижении порога.
-- Порог золота — 700, масштабируется по времени (инфляция) и снижается вдвое за каждый стак.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/GoldenSneakers", PATH.."assets/sprites/items/sGreenItems/GoldenSneakers.png", 1, 16, 16)

-- guid мода выносим один раз — чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

-- Максимальный бонус к скорости (50%) и базовый порог золота для его достижения
local MAX_BONUS = 0.50
local BASE_GOLD = 700

-- Создание предмета GoldenSneakers
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "GoldenSneakers")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Пересчёт статов: бонус к pHmax пропорционален текущему золоту относительно порога.
-- Порог = 700 × инфляция золота × 0.5^(стак-1): со временем растёт, за стаки — снижается.
item:onStatRecalc(function(actor, stack)
    if stack <= 0 then return end

    local gold = actor.gold or 0
    if gold <= 0 then return end

    -- Порог золота для максимального бонуса
    local threshold = BASE_GOLD * gm.cost_get_base_gold_price_scale() * (0.5 ^ (stack - 1))

    -- Доля от капа (не больше 100%) и итоговый множитель скорости
    local ratio = math.min(1, gold / threshold)
    local bonus = MAX_BONUS * ratio

    -- Прибавка считается от базовой скорости (pHmax_base), а не от текущей:
    -- бонус не перемножается с другими % к скорости, поэтому общий потолок жёстче.
    actor.pHmax = actor.pHmax + actor.pHmax_base * bonus
end)

-- Золото меняется постоянно, а статы сами по себе так часто не пересчитываются.
-- Поэтому при изменении золота запускаем пересчёт статов, чтобы бонус оставался актуальным.
item:onPostStep(function(actor, stack)
    local data = actor:get_data("DeerItems", GUID)
    local gold = actor.gold or 0
    if data.gs_last_gold ~= gold then
        data.gs_last_gold = gold
        actor:recalculate_stats()
    end
end)
