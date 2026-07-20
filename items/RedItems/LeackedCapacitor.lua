-- DeerItems-LeackedCapacitor / В«РђРІР°СЂРёР№РЅС‹Р№ СЃРІРµСЂС…РїСЂРѕРІРѕРґРЅРёРєВ» / "Faulty Conductor"
-- РџРѕСЂС‚ Faulty Conductor РёР· RoR2 (+ Р°РІС‚РѕСЂСЃРєР°СЏ РґРѕР±Р°РІРєР° РїСЂРѕ СѓСЂРѕРЅ РґСЂРѕРЅРѕРІ).
-- РљР°Р¶РґС‹Рµ 15 СЃРµРє (в€’20% Р·Р° СЃС‚Р°Рє) РІРѕР»РЅР° Р·Р°СЂСЏР¶Р°РµС‚ СЃРѕСЋР·РЅРёРєРѕРІ РЅР° 7 СЃРµРє: +30% СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё Рё РїРµСЂРµРґРІРёР¶РµРЅРёСЏ.
-- Р”СЂРѕРЅС‹ РїРѕСЃС‚РѕСЏРЅРЅРѕ РїРѕР»СѓС‡Р°СЋС‚ +15% (+15% Р·Р° СЃС‚Р°Рє) Рє СѓСЂРѕРЅСѓ.

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°, РёРєРѕРЅРєР° Р±Р°С„С„Р° В«Р·Р°СЂСЏР¶РµРЅВ», С‡Р°СЃС‚РёС†Р°-РІСЃРїС‹С€РєР° РїСѓР»СЊСЃР° Рё Р·РІСѓРє вЂ” Р±РѕР»РІР°РЅРєРё РёР· template (Р·Р°РјРµРЅРёС€СЊ СЃР°Рј).
local sprite      = Sprite.new("item/LeackedCapacitor", PATH.."assets/sprites/items/sRedItems/LeackedCapacitor.png", 1, 18, 18)
local buffSprite  = Sprite.new("buff/LeackedCapacitor", PATH.."assets/sprites/buffs/LeackedCapacitor.png", 1, 4, 8)
local pulseSprite = Sprite.new("particle/LeackedCapacitor", PATH.."assets/sprites/particle/LeackedCapacitor.png", 5, 10, 10)
local sound       = Sound.new("LeackedCapacitor/pulse", PATH.."assets/sounds/LeackedCapacitor.ogg")

local GUID = _ENV["!guid"]
local oP   = gm.constants.oP

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°: РѕСЂРёРіРёРЅР°Р»СЊРЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ Рё РѕС‚РґРµР»СЊРЅС‹Р№ Р±РѕРЅСѓСЃ РґР»СЏ РґСЂРѕРЅРѕРІ.
local BASE_PERIOD  = 15 * 60   -- Р±Р°Р·РѕРІС‹Р№ РїРµСЂРёРѕРґ РІРѕР»РЅС‹: 15 СЃРµРє
local MIN_PERIOD   = 240       -- РїРѕР» РїРµСЂРёРѕРґР° (4 СЃРµРє), С‡С‚РѕР±С‹ РЅР° РІС‹СЃРѕРєРёС… СЃС‚Р°РєР°С… РЅРµ СЃС‚Р°Р»Рѕ СЃС‚Р°С‚РёС‡РЅРѕР№ Р°СѓСЂРѕР№
local DURATION     = 7 * 60    -- РґР»РёС‚РµР»СЊРЅРѕСЃС‚СЊ Р·Р°СЂСЏРґР°: 7 СЃРµРє
local ATK_PCT      = 0.30      -- +30% СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё (РїР»РѕСЃРєРѕ, РЅРµ Р·Р° СЃС‚Р°Рє вЂ” РјР°СЃС€С‚Р°Р±РёСЂСѓРµС‚СЃСЏ Р§РђРЎРўРћРўРђ)
local MOVE_PCT     = 0.30      -- +30% СЃРєРѕСЂРѕСЃС‚Рё РїРµСЂРµРґРІРёР¶РµРЅРёСЏ
local RADIUS       = 500       -- СЂР°РґРёСѓСЃ РІРѕР»РЅС‹
local DRONE_AS_STACK  = 0.15   -- +15% attack speed per stack
local DRONE_RADIUS = 100000    -- СЂР°РґРёСѓСЃ РїРѕРёСЃРєР° РґСЂРѕРЅРѕРІ (РІСЃСЏ Р°СЂРµРЅР°)

-- Р‘Р°С„С„ В«Р·Р°СЂСЏР¶РµРЅВ»: +СЃРєРѕСЂРѕСЃС‚СЊ Р°С‚Р°РєРё Рё РїРµСЂРµРґРІРёР¶РµРЅРёСЏ, РїРѕРєР° Р°РєС‚РёРІРµРЅ.
local energize = Buff.new("Energize")
energize.icon_sprite = buffSprite
energize.show_icon = true
energize.is_debuff = false
energize.max_stack = 1          -- РќР• -1; max_stack=1 в†’ РїРѕРІС‚РѕСЂРЅС‹Р№ РїСѓР»СЊСЃ РћР‘РќРћР’Р›РЇР•Рў РґР»РёС‚РµР»СЊРЅРѕСЃС‚СЊ, РЅРµ СЃРєР»Р°РґС‹РІР°РµС‚
DeerItemsCallbacks.buff_stat_recalc(energize, function(a, s)
    a.attack_speed = a.attack_speed * (1 + ATK_PCT)
    a.pHmax        = a.pHmax        * (1 + MOVE_PCT)
end)

-- РўРµРєСѓС‰РµРµ С‡РёСЃР»Рѕ СЃС‚Р°РєРѕРІ РїСЂРµРґРјРµС‚Р° РїРѕ РєРѕРјР°РЅРґР°Рј вЂ” РґР»СЏ РіР»РѕР±Р°Р»СЊРЅРѕРіРѕ С…СѓРєР° СѓСЃРёР»РµРЅРёСЏ РґСЂРѕРЅРѕРІ.
local g_team_stack = {}

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

-- РџСЂРёРЅСѓРґРёС‚РµР»СЊРЅС‹Р№ РїРµСЂРµСЃС‡С‘С‚ РґСЂРѕРЅРѕРІ РІР»Р°РґРµР»СЊС†Р° (РёС… СѓСЂРѕРЅ РјРЅРѕР¶РёС‚ С…СѓРє РЅР° РРҐ РїРµСЂРµСЃС‡С‘С‚Рµ,
-- РїРѕСЌС‚РѕРјСѓ РїСЂРё СЃРјРµРЅРµ С‡РёСЃР»Р° СЃС‚Р°РєРѕРІ РёС… РЅР°РґРѕ РїРµСЂРµСЃС‡РёС‚Р°С‚СЊ РІСЂСѓС‡РЅСѓСЋ).
local function recalc_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP and not is_not_drone(char) then
            char:recalculate_stats()
        end
    end
end

local item = Item.new("LeackedCapacitor")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack)
    if stack > 0 then g_team_stack[actor.team] = stack end
end)

DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    g_team_stack[actor.team] = stack
    recalc_drones(actor)
end)

DeerItemsCallbacks.item_removed(item, function(actor, stack)
    if stack <= 1 then g_team_stack[actor.team] = nil end
end)

-- РџСѓР»СЊСЃ Р·Р°СЂСЏРґР° РїРѕ СЃРѕСЋР·РЅРёРєР°Рј + РїРѕРґРґРµСЂР¶Р°РЅРёРµ СЃС‚Р°РєРѕРІ РєРѕРјР°РЅРґС‹.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if stack <= 0 then return end
    g_team_stack[actor.team] = stack

    local data = actor:get_data("LeackedCapacitor", GUID)

    -- РЎРјРµРЅРёР»РѕСЃСЊ С‡РёСЃР»Рѕ СЃС‚Р°РєРѕРІ в†’ Сѓ РґСЂРѕРЅРѕРІ РґСЂСѓРіРѕР№ РјРЅРѕР¶РёС‚РµР»СЊ СѓСЂРѕРЅР°; РїРµСЂРµСЃС‡РёС‚С‹РІР°РµРј РёС….
    if data.fc_last_stack ~= stack then
        data.fc_last_stack = stack
        recalc_drones(actor)
    end

    -- РџРµСЂРёРѕРґ РІРѕР»РЅС‹ СЃРѕРєСЂР°С‰Р°РµС‚СЃСЏ РЅР° 20% Р·Р° СЃС‚Р°Рє (СѓРјРЅРѕР¶Р°РµРј РєР°РґСЂС‹ РЅР° 0.8^(stack-1)), РЅРѕ РЅРµ РЅРёР¶Рµ РїРѕР»Р°.
    if Net.client then return end

    local period = math.max(MIN_PERIOD, math.floor(BASE_PERIOD * (0.8 ^ (stack - 1))))
    local frame  = Global._current_frame
    if data.fc_next == nil then data.fc_next = frame + period end
    if frame < data.fc_next then return end
    data.fc_next = frame + period

    -- Р—Р°СЂСЏР¶Р°РµРј РІСЃРµС… СЃРѕСЋР·РЅРёРєРѕРІ РІ СЂР°РґРёСѓСЃРµ (find_characters_circle РІРѕР·РІСЂР°С‰Р°РµС‚ Р РёРіСЂРѕРєРѕРІ, Р РґСЂРѕРЅРѕРІ).
    local allies = List.wrap(actor:find_characters_circle(actor.x, actor.y, RADIUS, false, actor.team, true))
    for _, ally in ipairs(allies) do
        ally:buff_apply(energize, DURATION, 1)
    end

    -- РћР±СЂР°С‚РЅР°СЏ СЃРІСЏР·СЊ: Р·РІСѓРє + РІСЃРїС‹С€РєР°-РєРѕР»СЊС†Рѕ Сѓ РёРіСЂРѕРєР°.
    actor:sound_play(sound, 0.9, 0.95 + math.random() * 0.2)
    local fx = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
    if fx then fx.sprite_index = pulseSprite end
end)

-- Р“Р»РѕР±Р°Р»СЊРЅС‹Р№ С…СѓРє РїРµСЂРµСЃС‡С‘С‚Р° СЃС‚Р°С‚РѕРІ: СѓСЃРёР»РёРІР°РµС‚ СѓСЂРѕРЅ РєР°Р¶РґРѕРіРѕ РґСЂРѕРЅР° РЅР° Р•Р“Рћ РїРµСЂРµСЃС‡С‘С‚Рµ.
-- РњРЅРѕР¶РёРј СѓР¶Рµ РїРѕСЃС‡РёС‚Р°РЅРЅРѕРµ РґРІРёР¶РєРѕРј Р·РЅР°С‡РµРЅРёРµ в†’ РЅРµ РЅР°РєР°РїР»РёРІР°РµС‚СЃСЏ (Р±Р°Р·Р° СЃР±СЂР°СЃС‹РІР°РµС‚СЃСЏ РєР°Р¶РґС‹Р№ РїРµСЂРµСЃС‡С‘С‚),
-- С‚РѕС‚ Р¶Рµ РїСЂРёС‘Рј, С‡С‚Рѕ РІ HeavyLungs.lua.
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end
    if is_not_drone(self) then return end
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end
    self.attack_speed = self.attack_speed * (1 + DRONE_AS_STACK * s)
end)
