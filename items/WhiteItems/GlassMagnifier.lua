-- DeerItems-GlassMagnifier
-- Increases drone base damage.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/GlassMagnifier", PATH.."assets/sprites/items/sWhiteItems/GlassMagnifier.png", 1, 16, 16)

local GUID = _ENV["!guid"]
local oP = gm.constants.oP

local DRONE_DMG_BASE = 1
local DRONE_DMG_STACK = 3
local DRONE_RADIUS = 100000

local g_team_stack = {}
local team_state_frame = -1
local pending_recalculate = {}

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

local function recalc_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP and not is_not_drone(char) then
            char:recalculate_stats()
        end
    end
end

-- Создание нового предмета с названием "GlassMagnifier" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "GlassMagnifier")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

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
        if g_team_stack[team] ~= stack then changed = true end
    end
    for team in pairs(g_team_stack) do
        if stacks[team] ~= g_team_stack[team] then changed = true end
    end
    g_team_stack = stacks
    return changed
end

-- Keep owner stacks available for drone stat recalculation.
item:onStatRecalc(function(actor, stack)
    refresh_team_stacks()
end)

item:onAcquire(function(actor, stack)
    refresh_team_stacks()
    recalc_drones(actor)
end)

item:onRemove(function(actor, stack)
    pending_recalculate[actor.id] = actor
end)

item:onPostStep(function(actor, stack)
    local changed = refresh_team_stacks()
    if changed then
        recalc_drones(actor)
        return
    end
    if stack <= 0 then return end

    local data = actor:get_data("GlassMagnifier", GUID)
    local team_stack = g_team_stack[actor.team] or 0
    if data.gm_last_stack ~= team_stack then
        data.gm_last_stack = team_stack
        recalc_drones(actor)
    end
end)

Callback.add(Callback.TYPE.onStep, "DeerItems-GlassMagnifier-remove", function()
    for id, actor in pairs(pending_recalculate) do
        pending_recalculate[id] = nil
        if Instance.exists(actor) then
            refresh_team_stacks()
            recalc_drones(actor)
        end
    end
end)

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end
    if is_not_drone(self) then return end
    refresh_team_stacks()
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end
    self.damage = self.damage + DRONE_DMG_BASE + DRONE_DMG_STACK * s
end)
