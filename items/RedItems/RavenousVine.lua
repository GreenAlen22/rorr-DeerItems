-- DeerItems-RavenousVine / В«РќРµРЅР°СЃС‹С‚РЅР°СЏ Р»РѕР·Р°В» / "Ravenous Vine"
-- РџРµСЂРµСЂР°Р±РѕС‚РєР° в„–2 (RoR2 Growth Nectar -> В«СѓРґСѓС€РµРЅРёРµ С‚РѕР»РїС‹В» -> В«СЃР±РѕСЂ СЌСЃСЃРµРЅС†РёРё + РІСЃРїР»РµСЃРєВ»).
-- РЇРґСЂРѕ РїСЂРµР¶РЅРµРµ: СЃС‡РёС‚Р°РµРј РІСЂР°РіРѕРІ Р’РћРљР РЈР“ РёРіСЂРѕРєР°. РќРѕ СЃС‡С‘С‚С‡РёРє Р±РѕР»СЊС€Рµ РќР• РјРЅРѕР¶РёС‚ СЃС‚Р°С‚С‹
-- (СЌС‚РёРј СѓР¶Рµ Р·Р°РЅСЏС‚С‹ Community/IngrownIdol) вЂ” РѕРЅ РљРћР РњРРў Р»РѕР·Сѓ В«СЌСЃСЃРµРЅС†РёРµР№В».
-- РџРѕРєР° РІСЂР°РіРё СЂСЏРґРѕРј, Р»РѕР·Р° РєРѕРїРёС‚ СЌСЃСЃРµРЅС†РёСЋ (С‚РµРј Р±С‹СЃС‚СЂРµРµ, С‡РµРј Р±РѕР»СЊС€Рµ РІСЂР°РіРѕРІ РІ СЂР°РґРёСѓСЃРµ).
-- РџРѕРєР° РІСЂР°РіРё СЂСЏРґРѕРј, Р»РѕР·Р° РїРµСЂРёРѕРґРёС‡РµСЃРєРё Р±СЊС‘С‚ РїРѕ РѕР±Р»Р°СЃС‚Рё; РїСЂРё РґРѕСЃС‚РёР¶РµРЅРёРё РїРѕСЂРѕРіР° вЂ” В«С†РІРµС‚С‘С‚В»: Р±РѕР»СЊС€РѕР№ РІР·СЂС‹РІ + Р»РµС‡РµРЅРёРµ.
-- Р”РёРЅР°РјРёРєР° РїСЂРµР¶РЅСЏСЏ: СЃРјРµСЂС‚РµР»СЊРЅР° РІ РіСѓС‰Рµ Р±РѕСЏ, Р±РµСЃРїРѕР»РµР·РЅР° РІ РѕРґРёРЅРѕС‡РєСѓ. РЎС‚Р°РєРё СЂР°СЃС€РёСЂСЏСЋС‚
-- СЂР°РґРёСѓСЃ СЂР°СЃС€РёСЂСЏРµС‚СЃСЏ СЃРѕ СЃС‚Р°РєР°РјРё; Р±РѕР»СЊС€Рµ РІСЂР°РіРѕРІ РІ РЅС‘Рј СѓСЃРєРѕСЂСЏРµС‚ Р·Р°СЂСЏРґ Рё СѓСЃРёР»РёРІР°РµС‚ СѓСЂРѕРЅ Рё Р»РµС‡РµРЅРёРµ.

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° (Р±РѕР»РІР°РЅРєР° РёР· template). РќРѕРІР° РїРµСЂРµРёСЃРїРѕР»СЊР·СѓРµС‚ РіРѕС‚РѕРІС‹Р№ Explosive.png. Р—РІСѓРє РЅРµ РЅСѓР¶РµРЅ.
local sprite      = Sprite.new("item/RavenousVine", PATH.."assets/sprites/items/sRedItems/RavenousVine.png", 1, 18, 18)
local bloomSprite = Sprite.new("particle/RavenousVineBloom", PATH.."assets/sprites/particle/RavenousVineExplosion.png", 16, 50, 50)
local radiusSprite = Sprite.new("particle/RavenousVineRadius", PATH.."assets/sprites/particle/RavenousVineRadius.png", 12, 100, 100)

local GUID = _ENV["!guid"]

local packet_state = Packet.new("RavenousVine-packet_state")
local packet_bloom = Packet.new("RavenousVine-packet_bloom")

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local RADIUS_BASE  = 2 * 32     -- СЂР°РґРёСѓСЃ РїСЂРё 1 СЃС‚Р°РєРµ (2 РјРµС‚СЂР° = 64px)
local RADIUS_STACK = 32   -- +1 РјРµС‚СЂР° СЂР°РґРёСѓСЃР° Р·Р° РєР°Р¶РґС‹Р№ РґРѕРї. СЃС‚Р°Рє (+32px)
local COUNT_PERIOD = 15     -- РєР°Рє С‡Р°СЃС‚Рѕ РїРµСЂРµСЃС‡РёС‚С‹РІР°РµРј РІСЂР°РіРѕРІ СЂСЏРґРѕРј, РєР°РґСЂРѕРІ (4 СЂР°Р·Р°/СЃРµРє)
local DAMAGE_PERIOD = 30    -- РєР°Рє С‡Р°СЃС‚Рѕ Р»РѕР·Р° Р±СЊС‘С‚ РїРѕ РѕР±Р»Р°СЃС‚Рё, РєР°РґСЂРѕРІ (2 СЂР°Р·Р°/СЃРµРє)

local ESS_PER_ENEMY = 1.0   -- СЌСЃСЃРµРЅС†РёРё РІ СЃРµРєСѓРЅРґСѓ Р·Р° РєР°Р¶РґРѕРіРѕ СѓС‡С‚С‘РЅРЅРѕРіРѕ РІСЂР°РіР°
local THRESHOLD     = 24    -- СЌСЃСЃРµРЅС†РёРё РґР»СЏ В«С†РІРµС‚РµРЅРёСЏВ» (6 РІСЂР°РіРѕРІ => РІСЃРїР»РµСЃРє СЂР°Р· РІ ~4СЃ)

local DAMAGE_BASE  = 0.70  -- СѓСЂРѕРЅ С‚РёРєР°: 70% Р±Р°Р·РѕРІРѕРіРѕ СѓСЂРѕРЅР°...
local DAMAGE_STACK = 0.30  -- ...+30% Р·Р° РєР°Р¶РґС‹Р№ РґРѕРї. СЃС‚Р°Рє
local BURST_DMG_BASE  = 4.0   -- СѓСЂРѕРЅ РІР·СЂС‹РІР° С†РІРµС‚РµРЅРёСЏ: 400% СѓСЂРѕРЅР° РёРіСЂРѕРєР°...
local BURST_DMG_STACK = 2.0   -- ...+200% Р·Р° РєР°Р¶РґС‹Р№ РґРѕРї. СЃС‚Р°Рє
local HEAL_BASE    = 0.12  -- Р»РµС‡РµРЅРёРµ С†РІРµС‚РµРЅРёСЏ: 12% РјР°РєСЃ. HP...
local HEAL_STACK   = 0.06  -- ...+6% Р·Р° РєР°Р¶РґС‹Р№ РґРѕРї. СЃС‚Р°Рє

local VINE_COLOR = Color(0x577147)
local RADIUS_STAGE_FRAMES = 4
local RADIUS_ANIM_PERIOD = 60
local BLOOM_FRAMES = 15
local BLOOM_FRAME_PERIOD = 3

local function radius_for(stack) return RADIUS_BASE + (stack - 1) * RADIUS_STACK end
local function diameter_for(stack) return radius_for(stack) * 2 end
-- РЎР°РјРё РєР°РґСЂС‹ РёРјРµСЋС‚ origin (100, 100), РЅРѕ РёС… СЃРѕРґРµСЂР¶РёРјРѕРµ СЃР»РµРіРєР° СЃРјРµС‰РµРЅРѕ РѕС‚ РєР°РґСЂР° Рє РєР°РґСЂСѓ.
-- Р’С‹СЂР°РІРЅРёРІР°РµРј СЃРѕРґРµСЂР¶РёРјРѕРµ, РЅРµ РјРµРЅСЏСЏ РёСЃС…РѕРґРЅС‹Р№ СЂР°Р·РјРµСЂ С‚РµРєСЃС‚СѓСЂС‹.
local RADIUS_FRAME_OFFSETS = {
    { 0, 1 }, { 3, 0 }, { 1, 1 }, { 0, 0 },
    { 2, 1 }, { 3, -1 }, { 2, 1 }, { 1, -6 },
    { 0, 4 }, { -4, 1 }, { 1, 4 }, { 1, -3 },
}
local function radius_stage_for(ess)
    local frac = math.min(1, math.max(0, (ess or 0) / THRESHOLD))
    if frac < 0.50 then return 0 end
    if frac < 0.75 then return RADIUS_STAGE_FRAMES end
    return RADIUS_STAGE_FRAMES * 2
end
local function radius_frame_for(ess)
    return radius_stage_for(ess) + (math.floor((Global._current_frame or 0) / RADIUS_ANIM_PERIOD) % RADIUS_STAGE_FRAMES)
end
local function disable_control_effects(attack_info)
    attack_info.stun = 0
    attack_info.knockback = 0
    attack_info.knockup = 0
    attack_info.knockback_kind = Actor.KnockbackKind.NONE
    attack_info.knockback_direction = 0
end

local oBloom = Object.new("RavenousVineBloom")
oBloom:set_sprite(bloomSprite)
Callback.add(oBloom.on_create, function(self)
    self.parent = -4
    self.life = 0
    self.image_speed = 0
    self.image_index = 0
end)

Callback.add(oBloom.on_step, function(self)
    if not Instance.exists(self.parent) then self:destroy(); return end
    self.x = self.parent.x
    self.y = self.parent.y
    self.depth = self.parent.depth + 1
    local frame = math.floor((self.life or 0) / BLOOM_FRAME_PERIOD)
    if frame >= BLOOM_FRAMES then self:destroy(); return end
    self.image_index = frame
    self.life = (self.life or 0) + 1
end)

local function create_bloom(actor)
    local bloom = oBloom:create(actor.x, actor.y)
    bloom.parent = actor
    bloom.depth = actor.depth + 1
end

packet_state:set_serializers(function(buffer, actor, essence)
    buffer:write_instance(actor)
    buffer:write_float(essence)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local essence = buffer:read_float()
    if Instance.exists(actor) then
        actor:get_data("RavenousVine", GUID).ess = essence
    end
end)

packet_bloom:set_serializers(function(buffer, actor)
    buffer:write_instance(actor)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    if Instance.exists(actor) then create_bloom(actor) end
end)

local function sync_visual_state(actor, data)
    if not Net.host then return end

    packet_state:send_to_all(actor, data.ess or 0)
end

local item = Item.new("RavenousVine")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_HEALING
-- Р“Р»Р°РІРЅР°СЏ Р»РѕРіРёРєР° РЅР° С…РѕСЃС‚Рµ: РїРµСЂРµСЃС‡С‘С‚ РІСЂР°РіРѕРІ СЂСЏРґРѕРј, РЅР°РєРѕРїР»РµРЅРёРµ СЌСЃСЃРµРЅС†РёРё, В«С†РІРµС‚РµРЅРёРµВ».
-- РЈСЂРѕРЅ/Р»РµС‡РµРЅРёРµ Р°РІС‚РѕСЂРёС‚РµС‚РЅС‹ РЅР° С…РѕСЃС‚Рµ (РєР°Рє RiftBeacon/TwistedOpinion); РєР»РёРµРЅС‚Р°Рј HP СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓРµС‚СЃСЏ.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if Net.client then return end
    if stack <= 0 then return end

    local data  = actor:get_data("RavenousVine", GUID)
    local frame = Global._current_frame
    data.ess = data.ess or 0

    -- РџРµСЂРµСЃС‡С‘С‚ РІСЃРµС… РІСЂР°РіРѕРІ СЂСЏРґРѕРј СЂР°Р· РІ COUNT_PERIOD РєР°РґСЂРѕРІ.
    if data.rv_next == nil then data.rv_next = frame end
    if frame >= data.rv_next then
        data.rv_next = frame + COUNT_PERIOD
        local enemy_team = actor.team == 1 and 2 or 1
        local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, radius_for(stack), false, enemy_team, true))
        data.rv_count = #found
    end

    -- РќР°РєРѕРїР»РµРЅРёРµ СЌСЃСЃРµРЅС†РёРё РєР°Р¶РґС‹Р№ РєР°РґСЂ: С‚РµРј Р±С‹СЃС‚СЂРµРµ, С‡РµРј Р±РѕР»СЊС€Рµ РІСЂР°РіРѕРІ РІ СЂР°РґРёСѓСЃРµ.
    local nb = data.rv_count or 0
    if nb > 0 then
        data.ess = data.ess + nb * ESS_PER_ENEMY / 60
    end

    -- РџРµСЂРёРѕРґРёС‡РµСЃРєРёР№ AoE-СѓСЂРѕРЅ РїРѕ С‚РѕРјСѓ Р¶Рµ СЂР°РґРёСѓСЃСѓ, РїРѕРєР° Р»РѕР·Сѓ РєРѕСЂРјРёС‚ С…РѕС‚СЏ Р±С‹ РѕРґРёРЅ РІСЂР°Рі.
    if data.rv_damage_next == nil then data.rv_damage_next = frame end
    if nb > 0 and frame >= data.rv_damage_next then
        data.rv_damage_next = frame + DAMAGE_PERIOD

        local dmg_coef = DAMAGE_BASE + DAMAGE_STACK * (stack - 1)
        local diameter = diameter_for(stack)
        local atk = actor:fire_explosion(actor.x, actor.y, diameter, diameter, dmg_coef, nil, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false
            atk.attack_info:set_critical(false)
            atk.attack_info:set_color(VINE_COLOR)
            disable_control_effects(atk.attack_info)
        end
    end

    -- Р¦РІРµС‚РµРЅРёРµ: Р±РѕР»СЊС€РѕР№ AoE-РІР·СЂС‹РІ + Р»РµС‡РµРЅРёРµ, РѕСЃС‚Р°С‚РѕРє СЌСЃСЃРµРЅС†РёРё РїРµСЂРµРЅРѕСЃРёРј.
    if data.ess >= THRESHOLD then
        data.ess = data.ess - THRESHOLD

        local dmg_coef = BURST_DMG_BASE + BURST_DMG_STACK * (stack - 1)
        local diameter = diameter_for(stack)
        local atk = actor:fire_explosion(actor.x, actor.y, diameter, diameter, dmg_coef, nil, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false                 -- РІР·СЂС‹РІ С†РІРµС‚РµРЅРёСЏ РЅРµ РґРѕР»Р¶РµРЅ РїСЂРѕРєР°С‚СЊ РґСЂСѓРіРёРµ РїСЂРµРґРјРµС‚С‹/СЃР°Рј СЃРµР±СЏ
            atk.attack_info:set_critical(false)
            atk.attack_info:set_color(VINE_COLOR)
        end

        local heal_frac = HEAL_BASE + HEAL_STACK * (stack - 1)
        actor:heal(actor.maxhp * heal_frac)

        -- Р’РёР·СѓР°Р»СЊРЅР°СЏ РЅРѕРІР° С†РІРµС‚РµРЅРёСЏ
        create_bloom(actor)
        if Net.host then
            packet_bloom:send_to_all(actor)
        end
    end

    if (data.rv_visual_sync or 0) <= frame then
        data.rv_visual_sync = frame + COUNT_PERIOD
        sync_visual_state(actor, data)
    end
end)

-- РџСЂРё РїРѕР»РЅРѕР№ РїРѕС‚РµСЂРµ РїСЂРµРґРјРµС‚Р° РѕР±РЅСѓР»СЏРµРј РЅР°РєРѕРїР»РµРЅРЅРѕРµ.
DeerItemsCallbacks.item_removed(item, function(actor, stack)
    if stack <= 1 then
        local data = actor:get_data("RavenousVine", GUID)
        data.ess      = 0
        data.rv_count = 0
        data.rv_next  = nil
        data.rv_damage_next = nil
        data.rv_visual_sync = nil
    end
end)

-- Р’РёР·СѓР°Р»: РєРѕРЅС‚СѓСЂ СЂР°РґРёСѓСЃР° В«РїРёС‚Р°РЅРёСЏВ» РІРѕРєСЂСѓРі РёРіСЂРѕРєР° (Р±РµР· С…СѓРґР° РЅР°Рґ РіРѕР»РѕРІРѕР№).
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("RavenousVine", GUID)
    local frame = radius_frame_for(data.ess)
    local offset = RADIUS_FRAME_OFFSETS[frame + 1] or { 0, 0 }

    gm.draw_sprite_ext(radiusSprite, frame, actor.x + offset[1], actor.y + offset[2], 1, 1, 0, Color.WHITE, 1)
    gm.draw_set_colour(VINE_COLOR)
    gm.draw_circle(actor.x, actor.y, radius_for(stack), true)
    gm.draw_set_colour(Color.WHITE)
end)
