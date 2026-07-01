-- DeerItems-MagicMissile / «Волшебная стрела» / "Magic Missile"
-- Каждая результативная атака тратит заряд и выпускает дротик (хитскан) в ближайшего врага:
-- 120% урона (+60%/стак). Запас 4 заряда (+2/стак), восстановление 1 заряд / 2.5с.
-- Дротики не прокают предметы и не зацикливают сами себя.

local sprite = Resources.sprite_load("DeerItems", "item/MagicMissile", PATH.."assets/sprites/items/sGreenItems/MagicMissile.png", 1, 16, 16)

local GUID  = _ENV["!guid"]
local BLEND = Color(0xbfe3ff)

-- ── Баланс ──
local DART_BASE  = 1.2      -- 120% урона
local DART_STACK = 0.6      -- +60% за стак
local CAP_BASE   = 4        -- запас зарядов при 1 шт.
local CAP_STACK  = 2        -- +2 заряда за стак
local RECHARGE   = 150      -- 2.5с на восстановление одного заряда
local RANGE      = 12 * 32  -- радиус поиска цели (~12 м)

local item = Item.new("DeerItems", "MagicMissile")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

-- Восстановление зарядов
item:onPostStep(function(actor, stack)
    local data = actor:get_data("MagicMissile", GUID)
    local cap = CAP_BASE + CAP_STACK * (stack - 1)
    if data.charges == nil then data.charges = cap end
    if data.charges > cap then data.charges = cap end
    if data.charges < cap then
        data.rc = (data.rc or 0) + 1
        if data.rc >= RECHARGE then
            data.rc = 0
            data.charges = data.charges + 1
        end
    else
        data.rc = 0
    end
end)

-- Каждая результативная атака (proc-хит) выпускает дротик, если есть заряд
item:onHitProc(function(actor, victim, stack, hit_info)
    if not gm._mod_net_isHost() then return end
    local data = actor:get_data("MagicMissile", GUID)
    local cap = CAP_BASE + CAP_STACK * (stack - 1)
    if data.charges == nil then data.charges = cap end
    if data.charges <= 0 then return end

    -- Цель: ближайший враг рядом с игроком; иначе — задетый враг
    local enemy_team = actor.team == 1 and 2 or 1
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, RANGE, false, enemy_team, true))
    local target, best
    for _, e in ipairs(found) do
        if Instance.exists(e) then
            local d = gm.point_distance(actor.x, actor.y, e.x, e.y)
            if not best or d < best then best = d; target = e end
        end
    end
    if not target then target = victim end
    if not (target and Instance.exists(target)) then return end

    data.charges = data.charges - 1

    -- Хитскан-дротик. proc=false: дротик не прокает предметы (иначе попадание дротика само
    -- вызовет onHitProc → бесконечный самопрок).
    local coef = DART_BASE + DART_STACK * (stack - 1)
    local dir  = gm.point_direction(actor.x, actor.y, target.x, target.y)
    local hit  = actor:fire_direct(target, coef, dir, actor.x, actor.y)
    if hit and hit.attack_info then
        hit.attack_info.proc = false
        hit.attack_info:set_color(BLEND)
    end

    -- Визуал: трассер + искры (как у DeepcoreGK2)
    local efLineTracer = Object.find("ror-efLineTracer")
    local efSparks     = Object.find("ror-efSparks")
    if efLineTracer then
        local tracer = efLineTracer:create(actor.x, actor.y - 4)
        tracer.xend = target.x
        tracer.yend = target.y
        tracer.bm = 1
        tracer.rate = 0.12
        tracer.width = 1.2
        tracer.image_blend = BLEND
    end
    if efSparks then
        local sp = efSparks:create(target.x, target.y)
        sp.sprite_index = gm.constants.sSparks1
        sp.image_blend = BLEND
    end
end)
