-- DeerItems-CharlatansDie / «Кость шарлатана» / "Charlatan's Die"
-- Первый сундук, открытый за этап, с шансом дополнительно роняет предмет более высокой редкости.
-- (Объединение Chance Doll + Sale Star: исход Алтаря Шанса в RMT прочитать нельзя, поэтому
--  «удачу» перенесли на сундук — доспавниваем ящик более высокого тира.)

local sprite = Resources.sprite_load("DeerItems", "item/CharlatansDie", PATH.."assets/sprites/items/sGreenItems/CharlatansDie.png", 1, 16, 16)

local GUID = _ENV["!guid"]

-- ── Баланс ──
local CHANCE_BASE = 0.35
local CHANCE_STACK = 0.10
local RARE_BASE   = 0.30      -- из сработавших — доля редких (иначе необычный)
local RARE_STACK  = 0.10

local function truthy(v) return v ~= nil and v ~= false and v ~= 0 end

local item = Item.new("DeerItems", "CharlatansDie")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

-- [actor.id] → уже сработал на этом этапе
local used_stage = {}

local function is_chest(interactable)
    if not (interactable and Instance.exists(interactable)) then return false end
    local ok, res = pcall(function()
        return gm.object_is_ancestor(interactable.object_index, gm.constants.pInteractableChest)
    end)
    return ok and truthy(res)
end

local function pick_item(tier, exclude)
    local items = Item.find_all(tier, Item.ARRAY.tier)
    local n = #items
    if n == 0 then return nil end
    for _ = 1, 25 do
        local it = items[gm.irandom_range(1, n)]
        if it and it:is_loot() and it:is_unlocked() and it.value ~= exclude then
            return it
        end
    end
    return nil
end

item:onInteractableActivate(function(actor, stack, interactable)
    if gm._mod_net_isClient() then return end       -- спавн ящиков только на хосте
    if used_stage[actor.id] then return end
    if not is_chest(interactable) then return end
    used_stage[actor.id] = true

    if math.random() > (CHANCE_BASE + CHANCE_STACK * (stack - 1)) then return end

    local tier = (math.random() <= (RARE_BASE + RARE_STACK * (stack - 1))) and Item.TIER.rare or Item.TIER.uncommon
    local it = pick_item(tier, item.value)
    if not it then it = pick_item(Item.TIER.uncommon, item.value) end
    if not it then return end

    local x = (interactable and interactable.x) or actor.x
    local y = (interactable and interactable.y) or actor.y
    Item.spawn_crate(x + 24, y, tier, { it.value })
end)

-- Сброс на новом этапе
item:onStageStart(function(actor, stack)
    used_stage[actor.id] = nil
end)
