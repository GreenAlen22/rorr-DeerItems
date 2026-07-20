-- DeerItems-SporeOBloom
-- РџСЂРё СѓР±РёР№СЃС‚РІРµ СЃ С€Р°РЅСЃРѕРј 44% СЃРѕР·РґР°С‘С‚ СЏРґРѕРІРёС‚РѕРµ РѕР±Р»Р°РєРѕ, РЅР°РЅРѕСЃСЏС‰РµРµ СѓСЂРѕРЅ РѕС‚ СЃРёР»С‹ СѓР±РёР№С†С‹.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
local sprite = Sprite.new("item/SporeOBloom", PATH.."assets/sprites/items/sWhiteItems/SporeOBloom.png", 1, 16.5, 18)

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° SporeOBloom
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ (РѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ
local item = Item.new("SporeOBloom")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- РћС‡РёСЃС‚РєР° СЃС‚Р°СЂС‹С… РєРѕР»Р»Р±РµРєРѕРІ
-- РџСЂРё СѓР±РёР№СЃС‚РІРµ РІСЂР°РіР° СЃСЂР°Р±Р°С‚С‹РІР°РµС‚ С€Р°РЅСЃ РЅР° СЃРѕР·РґР°РЅРёРµ РѕР±Р»Р°РєР°
DeerItemsCallbacks.item_kill_proc(item, function(killer, victim, stack)
    if not Net.host then return end

    if math.random() < 0.44 then
        -- РЎРѕР·РґР°С‘Рј СЏРґРѕРІРёС‚РѕРµ РѕР±Р»Р°РєРѕ С‡СѓС‚СЊ РІС‹С€Рµ С‚СЂСѓРїР°
        local cloud = GM.instance_create(victim.x, victim.y - 20, gm.constants.oMushDust)
        -- РЈРєР°Р·С‹РІР°РµРј РІР»Р°РґРµР»СЊС†Р° Рё РєРѕРјР°РЅРґСѓ РґР»СЏ РєРѕСЂСЂРµРєС‚РЅРѕР№ СЂР°Р±РѕС‚С‹
        cloud.parent = killer
        cloud.team = killer.team
        -- РЈСЂРѕРЅ Р·Р°РІРёСЃРёС‚ РѕС‚ СѓСЂРѕРЅР° СѓР±РёР№С†С‹(РёРіСЂРѕРєР°) Рё РєРѕР»РёС‡РµСЃС‚РІР° СЃС‚Р°РєРѕРІ (60% РЅР° СЃС‚Р°Рє)
        cloud.damage = killer.damage * (0.6 * stack)
        -- РћР±Р»Р°РєРѕ СЃСѓС‰РµСЃС‚РІСѓРµС‚ 5 СЃРµРєСѓРЅРґ
        cloud:alarm_set(0, 60 * 5)
    end
end)
