-- DeerItems-ShieldGenerator
-- Даёт щит покупаемым союзным дронам.

local sprite = Resources.sprite_load("DeerItems", "item/ShieldGenerator", PATH.."assets/sprites/items/sWhiteItems/ShieldGenerator.png", 1, 16, 16)

local GUID = _ENV["!guid"]
local oP = gm.constants.oP
local DRONE_SHIELD_PER_STACK = 0.10
local DRONE_RADIUS = 100000
local COUNT_PERIOD = 15

local function is_not_drone(actor)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(actor)
end

-- Тот же критерий, что уже используют HeavyLungs и GlassMagnifier.
local function is_drone(actor)
    return actor and actor.object_index ~= oP and not is_not_drone(actor)
end

local item = Item.new("DeerItems", "ShieldGenerator")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)
item:clear_callbacks()

local team_stacks = {}
local team_state_frame = -1
local pending_recalculate = {}

-- В коопе складываем предметы всех игроков команды, а не зависим от того,
-- чей item:onPostStep выполнился последним в кадре.
local function refresh_team_stacks()
    local frame = Global._current_frame or 0
    if team_state_frame == frame then return false end
    team_state_frame = frame

    local stacks = {}
    for _, player in ipairs(Instance.find_all(oP)) do
        if Instance.exists(player) then
            local stack = player:item_stack_count(item) or 0
            if stack > 0 then
                stacks[player.team] = (stacks[player.team] or 0) + stack
            end
        end
    end

    local changed = false
    for team, stack in pairs(stacks) do
        if team_stacks[team] ~= stack then changed = true end
    end
    for team in pairs(team_stacks) do
        if stacks[team] ~= team_stacks[team] then changed = true end
    end
    team_stacks = stacks
    return changed
end

local function recalculate_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, drone in ipairs(found) do
        if is_drone(drone) then
            drone:recalculate_stats()
        end
    end
end

item:onAcquire(function(actor, stack)
    refresh_team_stacks()
    recalculate_drones(actor)
end)

-- onRemove приходит до изменения инвентаря, поэтому пересчёт переносим на следующий onStep.
item:onRemove(function(actor, stack)
    pending_recalculate[actor.id] = actor
end)

item:onPostStep(function(actor, stack)
    local changed = refresh_team_stacks()
    if changed then
        recalculate_drones(actor)
        return
    end

    local data = actor:get_data("ShieldGenerator", GUID)
    data.sg_tick = (data.sg_tick or 0) + 1
    if data.sg_tick >= COUNT_PERIOD then
        data.sg_tick = 0
        recalculate_drones(actor)
    end
end)

Callback.add(Callback.TYPE.onStep, "DeerItems-ShieldGenerator-remove", function()
    for id, actor in pairs(pending_recalculate) do
        pending_recalculate[id] = nil
        if Instance.exists(actor) then
            refresh_team_stacks()
            recalculate_drones(actor)
        end
    end
end)

-- Ванильные дроны не вызывают item:onStatRecalc владельца, поэтому применяем
-- щит на их собственном пересчёте — тот же путь, что у HeavyLungs.
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if not is_drone(self) then return end

    refresh_team_stacks()
    local stack = team_stacks[self.team] or 0
    local data = Instance.wrap(self):get_data("ShieldGenerator", GUID)
    if stack <= 0 then
        data.sg_bonus = nil
        self.shield = math.min(self.shield or 0, self.maxshield or 0)
        return
    end

    local bonus = self.maxhp * DRONE_SHIELD_PER_STACK * stack
    self.maxshield = self.maxshield + bonus

    -- Выдаём только прирост нового бонуса: щит появляется сразу при подборе, но не
    -- восстанавливается полностью на каждом последующем пересчёте характеристик.
    local gained_bonus = math.max(0, bonus - (data.sg_bonus or 0))
    if gained_bonus > 0 then
        self.shield = math.min(self.maxshield, (self.shield or 0) + gained_bonus)
    end
    data.sg_bonus = bonus
end)
