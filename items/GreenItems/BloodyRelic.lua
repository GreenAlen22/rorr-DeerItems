-- DeerItems-BloodyRelic
-- 10% шанс при ударе дать бафф на 8 сек, увеличивающий скорость атаки. Макс. баффов: 5 + количество предметов.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/BloodyRelic", PATH.."assets/sprites/items/sGreenItems/BloodyRelic.png", 1, 16, 16)

-- Создание предмета BloodyRelic
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "BloodyRelic")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Загружаем спрайт баффа
local buff_sprite = Resources.sprite_load("DeerItems", "buff/BloodyRelic", PATH.."assets/sprites/buffs/BloodyRelic.png", 1, 7, 10)

-- Создание баффа BloodyRelic
local buff = Buff.new("DeerItems", "BloodyRelic")
buff.icon_sprite = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0x870c0c))
buff.is_timed = false
buff.max_stack = 999

-- При применении баффа — создаём таймер его действия (8 секунд)
buff:onApply(function(actor, stack)
    local data = actor:get_data("BloodyRelic")
    if not data.timers then
        data.timers = {}
    end
    table.insert(data.timers, 8 * 60)
end)

-- Каждый кадр: уменьшаем таймеры, удаляем истёкшие, ограничиваем стаки
buff:onPostStep(function(actor, stack)
    local data = actor:get_data("BloodyRelic")
    local item = Item.find("DeerItems-BloodyRelic")
    local maxAllowed = 5 + actor:item_stack_count(item)
    if data.timers then
        -- Обновление и удаление истекших таймеров
        for i = #data.timers, 1, -1 do
            data.timers[i] = data.timers[i] - 1
            if data.timers[i] <= 0 then
                table.remove(data.timers, i)
                actor:buff_remove(buff, 1)
            end
        end
        -- Принудительное удаление лишних стаков, если больше допустимого лимита
        if stack > maxAllowed then
            local overflow = stack - maxAllowed
            for i = 1, overflow do
                table.remove(data.timers, 1)
            end
            actor:buff_remove(buff, overflow)
        end
    end

    -- Если стаков больше нет — сбрасываем все таймеры
    if stack == 0 and data.timers then
        data.timers = {}
    end
end)

-- Бафф увеличивает скорость атаки на 5% за стак
buff:onStatRecalc(function(actor, stack)
    actor.attack_speed = actor.attack_speed + ((actor.attack_speed * 0.05) * stack)
end)

-- При попадании атакой с шансом 10% за стак накладываем бафф
item:onHitProc(function(actor, victim, stack, hit_info)
    if math.random() <= 0.1 * stack then
        actor:buff_apply(buff, 1)
    end
end)
