-- DeerItems-ShadowShield
-- Р”Р°С‘С‚ Р±Р°С„С„ РІ РЅР°С‡Р°Р»Рµ СЌС‚Р°РїР°: СѓРІРµР»РёС‡РёРІР°РµС‚ Р±СЂРѕРЅСЋ Рё СЃРєРѕСЂРѕСЃС‚СЊ, РЅРѕ РёСЃС‡РµР·Р°РµС‚ РїСЂРё Р°С‚Р°РєРµ. Р”Р»РёС‚РµР»СЊРЅРѕСЃС‚СЊ вЂ” 20 + 10 СЃРµРє Р·Р° СЃС‚Р°Рє.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ Р±Р°С„С„Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
local sprite = Sprite.new("item/ShadowShield", PATH.."assets/sprites/items/sGreenItems/ShadowShield.png", 1, 16, 16)
local buff_sprite = Sprite.new("buff/ShadowShield", PATH.."assets/sprites/buffs/ShadowShield.png", 1, 7.5, 7.5)
local sound = Sound.new("sound/ShadowShield", PATH.."assets/sounds/ShadowShield.ogg")
local SHADOW_ALPHA = 0.85

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° Рё Р±Р°С„С„Р° ShadowShield
local item = Item.new("ShadowShield")
local buff = Buff.new("ShadowShield")

-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р·РµР»С‘РЅС‹Р№ (РЅРµРѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: СѓС‚РёР»РёС‚Р°СЂРЅС‹Р№ РїСЂРµРґРјРµС‚
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Р’ РЅР°С‡Р°Р»Рµ СЌС‚Р°РїР° РґР°С‘С‚ РІСЂРµРјРµРЅРЅС‹Р№ Р±Р°С„С„
DeerItemsCallbacks.item_stage_start(item, function(actor, stack)
    if Net.client then return end

    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
    -- Р”Р»РёС‚РµР»СЊРЅРѕСЃС‚СЊ: 20 + 10 СЃРµРє Р·Р° СЃС‚Р°Рє
    actor:buff_apply(buff, 60 * (20 + 10 * stack), stack)
end)

-- РџСЂРё СѓРґР°СЂРµ Р±Р°С„С„ РёСЃС‡РµР·Р°РµС‚ РїРѕР»РЅРѕСЃС‚СЊСЋ
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if Net.client then return end

    if actor:buff_count(buff) >= 1 then
        actor:buff_remove(buff, stack)
    end
end)

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°С„С„Р°
buff.icon_sprite = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = false
buff.show_icon = true
buff.is_debuff = false
buff.max_stack = 9999
local function draw_shadow(actor)
    gm.draw_sprite_ext(
        actor.sprite_index,
        actor.image_index,
        actor.x,
        actor.y,
        actor.image_xscale,
        actor.image_yscale,
        actor.image_angle,
        Color.BLACK,
        SHADOW_ALPHA
    )

    if actor.actor_state_current_id ~= -1
    and not actor:actor_state_is_climb_state(actor.actor_state_current_id)
    and actor.sprite_index2 then
        gm.draw_sprite_ext(
            actor.sprite_index2,
            actor.image_index,
            actor.x,
            actor.y,
            actor.image_xscale,
            actor.image_yscale,
            actor.image_angle,
            Color.BLACK,
            SHADOW_ALPHA
        )
    end
end

-- РћС‡РёСЃС‚РєР° РІСЃРµС… СЃС‚Р°СЂС‹С… РєРѕР»Р»Р±РµРєРѕРІ
DeerItemsCallbacks.buff_post_draw(buff, function(actor, stack)
    draw_shadow(actor)
end)

-- Р­С„С„РµРєС‚С‹ Р±Р°С„С„Р°: СЃРєРѕСЂРѕСЃС‚СЊ Рё Р±СЂРѕРЅСЏ
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack)
    -- РЈРІРµР»РёС‡РµРЅРёРµ СЃРєРѕСЂРѕСЃС‚Рё РїРµСЂРµРґРІРёР¶РµРЅРёСЏ
    actor.pHmax = actor.pHmax + (0.28 + 0.27 * stack)
    -- РЈРІРµР»РёС‡РµРЅРёРµ Р±СЂРѕРЅРё
    actor.armor = actor.armor + (40 + 20 * stack)
end)
