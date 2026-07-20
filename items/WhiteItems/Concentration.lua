-- DeerItems-Concentration
-- Р—Р°СЂСЏР¶Р°РµС‚СЃСЏ С‡РµСЂРµР· SAFE_FRAMES РєР°РґСЂРѕРІ. РџРѕР»СѓС‡РµРЅРЅС‹Р№ СѓСЂРѕРЅ С‚Р°Р№РјРµСЂ РЅРµ СЃР±СЂР°СЃС‹РІР°РµС‚.
-- Р—Р°СЂСЏРґ С‚СЂР°С‚РёС‚СЃСЏ С‚РѕР»СЊРєРѕ РїСЂРё РїРѕРїР°РґР°РЅРёРё, РєРѕС‚РѕСЂРѕРµ РЅР°РЅРµСЃР»Рѕ РїРѕР»РѕР¶РёС‚РµР»СЊРЅС‹Р№ СѓСЂРѕРЅ.

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- РџР°СЂС‚РёРєР» РіРѕС‚РѕРІРЅРѕСЃС‚Рё СѓСЃРёР»РµРЅРЅРѕРіРѕ СѓРґР°СЂР°
-- Р—РІСѓРє РІ РјРѕРјРµРЅС‚ РіРѕС‚РѕРІРЅРѕСЃС‚Рё
local sprite = Sprite.new("item/Concentration", PATH.."assets/sprites/items/sWhiteItems/Concentration.png", 1, 18, 18)
local critParticle = Sprite.new("particle/ConcentrationCrit", PATH.."assets/sprites/particle/ConcentrationCrit.png", 1, 8, 8)
local readySound = Sound.new("sound/Concentration", PATH.."assets/sounds/Concentration.ogg")

local GUID = _ENV["!guid"]

-- Р‘Р°Р»Р°РЅСЃРЅС‹Рµ РєРѕРЅСЃС‚Р°РЅС‚С‹
local SAFE_FRAMES   = 3 * 60   -- 3 СЃРµРєСѓРЅРґ Р±РµР· СѓСЂРѕРЅР° РґРѕ Р·Р°СЂСЏРґРєРё
local DMG_PER_STACK = 0.60     -- +60% СѓСЂРѕРЅР° Р·Р° СЃС‚Р°Рє РЅР° СѓСЃРёР»РµРЅРЅРѕРј СѓРґР°СЂРµ

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ С‚РёСЂ, С‚РµРі В«СѓСЂРѕРЅВ»
local item = Item.new("Concentration")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- В«Р—Р°СЂСЏР¶РµРЅРѕВ», РµСЃР»Рё СЃ РїРѕСЃР»РµРґРЅРµРіРѕ РїРѕР»СѓС‡РµРЅРЅРѕРіРѕ СѓСЂРѕРЅР° РїСЂРѕС€Р»Рѕ >= SAFE_FRAMES РєР°РґСЂРѕРІ
local function is_ready(data)
    return (Global._current_frame - (data.cc_last_hit or -math.huge)) >= SAFE_FRAMES
end

DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    local data = actor:get_data("Concentration", GUID)
    data.cc_last_hit = Global._current_frame
    data.cc_was_ready = false
end)

-- РЈСЃРёР»РµРЅРЅС‹Р№ СѓРґР°СЂ: РїСЂРё РїРѕРїР°РґР°РЅРёРё, РµСЃР»Рё Р·Р°СЂСЏР¶РµРЅРѕ вЂ” РґРѕР±Р°РІР»СЏРµРј +60%/СЃС‚Р°Рє РѕС‚РґРµР»СЊРЅС‹Рј С…РёС‚РѕРј
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    local data = actor:get_data("Concentration", GUID)
    if not is_ready(data) then return end

    -- РЈСЂРѕРЅ вЂ” С‚РѕР»СЊРєРѕ РЅР° С…РѕСЃС‚Рµ (С‡С‚РѕР±С‹ РІ СЃРµС‚РµРІРѕР№ РёРіСЂРµ РЅРµ Р±С‹Р»Рѕ РґРІРѕР№РЅРѕРіРѕ Р±РѕРЅСѓСЃ-С…РёС‚Р°),
    -- РЅРѕ Р·Р°СЂСЏРґ С‚СЂР°С‚РёРј РЅР° РІСЃРµС… РєР»РёРµРЅС‚Р°С…, РёРЅР°С‡Рµ РїР°СЂС‚РёРєР»/Р·РІСѓРє РіРѕС‚РѕРІРЅРѕСЃС‚Рё СЂР°СЃСЃРёРЅС…СЂРѕРЅСЏС‚СЃСЏ.
    if Net.host then
        local base = actor.damage or 0
        if base > 0 and dmg > 0 then
            -- coef РїРµСЂРµРІРѕРґРёС‚ В«+60%/СЃС‚Р°Рє РѕС‚ СѓСЂРѕРЅР° СЌС‚РѕРіРѕ РїРѕРїР°РґР°РЅРёСЏВ» РІ РєРѕСЌС„С„РёС†РёРµРЅС‚ fire_direct
            local coef = (DMG_PER_STACK * stack * dmg) / base
            actor:fire_direct(victim, coef, nil, nil, nil, nil, false)
        end
    end

    -- РўСЂР°С‚РёРј Р·Р°СЂСЏРґ: С‚Р°Р№РјРµСЂ 5 СЃРµРєСѓРЅРґ СЃС‚Р°СЂС‚СѓРµС‚ Р·Р°РЅРѕРІРѕ
    data.cc_last_hit = Global._current_frame
end)

-- Р—РІСѓРє СЂРѕРІРЅРѕ РІ РјРѕРјРµРЅС‚, РєРѕРіРґР° СѓРґР°СЂ СЃС‚Р°Р» РіРѕС‚РѕРІ (РїРµСЂРµС…РѕРґ В«РЅРµ РіРѕС‚РѕРІРѕ в†’ РіРѕС‚РѕРІРѕВ»)
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("Concentration", GUID)
    local ready = is_ready(data)
    if ready and not data.cc_was_ready then
        actor:sound_play(readySound, 1.0, 1.0 + math.random() * 0.1)
    end
    data.cc_was_ready = ready
end)

-- РџР°СЂС‚РёРєР» СЂРѕРІРЅРѕ РџРћР” РїРµСЂСЃРѕРЅР°Р¶РµРј, РїРѕРєР° СѓСЃРёР»РµРЅРЅС‹Р№ СѓРґР°СЂ РіРѕС‚РѕРІ
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    if stack <= 0 then return end
    if is_ready(actor:get_data("Concentration", GUID)) then
        gm.draw_sprite(critParticle, 0, actor.x, actor.y + 60)
    end
end)
