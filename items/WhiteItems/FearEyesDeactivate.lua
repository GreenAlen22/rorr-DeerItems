-- DeerItems-FearEyesDeactivate
-- Ослабленная версия предмета: даёт +1 к урону за стак.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/FearEyesDeactivate", PATH.."assets/sprites/items/sWhiteItems/FearEyesDeactivate.png", 1, 16, 16)

-- Создание сломанного предмета с флагом is_broken = true
-- Привязка спрайта к предмету
local item = Item.new("FearEyesDeactivate")
item:set_sprite(sprite)

-- Обработка пересчёта статистики при получении предмета
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
    -- Увеличение урона на 1 за каждый стак
    api.damage_add(1 * stack)
end)
