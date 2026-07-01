-- DeerItems-RiftBeacon / «Маяк разлома» / "Rift Beacon"
-- Падение ниже 25% HP даёт барьер и на 8с открывает разлом вокруг игрока: враги получают урон
-- и периодически выбрасываются прочь. Любое убийство при активном разломе продлевает его на 1с.
-- Срабатывает раз за этап (перезаряжается в начале нового этапа).

local sprite = Resources.sprite_load("DeerItems", "item/RiftBeacon", PATH.."assets/sprites/items/sRedItems/RiftBeacon.png", 1, 16, 16)

local GUID = _ENV["!guid"]
local RIFT_COLOR = Color(0x9b4dff)

local function truthy(v) return v ~= nil and v ~= false and v ~= 0 end

-- ── Баланс ──
local HP_THRESHOLD = 0.25
local BARRIER_FRAC = 0.25
local LIFE_BASE    = 8 * 60
local LIFE_MAX     = 16 * 60     -- потолок продления убийствами
local RADIUS       = 250
local DMG_TICK     = 30          -- урон раз в 0.5с
local DMG_BASE     = 0.5         -- 50% урона за тик
local DMG_STACK    = 0.1
local TP_TICK      = 60          -- выброс раз в 1с
local TP_DIST      = 250

-- Объект разлома (центрируется на игроке)
local obj = Object.new("DeerItems", "RiftZone")
obj:set_depth(40)
obj:clear_callbacks()

obj:onCreate(function(self)
    self.life = LIFE_BASE
    self.dt = 0
    self.tt = 0
    self:projectile_sync(4)   -- синкаем позицию клиентам (объект следует за игроком на хосте)
end)

obj:onStep(function(self)
    -- Логика и движение — только на хосте (parent хранится локально у хоста); клиентам
    -- позиция приходит через projectile_sync, а круг рисует onDraw.
    if gm._mod_net_isClient() then return end
    local data = self:get_data(nil, GUID)
    local parent = data.parent
    if not parent or not parent:exists() then self:destroy(); return end
    -- следуем за игроком
    self.x = parent.x
    self.y = parent.y

    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    local stack = data.stack or 1

    -- Урон по области раз в 0.5с
    self.dt = self.dt + 1
    if self.dt >= DMG_TICK then
        self.dt = 0
        local coef = DMG_BASE + DMG_STACK * (stack - 1)
        local atk = parent:fire_explosion(self.x, self.y, RADIUS, RADIUS, coef, nil, nil, false)
        if atk and atk.attack_info then
            atk.attack_info.proc = false
            atk.attack_info:set_critical(false)
        end
    end

    -- Выброс врагов прочь раз в 1с (боссов не трогаем)
    self.tt = self.tt + 1
    if self.tt >= TP_TICK then
        self.tt = 0
        local enemy_team = parent.team == 1 and 2 or 1
        local found = List.wrap(self:find_characters_circle(self.x, self.y, RADIUS, false, enemy_team, true))
        for _, e in ipairs(found) do
            if Instance.exists(e) and not (GM.actor_is_boss and truthy(GM.actor_is_boss(e))) then
                local rad = math.rad(gm.point_direction(self.x, self.y, e.x, e.y))
                e.x = self.x + math.cos(rad) * TP_DIST
                e.y = self.y - math.sin(rad) * TP_DIST   -- GM: ось Y инвертирована (lengthdir_y)
            end
        end
    end
end)

obj:onDraw(function(self)
    gm.draw_set_colour(RIFT_COLOR)
    gm.draw_circle(self.x, self.y, RADIUS, true)
    gm.draw_circle(self.x, self.y, RADIUS * 0.6, true)
end)

obj:onDestroy(function(self)
    self:instance_destroy_sync()
end)

local item = Item.new("DeerItems", "RiftBeacon")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

-- Триггер по низкому HP (раз за этап)
item:onPostStep(function(actor, stack)
    if gm._mod_net_isClient() then return end
    if stack <= 0 then return end
    local data = actor:get_data("RiftBeacon", GUID)
    if data.used then return end
    if not actor.maxhp or actor.maxhp <= 0 then return end
    if (actor.hp / actor.maxhp) >= HP_THRESHOLD then return end

    data.used = true
    actor:add_barrier(actor.maxhp * BARRIER_FRAC)

    local inst = obj:create(actor.x, actor.y)
    local idata = inst:get_data(nil, GUID)
    idata.parent = actor
    idata.stack = stack
    data.zone = inst
end)

-- Любое убийство при активном разломе продлевает его на 1с
item:onKillProc(function(actor, victim, stack)
    local data = actor:get_data("RiftBeacon", GUID)
    local z = data.zone
    if z and z:exists() then
        z.life = math.min(LIFE_MAX, (z.life or 0) + 60)
    end
end)

-- Перезаряд в начале этапа
item:onStageStart(function(actor, stack)
    local data = actor:get_data("RiftBeacon", GUID)
    data.used = false
    data.zone = nil
end)
