-- DeerItems-RustMite / В«Р Р¶Р°РІС‹Р№ РєР»РµС‰В» / "Rust Mite"
-- РџРѕСЂС‚ Symbiotic Scorpion РёР· RoR2.
-- 100% РїСЂРё РїРѕРїР°РґР°РЅРёРё РІРµС€Р°РµС‚ В«СЂР¶Р°РІС‡РёРЅСѓВ» РЅР° С†РµР»СЊ (РЅР°РІСЃРµРіРґР°, СЃС‚Р°РєРё РЅРµ СЃРїР°РґР°СЋС‚).
-- РљР°Р¶РґС‹Р№ СЃС‚Р°Рє СЂР¶Р°РІС‡РёРЅС‹ СѓРІРµР»РёС‡РёРІР°РµС‚ Р’Р•РЎР¬ РїРѕР»СѓС‡Р°РµРјС‹Р№ С†РµР»СЊСЋ СѓСЂРѕРЅ РЅР° +4%.
--
-- РџРѕС‡РµРјСѓ РЅРµ В«РјРёРЅСѓСЃ Р±СЂРѕРЅСЏВ»: РІ RoRR РѕС‚СЂРёС†Р°С‚РµР»СЊРЅР°СЏ Р±СЂРѕРЅСЏ РќР• СѓСЃРёР»РёРІР°РµС‚ СѓСЂРѕРЅ (РґРІРёР¶РѕРє СЃС‡РёС‚Р°РµС‚
-- Р±СЂРѕРЅСЋ <= 0 РєР°Рє В«РЅРµС‚ СЃРЅРёР¶РµРЅРёСЏВ»), РїРѕСЌС‚РѕРјСѓ СѓРІРѕРґРёС‚СЊ РµС‘ РІ РјРёРЅСѓСЃ Р±РµСЃСЃРјС‹СЃР»РµРЅРЅРѕ. Р’РјРµСЃС‚Рѕ СЌС‚РѕРіРѕ
-- СѓСЃРёР»РёРІР°РµРј РёС‚РѕРіРѕРІС‹Р№ СѓСЂРѕРЅ РїРѕ С†РµР»Рё РЅР°РїСЂСЏРјСѓСЋ РІ С…СѓРєРµ СЂР°СЃС‡С‘С‚Р° СѓСЂРѕРЅР° (damager_calculate_damage) вЂ”
-- СЌС„С„РµРєС‚ РіР°СЂР°РЅС‚РёСЂРѕРІР°РЅ Рё СЂР°Р±РѕС‚Р°РµС‚ РѕС‚ Р›Р®Р‘РћР“Рћ РёСЃС‚РѕС‡РЅРёРєР° СѓСЂРѕРЅР°.

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° Рё РёРєРѕРЅРєР° РґРµР±Р°С„С„Р° (Р±РѕР»РІР°РЅРєРё РёР· template вЂ” Р·Р°РјРµРЅРё С‚РµРєСЃС‚СѓСЂС‹ РїРѕ СЌС‚РёРј РїСѓС‚СЏРј).
local sprite     = Sprite.new("item/RustMite", PATH.."assets/sprites/items/sRedItems/RustMite.png", 1, 18, 18)
local buffSprite = Sprite.new("buff/RustMite", PATH.."assets/sprites/buffs/RustMite.png", 1, 7, 7)

-- guid РјРѕРґР°: СѓСЃРєРѕСЂСЏРµС‚ get_data
local GUID = _ENV["!guid"]

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local DMG_PER_STACK = 0.04   -- +4% РїРѕР»СѓС‡Р°РµРјРѕРіРѕ СѓСЂРѕРЅР° Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє В«СЂР¶Р°РІС‡РёРЅС‹В»
local MAX_STACKS    = 100    -- С‚РµС…. РїСЂРµРґРµР» СЃС‚Р°РєРѕРІ РЅР° РћР”РќРЈ С†РµР»СЊ (РјР°РєСЃ +400% СѓСЂРѕРЅР°);
                             -- РІС‹СЃРѕРєРёР№, РЅР° РѕР±С‹С‡РЅРѕР№ РёРіСЂРµ РЅРµ РѕС‰СѓС‰Р°РµС‚СЃСЏ, Р»РѕРІРёС‚ С‚РѕР»СЊРєРѕ runaway.

-- Р”РµР±Р°С„С„ В«СЂР¶Р°РІС‡РёРЅР°В»: РїРѕСЃС‚РѕСЏРЅРЅС‹Р№, РіР»СѓР±РѕРєРѕ СЃС‚Р°РєР°СЋС‰РёР№СЃСЏ. РќРѕСЃРёС‚РµР»СЊ СЃС‚Р°РєРѕРІ + РёРєРѕРЅРєР°.
-- РЎР°Рј РїРѕ СЃРµР±Рµ СЃС‚Р°С‚С‹ РЅРµ С‚СЂРѕРіР°РµС‚ вЂ” СѓСЃРёР»РµРЅРёРµ СѓСЂРѕРЅР° РґРµР»Р°РµС‚ С…СѓРє РЅРёР¶Рµ.
local buff = Buff.new("RustMite")
buff.icon_sprite         = buffSprite
buff.icon_stack_subimage = false
buff.draw_stack_number   = true
buff.stack_number_col    = Array.new(1, Color(0xb5651d))   -- СЂР¶Р°РІРѕ-РѕСЂР°РЅР¶РµРІС‹Р№
buff.max_stack = 999
buff.is_timed  = false     -- СЃС‚Р°РєРё РќР• СЃРїР°РґР°СЋС‚ РїРѕ РІСЂРµРјРµРЅРё = В«РЅР°РІСЃРµРіРґР°В»
buff.is_debuff = true
-- РџСЂРµРґРјРµС‚
local item = Item.new("RustMite")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- РџСЂРё РїРѕРїР°РґР°РЅРёРё (100% С€Р°РЅСЃ): РІРµС€Р°РµРј С†РµР»Рё СЃС‚Р°РєРё СЂР¶Р°РІС‡РёРЅС‹ = С‡РёСЃР»Сѓ СЃС‚Р°РєРѕРІ РїСЂРµРґРјРµС‚Р°.
-- РљРѕР»Р»Р±СЌРє СѓСЂРѕРЅР° РќР• РЅР°РЅРѕСЃРёС‚ в†’ СЃР°РјРѕРїСЂРѕРє РЅРµРІРѕР·РјРѕР¶РµРЅ, proc=false РЅРµ РЅСѓР¶РµРЅ.
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    if not Net.host then return end           -- СЃС‚Р°РєРё РІРµС€Р°РµРј РЅР° С…РѕСЃС‚Рµ (СЃРёРЅРє РґРІРёР¶РєРѕРј)
    if not (victim and Instance.exists(victim)) then return end
    if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return end  -- С‚РѕР»СЊРєРѕ Р°РєС‚РѕСЂС‹

    local cur = victim:buff_count(buff)
    if cur >= MAX_STACKS then return end
    local add = math.min(stack, MAX_STACKS - cur)          -- +1 СЃС‚Р°Рє РЅР° РїРѕРїР°РґР°РЅРёРµ Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє РїСЂРµРґРјРµС‚Р°
    if add <= 0 then return end

    victim:buff_apply(buff, 1, add)
end)

-- РЈСЃРёР»РµРЅРёРµ РїРѕР»СѓС‡Р°РµРјРѕРіРѕ СѓСЂРѕРЅР°: РґРѕ СЂР°СЃС‡С‘С‚Р° СѓСЂРѕРЅР° РґРѕРјРЅРѕР¶Р°РµРј РІС…РѕРґСЏС‰РёР№ СѓСЂРѕРЅ РїРѕ С†РµР»Рё,
-- РµСЃР»Рё РЅР° РЅРµР№ РІРёСЃРёС‚ В«СЂР¶Р°РІС‡РёРЅР°В». Р‘СЊС‘С‚ РїРѕ РёС‚РѕРіСѓ РґР»СЏ Р›Р®Р‘РћР“Рћ РёСЃС‚РѕС‡РЅРёРєР° (РёРіСЂРѕРє, СЃРѕСЋР·РЅРёРєРё, СЌС„С„РµРєС‚С‹).
-- Р’ pcall: РµСЃР»Рё РІ СЌС‚РѕР№ РІРµСЂСЃРёРё С‚СѓР»РєРёС‚Р° РёРЅР°СЏ СЃРёРіРЅР°С‚СѓСЂР°/РёРјСЏ С„СѓРЅРєС†РёРё вЂ” С„РёС‡Р° РїСЂРѕСЃС‚Рѕ РІС‹РєР»СЋС‡РёС‚СЃСЏ.
pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        local v = args[2] and args[2].value
        if not v then return end
        v = Instance.wrap(v)
        if not Instance.exists(v) then return end
        -- buff_stack_count РµСЃС‚СЊ С‚РѕР»СЊРєРѕ Сѓ Р°РєС‚РѕСЂРѕРІ; РЅРµ-Р°РєС‚РѕСЂС‹ (Р±РѕС‡РєРё/СЏС‰РёРєРё) С‚РѕР¶Рµ РёРґСѓС‚ С‡РµСЂРµР· СЂР°СЃС‡С‘С‚ СѓСЂРѕРЅР°.
        if gm.object_is_ancestor(v.object_index, gm.constants.pActor) ~= 1.0 then return end

        local s = v:buff_count(buff)
        if not s or s <= 0 then return end
        if s > MAX_STACKS then s = MAX_STACKS end

        local dmg = args[4] and args[4].value
        if not dmg then return end
        args[4].value = dmg * (1 + DMG_PER_STACK * s)
    end)
end)
