-- DeerItems-MosquitoNet / «Москитная сеть» / "Mosquito Net"
-- Порт Defensive Microbots из RoR2 (усиленная адаптация — в RoRR мало стреляющих врагов).
--  1) Каждые 0.5 сек сбивает вражеские снаряды в радиусе (база 2, +2 за стак).
--  2) Периодически ПОЛНОСТЬЮ блокирует один любой входящий удар (КД спадает за стаки).
-- Скорость перехвата растёт со скоростью атаки.

-- Спрайт предмета (болванка из template) и звук перехвата/блока (его делаешь ты).
local sprite = Resources.sprite_load("DeerItems", "item/MosquitoNet", PATH.."assets/sprites/items/sRedItems/MosquitoNet.png", 1, 18, 18)
local sound  = Resources.sfx_load("DeerItems", "MosquitoNet/zap", PATH.."assets/sounds/MosquitoNet.ogg")

local GUID  = _ENV["!guid"]
local oP    = gm.constants.oP
local BLEND = Color(0x88ccff)   -- холодный «технический» оттенок трассера/искр (как у Боско)

-- Настройки баланса
local BASE_PERIOD = 30    -- 0.5 сек при скорости атаки 1.0 (перехват снарядов)
local MIN_PERIOD  = 8     -- пол перезарядки перехвата
local RADIUS      = 160   -- ~5 м (в моде 32 px = 1 м)
local INTERCEPT_BASE  = 2     -- базовое число сбиваемых снарядов за тик
local INTERCEPT_STACK = 2     -- +2 за стак
local MAX_PER_TICK    = 14    -- кэп сбиваний за тик (защита от стоимости/имбы на роях)
local CORNER_LEN      = 48    -- длина уголков индикатора зоны

local BLOCK_BASE = 7 * 60          -- КД блока удара: 7 сек при 1 стаке
local BLOCK_REDUCTION = 0.10       -- -10% КД за стак гиперболически
local BLOCK_DAMAGE_FRAC = 0.10     -- блокирует только удары больше 10% текущего HP

local function block_cooldown(stack)
    return math.ceil(BLOCK_BASE / (1 + BLOCK_REDUCTION * math.max(0, stack - 1)))
end

-- Снаряды, помеченные как *NoSync, каждый клиент гасит ЛОКАЛЬНО (урон у него клиентский,
-- он его и так не получит). Синхронные снаряды сносим только на хосте, иначе десинк.
local NOSYNC = {}
for _, n in ipairs({ "oSpiderBulletNoSync", "oGuardBulletNoSync", "oBugBulletNoSync", "oScavengerBulletNoSync" }) do
    local c = gm.constants[n]
    if c then NOSYNC[c] = true end
end

local item = Item.new("DeerItems", "MosquitoNet")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    local data  = actor:get_data("MosquitoNet", GUID)
    local frame = Global._current_frame
    if data.mn_next == nil then data.mn_next = frame end
    if frame < data.mn_next then return end

    -- Перезарядка перехвата ускоряется скоростью атаки, но не ниже пола.
    local aspd = actor.attack_speed or 1
    if aspd < 0.1 then aspd = 0.1 end
    data.mn_next = frame + math.max(MIN_PERIOD, math.ceil(BASE_PERIOD / aspd))

    -- Готовый реестр ВРАЖДЕБНЫХ снарядов тулкита (только вражеские пули/ракеты).
    local projs, any = Instance.find_all(Instance.projectiles)
    if not any then return end

    -- Снаряды в радиусе + дистанции, чтобы сбивать ближайшие.
    local inrange = {}
    for _, p in ipairs(projs) do
        if Instance.exists(p) then
            local d = gm.point_distance(actor.x, actor.y, p.x, p.y)
            if d <= RADIUS then
                inrange[#inrange + 1] = { p = p, d = d }
            end
        end
    end
    if not inrange[1] then return end
    if inrange[2] then table.sort(inrange, function(a, b) return a.d < b.d end) end

    local host         = gm._mod_net_isHost()
    local efLineTracer = Object.find("ror-efLineTracer")
    local efSparks     = Object.find("ror-efSparks")

    local n    = math.min(INTERCEPT_BASE + INTERCEPT_STACK * stack, MAX_PER_TICK)   -- 2 (+2 за стак)
    local shot = 0
    for i = 1, #inrange do
        if shot >= n then break end
        local p = inrange[i].p
        if Instance.exists(p) then
            -- NoSync — локально на любом клиенте; синхронные — только хост.
            if NOSYNC[p.object_index] or host then
                -- Визуал как у Боско: трассер от игрока + искры на снаряде.
                if efLineTracer then
                    local tr = efLineTracer:create(actor.x, actor.y - 8)
                    tr.xend = p.x; tr.yend = p.y
                    tr.bm = 1; tr.rate = 0.1; tr.width = 1.5
                    tr.image_blend = BLEND
                end
                if efSparks then
                    local sp = efSparks:create(p.x, p.y)
                    sp.sprite_index = gm.constants.sSparks1
                    sp.image_blend  = BLEND
                end
                p:destroy()
                shot = shot + 1
            end
        end
    end

    if shot > 0 then
        actor:sound_play(sound, 0.7, 1.2 + math.random() * 0.3)
    end
end)

-- Периодический блок: до расчёта урона по игроку с предметом, если блок готов — гасим удар в 0.
-- Работает против ЛЮБОГО источника (пули, контакт, взрывы). В pcall: при иной сигнатуре функции
-- фича просто выключится, остальной предмет продолжит работать.
pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        local raw = args[2] and args[2].value
        if not raw then return end
        local v = Instance.wrap(raw)
        if not Instance.exists(v) then return end
        if v.object_index ~= oP then return end          -- блок только для игроков

        local stack = v:item_stack_count(item)
        if stack <= 0 then return end

        local dmg = args[4] and args[4].value
        if not dmg or dmg <= 0 then return end
        if not v.hp or v.hp <= 0 then return end
        if dmg <= v.hp * BLOCK_DAMAGE_FRAC then return end

        local data  = v:get_data("MosquitoNet", GUID)
        local frame = Global._current_frame
        if data.mn_block_next == nil then data.mn_block_next = 0 end
        if frame < data.mn_block_next then return end

        -- Блокируем удар и запускаем КД (спадает за стаки).
        args[4].value = 0
        data.mn_block_next = frame + block_cooldown(stack)

        pcall(function()
            local efSparks = Object.find("ror-efSparks")
            if efSparks then
                local sp = efSparks:create(v.x, v.y - 8)
                sp.sprite_index = gm.constants.sSparks1
                sp.image_blend  = BLEND
            end
            v:sound_play(sound, 0.9, 1.4 + math.random() * 0.2)
        end)
    end)
end)

-- Лёгкий индикатор зоны защиты под игроком (встроенная отрисовка, ассет не нужен).
item:onPostDraw(function(actor, stack)
    if stack <= 0 then return end
    local left   = actor.x - RADIUS
    local top    = actor.y - RADIUS
    local right  = actor.x + RADIUS
    local bottom = actor.y + RADIUS
    local len    = math.min(CORNER_LEN, RADIUS)

    gm.draw_set_colour(BLEND)
    gm.draw_set_alpha(0.25)
    gm.draw_line(left, top, left + len, top)
    gm.draw_line(left, top, left, top + len)
    gm.draw_line(right, top, right - len, top)
    gm.draw_line(right, top, right, top + len)
    gm.draw_line(left, bottom, left + len, bottom)
    gm.draw_line(left, bottom, left, bottom - len)
    gm.draw_line(right, bottom, right - len, bottom)
    gm.draw_line(right, bottom, right, bottom - len)
    gm.draw_set_alpha(1)
    gm.draw_set_colour(Color.WHITE)
end)
