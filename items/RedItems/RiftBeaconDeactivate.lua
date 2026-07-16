-- DeerItems-RiftBeaconDeactivate
-- Broken Rift Beacon: inert placeholder until the next stage.

local sprite = Resources.sprite_load("DeerItems", "item/RiftBeaconDeactivate", PATH.."assets/sprites/items/sRedItems/RiftBeaconDeactivate.png", 1, 18, 18)

local GUID = _ENV["!guid"]
local LIFE_MAX = 16 * 60
local active

local item = Item.new("DeerItems", "RiftBeaconDeactivate", true)
item:set_sprite(sprite)

local function extend_zone(actor)
    local data = actor:get_data("RiftBeacon", GUID)
    if data.last_extend_frame == Global._current_frame then return end

    local z = data.zone
    if z and z:exists() then
        data.last_extend_frame = Global._current_frame
        z.life = math.min(LIFE_MAX, (z.life or 0) + 60)
    end
end

item:onKillProc(function(actor, victim, stack)
    if gm._mod_net_isClient() then return end

    extend_zone(actor)
end)

item:onStageStart(function(actor, stack)
    if gm._mod_net_isClient() then return end

    active = active or Item.find("DeerItems-RiftBeacon")

    local data = actor:get_data("RiftBeacon", GUID)
    data.below_stack_gate = nil
    data.last_extend_frame = nil
    data.zone = nil

    local normal = actor:item_stack_count(item, Item.STACK_KIND.normal)
    if normal > 0 then
        actor:item_remove(item, normal)
        actor:item_give(active, normal)
    end

    local temp = actor:item_stack_count(item, Item.STACK_KIND.temporary_blue)
    if temp > 0 then
        actor:item_remove(item, temp, Item.STACK_KIND.temporary_blue)
        actor:item_give(active, temp, Item.STACK_KIND.temporary_blue)
    end
end)
