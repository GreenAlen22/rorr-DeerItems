-- DeerItems-MagicMissile / В«РњР°РіРёС‡РµСЃРєР°СЏ СЃС‚СЂРµР»Р°В» / "Magic Missile"
-- РћСЃРЅРѕРІРЅРѕРµ СѓРјРµРЅРёРµ С‚СЂР°С‚РёС‚ РѕРґРёРЅ Р·Р°СЂСЏРґ Рё РІС‹РїСѓСЃРєР°РµС‚ СЃС‚СЂРµР»Сѓ РІ РЅР°РїСЂР°РІР»РµРЅРёРё РїСЂРёС†РµР»Р° РІР»Р°РґРµР»СЊС†Р°.
-- РЈСЂРѕРЅ 120% (+60% Р·Р° СЃС‚Р°Рє). Р§РµС‚С‹СЂРµ Р·Р°СЂСЏРґР° (+2 Р·Р° СЃС‚Р°Рє), РѕРґРёРЅ РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµС‚СЃСЏ Р·Р° 2,5 СЃРµРєСѓРЅРґС‹.
-- РЎС‚СЂРµР»Р° РїСЂРѕРЅР·Р°РµС‚ РґРѕ С‡РµС‚С‹СЂС‘С… СЂР°Р·РЅС‹С… РІСЂР°РіРѕРІ. Р•С‘ РїРѕРїР°РґР°РЅРёСЏ РЅРµ РІС‹Р·С‹РІР°СЋС‚ РїСЂРµРґРјРµС‚С‹ Рё РЅРµ РјРѕРіСѓС‚ Р·Р°РїСѓСЃС‚РёС‚СЊ СЃРµР±СЏ.

local sprite = Sprite.new("item/MagicMissile", PATH.."assets/sprites/items/sGreenItems/MagicMissile.png", 1, 16, 16)
local arrowSprite = Sprite.new("particle/MagicMissileArrow", PATH.."assets/sprites/particle/MagicMissile.png", 5, 16, 16)
local MagicMissileHit = Sound.new("sound/boom", PATH.."assets/sounds/MagicMissileHit.ogg")
local MagicMissileLaunch = Sound.new("sound/launch", PATH.."assets/sounds/MagicMissileLaunch.ogg")

local GUID  = _ENV["!guid"]
local BLEND = Color(0xbfe3ff)

local ARROW_BASE  = 1.2
local ARROW_STACK = 0.6
local CAP_BASE   = 4
local CAP_STACK  = 2
local RECHARGE   = 150
local ARROW_SPEED = 14
local ARROW_LIFE  = 45
local HIT_RADIUS = 12
local PIERCE_TARGETS = 4

local arrow = Object.new("MagicMissileArrow")
arrow:set_sprite(arrowSprite)
arrow:onCreate(function(self)
    self.timer = 0
    self.speed = ARROW_SPEED
    self.direction = 0
    self.parent = -4
    self.team = 1
    self.dmg_coef = ARROW_BASE
    self.mask_index = gm.constants.sSinglePixel
    self:projectile_sync(8)
end)

arrow:onStep(function(self)
    self.image_angle = self.direction

    if Net.client then return end
    if not Instance.exists(self.parent) then self:destroy(); return end

    self.timer = self.timer + 1
    if self.timer >= ARROW_LIFE then self:destroy(); return end

    local enemy_team = self.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(self.x, self.y, HIT_RADIUS, false, enemy_team, true))
    local data = self:get_data("MagicMissile", GUID)
    if not data.hit_targets then data.hit_targets = {} end
    data.pierce_count = data.pierce_count or 0

    for _, target in ipairs(found) do
        if Instance.exists(target) and not data.hit_targets[target.id] and self:attack_collision_canhit(target) then
            data.hit_targets[target.id] = true
            data.pierce_count = data.pierce_count + 1

            local hit = self.parent:fire_direct(target, self.dmg_coef, self.direction, self.x, self.y)
            if hit and hit.attack_info then
                hit.attack_info.proc = false
                hit.attack_info:set_color(BLEND)
            end

            local efSparks = Object.find("efSparks", "ror")
            if efSparks then
                local sp = efSparks:create(target.x, target.y)
                sp.sprite_index = gm.constants.sSparks1
                sp.image_blend = BLEND
            end

            if data.pierce_count >= PIERCE_TARGETS then
                self:destroy()
                return
            end
        end
    end
end)

arrow:onDestroy(function(self)
    if Instance.exists(self.parent) then
        self.parent:sound_play(MagicMissileHit, 1.0, 0.9 + math.random() * 0.4)
    end
    self:instance_destroy_sync()
end)

Object.add_serializers(arrow, function(self, buffer)
    buffer:write_instance(self.parent)
    gm.write_direction(self.direction)
end, function(self, buffer)
    self.parent = buffer:read_instance()
    if Instance.exists(self.parent) then self.team = self.parent.team end
    self.direction = gm.read_direction()
end)

local function aim_direction(actor)
    if actor.skill_util_facing_direction then
        return actor:skill_util_facing_direction()
    end
    return (actor.image_xscale or 1) >= 0 and 0 or 180
end

local item = Item.new("MagicMissile")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
item:onPostStep(function(actor, stack)
    local data = actor:get_data("MagicMissile", GUID)
    local cap = CAP_BASE + CAP_STACK * (stack - 1)
    if data.charges == nil then data.charges = cap end
    if data.charges > cap then data.charges = cap end
    if data.charges < cap then
        data.rc = (data.rc or 0) + 1
        if data.rc >= RECHARGE then
            data.rc = 0
            data.charges = data.charges + 1
        end
    else
        data.rc = 0
    end
end)

item:onPrimaryUse(function(actor, stack, active_skill)
    if not Net.host then return end
    local data = actor:get_data("MagicMissile", GUID)

    local cap = CAP_BASE + CAP_STACK * (stack - 1)
    if data.charges == nil then data.charges = cap end
    if data.charges <= 0 then return end

    data.charges = data.charges - 1

    actor:sound_play(MagicMissileLaunch, 1.0, 0.9 + math.random() * 0.4)
    local dir = aim_direction(actor)
    local missile = arrow:create(actor.x + gm.lengthdir_x(10, dir), actor.y - 12 + gm.lengthdir_y(10, dir))
    missile.parent = actor
    missile.team = actor.team
    missile.dmg_coef = ARROW_BASE + ARROW_STACK * (stack - 1)
    missile.direction = dir
end)
