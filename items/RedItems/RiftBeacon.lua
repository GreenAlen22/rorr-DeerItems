-- DeerItems-RiftBeacon / «Маяк разлома» / "Rift Beacon"
-- Падение ниже 25% HP даёт барьер и на 8с открывает разлом вокруг игрока: враги
-- периодически выбрасываются прочь. Любое убийство при активном разломе продлевает его на 1с.
-- После срабатывания ломается и чинится в начале нового этапа.

local sprite = Sprite.new("item/RiftBeacon", PATH.."assets/sprites/items/sRedItems/RiftBeacon.png", 1, 18, 18)
local radiusSprite = Sprite.new("particle/RiftBeaconRadius", PATH.."assets/sprites/particle/RiftBeaconRadius.png", 26, 64, 64)

local GUID = _ENV["!guid"]
local RIFT_COLOR = Color(0x9b4dff)
local deactivate

local function truthy(v) return v ~= nil and v ~= false and v ~= 0 end

-- Настройки баланса
local HP_THRESHOLD = 0.25
local BARRIER_FRAC = 0.25
local LIFE_BASE    = 8 * 60
local LIFE_MAX     = 16 * 60     -- потолок продления убийствами
local RADIUS       = 250
local TP_TICK      = 60          -- выброс раз в 1с
local TP_DIST      = 250
local NET_ACTOR_TELEPORT = 47    -- ids.tsv: net 47 actor_teleport

local RADIUS_SPRITE_SIZE = 128
local RADIUS_SPRITE_SCALE = (RADIUS * 1.2) / RADIUS_SPRITE_SIZE
local RADIUS_ANIM_TICK = 4
local RADIUS_EDGE_FIRST = 0
local RADIUS_EDGE_LAST = 8
local RADIUS_LOOP_FIRST = 9
local RADIUS_LOOP_LAST = 25
local RADIUS_EDGE_DURATION = (RADIUS_EDGE_LAST - RADIUS_EDGE_FIRST + 1) * RADIUS_ANIM_TICK
local RADIUS_LOOP_LENGTH = RADIUS_LOOP_LAST - RADIUS_LOOP_FIRST + 1

local function actor_exists(actor)
    return actor and Instance.exists(actor)
end

local function is_boss(actor)
    return actor_exists(actor) and GM.actor_is_boss and truthy(GM.actor_is_boss(actor))
end

local function can_displace(actor)
    if not actor_exists(actor) then return false end
    if is_boss(actor) or truthy(actor.intangible) then return false end
    if actor.hp and actor.hp <= 0 then return false end
    return true
end

local function displace_from_rift(actor, x, y)
    local dir = gm.point_direction(x, y, actor.x, actor.y)
    local tx = x + math.cos(math.rad(dir)) * TP_DIST
    local ty = y - math.sin(math.rad(dir)) * TP_DIST

    if not GM.teleport_nearby then return end
    GM.teleport_nearby(actor, tx, ty)

    actor.pHspeed = 0
    actor.pVspeed = 0
    actor.ghost_x = actor.x
    actor.ghost_y = actor.y
    -- teleport_nearby двигает только у хоста; ваниль после него шлёт actor_teleport
    -- (scr_skills_enemy_imp.gml), иначе у клиента враг так и стоит в разломе.
    actor:net_send_instance_message(NET_ACTOR_TELEPORT)
end

local function radius_frame_for(self)
    local age = math.max(self.age or 0, 0)

    if age < RADIUS_EDGE_DURATION then
        return RADIUS_EDGE_FIRST + math.floor(age / RADIUS_ANIM_TICK)
    end

    if (self.life or 0) <= 0 then
        local end_age = math.min(self.end_age or 0, RADIUS_EDGE_DURATION - 1)
        return RADIUS_EDGE_FIRST + math.floor(end_age / RADIUS_ANIM_TICK)
    end

    local loop_age = age - RADIUS_EDGE_DURATION
    return RADIUS_LOOP_FIRST + (math.floor(loop_age / RADIUS_ANIM_TICK) % RADIUS_LOOP_LENGTH)
end

-- Объект разлома (центрируется на игроке)
local obj = Object.new("RiftZone")
obj:set_depth(40)
Callback.add(obj.on_create, function(self)
    self.life = LIFE_BASE
    self.age = 0
    self.end_age = nil
    self.radius_frame = 0
    self.tt = 0
    self:projectile_sync(4)   -- синкаем позицию клиентам (объект следует за игроком на хосте)
end)

Callback.add(obj.on_step, function(self)
    self.age = (self.age or 0) + 1
    self.radius_frame = radius_frame_for(self)

    -- Логика и движение — только на хосте (parent хранится локально у хоста); клиентам
    -- позиция приходит через projectile_sync, а круг рисует onDraw.
    if Net.client then return end
    local data = Instance.get_data(self, nil, GUID)
    local parent = data.parent
    if not Instance.exists(parent) then self:destroy(); return end
    -- следуем за игроком
    self.x = parent.x
    self.y = parent.y

    if self.life <= 0 then
        self.end_age = (self.end_age or 0) + 1
        if self.end_age >= RADIUS_EDGE_DURATION then self:destroy() end
        return
    end

    self.life = self.life - 1

    -- Выброс врагов прочь раз в 1с (боссов не трогаем)
    self.tt = self.tt + 1
    if self.tt >= TP_TICK then
        self.tt = 0
        local enemy_team = parent.team == 1 and 2 or 1
        local found = List.wrap(self:find_characters_circle(self.x, self.y, RADIUS, false, enemy_team, true))
        for _, e in ipairs(found) do
            if can_displace(e) then
                displace_from_rift(e, self.x, self.y)
            end
        end
    end
end)

Object.add_serializers(obj, function(self, buffer)
    buffer:write_byte(self.radius_frame or 0)
end, function(self, buffer)
    self.radius_frame = buffer:read_byte()
end)

Callback.add(obj.on_draw, function(self)
    gm.draw_set_colour(RIFT_COLOR)
    gm.draw_circle(self.x, self.y, RADIUS, true)
    gm.draw_sprite_ext(radiusSprite.value, self.radius_frame or radius_frame_for(self), self.x, self.y, RADIUS_SPRITE_SCALE, RADIUS_SPRITE_SCALE, 0, Color.WHITE, 1)
    gm.draw_set_colour(Color.WHITE)
end)

Callback.add(obj.on_destroy, function(self)
    self:instance_destroy_sync()
end)

local item = Item.new("RiftBeacon")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_HEALING
local function ready_stack_count(actor)
    return actor:item_count(item, Item.StackKind.NORMAL)
        + actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
end

local function break_item(actor)
    deactivate = deactivate or Item.find("RiftBeaconDeactivate", "DeerItems")

    local normal = actor:item_count(item, Item.StackKind.NORMAL)
    if normal > 0 then
        actor:item_take(item, 1)
        actor:item_give(deactivate, 1)
        return true
    end

    local temp = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
    if temp > 0 then
        actor:item_take(item, 1, Item.StackKind.TEMPORARY_BLUE)
        actor:item_give(deactivate, 1, Item.StackKind.TEMPORARY_BLUE)
        return true
    end

    return false
end

local function extend_zone(actor)
    local data = Instance.get_data(actor, "RiftBeacon", GUID)
    if data.last_extend_frame == Global._current_frame then return end

    local z = data.zone
    if Instance.exists(z) then
        data.last_extend_frame = Global._current_frame
        z.life = math.min(LIFE_MAX, (z.life or 0) + 60)
    end
end

-- Триггер по низкому HP (раз за этап)
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if Net.client then return end
    if stack <= 0 then return end
    local data = Instance.get_data(actor, "RiftBeacon", GUID)
    if not actor.maxhp or actor.maxhp <= 0 then return end
    if (actor.hp / actor.maxhp) >= HP_THRESHOLD then
        data.below_stack_gate = nil
        return
    end

    local ready = ready_stack_count(actor)
    if ready <= 0 then return end
    if data.below_stack_gate ~= nil and ready <= data.below_stack_gate then
        data.below_stack_gate = ready
        return
    end

    if not break_item(actor) then return end
    data.below_stack_gate = ready_stack_count(actor)
    actor:heal_barrier(actor.maxhp * BARRIER_FRAC)

    local inst = obj:create(actor.x, actor.y)
    local idata = Instance.get_data(inst, nil, GUID)
    idata.parent = actor
    data.zone = inst
end)

-- Любое убийство при активном разломе продлевает его на 1с
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if Net.client then return end

    extend_zone(actor)
end)

-- Перезаряд в начале этапа
DeerItemsCallbacks.item_stage_start(item, function(actor, stack)
    if Net.client then return end

    local data = Instance.get_data(actor, "RiftBeacon", GUID)
    data.below_stack_gate = nil
    data.last_extend_frame = nil
    data.zone = nil
end)
