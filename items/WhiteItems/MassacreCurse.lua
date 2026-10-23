-- DeerItems-MassacreCurse
-- После 3 убийств подряд даёт бафф, усиливающий урон и броню. Длительность стаков зависит от количества предметов.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/MassacreCurse", PATH.."assets/sprites/items/sWhiteItems/MassacreCurse.png", 1, 16, 17)

-- Создание предмета MassacreCurse
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("MassacreCurse")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- guid мода (ускоряет get_data) и ленивый кэш ссылки на бафф
local GUID = _ENV["!guid"]
local massacreBuff

-- При получении предмета инициализируем счётчик убийств
DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    local actorData = Instance.get_data(actor, "MassacreCurse", GUID)
    if not actorData.count then
        actorData.count = 0
    end
end)

-- При убийстве увеличиваем счётчик и выдаём бафф при достижении 3
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if not Net.host then return end

    massacreBuff = massacreBuff or Buff.find("MassacreCurse", "DeerItems")
    local buff = massacreBuff
    local actorData = Instance.get_data(actor, "MassacreCurse", GUID)

    actorData.count = actorData.count + 1

    if actorData.count >= 3 then
        local count = 1
        -- Если баффа не было вообще — даём сразу 3 стака
        if actor:buff_count(buff) <= 0 then
            count = 3
        end

        actor:buff_apply(buff, 1, count)
    end
end)

-- Бафф предмета MassacreCurse.
-- Долгосрочный бафф, усиливающий урон и броню, стаки удаляются по истечению времени

-- Загружаем спрайт баффа
local sprite = Sprite.new("buff/MassacreCurse", PATH.."assets/sprites/buffs/MassacreCurse.png", 1, 7, 7)

-- Создание баффа
local buff = Buff.new("MassacreCurse")
buff.icon_sprite = sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0xa0735b))
buff.max_stack = 999
buff.is_timed = false

-- При добавлении стака — добавляем таймер его действия
DeerItemsCallbacks.buff_apply(buff, function(actor, stack)
    local actorData = Instance.get_data(actor, "MassacreCurse", GUID)
    if not actorData.timers then actorData.timers = {} end
    -- Каждому стаку даётся время действия: 2.5 сек * количество предметов
    table.insert(actorData.timers, (2.5 * actor:item_count(item)) * 60.0)
end)

-- Постобновление: уменьшаем таймеры, удаляем стеки, если истекли
DeerItemsCallbacks.buff_post_step(buff, function(actor, stack)
    local actorData = Instance.get_data(actor, "MassacreCurse", GUID)
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
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack, api)
    api.damage_mult(1 + 0.03 * stack)
    api.armor_mult(1 + 0.03 * stack)
end)
