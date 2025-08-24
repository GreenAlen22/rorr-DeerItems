-- DeerItems-Accountant
-- При использовании оборудования даёт бафф на 3 + 3 сек за стак. Бафф увеличивает скорость атаки на 50%.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/Accountant", PATH.."assets/sprites/items/sGreenItems/Accountant.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/Accountant", PATH.."assets/sounds/Accountant.ogg")

-- Создание предмета и баффа Accountant
local item = Item.new("DeerItems", "Accountant")
local buff = Buff.new("DeerItems", "Accountant")

-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Очистка предыдущих коллбеков
item:clear_callbacks()
-- При использовании снаряжения — применяем бафф
item:onEquipmentUse(function(actor, stack)
    -- Длительность: 3 + 3 сек за стак
    actor:buff_apply(buff, 60 * (3 + 3 * stack), 1)

    -- Воспроизведение звука активации
    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
end)

-- Настройки баффа: скрыт, не дебафф, максимум 1 стак
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1

-- Очистка предыдущих коллбеков баффа
buff:clear_callbacks()
-- При активном баффе увеличивается скорость атаки на 50%
buff:onStatRecalc(function(actor, stack)
    actor.attack_speed = actor.attack_speed + (actor.attack_speed * 0.5)
end)
