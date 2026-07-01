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
local RADIUS_BASE   = 3 * 32        -- базовый радиус зоны: 3 м
local RADIUS_STACK  = 1.5 * 32      -- прибавка радиуса за каждый стак сверх первого: +1.5 м
local HEAL_BASE     = 0.06          -- базовое лечение: 6% от макс. HP владельца
local HEAL_STACK    = 0.03          -- прибавка лечения за каждый стак сверх первого: +3%
local MOVE_EPS      = 1             -- порог в пикселях: смещение меньше считаем «стоянием на месте»
local ZONE_Y_OFFSET = 40           -- центр зоны приподнят над ногами персонажа
local ZONE_TTL      = 5            -- запас кадров жизни зоны без обновления (страховка от «висячих» зон)

-- Цвет отрисовки зоны — создаётся один раз, а не каждый кадр в onDraw
local ZONE_COLOR    = Color(0x33CC33)

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
    self.radius = RADIUS_BASE
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
    local x, y, r = self.x, self.y, self.radius
    gm.draw_set_colour(ZONE_COLOR)
    gm.draw_circle(x, y, r, true)
    gm.draw_circle(x, y, r / 3, true)
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
    local moved = math.abs(px - (data.lf_px or px)) > MOVE_EPS
                or math.abs(py - (data.lf_py or py)) > MOVE_EPS
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
    local radius = RADIUS_BASE + RADIUS_STACK * (stack - 1)
    local zone = data.lf_zone
    if not (zone and Instance.exists(zone)) then
        zone = objZone:create(actor.x, actor.y - ZONE_Y_OFFSET)
        data.lf_zone = zone
    end
    zone.x      = actor.x
    zone.y      = actor.y - ZONE_Y_OFFSET
    zone.radius = radius
    zone.ttl    = ZONE_TTL   -- продлеваем жизнь зоны, пока владелец стоит

    -- Импульс лечения: ровно в момент активации (1 сек) и далее каждую секунду
    if (data.lf_still - STILL_NEEDED) % HEAL_TICK ~= 0 then return end

    -- Лечение выполняет сервер (как у тотема в Totemetry), чтобы не было двойного хила в мультиплеере
    if gm._mod_net_isClient() then return end

    local heal = actor.maxhp * (HEAL_BASE + HEAL_STACK * (stack - 1))
    local targets = List.wrap(actor:find_characters_circle(actor.x, actor.y - ZONE_Y_OFFSET, radius, false, 1, true))
    for _, ally in ipairs(targets) do
        ally:heal(heal)
    end
end)

-- При потере предмета — гарантированно убираем зону
item:onRemove(function(actor, stack)
    destroy_zone(actor:get_data("DeerItems", GUID))
end)
