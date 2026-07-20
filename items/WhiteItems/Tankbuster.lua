-- DeerItems-Tankbuster
-- Tankbuster: РЅРµ С‡Р°С‰Рµ СЂР°Р·Р° РІ 7 СЃРµРєСѓРЅРґ РїСЂРё РїРѕРїР°РґР°РЅРёРё РЅР°РЅРѕСЃРёС‚ С‚СЏР¶С‘Р»С‹Р№ РґРѕР±Р°РІРѕС‡РЅС‹Р№ СѓРґР°СЂ вЂ”
-- 40% (+20% Р·Р° СЃС‚Р°Рє) РѕС‚ СѓСЂРѕРЅР° РёРіСЂРѕРєР° РџР›Р®РЎ 2% (+1% Р·Р° СЃС‚Р°Рє) РѕС‚ РјР°РєСЃ. HP С†РµР»Рё.
-- (РђР»СЊС‚РµСЂРЅР°С‚РёРІР° Armor-Piercing Rounds: РІРјРµСЃС‚Рѕ В«С‚РѕР»СЊРєРѕ Р±РѕСЃСЃР°РјВ» вЂ” Р°РЅС‚Рё-С‚Р°РЅРєРѕРІС‹Р№ СѓРґР°СЂ РїРѕ Р»СЋР±РѕРјСѓ Р¶РёСЂРЅРѕРјСѓ.)

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° (Р±РµР· РїР°СЂС‚РёРєР»РѕРІ Рё Р·РІСѓРєР° РїРѕ РўР—)
local sprite = Sprite.new("item/Tankbuster", PATH.."assets/sprites/items/sWhiteItems/Tankbuster.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- Р‘Р°Р»Р°РЅСЃРЅС‹Рµ РєРѕРЅСЃС‚Р°РЅС‚С‹
local COOLDOWN_FRAMES  = 5 * 60   -- РїРµСЂРµР·Р°СЂСЏРґРєР° 5 СЃРµРєСѓРЅРґ
local PLAYER_DMG_BASE  = 1.00     -- 100% СѓСЂРѕРЅР° РёРіСЂРѕРєР°
local PLAYER_DMG_STACK = 0.70     -- +70% Р·Р° СЃС‚Р°Рє
local MAXHP_BASE       = 0.04     -- 4% РјР°РєСЃ. HP С†РµР»Рё
local MAXHP_STACK      = 0.02     -- +2% Р·Р° СЃС‚Р°Рє

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ С‚РёСЂ, С‚РµРі В«СѓСЂРѕРЅВ»
local item = Item.new("Tankbuster")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end
    if stack <= 0 then return end

    -- Р’РЅСѓС‚СЂРµРЅРЅРёР№ РєСѓР»РґР°СѓРЅ 7 СЃРµРєСѓРЅРґ (РЅР° РёРіСЂРѕРєР°)
    local data = actor:get_data("Tankbuster", GUID)
    local now = Global._current_frame
    if (now - (data.tb_last or -COOLDOWN_FRAMES)) < COOLDOWN_FRAMES then return end

    local base = actor.damage or 0
    if base <= 0 then return end
    local target_maxhp = victim.maxhp or 0

    -- РџР»РѕСЃРєРёР№ РґРѕР±Р°РІРѕС‡РЅС‹Р№ СѓСЂРѕРЅ = РґРѕР»СЏ СѓСЂРѕРЅР° РёРіСЂРѕРєР° + РґРѕР»СЏ РјР°РєСЃ. HP С†РµР»Рё
    local flat = base * (PLAYER_DMG_BASE + PLAYER_DMG_STACK * (stack - 1))
               + target_maxhp * (MAXHP_BASE + MAXHP_STACK * (stack - 1))
    -- РџРµСЂРµРІРѕРґРёРј РїР»РѕСЃРєСѓСЋ РІРµР»РёС‡РёРЅСѓ РІ РєРѕСЌС„С„РёС†РёРµРЅС‚ fire_direct (Г—actor.damage)
    local coef = flat / base
    actor:fire_direct(victim, coef, nil, nil, nil, nil, false)

    data.tb_last = now
end)
