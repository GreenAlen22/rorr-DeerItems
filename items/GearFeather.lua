-- Gear Feather

local sprite = Resources.sprite_load("DeerItems", "item/GearFeather", PATH.."assets/sprites/items/GearFeather.png", 1, 16, 16)
local item = Item.new("DeerItems", "GearFeather")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

item:onStatRecalc(function(actor, stack)
    actor.pVmax = actor.pVmax+(actor.pVmax*(0.07*stack))
end)