-- Artifact of Droneman: player-controlled drones inherit their own master's items.

local sprite = Resources.sprite_load(
    "DeerItems",
    "artifact/Droneman",
    PATH.."assets/sprites/artifacts/ArtefactOfDroneman.png",
    3,
    16,
    16
)

local PLAYER_DRONE = gm.constants.oPDrone

local artifact = Artifact.new("DeerItems", "Droneman")
artifact:set_sprites(sprite, sprite)
artifact:set_text(
    "artifact.Droneman.name",
    "artifact.Droneman.pickup",
    "artifact.Droneman.description"
)

local function inherit_master_items(drone)
    if not artifact.active or drone.object_index ~= PLAYER_DRONE then return end

    local master_value = drone.master
    if not master_value then return end

    local master = Instance.wrap(master_value)
    if not Instance.exists(master) then return end

    local inventory_order = master.inventory_item_order
    local inventory_stack = master.inventory_item_stack
    for _, item_id in ipairs(inventory_order) do
        local count = inventory_stack[item_id + 1]
        if count and count > 0 then
            gm.item_give(drone, item_id, count, Item.STACK_KIND.normal)
        end
    end
end

gm.post_script_hook(gm.constants.init_drone, function(self, other, result, args)
    inherit_master_items(self)
end)

-- Player drones may inherit a skin that is not valid for a drone actor.
gm.pre_script_hook(gm.constants.actor_skin_skinnable_set_skin, function(self, other, result, args)
    if not artifact.active then return end

    local actor = args[1] and args[1].value
    if actor and actor.object_index == PLAYER_DRONE then
        return false
    end
end)
