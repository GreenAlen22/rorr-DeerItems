-- DeerItems-ShineOSun
-- РџСЂРё СѓР±РёР№СЃС‚РІРµ СЃ С€Р°РЅСЃРѕРј 22% СЃРѕР·РґР°С‘С‚ СЃРѕР»РЅС†Рµ, РєРѕС‚РѕСЂРѕРµ 5 СЃРµРєСѓРЅРґ Р±СЊС‘С‚ РІСЂР°РіРѕРІ РїРѕРґ СЃРѕР±РѕР№ AOE-СѓСЂРѕРЅРѕРј РѕС‚ max HP Р¶РµСЂС‚РІС‹.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ СЃРѕР»РЅС†Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
local sprite = Sprite.new("item/ShineOSun", PATH.."assets/sprites/items/sRedItems/ShineOSun.png", 1, 16.5, 18)
local sunSprite = Sprite.new("particle/sunSprite", PATH.."assets/sprites/particle/sun_sprite.png", 14, 128, 128)
local sound = Sound.new("ShineOSun", PATH.."assets/sounds/ShineOSun.ogg")

-- guid РјРѕРґР°: СѓСЃРєРѕСЂСЏРµС‚ get_data (Р±РµР· РѕР±С…РѕРґР° debug-СЃС‚РµРєР° РЅР° РєР°Р¶РґРѕРј РєР°РґСЂРµ)
local GUID = _ENV["!guid"]

-- РњР°РєСЃРёРјСѓРј СЃРѕР»РЅС† РЅР° РєР°СЂС‚Рµ РѕРґРЅРѕРІСЂРµРјРµРЅРЅРѕ (Сѓ РѕРґРЅРѕРіРѕ РІР»Р°РґРµР»СЊС†Р°)
local MAX_SUNS = 5
local SUN_Y_OFFSET = 6 * 32
local SUN_SPAWN_COOLDOWN = 5 * 60
-- Р¦РІРµС‚ РѕС‚СЂРёСЃРѕРІРєРё Р·РѕРЅС‹ РґРµР№СЃС‚РІРёСЏ СЃРѕР»РЅС†Р° вЂ” СЃРѕР·РґР°С‘С‚СЃСЏ РѕРґРёРЅ СЂР°Р·, Р° РЅРµ РєР°Р¶РґС‹Р№ РєР°РґСЂ
local SUN_COLOR = Color(0xffcc33)

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° ShineOSun
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: РєСЂР°СЃРЅС‹Р№ (Р»РµРіРµРЅРґР°СЂРЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, СѓСЃРёР»РёРІР°СЋС‰РёР№ СѓСЂРѕРЅ
local item = Item.new("ShineOSun")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- РџСЂРё СѓР±РёР№СЃС‚РІРµ СЃСЂР°Р±Р°С‚С‹РІР°РµС‚ С€Р°РЅСЃ 22% СЃРѕР·РґР°С‚СЊ "СЃРѕР»РЅС†Рµ" РЅР°Рґ РІСЂР°РіРѕРј
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if not Net.host then return end

    if math.random() < 0.22 then
        stack = stack or 1

        -- РџРѕР»СѓС‡РµРЅРёРµ Рё СЃРѕС…СЂР°РЅРµРЅРёРµ РґР°РЅРЅС‹С… Рѕ СЃРѕР»РЅС†Рµ
        local data = actor:get_data(nil, GUID)
        data.suns = data.suns or {}

        if (data.sun_spawn_cooldown or 0) > 0 then return end

        -- РћРіСЂР°РЅРёС‡РµРЅРёРµ: РЅРµ Р±РѕР»СЊС€Рµ MAX_SUNS СЃРѕР»РЅС† РЅР° РєР°СЂС‚Рµ РѕРґРЅРѕРІСЂРµРјРµРЅРЅРѕ
        if #data.suns >= MAX_SUNS then return end

        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)

        -- РЈСЂРѕРЅ: 5% РѕС‚ РјР°РєСЃРёРјР°Р»СЊРЅРѕРіРѕ HP СѓР±РёС‚РѕРіРѕ
        local dmg = victim.maxhp * 0.005

        -- Р Р°Р·РјРµСЂ Р·РѕРЅС‹ РґРµР№СЃС‚РІРёСЏ Р·Р°РІРёСЃРёС‚ РѕС‚ РєРѕР»РёС‡РµСЃС‚РІР° СЃС‚Р°РєРѕРІ
        local radius = (12 + 2.5 * (stack - 1)) * 32
        local sunRadius = radius + SUN_Y_OFFSET

        table.insert(data.suns, {
            x = victim.x,
            y = victim.y - SUN_Y_OFFSET, -- РІРёР·СѓР°Р»СЊРЅРѕ РІС‹С€Рµ РІСЂР°РіР° (4 РјРµС‚СЂР° РІРІРµСЂС…)
            dmg = dmg,
            w = sunRadius,
            h = sunRadius,
            t = 5 * 60,                  -- РѕР±С‰РµРµ РІСЂРµРјСЏ Р¶РёР·РЅРё (5 СЃРµРєСѓРЅРґ)
            tick = 12                    -- РёРЅС‚РµСЂРІР°Р» СѓСЂРѕРЅР°: 12 РєР°РґСЂРѕРІ
        })
        data.sun_spawn_cooldown = SUN_SPAWN_COOLDOWN
    end
end)

-- РћР±СЂР°Р±РѕС‚РєР° РєР°Р¶РґРѕРіРѕ Р°РєС‚РёРІРЅРѕРіРѕ СЃРѕР»РЅС†Р°: СѓСЂРѕРЅ РїРѕ РѕР±Р»Р°СЃС‚Рё РєР°Р¶РґС‹Рµ 12 РєР°РґСЂРѕРІ
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if not Net.host then return end

    local data = actor:get_data(nil, GUID)
    if (data.sun_spawn_cooldown or 0) > 0 then
        data.sun_spawn_cooldown = data.sun_spawn_cooldown - 1
    end

    if not data.suns then return end

    for i = #data.suns, 1, -1 do
        local s = data.suns[i]
        -- РћР±РЅРѕРІР»РµРЅРёРµ С‚Р°Р№РјРµСЂРѕРІ
        s.t = s.t - 1
        s.tick = s.tick - 1
        -- РљР°Р¶РґС‹Рµ 12 РєР°РґСЂРѕРІ вЂ” РЅР°РЅРѕСЃРёРј СѓСЂРѕРЅ
        if s.tick <= 0 then
            s.tick = 12
            local atk = actor:fire_explosion(s.x, s.y, s.w, s.h, s.dmg, sunSprite, nil, false)
            -- РЈСЂРѕРЅ СЃРѕР»РЅС†Р° РќР• РґРѕР»Р¶РµРЅ РїСЂРѕРєР°С‚СЊ Рё СѓР±РёРІР°С‚СЊ В«РїРѕ-РЅР°СЃС‚РѕСЏС‰РµРјСѓВ» РІ СЃРјС‹СЃР»Рµ onKillProc:
            -- РёРЅР°С‡Рµ СѓР±РёС‚С‹Рµ СЃРѕР»РЅС†РµРј РІСЂР°РіРё РІС‹Р·РѕРІСѓС‚ onKillProc в†’ СЃРѕР»РЅС†Рµ СЃРѕР·РґР°СЃС‚ СЃР°РјРѕ СЃРµР±СЏ.
            if atk and atk.attack_info then
                atk.attack_info.proc = false
                atk.attack_info:set_critical(false)
            end
        end
        -- РЈРґР°Р»СЏРµРј РїРѕ Р·Р°РІРµСЂС€РµРЅРёРё Р¶РёР·РЅРё
        if s.t <= 0 then
            table.remove(data.suns, i)
        end
    end
end)

-- Р’РёР·СѓР°Р»: РїРѕРєР°Р·С‹РІР°РµРј Р·РѕРЅСѓ РґРµР№СЃС‚РІРёСЏ РєР°Р¶РґРѕРіРѕ Р°РєС‚РёРІРЅРѕРіРѕ СЃРѕР»РЅС†Р°
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    local data = actor:get_data(nil, GUID)
    if not data.suns then return end
    gm.draw_set_colour(SUN_COLOR)
    for _, s in ipairs(data.suns) do
        -- Р­Р»Р»РёРїСЃ РїРѕ С„Р°РєС‚РёС‡РµСЃРєРёРј СЂР°Р·РјРµСЂР°Рј Р·РѕРЅС‹ РІР·СЂС‹РІР° (s.w РїРѕ РіРѕСЂРёР·РѕРЅС‚Р°Р»Рё, s.h РїРѕ РІРµСЂС‚РёРєР°Р»Рё)
        gm.draw_ellipse(s.x - s.w, s.y - s.h, s.x + s.w, s.y + s.h, true)
    end
end)
