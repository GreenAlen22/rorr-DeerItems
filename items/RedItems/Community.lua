-- DeerItems-Community
-- Увеличивает все характеристики пропорционально общему количеству предметов. Масштабируется на 1% за предмет * кол-во стаков.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/Community", PATH.."assets/sprites/items/sRedItems/Community.png", 1, 16, 16)

-- Создание предмета Community
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("Community")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Список всех предметов игры фиксирован после загрузки модов — ищем его один раз и кэшируем.
-- У игрока меняется лишь количество, поэтому item_count пересчитываем при каждом вызове.
local all_items
local function count_total_items(actor)
    all_items = all_items or Item.find_all()
    local total = 0
    for _, it in ipairs(all_items) do
        total = total + actor:item_count(it, Item.StackKind.ANY)
    end
    return total
end

-- Прирост maxhp ваниль доливает в hp сама (recalculate_stats: hp + maxhp - maxhp_old).
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
    local total_items = count_total_items(actor)

    -- Множитель: +1% за каждый предмет * количество стаков
    local mult = 1.0 + (0.01 * total_items * (stack or 1))

    api.attack_speed_mult(mult)
    api.critical_chance_mult(mult * 2) -- крит дополнительно удваивается
    api.damage_mult(mult)
    api.armor_add(total_items)         -- по 1 ед. брони за каждый предмет
    api.pHmax_mult(mult)
    api.hp_regen_mult(mult * 2)        -- реген усиливается дополнительно
    api.maxhp_mult(mult)
end)
