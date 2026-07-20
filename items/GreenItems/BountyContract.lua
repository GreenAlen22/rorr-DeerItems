-- DeerItems-BountyContract / В«РљРѕРЅС‚СЂР°РєС‚ РЅР° РѕС‚СЃС‚СЂРµР»В» / "Bounty Contract"
-- РќР°РіСЂР°РґР° Р·Р° РіРѕР»РѕРІС‹ СЌР»РёС‚:
--   (a) Р”РѕР±РёРІР°РЅРёРµ: СЌР»РёС‚Р° (РЅРµ Р±РѕСЃСЃ) СЃ HP РЅРёР¶Рµ РїРѕСЂРѕРіР° РјРіРЅРѕРІРµРЅРЅРѕ РєР°Р·РЅРёС‚СЃСЏ.
--   (b) Р”РµРЅСЊРіРё РґР°СЋС‚ РўРћР›Р¬РљРћ СѓР±РёР№СЃС‚РІР° СЌР»РёС‚. РћР±С‹С‡РЅС‹Рµ СѓР±РёР№СЃС‚РІР° Р·РѕР»РѕС‚Р° РќР• РїСЂРёРЅРѕСЃСЏС‚.

local sprite = Sprite.new("item/BountyContract", PATH.."assets/sprites/items/sGreenItems/BountyContract.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local THRESH_STACK = 0.12   -- РіРёРїРµСЂР±РѕР»РёС‡РµСЃРєРёР№ РІРєР»Р°Рґ РєР°Р¶РґРѕРіРѕ СЃС‚Р°РєР° РІ РїРѕСЂРѕРі РєР°Р·РЅРё
local GOLD_BASE    = 15     -- Р·РѕР»РѕС‚Рѕ Р·Р° СѓР±РёР№СЃС‚РІРѕ СЌР»РёС‚С‹ (Г—РјРЅРѕР¶РёС‚РµР»СЊ С†РµРЅ)
local GOLD_STACK   = 15     -- +20 Р·Р° С€С‚.

local function diminishing_fraction(per_stack, stack)
    if stack <= 0 then return 0 end
    return 1 - 1 / (per_stack * stack + 1)
end

-- Р‘РµР·РѕРїР°СЃРЅРѕРµ РїСЂРёРІРµРґРµРЅРёРµ Р·РЅР°С‡РµРЅРёСЏ GML-С„СѓРЅРєС†РёРё (true / 1.0 / 0.0) Рє Р±СѓР»РµРІСѓ.
-- Р’Р°Р¶РЅРѕ: GM.* РІРѕР·РІСЂР°С‰Р°РµС‚ double, Рё 0.0 РІ Lua РРЎРўРРќРќРћ, РїРѕСЌС‚РѕРјСѓ Р±РµР· РѕР±С‘СЂС‚РєРё С„РёР»СЊС‚СЂ РЅРµ СЂР°Р±РѕС‚Р°РµС‚.
local function truthy(v) return v ~= nil and v ~= false and v ~= 0 end

local item = Item.new("BountyContract")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- РЇРІР»СЏРµС‚СЃСЏ Р»Рё Р¶РµСЂС‚РІР° СЌР»РёС‚РѕР№ (Р°РєС‚С‘СЂ + СЌР»РёС‚РЅС‹Р№ С„Р»Р°Рі). Р‘РѕСЃСЃР° РґРѕР±РёРІР°С‚СЊ РЅРµР»СЊР·СЏ (СЃРј. РЅРёР¶Рµ),
-- РЅРѕ РµСЃР»Рё Р±РѕСЃСЃ РµС‰С‘ Рё СЌР»РёС‚Р° вЂ” РѕРЅ РµСЃС‚РµСЃС‚РІРµРЅРЅРѕ РїРѕРїР°РґС‘С‚ РїРѕРґ РЅР°РіСЂР°РґСѓ Р·Р° СЌР»РёС‚.
local function is_elite(victim)
    if not (victim and Instance.exists(victim)) then return false end
    if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return false end
    return GM.actor_is_elite and truthy(GM.actor_is_elite(victim))
end

-- Р­Р»РёС‚С‹, Р·Р° РєРѕС‚РѕСЂС‹С… Р·РѕР»РѕС‚Рѕ СѓР¶Рµ РІС‹РґР°РЅРѕ (victim.id в†’ true). Р—Р°С‰РёС‰Р°РµС‚ РѕС‚ РґРІРѕР№РЅРѕР№ РІС‹РїР»Р°С‚С‹,
-- РµСЃР»Рё РґРѕР±РёС‚Р°СЏ СЌР»РёС‚Р° РµС‰С‘ Рё РІС‹Р·РѕРІРµС‚ onKillProc. РЎР±СЂР°СЃС‹РІР°РµС‚СЃСЏ РЅР° СЃС‚Р°СЂС‚Рµ СЌС‚Р°РїР°.
local paid = {}

-- Р—РѕР»РѕС‚Рѕ РїРёС€РµРј С‚РѕР»СЊРєРѕ Р›РћРљРђР›Р¬РќРћРњРЈ РёРіСЂРѕРєСѓ (HUD-Р·РѕР»РѕС‚Рѕ РєР»РёРµРЅС‚СЃРєРѕРµ), РјР°СЃС€С‚Р°Р± РїРѕ РІСЂРµРјРµРЅРё.
-- paid[id] РіР°СЂР°РЅС‚РёСЂСѓРµС‚ РѕРґРЅСѓ РІС‹РїР»Р°С‚Сѓ РЅР° СЌР»РёС‚Сѓ РЅРµР·Р°РІРёСЃРёРјРѕ РѕС‚ С‚РѕРіРѕ, РєР°РєРѕР№ РєРѕР»Р»Р±РµРє СЃСЂР°Р±РѕС‚Р°Р».
local function reward(actor, victim, stack)
    if not (victim and victim.id) then return end
    if paid[victim.id] then return end
    paid[victim.id] = true
    if not actor:same(Player.get_client()) then return end
    local hud = GM._mod_game_getHUD()
    if hud and hud ~= -4 then
        hud.gold = hud.gold + (GOLD_BASE + GOLD_STACK * (stack - 1)) * gm.cost_get_base_gold_price_scale()
    end
end

-- (a) Р”РѕР±РёРІР°РЅРёРµ СЌР»РёС‚ РїРѕ РїРѕСЂРѕРіСѓ HP (РЅР° С…РѕСЃС‚Рµ вЂ” РѕРЅ РІР»Р°РґРµРµС‚ HP РІСЂР°РіРѕРІ).
-- РќР°РіСЂР°РґСѓ РІС‹РґР°С‘Рј РџР РЇРњРћ Р·РґРµСЃСЊ (РјС‹ Р·РЅР°РµРј, С‡С‚Рѕ СЌС‚Рѕ СѓР±РёР№СЃС‚РІРѕ), РЅРµ РїРѕР»Р°РіР°СЏСЃСЊ РЅР° onKillProc РїРѕСЃР»Рµ
-- РїСЂСЏРјРѕР№ Р·Р°РїРёСЃРё HP. Р‘РѕСЃСЃР° РЅРµ РґРѕР±РёРІР°РµРј.
item:onHitProc(function(actor, victim, stack, hit_info)
    if not Net.host then return end
    if not is_elite(victim) then return end
    if GM.actor_is_boss and truthy(GM.actor_is_boss(victim)) then return end
    if not (victim.maxhp and victim.maxhp > 0) then return end
    if paid[victim.id] then return end

    local thresh = diminishing_fraction(THRESH_STACK, stack)
    if (victim.hp / victim.maxhp) < thresh then
        reward(actor, victim, stack)   -- РЅР°РіСЂР°РґР° Р·Р° РґРѕР±РёРІР°РЅРёРµ
        victim.hp = -1000000           -- РјРіРЅРѕРІРµРЅРЅР°СЏ РєР°Р·РЅСЊ
    end
end)

-- (b) РќР°РіСЂР°РґР° Р·Р° РѕР±С‹С‡РЅРѕРµ СѓР±РёР№СЃС‚РІРѕ СЌР»РёС‚С‹ (Р±РѕР»СЊС€РёРј СѓРґР°СЂРѕРј, Р±РµР· РґРѕР±РёРІР°РЅРёСЏ).
-- paid[id] РЅРµ РґР°СЃС‚ Р·Р°РїР»Р°С‚РёС‚СЊ РґРІР°Р¶РґС‹ Р·Р° СѓР¶Рµ РґРѕР±РёС‚СѓСЋ СЌР»РёС‚Сѓ.
item:onKillProc(function(actor, victim, stack)
    if not is_elite(victim) then return end
    reward(actor, victim, stack)
end)

-- РЎР±СЂРѕСЃ РјРµС‚РѕРє РЅР° РЅРѕРІРѕРј СЌС‚Р°РїРµ
Callback.add(Callback.ON_STAGE_START, function(...)
    paid = {}
end)
