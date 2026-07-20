-- DeerItems-FearEyesDeactivate
-- Ослабленная версия предмета: даёт +1 к урону за стак.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/FearEyesDeactivate", PATH.."assets/sprites/items/sWhiteItems/FearEyesDeactivate.png", 1, 16, 16)

-- Создание сломанного предмета с флагом is_broken = true
-- Привязка спрайта к предмету
local item = Item.new("FearEyesDeactivate")
item.is_hidden = true
item:set_sprite(sprite)

-- Обработка пересчёта статистики при получении предмета
item:onStatRecalc(function(actor, stack)
    -- Увеличение урона на 1 за каждый стак
    actor.damage = actor.damage + (1 * stack)
end)
