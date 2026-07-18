-- Artifact of Stagnation: the difficulty clock advances only during teleporter events.

local sprite = Resources.sprite_load(
    "DeerItems",
    "artifact/Stagnation",
    PATH.."assets/sprites/artifacts/ArtifactOfStagnation.png",
    3,
    16,
    16
)

local DIFFICULTY_ALARM = 0
local DIFFICULTY_TICK_FRAMES = 60
local EVENT_TIME_MULTIPLIER = 5

local artifact = Artifact.new("DeerItems", "Stagnation")
artifact:set_sprites(sprite, sprite)
artifact:set_text(
    "artifact.Stagnation.name",
    "artifact.Stagnation.pickup",
    "artifact.Stagnation.description"
)

local function set_difficulty_alarm(director, value)
    local ok = pcall(function()
        director:alarm_set(DIFFICULTY_ALARM, value)
    end)
    return ok
end

local function get_difficulty_alarm(director)
    local ok, value = pcall(function()
        return director:alarm_get(DIFFICULTY_ALARM)
    end)
    if not ok then return nil end
    return value
end

Callback.add(Callback.TYPE.postStep, "DeerItems-Stagnation-updateDifficultyTimer", function()
    if not artifact.active then return end

    local director = gm._mod_game_getDirector()
    if not director then return end

    local teleporter = DeerItemsTeleporter.find_active()
    if not teleporter then
        -- Alarm 0 drives the canonical difficulty/run timer. Resetting it after
        -- its normal frame tick freezes that timer without advancing any other
        -- game systems.
        set_difficulty_alarm(director, DIFFICULTY_TICK_FRAMES)
        return
    end

    local alarm = get_difficulty_alarm(director)
    if not alarm or alarm <= 0 then return end

    -- The normal Step already consumed one frame. Consume four more so the
    -- canonical timer advances at exactly five times normal speed.
    set_difficulty_alarm(director, math.max(1, alarm - (EVENT_TIME_MULTIPLIER - 1)))
end)
