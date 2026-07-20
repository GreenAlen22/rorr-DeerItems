-- DeerItems-UnfocusPrisma
-- РЈРІРµР»РёС‡РёРІР°РµС‚ СѓСЂРѕРЅ РїРѕ РІСЂР°РіР°Рј РЅР° СЂР°СЃСЃС‚РѕСЏРЅРёРё Р±РѕР»РµРµ 8 РјРµС‚СЂРѕРІ РЅР° 25% (+25% Р·Р° СЃС‚Р°Рє).

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
local sprite = Sprite.new("item/UnfocusPrisma", PATH.."assets/sprites/items/sWhiteItems/UnfocusPrisma.png", 1, 16, 16)

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° UnfocusPrisma
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ
local item = Item.new("UnfocusPrisma")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- РџРѕСЂРѕРі РґР°Р»СЊРЅРѕСЃС‚Рё, СЃ РєРѕС‚РѕСЂРѕРіРѕ РЅР°С‡РёРЅР°РµС‚ РґРµР№СЃС‚РІРѕРІР°С‚СЊ Р±РѕРЅСѓСЃ: 8 РјРµС‚СЂРѕРІ (1 РјРµС‚СЂ = 32 РїРёРєСЃРµР»СЏ)
local RANGE = 8 * 32
local PRISM_COLOR = Color(0x8ee7ff)
local PRISM_SIDES = 6

local function draw_prism_boundary(actor)
    local phase = (Global._current_frame or 0) / 180

    gm.draw_set_alpha(0.55)
    gm.draw_set_colour(PRISM_COLOR)
    for ring = 0, 1 do
        local radius = RANGE - ring * 4
        local offset = phase * (ring == 0 and 1 or -1)
        for i = 0, PRISM_SIDES - 1 do
            local a1 = offset + math.pi * 2 * i / PRISM_SIDES
            local a2 = offset + math.pi * 2 * (i + 1) / PRISM_SIDES
            gm.draw_line(
                actor.x + math.cos(a1) * radius,
                actor.y + math.sin(a1) * radius,
                actor.x + math.cos(a2) * radius,
                actor.y + math.sin(a2) * radius
            )
        end
    end

    gm.draw_set_alpha(0.3)
    for i = 0, PRISM_SIDES - 1 do
        local angle = phase + math.pi * 2 * i / PRISM_SIDES
        local inner = RANGE - 24
        gm.draw_line(
            actor.x + math.cos(angle) * inner,
            actor.y + math.sin(angle) * inner,
            actor.x + math.cos(angle) * RANGE,
            actor.y + math.sin(angle) * RANGE
        )
    end
    gm.draw_set_colour(Color.WHITE)
    gm.draw_set_alpha(1)
end

-- РџСЂРё РїРѕРїР°РґР°РЅРёРё: РµСЃР»Рё С†РµР»СЊ РґР°Р»СЊС€Рµ 8 РјРµС‚СЂРѕРІ вЂ” СѓСЃРёР»РёРІР°РµРј СѓСЂРѕРЅ РїРѕ РЅРµР№
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end

    if stack <= 0 then return end
    if not hit_info or not hit_info.damage or hit_info.damage <= 0 then return end
    if not Instance.exists(victim) then return end

    -- Р”РёСЃС‚Р°РЅС†РёСЏ РјРµР¶РґСѓ РёРіСЂРѕРєРѕРј Рё С†РµР»СЊСЋ
    local dx = victim.x - actor.x
    local dy = victim.y - actor.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Р‘РѕРЅСѓСЃ С‚РѕР»СЊРєРѕ РїРѕ РґР°Р»СЊРЅРёРј С†РµР»СЏРј: +40% СѓСЂРѕРЅР° Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє
    if dist > RANGE then
        local mult = 1 + 0.40 * stack
        hit_info:set_damage(hit_info.damage * mult)
    end
end)

-- Р“СЂР°РЅС‘РЅР°СЏ РіСЂР°РЅРёС†Р° РѕС‚РјРµС‡Р°РµС‚ Р·РѕРЅСѓ, РІ РєРѕС‚РѕСЂРѕР№ Р±РѕРЅСѓСЃ Рє РґР°Р»СЊРЅРµРјСѓ СѓСЂРѕРЅСѓ РЅРµ РґРµР№СЃС‚РІСѓРµС‚.
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    if stack <= 0 then return end
    draw_prism_boundary(actor)
end)
