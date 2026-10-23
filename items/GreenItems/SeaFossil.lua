-- DeerItems-SeaFossil
-- При использовании экипировки восстанавливает HP пропорционально времени кулдауна снаряжения.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Sprite.new("item/SeaFossil", PATH.."assets/sprites/items/sGreenItems/SeaFossil.png", 1, 16, 16)
local sound = Sound.new("sound/SeaFossil", PATH.."assets/sounds/SeaFossil.ogg")

-- Создание предмета SeaFossil
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("SeaFossil")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- При использовании экипировки: воспроизводим звук и восстанавливаем HP
DeerItemsCallbacks.item_equipment_use(item, function(actor, stack)
    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
    local cooldown = gm.player_get_equipment_cooldown(actor.value)
    -- Лечение: время кулдауна (сек) × множитель (1.2 + 0.5 за стак)
    local heal = (cooldown / 60) * (1.2 + 0.5 * stack)
    actor:heal(heal)
end)
