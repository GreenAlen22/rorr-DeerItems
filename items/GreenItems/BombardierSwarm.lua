-- DeerItems-BombardierSwarm / «Рой бомбардиров» / "Bombardier Swarm"
-- Призывает дрона-бомбардира: он сам летит к ближайшему врагу и зависает над ним. Раз в 10с
-- бомбардир сбрасывает шашку динамита; каждый ваш НАСТОЯЩИЙ дрон поблизости тоже роняет шашку.
-- Динамит падает под действием гравитации и взрывается при ударе о землю (или по запалу):
-- 250% урона (+125%/стак) в радиусе ~150 с оглушением на 1с.
--
-- Архитектура: дрон — кастомный объект на проверенном пути ArmySurplus/DeepcoreGK2 (создаётся
-- в onAcquire, ведёт себя в onStep, держится в onPostStep). Динамит — снаряд по образцу
-- AtGMissileMk0 (создаётся на хосте, projectile_sync для клиентов, взрыв и звук в onDestroy).

local droneSprite = Resources.sprite_load("DeerItems", "object/BombardierDrone", PATH.."assets/sprites/particle/BombardierDrone.png", 1, 18, 18)
local dynSprite   = Resources.sprite_load("DeerItems", "object/Dynamite",       PATH.."assets/sprites/particle/Dynamite.png", 6, 16, 16)
local sprite      = Resources.sprite_load("DeerItems", "item/BombardierSwarm",   PATH.."assets/sprites/items/sGreenItems/BombardierSwarm.png", 1, 16, 16)
local boom        = Resources.sfx_load("DeerItems", "sound/boom", PATH.."assets/sounds/boom.ogg")

local GUID = _ENV["!guid"]

-- Настройки баланса
local INTERVAL   = 10 * 60   -- бомбардировка раз в 10с
local DMG_BASE   = 2.5       -- 250% урона
local DMG_STACK  = 1.25      -- +125% за стак
local RADIUS     = 150       -- радиус взрыва
local STUN_SEC   = 1.0       -- оглушение
local SEEK_RANGE = 16 * 32   -- ищем врагов в этом радиусе ВОКРУГ ИГРОКА (а не вокруг дрона)
local LEASH      = 10 * 32   -- дрон никогда не отходит от игрока дальше этого — поэтому следует за вами
local DRONE_NEAR = 18 * 32   -- ваши настоящие дроны в этом радиусе тоже роняют динамит
local HOVER_H    = 60        -- высота зависания бомбардира над целью, px
local GRAVITY    = 0.4       -- ускорение падения динамита (родная гравитация GameMaker)
local FUSE       = 90        -- запал: взрыв через 1.5с, даже если не коснулся земли

local item = Item.new("DeerItems", "BombardierSwarm")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

-- ══════════════════ Динамит — снаряд под действием гравитации ══════════════════
local dyn = Object.new("DeerItems", "Dynamite")
dyn:set_sprite(dynSprite)
dyn:set_depth(-10)
dyn:clear_callbacks()

dyn:onCreate(function(self)
    self.parent   = -4
    self.team     = 1
    self.timer    = 0
    self.dmg_coef = DMG_BASE
    self.mask_index = gm.constants.sSinglePixel   -- надёжная маска для проверки земли (как у AtGMissileMk0)
    -- Родная физика GameMaker: gravity тянет вниз (направление по умолчанию 270),
    -- движок сам каждый кадр обновляет vspeed -> y. Стартуем небольшим броском вниз.
    self.gravity   = GRAVITY
    self.speed     = 2
    self.direction = 270 + gm.irandom_range(-25, 25)
    self:projectile_sync(8)      -- клиенты видят падение
end)

dyn:onStep(function(self)
    self.image_angle = self.image_angle + 12     -- кувыркание шашки (косметика, на всех клиентах)

    -- Детонация host-авторитетна; клиенты получат уничтожение через instance_destroy_sync.
    if gm._mod_net_isClient() then return end

    -- Нет владельца — тихо исчезаем без взрыва.
    if not Instance.exists(self.parent) then self:destroy(); return end

    self.timer = self.timer + 1

    -- Удар о землю: проверяем чуть ниже себя, но только когда уже падаем вниз (vspeed >= 0).
    -- pcall на случай, если place_meeting по oB где-то недоступен — тогда сработает запал.
    local hit_ground = false
    if self.vspeed >= 0 then
        local ok, res = pcall(function() return self:is_colliding(gm.constants.oB, self.x, self.y + 4) end)
        hit_ground = ok and res
    end

    if self.timer >= FUSE or hit_ground then
        -- damage у fire_explosion — КОЭФФИЦИЕНТ (×урон игрока). proc=false: взрыв не прокает предметы.
        local atk = self.parent:fire_explosion(self.x, self.y, RADIUS, RADIUS, self.dmg_coef, nil, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false
            atk.attack_info:set_critical(false)
            atk.attack_info:set_stun(STUN_SEC)
        end
        self:destroy()
    end
end)

dyn:onDestroy(function(self)
    -- Визуал взрыва (стандартный эффект движка) + звук.
    local ef = gm.instance_create(self.x, self.y, gm.constants.oEfExplosion)
    if ef then
        ef.image_xscale = RADIUS / 64
        ef.image_yscale = RADIUS / 64
    end
    if Instance.exists(self.parent) then
        pcall(function() self.parent:sound_play(boom, 1.0, 0.85 + math.random() * 0.3) end)
    end
    self:instance_destroy_sync()
end)

dyn:onSerialize(function(self, buffer)
    buffer:write_instance(self.parent)
end)

dyn:onDeserialize(function(self, buffer)
    self.parent = buffer:read_instance()
    if Instance.exists(self.parent) then self.team = self.parent.team end
end)

-- Сброс одной шашки из точки (x, y) с заданным коэффициентом урона.
local function drop_dynamite(actor, x, y, coef)
    local d = dyn:create(x, y)
    d.parent   = actor
    d.team     = actor.team
    d.dmg_coef = coef
end

-- ══════════════════ Дрон-бомбардир — летит к врагу и зависает над ним ══════════════════
local obj = Object.new("DeerItems", "BombardierDrone")
obj:set_sprite(droneSprite)
obj:set_depth(1)
obj:clear_callbacks()

obj:onCreate(function(self)
    local data = self:get_data(nil, GUID)
    self.persistent  = true       -- переживает смену этапа
    self.image_speed = 0.25
    data.bob = gm.irandom_range(0, 359)
end)

obj:onStep(function(self)
    local data   = self:get_data(nil, GUID)
    local parent = data.parent
    -- Нет владельца — дрона убираем.
    if not parent or not parent:exists() then self:destroy(); return end

    data.bob = (data.bob or 0) + 5

    -- Ищем ближайшего к ИГРОКУ врага (центр круга — игрок, не дрон!), раз в ~6 кадров.
    -- Поиск вокруг игрока + поводок ниже = дрон всегда держится рядом с вами и следует за вами,
    -- а не зависает на дальней цели, когда вы уходите.
    data.scan = (data.scan or 0) - 1
    if data.scan <= 0 then
        data.scan = 6
        local enemy_team = parent.team == 1 and 2 or 1
        local found = List.wrap(self:find_characters_circle(parent.x, parent.y, SEEK_RANGE, true, enemy_team, true))
        data.target = found[1]
    end
    local target = data.target

    local tx, ty
    if target and Instance.exists(target) then
        tx = target.x
        ty = target.y - HOVER_H
        self.image_xscale = (target.x < self.x) and -1 or 1
    else
        -- Врагов рядом нет — парим сбоку-сверху над игроком.
        local side = (parent.image_xscale ~= 0) and parent.image_xscale or 1
        tx = parent.x - side * 24
        ty = parent.y - 44
        self.image_xscale = side
    end

    -- Поводок: не даём точке зависания уйти от игрока дальше LEASH. Дрон тянется к врагу,
    -- но привязан к игроку, поэтому всегда возвращается и летит за вами.
    local dist = gm.point_distance(parent.x, parent.y, tx, ty)
    if dist > LEASH then
        local rad = math.rad(gm.point_direction(parent.x, parent.y, tx, ty))
        tx = parent.x + math.cos(rad) * LEASH
        ty = parent.y - math.sin(rad) * LEASH   -- GM: ось Y инвертирована
    end
    ty = ty + gm.dsin(data.bob) * 4   -- лёгкое покачивание

    -- Плавно летим к точке зависания.
    self.x = self.x + (tx - self.x) * 0.15
    self.y = self.y + (ty - self.y) * 0.15
end)

-- Создание/восстановление бомбардира у владельца, если его ещё нет.
local function ensure_drone(actor)
    local data = actor:get_data("BombardierSwarm", GUID)
    if not data.inst or not data.inst:exists() then
        local inst = obj:create(actor.x, actor.y - 44)
        inst:get_data(nil, GUID).parent = actor
        data.inst = inst
    end
    return data
end

item:onAcquire(function(actor, stack)
    ensure_drone(actor)
end)

item:onRemove(function(actor, stack)
    if stack <= 1 then
        local data = actor:get_data("BombardierSwarm", GUID)
        if data.inst and data.inst:exists() then data.inst:destroy() end
        data.inst = nil
    end
end)

-- Страховочно держим бомбардира живым (например, если смена этапа сбросила объект).
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    ensure_drone(actor)
end)

-- Таймер бомбардировки — host-авторитетно (как Totemetry).
item:onPreStep(function(actor, stack)
    if gm._mod_net_isClient() then return end
    local data = actor:get_data("BombardierSwarm", GUID)
    local now  = Global._current_frame
    if now < (data.last or -100000) + INTERVAL then return end
    data.last = now

    local coef = DMG_BASE + DMG_STACK * (stack - 1)

    -- Шашка из бомбардира (он висит над врагом — динамит упадёт прямо на цель).
    local drone = data.inst
    if drone and drone:exists() then
        drop_dynamite(actor, drone.x, drone.y, coef)
    end

    -- Шашка под каждым вашим настоящим дроном поблизости.
    pcall(function()
        for _, d in ipairs(Instance.find_all(gm.constants.oPDrone)) do
            if Instance.exists(d) and gm.point_distance(actor.x, actor.y, d.x, d.y) <= DRONE_NEAR then
                drop_dynamite(actor, d.x, d.y, coef)
            end
        end
    end)
end)
