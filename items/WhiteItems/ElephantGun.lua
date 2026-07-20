-- DeerItems-ElephantGun
-- РЎР»РѕРЅРѕР±РѕР№: РЅР°РЅРѕСЃРёС‚ Р±РѕР»СЊС€Рµ СѓСЂРѕРЅР° Р±РѕСЃСЃР°Рј Рё С‡Р°С‰Рµ РєСЂРёС‚СѓРµС‚ РїРѕ РЅРёРј.
-- (РђРґР°РїС‚Р°С†РёСЏ Armor-Piercing Rounds РёР· RoR2.)

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° (Р±РµР· РїР°СЂС‚РёРєР»РѕРІ Рё Р·РІСѓРєР° РїРѕ РўР—)
local sprite = Sprite.new("item/ElephantGun", PATH.."assets/sprites/items/sWhiteItems/ElephantGun.png", 1, 18, 18)

-- +15% СѓСЂРѕРЅР° Рё +10% РєСЂРёС‚-С€Р°РЅСЃР° Р±РѕСЃСЃР°Рј Р·Р° СЃС‚Р°Рє
local BOSS_DMG_PER_STACK = 0.15
local BOSS_CRIT_PER_STACK = 10

-- Р‘РµР·РѕРїР°СЃРЅРѕРµ РїСЂРёРІРµРґРµРЅРёРµ Р·РЅР°С‡РµРЅРёСЏ GML-С„СѓРЅРєС†РёРё (true / 1.0 / 0.0) Рє Р±СѓР»РµРІСѓ.
-- Р’РђР–РќРћ: GM.actor_is_boss РІРѕР·РІСЂР°С‰Р°РµС‚ GML-РґРІРѕР№РєРё 0.0/1.0, Р° РІ Lua 0.0 вЂ” РРЎРўРРќРђ. РџРѕСЌС‚РѕРјСѓ
-- `if not GM.actor_is_boss(...)` РЅРёРєРѕРіРґР° РЅРµ СЃСЂР°Р±Р°С‚С‹РІР°Р» Р±С‹, Рё Р±РѕРЅСѓСЃ Р»РµС‚РµР» Р±С‹ РїРѕ РІСЃРµРј РІСЂР°РіР°Рј.
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ С‚РёСЂ, С‚РµРі В«СѓСЂРѕРЅВ»
local item = Item.new("ElephantGun")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
local function is_boss(actor)
    return actor and Instance.exists(actor) and GM.actor_is_boss and truthy(GM.actor_is_boss(actor))
end

local function roll_bonus_crit(actor, bonus)
    if bonus <= 0 then return false end

    local base = actor.critical_chance or 0
    if base < 0 then base = 0 end
    if base >= 100 then return false end

    local missing = 100 - base
    if bonus >= missing then return true end
    return math.random() < (bonus / missing)
end

-- РљСЂРёС‚ РЅР°РґРѕ РґРѕРєРёРЅСѓС‚СЊ РґРѕ С„РёРЅР°Р»СЊРЅРѕРіРѕ СЂР°СЃС‡С‘С‚Р° СѓСЂРѕРЅР°: onHitProc СѓР¶Рµ РїРѕР·РґРЅРѕ РґР»СЏ С‡РёСЃР»Р°/Р·РІСѓРєР°.
pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        local hit_info = args[1] and Hit_Info.wrap(args[1].value)
        if not hit_info or not truthy(hit_info.proc) then return end

        local raw_victim = args[2] and args[2].value
        if not raw_victim then return end
        local victim = Instance.wrap(raw_victim)
        if not is_boss(victim) then return end

        local raw_actor = args[6] and args[6].value
        if not raw_actor then return end
        local actor = Instance.wrap(raw_actor)
        if not Instance.exists(actor) then return end

        local stack = actor:item_count(item)
        if stack <= 0 then return end

        local dmg = args[4] and args[4].value
        if not dmg or dmg <= 0 then return end

        if not truthy(hit_info.critical) and roll_bonus_crit(actor, BOSS_CRIT_PER_STACK * stack) then
            hit_info:set_critical(true)
            args[4].value = dmg * 2
        end
    end)
end)

-- РџСЂРё РїРѕРїР°РґР°РЅРёРё РїРѕ Р±РѕСЃСЃСѓ РґРѕР±Р°РІР»СЏРµРј РґРѕР»СЋ СѓСЂРѕРЅР° РѕС‚РґРµР»СЊРЅС‹Рј В«Р±РµР·РїСЂРѕРєРѕРІС‹РјВ» С…РёС‚РѕРј.
-- onHitProc (Р° РЅРµ onAttackHit) вЂ” СЃСЂР°Р±Р°С‚С‹РІР°РµС‚ С‚РѕР»СЊРєРѕ РЅР° РїСЂРѕРєРѕРІС‹С… Р°С‚Р°РєР°С…; Р±РѕРЅСѓСЃ-С…РёС‚ РЅРёР¶Рµ
-- РїРѕРјРµС‡РµРЅ proc=false, РїРѕСЌС‚РѕРјСѓ СЃР°Рј СЃРµР±СЏ РЅРµ РїСЂРѕРєР°РµС‚ (РёРЅР°С‡Рµ Р±РµСЃРєРѕРЅРµС‡РЅР°СЏ С†РµРїРѕС‡РєР°).
item:onHitProc(function(actor, victim, stack, hit_info)
    if not Net.host then return end
    if stack <= 0 then return end
    if not is_boss(victim) then return end

    local base = actor.damage or 0
    if base <= 0 then return end
    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    -- damage Сѓ fire_direct вЂ” СЌС‚Рѕ РљРћР­Р¤Р¤РР¦РР•РќРў (Г—actor.damage). Р§С‚РѕР±С‹ РґРѕР±Р°РІРёС‚СЊ СЂРѕРІРЅРѕ
    -- 15%/СЃС‚Р°Рє РѕС‚ С„Р°РєС‚РёС‡РµСЃРєРѕРіРѕ СѓСЂРѕРЅР° СЌС‚РѕРіРѕ РїРѕРїР°РґР°РЅРёСЏ, РїРµСЂРµРІРѕРґРёРј РїР»РѕСЃРєСѓСЋ РІРµР»РёС‡РёРЅСѓ РІ РєРѕСЌС„С„РёС†РёРµРЅС‚.
    local coef = (BOSS_DMG_PER_STACK * stack * dmg) / base
    actor:fire_direct(victim, coef, nil, nil, nil, nil, false)
end)
