-- РђСЂС‚РµС„Р°РєС‚ РїРѕР±РµРґС‹: РІРѕСЃРєСЂРµС€Р°РµС‚ РёРіСЂРѕРєРѕРІ РїРѕСЃР»Рµ РѕРєРѕРЅС‡Р°РЅРёСЏ С„Р°Р·С‹ Р±РѕСЃСЃР° Сѓ С‚РµР»РµРїРѕСЂС‚Р°.

local sprite = Sprite.new("artifact/Victory",
    PATH.."assets/sprites/artifacts/ArtifactOfVictory.png",
    3,
    16,
    16
)

local REVIVE_INVINCIBILITY_FRAMES = 60
local PLAYER_DRONE_OBJECT = gm.constants.oPDrone

local artifact = Artifact.new("Victory")
artifact.sprite_loadout_id = sprite
artifact.sprite_pickup_id = sprite
artifact.token_name = "artifact.Victory.name"
artifact.token_pickup_name = "artifact.Victory.pickup"
artifact.token_description = "artifact.Victory.description"

local dead_players = {}
local event_active_last_step = false
local boss_phase_seen = false
local packet_revive = Packet.new("ArtifactOfVictory-packet_revive")

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
    -- РРіСЂР° СЃРѕС…СЂР°РЅСЏРµС‚ СЌРєР·РµРјРїР»СЏСЂ РёРіСЂРѕРєР° РґР»СЏ СЃРјРµСЂС‚Рё Рё РєРѕРЅС‚СЂРѕР»СЊРЅС‹С… С‚РѕС‡РµРє. Р’РѕР·РІСЂР°С‰Р°РµРј
    -- СЌС‚Рѕ СЃРѕСЃС‚РѕСЏРЅРёРµ, С‡С‚РѕР±С‹ РЅРµ РїРѕС‚РµСЂСЏС‚СЊ СѓРїСЂР°РІР»РµРЅРёРµ, РёРЅРІРµРЅС‚Р°СЂСЊ Рё СЃРµС‚РµРІРѕР№ ID.
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

    -- oPDrone вЂ” РІСЂРµРјРµРЅРЅС‹Р№ Р°РІР°С‚Р°СЂ РјС‘СЂС‚РІРѕРіРѕ РёРіСЂРѕРєР°. m_id СЃРІСЏР·С‹РІР°РµС‚ РµРіРѕ СЃ РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹Рј oP.
    local player_m_id = player.m_id
    if player_m_id then
        for _, drone in ipairs(Instance.find_all(PLAYER_DRONE_OBJECT)) do
            if drone.m_id == player_m_id then
                drone:destroy()
            end
        end
    end

    if Net.host then player:instance_resync() end
    return true
end

packet_revive:set_serializers(function(buffer, player)
    buffer:write_instance(player)
end, function(buffer)
    if not Net.client then return end

    local player = buffer:read_instance()
    if Instance.exists(player) and player:same(Player.get_client()) then
        restore_player(player)
    end
end)

local function revive_dead_players()
    for player_id, _ in pairs(dead_players) do
        local player = Instance.wrap(player_id)
        if restore_player(player) and not player:same(Player.get_client()) then
            packet_revive:send_to_all(player)
        end
    end

    reset_event_state()
end

Callback.add(Callback.ON_GAME_START, function()
    reset_event_state()
    event_active_last_step = false
end)

DeerItemsPlayerDeath.on_host(function(player)
    if not artifact.active then return end
    dead_players[player.id] = true
end)

Callback.add(Callback.POST_STEP, function()
    if Net.client or not artifact.active then return end

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
