-- DeerItems-RiftBeaconDeactivate
-- РЎР»РѕРјР°РЅРЅС‹Р№ РјР°СЏРє СЂР°Р·Р»РѕРјР°: РЅРµР°РєС‚РёРІРЅР°СЏ Р·Р°РіР»СѓС€РєР° РґРѕ СЃР»РµРґСѓСЋС‰РµРіРѕ СЌС‚Р°РїР°.

local sprite = Sprite.new("item/RiftBeaconDeactivate", PATH.."assets/sprites/items/sRedItems/RiftBeaconDeactivate.png", 1, 18, 18)

local GUID = _ENV["!guid"]
local LIFE_MAX = 16 * 60
local active

local item = Item.new("RiftBeaconDeactivate")
item.is_hidden = true
item:set_sprite(sprite)

local function extend_zone(actor)
    local data = actor:get_data("RiftBeacon", GUID)
    if data.last_extend_frame == Global._current_frame then return end

    local z = data.zone
    if z and z:exists() then
        data.last_extend_frame = Global._current_frame
        z.life = math.min(LIFE_MAX, (z.life or 0) + 60)
    end
end

item:onKillProc(function(actor, victim, stack)
    if Net.client then return end

    extend_zone(actor)
end)

item:onStageStart(function(actor, stack)
    if Net.client then return end

    active = active or Item.find("RiftBeacon", "DeerItems")

    local data = actor:get_data("RiftBeacon", GUID)
    data.below_stack_gate = nil
    data.last_extend_frame = nil
    data.zone = nil

    local normal = actor:item_count(item, Item.StackKind.NORMAL)
    if normal > 0 then
        actor:item_take(item, normal)
        actor:item_give(active, normal)
    end

    local temp = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
    if temp > 0 then
        actor:item_take(item, temp, Item.StackKind.TEMPORARY_BLUE)
        actor:item_give(active, temp, Item.StackKind.TEMPORARY_BLUE)
    end
end)
