-- DeerItems-PainTax
-- Болевой тариф: при получении урона от врага даёт золото (8 за стак за удар), растёт со временем.
-- (Адаптация Roll of Pennies из RoR2.)

-- Спрайт предмета
-- Звук монеты (редкий шанс + защита от спама)
local sprite = Resources.sprite_load("DeerItems", "item/PainTax", PATH.."assets/sprites/items/sWhiteItems/PainTax.png", 1, 18, 18)
local coinSound = Resources.sfx_load("DeerItems", "sound/PainTax", PATH.."assets/sounds/PainTax.ogg")

local GUID = _ENV["!guid"]

-- Балансные константы
local GOLD_PER_STACK = 8     -- золото за стак за каждый удар
local SOUND_CHANCE   = 0.15  -- шанс звука при начислении
local SOUND_COOLDOWN = 60    -- минимум кадров между звуками (анти-спам, 1 сек)

-- Создание предмета: белый тир, тег «утилита»
local item = Item.new("DeerItems", "PainTax")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

item:clear_callbacks()

item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if stack <= 0 then return end
    -- Игнорируем урон от самого себя (например, своё же кровотечение)
    if attacker and actor:same(attacker) then return end
    -- Золото — только локальному игроку (HUD-золото клиентское)
    if not actor:same(Player.get_client()) then return end

    -- Сумма масштабируется глобальным множителем цен — «растёт со временем»
    local money = GOLD_PER_STACK * stack * gm.cost_get_base_gold_price_scale()
    local hud = GM._mod_game_getHUD()
    if hud ~= -4 then
        hud.gold = hud.gold + money
    end

    -- Звук с редким шансом и анти-спамом
    local data = actor:get_data("PainTax", GUID)
    local now = Global._current_frame
    if (now - (data.pt_last_sound or -SOUND_COOLDOWN)) >= SOUND_COOLDOWN and math.random() < SOUND_CHANCE then
        actor:sound_play(coinSound, 1.0, 0.95 + math.random() * 0.1)
        data.pt_last_sound = now
    end
end)
