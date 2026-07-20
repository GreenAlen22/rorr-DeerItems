-- DeerItems-MosquitoNet / В«РњРѕСЃРєРёС‚РЅР°СЏ СЃРµС‚СЊВ» / "Mosquito Net"
-- РџРѕСЂС‚ Defensive Microbots РёР· RoR2 (СѓСЃРёР»РµРЅРЅР°СЏ Р°РґР°РїС‚Р°С†РёСЏ вЂ” РІ RoRR РјР°Р»Рѕ СЃС‚СЂРµР»СЏСЋС‰РёС… РІСЂР°РіРѕРІ).
--  1) РљР°Р¶РґС‹Рµ 0.5 СЃРµРє СЃР±РёРІР°РµС‚ РІСЂР°Р¶РµСЃРєРёРµ СЃРЅР°СЂСЏРґС‹ РІ СЂР°РґРёСѓСЃРµ (Р±Р°Р·Р° 2, +2 Р·Р° СЃС‚Р°Рє).
--  2) РџРµСЂРёРѕРґРёС‡РµСЃРєРё РџРћР›РќРћРЎРўР¬Р® Р±Р»РѕРєРёСЂСѓРµС‚ РѕРґРёРЅ Р»СЋР±РѕР№ РІС…РѕРґСЏС‰РёР№ СѓРґР°СЂ (РљР” СЃРїР°РґР°РµС‚ Р·Р° СЃС‚Р°РєРё).
-- РЎРєРѕСЂРѕСЃС‚СЊ РїРµСЂРµС…РІР°С‚Р° СЂР°СЃС‚С‘С‚ СЃРѕ СЃРєРѕСЂРѕСЃС‚СЊСЋ Р°С‚Р°РєРё.

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° (Р±РѕР»РІР°РЅРєР° РёР· template) Рё Р·РІСѓРє РїРµСЂРµС…РІР°С‚Р°/Р±Р»РѕРєР° (РµРіРѕ РґРµР»Р°РµС€СЊ С‚С‹).
local sprite = Sprite.new("item/MosquitoNet", PATH.."assets/sprites/items/sRedItems/MosquitoNet.png", 1, 18, 18)
local sound  = Sound.new("MosquitoNet/zap", PATH.."assets/sounds/MosquitoNet.ogg")

local GUID  = _ENV["!guid"]
local oP    = gm.constants.oP
local BLEND = Color(0x88ccff)   -- С…РѕР»РѕРґРЅС‹Р№ В«С‚РµС…РЅРёС‡РµСЃРєРёР№В» РѕС‚С‚РµРЅРѕРє С‚СЂР°СЃСЃРµСЂР°/РёСЃРєСЂ (РєР°Рє Сѓ Р‘РѕСЃРєРѕ)

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local BASE_PERIOD = 30    -- 0.5 СЃРµРє РїСЂРё СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё 1.0 (РїРµСЂРµС…РІР°С‚ СЃРЅР°СЂСЏРґРѕРІ)
local MIN_PERIOD  = 8     -- РїРѕР» РїРµСЂРµР·Р°СЂСЏРґРєРё РїРµСЂРµС…РІР°С‚Р°
local RADIUS      = 160   -- ~5 Рј (РІ РјРѕРґРµ 32 px = 1 Рј)
local INTERCEPT_BASE  = 2     -- Р±Р°Р·РѕРІРѕРµ С‡РёСЃР»Рѕ СЃР±РёРІР°РµРјС‹С… СЃРЅР°СЂСЏРґРѕРІ Р·Р° С‚РёРє
local INTERCEPT_STACK = 2     -- +2 Р·Р° СЃС‚Р°Рє
local MAX_PER_TICK    = 14    -- РєСЌРї СЃР±РёРІР°РЅРёР№ Р·Р° С‚РёРє (Р·Р°С‰РёС‚Р° РѕС‚ СЃС‚РѕРёРјРѕСЃС‚Рё/РёРјР±С‹ РЅР° СЂРѕСЏС…)
local CORNER_LEN      = 48    -- РґР»РёРЅР° СѓРіРѕР»РєРѕРІ РёРЅРґРёРєР°С‚РѕСЂР° Р·РѕРЅС‹

local BLOCK_BASE = 7 * 60          -- РљР” Р±Р»РѕРєР° СѓРґР°СЂР°: 7 СЃРµРє РїСЂРё 1 СЃС‚Р°РєРµ
local BLOCK_REDUCTION = 0.10       -- -10% РљР” Р·Р° СЃС‚Р°Рє РіРёРїРµСЂР±РѕР»РёС‡РµСЃРєРё
local BLOCK_DAMAGE_FRAC = 0.10     -- Р±Р»РѕРєРёСЂСѓРµС‚ С‚РѕР»СЊРєРѕ СѓРґР°СЂС‹ Р±РѕР»СЊС€Рµ 10% С‚РµРєСѓС‰РµРіРѕ HP

local function block_cooldown(stack)
    return math.ceil(BLOCK_BASE / (1 + BLOCK_REDUCTION * math.max(0, stack - 1)))
end

-- РЎРЅР°СЂСЏРґС‹, РїРѕРјРµС‡РµРЅРЅС‹Рµ РєР°Рє *NoSync, РєР°Р¶РґС‹Р№ РєР»РёРµРЅС‚ РіР°СЃРёС‚ Р›РћРљРђР›Р¬РќРћ (СѓСЂРѕРЅ Сѓ РЅРµРіРѕ РєР»РёРµРЅС‚СЃРєРёР№,
-- РѕРЅ РµРіРѕ Рё С‚Р°Рє РЅРµ РїРѕР»СѓС‡РёС‚). РЎРёРЅС…СЂРѕРЅРЅС‹Рµ СЃРЅР°СЂСЏРґС‹ СЃРЅРѕСЃРёРј С‚РѕР»СЊРєРѕ РЅР° С…РѕСЃС‚Рµ, РёРЅР°С‡Рµ РґРµСЃРёРЅРє.
local NOSYNC = {}
for _, n in ipairs({ "oSpiderBulletNoSync", "oGuardBulletNoSync", "oBugBulletNoSync", "oScavengerBulletNoSync" }) do
    local c = gm.constants[n]
    if c then NOSYNC[c] = true end
end

local item = Item.new("MosquitoNet")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    local data  = actor:get_data("MosquitoNet", GUID)
    local frame = Global._current_frame
    if data.mn_next == nil then data.mn_next = frame end
    if frame < data.mn_next then return end

    -- РџРµСЂРµР·Р°СЂСЏРґРєР° РїРµСЂРµС…РІР°С‚Р° СѓСЃРєРѕСЂСЏРµС‚СЃСЏ СЃРєРѕСЂРѕСЃС‚СЊСЋ Р°С‚Р°РєРё, РЅРѕ РЅРµ РЅРёР¶Рµ РїРѕР»Р°.
    local aspd = actor.attack_speed or 1
    if aspd < 0.1 then aspd = 0.1 end
    data.mn_next = frame + math.max(MIN_PERIOD, math.ceil(BASE_PERIOD / aspd))

    -- Р“РѕС‚РѕРІС‹Р№ СЂРµРµСЃС‚СЂ Р’Р РђР–Р”Р•Р‘РќР«РҐ СЃРЅР°СЂСЏРґРѕРІ С‚СѓР»РєРёС‚Р° (С‚РѕР»СЊРєРѕ РІСЂР°Р¶РµСЃРєРёРµ РїСѓР»Рё/СЂР°РєРµС‚С‹).
    local projs, any = Instance.find_all(Instance.projectiles)
    if not any then return end

    -- РЎРЅР°СЂСЏРґС‹ РІ СЂР°РґРёСѓСЃРµ + РґРёСЃС‚Р°РЅС†РёРё, С‡С‚РѕР±С‹ СЃР±РёРІР°С‚СЊ Р±Р»РёР¶Р°Р№С€РёРµ.
    local inrange = {}
    for _, p in ipairs(projs) do
        if Instance.exists(p) then
            local d = gm.point_distance(actor.x, actor.y, p.x, p.y)
            if d <= RADIUS then
                inrange[#inrange + 1] = { p = p, d = d }
            end
        end
    end
    if not inrange[1] then return end
    if inrange[2] then table.sort(inrange, function(a, b) return a.d < b.d end) end

    local host         = Net.host
    local efLineTracer = Object.find("efLineTracer", "ror")
    local efSparks     = Object.find("efSparks", "ror")

    local n    = math.min(INTERCEPT_BASE + INTERCEPT_STACK * stack, MAX_PER_TICK)   -- 2 (+2 Р·Р° СЃС‚Р°Рє)
    local shot = 0
    for i = 1, #inrange do
        if shot >= n then break end
        local p = inrange[i].p
        if Instance.exists(p) then
            -- NoSync вЂ” Р»РѕРєР°Р»СЊРЅРѕ РЅР° Р»СЋР±РѕРј РєР»РёРµРЅС‚Рµ; СЃРёРЅС…СЂРѕРЅРЅС‹Рµ вЂ” С‚РѕР»СЊРєРѕ С…РѕСЃС‚.
            if NOSYNC[p.object_index] or host then
                -- Р’РёР·СѓР°Р» РєР°Рє Сѓ Р‘РѕСЃРєРѕ: С‚СЂР°СЃСЃРµСЂ РѕС‚ РёРіСЂРѕРєР° + РёСЃРєСЂС‹ РЅР° СЃРЅР°СЂСЏРґРµ.
                if efLineTracer then
                    local tr = efLineTracer:create(actor.x, actor.y - 8)
                    tr.xend = p.x; tr.yend = p.y
                    tr.bm = 1; tr.rate = 0.1; tr.width = 1.5
                    tr.image_blend = BLEND
                end
                if efSparks then
                    local sp = efSparks:create(p.x, p.y)
                    sp.sprite_index = gm.constants.sSparks1
                    sp.image_blend  = BLEND
                end
                p:destroy()
                shot = shot + 1
            end
        end
    end

    if shot > 0 then
        actor:sound_play(sound, 0.7, 1.2 + math.random() * 0.3)
    end
end)

-- РџРµСЂРёРѕРґРёС‡РµСЃРєРёР№ Р±Р»РѕРє: РґРѕ СЂР°СЃС‡С‘С‚Р° СѓСЂРѕРЅР° РїРѕ РёРіСЂРѕРєСѓ СЃ РїСЂРµРґРјРµС‚РѕРј, РµСЃР»Рё Р±Р»РѕРє РіРѕС‚РѕРІ вЂ” РіР°СЃРёРј СѓРґР°СЂ РІ 0.
-- Р Р°Р±РѕС‚Р°РµС‚ РїСЂРѕС‚РёРІ Р›Р®Р‘РћР“Рћ РёСЃС‚РѕС‡РЅРёРєР° (РїСѓР»Рё, РєРѕРЅС‚Р°РєС‚, РІР·СЂС‹РІС‹). Р’ pcall: РїСЂРё РёРЅРѕР№ СЃРёРіРЅР°С‚СѓСЂРµ С„СѓРЅРєС†РёРё
-- С„РёС‡Р° РїСЂРѕСЃС‚Рѕ РІС‹РєР»СЋС‡РёС‚СЃСЏ, РѕСЃС‚Р°Р»СЊРЅРѕР№ РїСЂРµРґРјРµС‚ РїСЂРѕРґРѕР»Р¶РёС‚ СЂР°Р±РѕС‚Р°С‚СЊ.
pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        local raw = args[2] and args[2].value
        if not raw then return end
        local v = Instance.wrap(raw)
        if not Instance.exists(v) then return end
        if v.object_index ~= oP then return end          -- Р±Р»РѕРє С‚РѕР»СЊРєРѕ РґР»СЏ РёРіСЂРѕРєРѕРІ

        local stack = v:item_count(item)
        if stack <= 0 then return end

        local dmg = args[4] and args[4].value
        if not dmg or dmg <= 0 then return end
        if not v.hp or v.hp <= 0 then return end
        if dmg <= v.hp * BLOCK_DAMAGE_FRAC then return end

        local data  = v:get_data("MosquitoNet", GUID)
        local frame = Global._current_frame
        if data.mn_block_next == nil then data.mn_block_next = 0 end
        if frame < data.mn_block_next then return end

        -- Р‘Р»РѕРєРёСЂСѓРµРј СѓРґР°СЂ Рё Р·Р°РїСѓСЃРєР°РµРј РљР” (СЃРїР°РґР°РµС‚ Р·Р° СЃС‚Р°РєРё).
        args[4].value = 0
        data.mn_block_next = frame + block_cooldown(stack)

        pcall(function()
            local efSparks = Object.find("efSparks", "ror")
            if efSparks then
                local sp = efSparks:create(v.x, v.y - 8)
                sp.sprite_index = gm.constants.sSparks1
                sp.image_blend  = BLEND
            end
            v:sound_play(sound, 0.9, 1.4 + math.random() * 0.2)
        end)
    end)
end)

-- Р›С‘РіРєРёР№ РёРЅРґРёРєР°С‚РѕСЂ Р·РѕРЅС‹ Р·Р°С‰РёС‚С‹ РїРѕРґ РёРіСЂРѕРєРѕРј (РІСЃС‚СЂРѕРµРЅРЅР°СЏ РѕС‚СЂРёСЃРѕРІРєР°, Р°СЃСЃРµС‚ РЅРµ РЅСѓР¶РµРЅ).
item:onPostDraw(function(actor, stack)
    if stack <= 0 then return end
    local left   = actor.x - RADIUS
    local top    = actor.y - RADIUS
    local right  = actor.x + RADIUS
    local bottom = actor.y + RADIUS
    local len    = math.min(CORNER_LEN, RADIUS)

    gm.draw_set_colour(BLEND)
    gm.draw_set_alpha(0.25)
    gm.draw_line(left, top, left + len, top)
    gm.draw_line(left, top, left, top + len)
    gm.draw_line(right, top, right - len, top)
    gm.draw_line(right, top, right, top + len)
    gm.draw_line(left, bottom, left + len, bottom)
    gm.draw_line(left, bottom, left, bottom - len)
    gm.draw_line(right, bottom, right - len, bottom)
    gm.draw_line(right, bottom, right, bottom - len)
    gm.draw_set_alpha(1)
    gm.draw_set_colour(Color.WHITE)
end)
