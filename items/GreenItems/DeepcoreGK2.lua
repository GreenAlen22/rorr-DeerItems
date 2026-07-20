-- DeerItems-DeepcoreGK2
-- РџСЂРёР·С‹РІР°РµС‚ Bosco, РєРѕС‚РѕСЂС‹Р№ СЃС‚СЂРµР»СЏРµС‚ РїРѕ РІСЂР°РіР°Рј Рё Р·Р°РјРµРґР»СЏРµС‚ РёС…. РљРѕР»-РІРѕ С†РµР»РµР№ Рё СЂР°РґРёСѓСЃ Р·Р°РІРёСЃСЏС‚ РѕС‚ СЃС‚Р°РєРѕРІ.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РґСЂРѕРЅР°
-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
local droneSprite = Sprite.new("object/bosco", PATH.."assets/sprites/particle/bosco.png", 4, 16, 8)
local sprite = Sprite.new("item/DeepcoreGK2", PATH.."assets/sprites/items/sGreenItems/DeepcoreGK2.png", 1, 16, 16)

-- Р’С‹РЅРѕСЃРёРј РѕРґРёРЅ СЂР°Р·: guid РјРѕРґР° (С‡С‚РѕР±С‹ get_data РЅРµ РёСЃРєР°Р» РµРіРѕ С‡РµСЂРµР· debug-СЃС‚РµРє РєР°Р¶РґС‹Р№ РєР°РґСЂ)
-- Рё С†РІРµС‚ СЌС„С„РµРєС‚РѕРІ (С‡С‚РѕР±С‹ РЅРµ РїРµСЂРµСЃРѕР·РґР°РІР°С‚СЊ Color РЅР° РєР°Р¶РґС‹Р№ РІС‹СЃС‚СЂРµР»)
local GUID = _ENV["!guid"]
local BLEND = Color(0x221f00)
local oP = gm.constants.oP

-- Р—Р°РјРµРґР»РµРЅРёРµ С†РµР»Рё РѕС‚ РІС‹СЃС‚СЂРµР»Р° РґСЂРѕРЅР° (РЅРµР±РѕР»СЊС€РѕРµ): РјРЅРѕР¶РёС‚РµР»СЊ Рє СЃРєРѕСЂРѕСЃС‚Рё Рё РґР»РёС‚РµР»СЊРЅРѕСЃС‚СЊ РІ РєР°РґСЂР°С….
local SLOW_MULT     = 0.85   -- -15% СЃРєРѕСЂРѕСЃС‚Рё РїРµСЂРµРґРІРёР¶РµРЅРёСЏ С†РµР»Рё
local SLOW_DURATION = 90     -- РґРµСЂР¶РёС‚СЃСЏ 1.5 СЃРµРє, РѕР±РЅРѕРІР»СЏРµС‚СЃСЏ РїСЂРё РєР°Р¶РґРѕРј РїРѕРїР°РґР°РЅРёРё
local HIT_DMG_FRAC  = 0.05   -- СѓСЂРѕРЅ РІС‹СЃС‚СЂРµР»Р° = 5% СѓСЂРѕРЅР° РёРіСЂРѕРєР° (РєРѕСЌС„С„РёС†РёРµРЅС‚ РґР»СЏ fire_direct)
local PROC_CHANCE   = 0.20
local SHIELD_PER_DRONE = 0.05
local DRONE_FIND_RADIUS = 100000
local packet_shot = Packet.new("DeepcoreGK2-packet_shot")
local packet_facing = Packet.new("DeepcoreGK2-packet_facing")

local function instance_exists(inst)
    return inst ~= nil and Instance.exists(inst)
end

local function create_shot_effect(source_x, source_y, target_x, target_y, facing)
    local efLineTracer = Object.find("efLineTracer", "ror")
    local efSparks = Object.find("efSparks", "ror")

    if efLineTracer then
        local tracer = efLineTracer:create(source_x + facing, source_y)
        tracer.xend = target_x
        tracer.yend = target_y
        tracer.bm = 1
        tracer.rate = 0.1
        tracer.width = 1.5
        tracer.image_blend = BLEND
    end

    if efSparks then
        local sparks = efSparks:create(target_x, target_y)
        sparks.sprite_index = gm.constants.sSparks1
        sparks.image_blend = BLEND
    end
end

packet_shot:set_serializers(function(buffer, source_x, source_y, target_x, target_y, facing)
    buffer:write_float(source_x)
    buffer:write_float(source_y)
    buffer:write_float(target_x)
    buffer:write_float(target_y)
    buffer:write_byte(facing >= 0 and 1 or 0)
end, function(buffer)
    if not Net.client then return end

    create_shot_effect(
        buffer:read_float(), buffer:read_float(),
        buffer:read_float(), buffer:read_float(),
        buffer:read_byte() == 1 and 1 or -1
    )
end)

packet_facing:set_serializers(function(buffer, actor, facing)
    buffer:write_instance(actor)
    buffer:write_byte(facing >= 0 and 1 or 0)
end, function(buffer)
    if Net.client then return end

    local actor = buffer:read_instance()
    if not instance_exists(actor) then return end
    actor:get_data("DeerItems", GUID).bosco_facing = buffer:read_byte() == 1 and 1 or -1
end)

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

local function count_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_FIND_RADIUS, false, actor.team, true))
    local n = 0
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP and not is_not_drone(char) then
            n = n + 1
        end
    end
    return n
end

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° DeepcoreGK2
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р·РµР»С‘РЅС‹Р№ (РЅРµРѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: СѓС‚РёР»РёС‚Р°СЂРЅС‹Р№ РїСЂРµРґРјРµС‚
local item = Item.new("DeepcoreGK2")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- РЎРєСЂС‹С‚С‹Р№ РґРµР±Р°С„С„ Р·Р°РјРµРґР»РµРЅРёСЏ, РєРѕС‚РѕСЂС‹Р№ РґСЂРѕРЅ РІРµС€Р°РµС‚ РЅР° С†РµР»СЊ (РёРєРѕРЅРєСѓ РЅРµ РїРѕРєР°Р·С‹РІР°РµРј вЂ” СЃРїСЂР°Р№С‚ РЅРµ РЅСѓР¶РµРЅ).
local slowBuff = Buff.new("DeepcoreSlow")
slowBuff.show_icon = false
slowBuff.is_debuff = true
slowBuff.max_stack = 1
slowBuff:onStatRecalc(function(actor, stack)
    actor.pHmax = actor.pHmax * SLOW_MULT
end)

item:onStatRecalc(function(actor, stack)
    if stack > 0 then
        local n = count_drones(actor)
        actor:get_data("DeerItems", GUID).bosco_drones = n
        if n > 0 then
            actor.maxshield = actor.maxshield + actor.maxhp * SHIELD_PER_DRONE * n
        end
    end
end)

-- РЎРѕР·РґР°РЅРёРµ РѕР±СЉРµРєС‚Р°-РґСЂРѕРЅР° Bosco
local obj = Object.new("Bosco")
obj:set_sprite(droneSprite)
obj:set_depth(1)
-- РџСЂРё СЃРѕР·РґР°РЅРёРё РґСЂРѕРЅР°: РёРЅРёС†РёР°Р»РёР·Р°С†РёСЏ РїР°СЂР°РјРµС‚СЂРѕРІ
obj:onCreate(function(self)
    local data = self:get_data(nil, GUID)
    self.persistent = true
    self.image_speed = 0.25
    self.parent = -4
    data.angle = gm.irandom_range(0, 359)
    data.angle_speed = 50
    data.radius = 100
    data.charge = 0
    self:projectile_sync(8)
end)

-- РџРѕРІРµРґРµРЅРёРµ РґСЂРѕРЅР° РєР°Р¶РґС‹Р№ РєР°РґСЂ
obj:onStep(function(self)
    if Net.client then return end

    local data = self:get_data(nil, GUID)
    local parent = self.parent
    if not instance_exists(parent) then parent = data.parent end

    -- РЈРЅРёС‡С‚РѕР¶Р°РµРј РґСЂРѕРЅР°, РµСЃР»Рё РІР»Р°РґРµР»РµС† РёСЃС‡РµР·
    if not instance_exists(parent) then
        self:destroy()
        return
    end

    -- Р Р°СЃС‡С‘С‚ РїРѕР·РёС†РёРё РІРѕРєСЂСѓРі РёРіСЂРѕРєР° РїРѕ СЃРёРЅСѓСЃРѕРёРґРµ
    data.angle = (data.angle or 0) + (data.angle_speed or 120) / 60
    self.x = parent.x + gm.dcos(data.angle) * (data.radius or 48)
    self.y = parent.y - 10

    -- РџРѕ СѓРјРѕР»С‡Р°РЅРёСЋ РґСЂРѕРЅ СЃРјРѕС‚СЂРёС‚ С‚СѓРґР° Р¶Рµ, РєСѓРґР° РїРѕРІС‘СЂРЅСѓС‚ РёРіСЂРѕРє (РЅР°РїСЂР°РІР»РµРЅРёРµ РїСЂРёС†РµР»Р°).
    -- Р•СЃР»Рё РЅРёР¶Рµ РЅР°Р№РґС‘С‚СЃСЏ С†РµР»СЊ вЂ” РѕСЂРёРµРЅС‚Р°С†РёСЏ РїРµСЂРµРѕРїСЂРµРґРµР»РёС‚СЃСЏ РЅР° РЅРµС‘.
    local owner_data = parent:get_data("DeerItems", GUID)
    local facing = owner_data.bosco_facing or parent.image_xscale
    if facing and facing ~= 0 and self.image_xscale ~= facing then
        self.image_xscale = facing
        self:instance_resync()
    end

    -- Р—Р°СЂСЏРґРєР° Р°С‚Р°РєРё РїРѕ РІСЂРµРјРµРЅРё, Р·Р°РІРёСЃСЏС‰РµРјСѓ РѕС‚ СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё РІР»Р°РґРµР»СЊС†Р°.
    -- РџРѕРєР° РЅРµ Р·Р°СЂСЏР¶РµРЅРѕ вЂ” РєРѕРїРёРј Р·Р°СЂСЏРґ Рё РІС‹С…РѕРґРёРј (РґРµС€С‘РІС‹Р№ РїСѓС‚СЊ, РІС‹РїРѕР»РЅСЏРµС‚СЃСЏ Р±РѕР»СЊС€РёРЅСЃС‚РІРѕ РєР°РґСЂРѕРІ).
    local req = 60 / (parent.attack_speed or 1)
    if data.charge < req then
        data.charge = data.charge + 1
        return
    end
    data.charge = 0

    -- Р”Р°Р»СЊС€Рµ вЂ” С‚РѕР»СЊРєРѕ РІ РјРѕРјРµРЅС‚ РІС‹СЃС‚СЂРµР»Р°. РЎС‚Р°Рє Рё СЂР°РґРёСѓСЃ РЅСѓР¶РЅС‹ Р»РёС€СЊ Р·РґРµСЃСЊ.
    local stack = parent:item_count(item)
    local fire_range = 320 + stack * 32

    -- РќР°С‚РёРІРЅС‹Р№ РїРѕРёСЃРє РІСЂР°РіРѕРІ РІ СЂР°РґРёСѓСЃРµ: РєСЂСѓРі Рё РєРѕРјР°РЅРґСѓ С„РёР»СЊС‚СЂСѓРµС‚ РґРІРёР¶РѕРє
    -- (РєРѕРјР°РЅРґР° РІСЂР°РіРѕРІ вЂ” РїСЂРѕС‚РёРІРѕРїРѕР»РѕР¶РЅР°СЏ РєРѕРјР°РЅРґРµ РІР»Р°РґРµР»СЊС†Р°, РєР°Рє РІ РїСЂРёРјРµСЂР°С… С‚СѓР»РєРёС‚Р°).
    local enemy_team = parent.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(self.x, self.y, fire_range, true, enemy_team, true))

    -- РЎС‡РёС‚Р°РµРј РґРёСЃС‚Р°РЅС†РёРё, С‡С‚РѕР±С‹ Р±РёС‚СЊ Р±Р»РёР¶Р°Р№С€РёС…
    local enemies = {}
    for _, actor in ipairs(found) do
        enemies[#enemies + 1] = {actor = actor, dist = gm.point_distance(self.x, self.y, actor.x, actor.y)}
    end

    -- РќРµС‚ С†РµР»РµР№ РІ СЂР°РґРёСѓСЃРµ вЂ” РІС‹С…РѕРґРёРј
    if not enemies[1] then return end

    -- РЎРѕСЂС‚РёСЂРѕРІРєР° РїРѕ РґРёСЃС‚Р°РЅС†РёРё РЅСѓР¶РЅР°, С‚РѕР»СЊРєРѕ РµСЃР»Рё С†РµР»РµР№ Р±РѕР»СЊС€Рµ РѕРґРЅРѕР№
    if enemies[2] then
        table.sort(enemies, function(a, b) return a.dist < b.dist end)
    end

    -- РћР±СЉРµРєС‚С‹ СЌС„С„РµРєС‚РѕРІ Рё РґР°РЅРЅС‹Рµ РІР»Р°РґРµР»СЊС†Р° Р±РµСЂС‘Рј РѕРґРёРЅ СЂР°Р· РЅР° РІС‹СЃС‚СЂРµР», Р° РЅРµ РЅР° РєР°Р¶РґСѓСЋ С†РµР»СЊ
    local efLineTracer = Object.find("efLineTracer", "ror")
    local efSparks = Object.find("efSparks", "ror")

    -- РђС‚Р°РєР° Р±Р»РёР¶Р°Р№С€РёС… РІСЂР°РіРѕРІ
    local max_targets = 2 + 2 * stack
    for i = 1, max_targets do
        local entry = enemies[i]
        if not entry then break end
        local target = entry.actor

        -- РћСЂРёРµРЅС‚Р°С†РёСЏ РґСЂРѕРЅР°
        self.image_xscale = (target.x < self.x) and -1 or 1
        self:instance_resync()

        -- Р’РёР·СѓР°Р»СЊРЅС‹Рµ СЌС„С„РµРєС‚С‹: Р»СѓС‡ + РёСЃРєСЂС‹
        create_shot_effect(self.x, self.y, target.x, target.y, self.image_xscale)
        if Net.host then
            packet_shot:send_to_all(self.x, self.y, target.x, target.y, self.image_xscale)
        end

        -- РќР°РЅРѕСЃРёРј СѓСЂРѕРЅ РЅР°РїСЂСЏРјСѓСЋ С†РµР»Рё. damage Сѓ fire_direct вЂ” РљРћР­Р¤Р¤РР¦РР•РќРў (Г—СѓСЂРѕРЅ РёРіСЂРѕРєР°),
        -- РїРѕСЌС‚РѕРјСѓ РїРµСЂРµРґР°С‘Рј РґРѕР»СЋ РЅР°РїСЂСЏРјСѓСЋ: 0.05 = 5% СѓСЂРѕРЅР° РёРіСЂРѕРєР° (СЂР°РЅСЊС€Рµ С‚СѓС‚ РѕС€РёР±РѕС‡РЅРѕ
        -- СѓРјРЅРѕР¶Р°Р»Рё РЅР° parent.damage РµС‰С‘ СЂР°Р· в†’ СѓСЂРѕРЅ С€С‘Р» В«РІ РєРІР°РґСЂР°С‚РµВ»).
        local hit = parent:fire_direct(target, HIT_DMG_FRAC)
        if hit and hit.attack_info then
            hit.attack_info:set_color(BLEND)
            if math.random() >= PROC_CHANCE then
                hit.attack_info.proc = false
            end
        end

        -- РќРµР±РѕР»СЊС€РѕРµ Р·Р°РјРµРґР»РµРЅРёРµ С†РµР»Рё; РѕР±РЅРѕРІР»СЏРµРј РґР»РёС‚РµР»СЊРЅРѕСЃС‚СЊ РїСЂРё РєР°Р¶РґРѕРј РїРѕРїР°РґР°РЅРёРё
        target:buff_apply(slowBuff, SLOW_DURATION)
    end
end)

obj:onDestroy(function(self)
    self:instance_destroy_sync()
end)

Object.add_serializers(obj, function(self, buffer)
    buffer:write_instance(self.parent)
    buffer:write_byte(self.image_xscale >= 0 and 1 or 0)
end, function(self, buffer)
    self.parent = buffer:read_instance()
    self.image_xscale = buffer:read_byte() == 1 and 1 or -1
    self:get_data(nil, GUID).parent = self.parent
end)

-- РљРѕРіРґР° РёРіСЂРѕРє РїРѕР»СѓС‡Р°РµС‚ РїСЂРµРґРјРµС‚ вЂ” СЃРѕР·РґР°С‘Рј РґСЂРѕРЅР°, РµСЃР»Рё РµРіРѕ РµС‰С‘ РЅРµС‚
item:onAcquire(function(actor, stack)
    if Net.client then return end

    local data = actor:get_data("DeerItems", GUID)
    if not instance_exists(data.inst) then
        local inst = obj:create(actor.x, actor.y)
        inst.parent = actor
        inst:get_data(nil, GUID).parent = actor
        data.inst = inst
    end
end)

item:onPostStep(function(actor, stack)
    if stack <= 0 then return end

    local data = actor:get_data("DeerItems", GUID)
    if Net.client then
        if actor.is_local then
            local facing = actor.image_xscale >= 0 and 1 or -1
            if data.bosco_facing ~= facing then
                data.bosco_facing = facing
                packet_facing:send_to_host(actor, facing)
            end
        end
        return
    end

    data.bosco_count_tick = (data.bosco_count_tick or 0) + 1
    if data.bosco_count_tick < 15 then return end
    data.bosco_count_tick = 0

    local n = count_drones(actor)
    if n ~= data.bosco_drones then
        data.bosco_drones = n
        actor:recalculate_stats()
    end
end)

-- РљРѕРіРґР° РїСЂРµРґРјРµС‚ СѓРґР°Р»СЏРµС‚СЃСЏ вЂ” СѓРЅРёС‡С‚РѕР¶Р°РµРј РґСЂРѕРЅР°, РµСЃР»Рё РїСЂРµРґРјРµС‚Р° Р±РѕР»СЊС€Рµ РЅРµС‚
item:onRemove(function(actor, stack)
    if Net.client then return end

    local data = actor:get_data("DeerItems", GUID)
    if stack <= 1 and instance_exists(data.inst) then
        data.inst:destroy()
        data.inst = nil
    end
end)
