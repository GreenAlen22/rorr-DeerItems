-- Shared ReturnsAPI registrations for item and buff callbacks that need stack filtering.
local M = {}

local function item_stack(actor, item)
    return actor:item_count(item, Item.StackKind.ANY) or 0
end

local function buff_stack(actor, buff)
    return actor:buff_count(buff) or 0
end

local function for_item_holders(item, fn)
    for _, actor in ipairs(item:get_holding_actors()) do
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack) end
    end
end

local function for_buff_holders(buff, fn)
    for _, actor in ipairs(buff:get_holding_actors()) do
        local stack = buff_stack(actor, buff)
        if stack > 0 then fn(actor, stack) end
    end
end

function M.item_acquired(item, fn) Callback.add(item.on_acquired, fn) end
function M.item_removed(item, fn) Callback.add(item.on_removed, fn) end

function M.item_stat_recalc(item, fn)
    RecalculateStats.add(function(actor)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack) end
    end)
end

function M.item_post_stat_recalc(item, fn)
    gm.post_script_hook(gm.constants.recalculate_stats, function(self)
        local actor = Instance.wrap(self)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack) end
    end)
end

function M.item_pre_step(item, fn) Callback.add(Callback.PRE_STEP, function() for_item_holders(item, fn) end) end
function M.item_post_step(item, fn) Callback.add(Callback.POST_STEP, function() for_item_holders(item, fn) end) end
function M.item_post_draw(item, fn) Callback.add(Callback.ON_DRAW, function() for_item_holders(item, fn) end) end
function M.item_stage_start(item, fn) Callback.add(Callback.ON_STAGE_START, function() for_item_holders(item, fn) end) end

function M.item_hit_proc(item, fn)
    Callback.add(Callback.ON_HIT_PROC, function(actor, victim, hit_info)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, victim, stack, hit_info) end
    end)
end

function M.item_damaged_proc(item, fn)
    Callback.add(Callback.ON_DAMAGED_PROC, function(actor, hit_info)
        local stack = item_stack(actor, item)
        local attack_info = hit_info and hit_info.attack_info
        if stack > 0 then fn(actor, attack_info and attack_info.parent, stack, hit_info) end
    end)
end

function M.item_kill_proc(item, fn)
    Callback.add(Callback.ON_KILL_PROC, function(victim, actor)
        if not actor then return end
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, victim, stack) end
    end)
end

function M.item_attack_create(item, fn)
    Callback.add(Callback.ON_ATTACK_CREATE, function(attack_info)
        local actor = attack_info.parent
        local stack = actor and item_stack(actor, item) or 0
        if stack > 0 then fn(actor, stack, attack_info) end
    end)
end

function M.item_attack_hit(item, fn)
    Callback.add(Callback.ON_ATTACK_HIT, function(hit_info)
        local attack_info = hit_info and hit_info.attack_info
        if not attack_info then return end
        local actor = attack_info.parent
        local stack = actor and item_stack(actor, item) or 0
        if stack > 0 then fn(actor, hit_info.target, stack, attack_info) end
    end)
end

function M.item_equipment_use(item, fn)
    Callback.add(Callback.ON_EQUIPMENT_USE, function(actor, equipment)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack, equipment) end
    end)
end

function M.item_interactable_activate(item, fn)
    Callback.add(Callback.ON_INTERACTABLE_ACTIVATE, function(interactable, actor)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack, interactable) end
    end)
end

function M.item_pickup_collected(item, fn)
    Callback.add(Callback.ON_PICKUP_COLLECTED, function(pickup, actor)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack, pickup) end
    end)
end

local function item_skill_use(item, slot, fn)
    Callback.add(Callback.ON_SKILL_ACTIVATE, function(actor, used_slot)
        if used_slot ~= slot then return end
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack, actor:get_active_skill(slot)) end
    end)
end

function M.item_primary_use(item, fn) item_skill_use(item, Skill.Slot.PRIMARY, fn) end
function M.item_secondary_use(item, fn) item_skill_use(item, Skill.Slot.SECONDARY, fn) end
function M.item_utility_use(item, fn) item_skill_use(item, Skill.Slot.UTILITY, fn) end
function M.item_special_use(item, fn) item_skill_use(item, Skill.Slot.SPECIAL, fn) end

function M.buff_apply(buff, fn)
    Callback.add(buff.on_apply, function(actor) fn(actor, buff_stack(actor, buff)) end)
end

function M.buff_remove(buff, fn)
    Callback.add(buff.on_remove, function(actor) fn(actor, 0) end)
end

function M.buff_post_step(buff, fn) Callback.add(Callback.POST_STEP, function() for_buff_holders(buff, fn) end) end
function M.buff_post_draw(buff, fn) Callback.add(Callback.ON_DRAW, function() for_buff_holders(buff, fn) end) end

function M.buff_stat_recalc(buff, fn)
    RecalculateStats.add(function(actor)
        local stack = buff_stack(actor, buff)
        if stack > 0 then fn(actor, stack) end
    end)
end

DeerItemsCallbacks = M
return M
