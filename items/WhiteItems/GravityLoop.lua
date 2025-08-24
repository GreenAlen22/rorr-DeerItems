-- DeerItems-GravityLoop
-- При получении урона на низком здоровье лечит и тратит один стак, заменяя его на "GravityLoopDeactivate".

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
-- Загружаем спрайт эффекта
local sprite = Resources.sprite_load("DeerItems", "item/GravityLoop", PATH.."assets/sprites/items/sWhiteItems/GravityLoop.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/GravityLoop", PATH.."assets/sounds/GravityLoop.ogg")
local GravityLoopBreack = Resources.sprite_load("DeerItems", "particle/GravityLoopBreack", PATH.."assets/sprites/particle/GravityLoopBreack.png", 9, 32, 32)

-- Создание нового предмета с названием "GravityLoop" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("DeerItems", "GravityLoop")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- Обработка триггера при получении урона
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    -- Срабатывает, если текущее HP упало до 25% или ниже
    if actor.hp <= actor.maxhp * 0.25 then
        -- Лечение на 50% от максимального HP
        actor:heal(actor.maxhp * 0.5)

        -- Воспроизводим звуковой эффект
        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)

        -- Эффект искр с кастомным спрайтом
        local ef = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
        ef.sprite_index = GravityLoopBreack

        -- Получаем ссылку на предмет, заменяющий использованный стак
        local item_used = Item.find("DeerItems-GravityLoopDeactivate")

        -- Удаляем 1 обычный стак и добавляем 1 сломанный
        local normal = actor:item_stack_count(item, Item.STACK_KIND.normal)
        if normal > 0 then
            actor:item_remove(item, 1)
            actor:item_give(item_used, 1)
            return
        end

        -- Если обычных стаков нет — заменяем временный/синий стак
        local temp = actor:item_stack_count(item, Item.STACK_KIND.temporary_blue)
        if temp > 0 then
            actor:item_remove(item, 1, Item.STACK_KIND.temporary_blue)
            actor:item_give(item_used, 1, Item.STACK_KIND.temporary_blue)
            return
        end
    end
end)
