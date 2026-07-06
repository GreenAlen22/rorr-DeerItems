-- DeerItems-LaughingFungus
-- Застыв на 1 секунду, создаёт вокруг владельца зону, которая раз в секунду лечит всех союзников
-- в радиусе на процент от МАКСИМАЛЬНОГО HP владельца. При движении зона гаснет, отсчёт начинается заново.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/LaughingFungus", PATH.."assets/sprites/items/sGreenItems/LaughingFungus.png", 1, 18, 18)
local zoneSprite = Resources.sprite_load("DeerItems", "particle/LaughingFungusZone", PATH.."assets/sprites/particle/LaughingFungusZone.png", 18, 16, 32)

-- guid мода выносим один раз — чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

-- Создание предмета LaughingFungus
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("DeerItems", "LaughingFungus")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- Константы поведения (1 метр = 32 пикселя)
local STILL_NEEDED  = 60            -- сколько кадров стоять неподвижно для активации зоны (1 сек)
local HEAL_TICK     = 60            -- период лечения после активации (раз в 1 сек)
local ZONE_RADIUS_BASE   = 3 * 32   -- базовая полуширина зоны: 3 м
local ZONE_RADIUS_STACK  = 1.5 * 32 -- прибавка полуширины за каждый стак сверх первого: +1.5 м
local ZONE_HEIGHT_SCALE  = 0.5      -- высота зоны относительно ширины: 0.5 = срезана в 2 раза по высоте
local HEAL_BASE     = 0.06          -- базовое лечение: 6% от макс. HP владельца
local HEAL_STACK    = 0.03          -- прибавка лечения за каждый стак сверх первого: +3%
local MOVE_POS_EPS  = 0.01          -- порог в пикселях: ловит subpixel-движение во время зажатой атаки
local MOVE_SPEED_EPS = 0.01         -- порог скорости: ловит движение меньше 1 пикселя за кадр
local ZONE_Y_OFFSET = 40           -- центр зоны приподнят над ногами персонажа
local ZONE_TTL      = 15            -- запас кадров жизни зоны без обновления (страховка от «висячих» зон)
local MUSHROOM_VARIANTS = 6
local MUSHROOM_VARIANT_FRAMES = 3
local MUSHROOM_APPEAR_TICK = 4
local MUSHROOM_GRAVITY = 0.35
local MUSHROOM_FALL_FUSE = 90
local MUSHROOM_DROP_HEIGHT_MIN = 2
local MUSHROOM_DROP_HEIGHT_MAX = 4
local MUSHROOM_COUNT_BASE = 6
local MUSHROOM_COUNT_STACK = 6
local MUSHROOM_COUNT_MAX = 45
local MUSHROOM_MIN_SPACING = 8
local MUSHROOM_SCALE_MIN = 100
local MUSHROOM_SCALE_MAX = 100

local function zone_radius_for(stack)
    return ZONE_RADIUS_BASE + ZONE_RADIUS_STACK * (stack - 1)
end

local function zone_height_for(radius)
    return radius * ZONE_HEIGHT_SCALE
end

local function is_in_zone(target, x, y, radius, height)
    local dx = (target.x - x) / radius
    local dy = (target.y - y) / height
    return dx * dx + dy * dy <= 1
end

local function is_actor_moving(actor, data, px, py)
    local moved_by_position = math.abs(px - (data.lf_px or px)) > MOVE_POS_EPS
                           or math.abs(py - (data.lf_py or py)) > MOVE_POS_EPS

    local phspeed = actor.pHspeed or actor.hspeed or 0
    local pvspeed = actor.pVspeed or actor.vspeed or 0
    local moved_by_speed = math.abs(phspeed) > MOVE_SPEED_EPS
                        or math.abs(pvspeed) > MOVE_SPEED_EPS

    return moved_by_position or moved_by_speed
end

local function mushroom_count_for(radius)
    local extra_stacks = math.max(0, math.floor((radius - ZONE_RADIUS_BASE) / ZONE_RADIUS_STACK + 0.5))
    return math.min(MUSHROOM_COUNT_MAX, MUSHROOM_COUNT_BASE + extra_stacks * MUSHROOM_COUNT_STACK)
end

local function random_mushroom_x(zone, mushrooms)
    local x = zone.x + gm.irandom_range(-zone.radius, zone.radius)
    for _ = 1, 8 do
        local ok = true
        for _, mushroom in ipairs(mushrooms) do
            if Instance.exists(mushroom) and math.abs(mushroom.x - x) < MUSHROOM_MIN_SPACING then
                ok = false
                break
            end
        end
        if ok then return x end
        x = zone.x + gm.irandom_range(-zone.radius, zone.radius)
    end
    return x
end

local function mushroom_frame_for(variant, life)
    local base = (variant or 0) * MUSHROOM_VARIANT_FRAMES
    local frame = math.min(MUSHROOM_VARIANT_FRAMES - 1, math.floor((life or 0) / MUSHROOM_APPEAR_TICK))
    return base + frame
end

local objMushroom = Object.new("DeerItems", "EfLaughingFungusMushroom")
objMushroom:set_sprite(zoneSprite)
objMushroom:set_depth(50)
objMushroom:clear_callbacks()

objMushroom:onCreate(function(self)
    self.zone = -4
    self.life = 0
    self.variant = 0
    self.mask_index = gm.constants.sSinglePixel
    self.image_speed = 0
    self.image_index = 0
    self.image_xscale = 1
    self.image_yscale = 1
    self.gravity = MUSHROOM_GRAVITY
    self.speed = 1
    self.direction = 270 + gm.irandom_range(-18, 18)
    self:projectile_sync(8)
end)

objMushroom:onStep(function(self)
    self.life = (self.life or 0) + 1
    self.image_index = mushroom_frame_for(self.variant, self.life)

    if gm._mod_net_isClient() then return end
    if not Instance.exists(self.zone) then self:destroy(); return end

    local hit_ground = false
    if (self.vspeed or 0) >= 0 then
        local ok, res = pcall(function() return self:is_colliding(gm.constants.oB, self.x, self.y + 2) end)
        hit_ground = ok and res
    end

    if hit_ground or self.life >= MUSHROOM_FALL_FUSE then
        self.gravity = 0
        self.speed = 0
        self.hspeed = 0
        self.vspeed = 0
    end
end)

objMushroom:onDestroy(function(self)
    self:instance_destroy_sync()
end)

objMushroom:onSerialize(function(self, buffer)
    buffer:write_byte(self.variant or 0)
    buffer:write_byte(self.image_xscale < 0 and 1 or 0)
    buffer:write_byte(math.floor(math.abs(self.image_xscale or 1) * 100 + 0.5))
end)

objMushroom:onDeserialize(function(self, buffer)
    self.image_speed = 0
    self.variant = buffer:read_byte()
    local flip = buffer:read_byte()
    local scale = buffer:read_byte() / 100
    self.image_xscale = flip == 1 and -scale or scale
    self.image_yscale = scale
    self.image_index = mushroom_frame_for(self.variant, self.life)
end)

--==================================================================================================
-- ОБЪЕКТ-ЗОНА
-- Отдельный объект, существующий только пока владелец стоит на месте. Отвечает ИСКЛЮЧИТЕЛЬНО
-- за визуализацию: сейчас это простая отрисовка кругов в onDraw, позже сюда встанут партиклы.
-- Логику лечения он не трогает — она остаётся в коллбеках предмета.
--
-- Жизненным циклом управляет предмет (см. ниже): создаёт зону при активации, каждый кадр обновляет
-- её позицию/радиус и продлевает ttl, а при движении сразу уничтожает. ttl — страховка: если предмет
-- по какой-то причине перестал обновлять зону (смерть владельца, потеря предмета), она сама исчезнет.
--==================================================================================================
local objZone = Object.new("DeerItems", "EfLaughingFungusZone")
objZone.obj_depth = 50

objZone:clear_callbacks()

local function destroy_zone_mushrooms(zone)
    local data = zone:get_data(nil, GUID)
    local mushrooms = data.mushrooms
    if not mushrooms then return end

    for _, mushroom in ipairs(mushrooms) do
        if Instance.exists(mushroom) then
            mushroom:destroy()
        end
    end
    data.mushrooms = nil
end

local function ensure_zone_mushrooms(zone)
    local data = zone:get_data(nil, GUID)
    data.mushrooms = data.mushrooms or {}
    local mushrooms = data.mushrooms

    for i = #mushrooms, 1, -1 do
        if not Instance.exists(mushrooms[i]) then
            table.remove(mushrooms, i)
        end
    end

    local wanted = mushroom_count_for(zone.radius)
    while #mushrooms > wanted do
        local mushroom = table.remove(mushrooms)
        if Instance.exists(mushroom) then
            mushroom:destroy()
        end
    end

    while #mushrooms < wanted do
        local x = random_mushroom_x(zone, mushrooms)
        local ground_y = zone.ground_y or zone.y
        local y = ground_y - gm.irandom_range(MUSHROOM_DROP_HEIGHT_MIN, MUSHROOM_DROP_HEIGHT_MAX)
        local mushroom = objMushroom:create(x, y)
        local scale = gm.irandom_range(MUSHROOM_SCALE_MIN, MUSHROOM_SCALE_MAX) / 100
        mushroom.zone = zone
        mushroom.variant = gm.irandom_range(0, MUSHROOM_VARIANTS - 1)
        mushroom.image_index = mushroom_frame_for(mushroom.variant, 0)
        mushroom.image_xscale = gm.irandom_range(0, 1) == 0 and scale or -scale
        mushroom.image_yscale = scale
        table.insert(mushrooms, mushroom)
    end
end

-- При создании зоны
objZone:onCreate(function(self)
    self.radius = ZONE_RADIUS_BASE
    self.height = zone_height_for(self.radius)
    self.life   = 0           -- сколько кадров зона существует (пригодится для анимации партиклов)
    self.ttl    = ZONE_TTL    -- кадры до самоуничтожения, если предмет перестал обновлять зону
    self:projectile_sync(4)
end)

-- Каждый кадр: считаем «возраст» зоны и проверяем страховочный таймер
objZone:onStep(function(self)
    if gm._mod_net_isClient() then return end

    self.life = self.life + 1
    self.ttl  = self.ttl - 1
    if self.ttl <= 0 then self:destroy(); return end

    ensure_zone_mushrooms(self)
end)

objZone:onDestroy(function(self)
    if not gm._mod_net_isClient() then
        destroy_zone_mushrooms(self)
    end
    self:instance_destroy_sync()
end)

--==================================================================================================
-- ЛОГИКА ПРЕДМЕТА
--==================================================================================================

-- Уничтожение зоны владельца (если она существует) и очистка ссылки
local function destroy_zone(data)
    local zone = data.lf_zone
    if zone and Instance.exists(zone) then
        zone:destroy()
    end
    data.lf_zone = nil
end

item:clear_callbacks()

-- Каждый кадр: отслеживаем неподвижность, ведём визуальную зону и лечим союзников раз в секунду
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end

    local data = actor:get_data("DeerItems", GUID)
    local px, py = actor.x, actor.y

    -- Сместился ли владелец заметно с прошлого кадра
    local moved = is_actor_moving(actor, data, px, py)
    data.lf_px, data.lf_py = px, py

    -- При движении: гасим зону и сбрасываем отсчёт
    if moved then
        data.lf_still = 0
        destroy_zone(data)
        return
    end

    -- Копим время неподвижности; пока зона не активирована — её ещё нет
    data.lf_still = (data.lf_still or 0) + 1
    if data.lf_still < STILL_NEEDED then
        destroy_zone(data)
        return
    end

    if gm._mod_net_isClient() then return end

    -- Зона активна: создаём объект, если его ещё нет, и каждый кадр обновляем под владельца.
    local radius = zone_radius_for(stack)
    local height = zone_height_for(radius)
    local zone = data.lf_zone
    if not (zone and Instance.exists(zone)) then
        zone = objZone:create(actor.x, actor.y - ZONE_Y_OFFSET)
        data.lf_zone = zone
    end
    zone.x      = actor.x
    zone.y      = actor.y - ZONE_Y_OFFSET
    zone.ground_y = actor.y
    zone.radius = radius
    zone.height = height
    zone.ttl    = ZONE_TTL   -- продлеваем жизнь зоны, пока владелец стоит

    -- Импульс лечения: ровно в момент активации (1 сек) и далее каждую секунду
    if (data.lf_still - STILL_NEEDED) % HEAL_TICK ~= 0 then return end

    local heal = actor.maxhp * (HEAL_BASE + HEAL_STACK * (stack - 1))
    local zone_x, zone_y = actor.x, actor.y - ZONE_Y_OFFSET
    local targets = List.wrap(actor:find_characters_circle(zone_x, zone_y, radius, false, 1, true))
    for _, ally in ipairs(targets) do
        if is_in_zone(ally, zone_x, zone_y, radius, height) then
            ally:heal(heal)
        end
    end
end)

-- При потере предмета — гарантированно убираем зону
item:onRemove(function(actor, stack)
    destroy_zone(actor:get_data("DeerItems", GUID))
end)
