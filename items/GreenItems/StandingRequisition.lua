-- DeerItems-StandingRequisition / "Standing Requisition"

local sprite = Resources.sprite_load("DeerItems", "item/StandingRequisition", PATH.."assets/sprites/items/sGreenItems/StandingRequisition.png", 1, 18, 18)

local CHEST_SPAWN_WEIGHT = 200
local CHEST_RECONCILE_DELAYS = { 8, 60 }

local item = Item.new("DeerItems", "StandingRequisition")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility, Item.LOOT_TAG.item_blacklist_engi_turrets)
item:clear_callbacks()

local stage_plans = {}
local reconcile_scheduled_frame = -1
local chest_api

local function load_chest_api()
    if chest_api then return chest_api end

    chest_api = _G.DeerItemsStandingRequisitionChest
    if type(chest_api) == "table" then return chest_api end

    for _, name in ipairs(path.get_files(PATH.."Interactables")) do
        if name:find("StandingRequisitionChest.lua", 1, true) then
            local ok, api = pcall(require, name)
            if not ok then error(api) end
            if type(api) == "table" then
                chest_api = api
            elseif type(_G.DeerItemsStandingRequisitionChest) == "table" then
                chest_api = _G.DeerItemsStandingRequisitionChest
            end
            break
        end
    end

    if type(chest_api) ~= "table" then
        error("StandingRequisitionChest API was not loaded")
    end

    return chest_api
end

local Chest = setmetatable({}, {
    __index = function(_, key)
        return load_chest_api()[key]
    end
})

local function roll_tier(stack)
    local n = math.max(1, stack or 1)
    local common_weight = 0.79
    local uncommon_weight = 0.2 * n
    local rare_weight = 0.01 * n * n
    local total = common_weight + uncommon_weight + rare_weight
    local r = math.random() * total

    if r < common_weight then return Item.TIER.common end
    if r < common_weight + uncommon_weight then return Item.TIER.uncommon end
    return Item.TIER.rare
end

local function is_excluded(value, exclude)
    if not exclude then return false end
    if type(exclude) ~= "table" then return value == exclude end

    for _, excluded in ipairs(exclude) do
        if value == excluded then return true end
    end
    return false
end

local function pick_item(tier, exclude)
    local items = Item.find_all(tier, Item.ARRAY.tier)
    local n = #items
    if n == 0 then return nil end
    for _ = 1, 25 do
        local it = items[gm.irandom_range(1, n)]
        if it and it:is_loot() and it:is_unlocked() and not is_excluded(it.value, exclude) then
            return it
        end
    end
    return nil
end

local function pick_item_with_fallback(tier, exclude)
    local it = pick_item(tier, exclude)
    if it then return it end

    for _, fallback_tier in ipairs({ Item.TIER.common, Item.TIER.uncommon, Item.TIER.rare }) do
        if fallback_tier ~= tier then
            it = pick_item(fallback_tier, exclude)
            if it then return it end
        end
    end

    return nil
end

local function pick_choices(stack)
    local a = pick_item_with_fallback(roll_tier(stack), { item.value })
    if not a then return nil end

    local b = pick_item_with_fallback(roll_tier(stack), { item.value, a.value })
    if not b then return nil end

    return a, b
end

local function collect_stage_plans()
    stage_plans = {}

    local players = Instance.find_all(gm.constants.oP)
    for _, actor in ipairs(players) do
        if Instance.exists(actor) then
            local stack = actor:item_stack_count(item) or 0
            if stack > 0 then
                local a, b = pick_choices(stack)
                if a and b then
                    stage_plans[#stage_plans + 1] = {
                        owner_id = actor.id,
                        stack = stack,
                        a = a.value,
                        b = b.value,
                        paid_tier = roll_tier(stack),
                        exclude_item = item.value,
                    }
                end
            end
        end
    end

    return #stage_plans
end

local function spawn_fallback_chest(plan, index)
    local owner = Instance.wrap(plan.owner_id)
    local x, y
    if Instance.exists(owner) then
        x = owner.x + gm.irandom_range(-160, 160)
        y = owner.y
    else
        x = 0 + index * 48
        y = 0
    end

    return Chest.create_at(x, y)
end

local function reconcile_chests()
    if gm._mod_net_isClient() then return end

    if #stage_plans == 0 then
        collect_stage_plans()
    end

    Chest.set_spawn_weight(0)

    local chests = Chest.get_instances()
    local by_owner = {}
    local free = {}

    for _, chest in ipairs(chests) do
        local owner_id = chest.sr_owner_id or -1
        if owner_id >= 0 and not by_owner[owner_id] then
            by_owner[owner_id] = chest
        else
            free[#free + 1] = chest
        end
    end

    local wanted_owner = {}
    for i, plan in ipairs(stage_plans) do
        wanted_owner[plan.owner_id] = true
        local chest = by_owner[plan.owner_id]
        if not chest then
            chest = table.remove(free, 1) or spawn_fallback_chest(plan, i)
            by_owner[plan.owner_id] = chest
        end
        if (chest.sr_chosen or 0) == 0
        and (
            (chest.sr_owner_id or -1) ~= plan.owner_id
            or (chest.sr_choice_a or -1) < 0
            or (chest.sr_choice_b or -1) < 0
        )
        then
            Chest.apply_plan(chest, plan)
        end
    end

    for owner_id, chest in pairs(by_owner) do
        if not wanted_owner[owner_id] and Instance.exists(chest) then
            chest:destroy()
        end
    end

    for _, chest in ipairs(free) do
        if Instance.exists(chest) then
            chest:destroy()
        end
    end
end

local function schedule_reconcile()
    local frame = Global._current_frame or 0
    if reconcile_scheduled_frame == frame then return end
    reconcile_scheduled_frame = frame
    for _, delay in ipairs(CHEST_RECONCILE_DELAYS) do
        Alarm.create(reconcile_chests, delay)
    end
end

gm.post_script_hook(gm.constants.run_create, function()
    Chest.register_for_all_stages()
end)

gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
    if gm._mod_net_isClient() then return end

    Chest.register_for_all_stages()

    local quota = collect_stage_plans()
    Chest.set_spawn_weight(quota > 0 and CHEST_SPAWN_WEIGHT or 0)

    if quota <= 0 then return end

    local stage = Stage.wrap(args[1].value)
    local added_points = quota * Chest.SPAWN_COST
    stage.interactable_spawn_points = stage.interactable_spawn_points + added_points

    Alarm.create(function()
        stage.interactable_spawn_points = stage.interactable_spawn_points - added_points
    end, 1)
end)

item:onStageStart(function()
    if gm._mod_net_isClient() then return end
    if #stage_plans == 0 then
        collect_stage_plans()
    end
    schedule_reconcile()
end)
