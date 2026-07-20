-- DeerItems-BloodyRelic
-- 10% С€Р°РЅСЃ РїСЂРё СѓРґР°СЂРµ РґР°С‚СЊ Р±Р°С„С„ РЅР° 8 СЃРµРє, СѓРІРµР»РёС‡РёРІР°СЋС‰РёР№ СЃРєРѕСЂРѕСЃС‚СЊ Р°С‚Р°РєРё. РњР°РєСЃ. Р±Р°С„С„РѕРІ: 5 + РєРѕР»РёС‡РµСЃС‚РІРѕ РїСЂРµРґРјРµС‚РѕРІ.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
local sprite = Sprite.new("item/BloodyRelic", PATH.."assets/sprites/items/sGreenItems/BloodyRelic.png", 1, 16, 17)

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° BloodyRelic
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р·РµР»С‘РЅС‹Р№ (РЅРµРѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ
local item = Item.new("BloodyRelic")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- guid РјРѕРґР°: СѓСЃРєРѕСЂСЏРµС‚ get_data (Р±РµР· РѕР±С…РѕРґР° debug-СЃС‚РµРєР° РЅР° РєР°Р¶РґРѕРј РєР°РґСЂРµ)
local GUID = _ENV["!guid"]
local PROC_CHANCE_PER_STACK = 0.10

local function hyperbolic_chance(stack)
    if stack <= 0 then return 0 end
    return 1 - (1 - PROC_CHANCE_PER_STACK) ^ stack
end

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ Р±Р°С„С„Р°
local buff_sprite = Sprite.new("buff/BloodyRelic", PATH.."assets/sprites/buffs/BloodyRelic.png", 1, 7, 10)

-- РЎРѕР·РґР°РЅРёРµ Р±Р°С„С„Р° BloodyRelic
local buff = Buff.new("BloodyRelic")
buff.icon_sprite = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0x870c0c))
buff.is_timed = false
buff.max_stack = 999

-- РџСЂРё РїСЂРёРјРµРЅРµРЅРёРё Р±Р°С„С„Р° вЂ” СЃРѕР·РґР°С‘Рј С‚Р°Р№РјРµСЂ РµРіРѕ РґРµР№СЃС‚РІРёСЏ (8 СЃРµРєСѓРЅРґ)
DeerItemsCallbacks.buff_apply(buff, function(actor, stack)
    local data = actor:get_data("BloodyRelic", GUID)
    if not data.timers then
        data.timers = {}
    end
    table.insert(data.timers, 8 * 60)
end)

-- РљР°Р¶РґС‹Р№ РєР°РґСЂ: СѓРјРµРЅСЊС€Р°РµРј С‚Р°Р№РјРµСЂС‹, СѓРґР°Р»СЏРµРј РёСЃС‚С‘РєС€РёРµ, РѕРіСЂР°РЅРёС‡РёРІР°РµРј СЃС‚Р°РєРё
DeerItemsCallbacks.buff_post_step(buff, function(actor, stack)
    local data = actor:get_data("BloodyRelic", GUID)
    local maxAllowed = 5 + actor:item_count(item)
    if data.timers then
        -- РћР±РЅРѕРІР»РµРЅРёРµ Рё СѓРґР°Р»РµРЅРёРµ РёСЃС‚РµРєС€РёС… С‚Р°Р№РјРµСЂРѕРІ
        for i = #data.timers, 1, -1 do
            data.timers[i] = data.timers[i] - 1
            if data.timers[i] <= 0 then
                table.remove(data.timers, i)
                actor:buff_remove(buff, 1)
            end
        end
        -- РџСЂРёРЅСѓРґРёС‚РµР»СЊРЅРѕРµ СѓРґР°Р»РµРЅРёРµ Р»РёС€РЅРёС… СЃС‚Р°РєРѕРІ, РµСЃР»Рё Р±РѕР»СЊС€Рµ РґРѕРїСѓСЃС‚РёРјРѕРіРѕ Р»РёРјРёС‚Р°
        if stack > maxAllowed then
            local overflow = stack - maxAllowed
            for i = 1, overflow do
                table.remove(data.timers, 1)
            end
            actor:buff_remove(buff, overflow)
        end
    end

    -- Р•СЃР»Рё СЃС‚Р°РєРѕРІ Р±РѕР»СЊС€Рµ РЅРµС‚ вЂ” СЃР±СЂР°СЃС‹РІР°РµРј РІСЃРµ С‚Р°Р№РјРµСЂС‹
    if stack == 0 and data.timers then
        data.timers = {}
    end
end)

-- Р‘Р°С„С„ СѓРІРµР»РёС‡РёРІР°РµС‚ СЃРєРѕСЂРѕСЃС‚СЊ Р°С‚Р°РєРё РЅР° 5% Р·Р° СЃС‚Р°Рє
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack)
    actor.attack_speed = actor.attack_speed + ((actor.attack_speed * 0.05) * stack)
end)

-- РџСЂРё РїРѕРїР°РґР°РЅРёРё: 20% Р·Р° РїРµСЂРІС‹Р№ РїСЂРµРґРјРµС‚, Р·Р°С‚РµРј СѓР±С‹РІР°СЋС‰РёР№ РїСЂРёСЂРѕСЃС‚ С€Р°РЅСЃР°.
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end

    if math.random() <= hyperbolic_chance(stack) then
        actor:buff_apply(buff, 1)
    end
end)
