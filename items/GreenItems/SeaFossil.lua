-- DeerItems-SeaFossil
-- При использовании экипировки восстанавливает HP пропорционально времени кулдауна снаряжения.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/SeaFossil", PATH.."assets/sprites/items/sGreenItems/SeaFossil.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/SeaFossil", PATH.."assets/sounds/SeaFossil.ogg")

-- Создание предмета SeaFossil
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("DeerItems", "SeaFossil")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- При использовании экипировки: воспроизводим звук и восстанавливаем HP
item:onEquipmentUse(function(actor, stack)
    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
    local cooldown = actor:get_equipment_cooldown()
    -- Лечение: время кулдауна (сек) × множитель (1.2 + 0.5 за стак)
    local heal = (cooldown / 60) * (1.2 + 0.5 * stack)
    actor:heal(heal)
end)
