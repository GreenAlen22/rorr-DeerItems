-- Shared teleporter-state helpers for DeerItems artifacts.

local M = {}
local TELEPORTER_PARENT = gm.constants.pTeleporter

function M.is_event_active(teleporter)
    local state = tonumber(teleporter.active)
    -- 1 = boss phase, 2 = charging; states 3 and 4 are completion/exit.
    return state and state > 0 and state < 3
end

function M.find_active()
    for _, teleporter in ipairs(Instance.find_all(TELEPORTER_PARENT)) do
        if M.is_event_active(teleporter) then
            return teleporter
        end
    end

    return nil
end

DeerItemsTeleporter = M

return M
