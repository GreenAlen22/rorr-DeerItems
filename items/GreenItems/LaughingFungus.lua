-- DeerItems-LaughingFungus
-- Р—Р°СЃС‚С‹РІ РЅР° 1 СЃРµРєСѓРЅРґСѓ, СЃРѕР·РґР°С‘С‚ РІРѕРєСЂСѓРі РІР»Р°РґРµР»СЊС†Р° Р·РѕРЅСѓ, РєРѕС‚РѕСЂР°СЏ СЂР°Р· РІ СЃРµРєСѓРЅРґСѓ Р»РµС‡РёС‚ РІСЃРµС… СЃРѕСЋР·РЅРёРєРѕРІ
-- РІ СЂР°РґРёСѓСЃРµ РЅР° РїСЂРѕС†РµРЅС‚ РѕС‚ РњРђРљРЎРРњРђР›Р¬РќРћР“Рћ HP РІР»Р°РґРµР»СЊС†Р°. РџСЂРё РґРІРёР¶РµРЅРёРё Р·РѕРЅР° РіР°СЃРЅРµС‚, РѕС‚СЃС‡С‘С‚ РЅР°С‡РёРЅР°РµС‚СЃСЏ Р·Р°РЅРѕРІРѕ.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
local sprite = Sprite.new("item/LaughingFungus", PATH.."assets/sprites/items/sGreenItems/LaughingFungus.png", 1, 18, 18)
local zoneSprite = Sprite.new("particle/LaughingFungusZone", PATH.."assets/sprites/particle/LaughingFungusZone.png", 18, 16, 32)

-- guid РјРѕРґР° РІС‹РЅРѕСЃРёРј РѕРґРёРЅ СЂР°Р· вЂ” С‡С‚РѕР±С‹ get_data РЅРµ РёСЃРєР°Р» РµРіРѕ С‡РµСЂРµР· debug-СЃС‚РµРє РєР°Р¶РґС‹Р№ РєР°РґСЂ
local GUID = _ENV["!guid"]

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° LaughingFungus
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р·РµР»С‘РЅС‹Р№ (РЅРµРѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, РїРѕРІС‹С€Р°СЋС‰РёР№ Р¶РёРІСѓС‡РµСЃС‚СЊ
local item = Item.new("LaughingFungus")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- РљРѕРЅСЃС‚Р°РЅС‚С‹ РїРѕРІРµРґРµРЅРёСЏ (1 РјРµС‚СЂ = 32 РїРёРєСЃРµР»СЏ)
local STILL_NEEDED  = 60            -- СЃРєРѕР»СЊРєРѕ РєР°РґСЂРѕРІ СЃС‚РѕСЏС‚СЊ РЅРµРїРѕРґРІРёР¶РЅРѕ РґР»СЏ Р°РєС‚РёРІР°С†РёРё Р·РѕРЅС‹ (1 СЃРµРє)
local HEAL_TICK     = 60            -- РїРµСЂРёРѕРґ Р»РµС‡РµРЅРёСЏ РїРѕСЃР»Рµ Р°РєС‚РёРІР°С†РёРё (СЂР°Р· РІ 1 СЃРµРє)
local ZONE_RADIUS_BASE   = 3 * 32   -- Р±Р°Р·РѕРІР°СЏ РїРѕР»СѓС€РёСЂРёРЅР° Р·РѕРЅС‹: 3 Рј
local ZONE_RADIUS_STACK  = 1.5 * 32 -- РїСЂРёР±Р°РІРєР° РїРѕР»СѓС€РёСЂРёРЅС‹ Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ: +1.5 Рј
local ZONE_HEIGHT_SCALE  = 0.5      -- РІС‹СЃРѕС‚Р° Р·РѕРЅС‹ РѕС‚РЅРѕСЃРёС‚РµР»СЊРЅРѕ С€РёСЂРёРЅС‹: 0.5 = СЃСЂРµР·Р°РЅР° РІ 2 СЂР°Р·Р° РїРѕ РІС‹СЃРѕС‚Рµ
local HEAL_BASE     = 0.06          -- Р±Р°Р·РѕРІРѕРµ Р»РµС‡РµРЅРёРµ: 6% РѕС‚ РјР°РєСЃ. HP РІР»Р°РґРµР»СЊС†Р°
local HEAL_STACK    = 0.03          -- РїСЂРёР±Р°РІРєР° Р»РµС‡РµРЅРёСЏ Р·Р° РєР°Р¶РґС‹Р№ СЃС‚Р°Рє СЃРІРµСЂС… РїРµСЂРІРѕРіРѕ: +3%
local MOVE_POS_EPS  = 0.01          -- РїРѕСЂРѕРі РІ РїРёРєСЃРµР»СЏС…: Р»РѕРІРёС‚ subpixel-РґРІРёР¶РµРЅРёРµ РІРѕ РІСЂРµРјСЏ Р·Р°Р¶Р°С‚РѕР№ Р°С‚Р°РєРё
local MOVE_SPEED_EPS = 0.01         -- РїРѕСЂРѕРі СЃРєРѕСЂРѕСЃС‚Рё: Р»РѕРІРёС‚ РґРІРёР¶РµРЅРёРµ РјРµРЅСЊС€Рµ 1 РїРёРєСЃРµР»СЏ Р·Р° РєР°РґСЂ
local ZONE_Y_OFFSET = 40           -- С†РµРЅС‚СЂ Р·РѕРЅС‹ РїСЂРёРїРѕРґРЅСЏС‚ РЅР°Рґ РЅРѕРіР°РјРё РїРµСЂСЃРѕРЅР°Р¶Р°
local ZONE_TTL      = 15            -- Р·Р°РїР°СЃ РєР°РґСЂРѕРІ Р¶РёР·РЅРё Р·РѕРЅС‹ Р±РµР· РѕР±РЅРѕРІР»РµРЅРёСЏ (СЃС‚СЂР°С…РѕРІРєР° РѕС‚ В«РІРёСЃСЏС‡РёС…В» Р·РѕРЅ)
local MUSHROOM_VARIANTS = 6
local MUSHROOM_VARIANT_FRAMES = 3
local MUSHROOM_APPEAR_TICK = 4
local MUSHROOM_GRAVITY = 0.35
local MUSHROOM_FALL_FUSE = 90
local MUSHROOM_DROP_HEIGHT_MIN = 2
local MUSHROOM_DROP_HEIGHT_MAX = 4
local MUSHROOM_COUNT_BASE = 6
local MUSHROOM_COUNT_STACK = 6
local MUSHROOM_COUNT_MAX = 45
local MUSHROOM_MIN_SPACING = 8
local MUSHROOM_SCALE_MIN = 100
local MUSHROOM_SCALE_MAX = 100

local function zone_radius_for(stack)
    return ZONE_RADIUS_BASE + ZONE_RADIUS_STACK * (stack - 1)
end

local function zone_height_for(radius)
    return radius * ZONE_HEIGHT_SCALE
end

local function is_in_zone(target, x, y, radius, height)
    local dx = (target.x - x) / radius
    local dy = (target.y - y) / height
    return dx * dx + dy * dy <= 1
end

local function is_actor_moving(actor, data, px, py)
    local moved_by_position = math.abs(px - (data.lf_px or px)) > MOVE_POS_EPS
                           or math.abs(py - (data.lf_py or py)) > MOVE_POS_EPS

    local phspeed = actor.pHspeed or actor.hspeed or 0
    local pvspeed = actor.pVspeed or actor.vspeed or 0
    local moved_by_speed = math.abs(phspeed) > MOVE_SPEED_EPS
                        or math.abs(pvspeed) > MOVE_SPEED_EPS

    return moved_by_position or moved_by_speed
end

local function mushroom_count_for(radius)
    local extra_stacks = math.max(0, math.floor((radius - ZONE_RADIUS_BASE) / ZONE_RADIUS_STACK + 0.5))
    return math.min(MUSHROOM_COUNT_MAX, MUSHROOM_COUNT_BASE + extra_stacks * MUSHROOM_COUNT_STACK)
end

local function random_mushroom_x(zone, mushrooms)
    local x = zone.x + gm.irandom_range(-zone.radius, zone.radius)
    for _ = 1, 8 do
        local ok = true
        for _, mushroom in ipairs(mushrooms) do
            if Instance.exists(mushroom) and math.abs(mushroom.x - x) < MUSHROOM_MIN_SPACING then
                ok = false
                break
            end
        end
        if ok then return x end
        x = zone.x + gm.irandom_range(-zone.radius, zone.radius)
    end
    return x
end

local function mushroom_frame_for(variant, life)
    local base = (variant or 0) * MUSHROOM_VARIANT_FRAMES
    local frame = math.min(MUSHROOM_VARIANT_FRAMES - 1, math.floor((life or 0) / MUSHROOM_APPEAR_TICK))
    return base + frame
end

local objMushroom = Object.new("EfLaughingFungusMushroom")
objMushroom:set_sprite(zoneSprite)
objMushroom:set_depth(50)
Callback.add(objMushroom.on_create, function(self)
    self.zone = -4
    self.life = 0
    self.variant = 0
    self.mask_index = gm.constants.sSinglePixel
    self.image_speed = 0
    self.image_index = 0
    self.image_xscale = 1
    self.image_yscale = 1
    self.gravity = MUSHROOM_GRAVITY
    self.speed = 1
    self.direction = 270 + gm.irandom_range(-18, 18)
    self:projectile_sync(8)

    -- РЎС‚РѕР»РєРЅРѕРІРµРЅРёСЏ СЃС‡РёС‚Р°РµС‚ СЃРµСЂРІРµСЂ. Р•СЃР»Рё СЃРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅРЅС‹Р№ РіСЂРёР± Р±СѓРґРµС‚ СЃР°Рј СЃС‡РёС‚Р°С‚СЊ
    -- РіСЂР°РІРёС‚Р°С†РёСЋ Сѓ РєР»РёРµРЅС‚Р°, РјРµР¶РґСѓ РѕР±РЅРѕРІР»РµРЅРёСЏРјРё projectile_sync РѕРЅ РїСЂРѕРІР°Р»РёС‚СЃСЏ СЃРєРІРѕР·СЊ РєР°СЂС‚Сѓ.
    if Net.client then
        self.gravity = 0
        self.speed = 0
        self.hspeed = 0
        self.vspeed = 0
    end
end)

Callback.add(objMushroom.on_step, function(self)
    self.life = (self.life or 0) + 1
    self.image_index = mushroom_frame_for(self.variant, self.life)

    if Net.client then
        self.gravity = 0
        self.speed = 0
        self.hspeed = 0
        self.vspeed = 0
        return
    end
    if not Instance.exists(self.zone) then self:destroy(); return end

    local hit_ground = false
    if (self.vspeed or 0) >= 0 then
        local ok, res = pcall(function() return self:is_colliding(gm.constants.oB, self.x, self.y + 2) end)
        hit_ground = ok and res
    end

    if hit_ground or self.life >= MUSHROOM_FALL_FUSE then
        self.gravity = 0
        self.speed = 0
        self.hspeed = 0
        self.vspeed = 0
    end
end)

Callback.add(objMushroom.on_destroy, function(self)
    self:instance_destroy_sync()
end)

Object.add_serializers(objMushroom, function(self, buffer)
    buffer:write_byte(self.variant or 0)
    buffer:write_byte(self.image_xscale < 0 and 1 or 0)
    buffer:write_byte(math.floor(math.abs(self.image_xscale or 1) * 100 + 0.5))
end, function(self, buffer)
    self.image_speed = 0
    self.variant = buffer:read_byte()
    local flip = buffer:read_byte()
    local scale = buffer:read_byte() / 100
    self.image_xscale = flip == 1 and -scale or scale
    self.image_yscale = scale
    self.image_index = mushroom_frame_for(self.variant, self.life)
end)

-- РћР±СЉРµРєС‚ Р·РѕРЅС‹
-- РћС‚РґРµР»СЊРЅС‹Р№ РѕР±СЉРµРєС‚, СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ С‚РѕР»СЊРєРѕ РїРѕРєР° РІР»Р°РґРµР»РµС† СЃС‚РѕРёС‚ РЅР° РјРµСЃС‚Рµ. РћС‚РІРµС‡Р°РµС‚ РРЎРљР›Р®Р§РРўР•Р›Р¬РќРћ
-- Р·Р° РІРёР·СѓР°Р»РёР·Р°С†РёСЋ: СЃРµР№С‡Р°СЃ СЌС‚Рѕ РїСЂРѕСЃС‚Р°СЏ РѕС‚СЂРёСЃРѕРІРєР° РєСЂСѓРіРѕРІ РІ onDraw, РїРѕР·Р¶Рµ СЃСЋРґР° РІСЃС‚Р°РЅСѓС‚ РїР°СЂС‚РёРєР»С‹.
-- Р›РѕРіРёРєСѓ Р»РµС‡РµРЅРёСЏ РѕРЅ РЅРµ С‚СЂРѕРіР°РµС‚ вЂ” РѕРЅР° РѕСЃС‚Р°С‘С‚СЃСЏ РІ РєРѕР»Р»Р±РµРєР°С… РїСЂРµРґРјРµС‚Р°.
--
-- Р–РёР·РЅРµРЅРЅС‹Рј С†РёРєР»РѕРј СѓРїСЂР°РІР»СЏРµС‚ РїСЂРµРґРјРµС‚ (СЃРј. РЅРёР¶Рµ): СЃРѕР·РґР°С‘С‚ Р·РѕРЅСѓ РїСЂРё Р°РєС‚РёРІР°С†РёРё, РєР°Р¶РґС‹Р№ РєР°РґСЂ РѕР±РЅРѕРІР»СЏРµС‚
-- РµС‘ РїРѕР·РёС†РёСЋ/СЂР°РґРёСѓСЃ Рё РїСЂРѕРґР»РµРІР°РµС‚ ttl, Р° РїСЂРё РґРІРёР¶РµРЅРёРё СЃСЂР°Р·Сѓ СѓРЅРёС‡С‚РѕР¶Р°РµС‚. ttl вЂ” СЃС‚СЂР°С…РѕРІРєР°: РµСЃР»Рё РїСЂРµРґРјРµС‚
-- РїРѕ РєР°РєРѕР№-С‚Рѕ РїСЂРёС‡РёРЅРµ РїРµСЂРµСЃС‚Р°Р» РѕР±РЅРѕРІР»СЏС‚СЊ Р·РѕРЅСѓ (СЃРјРµСЂС‚СЊ РІР»Р°РґРµР»СЊС†Р°, РїРѕС‚РµСЂСЏ РїСЂРµРґРјРµС‚Р°), РѕРЅР° СЃР°РјР° РёСЃС‡РµР·РЅРµС‚.
local objZone = Object.new("EfLaughingFungusZone")
objZone.obj_depth = 50
local function destroy_zone_mushrooms(zone)
    local data = zone:get_data(nil, GUID)
    local mushrooms = data.mushrooms
    if not mushrooms then return end

    for _, mushroom in ipairs(mushrooms) do
        if Instance.exists(mushroom) then
            mushroom:destroy()
        end
    end
    data.mushrooms = nil
end

local function ensure_zone_mushrooms(zone)
    local data = zone:get_data(nil, GUID)
    data.mushrooms = data.mushrooms or {}
    local mushrooms = data.mushrooms

    for i = #mushrooms, 1, -1 do
        if not Instance.exists(mushrooms[i]) then
            table.remove(mushrooms, i)
        end
    end

    local wanted = mushroom_count_for(zone.radius)
    while #mushrooms > wanted do
        local mushroom = table.remove(mushrooms)
        if Instance.exists(mushroom) then
            mushroom:destroy()
        end
    end

    while #mushrooms < wanted do
        local x = random_mushroom_x(zone, mushrooms)
        local ground_y = zone.ground_y or zone.y
        local y = ground_y - gm.irandom_range(MUSHROOM_DROP_HEIGHT_MIN, MUSHROOM_DROP_HEIGHT_MAX)
        local mushroom = objMushroom:create(x, y)
        local scale = gm.irandom_range(MUSHROOM_SCALE_MIN, MUSHROOM_SCALE_MAX) / 100
        mushroom.zone = zone
        mushroom.variant = gm.irandom_range(0, MUSHROOM_VARIANTS - 1)
        mushroom.image_index = mushroom_frame_for(mushroom.variant, 0)
        mushroom.image_xscale = gm.irandom_range(0, 1) == 0 and scale or -scale
        mushroom.image_yscale = scale
        table.insert(mushrooms, mushroom)
    end
end

-- РџСЂРё СЃРѕР·РґР°РЅРёРё Р·РѕРЅС‹
Callback.add(objZone.on_create, function(self)
    self.radius = ZONE_RADIUS_BASE
    self.height = zone_height_for(self.radius)
    self.life   = 0           -- СЃРєРѕР»СЊРєРѕ РєР°РґСЂРѕРІ Р·РѕРЅР° СЃСѓС‰РµСЃС‚РІСѓРµС‚ (РїСЂРёРіРѕРґРёС‚СЃСЏ РґР»СЏ Р°РЅРёРјР°С†РёРё РїР°СЂС‚РёРєР»РѕРІ)
    self.ttl    = ZONE_TTL    -- РєР°РґСЂС‹ РґРѕ СЃР°РјРѕСѓРЅРёС‡С‚РѕР¶РµРЅРёСЏ, РµСЃР»Рё РїСЂРµРґРјРµС‚ РїРµСЂРµСЃС‚Р°Р» РѕР±РЅРѕРІР»СЏС‚СЊ Р·РѕРЅСѓ
    self:projectile_sync(4)
end)

-- РљР°Р¶РґС‹Р№ РєР°РґСЂ: СЃС‡РёС‚Р°РµРј В«РІРѕР·СЂР°СЃС‚В» Р·РѕРЅС‹ Рё РїСЂРѕРІРµСЂСЏРµРј СЃС‚СЂР°С…РѕРІРѕС‡РЅС‹Р№ С‚Р°Р№РјРµСЂ
Callback.add(objZone.on_step, function(self)
    if Net.client then return end

    self.life = self.life + 1
    self.ttl  = self.ttl - 1
    if self.ttl <= 0 then self:destroy(); return end

    ensure_zone_mushrooms(self)
end)

Callback.add(objZone.on_destroy, function(self)
    if not Net.client then
        destroy_zone_mushrooms(self)
    end
    self:instance_destroy_sync()
end)

-- Р›РѕРіРёРєР° РїСЂРµРґРјРµС‚Р°

-- РЈРЅРёС‡С‚РѕР¶РµРЅРёРµ Р·РѕРЅС‹ РІР»Р°РґРµР»СЊС†Р° (РµСЃР»Рё РѕРЅР° СЃСѓС‰РµСЃС‚РІСѓРµС‚) Рё РѕС‡РёСЃС‚РєР° СЃСЃС‹Р»РєРё
local function destroy_zone(data)
    local zone = data.lf_zone
    if zone and Instance.exists(zone) then
        zone:destroy()
    end
    data.lf_zone = nil
end
-- РљР°Р¶РґС‹Р№ РєР°РґСЂ: РѕС‚СЃР»РµР¶РёРІР°РµРј РЅРµРїРѕРґРІРёР¶РЅРѕСЃС‚СЊ, РІРµРґС‘Рј РІРёР·СѓР°Р»СЊРЅСѓСЋ Р·РѕРЅСѓ Рё Р»РµС‡РёРј СЃРѕСЋР·РЅРёРєРѕРІ СЂР°Р· РІ СЃРµРєСѓРЅРґСѓ
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if stack <= 0 then return end

    local data = actor:get_data("DeerItems", GUID)
    local px, py = actor.x, actor.y

    -- РЎРјРµСЃС‚РёР»СЃСЏ Р»Рё РІР»Р°РґРµР»РµС† Р·Р°РјРµС‚РЅРѕ СЃ РїСЂРѕС€Р»РѕРіРѕ РєР°РґСЂР°
    local moved = is_actor_moving(actor, data, px, py)
    data.lf_px, data.lf_py = px, py

    -- РџСЂРё РґРІРёР¶РµРЅРёРё: РіР°СЃРёРј Р·РѕРЅСѓ Рё СЃР±СЂР°СЃС‹РІР°РµРј РѕС‚СЃС‡С‘С‚
    if moved then
        data.lf_still = 0
        destroy_zone(data)
        return
    end

    -- РљРѕРїРёРј РІСЂРµРјСЏ РЅРµРїРѕРґРІРёР¶РЅРѕСЃС‚Рё; РїРѕРєР° Р·РѕРЅР° РЅРµ Р°РєС‚РёРІРёСЂРѕРІР°РЅР° вЂ” РµС‘ РµС‰С‘ РЅРµС‚
    data.lf_still = (data.lf_still or 0) + 1
    if data.lf_still < STILL_NEEDED then
        destroy_zone(data)
        return
    end

    if Net.client then return end

    -- Р—РѕРЅР° Р°РєС‚РёРІРЅР°: СЃРѕР·РґР°С‘Рј РѕР±СЉРµРєС‚, РµСЃР»Рё РµРіРѕ РµС‰С‘ РЅРµС‚, Рё РєР°Р¶РґС‹Р№ РєР°РґСЂ РѕР±РЅРѕРІР»СЏРµРј РїРѕРґ РІР»Р°РґРµР»СЊС†Р°.
    local radius = zone_radius_for(stack)
    local height = zone_height_for(radius)
    local zone = data.lf_zone
    if not (zone and Instance.exists(zone)) then
        zone = objZone:create(actor.x, actor.y - ZONE_Y_OFFSET)
        data.lf_zone = zone
    end
    zone.x      = actor.x
    zone.y      = actor.y - ZONE_Y_OFFSET
    zone.ground_y = actor.y
    zone.radius = radius
    zone.height = height
    zone.ttl    = ZONE_TTL   -- РїСЂРѕРґР»РµРІР°РµРј Р¶РёР·РЅСЊ Р·РѕРЅС‹, РїРѕРєР° РІР»Р°РґРµР»РµС† СЃС‚РѕРёС‚

    -- РРјРїСѓР»СЊСЃ Р»РµС‡РµРЅРёСЏ: СЂРѕРІРЅРѕ РІ РјРѕРјРµРЅС‚ Р°РєС‚РёРІР°С†РёРё (1 СЃРµРє) Рё РґР°Р»РµРµ РєР°Р¶РґСѓСЋ СЃРµРєСѓРЅРґСѓ
    if (data.lf_still - STILL_NEEDED) % HEAL_TICK ~= 0 then return end

    local heal = actor.maxhp * (HEAL_BASE + HEAL_STACK * (stack - 1))
    local zone_x, zone_y = actor.x, actor.y - ZONE_Y_OFFSET
    local targets = List.wrap(actor:find_characters_circle(zone_x, zone_y, radius, false, 1, true))
    for _, ally in ipairs(targets) do
        if is_in_zone(ally, zone_x, zone_y, radius, height) then
            ally:heal(heal)
        end
    end
end)

-- РџСЂРё РїРѕС‚РµСЂРµ РїСЂРµРґРјРµС‚Р° вЂ” РіР°СЂР°РЅС‚РёСЂРѕРІР°РЅРЅРѕ СѓР±РёСЂР°РµРј Р·РѕРЅСѓ
DeerItemsCallbacks.item_removed(item, function(actor, stack)
    destroy_zone(actor:get_data("DeerItems", GUID))
end)
