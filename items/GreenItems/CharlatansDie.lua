-- DeerItems-CharlatansDie / «Кость шарлатана» / "Charlatan's Die"
-- Первый сундук, открытый за этап, с шансом дополнительно роняет предмет более высокой редкости.
-- (Объединение Chance Doll + Sale Star: исход Алтаря Шанса в RMT прочитать нельзя, поэтому
--  «удачу» перенесли на сундук — доспавниваем ящик более высокого тира.)

local sprite = Sprite.new("item/CharlatansDie", PATH.."assets/sprites/items/sGreenItems/CharlatansDie.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- Настройки баланса
local CHANCE_BASE = 0.35
local CHANCE_STACK = 0.20
local EXTRA_STEP  = 0.05
local MAX_EXTRA_ITEMS = 3
local RARE_BASE   = 0.08      -- из сработавших — доля редких (иначе необычный)
local RARE_STACK  = 0.05

local function truthy(v) return v ~= nil and v ~= false and v ~= 0 end

local item = Item.new("CharlatansDie")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
-- [actor.id] → уже сработал на этом этапе
local used_stage = {}

local function is_chest(interactable)
    if not (interactable and Instance.exists(interactable)) then return false end
    local ok, res = pcall(function()
        return gm.object_is_ancestor(interactable.object_index, gm.constants.pInteractableChest)
    end)
    return ok and truthy(res)
end

local function hyperbolic_chance(step, stack)
    local n = math.max(1, stack or 1)
    return 1 - (1 / (step * n + 1))
end

local function trigger_chance(stack)
    local n = math.max(1, stack or 1)
    return 1 - (1 / (CHANCE_BASE + CHANCE_STACK * (n - 1) + 1))
end

local function is_excluded(value, exclude)
    if not exclude then return false end
    if type(exclude) ~= "table" then return value == exclude end

    for _, excluded in ipairs(exclude) do
        if value == excluded then return true end
    end
    return false
end

local function pick_item(tier, exclude)
    local items = DeerItemsItemPool.of_tier(tier)
    local n = #items
    if n == 0 then return nil end
    for _ = 1, 25 do
        local it = items[gm.irandom_range(1, n)]
        if it and it:is_loot() and DeerItemsItemPool.is_unlocked(it) and not is_excluded(it.value, exclude) then
            return it
        end
    end
    return nil
end

local function roll_extra_count(stack)
    local count = 1
    local chance = hyperbolic_chance(EXTRA_STEP, stack)

    while count < MAX_EXTRA_ITEMS and math.random() <= chance do
        count = count + 1
    end

    return count
end

DeerItemsCallbacks.item_interactable_activate(item, function(actor, stack, interactable)
    if Net.client then return end       -- спавн ящиков только на хосте
    if used_stage[actor.id] then return end
    if not is_chest(interactable) then return end
    used_stage[actor.id] = true

    local x = (interactable and interactable.x) or actor.x
    local y = (interactable and interactable.y) or actor.y
    local exclude = { item.value }

    if math.random() > trigger_chance(stack) then return end

    for i = 1, roll_extra_count(stack) do
        local tier = (math.random() <= (RARE_BASE + RARE_STACK * (stack - 1))) and ItemTier.RARE or ItemTier.UNCOMMON
        local it = pick_item(tier, exclude)
        if not it then it = pick_item(ItemTier.UNCOMMON, exclude) end
        if not it then return end

        exclude[#exclude + 1] = it.value
        DeerItemsItemPool.drop(it, x + 24 + (i - 1) * 18, y - 16, interactable)
    end
end)

-- Сброс на новом этапе
DeerItemsCallbacks.item_stage_start(item, function(actor, stack)
    used_stage[actor.id] = nil
end)
