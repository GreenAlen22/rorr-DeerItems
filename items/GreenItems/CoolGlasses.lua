-- DeerItems-CoolGlasses
-- Даёт +5% критшанса. Критические атаки создают взрыв, нанося дополнительный урон.

-- Загружаем спрайт предмета
-- Загружаем спрайт индикатора
-- Загружаем спрайт взрыва
local sprite = Resources.sprite_load("DeerItems", "item/CoolGlasses", PATH.."assets/sprites/items/sGreenItems/CoolGlasses.png", 1, 16, 16)
local CoolIndictor = Resources.sprite_load("DeerItems", "paticle/CoolIndictor", PATH.."assets/sprites/particle/CoolIndictor.png", 1, 8, 8)
local sunExplosion = Resources.sprite_load("DeerItems", "paticle/sunExplosion", PATH.."assets/sprites/particle/SunExplosion.png", 9, 32, 32)

-- Создание предмета CoolGlasses
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "CoolGlasses")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- При попадании атакой — если был крит, создаётся взрыв
item:onAttackHit(function(actor, victim, stack, attack_info)
    if attack_info.critical then
        -- Получаем базовый урон до модификаторов
        local base_damage = attack_info:get_damage_nocrit(attack_info.damage)
        -- Создание взрыва на месте жертвы
        local inst = actor:fire_explosion(
            victim.x,
            victim.y,
            128, 128,                         -- радиус по X и Y
            base_damage * 1.2 * stack,        -- урон от взрыва
            nil,                              -- спрайт взырва
            sunExplosion,                     -- спрайт эффекта при поподании
            false                             -- не имеет proc 
        )
        -- Дополнительная настройка урона от взрыва
        local sunDMG = inst.attack_info
        sunDMG:set_critical(false)            -- убираем возможность крита
        sunDMG.proc = false                   -- отключаем проки
        sunDMG:use_raw_damage(true)          -- игнорируем модификаторы
        sunDMG:set_damage(base_damage * 0.2 * stack) -- наносим "сырой" урон
    end
end)

-- При пересчёте статов — даём +5% критического шанса
item:onStatRecalc(function(actor, stack)
    actor.critical_chance = actor.critical_chance + 5
end)

-- Отображение индикатора предмета поверх персонажа
item:onPostDraw(function(actor, stack)
    gm.draw_sprite(CoolIndictor, 0, actor.x + 30, actor.y + 50)
end)
