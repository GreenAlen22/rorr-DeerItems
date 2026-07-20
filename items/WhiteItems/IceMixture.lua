-- DeerItems-IceMixture
-- РџСЂРё РїРѕРїР°РґР°РЅРёРё СЃ С€Р°РЅСЃРѕРј РЅР°РєР»Р°РґС‹РІР°РµС‚ РґРµР±Р°С„С„, СЃРЅРёР¶Р°СЋС‰РёР№ СЃРєРѕСЂРѕСЃС‚СЊ РїРµСЂРµРґРІРёР¶РµРЅРёСЏ Рё Р°С‚Р°РєРё РЅР° 30% РЅР° 3 СЃРµРєСѓРЅРґС‹.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
local sprite = Sprite.new("item/IceMixture", PATH.."assets/sprites/items/sWhiteItems/IceMixture.png", 1, 16, 16)
local sound = Sound.new("sound/IceMixture", PATH.."assets/sounds/IceMixture.ogg")

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° IceMixture
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ (РѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ
local item = Item.new("IceMixture")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- guid РјРѕРґР° (СѓСЃРєРѕСЂСЏРµС‚ get_data) Рё Р»РµРЅРёРІС‹Р№ РєСЌС€ СЃСЃС‹Р»РєРё РЅР° РґРµР±Р°С„С„
local GUID = _ENV["!guid"]
local iceBuff

-- РћС‡РёСЃС‚РєР° СЃС‚Р°СЂС‹С… РєРѕР»Р»Р±РµРєРѕРІ
-- РџСЂРё РїРѕРїР°РґР°РЅРёРё Р°С‚Р°РєРѕР№ СЃСЂР°Р±Р°С‚С‹РІР°РµС‚ С€Р°РЅСЃ РЅР°Р»РѕР¶РёС‚СЊ Р·Р°РјРµРґР»СЏСЋС‰РёР№ РґРµР±Р°С„С„
item:onHitProc(function(actor, victim, stack, hit_info)
    if not Net.host then return end

    -- РЁР°РЅСЃ 7% (2+5) Рё + 5% Р·Р° СЃС‚Р°Рє
	if math.random() <= 0.02 + (0.05 * stack) then
        -- Р—РІСѓРє РЅР° С†РµР»Рё РїСЂРё РЅР°Р»РѕР¶РµРЅРёРё: РІСЃРµРіРґР° СЃР»СѓС‡Р°Р№РЅС‹Рµ РіСЂРѕРјРєРѕСЃС‚СЊ Рё РёРЅС‚РѕРЅР°С†РёСЏ
        victim:sound_play(sound, 0.8 + math.random() * 0.6, 0.7 + math.random() * 0.6)
        -- РџСЂРёРјРµРЅРµРЅРёРµ РґРµР±Р°С„С„Р°
        iceBuff = iceBuff or Buff.find("IceMixture", "DeerItems")
        victim:buff_apply(iceBuff, 1)
    end
end)

-- Р”РµР±Р°С„С„ РїСЂРµРґРјРµС‚Р° IceMixture.
-- Р”РµР±Р°С„С„, Р·Р°РјРµРґР»СЏСЋС‰РёР№ РїРµСЂРµРґРІРёР¶РµРЅРёРµ Рё СЃРєРѕСЂРѕСЃС‚СЊ Р°С‚Р°РєРё РЅР° 30% РІ С‚РµС‡РµРЅРёРµ 3 СЃРµРєСѓРЅРґ

-- РЎРѕР·РґР°РЅРёРµ РґРµР±Р°С„С„Р°
local buff = Buff.new("IceMixture")
buff.show_icon = false
buff.icon_stack_subimage = false
buff.max_stack = 1
buff.is_timed = false
buff.is_debuff = true

-- РџСЂРё РїСЂРёРјРµРЅРµРЅРёРё вЂ” Р·Р°РїСѓСЃРєР°РµРј С‚Р°Р№РјРµСЂ Рё РјРµРЅСЏРµРј РІРёР·СѓР°Р»
buff:onApply(function(actor, stack)
    local actorData = actor:get_data("IceMixture", GUID)
    if not actorData.timers then
        actorData.timers = {}
    end
    -- РљР°Р¶РґС‹Р№ СЃС‚Р°Рє РёРјРµРµС‚ 3 СЃРµРєСѓРЅРґС‹ РґР»РёС‚РµР»СЊРЅРѕСЃС‚Рё
    table.insert(actorData.timers, 3 * 60.0)
    -- Р­С„С„РµРєС‚ Р·Р°С‚РµРјРЅРµРЅРёСЏ
    actor.image_blend = Color(0xa8dbff)
end)

-- РћР±РЅРѕРІР»РµРЅРёРµ С‚Р°Р№РјРµСЂРѕРІ РєР°Р¶РґРѕРіРѕ СЃС‚РµРєР°
buff:onPostStep(function(actor, stack)
    local actorData = actor:get_data("IceMixture", GUID) or {}
    -- РћР±РЅРѕРІР»СЏРµРј С‚Р°Р№РјРµСЂС‹ Рё СѓРґР°Р»СЏРµРј РёСЃС‚РµРєС€РёРµ
    if actorData.timers then
        for i = #actorData.timers, 1, -1 do
            actorData.timers[i] = actorData.timers[i] - 1
            if actorData.timers[i] <= 0 then
                table.remove(actorData.timers, i)
            end
        end
    end
    -- РЈРґР°Р»СЏРµРј Р»РёС€РЅРёРµ СЃС‚Р°РєРё, РµСЃР»Рё РёС… Р±РѕР»СЊС€Рµ, С‡РµРј РѕСЃС‚Р°РІС€РёС…СЃСЏ С‚Р°Р№РјРµСЂРѕРІ
    local diff = stack - #(actorData.timers or {})
    if diff > 0 then
        actor:buff_remove(buff, diff)
        actor:recalculate_stats()
    end
end)

-- РџСЂРё СЃРЅСЏС‚РёРё РґРµР±Р°С„С„Р° вЂ” РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј С†РІРµС‚
buff:onRemove(function(actor, stacks_removed)
    actor.image_blend = Color(0xFFFFFF)
end)

-- РР·РјРµРЅРµРЅРёРµ СЃС‚Р°С‚РѕРІ РїРѕРґ РґРµР№СЃС‚РІРёРµРј РґРµР±Р°С„С„Р°
buff:onStatRecalc(function(actor, stack)
    actor.pHmax = actor.pHmax * 0.70          -- РјРёРЅСѓСЃ 30% Рє СЃРєРѕСЂРѕСЃС‚Рё РїРµСЂРµРґРІРёР¶РµРЅРёСЏ
    actor.attack_speed = actor.attack_speed * 0.70 -- РјРёРЅСѓСЃ 30% Рє СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё
end)
