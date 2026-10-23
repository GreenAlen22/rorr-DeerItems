-- Артефакт техника: добавляет в директора этапа покупаемые сломанные дроны.

local sprite = Sprite.new("artifact/Technician",
    PATH.."assets/sprites/artifacts/ArtifactOfTechnician.png",
    3,
    16,
    16
)

local DRONES_PER_PLAYER = 2
local MAX_DRONES_PER_STAGE = 8
local MAX_SPAWN_ATTEMPTS = 24
local DRONE_INTERACTABLE = gm.constants.pInteractableDrone

local artifact = Artifact.new("Technician")
artifact.sprite_loadout_id = sprite
artifact.sprite_pickup_id = sprite
artifact.token_name = "artifact.Technician.name"
artifact.token_pickup_name = "artifact.Technician.pickup"
artifact.token_description = "artifact.Technician.description"

-- Карта дрона с наименьшим id, как в RoMT, который шёл по массиву карт по порядку.
-- Object.find_all обходится через pairs и меняет выбор от запуска к запуску, а
-- find_all(…, Property) теряет последнюю карту.
local function find_drone_spawn_data()
    local best
    for _, card in ipairs(InteractableCard.find_all()) do
        local object_id = card.object_id
        if (object_id == DRONE_INTERACTABLE or gm.object_is_ancestor(object_id, DRONE_INTERACTABLE) == 1.0)
        and (not best or card.value < best.value)
        then
            best = card
        end
    end

    if not best then return nil, nil end
    return best.object_id, best.required_tile_space
end

Callback.add(Callback.ON_STAGE_START, function()
    if Net.client or not artifact.active then return end

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
