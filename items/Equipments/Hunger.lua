-- DeerItems-Hunger / «Голод» / "Hunger"
-- Активка (адаптация Primordial Cube из RoR2): создаёт чёрную дыру, которая 10 секунд
-- стягивает врагов в одну точку. Урона не наносит. Боссы невосприимчивы. cd 60с.
--
-- Притяжение: ищем врагов через find_characters_circle (подтверждённый API мода —
-- Totemetry/DeepcoreGK2/HeavyLungs) и тянем прямой записью x/y с защитой от проскока центра.
-- Боссов фильтруем (= иммунитет); урон нигде не наносится.

-- Иконка снаряжения (заглушка-шаблон). Визуал дыры рисуем процедурно (onDraw).
local sprite = Resources.sprite_load("DeerItems", "equipment/Hunger", PATH.."assets/sprites/items/sEquipments/Hunger.png", 1, 18, 18)
local HungerSpawn = Resources.sfx_load("DeerItems", "Hunger/hum", PATH.."assets/sounds/HungerSpawn.ogg")

-- ── Настройки баланса ──
local COOLDOWN    = 60          -- кулдаун, секунды
local LIFE        = 10 * 60     -- время жизни дыры, кадры (10 сек)
local PULL_RADIUS = 6 * 32      -- радиус притяжения, px (6 тайлов ≈ 192px)
local HOLE_SPEED  = 1.2         -- скорость полёта дыры вперёд, px/кадр (1.5x от прежних 0.8)

-- Цвета воронки — создаём один раз, а не каждый кадр
local COL_CORE = Color(0x0A0010)
local COL_RING = Color(0x5A1A7A)

-- Безопасное приведение GML-значения (true / 1.0 / 0.0) к булеву
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

-- ── Объект «чёрная дыра» ──
local obj = Object.new("DeerItems", "HungerHole")
obj:set_depth(-50)
obj:clear_callbacks()

obj:onCreate(function(self)
    self.life = LIFE
    self.radius = PULL_RADIUS
    self.team = 1
    self.speed = HOLE_SPEED          -- движение вперёд; направление задаётся в onUse / синке
    self:projectile_sync(10)         -- двигающийся объект → синкаем позицию/направление
end)

obj:onStep(function(self)
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
            -- Очень сильное втягивание к центру: квадратичный разгон. У края ~6 px/кадр,
            -- в ядре до ~24 px/кадр (раньше было 4..15 — ещё усилили).
            local t = 1 - math.min(dist / self.radius, 1)   -- 0 на краю, 1 в центре
            local strength = 6 + 18 * t * t
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

-- Визуал воронки (мировые координаты, поверх земли).
-- Ядро намеренно МАЛЕНЬКОЕ и полупрозрачное, чтобы не закрывать обзор (заменим на спрайт,
-- когда пришлёшь). Зону по-прежнему ясно очерчивают кольца-контуры.
obj:onDraw(function(self)
    local x, y, r = self.x, self.y, self.radius
    local pulse = 0.85 + 0.15 * math.sin(Global._current_frame / 6)
    gm.draw_set_alpha(0.5)
    gm.draw_set_colour(COL_CORE)
    gm.draw_circle(x, y, r * 0.16 * pulse, false)    -- маленькое тёмное ядро
    gm.draw_set_alpha(1)
    gm.draw_set_colour(COL_RING)
    gm.draw_circle(x, y, r, true)                     -- внешний горизонт
    gm.draw_circle(x, y, r * 0.75 * pulse, true)      -- внутреннее кольцо
    gm.draw_set_colour(Color.WHITE)
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
