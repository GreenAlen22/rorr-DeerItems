-- DeerItems-DeadWater
-- «Мёртвая вода»: совмещает Rejuvenation Rack и N'kuhana's Opinion из RoR2.
-- 1) Усиливает всё входящее исцеление на +100% за стак.
-- 2) Копит усиленное исцеление как «энергию души» (+100% за стак).
-- 3) Когда энергия души достигает 10% от макс. HP — выпускает самонаводящийся череп,
--    наносящий 250% от накопленной энергии (плоский урон, не крит, не прокает).

-- Загружаем спрайт предмета и спрайт черепа.
-- Эффект импакта и звуки переиспользуем из уже существующих ассетов мода.
local sprite      = Resources.sprite_load("DeerItems", "item/DeadWater", PATH.."assets/sprites/items/sRedItems/DeadWater.png", 1, 18, 17)
local skullSprite = Resources.sprite_load("DeerItems", "particle/DeadWaterSkull", PATH.."assets/sprites/particle/DeadWaterSkull.png", 1, 16, 16)
local burstSprite = Resources.sprite_load("DeerItems", "particle/DeadWaterBurst", PATH.."assets/sprites/particle/Explosive.png", 5, 32, 32)
local sndLaunch   = Resources.sfx_load("DeerItems", "DeadWater/launch", PATH.."assets/sounds/launch.ogg")
local sndImpact   = Resources.sfx_load("DeerItems", "DeadWater/impact", PATH.."assets/sounds/boom.ogg")

-- guid мода: ускоряет get_data (без обхода debug-стека на каждом кадре)
local GUID = _ENV["!guid"]

-- ── Настройки баланса (вынесены, чтобы легко крутить) ─────────────────────────
local THRESHOLD_FRAC = 0.10   -- порог выстрела: 10% от макс. HP
local SKULL_MULT     = 1.5    -- урон черепа: 150% от накопленной энергии души
local HEAL_AMP_BASE  = 0.75   -- усиление входящего исцеления: 75% за первый стак
local HEAL_AMP_STACK = 0.50   -- +50% за каждый стак сверх первого
local SOUL_BASE      = 1.0    -- накопление души: 100% от базового исцеления за первый стак
local SOUL_STACK     = 0.75   -- +75% за каждый стак сверх первого
local FIRE_COOLDOWN  = 12     -- мин. интервал между выстрелами (кадры) — защита от спама при огромном регене
-- ─────────────────────────────────────────────────────────────────────────────

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  Объект «череп» — самонаводящийся снаряд (по образцу AtGMissileMk0)         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local oSkull = Object.new("DeerItems", "DeadWaterSkull")
oSkull:set_sprite(skullSprite)
oSkull:clear_callbacks()

oSkull:onCreate(function(self)
    self.timer = 0
    self.mask_index = gm.constants.sSinglePixel
    self.speed = 5
    self.parent = -4
    self.target = -4
    self.team = 1
    self.dmg = 0
    -- Синхронизация объекта в сетевой игре
    self:projectile_sync(10)
end)

oSkull:onStep(function(self)
    -- Удаляем череп, если владелец исчез
    if not Instance.exists(self.parent) then
        self:destroy()
        return
    end
    self.timer = self.timer + 1

    -- Поиск цели, если текущей нет
    local t = self.target
    if not Instance.exists(t) then
        t = self:find_target_nearest()
        if t ~= -4 then
            t = t.parent
            self.target = t
            self:instance_resync()
        else
            self.target = -4
        end
    end

    if Instance.exists(t) then
        local tdir = gm.point_direction(self.x, self.y, t.x, t.y)
        -- Вблизи — жёсткое наведение, издалека — плавный доворот
        if self:distance_to_object(t) < 70 then
            self.direction = tdir
        else
            self:turn_towards(self.direction, tdir)
        end
        -- Разгон до лимита
        self.speed = math.min(13, self.speed + 0.25)
        -- Попадание
        if self:is_colliding(t) then
            if gm._mod_net_isHost() and self:attack_collision_canhit(t) then
                -- Плоский урон = 150% энергии души. damage у fire_explosion — коэффициент от урона актёра,
                -- поэтому фиксируем итог через raw damage, чтобы энергия души не умножалась на actor.damage.
                -- proc=false обязателен: иначе урон черепа
                -- мог бы прокать другие предметы и сам себя.
                local atk = self.parent:fire_explosion(self.x, self.y, 48, 48, self.dmg, burstSprite, nil, false)
                if atk and atk.attack_info then
                    atk.attack_info:use_raw_damage()
                    atk.attack_info:set_damage(self.dmg)
                    atk.attack_info.proc = false
                    atk.attack_info:set_critical(false)
                end
            end
            self:destroy()
            return
        end
    else
        -- Цель не найдена долго — самоликвидация; иначе слегка рыскаем в поиске
        if self.timer > 120 then
            self:destroy()
            return
        else
            self.direction = self.direction + math.sin(self.timer / 5) * 5
        end
    end

    self.image_angle = self.direction
end)

oSkull:onDestroy(function(self)
    if Instance.exists(self.parent) then
        self.parent:sound_play(sndImpact, 1.0, 1.1 + math.random() * 0.3)
    end
    -- Визуальный эффект импакта
    gm.instance_create(self.x, self.y, gm.constants.oEfExplosion).sprite_index = burstSprite
    -- Удаление в сетевой игре
    self:instance_destroy_sync()
end)

-- Сохранение/загрузка состояния для сетевой игры (урон считается на хосте, его слать не нужно)
oSkull:onSerialize(function(self, buffer)
    buffer:write_instance(self.target)
    buffer:write_instance(self.parent)
    gm.write_direction(self.direction)
end)

oSkull:onDeserialize(function(self, buffer)
    self.target = buffer:read_instance()
    self.parent = buffer:read_instance()
    self.team = self.parent.team
    self.direction = gm.read_direction()
end)

-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  Предмет «Мёртвая вода»                                                     ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
local item = Item.new("DeerItems", "DeadWater")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_healing)
item:clear_callbacks()

-- Главная логика: каждый кадр отслеживаем прирост HP (= исцеление за этот кадр),
-- усиливаем его, копим в энергию души и при достижении порога выпускаем череп.
--
-- Важно: захват исцеления идёт по дельте HP, поэтому ловит И actor:heal(), И hp_regen.
-- Ограничение метода — оверхил (лечение «в потолок» при полном HP) не виден через дельту;
-- усиление при этом тоже теряется. Полный захват оверхила потребовал бы хука gml-функции
-- лечения (имя константы нужно подтвердить в игре) — см. заметку в ответе.
item:onPostStep(function(actor, stack)
    -- Логика — на хосте; на клиентах HP синхронизируется, чтобы не было двойного срабатывания.
    if gm._mod_net_isClient() then return end

    local data = actor:get_data("DeadWater", GUID)
    data.soul = data.soul or 0
    if data.dw_cd and data.dw_cd > 0 then data.dw_cd = data.dw_cd - 1 end

    local hp    = actor.hp
    local maxhp = actor.maxhp

    -- Первый кадр после получения — просто запоминаем базовые значения
    if data.dw_prevHp == nil then
        data.dw_prevHp  = hp
        data.dw_prevMax = maxhp
        return
    end

    -- Засчитываем исцелением прирост HP, только если макс. HP не менялся в этом кадре
    -- (иначе скачок maxhp от уровня/предметов приняли бы за лечение).
    if maxhp == data.dw_prevMax and hp > data.dw_prevHp then
        local baseHeal = hp - data.dw_prevHp

        -- Усиление: 75% (+50%/стак). ВАЖНО: бонус пишем в HP НАПРЯМУЮ (мгновенно), а не через
        -- actor:heal(). actor:heal сетевой и применяется не в тот же кадр → бонус попадал в дельту
        -- HP СЛЕДУЮЩЕГО кадра, снова усиливался, и так по кругу = экспоненциальный «оверхил»
        -- (реген «лютo» заполнял полоску). Прямая запись закрывает этот цикл.
        local heal_amp = HEAL_AMP_BASE + HEAL_AMP_STACK * (stack - 1)
        local bonus = baseHeal * heal_amp
        if bonus > 0 then
            actor.hp = math.min(maxhp, actor.hp + bonus)
            hp = actor.hp -- учли бонус, чтобы не пересчитать его как новое лечение
        end

        -- Накопление души от БАЗОВОГО исцеления: 100% (+75%/стак), линейно.
        local soul_factor = SOUL_BASE + SOUL_STACK * (stack - 1)
        data.soul = data.soul + baseHeal * soul_factor
    end

    -- Выстрел при достижении порога (с внутренним кулдауном против спама)
    local threshold = maxhp * THRESHOLD_FRAC
    if threshold > 0 and data.soul >= threshold and (data.dw_cd or 0) <= 0 then
        if gm._mod_net_isHost() then
            actor:sound_play(sndLaunch, 0.9, 1.1 + math.random() * 0.3)
            local s = oSkull:create(actor.x, actor.y - 24)
            s.parent    = actor
            s.team      = actor.team
            s.dmg       = data.soul * SKULL_MULT
            s.direction = math.random(0, 359)
        end
        data.soul  = 0
        data.dw_cd = FIRE_COOLDOWN
    end

    data.dw_prevHp  = actor.hp
    data.dw_prevMax = maxhp
end)

-- Визуал: индикатор накопления энергии души над персонажем
item:onPostDraw(function(actor, stack)
    local data = actor:get_data("DeadWater", GUID)
    local threshold = actor.maxhp * THRESHOLD_FRAC
    if threshold <= 0 then return end

    local frac = math.min((data.soul or 0) / threshold, 1)
    local w, x, y = 24, actor.x - 12, actor.y - 52
    gm.draw_set_colour(Color(0x301038))            -- фон шкалы
    gm.draw_rectangle(x, y, x + w, y + 3, false)
    gm.draw_set_colour(Color(0xc060ff))            -- фиолетовая энергия души
    gm.draw_rectangle(x, y, x + w * frac, y + 3, false)
end)
