-- Артефакт техника: добавляет в директора этапа покупаемые сломанные дроны.

local sprite = Resources.sprite_load(
    "DeerItems",
    "artifact/Technician",
    PATH.."assets/sprites/artifacts/ArtifactOfTechnician.png",
    3,
    16,
    16
)

local DRONES_PER_PLAYER = 2
local MAX_DRONES_PER_STAGE = 8
local MAX_SPAWN_ATTEMPTS = 24
local DRONE_INTERACTABLE = gm.constants.pInteractableDrone

local artifact = Artifact.new("DeerItems", "Technician")
artifact:set_sprites(sprite, sprite)
artifact:set_text(
    "artifact.Technician.name",
    "artifact.Technician.pickup",
    "artifact.Technician.description"
)

local function find_drone_spawn_data()
    for _, card in ipairs(Class.INTERACTABLE_CARD) do
        local object_id = card:get(4)
        if object_id == DRONE_INTERACTABLE
        or gm.object_is_ancestor(object_id, DRONE_INTERACTABLE) == 1.0
        then
            return object_id, card:get(5)
        end
    end

    return nil, nil
end

artifact:onStageStart(function()
    if gm._mod_net_isClient() or not artifact.active then return end

    local drone_object, required_tile_space = find_drone_spawn_data()
    if not drone_object then
        log.error("Artifact of the Technician could not find the vanilla drone interactable")
        return
    end

    local director = gm._mod_game_getDirector()
    if not director then
        log.error("Artifact of the Technician could not access the director")
        return
    end

    local players = Instance.find_all(gm.constants.oP)
    local count = math.min(#players * DRONES_PER_PLAYER, MAX_DRONES_PER_STAGE)
    local target = Instance.count(drone_object) + count
    local attempts = 0

    while Instance.count(drone_object) < target and attempts < MAX_SPAWN_ATTEMPTS do
        director:mapobject_spawn(drone_object, required_tile_space or 1)
        attempts = attempts + 1
    end
end)
