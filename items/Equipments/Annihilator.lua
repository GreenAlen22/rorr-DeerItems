-- DeerItems-Annihilator / «Аннигилятор» / "Annihilator"
-- Активка (адаптация Preon Accumulator из RoR2): выпускает медленный заряд, который бьёт
-- молниями-тендрилами по ближним врагам (до 600%/сек) и при контакте/истечении взрывается
-- огромным взрывом на 20м за 4000% урона. cd 140с.

-- Ассеты (заглушки-шаблоны — замени текстуры/звук по этим путям)
local sprite       = Resources.sprite_load("DeerItems", "equipment/Annihilator", PATH.."assets/sprites/items/sEquipments/Annihilator.png", 1, 18, 18)
local chargeSprite = Resources.sprite_load("DeerItems", "particle/AnnihilatorCharge", PATH.."assets/sprites/particle/AnnihilatorCharge.png", 14, 64, 64)
local exploSprite  = Resources.sprite_load("DeerItems", "particle/AnnihilatorBoom", PATH.."assets/sprites/particle/AnnihilatorBoom.png", 8, 75, 75)
local zapSprite    = Resources.sprite_load("DeerItems", "particle/AnnihilatorZap", PATH.."assets/sprites/particle/AnnihilatorZap.png", 4, 8, 8)
local sndLaunch    = Resources.sfx_load("DeerItems", "Annihilator/launch", PATH.."assets/sounds/AnnihilatorLaunch.ogg")
local sndBoom      = Resources.sfx_load("DeerItems", "Annihilator/boom", PATH.."assets/sounds/AnnihilatorBoom.ogg")

-- ── Настройки баланса ──
local COOLDOWN       = 140       -- кулдаун, секунды
local CHARGE_SPEED   = 3         -- скорость заряда, px/кадр (медленный)
local LIFETIME       = 150       -- макс. время полёта до самоподрыва, кадры (~2.5 сек)
local TENDRIL_RANGE  = 192       -- радиус действия молний, px
local TENDRIL_EVERY  = 16.2        -- частота молний, кадры (3.7 раз/сек)
local TENDRIL_TARGETS= 2         -- сколько целей бьёт за тик
local TENDRIL_COEF   = 0.6       -- урон молнии за тик (0.6×3.7/сек = 222%/сек на цель)
local EXPLO_COEF     = 22.22      -- урон взрыва = 2222 % урона игрока (коэффициент)
local EXPLO_SIZE     = 22 * 32   -- размер взрыва, px (22 м ≈ 640px)
local CONTACT_RADIUS = 32        -- дистанция «контакта» с врагом для подрыва, px

-- ── Объект «заряд» ──
local oCharge = Object.new("DeerItems", "AnnihilatorCharge")
oCharge:set_sprite(chargeSprite)
oCharge:clear_callbacks()

oCharge:onCreate(function(self)
    self.timer = 0
    self.zap = 0
    self.mask_index = gm.constants.sSinglePixel
    self.speed = CHARGE_SPEED
    self.parent = -4
    self.team = 1
    self.image_speed = 0.4
    self:projectile_sync(10)
end)

oCharge:onStep(function(self)
    if not Instance.exists(self.parent) then self:destroy(); return end
    self.timer = self.timer + 1
    self.image_angle = self.direction

    local enemy_team = self.parent.team == 1 and 2 or 1

    -- Тендрилы: периодически бьём ближних врагов (урон считает хост, proc=false — не прокаем)
    self.zap = self.zap + 1
    if self.zap >= TENDRIL_EVERY then
        self.zap = 0
        if gm._mod_net_isHost() then
            local found = List.wrap(self:find_characters_circle(self.x, self.y, TENDRIL_RANGE, true, enemy_team, true))
            for i = 1, math.min(TENDRIL_TARGETS, #found) do
                local e = found[i]
                local hit = self.parent:fire_direct(e, TENDRIL_COEF, 0, e.x, e.y, zapSprite, false)
                if hit and hit.attack_info then
                    hit.attack_info.proc = false
                    hit.attack_info:set_critical(false)
                end
            end
        end
    end

    -- Подрыв при контакте с врагом или по истечении времени
    local detonate = self.timer >= LIFETIME
    if not detonate then
        local t = self:find_target_nearest()
        if t ~= -4 and Instance.exists(t.parent)
           and gm.point_distance(self.x, self.y, t.parent.x, t.parent.y) < CONTACT_RADIUS then
            detonate = true
        end
    end
    if detonate then self:destroy() end
end)

oCharge:onDestroy(function(self)
    if Instance.exists(self.parent) then
        self.parent:sound_play(sndBoom, 1.0, 0.8 + math.random() * 0.2)
        self.parent:screen_shake(8)
        -- Большой взрыв на 4000% (только хост наносит урон)
        if gm._mod_net_isHost() then
            local atk = self.parent:fire_explosion(self.x, self.y, EXPLO_SIZE, EXPLO_SIZE, EXPLO_COEF, exploSprite, zapSprite, false)
            if atk then
                atk.max_hit_number = 50   -- огромный радиус должен задеть всех в зоне
                if atk.attack_info then
                    atk.attack_info.proc = false
                    atk.attack_info:set_critical(false)
                end
            end
        end
    end
    -- Визуал взрыва (увеличиваем спрайт под размер зоны)
    local ef = gm.instance_create(self.x, self.y, gm.constants.oEfExplosion)
    ef.sprite_index = exploSprite
    ef.image_xscale = EXPLO_SIZE / 96
    ef.image_yscale = EXPLO_SIZE / 96
    self:instance_destroy_sync()
end)

-- Сеть: переносим владельца и направление
oCharge:onSerialize(function(self, buffer)
    buffer:write_instance(self.parent)
    gm.write_direction(self.direction)
end)

oCharge:onDeserialize(function(self, buffer)
    self.parent = buffer:read_instance()
    if Instance.exists(self.parent) then self.team = self.parent.team end
    self.direction = gm.read_direction()
end)

-- ── Снаряжение ──
local equip = Equipment.new("DeerItems", "Annihilator")
equip:set_sprite(sprite)
equip:set_loot_tags(Item.LOOT_TAG.category_damage)
equip:set_cooldown(COOLDOWN)

equip:onUse(function(actor)
    actor:sound_play(sndLaunch, 1.0, 0.9 + math.random() * 0.2)
    local c = oCharge:create(actor.x + actor.image_xscale * 16, actor.y - 16)
    c.parent = actor
    c.team   = actor.team
    c.direction = (actor.image_xscale >= 0) and 0 or 180
end)
