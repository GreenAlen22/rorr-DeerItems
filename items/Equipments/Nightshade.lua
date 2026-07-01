-- DeerItems-Nightshade / «Паслён» / "Nightshade"
-- Активка (переработка Goobo Jr из RoR2): призывает теневого КЛОНА-телепортёра.
-- Цикл, пока жив: невидим -> мигает к ближайшему врагу, появляется чёрной копией игрока
-- и бьёт взрывом на 133% урона -> тут же уходит в невидимость -> повторяет. ~13с, неуязвим.
-- Так нет ни «странной ходьбы», ни прохода сквозь текстуры — клон только мигает (телепорт).

-- Ассеты (заглушки-шаблоны — замени текстуры/звук по этим путям)
local sprite      = Resources.sprite_load("DeerItems", "equipment/Nightshade", PATH.."assets/sprites/items/sEquipments/Nightshade.png", 1, 16, 16)
local cloneSprite = Resources.sprite_load("DeerItems", "object/NightshadeClone", PATH.."assets/sprites/particle/NightshadeClone.png", 1, 8, 8)
local sndSummon   = Resources.sfx_load("DeerItems", "Nightshade/summon", PATH.."assets/sounds/NightshadeSummon.ogg")
local sndHit      = Resources.sfx_load("DeerItems", "Nightshade/hit", PATH.."assets/sounds/NightshadeHit.ogg")
local burst       = Resources.sprite_load("DeerItems", "particle/NightshadeBurst", PATH.."assets/sprites/particle/NightshadeBurst.png", 1, 8, 8)

local GUID  = _ENV["!guid"]
local oP    = gm.constants.oP
local BLACK = Color(0x000000)

-- ── Настройки баланса ──
local LIFETIME    = 800       -- время жизни клона, кадры (~13.3 сек; было 20 сек, уменьшено в 1.5 раза)
local COOLDOWN    = 100       -- кулдаун, секунды (set_cooldown сам умножает на 60 — передаём 100)
local DMG_COEF    = 1.33      -- урон удара = 133% урона игрока (было 200%, уменьшено в 1.5 раза)
local HUNT_RANGE  = 520       -- радиус поиска врага ВОКРУГ ИГРОКА, px
local STRIKE_AOE  = 140       -- радиус взрыва удара, px
local SHOW_TIME   = 42        -- кадров клон виден в фазе удара (~0.7 сек)
local HIDE_TIME   = 30        -- кадров невидим между ударами (~0.5 сек)
local RETRY_TIME  = 18        -- короткая пауза, если врага рядом нет

-- ── Объект-клон ──
local obj = Object.new("DeerItems", "NightshadeClone")
obj:set_sprite(cloneSprite)
obj:set_depth(1)
obj:clear_callbacks()

-- Ближайший враг вокруг ИГРОКА (а не клона) — чтобы охотиться по всему полю боя.
local function nearest_enemy(self, parent)
    local enemy_team = parent.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(parent.x, parent.y, HUNT_RANGE, true, enemy_team, true))
    return found[1]
end

-- Вспышка появления/исчезновения
local function puff(self, blend)
    local fx = gm.instance_create(self.x, self.y, gm.constants.oEfExplosion)
    if fx then
        fx.sprite_index = burst
        if blend then fx.image_blend = blend end
    end
end

obj:onCreate(function(self)
    self.parent      = -4
    self.team        = 1
    self.life        = LIFETIME
    self.state       = 0          -- 0 = скрыт, 1 = виден (удар)
    self.show        = 0          -- реплицируемый флаг видимости для клиентов
    self.phase       = HIDE_TIME  -- счётчик кадров до смены состояния
    self.image_alpha = 0          -- старт невидимым
    self.image_blend = BLACK
    self.image_speed = 0          -- застывшая «теневая» поза, без анимации ходьбы
    self:projectile_sync(10)
end)

obj:onStep(function(self)
    -- На клиенте только РИСУЕМ: позиция приходит из projectile_sync, видимость/облик — из
    -- onDeserialize (self.show / self.parent). Машину состояний НЕ крутим: иначе клиент сам
    -- выбирает другую цель и дерётся с синком позиции (мигание уходит не туда, FX дублируются).
    if gm._mod_net_isClient() then
        local p = self.parent
        if Instance.exists(p) and p.sprite_idle then self.sprite_index = p.sprite_idle end
        self.image_blend = BLACK
        self.image_alpha = (self.show == 1) and 1 or 0
        return
    end

    -- ── ХОСТ: вся логика только здесь ──
    -- Уходит вместе с владельцем / по таймеру
    if not Instance.exists(self.parent) then self:destroy(); return end
    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    local parent = self.parent

    -- Облик чёрной копии игрока (стойка, без ходьбы)
    if parent.sprite_idle and self.sprite_index ~= parent.sprite_idle then
        self.sprite_index = parent.sprite_idle
    end
    self.image_blend = BLACK

    self.phase = self.phase - 1

    if self.state == 0 then
        -- ── Скрыт: невидим, держимся у игрока ──
        self.image_alpha = 0
        self.show = 0
        self.x = parent.x
        self.y = parent.y - 6
        if self.phase > 0 then return end

        -- Пора бить: ищем врага
        local target = nearest_enemy(self, parent)
        if not target then self.phase = RETRY_TIME; return end

        -- Мигаем прямо на врага, становимся видимы
        self.x = target.x
        self.y = target.y - 2
        self.image_xscale = (target.x < parent.x) and -1 or 1
        self.image_alpha  = 1
        self.show  = 1
        self.state = 1
        self.phase = SHOW_TIME
        puff(self, nil)
        if Instance.exists(parent) then parent:sound_play(sndSummon, 0.7, 1.4 + math.random() * 0.3) end

        -- Удар: взрыв на цели за 200% урона игрока (хост — единственный авторитет). proc=false.
        local atk = parent:fire_explosion(target.x, target.y, STRIKE_AOE, STRIKE_AOE, DMG_COEF, burst, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false
            atk.attack_info:set_critical(false)
        end
        if Instance.exists(parent) then parent:sound_play(sndHit, 0.6, 1.1 + math.random() * 0.3) end
    else
        -- ── Виден (фаза удара): стоим на месте видимыми ──
        self.image_alpha = 1
        self.show = 1
        if self.phase > 0 then return end
        -- Исчезаем
        puff(self, BLACK)
        self.image_alpha = 0
        self.show = 0
        self.state = 0
        self.phase = HIDE_TIME
    end
end)

obj:onDestroy(function(self)
    puff(self, nil)
    self:instance_destroy_sync()
end)

-- Сеть: переносим владельца
obj:onSerialize(function(self, buffer)
    buffer:write_instance(self.parent)
    buffer:write_byte(self.show or 0)
end)

obj:onDeserialize(function(self, buffer)
    self.parent = buffer:read_instance()
    self.show   = buffer:read_byte()
    if Instance.exists(self.parent) then self.team = self.parent.team end
end)

-- ── Снаряжение ──
local equip = Equipment.new("DeerItems", "Nightshade")
equip:set_sprite(sprite)
equip:set_loot_tags(Item.LOOT_TAG.category_damage)
equip:set_cooldown(COOLDOWN)

equip:onUse(function(actor)
    actor:sound_play(sndSummon, 1.0, 0.8 + math.random() * 0.2)
    local c = obj:create(actor.x, actor.y - 6)
    c.parent      = actor
    c.team        = actor.team
    c.state       = 0
    c.show        = 0
    c.phase       = HIDE_TIME
    c.image_alpha = 0
    if actor.sprite_idle then c.sprite_index = actor.sprite_idle end
    actor:get_data("DeerItems", GUID).nightshade_inst = c
end)

-- На новой локации убираем оставшихся клонов (страховка к таймеру жизни).
Callback.add(Callback.TYPE.onStageStart, "DeerItems-Nightshade-clear", function(...)
    for _, p in ipairs(Instance.find_all(oP)) do
        local d = p:get_data("DeerItems", GUID)
        if d.nightshade_inst and d.nightshade_inst:exists() then
            d.nightshade_inst:destroy()
            d.nightshade_inst = nil
        end
    end
end)
