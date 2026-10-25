-- DeerItems-ShieldGenerator
-- Даёт щит покупаемым союзным дронам.

local sprite = Sprite.new("item/ShieldGenerator", PATH.."assets/sprites/items/sWhiteItems/ShieldGenerator.png", 1, 16, 16)

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

local item = Item.new("ShieldGenerator")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
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
            local stack = player:item_count(item) or 0
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

DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    refresh_team_stacks()
    recalculate_drones(actor)
end)

-- onRemove приходит до изменения инвентаря, поэтому пересчёт переносим на следующий onStep.
DeerItemsCallbacks.item_removed(item, function(actor, stack)
    pending_recalculate[actor.id] = actor
end)

DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    local changed = refresh_team_stacks()
    if changed then
        recalculate_drones(actor)
        return
    end

    local data = Instance.get_data(actor, "ShieldGenerator", GUID)
    data.sg_tick = (data.sg_tick or 0) + 1
    if data.sg_tick >= COUNT_PERIOD then
        data.sg_tick = 0
        recalculate_drones(actor)
    end
end)

Callback.add(Callback.ON_STEP, function()
    for id, actor in pairs(pending_recalculate) do
        pending_recalculate[id] = nil
        if Instance.exists(actor) then
            refresh_team_stacks()
            recalculate_drones(actor)
        end
    end
end)

-- Ванильные дроны не вызывают item:onStatRecalc владельца, поэтому щит вешаем
-- на их собственный пересчёт. Только через api: post-хук дописывал maxshield после
-- того, как ваниль уже обрезала shield до maxshield без бонуса (recalculate_stats.gml:107),
-- и щит дрона каждые COUNT_PERIOD кадров обнулялся и перезаливался со звуком wShield.
-- Прирост щита при подборе ваниль выдаёт сама той же строкой.
RecalculateStats.add(function(actor, api)
    if not is_drone(actor) then return end

    refresh_team_stacks()
    local stack = team_stacks[actor.team] or 0
    if stack <= 0 then return end

    api.maxshield_add(actor.maxhp * DRONE_SHIELD_PER_STACK * stack)
end)
