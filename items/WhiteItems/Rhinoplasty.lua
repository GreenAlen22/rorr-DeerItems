-- DeerItems-Rhinoplasty

local sprite = Resources.sprite_load("DeerItems", "item/Rhinoplasty", PATH.."assets/sprites/items/sWhiteItems/Rhinoplasty.png", 1, 16, 16)
local spriteBuff = Resources.sprite_load("DeerItems", "buff/Rhinoplasty", PATH.."assets/sprites/buffs/Rhinoplasty.png", 1, 6, 8)

local GUID = _ENV["!guid"]
local HEAL_PER_SKIN = 40
local HEAL_PER_EXTRA_ITEM = 20
local SKINS_BASE = 3
local SKINS_PER_EXTRA_ITEM = 2
local KILLS_PER_SKIN = 3
local SKIN_DURATION = 10 * 60

local item = Item.new("DeerItems", "Rhinoplasty")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

local buff = Buff.new("DeerItems", "Rhinoplasty")
buff.icon_sprite = spriteBuff
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.max_stack = 999
buff.is_timed = false

local function item_stack_count(actor)
    return math.max(1, actor:item_stack_count(item) or 1)
end

local function skin_cap(actor)
    return SKINS_BASE + SKINS_PER_EXTRA_ITEM * (item_stack_count(actor) - 1)
end

local function heal_per_skin(actor)
    return HEAL_PER_SKIN + HEAL_PER_EXTRA_ITEM * (item_stack_count(actor) - 1)
end

item:onKillProc(function(actor, victim, stack)
    if gm._mod_net_isClient() then return end

    local data = actor:get_data("Rhinoplasty", GUID)
    data.kills = (data.kills or 0) + 1
end)

-- Every skin owns its timer, so newer skins never refresh or consume older ones.
item:onPostStep(function(actor, stack)
    if gm._mod_net_isClient() then return end

    local data = actor:get_data("Rhinoplasty", GUID)
    data.kills = data.kills or 0
    data.skin_timers = data.skin_timers or {}
    local timers = data.skin_timers

    for i = #timers, 1, -1 do
        timers[i] = timers[i] - 1
        if timers[i] <= 0 then
            table.remove(timers, i)
            actor:buff_remove(buff, 1)
            actor:heal(heal_per_skin(actor))
            actor:sound_play_at(gm.constants.wUse, 1.0, 0.7, actor.x, actor.y)
        end
    end

    local cap = skin_cap(actor)
    while #timers > cap do
        table.remove(timers)
        actor:buff_remove(buff, 1)
    end

    while data.kills >= KILLS_PER_SKIN and #timers < cap do
        data.kills = data.kills - KILLS_PER_SKIN
        table.insert(timers, SKIN_DURATION)
        actor:buff_apply(buff, 1, 1)
    end

    -- Do not reserve complete skin stacks beyond the cap; keep only partial kill progress.
    if #timers >= cap then
        data.kills = data.kills % KILLS_PER_SKIN
    end
end)

item:onRemove(function(actor, stack)
    if gm._mod_net_isClient() or stack > 1 then return end

    local data = actor:get_data("Rhinoplasty", GUID)
    data.kills = 0
    data.skin_timers = {}
    local skins = actor:buff_stack_count(buff)
    if skins > 0 then actor:buff_remove(buff, skins) end
end)
