-- Передаёт хосту смерть игрока, принадлежащего клиенту, для артефактов с логикой на хосте.

local M = {}
local listeners = {}
local death_packet = Packet.new()

local function notify_listeners(player)
    for _, listener in ipairs(listeners) do
        listener(player)
    end
end

function M.on_host(listener)
    table.insert(listeners, listener)
end

death_packet:onReceived(function(message)
    if not gm._mod_net_isHost() then return end

    local player = message:read_instance()
    if player and Instance.exists(player) then
        notify_listeners(player)
    end
end)

Callback.add(Callback.TYPE.onPlayerDeath, "DeerItems-ArtifactPlayerDeath-notifyHost", function(player)
    if gm._mod_net_isClient() then
        local message = death_packet:message_begin()
        message:write_instance(player)
        message:send_to_host()
        return
    end

    notify_listeners(player)
end)

DeerItemsPlayerDeath = M

return M
