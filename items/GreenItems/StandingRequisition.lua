-- DeerItems-StandingRequisition / «Постоянная заявка» / "Standing Requisition"
-- В начале каждого этапа неподалёку появляется ящик-доставка с выбором 1 из 2 предметов.
-- (Command-ящик из Item.spawn_crate с двумя вариантами = выбор одного; второй пропадает.)

local sprite = Resources.sprite_load("DeerItems", "item/StandingRequisition", PATH.."assets/sprites/items/sGreenItems/StandingRequisition.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- ── Баланс редкости (стак повышает шансы) ──
local RARE_BASE  = 0.10
local RARE_STACK = 0.05
local UNC_BASE   = 0.30
local UNC_STACK  = 0.05

local item = Item.new("DeerItems", "StandingRequisition")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

local function roll_tier(stack)
    local r = math.random()
    local rare = RARE_BASE + RARE_STACK * (stack - 1)
    local unc  = UNC_BASE + UNC_STACK * (stack - 1)
    if r < rare then return Item.TIER.rare
    elseif r < rare + unc then return Item.TIER.uncommon
    else return Item.TIER.common end
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

-- Доставка в начале этапа: одна на этап независимо от числа стаков
item:onStageStart(function(actor, stack)
    if gm._mod_net_isClient() then return end       -- спавн ящиков только на хосте

    local a = pick_item(roll_tier(stack), item.value)
    if not a then a = pick_item(Item.TIER.common, item.value) end
    if not a then return end

    local b = pick_item(roll_tier(stack), a.value)
    if not b then b = pick_item(Item.TIER.common, a.value) end

    local choices = { a.value }
    if b and b.value ~= a.value then choices[#choices + 1] = b.value end

    local x = actor.x + gm.irandom_range(-100, 100)
    local y = actor.y
    Item.spawn_crate(x, y, Item.TIER.common, choices)
end)
