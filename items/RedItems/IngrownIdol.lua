-- DeerItems-IngrownIdol / «Вросший идол» / "Ingrown Idol"
-- ПЕРЕРАБОТКА (вторая): идол копит подношения по убийствам и при пороге призывает МОЩНОГО ЗВЕРЯ-союзника,
-- который сам охотится на врагов и бьёт атаками владельца. Не "ещё одни статы" — призыв боевого союзника.
--   * подношения за убийство: обычный = 1, элита = 2, босс = 3;
--   * ПОСЛЕ 20-й минуты забега подношения вдвое меньше: обычный = 0.5, элита = 1, босс = 2;
--   * при 30 подношениях идол призывает зверя на BEAST_LIFE секунд (жив один за раз; повторный порог
--     при живом звере продлевает ему жизнь). Заряды сбрасываются (с переносом остатка).
-- HUD прогресса рисуется СПРАВА СВЕРХУ (примерно на середине верхней части экрана), независимо от разрешения.

-- Спрайт предмета (16x16). Спрайт зверя и спрайт-эффект удара — болванки/готовый арт (замени зверя по пути).
-- Звук призыва/удара — болванка IngrownIdol.ogg (замени на рык).
local sprite      = Resources.sprite_load("DeerItems", "item/IngrownIdol", PATH.."assets/sprites/items/sRedItems/IngrownIdol.png", 1, 16, 16)
local beastSprite = Resources.sprite_load("DeerItems", "particle/IngrownIdolBeast", PATH.."assets/sprites/particle/IngrownIdolBeast.png", 1, 8, 8)
local explosive   = Resources.sprite_load("DeerItems", "particle/IngrownIdolBurst", PATH.."assets/sprites/particle/Explosive.png", 5, 32, 32)
local sound       = Resources.sfx_load("DeerItems", "IngrownIdol/beast", PATH.."assets/sounds/IngrownIdol.ogg")

local GUID = _ENV["!guid"]

-- ── Баланс ────────────────────────────────────────────────────────────────────
local THRESHOLD     = 30      -- подношений для призыва зверя
local LATE_MINUTE   = 20      -- с этой минуты забега подношения вдвое меньше

-- Зверь
local BEAST_LIFE      = 45 * 60   -- живёт 45 сек (кадры)
local BEAST_SIGHT     = 12 * 32   -- радиус обзора (px)
local BEAST_SPEED     = 6         -- скорость движения (px/кадр) — быстрее игрока, догоняет врагов
local BEAST_REACH     = 64        -- дистанция, с которой бьёт цель
local BEAST_FOLLOW    = 96        -- на каком расстоянии держится у игрока, когда врагов нет
local BEAST_ATK_PERIOD= 30        -- удар раз в 0.5 сек
local BEAST_HIT       = 120       -- размер зоны удара (px)
local BEAST_DMG       = 2.0       -- урон удара = 200% урона игрока
local BEAST_DMG_STACK = 0.5       -- +50% урона удара за доп. стак предмета
local BEAST_SCALE     = 3         -- визуальный масштаб болванки спрайта (зверь крупный)

-- HUD (справа сверху, примерно в середине верхней части). Координаты в HUD-единицах
-- (display/hud_scale) — раскладка одинакова для любого разрешения/окна/«размера интерфейса».
local HUD_W         = 64          -- ширина полосы прогресса
local HUD_H         = 10          -- высота полосы
local HUD_MARGIN_R  = 28          -- отступ полосы от правого края экрана
local HUD_FROM_TOP  = 0.30        -- доля высоты экрана сверху до полосы (0 = у верха, 0.5 = центр)
-- ──────────────────────────────────────────────────────────────────────────────

-- Безопасное приведение GML-значения (true / 1.0 / 0.0) к булеву (0.0 в Lua ИСТИННО — см. memory).
local function truthy(v) return v ~= nil and v ~= false and v ~= 0 end

local function is_boss(v)
    return v and Instance.exists(v) and GM.actor_is_boss and truthy(GM.actor_is_boss(v))
end
local function is_elite(v)
    return v and Instance.exists(v) and GM.actor_is_elite and truthy(GM.actor_is_elite(v))
end

-- Текущая минута забега из директора (как DIRECTOR.minute_current в примере Eclipse1). pcall — на
-- случай, если директор недоступен (между забегами): тогда считаем минуту 0 (полные подношения).
local function run_minute()
    local ok, dir = pcall(gm._mod_game_getDirector)
    if ok and dir then
        local m = dir.minute_current
        if type(m) == "number" then return m end
    end
    return 0
end

-- Сколько подношений даёт это убийство (с учётом ослабления после 20-й минуты).
local function offering_for(victim)
    local late = run_minute() >= LATE_MINUTE
    if is_boss(victim)  then return late and 2 or 3 end
    if is_elite(victim) then return late and 1 or 2 end
    return late and 0.5 or 1
end

-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║  Зверь-союзник — кастомный объект (паттерн RiftBeacon/Hunger): неуязвим,      ║
-- ║  сам ищет врагов, движется к ним и бьёт атаками владельца, живёт по таймеру.  ║
-- ╚════════════════════════════════════════════════════════════════════════════╝
local oBeast = Object.new("DeerItems", "IngrownIdolBeast")
oBeast:set_sprite(beastSprite)
oBeast:clear_callbacks()

oBeast:onCreate(function(self)
    self.life        = BEAST_LIFE
    self.atk_t       = 0
    self.image_speed = 0.3
    self.image_xscale= BEAST_SCALE
    self.image_yscale= BEAST_SCALE
    self:projectile_sync(6)   -- синкаем позицию клиентам (двигаем x/y вручную на хосте)
end)

oBeast:onStep(function(self)
    -- Вся логика/движение — на хосте (parent хранится локально); клиентам прилетает позиция через
    -- projectile_sync, а спрайт рисует движок. Сначала host-gate, потом читаем get_data (см. memory).
    if gm._mod_net_isClient() then return end
    local data = self:get_data(nil, GUID)
    local parent = data.parent
    if not parent or not parent:exists() then self:destroy(); return end

    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    local stack = data.stack or 1
    local enemy_team = parent.team == 1 and 2 or 1

    -- Ближайший враг в радиусе обзора.
    local found = List.wrap(self:find_characters_circle(self.x, self.y, BEAST_SIGHT, false, enemy_team, true))
    local target, best = nil, math.huge
    for _, e in ipairs(found) do
        if Instance.exists(e) then
            local d = gm.point_distance(self.x, self.y, e.x, e.y)
            if d < best then best, target = d, e end
        end
    end

    if target then
        local dir = gm.point_direction(self.x, self.y, target.x, target.y)
        if best > BEAST_REACH then
            self.x = self.x + math.cos(math.rad(dir)) * BEAST_SPEED
            self.y = self.y - math.sin(math.rad(dir)) * BEAST_SPEED   -- GM: ось Y инвертирована
        end
        self.image_xscale = (math.cos(math.rad(dir)) >= 0) and BEAST_SCALE or -BEAST_SCALE

        -- Удар по таймеру, когда дотянулся.
        self.atk_t = self.atk_t + 1
        if self.atk_t >= BEAST_ATK_PERIOD and best <= BEAST_REACH + 48 then
            self.atk_t = 0
            local coef = BEAST_DMG + BEAST_DMG_STACK * (stack - 1)
            -- proc=false / без крита: удар зверя не должен прокать предметы владельца и зацикливаться.
            local atk = parent:fire_explosion(target.x, target.y, BEAST_HIT, BEAST_HIT, coef, nil, nil, false)
            if atk and atk.attack_info then
                atk.attack_info.proc = false
                atk.attack_info:set_critical(false)
            end
            gm.instance_create(target.x, target.y, gm.constants.oEfExplosion).sprite_index = explosive
            parent:sound_play(sound, 0.9, 0.95 + math.random() * 0.2)
        end
    else
        -- Врагов нет — держимся рядом с игроком, чтобы не потеряться.
        local dist = gm.point_distance(self.x, self.y, parent.x, parent.y)
        if dist > BEAST_FOLLOW then
            local dir = gm.point_direction(self.x, self.y, parent.x, parent.y)
            self.x = self.x + math.cos(math.rad(dir)) * BEAST_SPEED
            self.y = self.y - math.sin(math.rad(dir)) * BEAST_SPEED
            self.image_xscale = (math.cos(math.rad(dir)) >= 0) and BEAST_SCALE or -BEAST_SCALE
        end
    end
end)

oBeast:onDestroy(function(self)
    self:instance_destroy_sync()
end)

local function beast_alive(b) return b ~= nil and b:exists() end

-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║  Предмет «Вросший идол»                                                      ║
-- ╚════════════════════════════════════════════════════════════════════════════╝
local item = Item.new("DeerItems", "IngrownIdol")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

-- Кормим идол убийствами (подношения зависят от типа врага и минуты забега).
item:onKillProc(function(actor, victim, stack)
    local data = actor:get_data("IngrownIdol", GUID)
    data.fed = (data.fed or 0) + offering_for(victim)
end)

-- Призыв/продление зверя при достижении порога. Сброс заряда — у всех (предсказуемый HUD),
-- спавн сетевой сущности — только на хосте (как ArmySurplus/RiftBeacon).
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("IngrownIdol", GUID)
    if (data.fed or 0) < THRESHOLD then return end
    data.fed = data.fed - THRESHOLD            -- переносим остаток сверх порога

    if gm._mod_net_isClient() then return end
    if beast_alive(data.beast) then
        data.beast.life = BEAST_LIFE           -- продлеваем уже живого зверя
        return
    end
    local b  = oBeast:create(actor.x, actor.y - 16)
    local bd = b:get_data(nil, GUID)
    bd.parent = actor
    bd.stack  = stack
    b.team    = actor.team
    data.beast = b
    actor:sound_play(sound, 1.0, 0.8)          -- рык призыва
end)

-- При полной потере предмета убираем зверя и сбрасываем счётчик.
item:onRemove(function(actor, stack)
    if stack <= 1 then
        local data = actor:get_data("IngrownIdol", GUID)
        data.fed = 0
        if not gm._mod_net_isClient() and beast_alive(data.beast) then data.beast:destroy() end
        data.beast = nil
    end
end)

-- HUD: прогресс к зверю — справа сверху, примерно на середине верхней части экрана.
-- Координаты в HUD-единицах (display/hud_scale) — попадание калибровать не нужно (см. memory).
gm.post_script_hook(gm.constants.draw_hud, function()
    local p = Player.get_client()
    if not p or not Instance.exists(p) then return end
    if (p:item_stack_count(item) or 0) <= 0 then return end

    local data = p:get_data("IngrownIdol", GUID)
    local fed  = data.fed or 0
    local frac = math.min(1, fed / THRESHOLD)
    local live = beast_alive(data.beast)

    local hud_scale = gm.prefs_get_hud_scale()
    if not hud_scale or hud_scale == 0 then hud_scale = 1 end
    local W = gm.display_get_width()  / hud_scale
    local H = gm.display_get_height() / hud_scale

    local x0 = W - HUD_W - HUD_MARGIN_R     -- левый край полосы
    local y0 = H * HUD_FROM_TOP             -- верх полосы

    -- иконка идола слева от полосы (origin спрайта = правый-низ, поэтому смещаем вправо-вниз)
    gm.draw_set_alpha(1)
    gm.draw_sprite(sprite, 0, x0 - 4, y0 + HUD_H)

    -- полоса заполнения: красная при наборе, зелёная пока зверь жив
    gm.draw_set_colour(Color(0x111111))
    gm.draw_rectangle(x0, y0, x0 + HUD_W, y0 + HUD_H, false)
    gm.draw_set_colour(live and Color(0x55ff66) or Color(0xff5533))
    gm.draw_rectangle(x0, y0, x0 + HUD_W * frac, y0 + HUD_H, false)
    gm.draw_set_colour(Color.WHITE)
    gm.draw_rectangle(x0, y0, x0 + HUD_W, y0 + HUD_H, true)

    -- подпись: прогресс к зверю либо отметка активного зверя
    if live then
        gm.draw_text(x0, y0 + HUD_H + 2, "ЗВЕРЬ")
    else
        gm.draw_text(x0, y0 + HUD_H + 2, string.format("%.1f/%d", fed, THRESHOLD))
    end
    gm.draw_set_colour(Color.WHITE)
end)
