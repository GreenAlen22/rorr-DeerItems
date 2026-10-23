-- Передаёт хосту смерть игрока, принадлежащего клиенту, для артефактов с логикой на хосте.

local M = {}
local listeners = {}
local death_packet = Packet.new("ArtifactPlayerDeath-death_packet")

local function notify_listeners(player)
    for _, listener in ipairs(listeners) do
        listener(player)
    end
end

function M.on_host(listener)
    table.insert(listeners, listener)
end

death_packet:set_serializers(function(buffer, player)
    buffer:write_instance(player)
end, function(buffer)
    if not Net.host then return end

    local player = buffer:read_instance()
    if player and Instance.exists(player) then
        notify_listeners(player)
    end
end)

Callback.add(Callback.ON_PLAYER_DEATH, function(player)
    if Net.client then
        death_packet:send_to_host(player)
        return
    end

    notify_listeners(player)
end)

DeerItemsPlayerDeath = M

return M
