-- РђСЂС‚РµС„Р°РєС‚ РґСЂРѕРЅРѕРІРѕРґР°: РґСЂРѕРЅС‹ РїРѕРґ СѓРїСЂР°РІР»РµРЅРёРµРј РёРіСЂРѕРєР° РЅР°СЃР»РµРґСѓСЋС‚ РїСЂРµРґРјРµС‚С‹ СЃРІРѕРµРіРѕ РІР»Р°РґРµР»СЊС†Р°.

local sprite = Sprite.new("artifact/Droneman",
    PATH.."assets/sprites/artifacts/ArtifactOfDroneman.png",
    3,
    16,
    16
)

local PLAYER_DRONE = gm.constants.oPDrone
local death_inventories = {}

local artifact = Artifact.new("Droneman")
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

Callback.add(Callback.ON_GAME_START, function()
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
        stack_kind or Item.StackKind.NORMAL
    )
end

local function inherit_master_items(drone)
    -- РРЅРІРµРЅС‚Р°СЂСЊ РїСЂРµРґРјРµС‚РѕРІ СЃС‡РёС‚Р°РµС‚ С…РѕСЃС‚. Р’С‹Р·РѕРІС‹ item_give РЅР° РєР»РёРµРЅС‚Рµ РёРіРЅРѕСЂРёСЂСѓСЋС‚СЃСЏ
    -- Рё РЅРµ СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓСЋС‚ РёРЅРІРµРЅС‚Р°СЂСЊ РґСЂРѕРЅР° РёРіСЂРѕРєР°.
    if Net.client or not artifact.active
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

-- РЎРѕРѕР±С‰РµРЅРёРµ РєР»РёРµРЅС‚Р° Рѕ СЃРјРµСЂС‚Рё РјРѕР¶РµС‚ РїСЂРёР№С‚Рё РїРѕСЃР»Рµ С‚РѕРіРѕ, РєР°Рє С…РѕСЃС‚ СѓР¶Рµ РІС‹Р·РІР°Р»
-- init_drone. РџРѕРІС‚РѕСЂРЅР°СЏ РїСЂРѕРІРµСЂРєР° СЃСѓС‰РµСЃС‚РІСѓСЋС‰РµРіРѕ РґСЂРѕРЅР° Р·Р°РєСЂС‹РІР°РµС‚ СЌС‚Сѓ РіРѕРЅРєСѓ.
Callback.add(Callback.POST_STEP, function()
    if Net.client or not artifact.active then return end

    for _, drone in ipairs(Instance.find_all(PLAYER_DRONE)) do
        inherit_master_items(drone)
    end
end)

-- РџРѕРґРѕР±СЂР°РЅРЅС‹Рµ Рё РІС‹РґР°РЅРЅС‹Рµ РїСЂРµРґРјРµС‚С‹ РїРѕР»СѓС‡Р°РµС‚ СЃРѕС…СЂР°РЅС‘РЅРЅС‹Р№ oP. РџРµСЂРµРґР°С‘Рј Р°РєС‚РёРІРЅРѕРјСѓ
-- oPDrone С‚РѕР»СЊРєРѕ РЅРѕРІС‹Р№ СЃС‚Р°Рє: РєРѕРїРёСЂРѕРІР°РЅРёРµ РІСЃРµРіРѕ РёРЅРІРµРЅС‚Р°СЂСЏ Р·Р°РґСѓР±Р»РёСЂСѓРµС‚ РїСЂРµРґРјРµС‚С‹,
-- СѓР¶Рµ СѓРЅР°СЃР»РµРґРѕРІР°РЅРЅС‹Рµ РїСЂРё СЃРјРµСЂС‚Рё.
gm.post_script_hook(gm.constants.item_give_internal, function(self, other, result, args)
    if Net.client or not artifact.active then return end

    local player = args[1] and args[1].value
    local item_id = args[2] and args[2].value
    local count = args[3] and args[3].value
    local stack_kind = args[4] and args[4].value
    if not player or player.object_index ~= gm.constants.oP or not player.dead then return end
    if type(item_id) ~= "number" or type(count) ~= "number" or count <= 0 then return end

    local drone = find_player_drone(player.m_id)
    if drone then give_item(drone, item_id, count, stack_kind) end
end)

-- Р”СЂРѕРЅ РёРіСЂРѕРєР° РјРѕР¶РµС‚ СѓРЅР°СЃР»РµРґРѕРІР°С‚СЊ СЃРєРёРЅ, РєРѕС‚РѕСЂС‹Р№ РЅРµ РїРѕРґС…РѕРґРёС‚ РґР»СЏ РґСЂРѕРЅР°.
gm.pre_script_hook(gm.constants.actor_skin_skinnable_set_skin, function(self, other, result, args)
    if not artifact.active then return end

    local actor = args[1] and args[1].value
    if actor and actor.object_index == PLAYER_DRONE then
        return false
    end
end)
