-- DeerItems-GravityLoopDeactivate
-- Сломанная версия GravityLoop: заменяет использованный стак и не имеет собственной логики.
local sprite = Sprite.new("item/GravityLoopDeactivate", PATH.."assets/sprites/items/sWhiteItems/GravityLoopDeactivate.png", 1, 16, 16)

local item = Item.new("GravityLoopDeactivate")
item.is_hidden = true
item:set_sprite(sprite)
