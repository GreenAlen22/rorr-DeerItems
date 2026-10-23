-- DeerItems-RiftBeaconDeactivate
-- Сломанный маяк разлома: неактивная заглушка до следующего этапа.

local sprite = Sprite.new("item/RiftBeaconDeactivate", PATH.."assets/sprites/items/sRedItems/RiftBeaconDeactivate.png", 1, 18, 18)

local GUID = _ENV["!guid"]
local LIFE_MAX = 16 * 60
local active

local item = Item.new("RiftBeaconDeactivate")
item:set_sprite(sprite)

local function extend_zone(actor)
    local data = Instance.get_data(actor, "RiftBeacon", GUID)
    if data.last_extend_frame == Global._current_frame then return end

    local z = data.zone
    if Instance.exists(z) then
        data.last_extend_frame = Global._current_frame
        z.life = math.min(LIFE_MAX, (z.life or 0) + 60)
    end
end

DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if Net.client then return end

    extend_zone(actor)
end)

DeerItemsCallbacks.item_stage_start(item, function(actor, stack)
    if Net.client then return end

    active = active or Item.find("RiftBeacon", "DeerItems")

    local data = Instance.get_data(actor, "RiftBeacon", GUID)
    data.below_stack_gate = nil
    data.last_extend_frame = nil
    data.zone = nil

    local normal = actor:item_count(item, Item.StackKind.NORMAL)
    if normal > 0 then
        actor:item_take(item, normal)
        actor:item_give(active, normal)
    end

    local temp = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
    if temp > 0 then
        actor:item_take(item, temp, Item.StackKind.TEMPORARY_BLUE)
        actor:item_give(active, temp, Item.StackKind.TEMPORARY_BLUE)
    end
end)
