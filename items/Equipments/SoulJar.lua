-- DeerItems-SoulJar / В«РЈСЂРЅР° РґСѓС€В» / "Soul Jar"
-- РђРєС‚РёРІРєР° (РїРµСЂРµСЂР°Р±РѕС‚РєР° Goobo Jr РёР· RoR2): РїСЂРёР·С‹РІР°РµС‚ С‚РµРЅРµРІРѕРіРѕ РљР›РћРќРђ-С‚РµР»РµРїРѕСЂС‚С‘СЂР°.
-- Р¦РёРєР», РїРѕРєР° Р¶РёРІ: РЅРµРІРёРґРёРј -> РјРёРіР°РµС‚ Рє Р±Р»РёР¶Р°Р№С€РµРјСѓ РІСЂР°РіСѓ, РїРѕСЏРІР»СЏРµС‚СЃСЏ С‡С‘СЂРЅРѕР№ РєРѕРїРёРµР№ РёРіСЂРѕРєР°
-- Рё Р±СЊС‘С‚ РІР·СЂС‹РІРѕРј РЅР° 133% СѓСЂРѕРЅР° -> С‚СѓС‚ Р¶Рµ СѓС…РѕРґРёС‚ РІ РЅРµРІРёРґРёРјРѕСЃС‚СЊ -> РїРѕРІС‚РѕСЂСЏРµС‚. ~13СЃ, РЅРµСѓСЏР·РІРёРј.
-- РўР°Рє РЅРµС‚ РЅРё В«СЃС‚СЂР°РЅРЅРѕР№ С…РѕРґСЊР±С‹В», РЅРё РїСЂРѕС…РѕРґР° СЃРєРІРѕР·СЊ С‚РµРєСЃС‚СѓСЂС‹ вЂ” РєР»РѕРЅ С‚РѕР»СЊРєРѕ РјРёРіР°РµС‚ (С‚РµР»РµРїРѕСЂС‚).

-- РђСЃСЃРµС‚С‹ (Р·Р°РіР»СѓС€РєРё-С€Р°Р±Р»РѕРЅС‹ вЂ” Р·Р°РјРµРЅРё С‚РµРєСЃС‚СѓСЂС‹/Р·РІСѓРє РїРѕ СЌС‚РёРј РїСѓС‚СЏРј)
local sprite      = Sprite.new("equipment/SoulJar", PATH.."assets/sprites/items/sEquipments/SoulJar.png", 1, 18, 18)
local cloneSprite = Sprite.new("object/SoulJarClone", PATH.."assets/sprites/particle/SoulJarClone.png", 1, 8, 8)
local sndSummon   = Sound.new("SoulJar/summon", PATH.."assets/sounds/SoulJarSummon.ogg")
local sndHit      = Sound.new("SoulJar/hit", PATH.."assets/sounds/SoulJarHit.ogg")
local burst       = Sprite.new("particle/SoulJarBurst", PATH.."assets/sprites/particle/SoulJarBurst.png", 1, 8, 8)

local GUID  = _ENV["!guid"]
local oP    = gm.constants.oP
local BLACK = Color(0x000000)

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local LIFETIME    = 800       -- РІСЂРµРјСЏ Р¶РёР·РЅРё РєР»РѕРЅР°, РєР°РґСЂС‹ (~13.3 СЃРµРє; Р±С‹Р»Рѕ 20 СЃРµРє, СѓРјРµРЅСЊС€РµРЅРѕ РІ 1.5 СЂР°Р·Р°)
local COOLDOWN    = 100       -- РєСѓР»РґР°СѓРЅ, СЃРµРєСѓРЅРґС‹ (set_cooldown СЃР°Рј СѓРјРЅРѕР¶Р°РµС‚ РЅР° 60 вЂ” РїРµСЂРµРґР°С‘Рј 100)
local DMG_COEF    = 2.33      -- СѓСЂРѕРЅ СѓРґР°СЂР° = 133% СѓСЂРѕРЅР° РёРіСЂРѕРєР° (Р±С‹Р»Рѕ 200%, СѓРјРµРЅСЊС€РµРЅРѕ РІ 1.5 СЂР°Р·Р°)
local HUNT_RANGE  = 520       -- СЂР°РґРёСѓСЃ РїРѕРёСЃРєР° РІСЂР°РіР° Р’РћРљР РЈР“ РР“Р РћРљРђ, px
local STRIKE_AOE  = 160       -- СЂР°РґРёСѓСЃ РІР·СЂС‹РІР° СѓРґР°СЂР°, px
local SHOW_TIME   = 42        -- РєР°РґСЂРѕРІ РєР»РѕРЅ РІРёРґРµРЅ РІ С„Р°Р·Рµ СѓРґР°СЂР° (~0.7 СЃРµРє)
local HIDE_TIME   = 30        -- РєР°РґСЂРѕРІ РЅРµРІРёРґРёРј РјРµР¶РґСѓ СѓРґР°СЂР°РјРё (~0.5 СЃРµРє)
local RETRY_TIME  = 18        -- РєРѕСЂРѕС‚РєР°СЏ РїР°СѓР·Р°, РµСЃР»Рё РІСЂР°РіР° СЂСЏРґРѕРј РЅРµС‚

-- РћР±СЉРµРєС‚-РєР»РѕРЅ
local obj = Object.new("SoulJarClone")
obj:set_sprite(cloneSprite)
obj:set_depth(1)
-- Р‘Р»РёР¶Р°Р№С€РёР№ РІСЂР°Рі РІРѕРєСЂСѓРі РР“Р РћРљРђ (Р° РЅРµ РєР»РѕРЅР°) вЂ” С‡С‚РѕР±С‹ РѕС…РѕС‚РёС‚СЊСЃСЏ РїРѕ РІСЃРµРјСѓ РїРѕР»СЋ Р±РѕСЏ.
local function nearest_enemy(self, parent)
    local enemy_team = parent.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(parent.x, parent.y, HUNT_RANGE, true, enemy_team, true))
    return found[1]
end

-- Р’СЃРїС‹С€РєР° РїРѕСЏРІР»РµРЅРёСЏ/РёСЃС‡РµР·РЅРѕРІРµРЅРёСЏ
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
    self.state       = 0          -- 0 = СЃРєСЂС‹С‚, 1 = РІРёРґРµРЅ (СѓРґР°СЂ)
    self.show        = 0          -- СЂРµРїР»РёС†РёСЂСѓРµРјС‹Р№ С„Р»Р°Рі РІРёРґРёРјРѕСЃС‚Рё РґР»СЏ РєР»РёРµРЅС‚РѕРІ
    self.phase       = HIDE_TIME  -- СЃС‡С‘С‚С‡РёРє РєР°РґСЂРѕРІ РґРѕ СЃРјРµРЅС‹ СЃРѕСЃС‚РѕСЏРЅРёСЏ
    self.image_alpha = 0          -- СЃС‚Р°СЂС‚ РЅРµРІРёРґРёРјС‹Рј
    self.image_blend = BLACK
    self.image_speed = 0          -- Р·Р°СЃС‚С‹РІС€Р°СЏ В«С‚РµРЅРµРІР°СЏВ» РїРѕР·Р°, Р±РµР· Р°РЅРёРјР°С†РёРё С…РѕРґСЊР±С‹
    self:projectile_sync(10)
end)

obj:onStep(function(self)
    -- РќР° РєР»РёРµРЅС‚Рµ С‚РѕР»СЊРєРѕ Р РРЎРЈР•Рњ: РїРѕР·РёС†РёСЏ РїСЂРёС…РѕРґРёС‚ РёР· projectile_sync, РІРёРґРёРјРѕСЃС‚СЊ/РѕР±Р»РёРє вЂ” РёР·
    -- onDeserialize (self.show / self.parent). РњР°С€РёРЅСѓ СЃРѕСЃС‚РѕСЏРЅРёР№ РќР• РєСЂСѓС‚РёРј: РёРЅР°С‡Рµ РєР»РёРµРЅС‚ СЃР°Рј
    -- РІС‹Р±РёСЂР°РµС‚ РґСЂСѓРіСѓСЋ С†РµР»СЊ Рё РґРµСЂС‘С‚СЃСЏ СЃ СЃРёРЅРєРѕРј РїРѕР·РёС†РёРё (РјРёРіР°РЅРёРµ СѓС…РѕРґРёС‚ РЅРµ С‚СѓРґР°, FX РґСѓР±Р»РёСЂСѓСЋС‚СЃСЏ).
    if Net.client then
        local p = self.parent
        if Instance.exists(p) and p.sprite_idle then self.sprite_index = p.sprite_idle end
        self.image_blend = BLACK
        self.image_alpha = (self.show == 1) and 1 or 0
        return
    end

    -- Р›РѕРіРёРєСѓ РІС‹РїРѕР»РЅСЏРµС‚ С‚РѕР»СЊРєРѕ С…РѕСЃС‚.
    -- РЈС…РѕРґРёС‚ РІРјРµСЃС‚Рµ СЃ РІР»Р°РґРµР»СЊС†РµРј / РїРѕ С‚Р°Р№РјРµСЂСѓ
    if not Instance.exists(self.parent) then self:destroy(); return end
    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    local parent = self.parent

    -- РћР±Р»РёРє С‡С‘СЂРЅРѕР№ РєРѕРїРёРё РёРіСЂРѕРєР° (СЃС‚РѕР№РєР°, Р±РµР· С…РѕРґСЊР±С‹)
    if parent.sprite_idle and self.sprite_index ~= parent.sprite_idle then
        self.sprite_index = parent.sprite_idle
    end
    self.image_blend = BLACK

    self.phase = self.phase - 1

    if self.state == 0 then
        -- РЎРєСЂС‹С‚: РЅРµРІРёРґРёРј Рё РґРµСЂР¶РёС‚СЃСЏ Сѓ РёРіСЂРѕРєР°.
        self.image_alpha = 0
        self.show = 0
        self.x = parent.x
        self.y = parent.y - 6
        if self.phase > 0 then return end

        -- РџРѕСЂР° Р±РёС‚СЊ: РёС‰РµРј РІСЂР°РіР°
        local target = nearest_enemy(self, parent)
        if not target then self.phase = RETRY_TIME; return end

        -- РњРёРіР°РµРј РїСЂСЏРјРѕ РЅР° РІСЂР°РіР°, СЃС‚Р°РЅРѕРІРёРјСЃСЏ РІРёРґРёРјС‹
        self.x = target.x
        self.y = target.y - 2
        self.image_xscale = (target.x < parent.x) and -1 or 1
        self.image_alpha  = 1
        self.show  = 1
        self.state = 1
        self.phase = SHOW_TIME
        self:instance_resync()
        puff(self, nil)
        if Instance.exists(parent) then parent:sound_play(sndSummon, 0.7, 1.4 + math.random() * 0.3) end

        -- РЈРґР°СЂ: РІР·СЂС‹РІ РЅР° С†РµР»Рё Р·Р° 200% СѓСЂРѕРЅР° РёРіСЂРѕРєР° (С…РѕСЃС‚ вЂ” РµРґРёРЅСЃС‚РІРµРЅРЅС‹Р№ Р°РІС‚РѕСЂРёС‚РµС‚). proc=false.
        local atk = parent:fire_explosion(target.x, target.y, STRIKE_AOE, STRIKE_AOE, DMG_COEF, burst, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false
            atk.attack_info:set_critical(false)
        end
        if Instance.exists(parent) then parent:sound_play(sndHit, 0.6, 1.1 + math.random() * 0.3) end
    else
        -- Р’РёРґРёРј РІРѕ РІСЂРµРјСЏ СѓРґР°СЂР°: СЃС‚РѕРёС‚ РЅР° РјРµСЃС‚Рµ.
        self.image_alpha = 1
        self.show = 1
        if self.phase > 0 then return end
        -- РСЃС‡РµР·Р°РµРј
        puff(self, BLACK)
        self.image_alpha = 0
        self.show = 0
        self.state = 0
        self.phase = HIDE_TIME
        self:instance_resync()
    end
end)

obj:onDestroy(function(self)
    puff(self, nil)
    self:instance_destroy_sync()
end)

-- РЎРµС‚СЊ: РїРµСЂРµРЅРѕСЃРёРј РІР»Р°РґРµР»СЊС†Р°
Object.add_serializers(obj, function(self, buffer)
    buffer:write_instance(self.parent)
    buffer:write_byte(self.show or 0)
end, function(self, buffer)
    self.parent = buffer:read_instance()
    self.show   = buffer:read_byte()
    if Instance.exists(self.parent) then self.team = self.parent.team end
end)

-- РЎРЅР°СЂСЏР¶РµРЅРёРµ
local equip = Equipment.new("SoulJar")
equip:set_sprite(sprite)
equip.loot_tags = Item.LootTag.CATEGORY_DAMAGE
equip.cooldown = COOLDOWN * 60

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
    c:instance_resync()
    actor:get_data("DeerItems", GUID).soul_jar_inst = c
end)

-- РќР° РЅРѕРІРѕР№ Р»РѕРєР°С†РёРё СѓР±РёСЂР°РµРј РѕСЃС‚Р°РІС€РёС…СЃСЏ РєР»РѕРЅРѕРІ (СЃС‚СЂР°С…РѕРІРєР° Рє С‚Р°Р№РјРµСЂСѓ Р¶РёР·РЅРё).
Callback.add(Callback.ON_STAGE_START, function(...)
    for _, p in ipairs(Instance.find_all(oP)) do
        local d = p:get_data("DeerItems", GUID)
        if d.soul_jar_inst and d.soul_jar_inst:exists() then
            d.soul_jar_inst:destroy()
            d.soul_jar_inst = nil
        end
    end
end)
