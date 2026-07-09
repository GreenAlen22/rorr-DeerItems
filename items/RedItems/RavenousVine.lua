-- DeerItems-RavenousVine / «Ненасытная лоза» / "Ravenous Vine"
-- Переработка №2 (RoR2 Growth Nectar -> «удушение толпы» -> «сбор эссенции + всплеск»).
-- Ядро прежнее: считаем врагов ВОКРУГ игрока. Но счётчик больше НЕ множит статы
-- (этим уже заняты Community/IngrownIdol) — он КОРМИТ лозу «эссенцией».
-- Пока враги рядом, лоза копит эссенцию (тем быстрее, чем больше врагов в радиусе).
-- Пока враги рядом, лоза периодически бьёт по области; при достижении порога — «цветёт»: большой взрыв + лечение.
-- Динамика прежняя: смертельна в гуще боя, бесполезна в одиночку. Стаки расширяют
-- радиус И потолок учитываемых врагов (=> заряд быстрее), усиливают урон и лечение.

-- Спрайт предмета (болванка из template). Нова переиспользует готовый Explosive.png. Звук не нужен.
local sprite      = Resources.sprite_load("DeerItems", "item/RavenousVine", PATH.."assets/sprites/items/sRedItems/RavenousVine.png", 1, 18, 18)
local bloomSprite = Resources.sprite_load("DeerItems", "particle/RavenousVineBloom", PATH.."assets/sprites/particle/RavenousVineExplosion.png", 15, 66, 66)
local radiusSprite = Resources.sprite_load("DeerItems", "particle/RavenousVineRadius", PATH.."assets/sprites/particle/RavenousVineRadius.png", 12, 100, 100)

local GUID = _ENV["!guid"]

-- ── Баланс ──────────────────────────────────────────────────────────────────────
local RADIUS_BASE  = 2 * 32     -- радиус при 1 стаке (2 метра = 64px)
local RADIUS_STACK = 32   -- +1 метра радиуса за каждый доп. стак (+32px)
local CAP_BASE     = 2      -- потолок учитываемых врагов = CAP_BASE + CAP_STACK*stack
local CAP_STACK    = 4      -- => стак1=6, стак2=10, стак3=14
local COUNT_PERIOD = 15     -- как часто пересчитываем врагов рядом, кадров (4 раза/сек)
local DAMAGE_PERIOD = 30    -- как часто лоза бьёт по области, кадров (2 раза/сек)

local ESS_PER_ENEMY = 1.0   -- эссенции в секунду за каждого учтённого врага
local THRESHOLD     = 24    -- эссенции для «цветения» (6 врагов => всплеск раз в ~4с)

local DAMAGE_BASE  = 0.70  -- урон тика: 70% базового урона...
local DAMAGE_STACK = 0.30  -- ...+30% за каждый доп. стак
local BURST_DMG_BASE  = 4.0   -- урон взрыва цветения: 400% урона игрока...
local BURST_DMG_STACK = 2.0   -- ...+200% за каждый доп. стак
local HEAL_BASE    = 0.12  -- лечение цветения: 12% макс. HP...
local HEAL_STACK   = 0.06  -- ...+6% за каждый доп. стак
-- ──────────────────────────────────────────────────────────────────────────────

local VINE_COLOR = Color(0x577147)
local RADIUS_SPRITE_SIZE = 200
local RADIUS_STAGE_FRAMES = 4
local RADIUS_ANIM_PERIOD = 60
local BLOOM_FRAMES = 15
local BLOOM_FRAME_PERIOD = 3

local function radius_for(stack) return RADIUS_BASE + (stack - 1) * RADIUS_STACK end
local function diameter_for(stack) return radius_for(stack) * 2 end
local function cap_for(stack)    return CAP_BASE + CAP_STACK * stack end
local function radius_texture_scale() return (RADIUS_BASE * 2) / RADIUS_SPRITE_SIZE end
local function radius_stage_for(ess)
    local frac = math.min(1, math.max(0, (ess or 0) / THRESHOLD))
    if frac < 0.50 then return 0 end
    if frac < 0.75 then return RADIUS_STAGE_FRAMES end
    return RADIUS_STAGE_FRAMES * 2
end
local function radius_frame_for(ess)
    return radius_stage_for(ess) + (math.floor((Global._current_frame or 0) / RADIUS_ANIM_PERIOD) % RADIUS_STAGE_FRAMES)
end
local function disable_control_effects(attack_info)
    attack_info.RMT_allow_stun = false
    attack_info.stun = 0
    attack_info.knockback = 0
    attack_info.knockup = 0
    attack_info.knockback_kind = Attack_Info.KNOCKBACK_KIND.none
    attack_info.knockback_direction = 0
end

local oBloom = Object.new("DeerItems", "RavenousVineBloom")
oBloom:set_sprite(bloomSprite)
oBloom:clear_callbacks()

oBloom:onCreate(function(self)
    self.parent = -4
    self.life = 0
    self.image_speed = 0
    self.image_index = 0
end)

oBloom:onStep(function(self)
    if not Instance.exists(self.parent) then self:destroy(); return end
    self.x = self.parent.x
    self.y = self.parent.y
    self.depth = self.parent.depth + 1
    local frame = math.floor((self.life or 0) / BLOOM_FRAME_PERIOD)
    if frame >= BLOOM_FRAMES then self:destroy(); return end
    self.image_index = frame
    self.life = (self.life or 0) + 1
end)

local item = Item.new("DeerItems", "RavenousVine")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_healing)
item:clear_callbacks()

-- Главная логика на хосте: пересчёт врагов рядом, накопление эссенции, «цветение».
-- Урон/лечение авторитетны на хосте (как RiftBeacon/DeadWater); клиентам HP синхронизируется.
item:onPostStep(function(actor, stack)
    if gm._mod_net_isClient() then return end
    if stack <= 0 then return end

    local data  = actor:get_data("RavenousVine", GUID)
    local frame = Global._current_frame
    data.ess = data.ess or 0

    -- Пересчёт врагов рядом раз в COUNT_PERIOD кадров (кэшируем число с кэпом).
    if data.rv_next == nil then data.rv_next = frame end
    if frame >= data.rv_next then
        data.rv_next = frame + COUNT_PERIOD
        local enemy_team = actor.team == 1 and 2 or 1
        local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, radius_for(stack), false, enemy_team, true))
        local n = #found
        local cap = cap_for(stack)
        if n > cap then n = cap end
        data.rv_count = n
    end

    -- Накопление эссенции каждый кадр: тем быстрее, чем больше врагов в радиусе.
    local nb = data.rv_count or 0
    if nb > 0 then
        data.ess = data.ess + nb * ESS_PER_ENEMY / 60
    end

    -- Периодический AoE-урон по тому же радиусу, пока лозу кормит хотя бы один враг.
    if data.rv_damage_next == nil then data.rv_damage_next = frame end
    if nb > 0 and frame >= data.rv_damage_next then
        data.rv_damage_next = frame + DAMAGE_PERIOD

        local dmg_coef = DAMAGE_BASE + DAMAGE_STACK * (stack - 1)
        local diameter = diameter_for(stack)
        local atk = actor:fire_explosion(actor.x, actor.y, diameter, diameter, dmg_coef, nil, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false
            atk.attack_info:set_critical(false)
            atk.attack_info:set_color(VINE_COLOR)
            disable_control_effects(atk.attack_info)
        end
    end

    -- Цветение: большой AoE-взрыв + лечение, остаток эссенции переносим.
    if data.ess >= THRESHOLD then
        data.ess = data.ess - THRESHOLD

        local dmg_coef = BURST_DMG_BASE + BURST_DMG_STACK * (stack - 1)
        local diameter = diameter_for(stack)
        local atk = actor:fire_explosion(actor.x, actor.y, diameter, diameter, dmg_coef, nil, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false                 -- взрыв цветения не должен прокать другие предметы/сам себя
            atk.attack_info:set_critical(false)
            atk.attack_info:set_color(VINE_COLOR)
        end

        local heal_frac = HEAL_BASE + HEAL_STACK * (stack - 1)
        actor:heal(actor.maxhp * heal_frac)

        -- Визуальная нова цветения
        local bloom = oBloom:create(actor.x, actor.y)
        bloom.parent = actor
        bloom.depth = actor.depth + 1
    end
end)

-- При полной потере предмета обнуляем накопленное.
item:onRemove(function(actor, stack)
    if stack <= 1 then
        local data = actor:get_data("RavenousVine", GUID)
        data.ess      = 0
        data.rv_count = 0
        data.rv_next  = nil
        data.rv_damage_next = nil
    end
end)

-- Визуал: контур радиуса «питания» вокруг игрока (без худа над головой).
item:onPostDraw(function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("RavenousVine", GUID)
    local frame = radius_frame_for(data.ess)
    local scale = radius_texture_scale()

    gm.draw_sprite_ext(radiusSprite, frame, actor.x, actor.y, scale, scale, 0, Color.WHITE, 1)
    gm.draw_set_colour(VINE_COLOR)
    gm.draw_circle(actor.x, actor.y, radius_for(stack), true)
    gm.draw_set_colour(Color.WHITE)
end)
