-- DeerItems-GiftPurity
-- Предмет уменьшает кулдаун утилитарного скилла и даёт барьер при его использовании.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/GiftPurity", PATH.."assets/sprites/items/sWhiteItems/GiftPurity.png", 1, 16, 16)

-- Создание нового предмета с названием "GiftPurity" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "GiftPurity")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Очистка всех предыдущих коллбеков предмета (важно для перезагрузки логики)
item:clear_callbacks()
-- Пересчёт статов: уменьшение кулдауна утилитарного скилла на 5% за стак
item:onStatRecalc(function(actor, stack)
	local utility = actor:get_active_skill(Skill.SLOT.utility)
	utility.cooldown = math.ceil(utility.cooldown * (0.95 ^ stack))
end)
-- При использовании утилитарного скилла: добавление барьера
item:onUtilityUse(function(actor, stack)
	actor:add_barrier(15 + 10 * stack)
end)
