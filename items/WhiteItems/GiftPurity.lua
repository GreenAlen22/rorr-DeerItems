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
-- При использовании утилитарного скилла: барьер, зависящий от базового кулдауна навыка.
-- Чем длиннее кулдаун (т.е. чем реже доступен барьер), тем он больше — это уравнивает
-- ценность предмета у персонажей с коротким и длинным КД третьего навыка.
item:onUtilityUse(function(actor, stack)
	local utility = actor:get_active_skill(Skill.SLOT.utility)
	-- cooldown хранится в кадрах (60 к/с) → переводим в секунды
	local cd_seconds = (utility.cooldown or 0) / 60
	-- 1.5% от макс. HP за каждую секунду кулдауна (+0.5% за стак сверх первого)
	local pct = 0.015 + 0.005 * (stack - 1)
	actor:add_barrier(actor.maxhp * pct * cd_seconds)
end)
