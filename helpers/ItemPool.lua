-- Предметы для наград мода: выборка по тиру, проверка, открыт ли предмет, и выдача.
local M = {}

local COMMAND = Artifact.find("command", "ror")
if not COMMAND then error("DeerItems: vanilla Artifact of Command not found") end

-- Item.find_all(tier, Item.Property.TIER) в ReturnsAPI 0.1.58 теряет последний
-- зарегистрированный предмет: перебор идёт до #find_cache - 1, а id начинаются с 0
-- (Class.lua:196, FindCache.lua:35). Полный список обходится через pairs, поэтому
-- сортировка по id: выбор в ящике едет по сети номером в этом списке.
function M.of_tier(tier)
    local items = {}
    for _, it in ipairs(Item.find_all()) do
        if it.tier == tier then items[#items + 1] = it end
    end
    table.sort(items, function(a, b) return a.value < b.value end)
    return items
end

-- В RoMT это был Item:is_unlocked(). Предмет без ачивки открыт
-- (achievement_is_unlocked_or_null для id < 0).
function M.is_unlocked(item)
    return Util.bool(item:get_achievement():is_unlocked())
end

-- Выдать награду так, как её выдал бы сундук. Под Артефактом командования ваниль роняет
-- вместо предмета ящик выбора его тира (treasure_loot_pool_roll_and_handle_artifacts.gml:5-6),
-- а Item:create зовёт голый item_drop_object и Командование не видит. Звать у хоста:
-- и предмет, и ящик игра синхронизирует сама.
function M.drop(item, x, y, target)
    if Util.bool(COMMAND.active) then
        -- Первый пул по индексу — ванильный пул тира предмета (Item.lua:337-348).
        local pool = item:get_loot_pools()[1]
        local crate = pool and pool.command_crate_object_id or -1
        if crate >= 0 then
            -- item_drop_object поднимает точку на 40 px; Item:create компенсирует так же.
            gm.item_drop_object(crate, x, y + 40, target and target.value or -4, false)
            return
        end
    end
    item:create(x, y, target)
end

DeerItemsItemPool = M
return M
