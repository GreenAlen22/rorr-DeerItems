-- DeerItems-Tankbuster
-- Tankbuster: не чаще раза в 7 секунд при попадании наносит тяжёлый добавочный удар —
-- 40% (+20% за стак) от урона игрока ПЛЮС 2% (+1% за стак) от макс. HP цели.
-- (Альтернатива Armor-Piercing Rounds: вместо «только боссам» — анти-танковый удар по любому жирному.)

-- Спрайт предмета (без партиклов и звука по ТЗ)
local sprite = Resources.sprite_load("DeerItems", "item/Tankbuster", PATH.."assets/sprites/items/sWhiteItems/Tankbuster.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- Балансные константы
local COOLDOWN_FRAMES  = 7 * 60   -- перезарядка 7 секунд
local PLAYER_DMG_BASE  = 0.40     -- 40% урона игрока
local PLAYER_DMG_STACK = 0.20     -- +20% за стак
local MAXHP_BASE       = 0.02     -- 2% макс. HP цели
local MAXHP_STACK      = 0.01     -- +1% за стак

-- Создание предмета: белый тир, тег «урон»
local item = Item.new("DeerItems", "Tankbuster")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

item:clear_callbacks()

item:onHitProc(function(actor, victim, stack, hit_info)
    if not gm._mod_net_isHost() then return end
    if stack <= 0 then return end

    -- Внутренний кулдаун 7 секунд (на игрока)
    local data = actor:get_data("Tankbuster", GUID)
    local now = Global._current_frame
    if (now - (data.tb_last or -COOLDOWN_FRAMES)) < COOLDOWN_FRAMES then return end

    local base = actor.damage or 0
    if base <= 0 then return end
    local target_maxhp = victim.maxhp or 0

    -- Плоский добавочный урон = доля урона игрока + доля макс. HP цели
    local flat = base * (PLAYER_DMG_BASE + PLAYER_DMG_STACK * (stack - 1))
               + target_maxhp * (MAXHP_BASE + MAXHP_STACK * (stack - 1))
    -- Переводим плоскую величину в коэффициент fire_direct (×actor.damage)
    local coef = flat / base
    actor:fire_direct(victim, coef, nil, nil, nil, nil, false)

    data.tb_last = now
end)
