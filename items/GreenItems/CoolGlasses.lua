-- DeerItems-CoolGlasses
-- Даёт +5% критшанса. Критические атаки создают взрыв, нанося дополнительный урон.

-- Загружаем спрайт предмета
-- Загружаем спрайт индикатора
-- Загружаем спрайт взрыва
local sprite = Sprite.new("item/CoolGlasses", PATH.."assets/sprites/items/sGreenItems/CoolGlasses.png", 1, 16, 16)
local CoolIndictor = Sprite.new("paticle/CoolIndictor", PATH.."assets/sprites/particle/CoolIndictor.png", 1, 8, 8)
local sunExplosion = Sprite.new("paticle/sunExplosion", PATH.."assets/sprites/particle/SunExplosion.png", 9, 32, 32)

-- Создание предмета CoolGlasses
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("CoolGlasses")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- При попадании атакой — если был крит, создаётся взрыв
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end
    local attack_info = hit_info and hit_info.attack_info
    if not attack_info then return end
    if attack_info.critical then
        -- Получаем базовый урон до модификаторов
        local base_damage = attack_info:get_damage_nocrit()
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
        sunDMG:use_raw_damage()              -- игнорируем модификаторы
        sunDMG:set_damage(base_damage * 0.2 * stack) -- наносим "сырой" урон
    end
end)

-- При пересчёте статов — даём +5% критического шанса
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
    api.critical_chance_add(5)
end)

-- Отображение индикатора предмета поверх персонажа
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    gm.draw_sprite(CoolIndictor.value, 0, actor.x + 30, actor.y + 50)
end)
