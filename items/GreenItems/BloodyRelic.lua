-- DeerItems-BloodyRelic
-- 10% шанс при ударе дать бафф на 8 сек, увеличивающий скорость атаки. Макс. баффов: 5 + количество предметов.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/BloodyRelic", PATH.."assets/sprites/items/sGreenItems/BloodyRelic.png", 1, 16, 17)

-- Создание предмета BloodyRelic
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("BloodyRelic")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- guid мода: ускоряет get_data (без обхода debug-стека на каждом кадре)
local GUID = _ENV["!guid"]
local PROC_CHANCE_PER_STACK = 0.10

local function hyperbolic_chance(stack)
    if stack <= 0 then return 0 end
    return 1 - (1 - PROC_CHANCE_PER_STACK) ^ stack
end

-- Загружаем спрайт баффа
local buff_sprite = Sprite.new("buff/BloodyRelic", PATH.."assets/sprites/buffs/BloodyRelic.png", 1, 7, 10)

-- Создание баффа BloodyRelic
local buff = Buff.new("BloodyRelic")
buff.icon_sprite = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0x870c0c))
buff.is_timed = false
buff.max_stack = 999

-- При применении баффа — создаём таймер его действия (8 секунд)
DeerItemsCallbacks.buff_apply(buff, function(actor, stack)
    local data = Instance.get_data(actor, "BloodyRelic", GUID)
    if not data.timers then
        data.timers = {}
    end
    table.insert(data.timers, 8 * 60)
end)

-- Каждый кадр: уменьшаем таймеры, удаляем истёкшие, ограничиваем стаки
DeerItemsCallbacks.buff_post_step(buff, function(actor, stack)
    local data = Instance.get_data(actor, "BloodyRelic", GUID)
    local maxAllowed = 5 + actor:item_count(item)
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
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack, api)
    api.attack_speed_mult(1 + 0.05 * stack)
end)

-- При попадании: 20% за первый предмет, затем убывающий прирост шанса.
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end

    if math.random() <= hyperbolic_chance(stack) then
        actor:buff_apply(buff, 1)
    end
end)
