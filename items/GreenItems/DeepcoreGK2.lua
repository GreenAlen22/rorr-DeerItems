-- DeerItems-DeepcoreGK2
-- Призывает Bosco, который стреляет по врагам и замедляет их. Кол-во целей и радиус зависят от стаков.

-- Загружаем спрайт дрона
-- Загружаем спрайт предмета
local droneSprite = Sprite.new("object/bosco", PATH.."assets/sprites/particle/bosco.png", 4, 16, 8)
local sprite = Sprite.new("item/DeepcoreGK2", PATH.."assets/sprites/items/sGreenItems/DeepcoreGK2.png", 1, 16, 16)

-- Выносим один раз: guid мода (чтобы get_data не искал его через debug-стек каждый кадр)
-- и цвет эффектов (чтобы не пересоздавать Color на каждый выстрел)
local GUID = _ENV["!guid"]
local BLEND = Color(0x221f00)
local oP = gm.constants.oP

-- Замедление цели от выстрела дрона (небольшое): множитель к скорости и длительность в кадрах.
local SLOW_MULT     = 0.85   -- -15% скорости передвижения цели
local SLOW_DURATION = 90     -- держится 1.5 сек, обновляется при каждом попадании
local HIT_DMG_FRAC  = 0.05   -- урон выстрела = 5% урона игрока (коэффициент для fire_direct)
local PROC_CHANCE   = 0.20
local SHIELD_PER_DRONE = 0.05
local DRONE_FIND_RADIUS = 100000
local packet_shot = Packet.new("DeepcoreGK2-packet_shot")
local packet_facing = Packet.new("DeepcoreGK2-packet_facing")

local function instance_exists(inst)
    return inst ~= nil and Instance.exists(inst)
end

local function create_shot_effect(source_x, source_y, target_x, target_y, facing)
    local efLineTracer = Object.find("EfLineTracer", "ror")
    local efSparks = Object.find("EfSparks", "ror")

    if efLineTracer then
        local tracer = efLineTracer:create(source_x + facing, source_y)
        tracer.xend = target_x
        tracer.yend = target_y
        tracer.bm = 1
        tracer.rate = 0.1
        tracer.width = 1.5
        tracer.image_blend = BLEND
    end

    if efSparks then
        local sparks = efSparks:create(target_x, target_y)
        sparks.sprite_index = gm.constants.sSparks1
        sparks.image_blend = BLEND
    end
end

packet_shot:set_serializers(function(buffer, source_x, source_y, target_x, target_y, facing)
    buffer:write_float(source_x)
    buffer:write_float(source_y)
    buffer:write_float(target_x)
    buffer:write_float(target_y)
    buffer:write_byte(facing >= 0 and 1 or 0)
end, function(buffer)
    -- Буфер дочитывается до любого return.
    local source_x, source_y = buffer:read_float(), buffer:read_float()
    local target_x, target_y = buffer:read_float(), buffer:read_float()
    local facing = buffer:read_byte() == 1 and 1 or -1
    if not Net.client then return end

    create_shot_effect(source_x, source_y, target_x, target_y, facing)
end)

packet_facing:set_serializers(function(buffer, actor, facing)
    buffer:write_instance(actor)
    buffer:write_byte(facing >= 0 and 1 or 0)
end, function(buffer)
    -- Буфер дочитывается до любого return.
    local actor = buffer:read_instance()
    local facing = buffer:read_byte() == 1 and 1 or -1
    if Net.client then return end

    if not instance_exists(actor) then return end
    Instance.get_data(actor, "DeerItems", GUID).bosco_facing = facing
end)

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

local function count_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_FIND_RADIUS, false, actor.team, true))
    local n = 0
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP and not is_not_drone(char) then
            n = n + 1
        end
    end
    return n
end

-- Создание предмета DeepcoreGK2
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeepcoreGK2")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Скрытый дебафф замедления, который дрон вешает на цель (иконку не показываем — спрайт не нужен).
local slowBuff = Buff.new("DeepcoreSlow")
slowBuff.show_icon = false
slowBuff.is_debuff = true
slowBuff.max_stack = 1
DeerItemsCallbacks.buff_stat_recalc(slowBuff, function(actor, stack, api)
    api.pHmax_mult(SLOW_MULT)
end)

DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
    if stack > 0 then
        local n = count_drones(actor)
        Instance.get_data(actor, "DeerItems", GUID).bosco_drones = n
        if n > 0 then
            -- От итогового maxhp прошлого пересчёта, как в RoMT: maxshield_add_from_maxhp
            -- берёт maxhp до Bitter Root, элит и Artifact of Glass.
            api.maxshield_add(actor.maxhp * SHIELD_PER_DRONE * n)
        end
    end
end)

-- Создание объекта-дрона Bosco
local obj = Object.new("Bosco")
obj:set_sprite(droneSprite)
obj:set_depth(1)
-- При создании дрона: инициализация параметров
Callback.add(obj.on_create, function(self)
    local data = Instance.get_data(self, nil, GUID)
    self.persistent = true
    self.image_speed = 0.25
    self.parent = -4
    data.angle = gm.irandom_range(0, 359)
    data.angle_speed = 50
    data.radius = 100
    data.charge = 0
    self:projectile_sync(8)
end)

-- Поведение дрона каждый кадр
Callback.add(obj.on_step, function(self)
    if Net.client then return end

    local data = Instance.get_data(self, nil, GUID)
    local parent = self.parent
    if not instance_exists(parent) then parent = data.parent end

    -- Уничтожаем дрона, если владелец исчез
    if not instance_exists(parent) then
        self:destroy()
        return
    end

    -- Расчёт позиции вокруг игрока по синусоиде
    data.angle = (data.angle or 0) + (data.angle_speed or 120) / 60
    self.x = parent.x + gm.dcos(data.angle) * (data.radius or 48)
    self.y = parent.y - 10

    -- По умолчанию дрон смотрит туда же, куда повёрнут игрок (направление прицела).
    -- Если ниже найдётся цель — ориентация переопределится на неё.
    local owner_data = Instance.get_data(parent, "DeerItems", GUID)
    local facing = owner_data.bosco_facing or parent.image_xscale
    if facing and facing ~= 0 and self.image_xscale ~= facing then
        self.image_xscale = facing
        self:instance_resync()
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
    local stack = parent:item_count(item)
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

    -- Атака ближайших врагов
    local max_targets = 2 + 2 * stack
    for i = 1, max_targets do
        local entry = enemies[i]
        if not entry then break end
        local target = entry.actor

        -- Ориентация дрона
        self.image_xscale = (target.x < self.x) and -1 or 1
        self:instance_resync()

        -- Визуальные эффекты: луч + искры
        create_shot_effect(self.x, self.y, target.x, target.y, self.image_xscale)
        if Net.host then
            packet_shot:send_to_all(self.x, self.y, target.x, target.y, self.image_xscale)
        end

        -- Наносим урон напрямую цели. damage у fire_direct — КОЭФФИЦИЕНТ (×урон игрока),
        -- поэтому передаём долю напрямую: 0.05 = 5% урона игрока (раньше тут ошибочно
        -- умножали на parent.damage ещё раз → урон шёл «в квадрате»).
        local hit = parent:fire_direct(target, HIT_DMG_FRAC)
        if hit and hit.attack_info then
            hit.attack_info.damage_color = BLEND
            if math.random() >= PROC_CHANCE then
                hit.attack_info.proc = false
            end
        end

        -- Небольшое замедление цели; обновляем длительность при каждом попадании
        target:buff_apply(slowBuff, SLOW_DURATION)
    end
end)

Callback.add(obj.on_destroy, function(self)
    self:instance_destroy_sync()
end)

Object.add_serializers(obj, function(self, buffer)
    buffer:write_instance(self.parent)
    buffer:write_byte(self.image_xscale >= 0 and 1 or 0)
end, function(self, buffer)
    self.parent = buffer:read_instance()
    self.image_xscale = buffer:read_byte() == 1 and 1 or -1
    Instance.get_data(self, nil, GUID).parent = self.parent
end)

-- Когда игрок получает предмет — создаём дрона, если его ещё нет
DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    if Net.client then return end

    local data = Instance.get_data(actor, "DeerItems", GUID)
    if not instance_exists(data.inst) then
        local inst = obj:create(actor.x, actor.y)
        inst.parent = actor
        Instance.get_data(inst, nil, GUID).parent = actor
        data.inst = inst
    end
end)

DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if stack <= 0 then return end

    local data = Instance.get_data(actor, "DeerItems", GUID)
    if Net.client then
        if actor.is_local then
            local facing = actor.image_xscale >= 0 and 1 or -1
            if data.bosco_facing ~= facing then
                data.bosco_facing = facing
                packet_facing:send_to_host(actor, facing)
            end
        end
        return
    end

    data.bosco_count_tick = (data.bosco_count_tick or 0) + 1
    if data.bosco_count_tick < 15 then return end
    data.bosco_count_tick = 0

    local n = count_drones(actor)
    if n ~= data.bosco_drones then
        data.bosco_drones = n
        actor:recalculate_stats()
    end
end)

-- Когда предмет удаляется — уничтожаем дрона, если предмета больше нет
DeerItemsCallbacks.item_removed(item, function(actor, stack)
    if Net.client then return end

    local data = Instance.get_data(actor, "DeerItems", GUID)
    if stack <= 1 and instance_exists(data.inst) then
        data.inst:destroy()
        data.inst = nil
    end
end)
