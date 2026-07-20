-- DeerItems-CascadeFailure / В«РљР°СЃРєР°РґРЅС‹Р№ РѕС‚РєР°Р·В» / "Cascade Failure"
-- РџРѕСЂС‚ Networked Suffering РёР· RoR2 (RoRR-РІР°СЂРёР°РЅС‚: РєРѕРїРёРј СѓСЂРѕРЅ, РєРѕС‚РѕСЂС‹Р№ РЅР°РЅРѕСЃРёРј Р·Р°СЂР°Р¶С‘РЅРЅС‹Рј).
-- Р—Р°СЂР°Р¶Р°РµС‚ РґРѕ 4 (+2 Р·Р° СЃС‚Р°Рє) РІСЂР°РіРѕРІ. 50% СѓСЂРѕРЅР°, РєРѕС‚РѕСЂС‹Р№ РІС‹ РЅР°РЅРѕСЃРёС‚Рµ Р·Р°СЂР°Р¶С‘РЅРЅС‹Рј, РєРѕРїРёС‚СЃСЏ РІ РѕР±С‰РёР№ РїСѓР».
-- РљР°Р¶РґС‹Рµ 3 СЃРµРє РІСЃРµ Р·Р°СЂР°Р¶С‘РЅРЅС‹Рµ РїРѕР»СѓС‡Р°СЋС‚ 100% РЅР°РєРѕРїР»РµРЅРЅРѕРіРѕ СѓСЂРѕРЅР°.

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° (Р±РѕР»РІР°РЅРєР° РёР· template), РёРјРїР°РєС‚-СЌС„С„РµРєС‚ РёР· РіРѕС‚РѕРІРѕРіРѕ Explosive.png, Р·РІСѓРє РґРµС‚РѕРЅР°С†РёРё (РµРіРѕ РґР°С‘С€СЊ С‚С‹).
local sprite    = Sprite.new("item/CascadeFailure", PATH.."assets/sprites/items/sRedItems/CascadeFailure.png", 1, 18, 18)
local explosive = Sprite.new("particle/CascadeBurst", PATH.."assets/sprites/particle/voltOverloadHit.png", 6, 16, 16)
local mark      = Sprite.new("particle/CascadeFailureMark", PATH.."assets/sprites/particle/CascadeFailureMark.png", 1, 9.5, 8.5)
local sound     = Sound.new("CascadeFailure/detonate", PATH.."assets/sounds/CascadeFailure.ogg")

local GUID = _ENV["!guid"]

-- Р›РѕРіРёРєСѓ СЃС‡РёС‚Р°РµС‚ С…РѕСЃС‚, Р° РґР°РЅРЅС‹Рµ РїСЂРµРґРјРµС‚Р° Сѓ РєР°Р¶РґРѕРіРѕ РёРіСЂРѕРєР° Р»РѕРєР°Р»СЊРЅС‹Рµ. РџРµСЂРµРґР°С‘Рј
-- РєР»РёРµРЅС‚Р°Рј СЃРѕСЃС‚РѕСЏРЅРёРµ РґР»СЏ РѕС‚СЂРёСЃРѕРІРєРё: Р·Р°СЂР°Р¶С‘РЅРЅС‹Рµ С†РµР»Рё, СЂР°Р·РјРµСЂ РїСѓР»Р°, СЌС„С„РµРєС‚ Рё Р·РІСѓРє
-- РІР·СЂС‹РІР° РґРѕР»Р¶РЅС‹ РІС‹РіР»СЏРґРµС‚СЊ РѕРґРёРЅР°РєРѕРІРѕ Сѓ РІСЃРµС….
local packet_state = Packet.new("CascadeFailure-packet_state")
local packet_release = Packet.new("CascadeFailure-packet_release")

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local CAP_BASE       = 4      -- РјР°РєСЃРёРјСѓРј Р·Р°СЂР°Р¶С‘РЅРЅС‹С… РїСЂРё 1 СЃС‚Р°РєРµ
local CAP_STACK      = 2      -- +2 Р·Р°СЂР°Р¶С‘РЅРЅС‹С… Р·Р° СЃС‚Р°Рє
local CAPTURE_FRAC   = 0.5    -- 50% РЅР°РЅРѕСЃРёРјРѕРіРѕ Р·Р°СЂР°Р¶С‘РЅРЅС‹Рј СѓСЂРѕРЅР° СѓС…РѕРґРёС‚ РІ РїСѓР»
local RELEASE_PERIOD = 180    -- РґРµС‚РѕРЅР°С†РёСЏ РєР°Р¶РґС‹Рµ 3 СЃРµРє
local POOL_CAP_COEF  = 25     -- РєР°Рї РґРµС‚РѕРЅР°С†РёРё: РЅРµ Р±РѕР»СЊС€Рµ 2500% СѓСЂРѕРЅР° РёРіСЂРѕРєР° РЅР° РѕРґРЅСѓ С†РµР»СЊ (Р°РЅС‚Рё-runaway)
local POOL_TEXT_COLOR = Color(0x6a2cff)

-- РњРµС‚РєР° Р·Р°СЂР°Р¶РµРЅРёСЏ: РїРѕСЃС‚РѕСЏРЅРЅР°СЏ (is_timed=false), СЃР»СѓР¶РёС‚ С‚РѕР»СЊРєРѕ РёРЅРґРёРєР°С‚РѕСЂРѕРј вЂ” СЃС‚Р°С‚РѕРІ РЅРµ РјРµРЅСЏРµС‚.
-- Р’РЅРµС€РЅРёР№ РІРёРґ Р·Р°СЂР°Р¶С‘РЅРЅС‹С… СЂРёСЃСѓРµРј СЃР°РјРё РІСЃС‚СЂРѕРµРЅРЅРѕР№ РіСЂР°С„РёРєРѕР№ (СЃРј. onPostDraw), РёРєРѕРЅРєСѓ РЅРµ РїРѕРєР°Р·С‹РІР°РµРј.
local function round_pool(pool)
    return math.floor((pool or 0) + 0.5)
end

local infectBuff = Buff.new("CascadeInfect")
infectBuff.show_icon = false
infectBuff.is_debuff = true
infectBuff.max_stack = 1
infectBuff.is_timed  = false
local function is_infected_actor(actor)
    return actor
        and Instance.exists(actor)
        and actor.buff_stack ~= nil
        and actor:buff_count(infectBuff) > 0
end

local function sync_visual_state(actor, data)
    if not Net.host then return end

    local infected = {}
    for vid, victim in pairs(data.infected or {}) do
        if is_infected_actor(victim) then
            infected[#infected + 1] = victim
        else
            data.infected[vid] = nil
        end
    end

    data.cf_synced_count = #infected
    packet_state:send_to_all(actor, data.pool or 0, infected)
end

packet_state:set_serializers(function(buffer, actor, pool, victims)
    buffer:write_instance(actor)
    buffer:write_float(pool)
    buffer:write_ushort(#victims)
    for _, victim in ipairs(victims) do
        buffer:write_instance(victim)
    end
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local pool = buffer:read_float()
    local count = buffer:read_ushort()
    local victims = {}
    for i = 1, count do
        victims[i] = buffer:read_instance()
    end
    if not Instance.exists(actor) then return end

    local data = actor:get_data("CascadeFailure", GUID)
    data.infected = {}
    data.pool = pool
    for _, victim in ipairs(victims) do
        if Instance.exists(victim) then
            data.infected[victim.id] = victim
        end
    end
end)

packet_release:set_serializers(function(buffer, actor, pitch, positions)
    buffer:write_instance(actor)
    buffer:write_float(pitch)
    buffer:write_ushort(#positions)
    for _, position in ipairs(positions) do
        buffer:write_float(position.x)
        buffer:write_float(position.y)
    end
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local pitch = buffer:read_float()
    local count = buffer:read_ushort()
    for _ = 1, count do
        local x = buffer:read_float()
        local y = buffer:read_float()
        local ef = gm.instance_create(x, y, gm.constants.oEfExplosion)
        ef.sprite_index = explosive
    end
    if Instance.exists(actor) then
        actor:sound_play(sound, 1.0, pitch)
    end
end)

local item = Item.new("CascadeFailure")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- Р§РёСЃС‚РёРј РЅР°Р±РѕСЂ Р·Р°СЂР°Р¶С‘РЅРЅС‹С… РѕС‚ РјС‘СЂС‚РІС‹С…/РёСЃС‡РµР·РЅСѓРІС€РёС…, РїРѕРїСѓС‚РЅРѕ СЃС‡РёС‚Р°СЏ Р¶РёРІС‹С….
local function prune_count(data)
    local cnt = 0
    for vid, v in pairs(data.infected) do
        if is_infected_actor(v) then
            cnt = cnt + 1
        else
            data.infected[vid] = nil
        end
    end
    return cnt
end

-- РџСЂРё РїРѕРїР°РґР°РЅРёРё: Р·Р°СЂР°Р¶Р°РµРј (РµСЃР»Рё РµСЃС‚СЊ СЃР»РѕС‚) Рё РєРѕРїРёРј 50% СѓСЂРѕРЅР° РїРѕ Р·Р°СЂР°Р¶С‘РЅРЅС‹Рј. Р’СЃС‘ РЅР° С…РѕСЃС‚Рµ.
item:onHitProc(function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    if not Net.host then return end
    if not (victim and Instance.exists(victim)) then return end
    if victim.buff_stack == nil then return end

    local data = actor:get_data("CascadeFailure", GUID)
    data.infected = data.infected or {}
    data.pool     = data.pool or 0

    local id    = victim.id
    local isInf = victim:buff_count(infectBuff) > 0
    if not isInf then
        local cap = CAP_BASE + CAP_STACK * (stack - 1)
        if prune_count(data) < cap then
            victim:buff_apply(infectBuff, 1, 1)
            data.infected[id] = victim
            isInf = true
        end
    end

    if isInf then
        local d = hit_info and (hit_info.damage or 0) or 0
        if d > 0 then data.pool = data.pool + d * CAPTURE_FRAC end
    end

    sync_visual_state(actor, data)
end)

-- РљР°Р¶РґС‹Рµ 3 СЃРµРє РІС‹Р»РёРІР°РµРј РІРµСЃСЊ РїСѓР» РІРѕ РІСЃРµС… Р·Р°СЂР°Р¶С‘РЅРЅС‹С…. Р’СЃС‘ РЅР° С…РѕСЃС‚Рµ.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    if not Net.host then return end

    local data = actor:get_data("CascadeFailure", GUID)
    data.infected = data.infected or {}
    data.pool     = data.pool or 0

    if prune_count(data) ~= (data.cf_synced_count or 0) then
        sync_visual_state(actor, data)
    end

    data.cf_t = (data.cf_t or 0) + 1
    if data.cf_t < RELEASE_PERIOD then return end
    data.cf_t = 0
    if data.pool <= 0 then return end

    local base = actor.damage or 0
    if base <= 0 then return end

    -- РљР°Рї РЅР° РѕРґРёРЅ Р·Р°Р»Рї + РїРµСЂРµРІРѕРґ РїР»РѕСЃРєРѕРіРѕ РїСѓР»Р° РІ РєРѕСЌС„С„РёС†РёРµРЅС‚ fire_direct (Г—СѓСЂРѕРЅ РёРіСЂРѕРєР°).
    local capped = math.min(data.pool, base * POOL_CAP_COEF)
    local coef   = capped / base

    local fired = false
    local positions = {}
    for vid, v in pairs(data.infected) do
        if is_infected_actor(v) then
            -- proc=false/Р±РµР· РєСЂРёС‚Р° РћР‘РЇР—РђРўР•Р›Р¬РќРћ: РёРЅР°С‡Рµ РґРµС‚РѕРЅР°С†РёСЏ СЃРЅРѕРІР° РїРѕРїР°РґС‘С‚ РІ onHitProc Рё Р·Р°С†РёРєР»РёС‚СЃСЏ.
            local atk = actor:fire_direct(v, coef, nil, nil, nil, nil, false)
            if atk and atk.attack_info then
                atk.attack_info.proc = false
                atk.attack_info:set_critical(false)
            end
            gm.instance_create(v.x, v.y, gm.constants.oEfExplosion).sprite_index = explosive
            positions[#positions + 1] = { x = v.x, y = v.y }
            fired = true
        else
            data.infected[vid] = nil
        end
    end

    if fired then
        local sound_pitch = 0.9 + math.random() * 0.3
        actor:sound_play(sound, 1.0, sound_pitch)

        if Net.host then
            packet_release:send_to_all(actor, sound_pitch, positions)
        end
    end
    data.pool = 0
    sync_visual_state(actor, data)
end)

-- РџСЂРё РїРѕР»РЅРѕР№ РїРѕС‚РµСЂРµ РїСЂРµРґРјРµС‚Р° СЃРЅРёРјР°РµРј Р·Р°СЂР°Р¶РµРЅРёРµ СЃ СѓС†РµР»РµРІС€РёС… РІСЂР°РіРѕРІ.
item:onRemove(function(actor, stack)
    if stack > 1 then return end
    local data = actor:get_data("CascadeFailure", GUID)
    if not data.infected then return end
    for vid, v in pairs(data.infected) do
        if is_infected_actor(v) then
            v:buff_remove(infectBuff, v:buff_count(infectBuff))
        end
    end
    data.infected = {}
    data.pool = 0
    sync_visual_state(actor, data)
end)

-- Р’РЅРµС€РЅРёР№ РІРёРґ Р·Р°СЂР°Р¶С‘РЅРЅС‹С…: РјР°СЂРєРµСЂ РЅР°Рґ РІСЂР°РіРѕРј РІСЃС‚СЂРѕРµРЅРЅРѕР№ РѕС‚СЂРёСЃРѕРІРєРѕР№ (Р°СЃСЃРµС‚ РЅРµ РЅСѓР¶РµРЅ).
item:onPostDraw(function(actor, stack)
    local data = actor:get_data("CascadeFailure", GUID)
    if not data.infected then return end
    local pool_text = string.format("%d", round_pool(data.pool))
    for vid, v in pairs(data.infected) do
        if Instance.exists(v) and (Net.client or is_infected_actor(v)) then
            gm.draw_sprite(mark, 0, v.x, v.y - 14)
            gm.draw_set_colour(POOL_TEXT_COLOR)
            gm.draw_text(v.x - (#pool_text * 3) - 9, v.y + 2, pool_text)
            gm.draw_set_colour(Color.WHITE)
        else
            data.infected[vid] = nil
        end
    end
end)
