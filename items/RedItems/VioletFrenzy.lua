-- DeerItems-VioletFrenzy / В«Р›РёР»РѕРІРѕРµ РЅРµРёСЃС‚РѕРІСЃС‚РІРѕВ» / "Violet Frenzy"
-- РџРѕСЂС‚ Brainstalks РёР· RoR2.
-- РџСЂРё СѓР±РёР№СЃС‚РІРµ СЌР»РёС‚РЅРѕРіРѕ РјРѕРЅСЃС‚СЂР° (РёР»Рё Р±РѕСЃСЃР°) РёРіСЂРѕРє РІС…РѕРґРёС‚ РІ СЃРѕСЃС‚РѕСЏРЅРёРµ Р±РµСЂСЃРµСЂРєР° РЅР° 4 (+4 Р·Р° С€С‚.) СЃРµРєСѓРЅРґС‹.
-- РџРѕРєР° Р±РµСЂСЃРµСЂРє Р°РєС‚РёРІРµРЅ, РїРµСЂРµР·Р°СЂСЏРґРєР° Р’РЎР•РҐ СѓРјРµРЅРёР№ СЃРѕСЃС‚Р°РІР»СЏРµС‚ 0,5 СЃРµРєСѓРЅРґС‹, Р° СЌРєСЂР°РЅ СЃР»РµРіРєР° РїРѕРґРєСЂР°С€РёРІР°РµС‚СЃСЏ Р»РёР»РѕРІС‹Рј.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° (РїР»РµР№СЃС…РѕР»РґРµСЂ вЂ” РєРѕРїРёСЏ Community.png; Р·Р°РјРµРЅРё РЅР° С„РёРЅР°Р»СЊРЅС‹Р№ Р°СЂС‚ РїРѕ СЌС‚РѕРјСѓ РїСѓС‚Рё)
local sprite = Sprite.new("item/VioletFrenzy", PATH.."assets/sprites/items/sRedItems/VioletFrenzy.png", 1, 18, 17)

-- guid РјРѕРґР°: СѓСЃРєРѕСЂСЏРµС‚ get_data (Р±РµР· РѕР±С…РѕРґР° debug-СЃС‚РµРєР° РЅР° РєР°Р¶РґРѕРј РєР°РґСЂРµ)
local GUID = _ENV["!guid"]

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local BASE_SECONDS = 8
local STACK_SECONDS = 6
local SPEED_MULT  = 1.3
local TINT        = Color(0x8A2BE2)  -- Р»РёР»РѕРІС‹Р№ (blueviolet, RGB)
local TINT_ALPHA  = 0.16             -- СЃРёР»Р° СЌРєСЂР°РЅРЅРѕР№ РїРѕРґСЃРІРµС‚РєРё

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° VioletFrenzy
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: РєСЂР°СЃРЅС‹Р№ (Р»РµРіРµРЅРґР°СЂРЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: СѓС‚РёР»РёС‚Р°СЂРЅС‹Р№ РїСЂРµРґРјРµС‚ (РєР°Рє Brainstalks)
local item = Item.new("VioletFrenzy")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- РћС‡РёСЃС‚РєР° СЃС‚Р°СЂС‹С… РєРѕР»Р»Р±РµРєРѕРІ
-- Р‘Р°С„С„-С„Р»Р°Рі В«Р±РµСЂСЃРµСЂРєВ». РЎР°Рј РїРѕ СЃРµР±Рµ СЃС‚Р°С‚РѕРІ РЅРµ РјРµРЅСЏРµС‚ вЂ” СЃР»СѓР¶РёС‚ РёРЅРґРёРєР°С‚РѕСЂРѕРј СЃРѕСЃС‚РѕСЏРЅРёСЏ
-- (РїРѕ РЅРµРјСѓ СЌРєСЂР°РЅРЅС‹Р№ С…СѓРє СЂРµС€Р°РµС‚, РєСЂР°СЃРёС‚СЊ Р»Рё СЌРєСЂР°РЅ, Р° HUD РїРѕРєР°Р·С‹РІР°РµС‚ РёРєРѕРЅРєСѓ).
local buff = Buff.new("VioletFrenzy")
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1
buff:onStatRecalc(function(actor, stack)
    actor.pHmax = actor.pHmax * SPEED_MULT
end)

-- Р‘РµР·РѕРїР°СЃРЅРѕРµ РїСЂРёРІРµРґРµРЅРёРµ Р·РЅР°С‡РµРЅРёСЏ GML-С„СѓРЅРєС†РёРё (true / 1.0 / 0.0) Рє Р±СѓР»РµРІСѓ
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

-- РЇРІР»СЏРµС‚СЃСЏ Р»Рё СѓР±РёС‚С‹Р№ СЌР»РёС‚РѕР№ РёР»Рё Р±РѕСЃСЃРѕРј
local function is_elite_or_boss(victim)
    if not victim or not Instance.exists(victim) then return false end
    if GM.actor_is_boss and truthy(GM.actor_is_boss(victim)) then return true end
    if GM.actor_is_elite and truthy(GM.actor_is_elite(victim)) then return true end
    return false
end

-- РџСЂРё СѓР±РёР№СЃС‚РІРµ СЌР»РёС‚С‹ вЂ” РІС…РѕРґРёРј (РёР»Рё РїСЂРѕРґР»РµРІР°РµРј) Р±РµСЂСЃРµСЂРє.
-- РўР°Р№РјРµСЂ РћР‘РќРћР’Р›РЇР•РўРЎРЇ РґРѕ РїРѕР»РЅРѕР№ РґР»РёС‚РµР»СЊРЅРѕСЃС‚Рё (РЅРµ СЃСѓРјРјРёСЂСѓРµС‚СЃСЏ), РєР°Рє РІ RoR2:
-- С‡С‚РѕР±С‹ РґРµСЂР¶Р°С‚СЊ Р±РµСЂСЃРµСЂРє, РЅСѓР¶РЅРѕ СѓР±РёРІР°С‚СЊ СЌР»РёС‚Сѓ РЅРµ СЂРµР¶Рµ, С‡РµРј СЂР°Р· РІ РґР»РёС‚РµР»СЊРЅРѕСЃС‚СЊ. Р­С‚Рѕ РµСЃС‚РµСЃС‚РІРµРЅРЅС‹Р№ РєСЌРї Р°РїС‚Р°Р№РјР°.
item:onKillProc(function(actor, victim, stack)
    if Net.client then return end

    if not is_elite_or_boss(victim) then return end
    stack = stack or 1
    local data = actor:get_data(nil, GUID)
    local full = (BASE_SECONDS + STACK_SECONDS * (stack - 1)) * 60
    data.berserk = math.max(data.berserk or 0, full)
end)

local function is_berserk(actor)
    return actor:buff_count(buff) > 0 or (actor:get_data(nil, GUID).berserk or 0) > 0
end

local function reduce_slot_cooldown(actor, slot)
    local sk = actor:get_active_skill(slot)
    if not sk then return end

    local cooldown = sk.cooldown or sk.cooldown_base or 0
    if cooldown <= 0 then return end
    if not sk.cooldown_stopwatch or not actor:stopwatch_is_active(sk.cooldown_stopwatch) then return end

    local remaining = actor:stopwatch_get_duration_remaining(sk.cooldown_stopwatch)
    if not remaining or remaining <= 0 then return end

    local reduced = math.max(0, math.ceil(remaining - cooldown * 0.5))
    if reduced <= 0 then
        actor:override_active_skill_cooldown(slot, 0)
        return
    end

    local frame = Global._current_frame or 0
    local duration = actor:stopwatch_get_duration(sk.cooldown_stopwatch) or cooldown
    local ready_frame = frame + reduced
    actor:stopwatch_stop(sk.cooldown_stopwatch)
    actor:stopwatch_start(sk.cooldown_stopwatch, ready_frame, ready_frame - duration)
end

local function reduce_other_skills(actor, used_slot)
    if not is_berserk(actor) then return end

    for _, slot in ipairs({ Skill.Slot.PRIMARY, Skill.Slot.SECONDARY, Skill.Slot.UTILITY, Skill.Slot.SPECIAL }) do
        if slot ~= used_slot then
            reduce_slot_cooldown(actor, slot)
        end
    end
end

-- РљР°Р¶РґС‹Р№ РєР°РґСЂ Сѓ РґРµСЂР¶Р°С‚РµР»СЏ: РїРѕРєР° Р±РµСЂСЃРµСЂРє Р°РєС‚РёРІРµРЅ, РїРѕРґРґРµСЂР¶РёРІР°РµРј С‚Р°Р№РјРµСЂ Рё РІРёР·СѓР°Р»СЊРЅС‹Р№ Р±Р°С„С„.
-- РЎРѕРєСЂР°С‰РµРЅРёРµ РєСѓР»РґР°СѓРЅРѕРІ РїСЂРѕРёСЃС…РѕРґРёС‚ С‚РѕР»СЊРєРѕ РІ onSecondaryUse/onUtilityUse/onSpecialUse.
item:onPostStep(function(actor, stack)
    if Net.client then return end

    local data = actor:get_data(nil, GUID)
    local t = data.berserk or 0
    if t <= 0 then return end

    -- РџРѕРґРґРµСЂР¶РёРІР°РµРј РІРёР·СѓР°Р»СЊРЅС‹Р№ Р±Р°С„С„, РїРѕРєР° РёРґС‘С‚ Р±РµСЂСЃРµСЂРє
    if actor:buff_count(buff) <= 0 then
        actor:buff_apply(buff, 2)
    end

    data.berserk = t - 1
    if data.berserk <= 0 then
        data.berserk = 0
        local n = actor:buff_count(buff)
        if n > 0 then actor:buff_remove(buff, n) end
    end
end)

item:onSecondaryUse(function(actor, stack, active_skill)
    reduce_other_skills(actor, Skill.Slot.SECONDARY)
end)

item:onUtilityUse(function(actor, stack, active_skill)
    reduce_other_skills(actor, Skill.Slot.UTILITY)
end)

item:onSpecialUse(function(actor, stack, active_skill)
    reduce_other_skills(actor, Skill.Slot.SPECIAL)
end)

-- Р­РєСЂР°РЅРЅР°СЏ РїРѕРґСЃРІРµС‚РєР°: Р»С‘РіРєРёР№ Р»РёР»РѕРІС‹Р№ РѕРІРµСЂР»РµР№ РЅР° РІРµСЃСЊ СЌРєСЂР°РЅ Р»РѕРєР°Р»СЊРЅРѕРіРѕ РёРіСЂРѕРєР°, РїРѕРєР° РѕРЅ РІ Р±РµСЂСЃРµСЂРєРµ.
-- Р РёСЃСѓРµРј РїРѕРІРµСЂС… HUD РІ СЌРєСЂР°РЅРЅС‹С… РєРѕРѕСЂРґРёРЅР°С‚Р°С…; rect РґРѕ СЂР°Р·РјРµСЂРѕРІ РґРёСЃРїР»РµСЏ РіР°СЂР°РЅС‚РёСЂРѕРІР°РЅРЅРѕ РїРѕРєСЂС‹РІР°РµС‚ СЌРєСЂР°РЅ.
gm.post_script_hook(gm.constants.draw_hud, function()
    local p = Player.get_client()
    if not p or not Instance.exists(p) then return end
    if p:buff_count(buff) <= 0 then return end

    local w = gm.display_get_width()
    local h = gm.display_get_height()
    gm.draw_set_colour(TINT)
    gm.draw_set_alpha(TINT_ALPHA)
    gm.draw_rectangle(0, 0, w, h, false)
    gm.draw_set_alpha(1)
    gm.draw_set_colour(Color.WHITE)
end)
