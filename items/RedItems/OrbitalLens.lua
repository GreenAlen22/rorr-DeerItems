-- DeerItems-OrbitalLens / «Орбитальная линза» / "Orbital Lens"
-- Порт Runic Lens из RoR2 (ослаблен под RoRR).
-- 3% (+2% за стак) шанс при попадании призвать метеор на 800% (+250% за стак) базового урона.
-- Каждые 100% нанесённого урона повышают шанс и урон метеора (с капом и затуханием).

-- Спрайт метеора (его даёшь ты), импакт-эффект из готового Explosive.png, звук удара (его даёшь ты).
local sprite      = Resources.sprite_load("DeerItems", "item/OrbitalLens", PATH.."assets/sprites/items/sRedItems/OrbitalLens.png", 1, 18, 18)
local OrbitalLensMeteor = Resources.sprite_load("DeerItems", "particle/OrbitalLens", PATH.."assets/sprites/particle/OrbitalLensMeteor.png", 5, 75, 75)
local OrbitalLensExplosive   = Resources.sprite_load("DeerItems", "particle/OrbitalLensBurst", PATH.."assets/sprites/particle/OrbitalLensExplosive.png", 14, 125, 235)
local sound       = Resources.sfx_load("DeerItems", "OrbitalLens/impact", PATH.."assets/sounds/OrbitalLens.ogg")

local GUID = _ENV["!guid"]

-- ── Баланс (как договорились: 1:1 переоценён, поэтому приручён) ──────────────────
local BASE_CHANCE    = 0.03   -- базовый шанс прока
local CHANCE_STACK   = 0.02   -- +2% шанса за каждый стак сверх первого
local BASE_COEF      = 8.0    -- 800% базового урона (не 2000%: в RoRR raw+частые проки)
local COEF_STACK     = 2.5    -- +250% за каждый стак сверх первого
local UNIT_CHANCE    = 0.01   -- +1% шанса за каждые 100% нанесённого урона
local UNIT_COEF      = 0.30   -- +30% урона метеора за каждые 100% нанесённого урона
local UNIT_CHANCE_CAP= 0.15   -- кап накопленного бонуса к шансу
local UNIT_COEF_CAP  = 6.0    -- кап накопленного бонуса к урону (=600%)
local DECAY_PERIOD   = 300    -- раз в 5 сек пул нанесённого урона уменьшается вдвое
local PROC_CD        = 15     -- мин. интервал между проками (кадры): onHitProc частит на мультихитах
local FALL_FRAMES    = 36     -- время падения метеора (~0.6 сек)
local RADIUS         = 160    -- радиус взрыва (~5 м)
local MAX_METEORS    = 6      -- одновременно в воздухе (как MAX_SUNS в ShineOSun)
-- ──────────────────────────────────────────────────────────────────────────────

local item = Item.new("DeerItems", "OrbitalLens")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

item:onAcquire(function(actor, stack)
    local data = actor:get_data("OrbitalLens", GUID)
    data.pool    = data.pool or 0
    data.meteors = data.meteors or {}
end)

-- Накопитель нанесённого урона + ролл метеора (вся логика на хосте).
item:onHitProc(function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    if not gm._mod_net_isHost() then return end
    if not (victim and Instance.exists(victim)) then return end

    local data = actor:get_data("OrbitalLens", GUID)
    data.pool    = data.pool or 0
    data.meteors = data.meteors or {}

    -- Копим нанесённый урон.
    local dealt = hit_info and (hit_info.damage or 0) or 0
    if dealt > 0 then data.pool = data.pool + dealt end

    -- Дебаунс прока (мультицель/частые атаки дают пачку попаданий за кадр).
    local frame = Global._current_frame
    if data.ol_last and (frame - data.ol_last) < PROC_CD then return end

    local base = actor.damage or 0
    if base <= 0 then return end

    -- «Юниты» = сколько раз накоплено 100% текущего урона игрока.
    local units      = math.floor(data.pool / base)
    local bonusChance = math.min(UNIT_CHANCE_CAP, UNIT_CHANCE * units)
    local bonusCoef   = math.min(UNIT_COEF_CAP,  UNIT_COEF  * units)

    local chance = BASE_CHANCE + CHANCE_STACK * (stack - 1) + bonusChance
    if math.random() >= chance then return end
    data.ol_last = frame

    if #data.meteors >= MAX_METEORS then return end

    local coef = BASE_COEF + COEF_STACK * (stack - 1) + bonusCoef
    data.meteors[#data.meteors + 1] = {
        x  = victim.x,
        ty = victim.y,                 -- точка падения
        sy = victim.y - (10 * 32),     -- старт метеора: ~10 м над целью
        t  = FALL_FRAMES,
        coef = coef,
        w  = RADIUS,
        h  = RADIUS,
    }
end)

-- Падение + взрыв метеоров и затухание накопителя.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    if not gm._mod_net_isHost() then return end
    local data = actor:get_data("OrbitalLens", GUID)
    data.pool    = data.pool or 0
    data.meteors = data.meteors or {}

    -- Затухание накопленного урона, чтобы линейная формула RoR2 не уходила в бесконечность.
    data.ol_decay = (data.ol_decay or 0) + 1
    if data.ol_decay >= DECAY_PERIOD then
        data.ol_decay = 0
        data.pool = data.pool * 0.5
    end

    for i = #data.meteors, 1, -1 do
        local m = data.meteors[i]
        m.t = m.t - 1
        if m.t <= 0 then
            -- coef передаём 5-м аргументом → fire_explosion трактует его как множитель урона игрока
            -- (= «800% базового урона»). proc=false/без крита — иначе самопрок и цепная реакция.
            local atk = actor:fire_explosion(m.x, m.ty, m.w, m.h, m.coef, nil, nil, false)
            if atk and atk.attack_info then
                atk.attack_info.proc = false
                atk.attack_info:set_critical(false)
            end
            gm.instance_create(m.x, m.ty, gm.constants.oEfExplosion).sprite_index = OrbitalLensExplosive
            actor:sound_play(sound, 1.0, 0.9 + math.random() * 0.4)
            table.remove(data.meteors, i)
        end
    end
end)

-- Визуал: падающий метеор + кольцо-цель (встроенная отрисовка).
item:onPostDraw(function(actor, stack)
    local data = actor:get_data("OrbitalLens", GUID)
    if not data.meteors then return end
    for _, m in ipairs(data.meteors) do
        local p  = 1 - (m.t / FALL_FRAMES)             -- прогресс падения 0..1
        local cy = m.sy + (m.ty - m.sy) * p
        gm.draw_sprite(OrbitalLensMeteor, 0, m.x, cy)
        gm.draw_set_colour(Color(0xff7733))
        gm.draw_set_colour(Color.WHITE)
    end
end)
