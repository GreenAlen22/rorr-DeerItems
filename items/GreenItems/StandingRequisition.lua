-- DeerItems-StandingRequisition / «Постоянное снабжение» / "Standing Requisition"
-- В начале этапа создаёт для каждого владельца ящик с двумя бесплатными вариантами и одним платным.
-- Хост создаёт ящики после того, как все игроки подтвердили загрузку этапа.

local sprite = Resources.sprite_load("DeerItems", "item/StandingRequisition", PATH.."assets/sprites/items/sGreenItems/StandingRequisition.png", 1, 18, 18)

-- Проверяем ящики дважды: сразу после загрузки и ещё раз, когда сеть успеет создать все экземпляры.
local CHEST_RECONCILE_DELAYS = { 8, 120 }

local item = Item.new("DeerItems", "StandingRequisition")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility, Item.LOOT_TAG.item_blacklist_engi_turrets)
item:clear_callbacks()

local stage_plans = {}
local reconcile_scheduled_frame = -1
local chest_api
local packet_stage_ready = Packet.new()
local pending_stage_ready = {}
local active_stage_key
local expected_stage_players = {}
local ready_stage_players = {}
local stage_reconcile_started = false
local schedule_reconcile

-- Подключает API ящика. Оно может ещё не быть загружено, если порядок файлов изменился.
local function load_chest_api()
    if chest_api then return chest_api end

    chest_api = _G.DeerItemsStandingRequisitionChest
    if type(chest_api) == "table" then return chest_api end

    for _, name in ipairs(path.get_files(PATH.."Interactables")) do
        if name:find("StandingRequisitionChest.lua", 1, true) then
            local ok, api = pcall(require, name)
            if not ok then error(api) end
            if type(api) == "table" then
                chest_api = api
            elseif type(_G.DeerItemsStandingRequisitionChest) == "table" then
                chest_api = _G.DeerItemsStandingRequisitionChest
            end
            break
        end
    end

    if type(chest_api) ~= "table" then
        error("StandingRequisitionChest API was not loaded")
    end

    return chest_api
end

-- Прокси позволяет обращаться к API ящика как к таблице и подгружает его только при первом обращении.
local Chest = setmetatable({}, {
    __index = function(_, key)
        return load_chest_api()[key]
    end
})

local function is_chest_authority()
    return Chest.is_creation_authority()
end

local function make_stage_key(level, stage_id)
    return tostring(level)..":"..tostring(stage_id)
end

-- Создаём ящики только после готовности всех игроков, иначе клиент может получить дубликат.
local function try_schedule_reconcile()
    if stage_reconcile_started or not active_stage_key then return end

    for player_id in pairs(expected_stage_players) do
        if not ready_stage_players[player_id] then return end
    end

    stage_reconcile_started = true
    schedule_reconcile()
end

-- Хост начинает ожидание клиентов на новом этапе.
local function begin_stage_ready_barrier(level, stage_id)
    if not is_chest_authority() then return end

    local key = make_stage_key(level, stage_id)
    active_stage_key = key
    expected_stage_players = {}
    ready_stage_players = pending_stage_ready[key] or {}
    pending_stage_ready = { [key] = ready_stage_players }
    stage_reconcile_started = false

    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        if Instance.exists(player) then
            expected_stage_players[player.m_id] = true
        end
    end

    local host = Player.get_host()
    if Instance.exists(host) then
        ready_stage_players[host.m_id] = true
    end

    try_schedule_reconcile()
end

-- Клиент сообщает хосту, что завершил загрузку этапа.
local function send_stage_ready(level, stage_id)
    if not Net.is_client() then return end

    local message = packet_stage_ready:message_begin()
    message:write_int(level)
    message:write_int(stage_id)
    message:send_to_host()
end

packet_stage_ready:onReceived(function(message, player)
    local level = message:read_int()
    local stage_id = message:read_int()
    if not is_chest_authority() or not Instance.exists(player) then return end

    local key = make_stage_key(level, stage_id)
    local ready = pending_stage_ready[key]
    if not ready then
        ready = {}
        pending_stage_ready[key] = ready
    end
    ready[player.m_id] = true

    if key == active_stage_key then
        ready_stage_players[player.m_id] = true
        try_schedule_reconcile()
    end
end)

-- Больше стаков повышает вес необычных и редких предметов.
local function roll_tier(stack)
    local n = math.max(1, stack or 1)
    local common_weight = 0.79
    local uncommon_weight = 0.2 * n
    local rare_weight = 0.01 * n * n
    local total = common_weight + uncommon_weight + rare_weight
    local r = math.random() * total

    if r < common_weight then return Item.TIER.common end
    if r < common_weight + uncommon_weight then return Item.TIER.uncommon end
    return Item.TIER.rare
end

local function is_excluded(value, exclude)
    if not exclude then return false end
    if type(exclude) ~= "table" then return value == exclude end

    for _, excluded in ipairs(exclude) do
        if value == excluded then return true end
    end
    return false
end

-- Выбирает доступный и открытый предмет нужного тира, исключая указанные ID.
local function pick_item(tier, exclude)
    local candidates = {}
    for _, it in ipairs(Item.find_all(tier, Item.ARRAY.tier)) do
        if it and it:is_loot() and it:is_unlocked() and not is_excluded(it.value, exclude) then
            candidates[#candidates + 1] = it
        end
    end

    if #candidates == 0 then return nil end
    return candidates[gm.irandom_range(1, #candidates)]
end

local function pick_item_with_fallback(tier, exclude)
    local it = pick_item(tier, exclude)
    if it then return it end

    for _, fallback_tier in ipairs({ Item.TIER.common, Item.TIER.uncommon, Item.TIER.rare }) do
        if fallback_tier ~= tier then
            it = pick_item(fallback_tier, exclude)
            if it then return it end
        end
    end

    return nil
end

-- Два варианта не могут повторяться и не могут быть самим StandingRequisition.
local function pick_choices(stack)
    local a = pick_item_with_fallback(roll_tier(stack), { item.value })
    if not a then return nil end

    local b = pick_item_with_fallback(roll_tier(stack), { item.value, a.value })
    if not b then return nil end

    return a, b
end

-- Готовит по одному плану ящика на каждого игрока, у которого есть предмет.
local function collect_stage_plans()
    stage_plans = {}

    local players = Instance.find_all(gm.constants.oP)
    for _, actor in ipairs(players) do
        if Instance.exists(actor) then
            local stack = actor:item_stack_count(item) or 0
            if stack > 0 then
                local a, b = pick_choices(stack)
                if a and b then
                    stage_plans[#stage_plans + 1] = {
                        owner_id = actor.id,
                        stack = stack,
                        a = a.value,
                        b = b.value,
                        paid_tier = roll_tier(stack),
                        exclude_item = item.value,
                    }
                end
            end
        end
    end

    return #stage_plans
end

-- Ищет случайную точку пола. Если не находит, ящик появится рядом с владельцем.
local function find_chest_position()
    local director = gm._mod_game_getDirector()
    local width = gm._mod_room_get_current_width()
    local height = gm._mod_room_get_current_height()
    if not director or not width or not height then return nil end

    for _ = 1, 20 do
        local ground = director:ground_nearest(
            gm.irandom_range(0, width),
            gm.irandom_range(0, height)
        )
        if ground and ground.width_box and ground.height_box then
            local x = ground.x + gm.irandom_range(0, math.max(0, ground.width_box * 32 - 32))
            local y = ground.y - ground.height_box * 32
            return x, y
        end
    end

    return nil
end

local function spawn_chest(plan, index)
    local x, y = find_chest_position()
    if not x then
        local owner = Instance.wrap(plan.owner_id)
        if Instance.exists(owner) then
            x, y = owner.x, owner.y
        else
            x, y = index * 48, 0
        end
    end

    return Chest.create_at(x, y, plan)
end

-- Сверяет реальные ящики с планами этапа: создаёт недостающие и удаляет лишние.
local function reconcile_chests()
    if not is_chest_authority() then return end

    if #stage_plans == 0 then
        collect_stage_plans()
    end

    local chests = Chest.get_instances()
    local by_owner = {}
    local free = {}

    for _, chest in ipairs(chests) do
        local owner_id = chest.sr_owner_id or -1
        if owner_id >= 0 and not by_owner[owner_id] then
            by_owner[owner_id] = chest
        else
            free[#free + 1] = chest
        end
    end

    local wanted_owner = {}
    for i, plan in ipairs(stage_plans) do
        wanted_owner[plan.owner_id] = true
        local chest = by_owner[plan.owner_id]
        if not chest then
            chest = table.remove(free, 1)
            if chest then
                Chest.apply_plan(chest, plan)
            else
                chest = spawn_chest(plan, i)
            end
            by_owner[plan.owner_id] = chest
        elseif chest and (chest.sr_chosen or 0) == 0
        and (
            (chest.sr_owner_id or -1) ~= plan.owner_id
            or (chest.sr_choice_a or -1) < 0
            or (chest.sr_choice_b or -1) < 0
        )
        then
            Chest.apply_plan(chest, plan)
        end
    end

    for owner_id, chest in pairs(by_owner) do
        if not wanted_owner[owner_id] and Instance.exists(chest) then
            chest:destroy()
        end
    end

    for _, chest in ipairs(free) do
        if Instance.exists(chest) then
            chest:destroy()
        end
    end
end

-- Откладывает сверку до двух моментов после загрузки этапа, но не ставит её дважды в один кадр.
schedule_reconcile = function()
    local frame = Global._current_frame or 0
    if reconcile_scheduled_frame == frame then return end
    reconcile_scheduled_frame = frame
    for _, delay in ipairs(CHEST_RECONCILE_DELAYS) do
        Alarm.create(reconcile_chests, delay)
    end
end

-- На новом этапе клиент отправляет подтверждение, а хост запускает ожидание всех игроков.
Callback.add(Callback.TYPE.onStageStart, "DeerItems-StandingRequisition-stageReady", function()
    local level = math.floor(Global.stage_current_level or -1)
    local stage_id = math.floor(Global.stage_id or -1)

    -- The multiplayer chest is deferred until its synchronization is fixed.
    -- toggle_loot affects normal drop pools only, not explicit item grants.
    item:toggle_loot(Net.is_single())

    if Net.is_single() then
        schedule_reconcile()
        return
    end

    if Net.is_client() then
        for _, delay in ipairs({ 1, 30 }) do
            Alarm.create(function()
                send_stage_ready(level, stage_id)
            end, delay)
        end
        return
    end

    begin_stage_ready_barrier(level, stage_id)
end)
