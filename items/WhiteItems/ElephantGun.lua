-- DeerItems-ElephantGun
-- Слонобой: наносит на +20% за стак больше урона боссам.
-- (Адаптация Armor-Piercing Rounds из RoR2.)

-- Спрайт предмета (без партиклов и звука по ТЗ)
local sprite = Resources.sprite_load("DeerItems", "item/ElephantGun", PATH.."assets/sprites/items/sWhiteItems/ElephantGun.png", 1, 18, 18)

-- +20% урона боссам за стак
local BOSS_DMG_PER_STACK = 0.20

-- Безопасное приведение значения GML-функции (true / 1.0 / 0.0) к булеву.
-- ВАЖНО: GM.actor_is_boss возвращает GML-двойки 0.0/1.0, а в Lua 0.0 — ИСТИНА. Поэтому
-- `if not GM.actor_is_boss(...)` никогда не срабатывал бы, и бонус летел бы по всем врагам.
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

-- Создание предмета: белый тир, тег «урон»
local item = Item.new("DeerItems", "ElephantGun")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

item:clear_callbacks()

-- При попадании по боссу добавляем долю урона отдельным «безпроковым» хитом.
-- onHitProc (а не onAttackHit) — срабатывает только на проковых атаках; бонус-хит ниже
-- помечен proc=false, поэтому сам себя не прокает (иначе бесконечная цепочка).
item:onHitProc(function(actor, victim, stack, hit_info)
    if not gm._mod_net_isHost() then return end
    if stack <= 0 then return end
    if not (GM.actor_is_boss and truthy(GM.actor_is_boss(victim))) then return end

    local base = actor.damage or 0
    if base <= 0 then return end
    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    -- damage у fire_direct — это КОЭФФИЦИЕНТ (×actor.damage). Чтобы добавить ровно
    -- 20%/стак от фактического урона этого попадания, переводим плоскую величину в коэффициент.
    local coef = (BOSS_DMG_PER_STACK * stack * dmg) / base
    actor:fire_direct(victim, coef, nil, nil, nil, nil, false)
end)
