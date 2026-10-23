-- DeerItems-ElephantGun
-- Слонобой: наносит больше урона боссам и чаще критует по ним.
-- (Адаптация Armor-Piercing Rounds из RoR2.)

-- Спрайт предмета (без партиклов и звука по ТЗ)
local sprite = Sprite.new("item/ElephantGun", PATH.."assets/sprites/items/sWhiteItems/ElephantGun.png", 1, 18, 18)

-- +15% урона и +10% крит-шанса боссам за стак
local BOSS_DMG_PER_STACK = 0.15
local BOSS_CRIT_PER_STACK = 10

-- Безопасное приведение значения GML-функции (true / 1.0 / 0.0) к булеву.
-- ВАЖНО: GM.actor_is_boss возвращает GML-двойки 0.0/1.0, а в Lua 0.0 — ИСТИНА. Поэтому
-- `if not GM.actor_is_boss(...)` никогда не срабатывал бы, и бонус летел бы по всем врагам.
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

-- Создание предмета: белый тир, тег «урон»
local item = Item.new("ElephantGun")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
local function is_boss(actor)
    return actor and Instance.exists(actor) and GM.actor_is_boss and truthy(GM.actor_is_boss(actor))
end

local function roll_bonus_crit(actor, bonus)
    if bonus <= 0 then return false end

    local base = actor.critical_chance or 0
    if base < 0 then base = 0 end
    if base >= 100 then return false end

    local missing = 100 - base
    if bonus >= missing then return true end
    return math.random() < (bonus / missing)
end

-- Крит надо докинуть до финального расчёта урона: onHitProc уже поздно для числа/звука.
pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        -- proc и critical — аргументы самого расчёта (damager_hit_process передаёт attack_info.proc).
        -- Поля proc у HitInfo нет, а hit_info.critical расчёт перезаписывает своим аргументом.
        local proc = args[7] and args[7].value
        if not truthy(proc) then return end

        local raw_victim = args[2] and args[2].value
        if not raw_victim then return end
        local victim = Instance.wrap(raw_victim)
        if not is_boss(victim) then return end

        local raw_actor = args[6] and args[6].value
        if not raw_actor then return end
        local actor = Instance.wrap(raw_actor)
        if not Instance.exists(actor) then return end

        local stack = actor:item_count(item)
        if stack <= 0 then return end

        local dmg = args[4] and args[4].value
        if not dmg or dmg <= 0 then return end

        local crit = args[5] and args[5].value
        if not truthy(crit) and roll_bonus_crit(actor, BOSS_CRIT_PER_STACK * stack) then
            args[5].value = true
            args[4].value = dmg * 2
        end
    end)
end)

-- При попадании по боссу добавляем долю урона отдельным «безпроковым» хитом.
-- onHitProc (а не onAttackHit) — срабатывает только на проковых атаках; бонус-хит ниже
-- помечен proc=false, поэтому сам себя не прокает (иначе бесконечная цепочка).
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end
    if stack <= 0 then return end
    if not is_boss(victim) then return end

    local base = actor.damage or 0
    if base <= 0 then return end
    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    -- damage у fire_direct — это КОЭФФИЦИЕНТ (×actor.damage). Чтобы добавить ровно
    -- 15%/стак от фактического урона этого попадания, переводим плоскую величину в коэффициент.
    local coef = (BOSS_DMG_PER_STACK * stack * dmg) / base
    actor:fire_direct(victim, coef, nil, nil, nil, nil, false)
end)
