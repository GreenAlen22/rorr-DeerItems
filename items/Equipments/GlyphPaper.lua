-- DeerItems-GlyphPaper / «Бумажный глиф» / "Glyph Paper"
-- Активка: над игроком на бумажке рисуется случайный глиф — огонь, лёд, свет или растения — и срабатывает.

local sprite      = Sprite.new("equipment/GlyphPaper", PATH.."assets/sprites/items/sEquipments/GlyphPaper.png", 1, 18, 18)
-- Лента 9 кадров 56×56 (PixelLab, вариант B; в кадре 1 вручную убран артефакт снизу слева): 0 — чистая бумага, 1–8 — сгорание.
local paperSprite = Sprite.new("particle/GlyphPaper", PATH.."assets/sprites/particle/GlyphPaper.png", 9, 28, 28)
-- ElevenLabs, выбраны пользователем 24.10.2026: рисование — дубль B, сгорание — дубль A.
local sndDraw     = Sound.new("GlyphPaper/draw", PATH.."assets/sounds/GlyphPaperDraw.ogg")
local sndBurn     = Sound.new("GlyphPaper/burn", PATH.."assets/sounds/GlyphPaperBurn.ogg")

local COOLDOWN   = 45
local DRAW_TIME  = 36     -- кадры, за которые рисуется круг с символом
local CAST_AT    = 45     -- кадр срабатывания
local BURN_SPEED = 0.35   -- кадров ленты за кадр игры при сгорании
local BURN_FIRST = 1
local BURN_LAST  = 8
local BURN_SOUND_AT = CAST_AT + 6   -- звук сгорания чуть позже звука стихии, чтобы не слиться
local LIFT       = 64     -- центр бумажки над игроком, px
local GLYPH_R    = 17     -- радиус кольца глифа, px: шире 17 кольцо задевает загнутый угол листа; формы в долях
local GLYPH_DX, GLYPH_DY = 1, 2   -- центр глифа чуть правее и ниже центра ленты — дальше от загнутого угла

local FIRE_COEF, FIRE_W, FIRE_H = 6.0, 256, 128       -- взрыв 8 × 4 м перед игроком
local ICE_COEF,  ICE_RADIUS     = 3.0, 256            -- 8 м
local LIGHT_RADIUS              = 320                 -- 10 м
local PLANT_RADIUS              = 256
local DOT_COEF, DOT_TICKS, DOT_RATE = 0.8, 5, 30      -- горение и лианы: 5 тиков по 80% раз в 0.5 с
local STUN_TIME   = 120   -- лёд, кадры
local BLIND_TIME  = 360   -- свет
local SNARE_TIME  = 240   -- растения
local LIGHT_HEAL  = 0.2   -- доля максимального здоровья союзника

-- Звук: по два ванильных кандидата на глиф, выбор — за ухом пользователя после прогона.
local SOUND_VARIANT = 1

-- Формы — по рисунку пользователя (24.10.2026). Координаты в долях радиуса внутреннего
-- кольца, центр 0,0, ось y вниз. Каждая линия — плоский список x1,y1,x2,y2,…; кружок
-- с заливкой — { dot = true, x, y, r }, рисуется, когда до него дошла обводка.
local function ring(cx, cy, r, segments)
    local pts = {}
    for i = 0, segments do
        local a = (i / segments) * math.pi * 2 - math.pi / 2
        pts[#pts + 1] = cx + math.cos(a) * r
        pts[#pts + 1] = cy + math.sin(a) * r
    end
    return pts
end

-- Кольцо рамки есть у всех четырёх глифов.
local function with_frame(strokes)
    table.insert(strokes, 1, ring(0, 0, 1, 40))
    return strokes
end

-- Цвет линий — тёмные чернила стихии: светло-голубое и светло-жёлтое на кремовой бумаге не видно.
local GLYPHS = {
    {   -- огонь: язык пламени вокруг большого круга с точкой, малый круг в вершине
        color = Color(0xFF6B3A),
        dot_color = Color(0xFF6B3A),
        sounds = { "wWormExplosion", "wExplosiveShot" },
        effect = gm.constants.sEfBombExplode,
        strokes = with_frame({
            { 0, -0.95, -0.2, -0.62, -0.36, -0.25, -0.46, 0.1, -0.48, 0.45 },
            { 0, -0.95, 0.2, -0.62, 0.36, -0.25, 0.46, 0.1, 0.48, 0.45 },
            { 0, -0.8, -0.21, -0.42 }, { 0, -0.8, 0.21, -0.42 },
            ring(0, -0.36, 0.25, 20),
            ring(0, 0.45, 0.48, 32),
            { dot = true, 0, 0.5, 0.09 },
        }),
    },
    {   -- лёд: вытянутый ромб над волной, треугольник остриём вниз
        color = Color(0x2F7FD0),
        sounds = { "wFrozen", "wSnowglobe" },
        effect = gm.constants.sSparksIce,
        strokes = with_frame({
            { 0, -0.95, 0.28, -0.2, 0, 0.62, -0.28, -0.2, 0, -0.95 },
            { -1, 0.32, -0.7, 0.3, -0.45, 0.18, -0.25, 0.0, 0, -0.05, 0.25, 0.0, 0.45, 0.18, 0.7, 0.3, 1, 0.32 },
            { -0.82, 0.5, 0.82, 0.5 },
            { -0.17, 0.5, 0, 0.75, 0.17, 0.5 },
        }),
    },
    {   -- свет: треугольник, сквозная линия с кругом у вершины и двумя засечками
        color = Color(0xD69A00),
        sounds = { "wDivineTP_Flash_01", "wDivineTP_Burst_01" },
        effect = gm.constants.sEfJewelSparkleBig,
        strokes = with_frame({
            { 0, -1, -0.78, 0.45, 0.78, 0.45, 0, -1 },
            { 0, -1, -0.15, -0.55 }, { 0, -1, 0.15, -0.55 },
            ring(0, -0.4, 0.2, 16),
            { 0, -0.2, 0, 1 },
            { -0.1, 0.0, 0.1, -0.1 }, { -0.1, 0.13, 0.1, 0.03 },
        }),
    },
    {   -- растения: воронка, стебель с «галочкой», круг с точкой
        color = Color(0x3F9E3A),
        -- Урон лиан коричневый: зелёные цифры читаются как лечение.
        dot_color = Color(0x8B5A2B),
        sounds = { "wAcridShoot2", "wChefGlaze" },
        effect = gm.constants.sEfPoisonSplash,
        strokes = with_frame({
            { -0.32, -0.72, 0.32, -0.72, 0, -0.38, -0.32, -0.72 },
            { -0.22, -0.62, 0.22, -0.62 },
            { 0, -0.38, 0, 0.32 },
            { -0.3, 0.04, 0, 0.24, 0.3, 0.04 },
            ring(0, 0.55, 0.23, 20),
            { dot = true, 0, 0.55, 0.07 },
        }),
    },
}

local function stroke_length(stroke)
    if stroke.dot then return 0 end
    local len = 0
    for i = 3, #stroke, 2 do
        len = len + math.sqrt((stroke[i] - stroke[i - 2]) ^ 2 + (stroke[i + 1] - stroke[i - 1]) ^ 2)
    end
    return len
end

-- Длины считаются один раз: прогресс рисования — доля общей длины всех линий по порядку.
for _, glyph in ipairs(GLYPHS) do
    glyph.length = 0
    for _, stroke in ipairs(glyph.strokes) do glyph.length = glyph.length + stroke_length(stroke) end
    local name = glyph.sounds[SOUND_VARIANT]
    glyph.sound = gm.constants[name]
    if not glyph.sound then error("GlyphPaper: sound "..name.." not found") end
    if not glyph.effect then error("GlyphPaper: effect sprite missing") end
end

local blind, snare

local function enemies_around(actor, x, y, radius)
    local enemy_team = tonumber(actor.team) == 1 and 2 or 1
    return List.wrap(actor:find_characters_circle(x, y, radius, true, enemy_team, true))
end

-- Эффекты наносит только хост; клиент получает их через синхронизацию fire_*, баффов,
-- оглушения и DoT (Actor.lua: apply_knockback, apply_dot, buff_apply — «synced»).
local CAST = {
    function(actor, side)   -- огонь: взрыв перед игроком и горение задетых
        local cx = actor.x + side * FIRE_W / 2
        local atk = actor:fire_explosion(cx, actor.y, FIRE_W, FIRE_H, FIRE_COEF, nil, gm.constants.sEfFire, false)
        if atk and atk.attack_info then atk.attack_info:set_critical(false) end
        for _, enemy in ipairs(enemies_around(actor, cx, actor.y, FIRE_W / 2)) do
            enemy:apply_dot(DOT_COEF, DOT_TICKS, DOT_RATE, actor, GLYPHS[1].dot_color)
        end
    end,
    function(actor, side)   -- лёд: урон, оглушение и ледяная глыба; боссы невосприимчивы сами
        actor:fire_explosion(actor.x, actor.y, ICE_RADIUS * 2, ICE_RADIUS * 2, ICE_COEF, nil, nil, false)
        for _, enemy in ipairs(enemies_around(actor, actor.x, actor.y, ICE_RADIUS)) do
            -- Порядок важен: виды отбрасывания складываются только по возрастанию (Actor.lua:170).
            enemy:apply_knockback(side, STUN_TIME, 0, Actor.KnockbackKind.STANDARD)
            enemy:apply_knockback(side, STUN_TIME, 0, Actor.KnockbackKind.DEEPFREEZE)
        end
    end,
    function(actor, side)   -- свет: ослепление врагов, лечение союзников
        blind = blind or Buff.find("blind", "ror")
        for _, enemy in ipairs(enemies_around(actor, actor.x, actor.y, LIGHT_RADIUS)) do
            enemy:buff_apply(blind, BLIND_TIME, 1)
        end
        local allies = List.wrap(actor:find_characters_circle(actor.x, actor.y, LIGHT_RADIUS, true, actor.team, true))
        for _, ally in ipairs(allies) do
            ally:heal(ally.maxhp * LIGHT_HEAL)
        end
    end,
    function(actor, side)   -- растения: корни и лианы
        snare = snare or Buff.find("snare", "ror")
        for _, enemy in ipairs(enemies_around(actor, actor.x, actor.y, PLANT_RADIUS)) do
            enemy:buff_apply(snare, SNARE_TIME, 1)
            enemy:apply_dot(DOT_COEF, DOT_TICKS, DOT_RATE, actor, GLYPHS[4].dot_color)
        end
    end,
}

for i, glyph in ipairs(GLYPHS) do glyph.cast = CAST[i] end

-- Вспышки — ванильные спрайты эффектов (сняты из data.win через datawin_sprite.py).
-- Рисуются у каждой машины по её таймеру бумажки, поэтому в fire_* спрайт взрыва не
-- передаётся: иначе у клиента он вышел бы дважды.
local function vfx(sprite, x, y, scale)
    local ef = gm.instance_create(x, y, gm.constants.oEfExplosion)
    ef.sprite_index = sprite
    ef.image_xscale = scale
    ef.image_yscale = scale
end

local VFX = {
    function(glyph, actor, side)
        vfx(glyph.effect, actor.x + side * FIRE_W / 2, actor.y, 1.1)
    end,
    function(glyph, actor, side)
        vfx(glyph.effect, actor.x, actor.y, 3)
        for _, enemy in ipairs(enemies_around(actor, actor.x, actor.y, ICE_RADIUS)) do
            vfx(gm.constants.sEFIceCrystal, enemy.x, enemy.y, 1.5)
        end
    end,
    function(glyph, actor, side)
        vfx(glyph.effect, actor.x, actor.y, 4)
        for _, enemy in ipairs(enemies_around(actor, actor.x, actor.y, LIGHT_RADIUS)) do
            vfx(glyph.effect, enemy.x, enemy.y, 1)
        end
    end,
    function(glyph, actor, side)
        for _, enemy in ipairs(enemies_around(actor, actor.x, actor.y, PLANT_RADIUS)) do
            vfx(glyph.effect, enemy.x, enemy.bbox_bottom, 1)
            vfx(gm.constants.sEfLeaf, enemy.x, enemy.y, 2)
        end
    end,
}

for i, glyph in ipairs(GLYPHS) do glyph.vfx = VFX[i] end

local obj = Object.new("GlyphPaper")

-- Хост задаёт владельца и глиф до instance_sync: образец — StandingRequisitionChest.
local spawn_plan

-- Таймер и кадр сгорания — в данных Lua, а не в полях инстанса: числовое поле инстанса
-- приходит не всегда числом Lua, и сравнение на равенство молча не срабатывает.
local GUID = _ENV["!guid"]

local function state(self)
    local data = Instance.get_data(self, "GlyphPaper", GUID)
    data.timer = data.timer or 0
    data.frame = data.frame or 0
    return data
end

local function glyph_of(self)
    return GLYPHS[math.floor(tonumber(self.glyph) or 0)]
end

Callback.add(obj.on_create, function(self)
    self.parent = -4
    self.glyph = 1
    if spawn_plan then
        self.parent = spawn_plan.parent
        self.glyph = spawn_plan.glyph
        spawn_plan = nil
        self:instance_sync()
    end
end)

Callback.add(obj.on_step, function(self)
    local parent = self.parent
    if not Instance.exists(parent) then
        if not Net.client then self:destroy() end
        return
    end
    self.x = parent.x
    self.y = parent.y - LIFT
    local data = state(self)
    data.timer = data.timer + 1

    if data.timer == 1 then parent:sound_play(sndDraw, 1, 0.95 + math.random() * 0.1) end
    if data.timer == BURN_SOUND_AT then parent:sound_play(sndBurn, 1, 0.95 + math.random() * 0.1) end

    -- Таймер идёт на каждой машине: звук каждый слышит у себя, урон и эффекты — только хост.
    if data.timer == CAST_AT then
        local glyph = glyph_of(self)
        if glyph then
            local side = parent.image_xscale >= 0 and 1 or -1
            parent:sound_play(glyph.sound, 1, 0.9 + math.random() * 0.2)
            glyph.vfx(glyph, parent, side)
            if Net.host then glyph.cast(parent, side) end
        end
    end

    if data.timer > CAST_AT then
        data.frame = math.min(data.frame + BURN_SPEED, BURN_LAST + 1)
        -- Уничтожает хост, клиентам уходит instance_destroy_sync. Клиент свою копию не
        -- трогает: копия должна жить ровно столько, сколько у хоста (у Hunger так не было).
        if data.frame > BURN_LAST and not Net.client then self:destroy() end
    end
end)

local function draw_glyph(glyph, x, y, progress)
    local budget = glyph.length * progress
    gm.draw_set_colour(glyph.color)
    for _, stroke in ipairs(glyph.strokes) do
        if budget <= 0 then break end
        if stroke.dot then
            gm.draw_circle(x + stroke[1] * GLYPH_R, y + stroke[2] * GLYPH_R, stroke[3] * GLYPH_R, false)
        else
            for i = 3, #stroke, 2 do
                if budget <= 0 then break end
                local x1, y1 = stroke[i - 2] * GLYPH_R, stroke[i - 1] * GLYPH_R
                local x2, y2 = stroke[i] * GLYPH_R, stroke[i + 1] * GLYPH_R
                local len = math.sqrt((stroke[i] - stroke[i - 2]) ^ 2 + (stroke[i + 1] - stroke[i - 1]) ^ 2)
                local part = math.min(1, budget / len)
                gm.draw_line(x + x1, y + y1, x + x1 + (x2 - x1) * part, y + y1 + (y2 - y1) * part)
                budget = budget - len
            end
        end
    end
    gm.draw_set_colour(Color.WHITE)
end

-- Модуля Draw в 0.1.58 нет: рисуем голыми gm.draw_*.
Callback.add(obj.on_draw, function(self)
    local glyph = glyph_of(self)
    if not glyph then return end
    local data = state(self)

    if data.timer <= CAST_AT then
        gm.draw_sprite(paperSprite.value, 0, self.x, self.y)
        draw_glyph(glyph, self.x + GLYPH_DX, self.y + GLYPH_DY, math.min(data.timer / DRAW_TIME, 1))
    elseif data.frame <= BURN_LAST then
        gm.draw_sprite(paperSprite.value, math.max(BURN_FIRST, math.floor(data.frame)), self.x, self.y)
    end
end)

Callback.add(obj.on_destroy, function(self)
    if not Net.client then self:instance_destroy_sync() end
end)

Object.add_serializers(obj, function(self, buffer)
    buffer:write_instance(self.parent)
    buffer:write_byte(self.glyph)
end, function(self, buffer)
    self.parent = buffer:read_instance()
    self.glyph = buffer:read_byte()
end)

local equip = Equipment.new("GlyphPaper")
equip:set_sprite(sprite)
equip.loot_tags = Item.LootTag.CATEGORY_DAMAGE
equip.cooldown = COOLDOWN * 60

-- on_use идёт у всех; бумажку создаёт хост, клиентам её даёт instance_sync.
Callback.add(equip.on_use, function(actor)
    if not Net.host then return end
    spawn_plan = { parent = actor, glyph = math.random(#GLYPHS) }
    obj:create(actor.x, actor.y - LIFT)
end)
