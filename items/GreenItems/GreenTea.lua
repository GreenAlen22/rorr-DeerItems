-- DeerItems-GreenTea
-- Увеличивает макс. HP на 6.8% за стак и даёт регенерацию.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/GreenTea", PATH.."assets/sprites/items/sGreenItems/GreenTea.png", 1, 18, 18)

-- Создание предмета GreenTea
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("GreenTea")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- Прирост maxhp ваниль доливает в hp сама (recalculate_stats: hp + maxhp - maxhp_old),
-- поэтому HP при подборе не теряется и отдельно не восстанавливается.
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
    api.maxhp_mult(1 + 0.068 * stack)
    api.hp_regen_add(0.0091 * stack)
end)
