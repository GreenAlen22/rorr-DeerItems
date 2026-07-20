-- DeerItems-NewtonsMechanism
-- Р”Р°С‘С‚ С‰РёС‚ (4% РѕС‚ РјР°РєСЃ. HP). РџРѕРєР° С‰РёС‚ РµСЃС‚СЊ вЂ” +30 Р±СЂРѕРЅРё (+30 Р·Р° С€С‚.).
-- РљРѕРіРґР° С‰РёС‚ РїСЂРѕР±РёРІР°СЋС‚ вЂ” РІС‹РїСѓСЃРєР°РµС‚ РѕРіР»СѓС€Р°СЋС‰РёР№ РїСѓР»СЊСЃ: 100% СѓСЂРѕРЅР° + 100% (+10% Р·Р° С€С‚.) РѕС‚ РјР°РєСЃ. С‰РёС‚Р°.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚С‹ СЌС„С„РµРєС‚РѕРІ
-- Р—Р°РіСЂСѓР¶Р°РµРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
local sprite = Sprite.new("item/NewtonsMechanism", PATH.."assets/sprites/items/sGreenItems/NewtonsMechanism.png", 1, 17, 17)
local voltOverload = Sprite.new("paticle/voltOverload", PATH.."assets/sprites/particle/voltOverload.png", 13, 64, 112)
local voltOverloadHit = Sprite.new("paticle/voltOverloadHit", PATH.."assets/sprites/particle/voltOverloadHit.png", 6, 16, 16)
local sound = Sound.new("sound/voltOverload", PATH.."assets/sounds/voltOverload.ogg")

-- guid РјРѕРґР° РІС‹РЅРѕСЃРёРј РѕРґРёРЅ СЂР°Р· вЂ” С‡С‚РѕР±С‹ get_data РЅРµ РёСЃРєР°Р» РµРіРѕ С‡РµСЂРµР· debug-СЃС‚РµРє РєР°Р¶РґС‹Р№ РєР°РґСЂ
local GUID = _ENV["!guid"]

-- Р‘Р°Р»Р°РЅСЃРЅС‹Рµ РєРѕРЅСЃС‚Р°РЅС‚С‹
local ARMOR_PER_STACK   = 5     -- +5 Р±СЂРѕРЅРё Р·Р° СЃС‚Р°Рє, РїРѕРєР° РµСЃС‚СЊ С‰РёС‚
local PULSE_PLAYER_BASE = 1.5    -- РїСѓР»СЊСЃ: 150% Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР°
local PULSE_PLAYER_STACK= 1.25   -- +125% Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР° Р·Р° РєР°Р¶РґС‹Р№ РґРѕРї. СЃС‚Р°Рє
local PULSE_SHIELD_BASE = 1.25    -- РїСѓР»СЊСЃ: +125% РѕС‚ РјР°РєСЃ. С‰РёС‚Р°
local PULSE_SHIELD_STACK= 1.0    -- +100% РѕС‚ РјР°РєСЃ. С‰РёС‚Р° Р·Р° СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ
local STUN_SECONDS      = 1.5    -- РґР»РёС‚РµР»СЊРЅРѕСЃС‚СЊ РѕРіР»СѓС€РµРЅРёСЏ РѕС‚ РїСѓР»СЊСЃР°
local RADIUS_BASE       = 3 * 32      -- Р±Р°Р·РѕРІС‹Р№ СЂР°РґРёСѓСЃ РїСѓР»СЊСЃР° (3 Рј)
local RADIUS_STACK      = 0.5 * 32    -- +0.5 Рј СЂР°РґРёСѓСЃР° Р·Р° СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° NewtonsMechanism
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р·РµР»С‘РЅС‹Р№ (РЅРµРѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, РїРѕРІС‹С€Р°СЋС‰РёР№ Р¶РёРІСѓС‡РµСЃС‚СЊ
local item = Item.new("NewtonsMechanism")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- РџРѕРєР° Сѓ РёРіСЂРѕРєР° РµСЃС‚СЊ С‰РёС‚ РёР· Р»СЋР±РѕРіРѕ РёСЃС‚РѕС‡РЅРёРєР°, РґР°С‘Рј Р±СЂРѕРЅСЋ.
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack)
    if stack <= 0 then return end
    -- Р‘СЂРѕРЅСЏ вЂ” С‚РѕР»СЊРєРѕ РїРѕРєР° Сѓ РёРіСЂРѕРєР° СЂРµР°Р»СЊРЅРѕ РµСЃС‚СЊ С‰РёС‚.
    if (actor.shield or 0) > 0 then
        actor.armor = actor.armor + ARMOR_PER_STACK * stack
    end
end)

-- РћРіР»СѓС€Р°СЋС‰РёР№ РїСѓР»СЊСЃ РїСЂРё РїСЂРѕР±РёС‚РёРё С‰РёС‚Р°: 150%(+75%/СЃС‚Р°Рє) Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР° + 100%(+50%/СЃС‚Р°Рє) РѕС‚ РјР°РєСЃ. С‰РёС‚Р°.
local function release_pulse(actor, stack)
    local radius = RADIUS_BASE + RADIUS_STACK * (stack - 1)
    -- РџР›РћРЎРљРР™ СѓСЂРѕРЅ РїРѕ РўР—: 150%(+75%/СЃС‚Р°Рє) Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР° + 100%(+50%/СЃС‚Р°Рє) РѕС‚ РјР°РєСЃ. С‰РёС‚Р°.
    -- Р’РќРРњРђРќРР•: РїР°СЂР°РјРµС‚СЂ damage Сѓ fire_explosion вЂ” СЌС‚Рѕ РљРћР­Р¤Р¤РР¦РР•РќРў (РґРІРёР¶РѕРє СѓРјРЅРѕР¶Р°РµС‚ РµРіРѕ РЅР°
    -- actor.damage). Р‘РµР· РїРѕРїСЂР°РІРєРё РїРѕР»СѓС‡Р°Р»РѕСЃСЊ dmgГ—actor.damage в‰€ СѓСЂРѕРЅ РІ РєРІР°РґСЂР°С‚Рµ (Р±РёР»Рѕ СЃР»РёС€РєРѕРј СЃРёР»СЊРЅРѕ).
    -- РџРѕСЌС‚РѕРјСѓ С„РѕСЂСЃРёРј В«СЃС‹СЂРѕР№В» СѓСЂРѕРЅ С‡РµСЂРµР· use_raw_damage()+set_damage(), РєР°Рє РІ Р”РѕРјР±СЂРµ.
    local dmg = actor.damage * (PULSE_PLAYER_BASE + PULSE_PLAYER_STACK * (stack - 1))
              + actor.maxshield * (PULSE_SHIELD_BASE + PULSE_SHIELD_STACK * (stack - 1))

    -- РћР±Р° РІРёР·СѓР°Р»СЊРЅС‹С… СЃРїСЂР°Р№С‚Р° nil вЂ” СЂРёСЃСѓРµРј Р РћР’РќРћ РћР”РРќ СЃРїСЂР°Р№С‚ РІСЂСѓС‡РЅСѓСЋ (Р±РµР· РґРІРѕР№РЅРѕР№ РјРѕР»РЅРёРё).
    -- proc=false: РїСѓР»СЊСЃ РЅРµ РґРѕР»Р¶РµРЅ РїСЂРѕРєР°С‚СЊ РґСЂСѓРіРёРµ РїСЂРµРґРјРµС‚С‹ Рё СЃР°Рј СЃРµР±СЏ.
    local attack = actor:fire_explosion(actor.x, actor.y, radius, radius, dmg, nil, nil, false)
    attack.max_hit_number = 5 + 10 * stack
    -- РћРіР»СѓС€РµРЅРёРµ РїРѕСЂР°Р¶С‘РЅРЅС‹С… РІСЂР°РіРѕРІ + С„РёРєСЃР°С†РёСЏ РїР»РѕСЃРєРѕРіРѕ СѓСЂРѕРЅР° (Р±РµР· РєСЂРёС‚Р°)
    if attack and attack.attack_info then
        attack.attack_info:use_raw_damage()
        attack.attack_info:set_damage(dmg)
        attack.attack_info:set_critical(false)
        attack.attack_info:set_stun(STUN_SECONDS)
    end

    -- РћРґРёРЅ СЃРїСЂР°Р№С‚ РјРѕР»РЅРёРё: РІС‹СЃРѕС‚Р° = СЂР°РґРёСѓСЃ, С€РёСЂРёРЅР° = 0.8Г—РІС‹СЃРѕС‚С‹ (РїСЂРѕРїРѕСЂС†РёСЏ Р°СЂС‚Р°). РЎРїСЂР°Р№С‚ 64Г—112 px.
    local ef = gm.instance_create(actor.x, actor.y, gm.constants.oEfExplosion)
    ef.sprite_index = voltOverload
    ef.image_yscale = radius / 112
    ef.image_xscale = (radius * 0.8) / 64

    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.2)
    actor:screen_shake(3)
end

-- РљР°Р¶РґС‹Р№ РєР°РґСЂ: Р»РѕРІРёРј РїСЂРѕР±РёС‚РёРµ С‰РёС‚Р° Рё РґРµСЂР¶РёРј Р±РѕРЅСѓСЃ Р±СЂРѕРЅРё Р°РєС‚СѓР°Р»СЊРЅС‹Рј.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("DeerItems", GUID)
    if data.nm_cd and data.nm_cd > 0 then data.nm_cd = data.nm_cd - 1 end
    local shield = actor.shield or 0
    local prev = data.nm_prev_shield or 0

    -- Р©РёС‚ РїСЂРѕР±РёС‚ (Р±С‹Р» > 0, СЃС‚Р°Р» в‰¤ 0) в†’ РІС‹РїСѓСЃРєР°РµРј РїСѓР»СЊСЃ. РљСѓР»РґР°СѓРЅ = Р·Р°С‰РёС‚Р° РѕС‚ Р”Р’РћР™РќРћР™ РјРѕР»РЅРёРё:
    -- РµСЃР»Рё РґРµС‚РµРєС‚ РїСЂРѕР±РёС‚РёСЏ СЃСЂР°Р±Р°С‚С‹РІР°РµС‚ РЅРµСЃРєРѕР»СЊРєРѕ РєР°РґСЂРѕРІ РїРѕРґСЂСЏРґ (С‰РёС‚ В«РґС‘СЂРіР°РµС‚СЃСЏВ» Сѓ РЅСѓР»СЏ РёР»Рё РёР·-Р·Р°
    -- РїРµСЂРµСЃС‡С‘С‚Р° СЃС‚Р°С‚РѕРІ), РїСѓР»СЊСЃ Рё РµРіРѕ РІРёР·СѓР°Р» Р±РѕР»СЊС€Рµ РЅРµ РґСѓР±Р»РёСЂСѓСЋС‚СЃСЏ.
    if prev > 0 and shield <= 0 and (data.nm_cd or 0) <= 0 then
        if not Net.client then
            release_pulse(actor, stack)
        end
        data.nm_cd = 30
    end

    -- РќР°Р»РёС‡РёРµ С‰РёС‚Р° РїРµСЂРµРєР»СЋС‡РёР»РѕСЃСЊ в†’ РїРµСЂРµСЃС‡С‘С‚, С‡С‚РѕР±С‹ +30 Р±СЂРѕРЅРё РІРєР»СЋС‡Р°Р»РѕСЃСЊ/РІС‹РєР»СЋС‡Р°Р»РѕСЃСЊ РІРѕРІСЂРµРјСЏ
    if (prev > 0) ~= (shield > 0) then
        actor:recalculate_stats()
    end

    data.nm_prev_shield = shield
end)
