-- DeerItems-Community
-- Увеличивает все характеристики пропорционально общему количеству предметов. Масштабируется на 1% за предмет * кол-во стаков.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/Community", PATH.."assets/sprites/items/sRedItems/Community.png", 1, 16, 16)

-- Создание предмета Community
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "Community")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Очистка старых коллбеков
item:clear_callbacks()
-- Перерасчёт основных характеристик
item:onStatRecalc(function(actor, stack)
    -- Подсчёт всех предметов
    local total_items = 0
    local all_items = Item.find_all()
    for _, it in ipairs(all_items) do
        total_items = total_items + actor:item_stack_count(it, Item.STACK_KIND.any)
    end

    -- Множитель: +1% за каждый предмет * количество стаков
    local mult = 1.0 + (0.01 * total_items * (stack or 1))

    actor.attack_speed    = actor.attack_speed * mult
    actor.critical_chance = actor.critical_chance * mult * 2 -- крит дополнительно удваивается
    actor.damage          = actor.damage * mult
    actor.armor           = actor.armor + total_items        -- по 1 ед. брони за каждый предмет
    actor.pHmax           = actor.pHmax * mult
    actor.hp_regen        = actor.hp_regen * mult * 2        -- реген усиливается дополнительно
    actor.maxhp           = math.ceil(actor.maxhp * mult)
end)

-- До пересчёта: сохраняем старые значения maxhp и текущего HP
local maxhp_old
local hp_old
gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
	maxhp_old = self.maxhp
	hp_old = self.hp
end)

-- После пересчёта: компенсируем изменение maxhp, чтобы не потерять здоровье
item:onPostStatRecalc(function(actor, stack)
	local total_items = 0
    local all_items = Item.find_all()
    for _, it in ipairs(all_items) do
        total_items = total_items + actor:item_stack_count(it, Item.STACK_KIND.any)
    end

    local mult = 1.0 + (0.01 * total_items * (stack or 1))

    -- Повторно задаём maxhp для восстановления пропущенного изменения
	actor.maxhp = math.ceil(actor.maxhp * mult)

    -- Компенсация HP: текущий HP + разница между новым и старым maxhp
	local hp_restore = hp_old - actor.hp
	actor.hp = math.min(actor.maxhp, actor.hp + math.max(0, actor.maxhp - maxhp_old + hp_restore))
end)
