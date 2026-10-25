-- DeerItems-FearEyes
-- Увеличевает урон игрока за стак. При достижении 40% HP превращается в сломанные стаки.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
-- Загружаем спрайт эффекта
local sprite = Sprite.new("item/FearEyes", PATH.."assets/sprites/items/sWhiteItems/FearEyes.png", 1, 16, 16)
local sound = Sound.new("sound/FearEyes", PATH.."assets/sounds/FearEyes.ogg")
local spike = Sprite.new("particle/Spike", PATH.."assets/sprites/particle/Spike.png", 1, 20, 15)

-- ленивый кэш ссылки на сломанную версию (на загрузке может быть ещё не зарегистрирована)
local deactivate

-- Создание нового предмета с названием "FearEyes" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("FearEyes")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- Обработка пересчёта статистики: временный бонус к урону, зависит от суммарных стаков
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
    local normal = actor:item_count(item, Item.StackKind.NORMAL)
    local temp   = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
    local stacks = normal + temp
    if stacks > 0 then
        api.damage_add(5 + 10 * stacks)
    end
end)

-- При получении урона и снижении HP до 40%: преобразует стаки в сломанные
DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if Net.client then return end

    if actor.hp <= actor.maxhp * 0.40 then
        deactivate = deactivate or Item.find("FearEyesDeactivate", "DeerItems")
        local item_used = deactivate

        -- Переносим обычные стаки
        local normal = actor:item_count(item, Item.StackKind.NORMAL)
        if normal > 0 then
            actor:item_take(item, normal)
            DeerItemsSound.play_at(sound, actor.x, actor.y, 2.0, 0.9 + math.random() * 0.5)
            actor:item_give(item_used, normal)
        end

        -- Переносим временные/синие стаки
        local temp = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
        if temp > 0 then
            actor:item_take(item, temp, Item.StackKind.TEMPORARY_BLUE)
            DeerItemsSound.play_at(sound, actor.x, actor.y, 2.0, 0.9 + math.random() * 0.5)
            actor:item_give(item_used, temp, Item.StackKind.TEMPORARY_BLUE)
        end
    end
end)

-- Отображение эффекта поверх персонажа
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    gm.draw_sprite(spike.value, 0, actor.x, actor.y)
end)
