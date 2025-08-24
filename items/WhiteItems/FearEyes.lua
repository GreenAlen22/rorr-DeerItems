-- DeerItems-FearEyes
-- Увеличевает урон игрока за стак. При достижении 15% HP превращается в сломанные стаки.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
-- Загружаем спрайт эффекта
local sprite = Resources.sprite_load("DeerItems", "item/FearEyes", PATH.."assets/sprites/items/sWhiteItems/FearEyes.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/FearEyes", PATH.."assets/sounds/FearEyes.ogg")
local spike = Resources.sprite_load("DeerItems", "particle/Spike", PATH.."assets/sprites/particle/Spike.png", 1, 20, 15)

-- Создание нового предмета с названием "FearEyes" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "FearEyes")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Обработка пересчёта статистики: временный бонус к урону, зависит от суммарных стаков
if item.onStatRecalc then
    item:onStatRecalc(function(actor, stack)
        local normal = actor:item_stack_count(item, Item.STACK_KIND.normal)
        local temp   = actor:item_stack_count(item, Item.STACK_KIND.temporary_blue)
        local stacks = normal + temp
        if stacks > 0 then
            actor.damage = actor.damage + (5 + 10 * stacks)
        end
    end)
end

-- При получении урона и снижении HP до 15%: преобразует стаки в сломанные
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if actor.hp <= actor.maxhp * 0.15 then
        local item_used = Item.find("DeerItems-FearEyesDeactivate")

        -- Переносим обычные стаки
        local normal = actor:item_stack_count(item, Item.STACK_KIND.normal)
        if normal > 0 then
            actor:item_remove(item, normal)
            actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
            actor:item_give(item_used, normal)
        end

        -- Переносим временные/синие стаки
        local temp = actor:item_stack_count(item, Item.STACK_KIND.temporary_blue)
        if temp > 0 then
            actor:item_remove(item, temp, Item.STACK_KIND.temporary_blue)
            actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
            actor:item_give(item_used, temp, Item.STACK_KIND.temporary_blue)
        end
    end
end)

-- Отображение эффекта поверх персонажа
item:onPostDraw(function(actor, stack)
    gm.draw_sprite(spike, 0, actor.x, actor.y)
end)
