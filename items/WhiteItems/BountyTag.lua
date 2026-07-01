-- DeerItems-BountyTag
-- Премия за голову: золото за убийство. Каждое убийство без полученного урона повышает выплату;
-- любой полученный урон обнуляет серию.
-- (Альтернатива Roll of Pennies: вместо «страдай = богатей» — «играй чисто = богатей».)

-- Спрайт предмета (без партиклов и звука по ТЗ)
local sprite = Resources.sprite_load("DeerItems", "item/BountyTag", PATH.."assets/sprites/items/sWhiteItems/BountyTag.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- Балансные константы
local GOLD_PER_STACK = 2    -- базовое золото за убийство за стак
local STREAK_BONUS   = 1    -- +1 золота за каждое убийство в серии
local STREAK_CAP     = 10   -- максимум бонуса от серии

-- Создание предмета: белый тир, тег «утилита»
local item = Item.new("DeerItems", "BountyTag")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

item:clear_callbacks()

-- Получение урона обнуляет серию
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if attacker and actor:same(attacker) then return end
    actor:get_data("BountyTag", GUID).bt_streak = 0
end)

-- Убийство: начисляем золото и наращиваем серию
item:onKillProc(function(actor, victim, stack)
    -- Золото — только локальному игроку (HUD-золото клиентское)
    if not actor:same(Player.get_client()) then return end

    local data = actor:get_data("BountyTag", GUID)
    local streak = data.bt_streak or 0

    -- Базовое золото + бонус серии (с капом), масштаб по времени через множитель цен
    local money = (GOLD_PER_STACK * stack + math.min(streak, STREAK_CAP) * STREAK_BONUS)
                * gm.cost_get_base_gold_price_scale()
    local hud = GM._mod_game_getHUD()
    if hud ~= -4 then
        hud.gold = hud.gold + money
    end

    data.bt_streak = streak + 1
end)
