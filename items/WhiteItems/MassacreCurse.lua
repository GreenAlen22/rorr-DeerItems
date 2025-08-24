-- DeerItems-MassacreCurse
-- После 3 убийств подряд даёт бафф, усиливающий урон и броню. Длительность стаков зависит от количества предметов.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/MassacreCurse", PATH.."assets/sprites/items/sWhiteItems/MassacreCurse.png", 1, 16, 16)

-- Создание предмета MassacreCurse
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "MassacreCurse")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- При получении предмета инициализируем счётчик убийств
item:onAcquire(function(actor, stack)
    local actorData = actor:get_data("MassacreCurse")
    if not actorData.count then
        actorData.count = 0
    end
end)

-- При убийстве увеличиваем счётчик и выдаём бафф при достижении 3
item:onKillProc(function(actor, victim, stack)
    local buff = Buff.find("DeerItems-MassacreCurse")
    local actorData = actor:get_data("MassacreCurse")

    actorData.count = actorData.count + 1

    if actorData.count >= 3 then
        local count = 1
        -- Если баффа не было вообще — даём сразу 3 стака
        if actor:buff_stack_count(buff) <= 0 then
            count = 3
        end

        actor:buff_apply(buff, 1, count)
    end
end)

-- Buff: MassacreCurse
-- Долгосрочный бафф, усиливающий урон и броню, стаки удаляются по истечению времени

-- Загружаем спрайт баффа
local sprite = Resources.sprite_load("DeerItems", "buff/MassacreCurse", PATH.."assets/sprites/buffs/MassacreCurse.png", 1, 7, 7)

-- Создание баффа
local buff = Buff.new("DeerItems", "MassacreCurse")
buff.icon_sprite = sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0xa0735b))
buff.max_stack = 999
buff.is_timed = false

-- При добавлении стака — добавляем таймер его действия
buff:onApply(function(actor, stack)
    local actorData = actor:get_data("MassacreCurse")
    if not actorData.timers then actorData.timers = {} end
    -- Каждому стаку даётся время действия: 2.5 сек * количество предметов
    table.insert(actorData.timers, (2.5 * actor:item_stack_count(item)) * 60.0)
end)

-- Постобновление: уменьшаем таймеры, удаляем стеки, если истекли
buff:onPostStep(function(actor, stack)
    local actorData = actor:get_data("MassacreCurse")
    -- Обновляем каждый таймер
    for i, time in ipairs(actorData.timers) do
        actorData.timers[i] = time - 1
        if time <= 0 then
            table.remove(actorData.timers, i)
        end
    end

    -- Если таймеров меньше, чем стаков — удаляем лишние стаки
    if stack > #actorData.timers then
        local diff = stack - #actorData.timers
        actor:buff_remove(buff, diff)
        actor:recalculate_stats()
    end

    -- Если стаков больше нет — сбрасываем счётчик убийств
    if stack == 0 then
        actorData.count = 0
    end
end)

-- Увеличиваем урон и броню на 3% за стак
buff:onStatRecalc(function(actor, stack)
    actor.damage = actor.damage + ((actor.damage * 0.03) * stack)
    actor.armor  = actor.armor  + ((actor.armor  * 0.03) * stack)
end)
