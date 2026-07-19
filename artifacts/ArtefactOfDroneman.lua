-- Артефакт дроновода: дроны под управлением игрока наследуют предметы своего владельца.

local sprite = Resources.sprite_load(
    "DeerItems",
    "artifact/Droneman",
    PATH.."assets/sprites/artifacts/ArtifactOfDroneman.png",
    3,
    16,
    16
)

local PLAYER_DRONE = gm.constants.oPDrone
local death_inventories = {}

local artifact = Artifact.new("DeerItems", "Droneman")
artifact:set_sprites(sprite, sprite)
artifact:set_text(
    "artifact.Droneman.name",
    "artifact.Droneman.pickup",
    "artifact.Droneman.description"
)

local function copy_inventory(actor)
    local inventory = {}
    local inventory_order = actor.inventory_item_order
    local inventory_stack = actor.inventory_item_stack
    for _, item_id in ipairs(inventory_order) do
        local count = inventory_stack[item_id + 1]
        if count and count > 0 then
            inventory[item_id] = count
        end
    end

    return inventory
end

Callback.add(Callback.TYPE.onGameStart, "DeerItems-Droneman-resetDeathInventories", function()
    death_inventories = {}
end)

DeerItemsPlayerDeath.on_host(function(player)
    if not artifact.active then return end
    death_inventories[player.m_id] = copy_inventory(player)
end)

local function find_player_drone(m_id)
    if not m_id then return nil end

    for _, drone in ipairs(Instance.find_all(PLAYER_DRONE)) do
        if drone.m_id == m_id then return drone end
    end
end

local function give_item(drone, item_id, count, stack_kind)
    gm.item_give(
        Wrap.unwrap(drone),
        item_id,
        count,
        stack_kind or Item.STACK_KIND.normal
    )
end

local function inherit_master_items(drone)
    -- Инвентарь предметов считает хост. Вызовы item_give на клиенте игнорируются
    -- и не синхронизируют инвентарь дрона игрока.
    if gm._mod_net_isClient() or not artifact.active
    or drone.object_index ~= PLAYER_DRONE then
        return
    end

    local inventory = death_inventories[drone.m_id]
    if not inventory then return end

    for item_id, count in pairs(inventory) do
        give_item(drone, item_id, count)
    end
    death_inventories[drone.m_id] = nil
end

gm.post_script_hook(gm.constants.init_drone, function(self, other, result, args)
    inherit_master_items(self)
end)

-- Сообщение клиента о смерти может прийти после того, как хост уже вызвал
-- init_drone. Повторная проверка существующего дрона закрывает эту гонку.
Callback.add(Callback.TYPE.postStep, "DeerItems-Droneman-inheritLateDeathInventory", function()
    if gm._mod_net_isClient() or not artifact.active then return end

    for _, drone in ipairs(Instance.find_all(PLAYER_DRONE)) do
        inherit_master_items(drone)
    end
end)

-- Подобранные и выданные предметы получает сохранённый oP. Передаём активному
-- oPDrone только новый стак: копирование всего инвентаря задублирует предметы,
-- уже унаследованные при смерти.
gm.post_script_hook(gm.constants.item_give_internal, function(self, other, result, args)
    if gm._mod_net_isClient() or not artifact.active then return end

    local player = args[1] and args[1].value
    local item_id = args[2] and args[2].value
    local count = args[3] and args[3].value
    local stack_kind = args[4] and args[4].value
    if not player or player.object_index ~= gm.constants.oP or not player.dead then return end
    if type(item_id) ~= "number" or type(count) ~= "number" or count <= 0 then return end

    local drone = find_player_drone(player.m_id)
    if drone then give_item(drone, item_id, count, stack_kind) end
end)

-- Дрон игрока может унаследовать скин, который не подходит для дрона.
gm.pre_script_hook(gm.constants.actor_skin_skinnable_set_skin, function(self, other, result, args)
    if not artifact.active then return end

    local actor = args[1] and args[1].value
    if actor and actor.object_index == PLAYER_DRONE then
        return false
    end
end)
