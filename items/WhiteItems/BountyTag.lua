-- DeerItems-BountyTag
-- Премия за голову: золото за убийство. Каждое убийство без полученного урона повышает выплату;
-- любой полученный урон обнуляет серию.
-- (Альтернатива Roll of Pennies: вместо «страдай = богатей» — «играй чисто = богатей».)

-- Спрайт предмета (без партиклов и звука по ТЗ)
local sprite = Sprite.new("item/BountyTag", PATH.."assets/sprites/items/sWhiteItems/BountyTag.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- Балансные константы
local GOLD_PER_STACK = 2    -- базовое золото за убийство за стак
local STREAK_BONUS   = 1    -- +1 золота за каждое убийство в серии
local STREAK_CAP     = 10   -- максимум бонуса от серии

-- Создание предмета: белый тир, тег «утилита»
local item = Item.new("BountyTag")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
-- Получение урона обнуляет серию
DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if attacker and actor == attacker then return end
    Instance.get_data(actor, "BountyTag", GUID).bt_streak = 0
end)

-- Убийство: начисляем золото и наращиваем серию. Оба колбэка зовёт только хост,
-- поэтому серия живёт у хоста, а держателю-клиенту золото уходит пакетом.
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    local data = Instance.get_data(actor, "BountyTag", GUID)
    local streak = data.bt_streak or 0

    -- Базовое золото + бонус серии (с капом), масштаб по времени через множитель цен
    local money = (GOLD_PER_STACK * stack + math.min(streak, STREAK_CAP) * STREAK_BONUS)
                * gm.cost_get_base_gold_price_scale()
    DeerItemsGold.pay(actor, money)

    data.bt_streak = streak + 1
end)
