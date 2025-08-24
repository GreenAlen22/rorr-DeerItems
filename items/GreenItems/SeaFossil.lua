-- DeerItems-SeaFossil
-- Постепенно сокращает кулдаун экипировки. При её использовании восстанавливает HP пропорционально времени кулдауна снаряжения.

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
item:set_loot_tags(Item.LOOT_TAG.category_survive)

-- Каждый кадр: уменьшаем кулдаун экипировки на 0.1 сек за стак
item:onPostStep(function(actor, stack)
    if actor:get_equipment_cooldown() > 0 then
        actor:reduce_equipment_cooldown(0.1 * stack)
    end
end)

-- При использовании экипировки: воспроизводим звук и восстанавливаем HP
item:onEquipmentUse(function(actor, stack)
    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
    local cooldown = actor:get_equipment_cooldown()
    -- Лечение: 2 HP в сек × оставшееся время × стаки
    local heal = (cooldown / 60) * 2 * stack
    actor:heal(heal)
end)
