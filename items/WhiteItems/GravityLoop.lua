-- DeerItems-GravityLoop
-- РџСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓСЂРѕРЅР° РЅР° РЅРёР·РєРѕРј Р·РґРѕСЂРѕРІСЊРµ Р»РµС‡РёС‚ Рё С‚СЂР°С‚РёС‚ РѕРґРёРЅ СЃС‚Р°Рє, Р·Р°РјРµРЅСЏСЏ РµРіРѕ РЅР° "GravityLoopDeactivate".

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ СЌС„С„РµРєС‚Р°
local sprite = Sprite.new("item/GravityLoop", PATH.."assets/sprites/items/sWhiteItems/GravityLoop.png", 1, 16, 16)
local sound = Sound.new("sound/GravityLoop", PATH.."assets/sounds/GravityLoop.ogg")
local GravityLoopBreack = Sprite.new("particle/GravityLoopBreack", PATH.."assets/sprites/particle/GravityLoopBreack.png", 15, 50, 50)

-- Р»РµРЅРёРІС‹Р№ РєСЌС€ СЃСЃС‹Р»РєРё РЅР° СЃР»РѕРјР°РЅРЅСѓСЋ РІРµСЂСЃРёСЋ (РЅР° Р·Р°РіСЂСѓР·РєРµ РјРѕР¶РµС‚ Р±С‹С‚СЊ РµС‰С‘ РЅРµ Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°РЅР°)
local deactivate

-- `sound_play` Рё РІР°РЅРёР»СЊРЅС‹Рµ СЌС„С„РµРєС‚С‹ РІРёРґРЅС‹ С‚РѕР»СЊРєРѕ РЅР° Р»РѕРєР°Р»СЊРЅРѕР№ РјР°С€РёРЅРµ. РџРѕСЌС‚РѕРјСѓ
-- С…РѕСЃС‚ РѕС‚РґРµР»СЊРЅРѕ РїРµСЂРµРґР°С‘С‚ РєР»РёРµРЅС‚Р°Рј СЃРёРіРЅР°Р» РґР»СЏ Р·РІСѓРєР° Рё РІРёР·СѓР°Р»СЊРЅРѕРіРѕ СЌС„С„РµРєС‚Р°.
local packet_trigger = Packet.new("GravityLoop-packet_trigger")
packet_trigger:set_serializers(function(buffer, actor, pitch)
    buffer:write_instance(actor)
    buffer:write_float(pitch)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local pitch = buffer:read_float()
    if not Instance.exists(actor) then return end

    actor:sound_play(sound, 2.0, pitch)
    local ef = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
    ef.sprite_index = GravityLoopBreack
end)

-- РЎРѕР·РґР°РЅРёРµ РЅРѕРІРѕРіРѕ РїСЂРµРґРјРµС‚Р° СЃ РЅР°Р·РІР°РЅРёРµРј "GravityLoop" РІ РєР°С‚РµРіРѕСЂРёРё "DeerItems"
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ (РѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СЃРІСЏР·Р°РЅРЅС‹Р№ СЃ Р»РµС‡РµРЅРёРµРј
local item = Item.new("GravityLoop")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- РћР±СЂР°Р±РѕС‚РєР° С‚СЂРёРіРіРµСЂР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓСЂРѕРЅР°
DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if Net.client then return end

    -- РЎСЂР°Р±Р°С‚С‹РІР°РµС‚, РµСЃР»Рё С‚РµРєСѓС‰РµРµ HP СѓРїР°Р»Рѕ РґРѕ 25% РёР»Рё РЅРёР¶Рµ
    if actor.hp <= actor.maxhp * 0.35 then
        -- Р›РµС‡РµРЅРёРµ РЅР° 70% РѕС‚ РјР°РєСЃРёРјР°Р»СЊРЅРѕРіРѕ HP
        actor:heal(actor.maxhp * 0.7)

        -- Р’РѕСЃРїСЂРѕРёР·РІРѕРґРёРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
        local sound_pitch = 0.9 + math.random() * 0.5
        actor:sound_play(sound, 2.0, sound_pitch)

        -- Р­С„С„РµРєС‚ РёСЃРєСЂ СЃ РєР°СЃС‚РѕРјРЅС‹Рј СЃРїСЂР°Р№С‚РѕРј
        local ef = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
        ef.sprite_index = GravityLoopBreack

        if Net.host then
            packet_trigger:send_to_all(actor, sound_pitch)
        end

        -- РџРѕР»СѓС‡Р°РµРј СЃСЃС‹Р»РєСѓ РЅР° РїСЂРµРґРјРµС‚, Р·Р°РјРµРЅСЏСЋС‰РёР№ РёСЃРїРѕР»СЊР·РѕРІР°РЅРЅС‹Р№ СЃС‚Р°Рє
        deactivate = deactivate or Item.find("GravityLoopDeactivate", "DeerItems")
        local item_used = deactivate

        -- РЈРґР°Р»СЏРµРј 1 РѕР±С‹С‡РЅС‹Р№ СЃС‚Р°Рє Рё РґРѕР±Р°РІР»СЏРµРј 1 СЃР»РѕРјР°РЅРЅС‹Р№
        local normal = actor:item_count(item, Item.StackKind.NORMAL)
        if normal > 0 then
            actor:item_take(item, 1)
            actor:item_give(item_used, 1)
            return
        end

        -- Р•СЃР»Рё РѕР±С‹С‡РЅС‹С… СЃС‚Р°РєРѕРІ РЅРµС‚ вЂ” Р·Р°РјРµРЅСЏРµРј РІСЂРµРјРµРЅРЅС‹Р№/СЃРёРЅРёР№ СЃС‚Р°Рє
        local temp = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
        if temp > 0 then
            actor:item_take(item, 1, Item.StackKind.TEMPORARY_BLUE)
            actor:item_give(item_used, 1, Item.StackKind.TEMPORARY_BLUE)
            return
        end
    end
end)
