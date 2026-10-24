-- DeerItems-TipJar / «Банка для чаевых» / "Tip Jar"
-- Всё получаемое золото больше на 15% (+15% за стак), из любого источника.

local sprite = Sprite.new("item/TipJar", PATH.."assets/sprites/items/sWhiteItems/TipJar.png", 1, 18, 18)

local GOLD_BONUS = 0.15   -- доля золота сверху за стак

local item = Item.new("TipJar")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Кошелёк у каждой машины свой, и add_gold зовётся на машине того, кто получает золото.
-- Поэтому бонус считается только от локального игрока: зеркала чужих игроков на этой машине
-- свой бонус получают у себя. Pre-хук: GoldStandard читает в post-хуке уже увеличенную сумму.
Hook.add_pre(DeerItemsGold.ADD_GOLD, function(self, other, result, args)
    local amount = args[1].value
    if type(amount) ~= "number" or amount <= 0 then return end

    local player = Player.get_local()
    if player == Instance.INVALID or not Instance.exists(player) then return end
    local stack = player:item_count(item, Item.StackKind.ANY) or 0
    if stack <= 0 then return end

    args[1].value = amount * (1 + GOLD_BONUS * stack)
end)
