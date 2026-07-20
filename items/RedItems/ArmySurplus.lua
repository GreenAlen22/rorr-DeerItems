-- DeerItems-ArmySurplus / В«РђСЂРјРµР№СЃРєРёРµ РёР·Р»РёС€РєРёВ» / "Army Surplus"
-- РџРѕСЂС‚ Spare Drone Parts РёР· RoR2.
-- РџСЂРёР·С‹РІР°РµС‚ РќРђРЎРўРћРЇР©Р•Р“Рћ РёРіСЂРѕРІРѕРіРѕ Р±РѕРµРІРѕРіРѕ РґСЂРѕРЅР° (oDrone10 вЂ” СЂРµРґРєРёР№ В«РєСЂР°СЃРЅС‹Р№В» Р±РѕРµРІРѕР№ РґСЂРѕРЅ) вЂ” С‚Р°РєРѕРіРѕ Р¶Рµ,
-- РєР°Рє РїРѕРєСѓРїР°РµРјС‹Рµ Сѓ СЃР»РѕРјР°РЅРЅС‹С… РґСЂРѕРЅРѕРІ-РёРЅС‚РµСЂР°РєС‚РёРІРѕРІ. РћРЅ СЃР°Рј Р»РµС‚Р°РµС‚, РЅР°РІРѕРґРёС‚СЃСЏ Рё СЃС‚СЂРµР»СЏРµС‚ СЃРІРѕРёРј РР
-- Рё РќР• СѓРїСЂР°РІР»СЏРµС‚СЃСЏ РєР°Рє РІС‚РѕСЂРѕР№ РїРµСЂСЃРѕРЅР°Р¶ (РІ РѕС‚Р»РёС‡РёРµ РѕС‚ oPDrone + set_player, РєРѕС‚РѕСЂС‹Р№ РґРµР»Р°Р» РёРјРµРЅРЅРѕ С‚Р°Рє).
-- РЎРїР°РІРЅ вЂ” РїСЂРѕРІРµСЂРµРЅРЅС‹Рј СЃРїРѕСЃРѕР±РѕРј РёР· РїСЂРёРјРµСЂР° Artifact of Assembly:
--   gm.instance_create_depth(x, y, depth, gm.constants.oDrone1)  в†’ РіРѕС‚РѕРІС‹Р№ РґСЂРѕРЅ-СЃРѕСЋР·РЅРёРє.
-- Р’СЃРµ РЅР°СЃС‚РѕСЏС‰РёРµ РґСЂРѕРЅС‹/СЃРѕСЋР·РЅРёРєРё РІР»Р°РґРµР»СЊС†Р° (РІРєР»СЋС‡Р°СЏ СЌС‚РѕРіРѕ) РїРѕР»СѓС‡Р°СЋС‚ +60% СѓСЂРѕРЅР° Р·Р° СЃС‚Р°Рє.
-- Р§Р°СЃС‚СЊ РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅРѕРіРѕ Р»РµС‡РµРЅРёСЏ РІР»Р°РґРµР»СЊС†Р° РїРµСЂРµРґР°РµС‚СЃСЏ РґСЂРѕРЅР°Рј.

local sprite = Sprite.new("item/ArmySurplus", PATH.."assets/sprites/items/sRedItems/ArmySurplus.png", 1, 18, 18)

local GUID = _ENV["!guid"]
local oP   = gm.constants.oP

-- РљР°РєРѕРіРѕ РёРіСЂРѕРІРѕРіРѕ РґСЂРѕРЅР° СЂР°Р·РІРѕСЂР°С‡РёРІР°С‚СЊ. oDrone10 = СЂРµРґРєРёР№ Р±РѕРµРІРѕР№ РґСЂРѕРЅ РёР· В«РєСЂР°СЃРЅРѕР№В» РіСЂСѓРїРїС‹
-- (РїРѕ СЂР°Р·Р±РёРІРєРµ Artifact of Assembly: red = {oDrone8, oDrone9, oDrone10}). Р•СЃР»Рё РІ СЌС‚РѕР№ СЃР±РѕСЂРєРµ
-- С‚Р°РєРѕР№ РєРѕРЅСЃС‚Р°РЅС‚С‹ РЅРµС‚ вЂ” РѕС‚РєР°С‚С‹РІР°РµРјСЃСЏ РЅР° РЅР°РґС‘Р¶РЅРѕРіРѕ Р±Р°Р·РѕРІРѕРіРѕ oDrone1, С‡С‚РѕР±С‹ РїСЂРµРґРјРµС‚ РЅРµ В«РјРѕР»С‡Р°Р»В».
local DRONE_OBJ = gm.constants.oDrone10 or gm.constants.oDrone1

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local DRONE_DMG_STACK = 0.60    -- +60% drone damage per stack
local HEAL_SHARE = 0.25
local HEAL_BUFFER_DURATION = 3 * 60
local DRONE_RADIUS = 100000

local g_team_stack = {}   -- СЃС‚Р°РєРё РїСЂРµРґРјРµС‚Р° РїРѕ РєРѕРјР°РЅРґР°Рј вЂ” РґР»СЏ С…СѓРєР° СѓСЃРёР»РµРЅРёСЏ РґСЂРѕРЅРѕРІ

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

local item = Item.new("ArmySurplus")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
-- Р–РёРІ Р»Рё РЅР°С€ РґСЂРѕРЅ? Р­С‚Рѕ RAW-РёРЅСЃС‚Р°РЅСЃ (РёР· gm.instance_create_depth), РїРѕСЌС‚РѕРјСѓ РїСЂРѕРІРµСЂСЏРµРј РЅР°С‚РёРІРЅРѕ.
-- gm.instance_exists РІРѕР·РІСЂР°С‰Р°РµС‚ 1.0/0.0 вЂ” СЃСЂР°РІРЅРёРІР°РµРј СЃ 1.0 (РїРѕРјРЅРёРј РїСЂРѕ В«0.0 truthyВ» РІ Lua).
-- Р”РѕРї. СЃРІРµСЂРєР° object_index СЃС‚СЂР°С…СѓРµС‚ РѕС‚ РїРµСЂРµРёСЃРїРѕР»СЊР·РѕРІР°РЅРёСЏ id РґРІРёР¶РєРѕРј РїРѕСЃР»Рµ СЃРјРµСЂС‚Рё РґСЂРѕРЅР°.
local function drone_alive(inst)
    return inst ~= nil and gm.instance_exists(inst) == 1.0 and inst.object_index == DRONE_OBJ
end

-- Р Р°Р·РІРѕСЂР°С‡РёРІР°РµРј РЅР°СЃС‚РѕСЏС‰РµРіРѕ РґСЂРѕРЅР° Сѓ РІР»Р°РґРµР»СЊС†Р°, РµСЃР»Рё РµРіРѕ РµС‰С‘ РЅРµС‚. РўРѕР»СЊРєРѕ РЅР° С…РѕСЃС‚Рµ: РґСЂРѕРЅ вЂ” СЃРµС‚РµРІР°СЏ
-- СЃСѓС‰РЅРѕСЃС‚СЊ, С…РѕСЃС‚ РµС‘ СЃРїР°РІРЅРёС‚, Р° РєР»РёРµРЅС‚Р°Рј РёРіСЂР° СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓРµС‚ РґСЂРѕРЅР° СЃРІРѕРёРјРё СЃСЂРµРґСЃС‚РІР°РјРё СЃР°РјР°.
local function ensure_drone(actor)
    if Net.client then return end
    if not DRONE_OBJ then return end                 -- РєРѕРЅСЃС‚Р°РЅС‚Р° РЅРµРґРѕСЃС‚СѓРїРЅР° вЂ” С‚РёС…Рѕ РІС‹С…РѕРґРёРј
    local data = actor:get_data("ArmySurplus", GUID)
    if drone_alive(data.inst) then return end
    local inst = gm.instance_create_depth(actor.x, actor.y, actor.depth, DRONE_OBJ)
    -- РџСЂРёРІСЏР·С‹РІР°РµРј РґСЂРѕРЅР° Рє Р’Р›РђР”Р•Р›Р¬Р¦РЈ. owner вЂ” СЂРµР°Р»СЊРЅРѕРµ РїРѕР»Рµ РґСЂРѕРЅРѕРІ (РµРіРѕ С‡РёС‚Р°РµС‚ voidCore.lua);
    -- РєР»Р°РґС‘Рј РёРјРµРЅРЅРѕ raw-CInstance (actor.value), Р° РЅРµ С‚СѓР»РєРёС‚-РѕР±С‘СЂС‚РєСѓ, РёРЅР°С‡Рµ GML РїРѕР»СѓС‡РёС‚ РјСѓСЃРѕСЂ.
    inst.owner = actor.value
    data.inst  = inst
end

local function heal_drones(actor, amount)
    if amount <= 0 then return end

    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP and not is_not_drone(char) then
            char:heal(amount)
        end
    end
end

local function share_bonus_healing(actor)
    local data = actor:get_data("ArmySurplus", GUID)
    local hp = actor.hp
    local maxhp = actor.maxhp
    if not hp or not maxhp then return end

    if data.as_prev_hp == nil or data.as_prev_maxhp ~= maxhp then
        data.as_prev_hp = hp
        data.as_prev_maxhp = maxhp
    else
        local gained = hp - data.as_prev_hp
        if gained > 0 then
            local expected_regen = math.max(0, actor.hp_regen or 0)
            local bonus_heal = gained - expected_regen
            if bonus_heal > 0 then
                data.as_heal_buffer = (data.as_heal_buffer or 0) + bonus_heal * HEAL_SHARE
            end
        end
    end

    data.as_prev_hp = actor.hp
    data.as_prev_maxhp = maxhp

    data.as_heal_buffer_timer = (data.as_heal_buffer_timer or HEAL_BUFFER_DURATION) - 1
    if data.as_heal_buffer_timer <= 0 then
        heal_drones(actor, data.as_heal_buffer or 0)
        data.as_heal_buffer = 0
        data.as_heal_buffer_timer = HEAL_BUFFER_DURATION
    end
end

item:onStatRecalc(function(actor, stack)
    if stack > 0 then g_team_stack[actor.team] = stack end
end)

item:onAcquire(function(actor, stack)
    g_team_stack[actor.team] = stack
    ensure_drone(actor)
    local data = actor:get_data("ArmySurplus", GUID)
    data.as_prev_hp = actor.hp
    data.as_prev_maxhp = actor.maxhp
    data.as_heal_buffer = 0
    data.as_heal_buffer_timer = HEAL_BUFFER_DURATION
end)

item:onRemove(function(actor, stack)
    if stack <= 1 then
        g_team_stack[actor.team] = nil
        if Net.client then return end
        local data = actor:get_data("ArmySurplus", GUID)
        if drone_alive(data.inst) then gm.instance_destroy(data.inst) end
        data.inst = nil
    end
end)

-- Р”РµСЂР¶РёРј СЃС‚Р°Рє СЃРІРµР¶РёРј + РїРµСЂРµСѓСЃС‚Р°РЅР°РІР»РёРІР°РµРј РґСЂРѕРЅР°, РµСЃР»Рё РёРіСЂР° РµРіРѕ СѓР±СЂР°Р»Р°. РљСѓРїР»РµРЅРЅС‹Рµ РґСЂРѕРЅС‹ РЅРµ
-- РїРµСЂРµС…РѕРґСЏС‚ РјРµР¶РґСѓ СЌС‚Р°РїР°РјРё вЂ” РЅР° РЅРѕРІРѕР№ Р»РѕРєР°С†РёРё drone_alive РІРµСЂРЅС‘С‚ false Рё РјС‹ СЂР°Р·РІРµСЂРЅС‘Рј СЃРІРѕРµРіРѕ Р·Р°РЅРѕРІРѕ.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    g_team_stack[actor.team] = stack
    ensure_drone(actor)
    share_bonus_healing(actor)
end)

-- РЈСЃРёР»РµРЅРёРµ СѓСЂРѕРЅР° Р’РЎР•РҐ РґСЂРѕРЅРѕРІ/СЃРѕСЋР·РЅРёРєРѕРІ РІР»Р°РґРµР»СЊС†Р° вЂ” РЅР° РїРµСЂРµСЃС‡С‘С‚Рµ РёС… СЃС‚Р°С‚РѕРІ
-- (РїСЂРёС‘Рј РёР· HeavyLungs: РІР°РЅРёР»СЊРЅС‹Рµ РґСЂРѕРЅС‹ РЅРµ Р·РѕРІСѓС‚ item:onStatRecalc, Р»РѕРІРёРј РёС… РІ С…СѓРєРµ).
-- РќР°С€ СЂР°Р·РІС‘СЂРЅСѓС‚С‹Р№ oDrone1 вЂ” С‚РѕР¶Рµ РґСЂРѕРЅ, РїРѕСЌС‚РѕРјСѓ СѓСЃРёР»РёРІР°РµС‚СЃСЏ СЌС‚РёРј Р¶Рµ С…СѓРєРѕРј (РєР°Рє Рё Р·Р°РґСѓРјР°РЅРѕ).
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end       -- РЅРµ С‚СЂРѕРіР°РµРј СЃР°РјРёС… РёРіСЂРѕРєРѕРІ
    if is_not_drone(self) then return end
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end
    self.damage = self.damage * (1 + DRONE_DMG_STACK * s)
end)
