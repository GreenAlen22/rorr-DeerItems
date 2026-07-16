-- DeerItems-Dombra
-- С вероятностью 20% при попадании справа и слева от игрока появляются крылья беркута,
-- наносящие 122% (+122% за стак) ОБЩЕГО урона каждое.

-- Загружаем спрайт предмета (иконка 36x34).
-- Загружаем спрайт крыльев беркута (визуальный эффект за спиной игрока, 400x128, 1 кадр).
--   Origin по центру (200, 64) — чтобы текстура центрировалась на игроке.
--   ПОД АНИМАЦИЮ: если сделаешь ленту из N кадров по горизонтали, поставь img_num=N и
--   x_orig = (400/N)/2 (центр одного кадра); y_orig = 64.
-- Загружаем звук срабатывания (перебор струн домбры).
local sprite     = Resources.sprite_load("DeerItems", "item/Dombra", PATH.."assets/sprites/items/sRedItems/Dombra.png", 1, 18, 17)
local wingSprite = Resources.sprite_load("DeerItems", "particle/DombraBerkutWings", PATH.."assets/sprites/particle/DombraBerkutWings.png", 1, 200, 64)
local sound      = Resources.sfx_load("DeerItems", "sound/Dombra", PATH.."assets/sounds/BerkutDombra.ogg")

-- Звук не синхронизируется движком вместе с actor:sound_play, поэтому хост
-- отдельно сообщает клиентам о срабатывании, сохраняя одинаковые громкость и тон.
local packet_sound = Packet.new()
packet_sound:onReceived(function(message)
    if not gm._mod_net_isClient() then return end

    local actor = message:read_instance()
    local volume = message:read_float()
    local pitch = message:read_float()
    if Instance.exists(actor) then
        actor:sound_play(sound, volume, pitch)
    end
end)

-- guid мода выносим один раз — для per-actor кулдауна срабатывания
local GUID = _ENV["!guid"]

-- ── Настройки визуала крыльев ────────────────────────────────────────────────
local WING_LIFETIME = 24    -- сколько кадров живут крылья (~0.4 c)
local WING_Y_OFFSET = 16    -- приподнимаем крылья от ног к корпусу игрока
local WING_ANIM_SPD = 0.4   -- скорость анимации спрайта крыльев (когда добавишь кадры; на 1-кадровом — без эффекта)
-- ── Настройки боя ────────────────────────────────────────────────────────────
local PROC_COOLDOWN = 18    -- мин. интервал между срабатываниями (кадры), чтобы звук/крылья не наслаивались
local HIT_OFFSET    = 80    -- смещение зон поражения от игрока (под крупный спрайт 400x128)
local HIT_W         = 195   -- ширина зоны поражения крыла
local HIT_H         = 200   -- высота зоны поражения крыла
-- ─────────────────────────────────────────────────────────────────────────────

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  Объект «крылья беркута» — чисто визуальный эффект за спиной игрока          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local oWing = Object.new("DeerItems", "DombraBerkutWings")
oWing:set_sprite(wingSprite)
oWing:clear_callbacks()

oWing:onCreate(function(self)
    self.timer       = 0
    self.image_speed = WING_ANIM_SPD   -- проигрываем анимацию спрайта (на 1-кадровом — статичен)
    self.image_index = 0
    self.parent      = -4
    self:projectile_sync(8)
end)

oWing:onStep(function(self)
    self.timer = self.timer + 1

    -- Держимся за спиной игрока, пока он двигается
    if Instance.exists(self.parent) then
        self.x     = self.parent.x
        self.y     = self.parent.y - WING_Y_OFFSET
        self.depth = self.parent.depth + 1   -- больше depth = рисуется ЗА игроком
    end

    -- Плавное появление (первые 30%) и затухание (остальное)
    local t = self.timer / WING_LIFETIME
    if t < 0.3 then
        self.image_alpha = t / 0.3
    else
        self.image_alpha = 1 - (t - 0.3) / 0.7
    end

    if self.timer >= WING_LIFETIME then
        self:destroy()
    end
end)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  Предмет «Домбыра»                                                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
-- Привязка спрайта к предмету; тир: красный (легендарный); тег лута: усиление урона.
oWing:onDestroy(function(self)
    self:instance_destroy_sync()
end)

oWing:onSerialize(function(self, buffer)
    buffer:write_instance(self.parent)
end)

oWing:onDeserialize(function(self, buffer)
    self.parent = buffer:read_instance()
end)

local item = Item.new("DeerItems", "Dombra")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Очистка всех коллбеков перед переопределением
item:clear_callbacks()

-- При попадании атакой: шанс 20% призвать крылья беркута слева и справа
item:onAttackHit(function(actor, victim, stack, attack_info)
    if gm._mod_net_isClient() then return end

    -- Анти-наложение: onAttackHit зовётся на КАЖДОЕ попадание (многоцелевые/частые атаки за кадр
    -- дают пачку наложенных звуков). Не чаще одного срабатывания раз в PROC_COOLDOWN кадров.
    local data  = actor:get_data("DeerItems", GUID)
    local frame = Global._current_frame
    if data.dombra_last and (frame - data.dombra_last) < PROC_COOLDOWN then return end

    -- Плоский шанс 20% (не зависит от количества стаков)
    if math.random() >= 0.20 then return end
    data.dombra_last = frame

    -- Звук срабатывания: случайная громкость (0.8–1.2) и высота тона/интонация (0.8–1.3)
    local sound_volume = 0.8 + math.random() * 0.4
    local sound_pitch = 0.8 + math.random() * 0.5
    actor:sound_play(sound, sound_volume, sound_pitch)

    if gm._mod_net_isHost() then
        local message = packet_sound:message_begin()
        message:write_instance(actor)
        message:write_float(sound_volume)
        message:write_float(sound_pitch)
        message:send_to_all()
    end

    -- Визуал: одни большие крылья беркута распахиваются ЗА спиной игрока
    local wing = oWing:create(actor.x, actor.y - WING_Y_OFFSET)
    wing.parent = actor
    wing.depth  = actor.depth + 1

    -- "ОБЩИЙ урон": базовый урон сработавшего удара (без крита)
    local base_damage = attack_info:get_damage_nocrit()
    -- Суммарно оба крыла: 122% +122% за стак → по 61% на каждое крыло
    local dmg = base_damage * 0.61 * stack

    -- Бьём взрывом с каждой стороны игрока (визуал — общие крылья за спиной, спрайт взрыва не нужен)
    for _, dir in ipairs({-1, 1}) do
        local inst = actor:fire_explosion(
            actor.x + HIT_OFFSET * dir,       -- слева (-) и справа (+) от игрока
            actor.y,
            HIT_W, HIT_H,                     -- зона поражения крыла
            dmg,                              -- урон крыла
            nil,                              -- спрайт взрыва
            nil,                              -- спрайт эффекта при попадании (не нужен — визуал общий)
            false                             -- без proc-коэффициента
        )

        -- Настройка урона крыла:
        -- proc = false ОБЯЗАТЕЛЬНО — иначе попадание крыла снова вызовет onAttackHit
        -- и запустит новые крылья → бесконечный самопрок.
        local ai = inst.attack_info
        ai:set_critical(false)                -- крылья не критуют
        ai.proc = false                       -- отключаем проки
        ai:use_raw_damage()                   -- игнорируем модификаторы урона
        ai:set_damage(dmg)                    -- наносим "сырой" урон
    end
end)
