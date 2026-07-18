-- Artifact of Victory: revive players once the teleporter boss phase ends.

local sprite = Resources.sprite_load(
    "DeerItems",
    "artifact/Victory",
    PATH.."assets/sprites/artifacts/ArtifactOfVictory.png",
    3,
    16,
    16
)

local REVIVE_INVINCIBILITY_FRAMES = 60
local PLAYER_DRONE_OBJECT = gm.constants.oPDrone

local artifact = Artifact.new("DeerItems", "Victory")
artifact:set_sprites(sprite, sprite)
artifact:set_text(
    "artifact.Victory.name",
    "artifact.Victory.pickup",
    "artifact.Victory.description"
)

local dead_players = {}
local event_active_last_step = false
local boss_phase_seen = false
local packet_revive = Packet.new()

local function truthy(value)
    return value == true or value == 1 or value == 1.0
end

local function is_boss(actor)
    return actor
        and Instance.exists(actor)
        and GM.actor_is_boss
        and truthy(GM.actor_is_boss(actor))
end

local function reset_event_state()
    dead_players = {}
    boss_phase_seen = false
end

local function restore_player(player)
    -- The player instance is retained by the game's death/checkpoint flow.
    -- Restoring this state preserves its controller, inventory and network ID.
    if not player or not Instance.exists(player) then return false end

    player.dead = false
    player.hp = player.maxhp
    if player.maxshield and player.maxshield > 0 then
        player.shield = player.maxshield
    end
    player.barrier = 0
    player.invincible = math.max(player.invincible or 0, REVIVE_INVINCIBILITY_FRAMES)
    player.activity = 0
    player.activity_type = 0
    player.visible = true
    player.following_player_index = 0
    player.ghost_x = player.x
    player.ghost_y = player.y
    player:__actor_update_target_marker()

    if Instance.exists(player.dead_body) then
        player.dead_body:destroy()
    end

    -- oPDrone is the dead player's temporary avatar. m_id is the stable link
    -- between that avatar and the restored oP.
    local player_m_id = player.m_id
    if player_m_id then
        for _, drone in ipairs(Instance.find_all(PLAYER_DRONE_OBJECT)) do
            if drone.m_id == player_m_id then
                drone:destroy()
            end
        end
    end

    if gm._mod_net_isHost() then player:instance_resync() end
    return true
end

packet_revive:onReceived(function(message)
    if not gm._mod_net_isClient() then return end

    local player = message:read_instance()
    if Instance.exists(player) and player:same(Player.get_client()) then
        restore_player(player)
    end
end)

local function revive_dead_players()
    for player_id, _ in pairs(dead_players) do
        local player = Instance.wrap(player_id)
        if restore_player(player) and not player:same(Player.get_client()) then
            local message = packet_revive:message_begin()
            message:write_instance(player)
            message:send_to_all()
        end
    end

    reset_event_state()
end

Callback.add(Callback.TYPE.onGameStart, "DeerItems-Victory-resetRunState", function()
    reset_event_state()
    event_active_last_step = false
end)

DeerItemsPlayerDeath.on_host(function(player)
    if not artifact.active then return end
    dead_players[player.id] = true
end)

Callback.add(Callback.TYPE.postStep, "DeerItems-Victory-revivePlayers", function()
    if gm._mod_net_isClient() or not artifact.active then return end

    local teleporter = DeerItemsTeleporter.find_active()
    if not teleporter then
        if event_active_last_step then reset_event_state() end
        event_active_last_step = false
        return
    end

    event_active_last_step = true
    local alive_bosses = false
    for _, actor in ipairs(Instance.find_all(gm.constants.pActor)) do
        if is_boss(actor) and (actor.hp or 0) > 0 then
            alive_bosses = true
            break
        end
    end

    if alive_bosses then
        boss_phase_seen = true
    elseif boss_phase_seen then
        revive_dead_players()
    end
end)
