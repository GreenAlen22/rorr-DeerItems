-- DeerItems-Rhinoplasty

local sprite = Sprite.new("item/Rhinoplasty", PATH.."assets/sprites/items/sWhiteItems/Rhinoplasty.png", 1, 16, 16)
local spriteBuff = Sprite.new("buff/Rhinoplasty", PATH.."assets/sprites/buffs/Rhinoplasty.png", 1, 6, 8)

local GUID = _ENV["!guid"]
local HEAL_PER_SKIN = 40
local HEAL_PER_EXTRA_ITEM = 20
local SKINS_BASE = 3
local SKINS_PER_EXTRA_ITEM = 2
local KILLS_PER_SKIN = 3
local SKIN_DURATION = 10 * 60

local item = Item.new("Rhinoplasty")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

local buff = Buff.new("Rhinoplasty")
buff.icon_sprite = spriteBuff
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.max_stack = 999
buff.is_timed = false

local function item_stack_count(actor)
    return math.max(1, actor:item_count(item) or 1)
end

local function skin_cap(actor)
    return SKINS_BASE + SKINS_PER_EXTRA_ITEM * (item_stack_count(actor) - 1)
end

local function heal_per_skin(actor)
    return HEAL_PER_SKIN + HEAL_PER_EXTRA_ITEM * (item_stack_count(actor) - 1)
end

DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if Net.client then return end

    local data = Instance.get_data(actor, "Rhinoplasty", GUID)
    data.kills = (data.kills or 0) + 1
end)

-- У каждой кожи свой таймер: новая кожа не обновляет и не тратит старые.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if Net.client then return end

    local data = Instance.get_data(actor, "Rhinoplasty", GUID)
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

    -- После лимита не копим готовые кожи: сохраняем только неполный прогресс убийств.
    if #timers >= cap then
        data.kills = data.kills % KILLS_PER_SKIN
    end
end)

DeerItemsCallbacks.item_removed(item, function(actor, stack)
    if Net.client or stack > 1 then return end

    local data = Instance.get_data(actor, "Rhinoplasty", GUID)
    data.kills = 0
    data.skin_timers = {}
    local skins = actor:buff_count(buff)
    if skins > 0 then actor:buff_remove(buff, skins) end
end)
