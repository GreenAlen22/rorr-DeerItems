-- DeerItems-Hunger / «Голод» / "Hunger"
-- Активка (адаптация Primordial Cube из RoR2): создаёт чёрную дыру, которая 10 секунд
-- стягивает врагов в одну точку. Урона не наносит. Боссы невосприимчивы. cd 60с.
--
-- Притяжение: ищем врагов через find_characters_circle (подтверждённый API мода —
-- Totemetry/DeepcoreGK2/HeavyLungs) и тянем прямой записью x/y с защитой от проскока центра.
-- Боссов фильтруем (= иммунитет); урон нигде не наносится.

-- Иконка снаряжения и спрайтовый визуал дыры.
local sprite = Resources.sprite_load("DeerItems", "equipment/Hunger", PATH.."assets/sprites/items/sEquipments/Hunger.png", 1, 18, 18)
local radiusSprite = Resources.sprite_load("DeerItems", "particle/HungerRadius", PATH.."assets/sprites/particle/HungerRadius.png", 36, 100, 100)
local HungerSpawn = Resources.sfx_load("DeerItems", "Hunger/hum", PATH.."assets/sounds/HungerSpawn.ogg")

-- ── Настройки баланса ──
local COOLDOWN    = 60          -- кулдаун, секунды
local LIFE        = 10 * 60     -- время жизни дыры, кадры (10 сек)
local PULL_RADIUS = 6 * 32      -- радиус притяжения, px (6 метров ≈ 192px)
local PULL_STRENGTH_MIN = 3    -- сила всасывания на краю, px/кадр
local PULL_STRENGTH_MAX = 48    -- сила всасывания в центре, px/кадр
local HOLE_SPEED  = 1.2         -- скорость полёта дыры вперёд, px/кадр (1.5x от прежних 0.8)

local RADIUS_SPRITE_SIZE = 200
local RADIUS_SCALE = (PULL_RADIUS * 2) / RADIUS_SPRITE_SIZE
local VISUAL_DEPTH = 100

local ANIM_TICK = 4
local SPAWN_FRAME_FIRST = 0      -- кадры 1-7
local SPAWN_FRAME_LAST  = 6
local LOOP_FRAME_FIRST  = 7      -- кадры 8-25
local LOOP_FRAME_LAST   = 31
local END_FRAME_FIRST   = 32     -- последние 4 кадра
local END_FRAME_LAST    = 35

local SPAWN_DURATION = (SPAWN_FRAME_LAST - SPAWN_FRAME_FIRST + 1) * ANIM_TICK
local END_DURATION = (END_FRAME_LAST - END_FRAME_FIRST + 1) * ANIM_TICK
local LOOP_LENGTH = LOOP_FRAME_LAST - LOOP_FRAME_FIRST + 1

-- Безопасное приведение GML-значения (true / 1.0 / 0.0) к булеву
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

local function visual_frame_for(age)
    age = math.max(age or 0, 0)

    if age < SPAWN_DURATION then
        return SPAWN_FRAME_FIRST + math.floor(age / ANIM_TICK)
    end

    if age >= LIFE - END_DURATION then
        local end_age = math.min(age - (LIFE - END_DURATION), END_DURATION - 1)
        return END_FRAME_FIRST + math.floor(end_age / ANIM_TICK)
    end

    local loop_age = age - SPAWN_DURATION
    return LOOP_FRAME_FIRST + (math.floor(loop_age / ANIM_TICK) % LOOP_LENGTH)
end

-- ── Объект «чёрная дыра» ──
local obj = Object.new("DeerItems", "HungerHole")
obj:set_sprite(radiusSprite)
obj:set_depth(VISUAL_DEPTH)
obj:clear_callbacks()

obj:onCreate(function(self)
    self.life = LIFE
    self.age = 0
    self.radius = PULL_RADIUS
    self.team = 1
    self.speed = HOLE_SPEED          -- движение вперёд; направление задаётся в onUse / синке
    self.mask_index = gm.constants.sSinglePixel
    self.depth = VISUAL_DEPTH
    self.image_speed = 0
    self.image_index = visual_frame_for(self.age)
    self.image_xscale = RADIUS_SCALE
    self.image_yscale = RADIUS_SCALE
    self:projectile_sync(10)         -- двигающийся объект → синкаем позицию/направление
end)

obj:onStep(function(self)
    self.depth = VISUAL_DEPTH
    self.image_index = visual_frame_for(self.age)
    self.age = (self.age or 0) + 1

    -- Притяжение считает хост (авторитет по позициям врагов); клиентам прилетает синк
    if gm._mod_net_isClient() then return end

    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    -- Враги = противоположная команда владельца (как в Totemetry/DeepcoreGK2)
    local enemy_team = self.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(self.x, self.y, self.radius, false, enemy_team, true))
    for _, target in ipairs(found) do
        -- Боссов не тянем (иммунитет); неосязаемых пропускаем. GM.actor_is_boss защищаем
        -- проверкой на существование (uppercase-прокси может вернуть 0.0 — оборачиваем в truthy).
        local is_boss = GM.actor_is_boss and truthy(GM.actor_is_boss(target))
        if not is_boss and not truthy(target.intangible) then
            local lastx, lasty = target.x, target.y
            local dist = gm.point_distance(self.x, self.y, target.x, target.y)
            -- Очень сильное втягивание к центру: квадратичный разгон от PULL_STRENGTH_MIN до PULL_STRENGTH_MAX.
            local t = 1 - math.min(dist / self.radius, 1)   -- 0 на краю, 1 в центре
            local strength = PULL_STRENGTH_MIN + (PULL_STRENGTH_MAX - PULL_STRENGTH_MIN) * t * t
            local d = gm.point_direction(self.x, self.y, target.x, target.y)
            target.x = target.x - math.cos(math.rad(d)) * strength
            target.y = target.y + math.sin(math.rad(d)) * strength
            -- Защита от проскока центра по обеим осям
            if lastx < self.x and target.x >= self.x then target.x = math.min(target.x, self.x)
            elseif lastx > self.x and target.x <= self.x then target.x = math.max(target.x, self.x) end
            if lasty < self.y and target.y >= self.y then target.y = math.min(target.y, self.y)
            elseif lasty > self.y and target.y <= self.y then target.y = math.max(target.y, self.y) end
        end
    end
end)

-- Сеть: переносим направление полёта (скорость одинаковая на всех клиентах).
obj:onSerialize(function(self, buffer)
    gm.write_direction(self.direction or 0)
end)

obj:onDeserialize(function(self, buffer)
    self.direction = gm.read_direction()
    self.speed = HOLE_SPEED
end)

obj:onDestroy(function(self)
    self:instance_destroy_sync()
end)

-- ── Снаряжение ──
local equip = Equipment.new("DeerItems", "Hunger")
equip:set_sprite(sprite)
equip:set_loot_tags(Item.LOOT_TAG.category_utility)
equip:set_cooldown(COOLDOWN)

equip:onUse(function(actor)
    actor:sound_play(HungerSpawn, 1.0, 1.0)
    -- Дыра появляется чуть впереди игрока и медленно летит вперёд по направлению запуска.
    local dir = (actor.image_xscale >= 0) and 0 or 180   -- по направлению взгляда игрока
    local hole = obj:create(actor.x + actor.image_xscale * 48, actor.y - 16)
    hole.team = actor.team
    hole.direction = dir
    hole.speed = HOLE_SPEED
end)
