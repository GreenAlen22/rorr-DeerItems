-- DeerItems-LootFever / «Лихорадка добычи» / "Loot Fever"
-- Подбор любого предмета даёт стак «азарта»: +3% к основным характеристикам на 20 сек.
-- Стаки тикают по отдельности (как BloodyRelic); кап растёт с числом предметов.

-- Иконка предмета и иконка баффа (заглушки-шаблоны — замени текстуры по этим путям).
local sprite      = Resources.sprite_load("DeerItems", "item/LootFever", PATH.."assets/sprites/items/sGreenItems/LootFever.png", 1, 16, 16)
local buff_sprite = Resources.sprite_load("DeerItems", "buff/LootFever", PATH.."assets/sprites/buffs/LootFever.png", 1, 7, 10)

-- guid мода: ускоряет get_data
local GUID = _ENV["!guid"]

-- ── Баланс ──
local PER_STACK    = 0.03      -- +3% к характеристикам за каждый стак азарта
local DURATION     = 20 * 60   -- каждый стак живёт 20 секунд
local BASE_CAP     = 4         -- макс. стаков при 1 шт. предмета
local CAP_PER_ITEM = 2         -- +2 к капу за каждую доп. шт.

-- Предмет
local item = Item.new("DeerItems", "LootFever")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

-- Бафф «азарт»: стаки храним сами (is_timed=false), таймеры ведём вручную — как BloodyRelic.
local buff = Buff.new("DeerItems", "LootFever")
buff.icon_sprite         = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number   = true
buff.stack_number_col    = Array.new(1, Color(0xffd24a))
buff.is_timed  = false
buff.max_stack = 999
buff:clear_callbacks()

-- Каждое применение баффа добавляет отдельный таймер на DURATION кадров
buff:onApply(function(actor, stack)
    local data = actor:get_data("LootFever", GUID)
    if not data.timers then data.timers = {} end
    table.insert(data.timers, DURATION)
end)

-- Тик таймеров: истёкшие стаки снимаем; сверху держим кап по числу предметов
buff:onPostStep(function(actor, stack)
    local data = actor:get_data("LootFever", GUID)
    local maxAllowed = BASE_CAP + CAP_PER_ITEM * (actor:item_stack_count(item) - 1)
    if data.timers then
        for i = #data.timers, 1, -1 do
            data.timers[i] = data.timers[i] - 1
            if data.timers[i] <= 0 then
                table.remove(data.timers, i)
                actor:buff_remove(buff, 1)
            end
        end
        -- Снимаем лишние стаки сверх лимита (если число предметов уменьшилось)
        if stack > maxAllowed then
            local overflow = stack - maxAllowed
            for i = 1, overflow do table.remove(data.timers, 1) end
            actor:buff_remove(buff, overflow)
        end
    end
    if stack == 0 and data.timers then data.timers = {} end
end)

-- +3% к основным характеристикам за стак
buff:onStatRecalc(function(actor, stack)
    local mult = 1 + PER_STACK * stack
    actor.damage       = actor.damage * mult
    actor.attack_speed = actor.attack_speed * mult
    actor.pHmax        = actor.pHmax * mult
    actor.hp_regen     = actor.hp_regen * mult
end)

-- Любой подобранный предмет добавляет стак (только держателям предмета, на хосте)
Player:onPickupCollected("DeerItems-LootFever", function(actor, pickup_instance)
    if not (actor and Instance.exists(actor)) then return end
    if not gm._mod_net_isHost() then return end
    if actor:item_stack_count(item) <= 0 then return end
    -- ограничение по капу проверяет buff:onPostStep; здесь просто докидываем стак
    actor:buff_apply(buff, 1, 1)
end)
