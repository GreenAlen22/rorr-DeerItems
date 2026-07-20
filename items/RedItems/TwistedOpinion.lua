-- DeerItems-TwistedOpinion
-- В«РњС‘СЂС‚РІР°СЏ РІРѕРґР°В»: СЃРѕРІРјРµС‰Р°РµС‚ Rejuvenation Rack Рё N'kuhana's Opinion РёР· RoR2.
-- 1) РЈСЃРёР»РёРІР°РµС‚ РІСЃС‘ РІС…РѕРґСЏС‰РµРµ РёСЃС†РµР»РµРЅРёРµ РЅР° +100% Р·Р° СЃС‚Р°Рє.
-- 2) РљРѕРїРёС‚ СѓСЃРёР»РµРЅРЅРѕРµ РёСЃС†РµР»РµРЅРёРµ РєР°Рє В«СЌРЅРµСЂРіРёСЋ РґСѓС€РёВ» (+100% Р·Р° СЃС‚Р°Рє).
-- 3) РљРѕРіРґР° СЌРЅРµСЂРіРёСЏ РґСѓС€Рё РґРѕСЃС‚РёРіР°РµС‚ 10% РѕС‚ РјР°РєСЃ. HP вЂ” РІС‹РїСѓСЃРєР°РµС‚ СЃР°РјРѕРЅР°РІРѕРґСЏС‰РёР№СЃСЏ С‡РµСЂРµРї,
--    РЅР°РЅРѕСЃСЏС‰РёР№ 250% РѕС‚ РЅР°РєРѕРїР»РµРЅРЅРѕР№ СЌРЅРµСЂРіРёРё (РїР»РѕСЃРєРёР№ СѓСЂРѕРЅ, РЅРµ РєСЂРёС‚, РЅРµ РїСЂРѕРєР°РµС‚).

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° Рё СЃРїСЂР°Р№С‚ С‡РµСЂРµРїР°.
-- Р­С„С„РµРєС‚ РёРјРїР°РєС‚Р° Рё Р·РІСѓРєРё РїРµСЂРµРёСЃРїРѕР»СЊР·СѓРµРј РёР· СѓР¶Рµ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёС… Р°СЃСЃРµС‚РѕРІ РјРѕРґР°.
local sprite      = Sprite.new("item/TwistedOpinion", PATH.."assets/sprites/items/sRedItems/TwistedOpinion.png", 1, 18, 17)
local skullSprite = Sprite.new("particle/TwistedOpinionSkull", PATH.."assets/sprites/particle/TwistedOpinionSkull.png", 1, 16, 16)
local burstSprite = Sprite.new("particle/TwistedOpinionBurst", PATH.."assets/sprites/particle/TwistedOpinionBurst.png", 10, 16, 16)
local barSprite   = Sprite.new("particle/TwistedOpinionCustomBar", PATH.."assets/sprites/particle/TwistedOpinionCustomBar.png", 1, 0, 0)
local sndLaunch   = Sound.new("TwistedOpinion/launch", PATH.."assets/sounds/TwistedOpinionLaunch.ogg")
local sndImpact   = Sound.new("TwistedOpinion/impact", PATH.."assets/sounds/TwistedOpinionImpact.ogg")

-- guid РјРѕРґР°: СѓСЃРєРѕСЂСЏРµС‚ get_data (Р±РµР· РѕР±С…РѕРґР° debug-СЃС‚РµРєР° РЅР° РєР°Р¶РґРѕРј РєР°РґСЂРµ)
local GUID = _ENV["!guid"]

local packet_soul = Packet.new("TwistedOpinion-packet_soul")

local HUD_FILL_X    = 4
local HUD_FILL_Y    = 8
local HUD_FILL_W    = 50
local HUD_FILL_H    = 6
local HUD_X         = 244
local HUD_Y         = 36
local HUD_FILL_BG   = Color(0x1b1020)
local HUD_FILL_FG   = Color(0xc060ff)

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°: РІС‹РЅРµСЃРµРЅС‹ РѕС‚РґРµР»СЊРЅРѕ, С‡С‚РѕР±С‹ РёС… Р±С‹Р»Рѕ РїСЂРѕС‰Рµ РјРµРЅСЏС‚СЊ.
local THRESHOLD_FRAC = 0.10   -- РїРѕСЂРѕРі РІС‹СЃС‚СЂРµР»Р°: 10% РѕС‚ РјР°РєСЃ. HP
local SKULL_MULT     = 1.5    -- СѓСЂРѕРЅ С‡РµСЂРµРїР°: 150% РѕС‚ РЅР°РєРѕРїР»РµРЅРЅРѕР№ СЌРЅРµСЂРіРёРё РґСѓС€Рё
local HEAL_AMP_BASE  = 0.75   -- СѓСЃРёР»РµРЅРёРµ РІС…РѕРґСЏС‰РµРіРѕ РёСЃС†РµР»РµРЅРёСЏ: 75% Р·Р° РїРµСЂРІС‹Р№ СЃС‚Р°Рє
local HEAL_AMP_STACK = 0.50   -- +50% Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ
local SOUL_BASE      = 1.0    -- РЅР°РєРѕРїР»РµРЅРёРµ РґСѓС€Рё: 100% РѕС‚ Р±Р°Р·РѕРІРѕРіРѕ РёСЃС†РµР»РµРЅРёСЏ Р·Р° РїРµСЂРІС‹Р№ СЃС‚Р°Рє
local SOUL_STACK     = 0.75   -- +75% Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ
local FIRE_COOLDOWN  = 6     -- РјРёРЅ. РёРЅС‚РµСЂРІР°Р» РјРµР¶РґСѓ РІС‹СЃС‚СЂРµР»Р°РјРё (РєР°РґСЂС‹) вЂ” Р·Р°С‰РёС‚Р° РѕС‚ СЃРїР°РјР° РїСЂРё РѕРіСЂРѕРјРЅРѕРј СЂРµРіРµРЅРµ

-- в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
-- в•‘  РћР±СЉРµРєС‚ В«С‡РµСЂРµРїВ» вЂ” СЃР°РјРѕРЅР°РІРѕРґСЏС‰РёР№СЃСЏ СЃРЅР°СЂСЏРґ (РїРѕ РѕР±СЂР°Р·С†Сѓ AtGMissileMk0)         в•‘
-- в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ
local oSkull = Object.new("TwistedOpinionSkull")
oSkull:set_sprite(skullSprite)
Callback.add(oSkull.on_create, function(self)
    self.timer = 0
    self.mask_index = gm.constants.sSinglePixel
    self.speed = 5
    self.parent = -4
    self.target = -4
    self.team = 1
    self.dmg = 0
    -- РЎРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏ РѕР±СЉРµРєС‚Р° РІ СЃРµС‚РµРІРѕР№ РёРіСЂРµ
    self:projectile_sync(10)
end)

Callback.add(oSkull.on_step, function(self)
    -- РЈРґР°Р»СЏРµРј С‡РµСЂРµРї, РµСЃР»Рё РІР»Р°РґРµР»РµС† РёСЃС‡РµР·
    if not Instance.exists(self.parent) then
        self:destroy()
        return
    end
    self.timer = self.timer + 1

    -- РџРѕРёСЃРє С†РµР»Рё, РµСЃР»Рё С‚РµРєСѓС‰РµР№ РЅРµС‚
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
        -- Р’Р±Р»РёР·Рё вЂ” Р¶С‘СЃС‚РєРѕРµ РЅР°РІРµРґРµРЅРёРµ, РёР·РґР°Р»РµРєР° вЂ” РїР»Р°РІРЅС‹Р№ РґРѕРІРѕСЂРѕС‚
        if self:distance_to_object(t) < 70 then
            self.direction = tdir
        else
            self:turn_towards(self.direction, tdir)
        end
        -- Р Р°Р·РіРѕРЅ РґРѕ Р»РёРјРёС‚Р°
        self.speed = math.min(13, self.speed + 0.25)
        -- РџРѕРїР°РґР°РЅРёРµ
        if self:is_colliding(t) then
            if Net.host and self:attack_collision_canhit(t) then
                -- РџР»РѕСЃРєРёР№ СѓСЂРѕРЅ = 150% СЌРЅРµСЂРіРёРё РґСѓС€Рё. damage Сѓ fire_explosion вЂ” РєРѕСЌС„С„РёС†РёРµРЅС‚ РѕС‚ СѓСЂРѕРЅР° Р°РєС‚С‘СЂР°,
                -- РїРѕСЌС‚РѕРјСѓ С„РёРєСЃРёСЂСѓРµРј РёС‚РѕРі С‡РµСЂРµР· raw damage, С‡С‚РѕР±С‹ СЌРЅРµСЂРіРёСЏ РґСѓС€Рё РЅРµ СѓРјРЅРѕР¶Р°Р»Р°СЃСЊ РЅР° actor.damage.
                -- proc=false РѕР±СЏР·Р°С‚РµР»РµРЅ: РёРЅР°С‡Рµ СѓСЂРѕРЅ С‡РµСЂРµРїР°
                -- РјРѕРі Р±С‹ РїСЂРѕРєР°С‚СЊ РґСЂСѓРіРёРµ РїСЂРµРґРјРµС‚С‹ Рё СЃР°Рј СЃРµР±СЏ.
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
        -- Р¦РµР»СЊ РЅРµ РЅР°Р№РґРµРЅР° РґРѕР»РіРѕ вЂ” СЃР°РјРѕР»РёРєРІРёРґР°С†РёСЏ; РёРЅР°С‡Рµ СЃР»РµРіРєР° СЂС‹СЃРєР°РµРј РІ РїРѕРёСЃРєРµ
        if self.timer > 120 then
            self:destroy()
            return
        else
            self.direction = self.direction + math.sin(self.timer / 5) * 5
        end
    end

    self.image_angle = self.direction
end)

Callback.add(oSkull.on_destroy, function(self)
    if Instance.exists(self.parent) then
        self.parent:sound_play(sndImpact, 1.0, 1.1 + math.random() * 0.3)
    end
    -- Р’РёР·СѓР°Р»СЊРЅС‹Р№ СЌС„С„РµРєС‚ РёРјРїР°РєС‚Р°
    gm.instance_create(self.x, self.y, gm.constants.oEfExplosion).sprite_index = burstSprite
    -- РЈРґР°Р»РµРЅРёРµ РІ СЃРµС‚РµРІРѕР№ РёРіСЂРµ
    self:instance_destroy_sync()
end)

-- РЎРѕС…СЂР°РЅРµРЅРёРµ/Р·Р°РіСЂСѓР·РєР° СЃРѕСЃС‚РѕСЏРЅРёСЏ РґР»СЏ СЃРµС‚РµРІРѕР№ РёРіСЂС‹ (СѓСЂРѕРЅ СЃС‡РёС‚Р°РµС‚СЃСЏ РЅР° С…РѕСЃС‚Рµ, РµРіРѕ СЃР»Р°С‚СЊ РЅРµ РЅСѓР¶РЅРѕ)
Object.add_serializers(oSkull, function(self, buffer)
    buffer:write_instance(self.target)
    buffer:write_instance(self.parent)
    gm.write_direction(self.direction)
end, function(self, buffer)
    self.target = buffer:read_instance()
    self.parent = buffer:read_instance()
    self.team = self.parent.team
    self.direction = gm.read_direction()
end)

packet_soul:set_serializers(function(buffer, actor, soul)
    buffer:write_instance(actor)
    buffer:write_float(soul)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local soul = buffer:read_float()
    if Instance.exists(actor) then
        actor:get_data("TwistedOpinion", GUID).soul = soul
    end
end)

local function sync_soul(actor, data)
    if not Net.host or data.tw_synced_soul == data.soul then return end

    data.tw_synced_soul = data.soul
    packet_soul:send_to_all(actor, data.soul or 0)
end

-- в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
-- в•‘  РџСЂРµРґРјРµС‚ В«РњС‘СЂС‚РІР°СЏ РІРѕРґР°В»                                                     в•‘
-- в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ
local item = Item.new("TwistedOpinion")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_HEALING
-- Р“Р»Р°РІРЅР°СЏ Р»РѕРіРёРєР°: РєР°Р¶РґС‹Р№ РєР°РґСЂ РѕС‚СЃР»РµР¶РёРІР°РµРј РїСЂРёСЂРѕСЃС‚ HP (= РёСЃС†РµР»РµРЅРёРµ Р·Р° СЌС‚РѕС‚ РєР°РґСЂ),
-- СѓСЃРёР»РёРІР°РµРј РµРіРѕ, РєРѕРїРёРј РІ СЌРЅРµСЂРіРёСЋ РґСѓС€Рё Рё РїСЂРё РґРѕСЃС‚РёР¶РµРЅРёРё РїРѕСЂРѕРіР° РІС‹РїСѓСЃРєР°РµРј С‡РµСЂРµРї.
--
-- Р’Р°Р¶РЅРѕ: Р·Р°С…РІР°С‚ РёСЃС†РµР»РµРЅРёСЏ РёРґС‘С‚ РїРѕ РґРµР»СЊС‚Рµ HP, РїРѕСЌС‚РѕРјСѓ Р»РѕРІРёС‚ Р actor:heal(), Р hp_regen.
-- РћРіСЂР°РЅРёС‡РµРЅРёРµ РјРµС‚РѕРґР° вЂ” РѕРІРµСЂС…РёР» (Р»РµС‡РµРЅРёРµ В«РІ РїРѕС‚РѕР»РѕРєВ» РїСЂРё РїРѕР»РЅРѕРј HP) РЅРµ РІРёРґРµРЅ С‡РµСЂРµР· РґРµР»СЊС‚Сѓ;
-- СѓСЃРёР»РµРЅРёРµ РїСЂРё СЌС‚РѕРј С‚РѕР¶Рµ С‚РµСЂСЏРµС‚СЃСЏ. РџРѕР»РЅС‹Р№ Р·Р°С…РІР°С‚ РѕРІРµСЂС…РёР»Р° РїРѕС‚СЂРµР±РѕРІР°Р» Р±С‹ С…СѓРєР° gml-С„СѓРЅРєС†РёРё
-- Р»РµС‡РµРЅРёСЏ (РёРјСЏ РєРѕРЅСЃС‚Р°РЅС‚С‹ РЅСѓР¶РЅРѕ РїРѕРґС‚РІРµСЂРґРёС‚СЊ РІ РёРіСЂРµ) вЂ” СЃРј. Р·Р°РјРµС‚РєСѓ РІ РѕС‚РІРµС‚Рµ.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    -- Р›РѕРіРёРєР° вЂ” РЅР° С…РѕСЃС‚Рµ; РЅР° РєР»РёРµРЅС‚Р°С… HP СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓРµС‚СЃСЏ, С‡С‚РѕР±С‹ РЅРµ Р±С‹Р»Рѕ РґРІРѕР№РЅРѕРіРѕ СЃСЂР°Р±Р°С‚С‹РІР°РЅРёСЏ.
    if Net.client then return end

    local data = actor:get_data("TwistedOpinion", GUID)
    data.soul = data.soul or 0
    if data.dw_cd and data.dw_cd > 0 then data.dw_cd = data.dw_cd - 1 end

    local hp    = actor.hp
    local maxhp = actor.maxhp

    -- РџРµСЂРІС‹Р№ РєР°РґСЂ РїРѕСЃР»Рµ РїРѕР»СѓС‡РµРЅРёСЏ вЂ” РїСЂРѕСЃС‚Рѕ Р·Р°РїРѕРјРёРЅР°РµРј Р±Р°Р·РѕРІС‹Рµ Р·РЅР°С‡РµРЅРёСЏ
    if data.dw_prevHp == nil then
        data.dw_prevHp  = hp
        data.dw_prevMax = maxhp
        return
    end

    -- Р—Р°СЃС‡РёС‚С‹РІР°РµРј РёСЃС†РµР»РµРЅРёРµРј РїСЂРёСЂРѕСЃС‚ HP, С‚РѕР»СЊРєРѕ РµСЃР»Рё РјР°РєСЃ. HP РЅРµ РјРµРЅСЏР»СЃСЏ РІ СЌС‚РѕРј РєР°РґСЂРµ
    -- (РёРЅР°С‡Рµ СЃРєР°С‡РѕРє maxhp РѕС‚ СѓСЂРѕРІРЅСЏ/РїСЂРµРґРјРµС‚РѕРІ РїСЂРёРЅСЏР»Рё Р±С‹ Р·Р° Р»РµС‡РµРЅРёРµ).
    if maxhp == data.dw_prevMax and hp > data.dw_prevHp then
        local baseHeal = hp - data.dw_prevHp

        -- РЈСЃРёР»РµРЅРёРµ: 75% (+50%/СЃС‚Р°Рє). Р’РђР–РќРћ: Р±РѕРЅСѓСЃ РїРёС€РµРј РІ HP РќРђРџР РЇРњРЈР® (РјРіРЅРѕРІРµРЅРЅРѕ), Р° РЅРµ С‡РµСЂРµР·
        -- actor:heal(). actor:heal СЃРµС‚РµРІРѕР№ Рё РїСЂРёРјРµРЅСЏРµС‚СЃСЏ РЅРµ РІ С‚РѕС‚ Р¶Рµ РєР°РґСЂ в†’ Р±РѕРЅСѓСЃ РїРѕРїР°РґР°Р» РІ РґРµР»СЊС‚Сѓ
        -- HP РЎР›Р•Р”РЈР®Р©Р•Р“Рћ РєР°РґСЂР°, СЃРЅРѕРІР° СѓСЃРёР»РёРІР°Р»СЃСЏ, Рё С‚Р°Рє РїРѕ РєСЂСѓРіСѓ = СЌРєСЃРїРѕРЅРµРЅС†РёР°Р»СЊРЅС‹Р№ В«РѕРІРµСЂС…РёР»В»
        -- (СЂРµРіРµРЅ В«Р»СЋС‚oВ» Р·Р°РїРѕР»РЅСЏР» РїРѕР»РѕСЃРєСѓ). РџСЂСЏРјР°СЏ Р·Р°РїРёСЃСЊ Р·Р°РєСЂС‹РІР°РµС‚ СЌС‚РѕС‚ С†РёРєР».
        local heal_amp = HEAL_AMP_BASE + HEAL_AMP_STACK * (stack - 1)
        local bonus = baseHeal * heal_amp
        if bonus > 0 then
            actor.hp = math.min(maxhp, actor.hp + bonus)
            hp = actor.hp -- СѓС‡Р»Рё Р±РѕРЅСѓСЃ, С‡С‚РѕР±С‹ РЅРµ РїРµСЂРµСЃС‡РёС‚Р°С‚СЊ РµРіРѕ РєР°Рє РЅРѕРІРѕРµ Р»РµС‡РµРЅРёРµ
        end

        -- РќР°РєРѕРїР»РµРЅРёРµ РґСѓС€Рё РѕС‚ Р‘РђР—РћР’РћР“Рћ РёСЃС†РµР»РµРЅРёСЏ: 100% (+75%/СЃС‚Р°Рє), Р»РёРЅРµР№РЅРѕ.
        local soul_factor = SOUL_BASE + SOUL_STACK * (stack - 1)
        data.soul = data.soul + baseHeal * soul_factor
    end

    -- Р’С‹СЃС‚СЂРµР» РїСЂРё РґРѕСЃС‚РёР¶РµРЅРёРё РїРѕСЂРѕРіР° (СЃ РІРЅСѓС‚СЂРµРЅРЅРёРј РєСѓР»РґР°СѓРЅРѕРј РїСЂРѕС‚РёРІ СЃРїР°РјР°)
    local threshold = maxhp * THRESHOLD_FRAC
    if threshold > 0 and data.soul >= threshold and (data.dw_cd or 0) <= 0 then
        if Net.host then
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
    sync_soul(actor, data)
end)

-- Р’РёР·СѓР°Р»: РёРЅРґРёРєР°С‚РѕСЂ РЅР°РєРѕРїР»РµРЅРёСЏ СЌРЅРµСЂРіРёРё РґСѓС€Рё РЅР°Рґ РїРµСЂСЃРѕРЅР°Р¶РµРј
--[[ DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    if true then return end
    local data = actor:get_data("TwistedOpinion", GUID)
    local threshold = actor.maxhp * THRESHOLD_FRAC
    if threshold <= 0 then return end

    local frac = math.min((data.soul or 0) / threshold, 1)
    local w, x, y = 24, actor.x - 12, actor.y - 52
    gm.draw_set_colour(Color(0x301038))            -- С„РѕРЅ С€РєР°Р»С‹
    gm.draw_rectangle(x, y, x + w, y + 3, false)
    gm.draw_set_colour(Color(0xc060ff))            -- С„РёРѕР»РµС‚РѕРІР°СЏ СЌРЅРµСЂРіРёСЏ РґСѓС€Рё
    gm.draw_rectangle(x, y, x + w * frac, y + 3, false)
end) ]]

gm.post_script_hook(gm.constants.draw_hud, function()
    local p = Player.get_client()
    if not p or not Instance.exists(p) then return end
    if (p:item_count(item, Item.StackKind.ANY) or 0) <= 0 then return end

    local threshold = p.maxhp * THRESHOLD_FRAC
    if threshold <= 0 then return end

    local data = p:get_data("TwistedOpinion", GUID)
    local frac = math.min((data.soul or 0) / threshold, 1)
    local fill = math.floor(HUD_FILL_W * frac)

    local x = HUD_X
    local y = HUD_Y
    local fx = x + HUD_FILL_X
    local fy = y + HUD_FILL_Y

    gm.draw_set_alpha(1)
    gm.draw_set_colour(HUD_FILL_BG)
    gm.draw_rectangle(fx, fy, fx + HUD_FILL_W - 1, fy + HUD_FILL_H - 1, false)
    if fill > 0 then
        gm.draw_set_colour(HUD_FILL_FG)
        gm.draw_rectangle(fx, fy, fx + fill - 1, fy + HUD_FILL_H - 1, false)
    end
    gm.draw_set_colour(Color.WHITE)
    gm.draw_sprite(barSprite, 0, x, y)
end)
