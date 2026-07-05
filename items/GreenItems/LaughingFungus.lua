-- DeerItems-LaughingFungus
-- Застыв на 1 секунду, создаёт вокруг владельца зону, которая раз в секунду лечит всех союзников
-- в радиусе на процент от МАКСИМАЛЬНОГО HP владельца. При движении зона гаснет, отсчёт начинается заново.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/LaughingFungus", PATH.."assets/sprites/items/sGreenItems/LaughingFungus.png", 1, 18, 18)

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
local ZONE_INNER_SCALE   = 1 / 3    -- размер внутреннего кольца визуализации
local HEAL_BASE     = 0.06          -- базовое лечение: 6% от макс. HP владельца
local HEAL_STACK    = 0.03          -- прибавка лечения за каждый стак сверх первого: +3%
local MOVE_POS_EPS  = 0.01          -- порог в пикселях: ловит subpixel-движение во время зажатой атаки
local MOVE_SPEED_EPS = 0.01         -- порог скорости: ловит движение меньше 1 пикселя за кадр
local ZONE_Y_OFFSET = 40           -- центр зоны приподнят над ногами персонажа
local ZONE_TTL      = 5            -- запас кадров жизни зоны без обновления (страховка от «висячих» зон)

-- Цвет отрисовки зоны — создаётся один раз, а не каждый кадр в onDraw
local ZONE_COLOR    = Color(0x33CC33)

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

-- При создании зоны
objZone:onCreate(function(self)
    self.radius = ZONE_RADIUS_BASE
    self.height = zone_height_for(self.radius)
    self.life   = 0           -- сколько кадров зона существует (пригодится для анимации партиклов)
    self.ttl    = ZONE_TTL    -- кадры до самоуничтожения, если предмет перестал обновлять зону
end)

-- Каждый кадр: считаем «возраст» зоны и проверяем страховочный таймер
objZone:onStep(function(self)
    self.life = self.life + 1
    self.ttl  = self.ttl - 1
    if self.ttl <= 0 then self:destroy() end
end)

-- Визуализация зоны. Точка входа для будущих партиклов — заменяй/дополняй содержимое этого коллбека.
objZone:onDraw(function(self)
    local x, y, r, h = self.x, self.y, self.radius, self.height
    gm.draw_set_colour(ZONE_COLOR)
    gm.draw_ellipse(x - r, y - h, x + r, y + h, true)
    gm.draw_ellipse(
        x - r * ZONE_INNER_SCALE, y - h * ZONE_INNER_SCALE,
        x + r * ZONE_INNER_SCALE, y + h * ZONE_INNER_SCALE,
        true
    )
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

    -- Зона активна: создаём объект, если его ещё нет, и каждый кадр обновляем под владельца.
    -- Спавним локально на каждой машине — визуализация рисуется у каждого клиента сама.
    local radius = zone_radius_for(stack)
    local height = zone_height_for(radius)
    local zone = data.lf_zone
    if not (zone and Instance.exists(zone)) then
        zone = objZone:create(actor.x, actor.y - ZONE_Y_OFFSET)
        data.lf_zone = zone
    end
    zone.x      = actor.x
    zone.y      = actor.y - ZONE_Y_OFFSET
    zone.radius = radius
    zone.height = height
    zone.ttl    = ZONE_TTL   -- продлеваем жизнь зоны, пока владелец стоит

    -- Импульс лечения: ровно в момент активации (1 сек) и далее каждую секунду
    if (data.lf_still - STILL_NEEDED) % HEAL_TICK ~= 0 then return end

    -- Лечение выполняет сервер (как у тотема в Totemetry), чтобы не было двойного хила в мультиплеере
    if gm._mod_net_isClient() then return end

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
