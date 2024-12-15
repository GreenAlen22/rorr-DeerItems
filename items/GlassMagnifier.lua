-- Glass Magnifier

local sprite = Resources.sprite_load("DeerItems", "item/GlassMagnifier", PATH.."assets/sprites/items/GlassMagnifier.png", 1, 16, 16)
local item = Item.new("DeerItems", "GlassMagnifier")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

item:onStatRecalc(function(actor, stack)
    actor.damage = actor.damage + 0.5 + (1.5 * stack)
end)