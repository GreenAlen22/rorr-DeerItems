-- Shared ReturnsAPI registrations for item and buff callbacks that need stack filtering.
local M = {}

local function item_stack(actor, item)
    return actor:item_count(item, Item.StackKind.ANY) or 0
end

-- Read the array, not actor:buff_count: the syncBuffStack receiver writes buff_stack
-- without resetting the buff_count cache, so a client keeps the old stack after the
-- host removes part of it (ReturnsAPI 0.1.58, Actor.lua:110-117).
local function buff_stack(actor, buff)
    local stacks = actor.buff_stack
    local id = buff.value
    if id >= #stacks then return 0 end
    return stacks:get(id) or 0
end

-- Instance.INVALID has no CInstance behind it: Wrap.unwrap returns the Lua table
-- itself, and Instance.exists would hand that table to the engine. ReturnsAPI
-- compares against INVALID instead (Console.lua:206). -4 is cut first as well:
-- rorr_cloding/knowledge/mechanics.md treats it as unsafe for exists.
local function alive(inst)
    return inst ~= nil and inst ~= -4 and inst ~= Instance.INVALID and Instance.exists(inst)
end

-- RoMT ran step and draw callbacks from step_actor/draw_actor, which skip dead and
-- invisible actors. ReturnsAPI keeps dead players among item and buff holders, and a
-- holder destroyed without dying stays in the list as INVALID until the room changes.
local function is_stepping(actor)
    return actor ~= Instance.INVALID and not Util.bool(actor.dead)
end

local function is_drawn(actor)
    return is_stepping(actor) and Util.bool(actor.visible)
end

local function for_item_holders(item, filter, fn)
    for _, actor in ipairs(item:get_holding_actors()) do
        if filter(actor) then
            local stack = item_stack(actor, item)
            if stack > 0 then fn(actor, stack) end
        end
    end
end

local function for_buff_holders(buff, filter, fn)
    for _, actor in ipairs(buff:get_holding_actors()) do
        if filter(actor) then
            local stack = buff_stack(actor, buff)
            if stack > 0 then fn(actor, stack) end
        end
    end
end

function M.item_acquired(item, fn) Callback.add(item.on_acquired, fn) end
function M.item_removed(item, fn) Callback.add(item.on_removed, fn) end

-- RecalculateStats runs before vanilla rebuilds the stats, so direct writes to actor
-- fields are overwritten. Stats change only through `api`.
function M.item_stat_recalc(item, fn)
    RecalculateStats.add(function(actor, api)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack, api) end
    end)
end

function M.item_pre_step(item, fn) Callback.add(Callback.PRE_STEP, function() for_item_holders(item, is_stepping, fn) end) end
function M.item_post_step(item, fn) Callback.add(Callback.POST_STEP, function() for_item_holders(item, is_stepping, fn) end) end
function M.item_post_draw(item, fn) Callback.add(Callback.ON_DRAW, function() for_item_holders(item, is_drawn, fn) end) end
function M.item_stage_start(item, fn) Callback.add(Callback.ON_STAGE_START, function() for_item_holders(item, is_stepping, fn) end) end

function M.item_hit_proc(item, fn)
    Callback.add(Callback.ON_HIT_PROC, function(actor, victim, hit_info)
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, victim, stack, hit_info) end
    end)
end

-- DoT ticks reach ON_DAMAGED_PROC through damage_inflict without attack_info,
-- so the attacker is the inflictor, as in RoMT. Damage without a source (falls,
-- lava, blood shrine) has inflictor = -4 and is passed on as a nil attacker.
function M.item_damaged_proc(item, fn)
    Callback.add(Callback.ON_DAMAGED_PROC, function(actor, hit_info)
        local stack = item_stack(actor, item)
        if stack <= 0 then return end
        local inflictor = hit_info.inflictor
        fn(actor, alive(inflictor) and Instance.wrap(inflictor) or nil, stack, hit_info)
    end)
end

function M.item_kill_proc(item, fn)
    Callback.add(Callback.ON_KILL_PROC, function(victim, actor)
        if not actor then return end
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, victim, stack) end
    end)
end

-- Attacks without a parent (Spite bombs, fire_explosion_noparent) carry parent = -4.
function M.item_attack_create(item, fn)
    Callback.add(Callback.ON_ATTACK_CREATE, function(attack_info)
        local actor = attack_info.parent
        if not alive(actor) then return end
        local stack = item_stack(actor, item)
        if stack > 0 then fn(actor, stack, attack_info) end
    end)
end

function M.item_attack_hit(item, fn)
    Callback.add(Callback.ON_ATTACK_HIT, function(hit_info)
        local attack_info = hit_info and hit_info.attack_info
        if not attack_info then return end
        local actor = attack_info.parent
        if not alive(actor) then return end
        local stack = item_stack(actor, item)
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

function M.buff_post_step(buff, fn) Callback.add(Callback.POST_STEP, function() for_buff_holders(buff, is_stepping, fn) end) end
function M.buff_post_draw(buff, fn) Callback.add(Callback.ON_DRAW, function() for_buff_holders(buff, is_drawn, fn) end) end

function M.buff_stat_recalc(buff, fn)
    RecalculateStats.add(function(actor, api)
        local stack = buff_stack(actor, buff)
        if stack > 0 then fn(actor, stack, api) end
    end)
end

DeerItemsCallbacks = M
return M
