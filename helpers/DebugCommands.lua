-- Отладочные команды прогона: выдать предмет или снаряжение мода, чтобы не искать его в забеге,
-- вызвать зверя Ingrown Idol и напечатать статы игрока, чтобы бонус предмета был виден числом.
-- Консоль: Shift + ` (на русской раскладке Shift + Ё), не на паузе.

-- Спутники *Deactivate тоже выдаются: их состояние иначе получить долго.
local function find_entry(id)
    local wanted = tostring(id):lower()
    for _, category in ipairs(DeerItemsItemManifest.categories) do
        for _, entry in ipairs(category.items) do
            if entry.id:lower() == wanted then return category.key, entry.id end
            for _, dependency in ipairs(entry.dependencies or {}) do
                if dependency:lower() == wanted then return category.key, dependency end
            end
        end
    end
end

local function print_ids()
    for _, category in ipairs(DeerItemsItemManifest.categories) do
        local ids = {}
        for _, entry in ipairs(category.items) do ids[#ids + 1] = entry.id end
        Console.print("<y>"..category.key.."</c>: "..table.concat(ids, ", "))
    end
end

-- Клиент сам себе выдать не может, поэтому хост выдаёт ему по номеру: порядок oP на
-- машине хоста. Кому ушло, видно по имени в ответе команды.
local function target_player(n)
    if n == nil then return Player.get_local() end
    return Instance.find_all(gm.constants.oP)[math.floor(tonumber(n) or 0)] or Instance.INVALID
end

local function give(args)
    if #args < 1 then
        Console.print("Usage: deer_give (id) [count] [player]. Ids:")
        print_ids()
        return
    end

    -- item_give и equipment_set — хостовые: у клиента выдача не уйдёт дальше его машины.
    if not Net.host then
        Console.print("deer_give: host or single player only.", Color.Console.RED)
        return
    end

    -- Вне забега get_local отдаёт INVALID, а его Instance.exists развернуть не может.
    local player = target_player(args[3])
    if player == Instance.INVALID or not Instance.exists(player) then
        Console.print("deer_give: no such player, start a run first.", Color.Console.RED)
        return
    end

    local key, id = find_entry(args[1])
    if not id then
        Console.print("deer_give: unknown id '"..tostring(args[1]).."'. Type deer_give for the list.", Color.Console.RED)
        return
    end

    local to = " to "..tostring(player.user_name)
    if key == "Equipments" then
        player:equipment_set(Equipment.find(id, "DeerItems", true))
        Console.print("deer_give: equipment "..id..to)
        return
    end

    local count = math.max(1, math.floor(tonumber(args[2]) or 1))
    player:item_give(Item.find(id, "DeerItems", true), count)
    Console.print("deer_give: "..id.." x"..count..to..", now "..player:item_count(Item.find(id, "DeerItems", true), Item.StackKind.NORMAL))
end

-- Статы на экране не видны, а пересчёт идёт через api: проверка — разница до и после выдачи.
local STATS = {
    "damage", "attack_speed", "critical_chance", "armor",
    "maxhp", "hp", "hp_regen", "maxshield", "pHmax", "pVmax",
}
local SKILL_SLOTS = { "SECONDARY", "UTILITY", "SPECIAL" }

local function stats()
    local player = Player.get_local()
    if player == Instance.INVALID or not Instance.exists(player) then
        Console.print("deer_stats: no local player, start a run first.", Color.Console.RED)
        return
    end

    local parts = {}
    for _, key in ipairs(STATS) do
        parts[#parts + 1] = key.." "..string.format("%.4g", player[key] or 0)
    end
    Console.print(table.concat(parts, " | "))

    parts = {}
    for _, slot in ipairs(SKILL_SLOTS) do
        local skill = player:get_active_skill(Skill.Slot[slot])
        parts[#parts + 1] = slot:lower().." cd "..tostring(skill and skill.cooldown or "?")
    end
    Console.print(table.concat(parts, " | ").." (frames)")
end

-- Зверя Ingrown Idol иначе ждать 30 подношений. Тот же вызов, что у предмета: зверь один на
-- команду, повторный вызов продлевает живого.
local function beast(args)
    if not Net.host then
        Console.print("deer_beast: host or single player only.", Color.Console.RED)
        return
    end

    local player = Player.get_local()
    if player == Instance.INVALID or not Instance.exists(player) then
        Console.print("deer_beast: no local player, start a run first.", Color.Console.RED)
        return
    end

    local stack = math.max(1, math.floor(tonumber(args[1]) or 1))
    local inst = DeerItemsCernunnos.spawn(player, stack)
    Console.print("deer_beast: "..(inst and "beast x"..stack.." for "..tostring(player.user_name) or "not spawned"))
end

Console.new{
    "deer_beast [stack]",
    {
        "Summon Ingrown Idol's beast next to the local player (host or single player).",
        {"[stack]", "number", "Idol stacks for the beast's damage, 1 by default."},
    },
    function(args)
        local ok, err = pcall(beast, args)
        if not ok then Console.print("deer_beast failed: "..tostring(err), Color.Console.RED) end
    end
}

Console.new{
    "deer_stats",
    {
        "Print the local player's stats and skill cooldowns.",
    },
    function()
        local ok, err = pcall(stats)
        if not ok then Console.print("deer_stats failed: "..tostring(err), Color.Console.RED) end
    end
}

Console.new{
    "deer_give [id] [count] [player]",
    {
        "Give a DeerItems item or equipment to a player. Without arguments, lists the ids.",
        {"[id]", "string", "Id from the item manifest, any case."},
        {"[count]", "number", "Stacks to give, 1 by default. Ignored for equipment."},
        {"[player]", "number", "Player number on the host, from 1. The local player by default."},
    },
    -- Исключение в обработчике консоль не показывает: печатаем его сами.
    function(args)
        local ok, err = pcall(give, args)
        if not ok then Console.print("deer_give failed: "..tostring(err), Color.Console.RED) end
    end
}
