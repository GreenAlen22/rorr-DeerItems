-- DeerItems-RadialAlloy
-- РџСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓСЂРѕРЅР° РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ РґРѕ 12 HP Р·Р° СЃС‚Р°Рє, РЅРѕ РЅРµ Р±РѕР»РµРµ (СѓСЂРѕРЅ - 5).

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
local sprite = Sprite.new("item/RadialAlloy", PATH.."assets/sprites/items/sGreenItems/RadialAlloy.png", 1, 16, 16)

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° RadialAlloy
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р·РµР»С‘РЅС‹Р№ (РЅРµРѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, РїРѕРІС‹С€Р°СЋС‰РёР№ Р¶РёРІСѓС‡РµСЃС‚СЊ
local item = Item.new("RadialAlloy")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- РџСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓСЂРѕРЅР°: Р»РµС‡РёРј С‡Р°СЃС‚СЊ РѕР±СЂР°С‚РЅРѕ
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if Net.client then return end

    if stack <= 0 then return end

    -- РР·РІР»РµРєР°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ РїРѕР»СѓС‡РµРЅРЅРѕРіРѕ СѓСЂРѕРЅР°
    local dmg = hit_info and (hit_info.damage or (hit_info.get_damage and hit_info:get_damage())) or 0
    if dmg <= 0 then return end

    -- РЎРєРѕР»СЊРєРѕ РјРѕР¶РЅРѕ РІРѕСЃСЃС‚Р°РЅРѕРІРёС‚СЊ: РјР°РєСЃРёРјСѓРј (СѓСЂРѕРЅ - 5), РЅРµ Р±РѕР»РµРµ Р»РёРјРёС‚Р° РѕС‚ СЃС‚Р°РєРѕРІ
    local reduction = 12 * stack
    local can_reduce = math.max(0, dmg - 5)
    local heal_back = math.min(reduction, can_reduce)

    -- Р›РµС‡РµРЅРёРµ, РµСЃР»Рё РµСЃС‚СЊ С‡С‚Рѕ РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°С‚СЊ
    if heal_back > 0 then
        actor:heal(heal_back)
    end
end)
