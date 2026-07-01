-- DeerItems-Golemshot / «Големострел» / "Golemshot"
-- Активация любого интерактива (сундук, магазин, алтарь, бочка) разворачивает турель на 30с,
-- которая бьёт ближайших врагов в радиусе ~250. Одновременно не больше stack турелей.

local sprite       = Resources.sprite_load("DeerItems", "item/Golemshot", PATH.."assets/sprites/items/sGreenItems/Golemshot.png", 1, 16, 16)
local turretSprite = Resources.sprite_load("DeerItems", "object/Golemshot", PATH.."assets/sprites/particle/Golemshot.png", 1, 16, 16)

local GUID  = _ENV["!guid"]
local BLEND = Color(0x7fd5a0)

-- ── Баланс ──
local LIFE      = 30 * 60   -- время жизни турели 30с
local FIRE_RATE = 45        -- выстрел раз в 0.75с
local RANGE     = 250       -- радиус поражения
local DMG_BASE  = 1.0       -- 100% урона
local DMG_STACK = 0.5       -- +50% за стак

-- Объект турели: статичный, host-авторитетный (как тотем Totemetry)
local obj = Object.new("DeerItems", "Golemshot")
obj:set_sprite(turretSprite)
obj:set_depth(2)
obj:clear_callbacks()

obj:onCreate(function(self)
    self.life = LIFE
    self:instance_sync()
end)

obj:onStep(function(self)
    if gm._mod_net_isClient() then return end
    local data   = self:get_data(nil, GUID)
    local parent = data.parent

    self.life = self.life - 1
    if self.life <= 0 or not parent or not parent:exists() then
        self:destroy()
        return
    end

    data.charge = (data.charge or 0) + 1
    if data.charge < FIRE_RATE then return end
    data.charge = 0

    local stack = data.stack or 1
    local enemy_team = parent.team == 1 and 2 or 1
    local found = List.wrap(self:find_characters_circle(self.x, self.y, RANGE, false, enemy_team, true))
    local target, best
    for _, e in ipairs(found) do
        if Instance.exists(e) then
            local d = gm.point_distance(self.x, self.y, e.x, e.y)
            if not best or d < best then best = d; target = e end
        end
    end
    if not (target and Instance.exists(target)) then return end

    self.image_xscale = (target.x < self.x) and -1 or 1

    local coef = DMG_BASE + DMG_STACK * (stack - 1)
    local dir  = gm.point_direction(self.x, self.y, target.x, target.y)
    local hit  = parent:fire_direct(target, coef, dir, self.x, self.y)
    if hit and hit.attack_info then
        hit.attack_info.proc = false   -- выстрел турели не прокает предметы владельца
        hit.attack_info:set_color(BLEND)
    end

    local efSparks = Object.find("ror-efSparks")
    if efSparks then
        local sp = efSparks:create(target.x, target.y)
        sp.sprite_index = gm.constants.sSparks1
        sp.image_blend = BLEND
    end
end)

obj:onDestroy(function(self)
    self:instance_destroy_sync()
end)

local item = Item.new("DeerItems", "Golemshot")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

-- При активации интерактива — спавним турель у этого объекта (не больше stack одновременно)
item:onInteractableActivate(function(actor, stack, interactable)
    if gm._mod_net_isClient() then return end
    local data = actor:get_data("Golemshot", GUID)
    if not data.turrets then data.turrets = {} end

    -- Чистим уничтоженные турели
    for i = #data.turrets, 1, -1 do
        local t = data.turrets[i]
        if not (t and t:exists()) then table.remove(data.turrets, i) end
    end
    if #data.turrets >= stack then return end

    local sx, sy = actor.x, actor.y
    if interactable and Instance.exists(interactable) then sx, sy = interactable.x, interactable.y end

    local inst  = obj:create(sx, sy)
    local idata = inst:get_data(nil, GUID)
    idata.parent = actor
    idata.stack  = stack
    table.insert(data.turrets, inst)
end)
