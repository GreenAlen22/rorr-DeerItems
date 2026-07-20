-- DeerItems-Hunger / В«Р“РѕР»РѕРґВ» / "Hunger"
-- РђРєС‚РёРІРєР° (Р°РґР°РїС‚Р°С†РёСЏ Primordial Cube РёР· RoR2): СЃРѕР·РґР°С‘С‚ С‡С‘СЂРЅСѓСЋ РґС‹СЂСѓ, РєРѕС‚РѕСЂР°СЏ 10 СЃРµРєСѓРЅРґ
-- СЃС‚СЏРіРёРІР°РµС‚ РІСЂР°РіРѕРІ РІ РѕРґРЅСѓ С‚РѕС‡РєСѓ. РЈСЂРѕРЅР° РЅРµ РЅР°РЅРѕСЃРёС‚. Р‘РѕСЃСЃС‹ РЅРµРІРѕСЃРїСЂРёРёРјС‡РёРІС‹. cd 60СЃ.
--
-- РџСЂРёС‚СЏР¶РµРЅРёРµ: РёС‰РµРј РІСЂР°РіРѕРІ С‡РµСЂРµР· find_characters_circle (РїРѕРґС‚РІРµСЂР¶РґС‘РЅРЅС‹Р№ API РјРѕРґР° вЂ”
-- Totemetry/DeepcoreGK2/HeavyLungs) Рё С‚СЏРЅРµРј РїСЂСЏРјРѕР№ Р·Р°РїРёСЃСЊСЋ x/y СЃ Р·Р°С‰РёС‚РѕР№ РѕС‚ РїСЂРѕСЃРєРѕРєР° С†РµРЅС‚СЂР°.
-- Р‘РѕСЃСЃРѕРІ С„РёР»СЊС‚СЂСѓРµРј (= РёРјРјСѓРЅРёС‚РµС‚); СѓСЂРѕРЅ РЅРёРіРґРµ РЅРµ РЅР°РЅРѕСЃРёС‚СЃСЏ.

-- РРєРѕРЅРєР° СЃРЅР°СЂСЏР¶РµРЅРёСЏ Рё СЃРїСЂР°Р№С‚РѕРІС‹Р№ РІРёР·СѓР°Р» РґС‹СЂС‹.
local sprite = Sprite.new("equipment/Hunger", PATH.."assets/sprites/items/sEquipments/Hunger.png", 1, 18, 18)
local radiusSprite = Sprite.new("particle/HungerRadius", PATH.."assets/sprites/particle/HungerRadius.png", 36, 100, 100)
local HungerSpawn = Sound.new("Hunger/hum", PATH.."assets/sounds/HungerSpawn.ogg")

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР°
local COOLDOWN    = 60          -- РєСѓР»РґР°СѓРЅ, СЃРµРєСѓРЅРґС‹
local LIFE        = 10 * 60     -- РІСЂРµРјСЏ Р¶РёР·РЅРё РґС‹СЂС‹, РєР°РґСЂС‹ (10 СЃРµРє)
local PULL_RADIUS = 6 * 32      -- СЂР°РґРёСѓСЃ РїСЂРёС‚СЏР¶РµРЅРёСЏ, px (6 РјРµС‚СЂРѕРІ в‰€ 192px)
local PULL_STRENGTH_MIN = 3    -- СЃРёР»Р° РІСЃР°СЃС‹РІР°РЅРёСЏ РЅР° РєСЂР°СЋ, px/РєР°РґСЂ
local PULL_STRENGTH_MAX = 48    -- СЃРёР»Р° РІСЃР°СЃС‹РІР°РЅРёСЏ РІ С†РµРЅС‚СЂРµ, px/РєР°РґСЂ
local HOLE_SPEED  = 1.2         -- СЃРєРѕСЂРѕСЃС‚СЊ РїРѕР»С‘С‚Р° РґС‹СЂС‹ РІРїРµСЂС‘Рґ, px/РєР°РґСЂ (1.5x РѕС‚ РїСЂРµР¶РЅРёС… 0.8)

local RADIUS_SPRITE_SIZE = 200
local RADIUS_SCALE = (PULL_RADIUS * 2) / RADIUS_SPRITE_SIZE
local VISUAL_DEPTH = 100

local ANIM_TICK = 4
local SPAWN_FRAME_FIRST = 0      -- РєР°РґСЂС‹ 1-7
local SPAWN_FRAME_LAST  = 6
local LOOP_FRAME_FIRST  = 7      -- РєР°РґСЂС‹ 8-25
local LOOP_FRAME_LAST   = 31
local END_FRAME_FIRST   = 32     -- РїРѕСЃР»РµРґРЅРёРµ 4 РєР°РґСЂР°
local END_FRAME_LAST    = 35

local SPAWN_DURATION = (SPAWN_FRAME_LAST - SPAWN_FRAME_FIRST + 1) * ANIM_TICK
local END_DURATION = (END_FRAME_LAST - END_FRAME_FIRST + 1) * ANIM_TICK
local LOOP_LENGTH = LOOP_FRAME_LAST - LOOP_FRAME_FIRST + 1

-- Р‘РµР·РѕРїР°СЃРЅРѕРµ РїСЂРёРІРµРґРµРЅРёРµ GML-Р·РЅР°С‡РµРЅРёСЏ (true / 1.0 / 0.0) Рє Р±СѓР»РµРІСѓ
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

local function visual_frame_for(age)
    age = math.max(age or 0, 0)

    if age < SPAWN_DURATION then
        return SPAWN_FRAME_FIRST + math.floor(age / ANIM_TICK)
    end

    if age >= LIFE - END_DURATION then
        local end_age = math.min(age - (LIFE - END_DURATION), END_DURATION - 1)
        return END_FRAME_FIRST + math.floor(end_age / ANIM_TICK)
    end

    local loop_age = age - SPAWN_DURATION
    return LOOP_FRAME_FIRST + (math.floor(loop_age / ANIM_TICK) % LOOP_LENGTH)
end

-- РћР±СЉРµРєС‚ В«С‡С‘СЂРЅР°СЏ РґС‹СЂР°В»
local obj = Object.new("HungerHole")
obj:set_sprite(radiusSprite)
obj:set_depth(VISUAL_DEPTH)
Callback.add(obj.on_create, function(self)
    self.life = LIFE
    self.age = 0
    self.radius = PULL_RADIUS
    self.team = 1
    self.speed = HOLE_SPEED          -- РґРІРёР¶РµРЅРёРµ РІРїРµСЂС‘Рґ; РЅР°РїСЂР°РІР»РµРЅРёРµ Р·Р°РґР°С‘С‚СЃСЏ РІ onUse / СЃРёРЅРєРµ
    self.mask_index = gm.constants.sSinglePixel
    self.depth = VISUAL_DEPTH
    self.image_speed = 0
    self.image_index = visual_frame_for(self.age)
    self.image_xscale = RADIUS_SCALE
    self.image_yscale = RADIUS_SCALE
    self:projectile_sync(10)         -- РґРІРёРіР°СЋС‰РёР№СЃСЏ РѕР±СЉРµРєС‚ в†’ СЃРёРЅРєР°РµРј РїРѕР·РёС†РёСЋ/РЅР°РїСЂР°РІР»РµРЅРёРµ
end)

Callback.add(obj.on_step, function(self)
    self.depth = VISUAL_DEPTH
    self.image_index = visual_frame_for(self.age)
    self.age = (self.age or 0) + 1

    -- РџСЂРёС‚СЏР¶РµРЅРёРµ СЃС‡РёС‚Р°РµС‚ С…РѕСЃС‚ (Р°РІС‚РѕСЂРёС‚РµС‚ РїРѕ РїРѕР·РёС†РёСЏРј РІСЂР°РіРѕРІ); РєР»РёРµРЅС‚Р°Рј РїСЂРёР»РµС‚Р°РµС‚ СЃРёРЅРє
    if Net.client then return end

    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    -- Р’СЂР°РіРё = РїСЂРѕС‚РёРІРѕРїРѕР»РѕР¶РЅР°СЏ РєРѕРјР°РЅРґР° РІР»Р°РґРµР»СЊС†Р° (РєР°Рє РІ Totemetry/DeepcoreGK2)
    local enemy_team = self.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(self.x, self.y, self.radius, false, enemy_team, true))
    for _, target in ipairs(found) do
        -- Р‘РѕСЃСЃРѕРІ РЅРµ С‚СЏРЅРµРј (РёРјРјСѓРЅРёС‚РµС‚); РЅРµРѕСЃСЏР·Р°РµРјС‹С… РїСЂРѕРїСѓСЃРєР°РµРј. GM.actor_is_boss Р·Р°С‰РёС‰Р°РµРј
        -- РїСЂРѕРІРµСЂРєРѕР№ РЅР° СЃСѓС‰РµСЃС‚РІРѕРІР°РЅРёРµ (uppercase-РїСЂРѕРєСЃРё РјРѕР¶РµС‚ РІРµСЂРЅСѓС‚СЊ 0.0 вЂ” РѕР±РѕСЂР°С‡РёРІР°РµРј РІ truthy).
        local is_boss = GM.actor_is_boss and truthy(GM.actor_is_boss(target))
        if not is_boss and not truthy(target.intangible) then
            local lastx, lasty = target.x, target.y
            local dist = gm.point_distance(self.x, self.y, target.x, target.y)
            -- РћС‡РµРЅСЊ СЃРёР»СЊРЅРѕРµ РІС‚СЏРіРёРІР°РЅРёРµ Рє С†РµРЅС‚СЂСѓ: РєРІР°РґСЂР°С‚РёС‡РЅС‹Р№ СЂР°Р·РіРѕРЅ РѕС‚ PULL_STRENGTH_MIN РґРѕ PULL_STRENGTH_MAX.
            local t = 1 - math.min(dist / self.radius, 1)   -- 0 РЅР° РєСЂР°СЋ, 1 РІ С†РµРЅС‚СЂРµ
            local strength = PULL_STRENGTH_MIN + (PULL_STRENGTH_MAX - PULL_STRENGTH_MIN) * t * t
            local d = gm.point_direction(self.x, self.y, target.x, target.y)
            target.x = target.x - math.cos(math.rad(d)) * strength
            target.y = target.y + math.sin(math.rad(d)) * strength
            -- Р—Р°С‰РёС‚Р° РѕС‚ РїСЂРѕСЃРєРѕРєР° С†РµРЅС‚СЂР° РїРѕ РѕР±РµРёРј РѕСЃСЏРј
            if lastx < self.x and target.x >= self.x then target.x = math.min(target.x, self.x)
            elseif lastx > self.x and target.x <= self.x then target.x = math.max(target.x, self.x) end
            if lasty < self.y and target.y >= self.y then target.y = math.min(target.y, self.y)
            elseif lasty > self.y and target.y <= self.y then target.y = math.max(target.y, self.y) end
        end
    end
end)

-- РЎРµС‚СЊ: РїРµСЂРµРЅРѕСЃРёРј РЅР°РїСЂР°РІР»РµРЅРёРµ РїРѕР»С‘С‚Р° (СЃРєРѕСЂРѕСЃС‚СЊ РѕРґРёРЅР°РєРѕРІР°СЏ РЅР° РІСЃРµС… РєР»РёРµРЅС‚Р°С…).
Object.add_serializers(obj, function(self, buffer)
    gm.write_direction(self.direction or 0)
end, function(self, buffer)
    self.direction = gm.read_direction()
    self.speed = HOLE_SPEED
end)

Callback.add(obj.on_destroy, function(self)
    self:instance_destroy_sync()
end)

-- РЎРЅР°СЂСЏР¶РµРЅРёРµ
local equip = Equipment.new("Hunger")
equip:set_sprite(sprite)
equip.loot_tags = Item.LootTag.CATEGORY_UTILITY
equip.cooldown = COOLDOWN * 60

Callback.add(equip.on_use, function(actor)
    actor:sound_play(HungerSpawn, 1.0, 1.0)
    -- Р”С‹СЂР° РїРѕСЏРІР»СЏРµС‚СЃСЏ С‡СѓС‚СЊ РІРїРµСЂРµРґРё РёРіСЂРѕРєР° Рё РјРµРґР»РµРЅРЅРѕ Р»РµС‚РёС‚ РІРїРµСЂС‘Рґ РїРѕ РЅР°РїСЂР°РІР»РµРЅРёСЋ Р·Р°РїСѓСЃРєР°.
    local dir = (actor.image_xscale >= 0) and 0 or 180   -- РїРѕ РЅР°РїСЂР°РІР»РµРЅРёСЋ РІР·РіР»СЏРґР° РёРіСЂРѕРєР°
    local hole = obj:create(actor.x + actor.image_xscale * 48, actor.y - 16)
    hole.team = actor.team
    hole.direction = dir
    hole.speed = HOLE_SPEED
end)
