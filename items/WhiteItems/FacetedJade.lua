-- DeerItems-FacetedJade
-- Р“СЂР°РЅРµРЅС‹Р№ РЅРµС„СЂРёС‚: РµСЃР»Рё РЅРµ РїРѕР»СѓС‡Р°С‚СЊ СѓСЂРѕРЅ 5 СЃРµРєСѓРЅРґ вЂ” РґР°С‘С‚ +45 Р±СЂРѕРЅРё Р·Р° СЃС‚Р°Рє.
-- РџРѕСЃР»Рµ СѓРґР°СЂР° Р°РєС‚РёРІРЅС‹Р№ Р±РѕРЅСѓСЃ РґРµСЂР¶РёС‚СЃСЏ РµС‰С‘ 3 СЃРµРєСѓРЅРґС‹, Р·Р°С‚РµРј РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµС‚СЃСЏ СЃРЅРѕРІР° РїРѕСЃР»Рµ 5 СЃРµРєСѓРЅРґ РїРѕРєРѕСЏ.
-- (РђРґР°РїС‚Р°С†РёСЏ Oddly-shaped Opal РёР· RoR2: С‰РёС‚ В«РІРЅРµ РѕРїР°СЃРЅРѕСЃС‚РёВ», С‚РѕР»СЊРєРѕ С‡РµСЂРµР· Р±СЂРѕРЅСЋ.)

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- РЎРїСЂР°Р№С‚-С‰РёС‚, РєРѕС‚РѕСЂС‹Р№ СЂРёСЃСѓРµС‚СЃСЏ РІРѕРєСЂСѓРі С‚РµР»Р°, РїРѕРєР° Р±РѕРЅСѓСЃ Р°РєС‚РёРІРµРЅ
-- Р—РІСѓРє РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёСЏ С‰РёС‚Р°
local sprite = Sprite.new("item/FacetedJade", PATH.."assets/sprites/items/sWhiteItems/FacetedJade.png", 1, 18, 18)
local shieldSprite = Sprite.new("particle/FacetedJadeShield", PATH.."assets/sprites/particle/FacetedJadeShield.png", 1, 24, 24)  -- 48x48, origin РїРѕ С†РµРЅС‚СЂСѓ
local restoreSound = Sound.new("sound/FacetedJade", PATH.."assets/sounds/FacetedJade.ogg")

-- guid РјРѕРґР° РІС‹РЅРѕСЃРёРј РѕРґРёРЅ СЂР°Р·, С‡С‚РѕР±С‹ get_data РЅРµ РёСЃРєР°Р» РµРіРѕ С‡РµСЂРµР· debug-СЃС‚РµРє РєР°Р¶РґС‹Р№ РєР°РґСЂ
local GUID = _ENV["!guid"]

-- Р‘Р°Р»Р°РЅСЃРЅС‹Рµ РєРѕРЅСЃС‚Р°РЅС‚С‹
local SAFE_FRAMES     = 5 * 60   -- СЃРєРѕР»СЊРєРѕ РєР°РґСЂРѕРІ Р±РµР· СѓСЂРѕРЅР° РЅСѓР¶РЅРѕ, С‡С‚РѕР±С‹ С‰РёС‚ В«Р·Р°СЂСЏРґРёР»СЃСЏВ» (5 СЃРµРє)
local GRACE_FRAMES    = 3 * 60   -- СЃРєРѕР»СЊРєРѕ РєР°РґСЂРѕРІ Р±РѕРЅСѓСЃ РґРµСЂР¶РёС‚СЃСЏ РїРѕСЃР»Рµ СѓРґР°СЂР°
local ARMOR_PER_STACK = 45       -- +45 Р±СЂРѕРЅРё Р·Р° СЃС‚Р°Рє, РїРѕРєР° С‰РёС‚ Р°РєС‚РёРІРµРЅ

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ С‚РёСЂ, С‚РµРі В«СѓС‚РёР»РёС‚Р°В» (Р·Р°С‰РёС‚РЅС‹Р№)
local item = Item.new("FacetedJade")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING
-- В«Р’РЅРµ РѕРїР°СЃРЅРѕСЃС‚РёВ», РµСЃР»Рё СЃ РїРѕСЃР»РµРґРЅРµРіРѕ РїРѕР»СѓС‡РµРЅРЅРѕРіРѕ СѓСЂРѕРЅР° РїСЂРѕС€Р»Рѕ >= SAFE_FRAMES РєР°РґСЂРѕРІ
local function is_safe(data)
    return (Global._current_frame - (data.fj_last_hit or -math.huge)) >= SAFE_FRAMES
end

local function is_bonus_active(data)
    return is_safe(data) or (data.fj_grace_until or -math.huge) > Global._current_frame
end

-- РЎРїСЂР°Р№С‚-С‰РёС‚ СЂРёСЃСѓРµРј РћРўР”Р•Р›Р¬РќР«Рњ РѕР±СЉРµРєС‚РѕРј Р—Рђ РёРіСЂРѕРєРѕРј (depth = parent.depth+1 в†’ Р·Р° СЃРїРёРЅРѕР№),
-- СЃ РІРёРґРёРјРѕСЃС‚СЊСЋ 35% (РїСЂРѕР·СЂР°С‡РЅРѕСЃС‚СЊ 65%). РЎРїСЂР°Р№С‚ С†РµРЅС‚СЂРёСЂСѓРµС‚СЃСЏ РЅР° РёРіСЂРѕРєРµ (origin 24,24 РґР»СЏ 48x48).
local SHIELD_ALPHA = 0.35
local objShield = Object.new("FacetedJadeShield")
objShield:set_sprite(shieldSprite)
Callback.add(objShield.on_create, function(self)
    self.parent      = -4
    self.image_alpha = SHIELD_ALPHA
    self:projectile_sync(8)
end)
Callback.add(objShield.on_step, function(self)
    if not Instance.exists(self.parent) then
        if Net.client then return end
        self:destroy()
        return
    end
    self.x           = self.parent.x
    self.y           = self.parent.y
    self.depth       = self.parent.depth + 1   -- Р±РѕР»СЊС€Рµ depth в†’ СЂРёСЃСѓРµС‚СЃСЏ Р—Рђ РёРіСЂРѕРєРѕРј
    self.image_alpha = SHIELD_ALPHA
end)

-- Р’РєР»СЋС‡РёС‚СЊ/РІС‹РєР»СЋС‡РёС‚СЊ С‰РёС‚-РѕР±СЉРµРєС‚ Сѓ РІР»Р°РґРµР»СЊС†Р° (РёРґРµРјРїРѕС‚РµРЅС‚РЅРѕ вЂ” РјРѕР¶РЅРѕ Р·РІР°С‚СЊ РєР°Р¶РґС‹Р№ РєР°РґСЂ)
Callback.add(objShield.on_destroy, function(self)
    self:instance_destroy_sync()
end)

Object.add_serializers(objShield, function(self, buffer)
    buffer:write_instance(self.parent)
end, function(self, buffer)
    self.parent = buffer:read_instance()
end)

local function set_shield(actor, data, on)
    local sh = data.fj_shield
    if on then
        if not (sh and Instance.exists(sh)) then
            sh = objShield:create(actor.x, actor.y)
            sh.parent = actor
            data.fj_shield = sh
        end
    elseif sh and Instance.exists(sh) then
        sh:destroy()
        data.fj_shield = nil
    end
end

-- РџСЂРё РїРѕР»СѓС‡РµРЅРёРё РїСЂРµРґРјРµС‚Р° Р·Р°РїСѓСЃРєР°РµРј С‚Р°Р№РјРµСЂ РїРѕРєРѕСЏ (С‰РёС‚ Р·Р°СЂСЏРґРёС‚СЃСЏ С‡РµСЂРµР· 5 СЃРµРє РїРѕСЃР»Рµ РїРѕРґР±РѕСЂР°)
DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    local data = actor:get_data("FacetedJade", GUID)
    data.fj_last_hit = Global._current_frame
    data.fj_was_active = false
    data.fj_grace_until = nil
end)

-- Р—Р°РїРѕРјРёРЅР°РµРј РєР°РґСЂ РїРѕСЃР»РµРґРЅРµРіРѕ РїРѕР»СѓС‡РµРЅРЅРѕРіРѕ СѓСЂРѕРЅР° (СЌС‚Рѕ СЃР±СЂР°СЃС‹РІР°РµС‚ В«РІРЅРµ РѕРїР°СЃРЅРѕСЃС‚РёВ»)
DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if Net.client then return end

    -- РРіРЅРѕСЂРёСЂСѓРµРј СѓСЂРѕРЅ РѕС‚ СЃР°РјРѕРіРѕ СЃРµР±СЏ (С‡СѓР¶РёРµ СЃР°РјРѕРїРѕРІСЂРµР¶РґР°СЋС‰РёРµ СЌС„С„РµРєС‚С‹ РЅРµ РґРѕР»Р¶РЅС‹ СЃР±РёРІР°С‚СЊ С‰РёС‚)
    if attacker and actor:same(attacker) then return end
    local data = actor:get_data("FacetedJade", GUID)
    if is_bonus_active(data) then
        data.fj_grace_until = Global._current_frame + GRACE_FRAMES
    end
    data.fj_last_hit = Global._current_frame
end)

-- РџРѕРєР° В«РІРЅРµ РѕРїР°СЃРЅРѕСЃС‚РёВ» вЂ” РґР°С‘Рј Р±СЂРѕРЅСЋ (РїСЂРёРјРµРЅСЏРµС‚СЃСЏ РїСЂРё РєР°Р¶РґРѕРј РїРµСЂРµСЃС‡С‘С‚Рµ СЃС‚Р°С‚РѕРІ)
DeerItemsCallbacks.item_post_stat_recalc(item, function(actor, stack)
    if Net.client then return end

    if stack <= 0 then return end
    if is_bonus_active(actor:get_data("FacetedJade", GUID)) then
        actor.armor = actor.armor + ARMOR_PER_STACK * stack
    end
end)

-- РљР°Р¶РґС‹Р№ РєР°РґСЂ Р»РѕРІРёРј РїРµСЂРµС…РѕРґ В«РѕРїР°СЃРЅРѕ <-> Р±РµР·РѕРїР°СЃРЅРѕВ»: РїРѕСЂРѕРі Р·Р°РІСЏР·Р°РЅ РЅР° Р’Р Р•РњРЇ, Р° РЅРµ РЅР° СЃРѕР±С‹С‚РёРµ,
-- РїРѕСЌС‚РѕРјСѓ С„РѕСЂСЃРёРј РїРµСЂРµСЃС‡С‘С‚ СЃС‚Р°С‚РѕРІ РІСЂСѓС‡РЅСѓСЋ, С‡С‚РѕР±С‹ +Р±СЂРѕРЅСЏ РІРєР»СЋС‡Р°Р»Р°СЃСЊ/РІС‹РєР»СЋС‡Р°Р»Р°СЃСЊ РІРѕРІСЂРµРјСЏ.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if Net.client then return end

    if stack <= 0 then return end
    local data = actor:get_data("FacetedJade", GUID)
    local active = is_bonus_active(data)
    local safe = is_safe(data)
    if active ~= data.fj_was_active then
        actor:recalculate_stats()
        if safe then
            actor:sound_play(restoreSound, 1.0, 0.95 + math.random() * 0.1)
        end
        data.fj_was_active = active
    end
    -- Р”РµСЂР¶РёРј С‰РёС‚-РѕР±СЉРµРєС‚ РІ Р°РєС‚СѓР°Р»СЊРЅРѕРј СЃРѕСЃС‚РѕСЏРЅРёРё (Р·Р° СЃРїРёРЅРѕР№ РёРіСЂРѕРєР°, РїРѕРєР° Р±РѕРЅСѓСЃ Р°РєС‚РёРІРµРЅ)
    set_shield(actor, data, active)
end)

-- РџСЂРё РїРѕС‚РµСЂРµ РїСЂРµРґРјРµС‚Р° вЂ” СѓР±РёСЂР°РµРј РѕР±СЉРµРєС‚-С‰РёС‚ (РёРЅР°С‡Рµ РѕСЃС‚Р°Р»СЃСЏ Р±С‹ РІРёСЃРµС‚СЊ)
DeerItemsCallbacks.item_removed(item, function(actor, stack)
    if Net.client then return end

    set_shield(actor, actor:get_data("FacetedJade", GUID), false)
end)
