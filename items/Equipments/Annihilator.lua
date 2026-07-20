-- DeerItems-Annihilator / В«РђРЅРЅРёРіРёР»СЏС‚РѕСЂВ» / "Annihilator"
-- РђРєС‚РёРІРєР° (Р°РґР°РїС‚Р°С†РёСЏ Preon Accumulator РёР· RoR2): РІС‹РїСѓСЃРєР°РµС‚ РјРµРґР»РµРЅРЅС‹Р№ Р·Р°СЂСЏРґ, РєРѕС‚РѕСЂС‹Р№ Р±СЊС‘С‚
-- РјРѕР»РЅРёСЏРјРё-С‚РµРЅРґСЂРёР»Р°РјРё РїРѕ Р±Р»РёР¶РЅРёРј РІСЂР°РіР°Рј (РґРѕ 600%/СЃРµРє) Рё РїСЂРё РєРѕРЅС‚Р°РєС‚Рµ/РёСЃС‚РµС‡РµРЅРёРё РІР·СЂС‹РІР°РµС‚СЃСЏ
-- РѕРіСЂРѕРјРЅС‹Рј РІР·СЂС‹РІРѕРј РЅР° 20Рј Р·Р° 4000% СѓСЂРѕРЅР°. cd 140СЃ.

-- РђСЃСЃРµС‚С‹ (Р·Р°РіР»СѓС€РєРё-С€Р°Р±Р»РѕРЅС‹ вЂ” Р·Р°РјРµРЅРё С‚РµРєСЃС‚СѓСЂС‹/Р·РІСѓРє РїРѕ СЌС‚РёРј РїСѓС‚СЏРј)
local sprite       = Sprite.new("equipment/Annihilator", PATH.."assets/sprites/items/sEquipments/Annihilator.png", 1, 18, 18)
local chargeSprite = Sprite.new("particle/AnnihilatorCharge", PATH.."assets/sprites/particle/AnnihilatorCharge.png", 14, 64, 64)
local exploSprite  = Sprite.new("particle/AnnihilatorBoom", PATH.."assets/sprites/particle/AnnihilatorBoom.png", 8, 75, 75)
local zapSprite    = Sprite.new("particle/AnnihilatorZap", PATH.."assets/sprites/particle/AnnihilatorZap.png", 4, 8, 8)
local sndLaunch    = Sound.new("Annihilator/launch", PATH.."assets/sounds/AnnihilatorLaunch.ogg")
local sndBoom      = Sound.new("Annihilator/boom", PATH.."assets/sounds/AnnihilatorBoom.ogg")

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local COOLDOWN       = 140       -- РєСѓР»РґР°СѓРЅ, СЃРµРєСѓРЅРґС‹
local CHARGE_SPEED   = 3         -- СЃРєРѕСЂРѕСЃС‚СЊ Р·Р°СЂСЏРґР°, px/РєР°РґСЂ (РјРµРґР»РµРЅРЅС‹Р№)
local LIFETIME       = 150       -- РјР°РєСЃ. РІСЂРµРјСЏ РїРѕР»С‘С‚Р° РґРѕ СЃР°РјРѕРїРѕРґСЂС‹РІР°, РєР°РґСЂС‹ (~2.5 СЃРµРє)
local TENDRIL_RANGE  = 192       -- СЂР°РґРёСѓСЃ РґРµР№СЃС‚РІРёСЏ РјРѕР»РЅРёР№, px
local TENDRIL_EVERY  = 16.2        -- С‡Р°СЃС‚РѕС‚Р° РјРѕР»РЅРёР№, РєР°РґСЂС‹ (3.7 СЂР°Р·/СЃРµРє)
local TENDRIL_TARGETS= 2         -- СЃРєРѕР»СЊРєРѕ С†РµР»РµР№ Р±СЊС‘С‚ Р·Р° С‚РёРє
local TENDRIL_COEF   = 0.6       -- СѓСЂРѕРЅ РјРѕР»РЅРёРё Р·Р° С‚РёРє (0.6Г—3.7/СЃРµРє = 222%/СЃРµРє РЅР° С†РµР»СЊ)
local EXPLO_COEF     = 22.22      -- СѓСЂРѕРЅ РІР·СЂС‹РІР° = 2222 % СѓСЂРѕРЅР° РёРіСЂРѕРєР° (РєРѕСЌС„С„РёС†РёРµРЅС‚)
local EXPLO_SIZE     = 22 * 32   -- СЂР°Р·РјРµСЂ РІР·СЂС‹РІР°, px (22 Рј в‰€ 640px)
local CONTACT_RADIUS = 32        -- РґРёСЃС‚Р°РЅС†РёСЏ В«РєРѕРЅС‚Р°РєС‚Р°В» СЃ РІСЂР°РіРѕРј РґР»СЏ РїРѕРґСЂС‹РІР°, px

-- РћР±СЉРµРєС‚ В«Р·Р°СЂСЏРґВ»
local oCharge = Object.new("AnnihilatorCharge")
oCharge:set_sprite(chargeSprite)
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
    -- Р—Р°СЂСЏРґ СЂР°СЃСЃС‡РёС‚С‹РІР°РµС‚ С…РѕСЃС‚. РљР»РёРµРЅС‚С‹ С‚РѕР»СЊРєРѕ СЂРёСЃСѓСЋС‚ СЃРЅР°СЂСЏРґ, СЃРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅРЅС‹Р№ С‡РµСЂРµР·
    -- projectile_sync, Рё РЅРµ РґРІРёРіР°СЋС‚ РІС‚РѕСЂСѓСЋ Р»РѕРєР°Р»СЊРЅСѓСЋ РєРѕРїРёСЋ.
    if Net.client then return end

    if not Instance.exists(self.parent) then self:destroy(); return end
    self.timer = self.timer + 1
    self.image_angle = self.direction

    local enemy_team = self.parent.team == 1 and 2 or 1

    -- РўРµРЅРґСЂРёР»С‹: РїРµСЂРёРѕРґРёС‡РµСЃРєРё Р±СЊС‘Рј Р±Р»РёР¶РЅРёС… РІСЂР°РіРѕРІ (СѓСЂРѕРЅ СЃС‡РёС‚Р°РµС‚ С…РѕСЃС‚, proc=false вЂ” РЅРµ РїСЂРѕРєР°РµРј)
    self.zap = self.zap + 1
    if self.zap >= TENDRIL_EVERY then
        self.zap = 0
        if Net.host then
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

    -- РџРѕРґСЂС‹РІ РїСЂРё РєРѕРЅС‚Р°РєС‚Рµ СЃ РІСЂР°РіРѕРј РёР»Рё РїРѕ РёСЃС‚РµС‡РµРЅРёРё РІСЂРµРјРµРЅРё
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
        -- Р‘РѕР»СЊС€РѕР№ РІР·СЂС‹РІ РЅР° 4000% (С‚РѕР»СЊРєРѕ С…РѕСЃС‚ РЅР°РЅРѕСЃРёС‚ СѓСЂРѕРЅ)
        if Net.host then
            local atk = self.parent:fire_explosion(self.x, self.y, EXPLO_SIZE, EXPLO_SIZE, EXPLO_COEF, exploSprite, zapSprite, false)
            if atk then
                atk.max_hit_number = 50   -- РѕРіСЂРѕРјРЅС‹Р№ СЂР°РґРёСѓСЃ РґРѕР»Р¶РµРЅ Р·Р°РґРµС‚СЊ РІСЃРµС… РІ Р·РѕРЅРµ
                if atk.attack_info then
                    atk.attack_info.proc = false
                    atk.attack_info:set_critical(false)
                end
            end
        end
    end
    -- Р’РёР·СѓР°Р» РІР·СЂС‹РІР° (СѓРІРµР»РёС‡РёРІР°РµРј СЃРїСЂР°Р№С‚ РїРѕРґ СЂР°Р·РјРµСЂ Р·РѕРЅС‹)
    local ef = gm.instance_create(self.x, self.y, gm.constants.oEfExplosion)
    ef.sprite_index = exploSprite
    ef.image_xscale = EXPLO_SIZE / 96
    ef.image_yscale = EXPLO_SIZE / 96
    self:instance_destroy_sync()
end)

-- РЎРµС‚СЊ: РїРµСЂРµРЅРѕСЃРёРј РІР»Р°РґРµР»СЊС†Р° Рё РЅР°РїСЂР°РІР»РµРЅРёРµ
Object.add_serializers(oCharge, function(self, buffer)
    buffer:write_instance(self.parent)
    gm.write_direction(self.direction)
end, function(self, buffer)
    self.parent = buffer:read_instance()
    if Instance.exists(self.parent) then self.team = self.parent.team end
    self.direction = gm.read_direction()
end)

-- РЎРЅР°СЂСЏР¶РµРЅРёРµ
local equip = Equipment.new("Annihilator")
equip:set_sprite(sprite)
equip.loot_tags = Item.LootTag.CATEGORY_DAMAGE
equip.cooldown = COOLDOWN * 60

equip:onUse(function(actor)
    -- РљРѕР»Р»Р±РµРє СЃРЅР°СЂСЏР¶РµРЅРёСЏ РІС‹Р·С‹РІР°РµС‚СЃСЏ Сѓ РІСЃРµС…. РЎРѕР·РґР°С‘Рј Р·Р°СЂСЏРґ С‚РѕР»СЊРєРѕ РЅР° С…РѕСЃС‚Рµ, С‡С‚РѕР±С‹
    -- СЃРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅРЅС‹Р№ projectile_sync Р±С‹Р» РµРґРёРЅСЃС‚РІРµРЅРЅРѕР№ РєРѕРїРёРµР№, РІРёРґРёРјРѕР№ РєР»РёРµРЅС‚Р°Рј.
    if not Net.host then return end

    actor:sound_play(sndLaunch, 1.0, 0.9 + math.random() * 0.2)
    local c = oCharge:create(actor.x + actor.image_xscale * 16, actor.y - 16)
    c.parent = actor
    c.team   = actor.team
    c.direction = (actor.image_xscale >= 0) and 0 or 180
end)
