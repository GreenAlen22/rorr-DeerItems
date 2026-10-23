-- DeerItems-LootFever / «Лихорадка добычи» / "Loot Fever"
-- Подбор предмета даёт временный бонус к основным характеристикам.
-- Размер бонуса зависит от редкости, таймеры тикают отдельно, итоговый бонус ограничен числом предметов.

-- Иконка предмета и иконка баффа (заглушки-шаблоны — замени текстуры по этим путям).
local sprite      = Sprite.new("item/LootFever", PATH.."assets/sprites/items/sGreenItems/LootFever.png", 1, 18, 18)
local buff_sprite = Sprite.new("buff/LootFever", PATH.."assets/sprites/buffs/LootFever.png", 1, 7, 10)

-- guid мода: ускоряет get_data
local GUID = _ENV["!guid"]

-- Настройки баланса
local DURATION     = 20 * 60   -- каждый стак живёт 20 секунд
local DURATION_STACK = 20 * 60 -- +20 секунд за шт.
local CAP_PER_ITEM = 0.15      -- макс. бонус к характеристикам за шт.

-- Предмет
local item = Item.new("LootFever")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
-- Бафф «азарт»: стаки храним сами (is_timed=false), таймеры ведём вручную — как BloodyRelic.
local buff = Buff.new("LootFever")
buff.icon_sprite         = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number   = true
buff.stack_number_col    = Array.new(1, Color(0xffd24a))
buff.is_timed  = false
buff.max_stack = 999
-- Каждое применение баффа добавляет отдельный таймер на DURATION кадров
DeerItemsCallbacks.buff_apply(buff, function(actor, stack)
    local data = Instance.get_data(actor, "LootFever", GUID)
    if not data.timers then data.timers = {} end
    local item_stack = actor:item_count(item) or 1
    table.insert(data.timers, {
        time = DURATION + DURATION_STACK * (item_stack - 1),
        bonus = data.pending_bonus or 0.02,
    })
    data.pending_bonus = nil
end)

-- Тик таймеров: истёкшие стаки снимаем; сверху держим кап по числу предметов
DeerItemsCallbacks.buff_post_step(buff, function(actor, stack)
    local data = Instance.get_data(actor, "LootFever", GUID)
    if data.timers then
        for i = #data.timers, 1, -1 do
            data.timers[i].time = data.timers[i].time - 1
            if data.timers[i].time <= 0 then
                table.remove(data.timers, i)
                actor:buff_remove(buff, 1)
            end
        end
    end
    if stack == 0 and data.timers then data.timers = {} end
end)

-- Суммарный бонус к основным характеристикам, ограниченный капом.
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack, api)
    local data = Instance.get_data(actor, "LootFever", GUID)
    local total = 0
    for _, entry in ipairs(data.timers or {}) do
        total = total + (entry.bonus or 0)
    end

    local cap = CAP_PER_ITEM * (actor:item_count(item) or 1)
    local mult = 1 + math.min(total, cap)
    api.damage_mult(mult)
    api.attack_speed_mult(mult)
    api.pHmax_mult(mult)
    api.hp_regen_mult(mult)
end)

local function item_from_pickup(pickup)
    if not (pickup and Instance.exists(pickup)) then return nil end

    local object_id = pickup.object_index
    if object_id and gm.object_to_item then
        local ok, item_id = pcall(gm.object_to_item, object_id)
        if ok and item_id and item_id >= 0 then
            return Item.wrap(item_id)
        end
    end

    for _, key in ipairs({ "item", "item_id", "item_index" }) do
        local item_id = pickup[key]
        if type(item_id) == "number" and item_id >= 0 then
            local ok, picked = pcall(Item.wrap, item_id)
            if ok and picked then return picked end
        end
    end

    return nil
end

local function bonus_for_pickup(pickup)
    local picked = item_from_pickup(pickup)
    local tier = picked and picked.tier

    if tier == ItemTier.COMMON then return 0.02 end
    if tier == ItemTier.UNCOMMON then return 0.04 end
    if tier == ItemTier.EQUIPMENT then return 0.06 end
    if tier == ItemTier.RARE or tier == ItemTier.BOSS then return 0.08 end

    return 0.02
end

-- Любой подобранный предмет добавляет временный бонус (только держателям предмета, на хосте).
DeerItemsCallbacks.item_pickup_collected(item, function(actor, stack, pickup_instance)
    if not (actor and Instance.exists(actor)) then return end
    if not Net.host then return end
    if stack <= 0 then return end

    Instance.get_data(actor, "LootFever", GUID).pending_bonus = bonus_for_pickup(pickup_instance)
    actor:buff_apply(buff, 1, 1)
end)
