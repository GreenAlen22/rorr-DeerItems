-- DeerItems-MagicMissile / "Magic Missile"
-- Using the primary skill spends one charge and fires a straight arrow in the owner's aim direction.
-- 300% damage (+100% per stack). 4 charges (+2 per stack), recharges 1 charge / 2.5s.
-- Arrow hits do not proc items and cannot trigger themselves.

local sprite = Resources.sprite_load("DeerItems", "item/MagicMissile", PATH.."assets/sprites/items/sGreenItems/MagicMissile.png", 1, 16, 16)
local arrowSprite = Resources.sprite_load("DeerItems", "particle/MagicMissileArrow", PATH.."assets/sprites/particle/MagicMissile.png", 5, 16, 16)
local MagicMissileHit = Resources.sfx_load("DeerItems", "sound/boom", PATH.."assets/sounds/MagicMissileHit.ogg")
local MagicMissileLaunch = Resources.sfx_load("DeerItems", "sound/launch", PATH.."assets/sounds/MagicMissileLaunch.ogg")

local GUID  = _ENV["!guid"]
local BLEND = Color(0xbfe3ff)

local ARROW_BASE  = 3.0
local ARROW_STACK = 1.0
local CAP_BASE   = 4
local CAP_STACK  = 2
local RECHARGE   = 150
local ARROW_SPEED = 14
local ARROW_LIFE  = 45
local HIT_RADIUS = 12

local arrow = Object.new("DeerItems", "MagicMissileArrow")
arrow:set_sprite(arrowSprite)
arrow:clear_callbacks()

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

    if gm._mod_net_isClient() then return end
    if not Instance.exists(self.parent) then self:destroy(); return end

    self.timer = self.timer + 1
    if self.timer >= ARROW_LIFE then self:destroy(); return end

    local enemy_team = self.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(self.x, self.y, HIT_RADIUS, false, enemy_team, true))
    for _, target in ipairs(found) do
        if Instance.exists(target) and self:attack_collision_canhit(target) then
            local hit = self.parent:fire_direct(target, self.dmg_coef, self.direction, self.x, self.y)
            if hit and hit.attack_info then
                hit.attack_info.proc = false
                hit.attack_info:set_color(BLEND)
            end

            local efSparks = Object.find("ror-efSparks")
            if efSparks then
                local sp = efSparks:create(target.x, target.y)
                sp.sprite_index = gm.constants.sSparks1
                sp.image_blend = BLEND
            end

            self:destroy()
            return
        end
    end
end)

arrow:onDestroy(function(self)
    if Instance.exists(self.parent) then
        self.parent:sound_play(MagicMissileHit, 1.0, 0.9 + math.random() * 0.4)
    end
    self:instance_destroy_sync()
end)

arrow:onSerialize(function(self, buffer)
    buffer:write_instance(self.parent)
    gm.write_direction(self.direction)
end)

arrow:onDeserialize(function(self, buffer)
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

local item = Item.new("DeerItems", "MagicMissile")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

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
    if not gm._mod_net_isHost() then return end
    local data = actor:get_data("MagicMissile", GUID)

    local cap = CAP_BASE + CAP_STACK * (stack - 1)
    if data.charges == nil then data.charges = cap end
    if data.charges <= 0 then return end

    data.charges = data.charges - 1

    local dir = aim_direction(actor)
    local missile = arrow:create(actor.x + gm.lengthdir_x(10, dir), actor.y - 12 + gm.lengthdir_y(10, dir))
    missile.parent = actor
    missile.team = actor.team
    missile.dmg_coef = ARROW_BASE + ARROW_STACK * (stack - 1)
    missile.direction = dir
    actor:sound_play(MagicMissileLaunch, 1.0, 0.9 + math.random() * 0.4)
end)
