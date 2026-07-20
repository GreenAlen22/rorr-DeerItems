-- DeerItems-MassacreCurse
-- РџРѕСЃР»Рµ 3 СѓР±РёР№СЃС‚РІ РїРѕРґСЂСЏРґ РґР°С‘С‚ Р±Р°С„С„, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ Рё Р±СЂРѕРЅСЋ. Р”Р»РёС‚РµР»СЊРЅРѕСЃС‚СЊ СЃС‚Р°РєРѕРІ Р·Р°РІРёСЃРёС‚ РѕС‚ РєРѕР»РёС‡РµСЃС‚РІР° РїСЂРµРґРјРµС‚РѕРІ.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
local sprite = Sprite.new("item/MassacreCurse", PATH.."assets/sprites/items/sWhiteItems/MassacreCurse.png", 1, 16, 17)

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° MassacreCurse
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ (РѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ
local item = Item.new("MassacreCurse")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- guid РјРѕРґР° (СѓСЃРєРѕСЂСЏРµС‚ get_data) Рё Р»РµРЅРёРІС‹Р№ РєСЌС€ СЃСЃС‹Р»РєРё РЅР° Р±Р°С„С„
local GUID = _ENV["!guid"]
local massacreBuff

-- РџСЂРё РїРѕР»СѓС‡РµРЅРёРё РїСЂРµРґРјРµС‚Р° РёРЅРёС†РёР°Р»РёР·РёСЂСѓРµРј СЃС‡С‘С‚С‡РёРє СѓР±РёР№СЃС‚РІ
DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    local actorData = actor:get_data("MassacreCurse", GUID)
    if not actorData.count then
        actorData.count = 0
    end
end)

-- РџСЂРё СѓР±РёР№СЃС‚РІРµ СѓРІРµР»РёС‡РёРІР°РµРј СЃС‡С‘С‚С‡РёРє Рё РІС‹РґР°С‘Рј Р±Р°С„С„ РїСЂРё РґРѕСЃС‚РёР¶РµРЅРёРё 3
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if not Net.host then return end

    massacreBuff = massacreBuff or Buff.find("MassacreCurse", "DeerItems")
    local buff = massacreBuff
    local actorData = actor:get_data("MassacreCurse", GUID)

    actorData.count = actorData.count + 1

    if actorData.count >= 3 then
        local count = 1
        -- Р•СЃР»Рё Р±Р°С„С„Р° РЅРµ Р±С‹Р»Рѕ РІРѕРѕР±С‰Рµ вЂ” РґР°С‘Рј СЃСЂР°Р·Сѓ 3 СЃС‚Р°РєР°
        if actor:buff_count(buff) <= 0 then
            count = 3
        end

        actor:buff_apply(buff, 1, count)
    end
end)

-- Р‘Р°С„С„ РїСЂРµРґРјРµС‚Р° MassacreCurse.
-- Р”РѕР»РіРѕСЃСЂРѕС‡РЅС‹Р№ Р±Р°С„С„, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ Рё Р±СЂРѕРЅСЋ, СЃС‚Р°РєРё СѓРґР°Р»СЏСЋС‚СЃСЏ РїРѕ РёСЃС‚РµС‡РµРЅРёСЋ РІСЂРµРјРµРЅРё

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ Р±Р°С„С„Р°
local sprite = Sprite.new("buff/MassacreCurse", PATH.."assets/sprites/buffs/MassacreCurse.png", 1, 7, 7)

-- РЎРѕР·РґР°РЅРёРµ Р±Р°С„С„Р°
local buff = Buff.new("MassacreCurse")
buff.icon_sprite = sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0xa0735b))
buff.max_stack = 999
buff.is_timed = false

-- РџСЂРё РґРѕР±Р°РІР»РµРЅРёРё СЃС‚Р°РєР° вЂ” РґРѕР±Р°РІР»СЏРµРј С‚Р°Р№РјРµСЂ РµРіРѕ РґРµР№СЃС‚РІРёСЏ
DeerItemsCallbacks.buff_apply(buff, function(actor, stack)
    local actorData = actor:get_data("MassacreCurse", GUID)
    if not actorData.timers then actorData.timers = {} end
    -- РљР°Р¶РґРѕРјСѓ СЃС‚Р°РєСѓ РґР°С‘С‚СЃСЏ РІСЂРµРјСЏ РґРµР№СЃС‚РІРёСЏ: 2.5 СЃРµРє * РєРѕР»РёС‡РµСЃС‚РІРѕ РїСЂРµРґРјРµС‚РѕРІ
    table.insert(actorData.timers, (2.5 * actor:item_count(item)) * 60.0)
end)

-- РџРѕСЃС‚РѕР±РЅРѕРІР»РµРЅРёРµ: СѓРјРµРЅСЊС€Р°РµРј С‚Р°Р№РјРµСЂС‹, СѓРґР°Р»СЏРµРј СЃС‚РµРєРё, РµСЃР»Рё РёСЃС‚РµРєР»Рё
DeerItemsCallbacks.buff_post_step(buff, function(actor, stack)
    local actorData = actor:get_data("MassacreCurse", GUID)
    -- РћР±РЅРѕРІР»СЏРµРј РєР°Р¶РґС‹Р№ С‚Р°Р№РјРµСЂ
    for i, time in ipairs(actorData.timers) do
        actorData.timers[i] = time - 1
        if time <= 0 then
            table.remove(actorData.timers, i)
        end
    end

    -- Р•СЃР»Рё С‚Р°Р№РјРµСЂРѕРІ РјРµРЅСЊС€Рµ, С‡РµРј СЃС‚Р°РєРѕРІ вЂ” СѓРґР°Р»СЏРµРј Р»РёС€РЅРёРµ СЃС‚Р°РєРё
    if stack > #actorData.timers then
        local diff = stack - #actorData.timers
        actor:buff_remove(buff, diff)
        actor:recalculate_stats()
    end

    -- Р•СЃР»Рё СЃС‚Р°РєРѕРІ Р±РѕР»СЊС€Рµ РЅРµС‚ вЂ” СЃР±СЂР°СЃС‹РІР°РµРј СЃС‡С‘С‚С‡РёРє СѓР±РёР№СЃС‚РІ
    if stack == 0 then
        actorData.count = 0
    end
end)

-- РЈРІРµР»РёС‡РёРІР°РµРј СѓСЂРѕРЅ Рё Р±СЂРѕРЅСЋ РЅР° 3% Р·Р° СЃС‚Р°Рє
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack)
    actor.damage = actor.damage + ((actor.damage * 0.03) * stack)
    actor.armor  = actor.armor  + ((actor.armor  * 0.03) * stack)
end)
