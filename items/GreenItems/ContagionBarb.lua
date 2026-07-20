-- DeerItems-ContagionBarb / В«Р–Р°Р»Рѕ Р·Р°СЂР°Р·С‹В» / "Contagion Barb"
-- РЁР°РЅСЃ РїСЂРё РїРѕРїР°РґР°РЅРёРё РЅР°Р»РѕР¶РёС‚СЊ РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ. РџСЂРё СѓР±РёР№СЃС‚РІРµ РєСЂРѕРІРѕС‚РѕС‡Р°С‰РµРіРѕ РІСЂР°РіР° РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ
-- СЂР°СЃРїСЂРѕСЃС‚СЂР°РЅСЏРµС‚СЃСЏ РЅР° Р±Р»РёР¶Р°Р№С€РёС… РІСЂР°РіРѕРІ.
-- (РЈСЂРѕРЅ РєСЂРѕРІРѕС‚РµС‡РµРЅРёСЏ РІРµРґС‘Рј СЃРїРёСЃРєРѕРј Сѓ РёРіСЂРѕРєР°, РєР°Рє В«СЃРѕР»РЅС†Р°В» ShineOSun: С‚Р°Рє РѕРЅ СЃРєРµР№Р»РёС‚СЃСЏ Рё
--  Р·Р°СЃС‡РёС‚С‹РІР°РµС‚СЃСЏ РёРіСЂРѕРєСѓ; СЃР°Рј Р±Р°С„С„ вЂ” Р»РёС€СЊ РІРёР·СѓР°Р»СЊРЅР°СЏ РјРµС‚РєР°-РґРµР±Р°С„С„.)

local sprite      = Sprite.new("item/ContagionBarb", PATH.."assets/sprites/items/sGreenItems/ContagionBarb.png", 1, 18, 18)
local buff_sprite = Sprite.new("buff/ContagionBleed", PATH.."assets/sprites/buffs/ContagionBarb.png", 1, 7.5, 7.5)

local GUID = _ENV["!guid"]

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local CHANCE_BASE  = 0.08
local CHANCE_STACK = 0.08
local BLEED_TIME   = 4 * 60     -- РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ 4СЃ
local BLEED_TICK   = 30         -- СѓСЂРѕРЅ СЂР°Р· РІ 0.5СЃ
local BLEED_TOTAL  = 90       -- 90% СѓСЂРѕРЅР°, РЅР°Р»РѕР¶РёРІС€РµРіРѕ Р±РѕР»РµР·РЅСЊ
local BLEED_TICKS  = BLEED_TIME / BLEED_TICK
local SPREAD_BASE  = 1          -- С†РµР»РµР№ СЂР°СЃРїСЂРѕСЃС‚СЂР°РЅРµРЅРёСЏ РїСЂРё 1 С€С‚.
local SPREAD_RAD   = 200

-- Р”РµР±Р°С„С„-РјРµС‚РєР° РєСЂРѕРІРѕС‚РµС‡РµРЅРёСЏ (РёРєРѕРЅРєР°; СѓСЂРѕРЅ РІРµРґС‘С‚ СЃРїРёСЃРѕРє Сѓ РёРіСЂРѕРєР°)
local bleed = Buff.new("ContagionBleed")
bleed.icon_sprite = buff_sprite
bleed.icon_stack_subimage = false
bleed.draw_stack_number = false
bleed.is_debuff = true
bleed.is_timed  = true
local item = Item.new("ContagionBarb")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- Р—Р°РІРµСЃС‚Рё/РѕР±РЅРѕРІРёС‚СЊ РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ РЅР° С†РµР»Рё
local function apply_bleed(actor, victim, source_damage)
    if not (victim and Instance.exists(victim)) then return end
    if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return end
    if not source_damage or source_damage <= 0 then return end
    victim:buff_apply(bleed, BLEED_TIME)
    local data = actor:get_data("ContagionBarb", GUID)
    if not data.bleeds then data.bleeds = {} end
    data.bleeds[victim.id] = {
        inst = victim,
        t = BLEED_TIME,
        tick = BLEED_TICK,
        tick_damage = source_damage * BLEED_TOTAL / BLEED_TICKS,
        source_damage = source_damage,
    }
end

-- РџСЂРё РїРѕРїР°РґР°РЅРёРё: С€Р°РЅСЃ РЅР°Р»РѕР¶РёС‚СЊ РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end
    if math.random() <= (CHANCE_BASE + CHANCE_STACK * (stack - 1)) then
        apply_bleed(actor, victim, hit_info and hit_info.damage)
    end
end)

-- РўРёРє РєСЂРѕРІРѕС‚РµС‡РµРЅРёСЏ РѕС‚ Р»РёС†Р° РёРіСЂРѕРєР° (СѓСЂРѕРЅ СЃРєРµР№Р»РёС‚СЃСЏ Рё Р·Р°СЃС‡РёС‚С‹РІР°РµС‚СЃСЏ РёРіСЂРѕРєСѓ)
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if Net.client then return end
    local data = actor:get_data("ContagionBarb", GUID)
    if not data.bleeds then return end
    for id, b in pairs(data.bleeds) do
        b.t = b.t - 1
        b.tick = b.tick - 1
        local v = b.inst
        if not (v and Instance.exists(v)) or b.t <= 0 then
            data.bleeds[id] = nil
        elseif b.tick <= 0 then
            b.tick = BLEED_TICK
            -- 8 С‚РёРєРѕРІ РїРѕ 15% РґР°СЋС‚ СЂРѕРІРЅРѕ 120% РѕС‚ СѓСЂРѕРЅР°, РЅР°Р»РѕР¶РёРІС€РµРіРѕ Р±РѕР»РµР·РЅСЊ.
            local base_damage = math.max(actor.damage or 0, 1)
            local hit = actor:fire_direct(v, b.tick_damage / base_damage, nil, nil, nil, nil, false)
            if hit and hit.attack_info then
                hit.attack_info:use_raw_damage()
                hit.attack_info:set_damage(b.tick_damage)
                hit.attack_info.proc = false
                hit.attack_info:set_critical(false)
            end
        end
    end
end)

-- РџСЂРё СѓР±РёР№СЃС‚РІРµ РєСЂРѕРІРѕС‚РѕС‡Р°С‰РµРіРѕ РІСЂР°РіР°: СЂР°СЃРїСЂРѕСЃС‚СЂР°РЅСЏРµРј РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ РЅР° Р±Р»РёР¶Р°Р№С€РёС…
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if not Net.host then return end
    if not (victim and Instance.exists(victim)) then return end
    local data = actor:get_data("ContagionBarb", GUID)
    if not (data.bleeds and data.bleeds[victim.id]) then return end
    local source_damage = data.bleeds[victim.id].source_damage
    data.bleeds[victim.id] = nil

    local targets = SPREAD_BASE + (stack - 1)
    local enemy_team = actor.team == 1 and 2 or 1
    local found = List.wrap(actor:find_characters_circle(victim.x, victim.y, SPREAD_RAD + 32 * (stack - 1), false, enemy_team, true))
    local picked = 0
    for _, e in ipairs(found) do
        if picked >= targets then break end
        if Instance.exists(e) and e.id ~= victim.id then
            apply_bleed(actor, e, source_damage)
            picked = picked + 1
        end
    end
end)
