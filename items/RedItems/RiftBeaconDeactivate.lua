-- DeerItems-RiftBeaconDeactivate
-- Broken Rift Beacon: inert placeholder until the next stage.

local sprite = Resources.sprite_load("DeerItems", "item/RiftBeaconDeactivate", PATH.."assets/sprites/items/sRedItems/RiftBeaconDeactivate.png", 1, 18, 18)

local GUID = _ENV["!guid"]
local LIFE_MAX = 16 * 60
local active

local item = Item.new("DeerItems", "RiftBeaconDeactivate", true)
item:set_sprite(sprite)

item:onKillProc(function(actor, victim, stack)
    local data = actor:get_data("RiftBeacon", GUID)
    local z = data.zone
    if z and z:exists() then
        z.life = math.min(LIFE_MAX, (z.life or 0) + 60)
    end
end)

item:onStageStart(function(actor, stack)
    active = active or Item.find("DeerItems-RiftBeacon")

    local data = actor:get_data("RiftBeacon", GUID)
    data.used = false
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
