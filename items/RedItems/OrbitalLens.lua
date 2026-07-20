-- DeerItems-OrbitalLens / В«РћСЂР±РёС‚Р°Р»СЊРЅР°СЏ Р»РёРЅР·Р°В» / "Orbital Lens"
-- РџРѕСЂС‚ Runic Lens РёР· RoR2 (РѕСЃР»Р°Р±Р»РµРЅ РїРѕРґ RoRR).
-- 1% (+2/3% Р·Р° СЃС‚Р°Рє) С€Р°РЅСЃ РїСЂРё РїРѕРїР°РґР°РЅРёРё РїСЂРёР·РІР°С‚СЊ РјРµС‚РµРѕСЂ РЅР° 800% (+250% Р·Р° СЃС‚Р°Рє) Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР°.
-- РљР°Р¶РґС‹Рµ 100% РЅР°РЅРµСЃС‘РЅРЅРѕРіРѕ СѓСЂРѕРЅР° РїРѕРІС‹С€Р°СЋС‚ С€Р°РЅСЃ Рё СѓСЂРѕРЅ РјРµС‚РµРѕСЂР° (СЃ РєР°РїРѕРј Рё Р·Р°С‚СѓС…Р°РЅРёРµРј).

-- РЎРїСЂР°Р№С‚ РјРµС‚РµРѕСЂР° (РµРіРѕ РґР°С‘С€СЊ С‚С‹), РёРјРїР°РєС‚-СЌС„С„РµРєС‚ РёР· РіРѕС‚РѕРІРѕРіРѕ Explosive.png, Р·РІСѓРє СѓРґР°СЂР° (РµРіРѕ РґР°С‘С€СЊ С‚С‹).
local sprite      = Sprite.new("item/OrbitalLens", PATH.."assets/sprites/items/sRedItems/OrbitalLens.png", 1, 18, 18)
local OrbitalLensMeteor = Sprite.new("particle/OrbitalLens", PATH.."assets/sprites/particle/OrbitalLensMeteor.png", 5, 75, 75)
local OrbitalLensExplosive   = Sprite.new("particle/OrbitalLensBurst", PATH.."assets/sprites/particle/OrbitalLensExplosive.png", 14, 125, 235)
local sound       = Sound.new("OrbitalLens/impact", PATH.."assets/sounds/OrbitalLens.ogg")

local GUID = _ENV["!guid"]

local packet_meteor = Packet.new("OrbitalLens-packet_meteor")
local packet_impact = Packet.new("OrbitalLens-packet_impact")

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°: РІР°СЂРёР°РЅС‚ 1:1 РѕРєР°Р·Р°Р»СЃСЏ СЃРёР»СЊРЅРµРµ РЅСѓР¶РЅРѕРіРѕ, РїРѕСЌС‚РѕРјСѓ Р·РЅР°С‡РµРЅРёСЏ СЃРЅРёР¶РµРЅС‹.
local BASE_CHANCE    = 0.01   -- Р±Р°Р·РѕРІС‹Р№ С€Р°РЅСЃ РїСЂРѕРєР°
local CHANCE_STACK   = 0.02 / 3 -- +2/3% С€Р°РЅСЃР° Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ
local BASE_COEF      = 8.0    -- 800% Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР° (РЅРµ 2000%: РІ RoRR raw+С‡Р°СЃС‚С‹Рµ РїСЂРѕРєРё)
local COEF_STACK     = 2.5    -- +250% Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ
local UNIT_CHANCE    = 0.01 / 3 -- +1/3% С€Р°РЅСЃР° Р·Р° РєР°Р¶РґС‹Рµ 100% РЅР°РЅРµСЃС‘РЅРЅРѕРіРѕ СѓСЂРѕРЅР°
local UNIT_COEF      = 0.30   -- +30% СѓСЂРѕРЅР° РјРµС‚РµРѕСЂР° Р·Р° РєР°Р¶РґС‹Рµ 100% РЅР°РЅРµСЃС‘РЅРЅРѕРіРѕ СѓСЂРѕРЅР°
local UNIT_CHANCE_CAP= 0.05   -- РєР°Рї РЅР°РєРѕРїР»РµРЅРЅРѕРіРѕ Р±РѕРЅСѓСЃР° Рє С€Р°РЅСЃСѓ
local UNIT_COEF_CAP  = 6.0    -- РєР°Рї РЅР°РєРѕРїР»РµРЅРЅРѕРіРѕ Р±РѕРЅСѓСЃР° Рє СѓСЂРѕРЅСѓ (=600%)
local DECAY_PERIOD   = 300    -- СЂР°Р· РІ 5 СЃРµРє РїСѓР» РЅР°РЅРµСЃС‘РЅРЅРѕРіРѕ СѓСЂРѕРЅР° СѓРјРµРЅСЊС€Р°РµС‚СЃСЏ РІРґРІРѕРµ
local PROC_CD        = 15     -- РјРёРЅ. РёРЅС‚РµСЂРІР°Р» РјРµР¶РґСѓ РїСЂРѕРєР°РјРё (РєР°РґСЂС‹): onHitProc С‡Р°СЃС‚РёС‚ РЅР° РјСѓР»СЊС‚РёС…РёС‚Р°С…
local FALL_FRAMES    = 36     -- РІСЂРµРјСЏ РїР°РґРµРЅРёСЏ РјРµС‚РµРѕСЂР° (~0.6 СЃРµРє)
local RADIUS         = 160    -- СЂР°РґРёСѓСЃ РІР·СЂС‹РІР° (~5 Рј)
local MAX_METEORS    = 6      -- РѕРґРЅРѕРІСЂРµРјРµРЅРЅРѕ РІ РІРѕР·РґСѓС…Рµ (РєР°Рє MAX_SUNS РІ ShineOSun)

local item = Item.new("OrbitalLens")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
packet_meteor:set_serializers(function(buffer, actor, x, ty, sy)
    buffer:write_instance(actor)
    buffer:write_float(x)
    buffer:write_float(ty)
    buffer:write_float(sy)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local x = buffer:read_float()
    local ty = buffer:read_float()
    local sy = buffer:read_float()
    if not Instance.exists(actor) then return end

    local data = actor:get_data("OrbitalLens", GUID)
    data.meteors = data.meteors or {}
    data.meteors[#data.meteors + 1] = { x = x, ty = ty, sy = sy, t = FALL_FRAMES }
end)

packet_impact:set_serializers(function(buffer, actor, x, y, pitch)
    buffer:write_instance(actor)
    buffer:write_float(x)
    buffer:write_float(y)
    buffer:write_float(pitch)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local x = buffer:read_float()
    local y = buffer:read_float()
    local pitch = buffer:read_float()
    local ef = gm.instance_create(x, y, gm.constants.oEfExplosion)
    ef.sprite_index = OrbitalLensExplosive
    if Instance.exists(actor) then actor:sound_play(sound, 1.0, pitch) end
end)

item:onAcquire(function(actor, stack)
    local data = actor:get_data("OrbitalLens", GUID)
    data.pool    = data.pool or 0
    data.meteors = data.meteors or {}
end)

-- РќР°РєРѕРїРёС‚РµР»СЊ РЅР°РЅРµСЃС‘РЅРЅРѕРіРѕ СѓСЂРѕРЅР° + СЂРѕР»Р» РјРµС‚РµРѕСЂР° (РІСЃСЏ Р»РѕРіРёРєР° РЅР° С…РѕСЃС‚Рµ).
item:onHitProc(function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    if not Net.host then return end
    if not (victim and Instance.exists(victim)) then return end

    local data = actor:get_data("OrbitalLens", GUID)
    data.pool    = data.pool or 0
    data.meteors = data.meteors or {}

    -- РљРѕРїРёРј РЅР°РЅРµСЃС‘РЅРЅС‹Р№ СѓСЂРѕРЅ.
    local dealt = hit_info and (hit_info.damage or 0) or 0
    if dealt > 0 then data.pool = data.pool + dealt end

    -- Р”РµР±Р°СѓРЅСЃ РїСЂРѕРєР° (РјСѓР»СЊС‚РёС†РµР»СЊ/С‡Р°СЃС‚С‹Рµ Р°С‚Р°РєРё РґР°СЋС‚ РїР°С‡РєСѓ РїРѕРїР°РґР°РЅРёР№ Р·Р° РєР°РґСЂ).
    local frame = Global._current_frame
    if data.ol_last and (frame - data.ol_last) < PROC_CD then return end

    local base = actor.damage or 0
    if base <= 0 then return end

    -- В«Р®РЅРёС‚С‹В» = СЃРєРѕР»СЊРєРѕ СЂР°Р· РЅР°РєРѕРїР»РµРЅРѕ 100% С‚РµРєСѓС‰РµРіРѕ СѓСЂРѕРЅР° РёРіСЂРѕРєР°.
    local units      = math.floor(data.pool / base)
    local bonusChance = math.min(UNIT_CHANCE_CAP, UNIT_CHANCE * units)
    local bonusCoef   = math.min(UNIT_COEF_CAP,  UNIT_COEF  * units)

    local chance = BASE_CHANCE + CHANCE_STACK * (stack - 1) + bonusChance
    if math.random() >= chance then return end
    data.ol_last = frame

    if #data.meteors >= MAX_METEORS then return end

    local coef = BASE_COEF + COEF_STACK * (stack - 1) + bonusCoef
    -- РњРµС‚РµРѕСЂ СЂР°СЃС…РѕРґСѓРµС‚ РЅР°РєРѕРїР»РµРЅРЅС‹Р№ СѓСЂРѕРЅ: РїСЂРё РЅРµРїСЂРµСЂС‹РІРЅРѕР№ Р°С‚Р°РєРµ С€Р°РЅСЃ РЅРµ РѕСЃС‚Р°С‘С‚СЃСЏ РЅР° РєР°РїРµ.
    data.pool = 0
    data.meteors[#data.meteors + 1] = {
        x  = victim.x,
        ty = victim.y,                 -- С‚РѕС‡РєР° РїР°РґРµРЅРёСЏ
        sy = victim.y - (10 * 32),     -- СЃС‚Р°СЂС‚ РјРµС‚РµРѕСЂР°: ~10 Рј РЅР°Рґ С†РµР»СЊСЋ
        t  = FALL_FRAMES,
        coef = coef,
        w  = RADIUS,
        h  = RADIUS,
    }

    if Net.host then
        packet_meteor:send_to_all(actor, victim.x, victim.y, victim.y - (10 * 32))
    end
end)

-- РџР°РґРµРЅРёРµ + РІР·СЂС‹РІ РјРµС‚РµРѕСЂРѕРІ Рё Р·Р°С‚СѓС…Р°РЅРёРµ РЅР°РєРѕРїРёС‚РµР»СЏ.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("OrbitalLens", GUID)
    data.pool    = data.pool or 0
    data.meteors = data.meteors or {}

    if Net.client then
        for i = #data.meteors, 1, -1 do
            local meteor = data.meteors[i]
            meteor.t = meteor.t - 1
            if meteor.t <= 0 then table.remove(data.meteors, i) end
        end
        return
    end

    -- Р—Р°С‚СѓС…Р°РЅРёРµ РЅР°РєРѕРїР»РµРЅРЅРѕРіРѕ СѓСЂРѕРЅР°, С‡С‚РѕР±С‹ Р»РёРЅРµР№РЅР°СЏ С„РѕСЂРјСѓР»Р° RoR2 РЅРµ СѓС…РѕРґРёР»Р° РІ Р±РµСЃРєРѕРЅРµС‡РЅРѕСЃС‚СЊ.
    data.ol_decay = (data.ol_decay or 0) + 1
    if data.ol_decay >= DECAY_PERIOD then
        data.ol_decay = 0
        data.pool = data.pool * 0.5
    end

    for i = #data.meteors, 1, -1 do
        local m = data.meteors[i]
        m.t = m.t - 1
        if m.t <= 0 then
            -- coef РїРµСЂРµРґР°С‘Рј 5-Рј Р°СЂРіСѓРјРµРЅС‚РѕРј в†’ fire_explosion С‚СЂР°РєС‚СѓРµС‚ РµРіРѕ РєР°Рє РјРЅРѕР¶РёС‚РµР»СЊ СѓСЂРѕРЅР° РёРіСЂРѕРєР°
            -- (= В«800% Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР°В»). proc=false/Р±РµР· РєСЂРёС‚Р° вЂ” РёРЅР°С‡Рµ СЃР°РјРѕРїСЂРѕРє Рё С†РµРїРЅР°СЏ СЂРµР°РєС†РёСЏ.
            local atk = actor:fire_explosion(m.x, m.ty, m.w, m.h, m.coef, nil, nil, false)
            if atk and atk.attack_info then
                atk.attack_info.proc = false
                atk.attack_info:set_critical(false)
            end
            gm.instance_create(m.x, m.ty, gm.constants.oEfExplosion).sprite_index = OrbitalLensExplosive
            local sound_pitch = 0.9 + math.random() * 0.4
            actor:sound_play(sound, 1.0, sound_pitch)
            if Net.host then
                packet_impact:send_to_all(actor, m.x, m.ty, sound_pitch)
            end
            table.remove(data.meteors, i)
        end
    end
end)

-- Р’РёР·СѓР°Р»: РїР°РґР°СЋС‰РёР№ РјРµС‚РµРѕСЂ + РєРѕР»СЊС†Рѕ-С†РµР»СЊ (РІСЃС‚СЂРѕРµРЅРЅР°СЏ РѕС‚СЂРёСЃРѕРІРєР°).
item:onPostDraw(function(actor, stack)
    local data = actor:get_data("OrbitalLens", GUID)
    if not data.meteors then return end
    for _, m in ipairs(data.meteors) do
        local p  = 1 - (m.t / FALL_FRAMES)             -- РїСЂРѕРіСЂРµСЃСЃ РїР°РґРµРЅРёСЏ 0..1
        local cy = m.sy + (m.ty - m.sy) * p
        gm.draw_sprite(OrbitalLensMeteor, 0, m.x, cy)
        gm.draw_set_colour(Color(0xff7733))
        gm.draw_set_colour(Color.WHITE)
    end
end)
