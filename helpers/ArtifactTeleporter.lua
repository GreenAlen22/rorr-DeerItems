-- Общие функции для проверки состояния телепорта у артефактов DeerItems.

local M = {}
local TELEPORTER_PARENT = gm.constants.pTeleporter

function M.is_event_active(teleporter)
    local state = tonumber(teleporter.active)
    -- 1 — фаза босса, 2 — зарядка; 3 и 4 означают завершение события и выход.
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
