-- DeerItems-GravityLoopDeactivate
-- Сломанная версия GravityLoop: заменяет использованный стак и не имеет собственной логики.
local sprite = Resources.sprite_load("DeerItems", "item/GravityLoopDeactivate", PATH.."assets/sprites/items/sWhiteItems/GravityLoopDeactivate.png", 1, 16, 16)

local item = Item.new("DeerItems", "GravityLoopDeactivate", true)
item:set_sprite(sprite)
