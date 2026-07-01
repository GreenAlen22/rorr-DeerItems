-- DeerItems-DeepcoreGK2
-- Призывает дрона, который вращается вокруг игрока, находит врагов и наносит небольшой урон, а также увеличевает скорость игрока. Кол-во целей и радиус зависят от стаков.

-- Загружаем спрайт дрона
-- Загружаем спрайт предмета
local droneSprite = Resources.sprite_load("DeerItems", "object/bosco", PATH.."assets/sprites/particle/bosco.png", 4, 16, 8)
local sprite = Resources.sprite_load("DeerItems", "item/DeepcoreGK2", PATH.."assets/sprites/items/sGreenItems/DeepcoreGK2.png", 1, 16, 16)

-- Выносим один раз: guid мода (чтобы get_data не искал его через debug-стек каждый кадр)
-- и цвет эффектов (чтобы не пересоздавать Color на каждый выстрел)
local GUID = _ENV["!guid"]
local BLEND = Color(0x221f00)
local oP = gm.constants.oP

-- Прибавка к скорости движения за каждого УНИКАЛЬНОГО подбитого моба (1 моб = 1 стак).
-- Накопление сбрасывается при переходе на новую локацию (см. onStageStart внизу).
local SPEED_PER_HIT = 0.07

-- Замедление цели от выстрела дрона (небольшое): множитель к скорости и длительность в кадрах.
local SLOW_MULT     = 0.85   -- -15% скорости передвижения цели
local SLOW_DURATION = 90     -- держится 1.5 сек, обновляется при каждом попадании
local HIT_DMG_FRAC  = 0.03   -- урон выстрела = 3% урона игрока (коэффициент для fire_direct)

-- Создание предмета DeepcoreGK2
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "DeepcoreGK2")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Скрытый дебафф замедления, который дрон вешает на цель (иконку не показываем — спрайт не нужен).
local slowBuff = Buff.new("DeerItems", "DeepcoreSlow")
slowBuff.show_icon = false
slowBuff.is_debuff = true
slowBuff.max_stack = 1
slowBuff:clear_callbacks()
slowBuff:onStatRecalc(function(actor, stack)
    actor.pHmax = actor.pHmax * SLOW_MULT
end)

-- Накопленную прибавку к скорости применяем при пересчёте статов: движок при
-- recalculate_stats сбрасывает pHmax к базе, поэтому прямое изменение не сохранялось.
item:onStatRecalc(function(actor, stack)
    local bonus = actor:get_data("DeerItems", GUID).bosco_speed
    if bonus then
        actor.pHmax = actor.pHmax + bonus
    end
end)

-- Создание объекта-дрона Bosco
local obj = Object.new("Bosco")
obj:set_sprite(droneSprite)
obj:set_depth(1)

-- При создании дрона: инициализация параметров
obj:onCreate(function(self)
    local data = self:get_data(nil, GUID)
    self.persistent = true
    self.image_speed = 0.25
    data.angle = gm.irandom_range(0, 359)
    data.angle_speed = 50
    data.radius = 100
    data.charge = 0
end)

-- Поведение дрона каждый кадр
obj:onStep(function(self)
    local data = self:get_data(nil, GUID)
    local parent = data.parent

    -- Уничтожаем дрона, если владелец исчез
    if not parent or not parent:exists() then
        self:destroy()
        return
    end

    -- Расчёт позиции вокруг игрока по синусоиде
    data.angle = (data.angle or 0) + (data.angle_speed or 120) / 60
    self.x = parent.x + gm.dcos(data.angle) * (data.radius or 48)
    self.y = parent.y - 10

    -- По умолчанию дрон смотрит туда же, куда повёрнут игрок (направление прицела).
    -- Если ниже найдётся цель — ориентация переопределится на неё.
    if parent.image_xscale ~= 0 then
        self.image_xscale = parent.image_xscale
    end

    -- Зарядка атаки по времени, зависящему от скорости атаки владельца.
    -- Пока не заряжено — копим заряд и выходим (дешёвый путь, выполняется большинство кадров).
    local req = 60 / (parent.attack_speed or 1)
    if data.charge < req then
        data.charge = data.charge + 1
        return
    end
    data.charge = 0

    -- Дальше — только в момент выстрела. Стак и радиус нужны лишь здесь.
    local stack = parent:item_stack_count(item)
    local fire_range = 320 + stack * 32

    -- Нативный поиск врагов в радиусе: круг и команду фильтрует движок
    -- (команда врагов — противоположная команде владельца, как в примерах тулкита).
    local enemy_team = parent.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(self.x, self.y, fire_range, true, enemy_team, true))

    -- Считаем дистанции, чтобы бить ближайших
    local enemies = {}
    for _, actor in ipairs(found) do
        enemies[#enemies + 1] = {actor = actor, dist = gm.point_distance(self.x, self.y, actor.x, actor.y)}
    end

    -- Нет целей в радиусе — выходим
    if not enemies[1] then return end

    -- Сортировка по дистанции нужна, только если целей больше одной
    if enemies[2] then
        table.sort(enemies, function(a, b) return a.dist < b.dist end)
    end

    -- Объекты эффектов и данные владельца берём один раз на выстрел, а не на каждую цель
    local efLineTracer = Object.find("ror-efLineTracer")
    local efSparks = Object.find("ror-efSparks")
    local pdata = parent:get_data("DeerItems", GUID)

    -- Атака ближайших врагов
    local max_targets = 2 + 2 * stack
    for i = 1, max_targets do
        local entry = enemies[i]
        if not entry then break end
        local target = entry.actor

        -- Ориентация дрона
        self.image_xscale = (target.x < self.x) and -1 or 1

        -- Визуальные эффекты: луч + искры
        local tracer = efLineTracer:create(self.x + self.image_xscale, self.y)
        tracer.xend = target.x
        tracer.yend = target.y
        tracer.bm = 1
        tracer.rate = 0.1
        tracer.width = 1.5
        tracer.image_blend = BLEND

        local sparks = efSparks:create(target.x, target.y)
        sparks.sprite_index = gm.constants.sSparks1
        sparks.image_blend = BLEND

        -- Копим прибавку к скорости: +1 стак за КАЖДОГО уникального моба (не за каждый удар).
        -- Множество подбитых в этом этапе мобов храним у владельца; повторные удары по тому же
        -- мобу скорость не добавляют. Сбрасывается на новой локации (onStageStart).
        local hit_set = pdata.bosco_hit
        if not hit_set then hit_set = {}; pdata.bosco_hit = hit_set end
        if not hit_set[target.id] then
            hit_set[target.id] = true
            pdata.bosco_speed = (pdata.bosco_speed or 0) + SPEED_PER_HIT
        end

        -- Наносим урон напрямую цели. damage у fire_direct — КОЭФФИЦИЕНТ (×урон игрока),
        -- поэтому передаём долю напрямую: 0.03 = 3% урона игрока (раньше тут ошибочно
        -- умножали на parent.damage ещё раз → урон шёл «в квадрате»).
        local attack_info = parent:fire_direct(target, HIT_DMG_FRAC).attack_info
        attack_info:set_color(BLEND)

        -- Небольшое замедление цели; обновляем длительность при каждом попадании
        target:buff_apply(slowBuff, SLOW_DURATION)
    end
end)

-- Когда игрок получает предмет — создаём дрона, если его ещё нет
item:onAcquire(function(actor, stack)
    local data = actor:get_data("DeerItems", GUID)
    if not data.inst then
        local inst = obj:create(actor.x, actor.y)
        inst:get_data(nil, GUID).parent = actor
        data.inst = inst
    end
end)

-- Когда предмет удаляется — уничтожаем дрона, если предмета больше нет
item:onRemove(function(actor, stack)
    local data = actor:get_data("DeerItems", GUID)
    if stack <= 1 and data.inst and data.inst:exists() then
        data.inst:destroy()
        data.inst = nil
    end
end)

-- На новой локации сбрасываем накопленную скорость и список подбитых мобов у всех игроков.
-- Используем vararg-функцию, чтобы не зависеть от числа аргументов колбэка.
Callback.add(Callback.TYPE.onStageStart, "DeerItems-DeepcoreGK2-reset", function(...)
    for _, p in ipairs(Instance.find_all(oP)) do
        local d = p:get_data("DeerItems", GUID)
        if (d.bosco_speed and d.bosco_speed > 0) or d.bosco_hit then
            d.bosco_speed = 0
            d.bosco_hit = {}
            p:recalculate_stats()
        end
    end
end)
