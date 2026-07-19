-- Артефакт стагнации: таймер сложности идёт только во время события телепорта.

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
        -- Alarm 0 ведёт таймер сложности и забега. Сбрасываем его после обычного
        -- тика кадра, чтобы остановить только этот таймер, не затрагивая другие системы.
        set_difficulty_alarm(director, DIFFICULTY_TICK_FRAMES)
        return
    end

    local alarm = get_difficulty_alarm(director)
    if not alarm or alarm <= 0 then return end

    -- Обычный Step уже списал один кадр. Списываем ещё четыре, чтобы таймер шёл
    -- ровно в пять раз быстрее.
    set_difficulty_alarm(director, math.max(1, alarm - (EVENT_TIME_MULTIPLIER - 1)))
end)
