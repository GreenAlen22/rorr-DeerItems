-- DeerItems-GiftPurity
-- Предмет уменьшает кулдаун утилитарного скилла и даёт барьер при его использовании.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/GiftPurity", PATH.."assets/sprites/items/sWhiteItems/GiftPurity.png", 1, 16, 16)

-- Создание нового предмета с названием "GiftPurity" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("GiftPurity")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Пересчёт статов: уменьшение кулдауна утилитарного скилла на 5% за стак
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
	api.skill_utility.cooldown_mult(0.95 ^ stack)
end)
-- При использовании утилитарного скилла: барьер, зависящий от базового кулдауна навыка.
-- Чем длиннее кулдаун (т.е. чем реже доступен барьер), тем он больше — это уравнивает
-- ценность предмета у персонажей с коротким и длинным КД третьего навыка.
DeerItemsCallbacks.item_utility_use(item, function(actor, stack)
	local utility = actor:get_active_skill(Skill.Slot.UTILITY)
	-- cooldown хранится в кадрах (60 к/с) → переводим в секунды
	local cd_seconds = (utility.cooldown or 0) / 60
	-- 1.5% от макс. HP за каждую секунду кулдауна (+0.5% за стак сверх первого)
	local pct = 0.015 + 0.005 * (stack - 1)
	-- heal_barrier сам выходит на клиенте; хост выдаёт барьер и рассылает его.
	actor:heal_barrier(actor.maxhp * pct * cd_seconds)
end)
