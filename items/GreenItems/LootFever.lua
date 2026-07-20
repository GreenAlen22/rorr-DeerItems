-- DeerItems-LootFever / В«Р›РёС…РѕСЂР°РґРєР° РґРѕР±С‹С‡РёВ» / "Loot Fever"
-- РџРѕРґР±РѕСЂ РїСЂРµРґРјРµС‚Р° РґР°С‘С‚ РІСЂРµРјРµРЅРЅС‹Р№ Р±РѕРЅСѓСЃ Рє РѕСЃРЅРѕРІРЅС‹Рј С…Р°СЂР°РєС‚РµСЂРёСЃС‚РёРєР°Рј.
-- Р Р°Р·РјРµСЂ Р±РѕРЅСѓСЃР° Р·Р°РІРёСЃРёС‚ РѕС‚ СЂРµРґРєРѕСЃС‚Рё, С‚Р°Р№РјРµСЂС‹ С‚РёРєР°СЋС‚ РѕС‚РґРµР»СЊРЅРѕ, РёС‚РѕРіРѕРІС‹Р№ Р±РѕРЅСѓСЃ РѕРіСЂР°РЅРёС‡РµРЅ С‡РёСЃР»РѕРј РїСЂРµРґРјРµС‚РѕРІ.

-- РРєРѕРЅРєР° РїСЂРµРґРјРµС‚Р° Рё РёРєРѕРЅРєР° Р±Р°С„С„Р° (Р·Р°РіР»СѓС€РєРё-С€Р°Р±Р»РѕРЅС‹ вЂ” Р·Р°РјРµРЅРё С‚РµРєСЃС‚СѓСЂС‹ РїРѕ СЌС‚РёРј РїСѓС‚СЏРј).
local sprite      = Sprite.new("item/LootFever", PATH.."assets/sprites/items/sGreenItems/LootFever.png", 1, 18, 18)
local buff_sprite = Sprite.new("buff/LootFever", PATH.."assets/sprites/buffs/LootFever.png", 1, 7, 10)

-- guid РјРѕРґР°: СѓСЃРєРѕСЂСЏРµС‚ get_data
local GUID = _ENV["!guid"]

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local DURATION     = 20 * 60   -- РєР°Р¶РґС‹Р№ СЃС‚Р°Рє Р¶РёРІС‘С‚ 20 СЃРµРєСѓРЅРґ
local DURATION_STACK = 20 * 60 -- +20 СЃРµРєСѓРЅРґ Р·Р° С€С‚.
local CAP_PER_ITEM = 0.15      -- РјР°РєСЃ. Р±РѕРЅСѓСЃ Рє С…Р°СЂР°РєС‚РµСЂРёСЃС‚РёРєР°Рј Р·Р° С€С‚.

-- РџСЂРµРґРјРµС‚
local item = Item.new("LootFever")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
-- Р‘Р°С„С„ В«Р°Р·Р°СЂС‚В»: СЃС‚Р°РєРё С…СЂР°РЅРёРј СЃР°РјРё (is_timed=false), С‚Р°Р№РјРµСЂС‹ РІРµРґС‘Рј РІСЂСѓС‡РЅСѓСЋ вЂ” РєР°Рє BloodyRelic.
local buff = Buff.new("LootFever")
buff.icon_sprite         = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number   = true
buff.stack_number_col    = Array.new(1, Color(0xffd24a))
buff.is_timed  = false
buff.max_stack = 999
-- РљР°Р¶РґРѕРµ РїСЂРёРјРµРЅРµРЅРёРµ Р±Р°С„С„Р° РґРѕР±Р°РІР»СЏРµС‚ РѕС‚РґРµР»СЊРЅС‹Р№ С‚Р°Р№РјРµСЂ РЅР° DURATION РєР°РґСЂРѕРІ
buff:onApply(function(actor, stack)
    local data = actor:get_data("LootFever", GUID)
    if not data.timers then data.timers = {} end
    local item_stack = actor:item_count(item) or 1
    table.insert(data.timers, {
        time = DURATION + DURATION_STACK * (item_stack - 1),
        bonus = data.pending_bonus or 0.02,
    })
    data.pending_bonus = nil
end)

-- РўРёРє С‚Р°Р№РјРµСЂРѕРІ: РёСЃС‚С‘РєС€РёРµ СЃС‚Р°РєРё СЃРЅРёРјР°РµРј; СЃРІРµСЂС…Сѓ РґРµСЂР¶РёРј РєР°Рї РїРѕ С‡РёСЃР»Сѓ РїСЂРµРґРјРµС‚РѕРІ
buff:onPostStep(function(actor, stack)
    local data = actor:get_data("LootFever", GUID)
    if data.timers then
        for i = #data.timers, 1, -1 do
            data.timers[i].time = data.timers[i].time - 1
            if data.timers[i].time <= 0 then
                table.remove(data.timers, i)
                actor:buff_remove(buff, 1)
            end
        end
    end
    if stack == 0 and data.timers then data.timers = {} end
end)

-- РЎСѓРјРјР°СЂРЅС‹Р№ Р±РѕРЅСѓСЃ Рє РѕСЃРЅРѕРІРЅС‹Рј С…Р°СЂР°РєС‚РµСЂРёСЃС‚РёРєР°Рј, РѕРіСЂР°РЅРёС‡РµРЅРЅС‹Р№ РєР°РїРѕРј.
buff:onStatRecalc(function(actor, stack)
    local data = actor:get_data("LootFever", GUID)
    local total = 0
    for _, entry in ipairs(data.timers or {}) do
        total = total + (entry.bonus or 0)
    end

    local cap = CAP_PER_ITEM * (actor:item_count(item) or 1)
    local mult = 1 + math.min(total, cap)
    actor.damage       = actor.damage * mult
    actor.attack_speed = actor.attack_speed * mult
    actor.pHmax        = actor.pHmax * mult
    actor.hp_regen     = actor.hp_regen * mult
end)

local function item_from_pickup(pickup)
    if not (pickup and Instance.exists(pickup)) then return nil end

    local object_id = pickup.object_index
    if object_id and gm.object_to_item then
        local ok, item_id = pcall(gm.object_to_item, object_id)
        if ok and item_id and item_id >= 0 then
            return Item.wrap(item_id)
        end
    end

    for _, key in ipairs({ "item", "item_id", "item_index" }) do
        local item_id = pickup[key]
        if type(item_id) == "number" and item_id >= 0 then
            local ok, picked = pcall(Item.wrap, item_id)
            if ok and picked then return picked end
        end
    end

    return nil
end

local function bonus_for_pickup(pickup)
    local picked = item_from_pickup(pickup)
    local tier = picked and picked.tier

    if tier == ItemTier.COMMON then return 0.02 end
    if tier == ItemTier.UNCOMMON then return 0.04 end
    if tier == ItemTier.EQUIPMENT then return 0.06 end
    if tier == ItemTier.RARE or tier == ItemTier.BOSS then return 0.08 end

    return 0.02
end

-- Р›СЋР±РѕР№ РїРѕРґРѕР±СЂР°РЅРЅС‹Р№ РїСЂРµРґРјРµС‚ РґРѕР±Р°РІР»СЏРµС‚ РІСЂРµРјРµРЅРЅС‹Р№ Р±РѕРЅСѓСЃ (С‚РѕР»СЊРєРѕ РґРµСЂР¶Р°С‚РµР»СЏРј РїСЂРµРґРјРµС‚Р°, РЅР° С…РѕСЃС‚Рµ).
item:onPickupCollected(function(actor, stack, pickup_instance)
    if not (actor and Instance.exists(actor)) then return end
    if not Net.host then return end
    if stack <= 0 then return end

    actor:get_data("LootFever", GUID).pending_bonus = bonus_for_pickup(pickup_instance)
    actor:buff_apply(buff, 1, 1)
end)
