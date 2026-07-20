-- DeerItems-FearEyes
-- РЈРІРµР»РёС‡РµРІР°РµС‚ СѓСЂРѕРЅ РёРіСЂРѕРєР° Р·Р° СЃС‚Р°Рє. РџСЂРё РґРѕСЃС‚РёР¶РµРЅРёРё 40% HP РїСЂРµРІСЂР°С‰Р°РµС‚СЃСЏ РІ СЃР»РѕРјР°РЅРЅС‹Рµ СЃС‚Р°РєРё.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ СЌС„С„РµРєС‚Р°
local sprite = Sprite.new("item/FearEyes", PATH.."assets/sprites/items/sWhiteItems/FearEyes.png", 1, 16, 16)
local sound = Sound.new("sound/FearEyes", PATH.."assets/sounds/FearEyes.ogg")
local spike = Sprite.new("particle/Spike", PATH.."assets/sprites/particle/Spike.png", 1, 20, 15)

-- Р»РµРЅРёРІС‹Р№ РєСЌС€ СЃСЃС‹Р»РєРё РЅР° СЃР»РѕРјР°РЅРЅСѓСЋ РІРµСЂСЃРёСЋ (РЅР° Р·Р°РіСЂСѓР·РєРµ РјРѕР¶РµС‚ Р±С‹С‚СЊ РµС‰С‘ РЅРµ Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°РЅР°)
local deactivate

-- РЎРѕР·РґР°РЅРёРµ РЅРѕРІРѕРіРѕ РїСЂРµРґРјРµС‚Р° СЃ РЅР°Р·РІР°РЅРёРµРј "FearEyes" РІ РєР°С‚РµРіРѕСЂРёРё "DeerItems"
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ (РѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ
local item = Item.new("FearEyes")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- РћР±СЂР°Р±РѕС‚РєР° РїРµСЂРµСЃС‡С‘С‚Р° СЃС‚Р°С‚РёСЃС‚РёРєРё: РІСЂРµРјРµРЅРЅС‹Р№ Р±РѕРЅСѓСЃ Рє СѓСЂРѕРЅСѓ, Р·Р°РІРёСЃРёС‚ РѕС‚ СЃСѓРјРјР°СЂРЅС‹С… СЃС‚Р°РєРѕРІ
if item.onStatRecalc then
    item:onStatRecalc(function(actor, stack)
        local normal = actor:item_count(item, Item.StackKind.NORMAL)
        local temp   = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
        local stacks = normal + temp
        if stacks > 0 then
            actor.damage = actor.damage + (5 + 10 * stacks)
        end
    end)
end

-- РџСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓСЂРѕРЅР° Рё СЃРЅРёР¶РµРЅРёРё HP РґРѕ 40%: РїСЂРµРѕР±СЂР°Р·СѓРµС‚ СЃС‚Р°РєРё РІ СЃР»РѕРјР°РЅРЅС‹Рµ
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if Net.client then return end

    if actor.hp <= actor.maxhp * 0.40 then
        deactivate = deactivate or Item.find("FearEyesDeactivate", "DeerItems")
        local item_used = deactivate

        -- РџРµСЂРµРЅРѕСЃРёРј РѕР±С‹С‡РЅС‹Рµ СЃС‚Р°РєРё
        local normal = actor:item_count(item, Item.StackKind.NORMAL)
        if normal > 0 then
            actor:item_take(item, normal)
            actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
            actor:item_give(item_used, normal)
        end

        -- РџРµСЂРµРЅРѕСЃРёРј РІСЂРµРјРµРЅРЅС‹Рµ/СЃРёРЅРёРµ СЃС‚Р°РєРё
        local temp = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
        if temp > 0 then
            actor:item_take(item, temp, Item.StackKind.TEMPORARY_BLUE)
            actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
            actor:item_give(item_used, temp, Item.StackKind.TEMPORARY_BLUE)
        end
    end
end)

-- РћС‚РѕР±СЂР°Р¶РµРЅРёРµ СЌС„С„РµРєС‚Р° РїРѕРІРµСЂС… РїРµСЂСЃРѕРЅР°Р¶Р°
item:onPostDraw(function(actor, stack)
    gm.draw_sprite(spike, 0, actor.x, actor.y)
end)
