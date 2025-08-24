-- DeerItems-EyeDiamond
-- Даёт +10% критшанса. Криты наносят усиленный урон: x2.5 за 1 стак, +x1 за каждый последующий.

-- Загружаем спрайт предмета
-- Загружаем спрайт визуального индикатора
local sprite = Resources.sprite_load("DeerItems", "item/EyeDiamond", PATH.."assets/sprites/items/sRedItems/EyeDiamond.png", 1, 16, 16)
local DiamondIndictor = Resources.sprite_load("DeerItems", "DiamondIndictor", PATH.."assets/sprites/particle/DiamondIndictor.png", 1, 8, 8)

-- Создание предмета EyeDiamond
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "EyeDiamond")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- При создании атаки: усиливаем критический урон
item:onAttackCreate(function(actor, stack, attack_info)
    if attack_info.critical and stack and stack > 0 then
        -- Усиление: 1.5 базово + 1.0 за каждый последующий стак
        local extra = 1.5 + 1.0 * (stack - 1)
        -- Итоговое усиление урона
        attack_info.damage = attack_info.damage * (1 + extra)
    end
end)

-- Добавляем 10% критшанса
item:onStatRecalc(function(actor, stack)
    actor.critical_chance = actor.critical_chance + 10
end)
-- Отображение визуального индикатора у персонажа
item:onPostDraw(function(actor, stack)
    gm.draw_sprite(DiamondIndictor, 0, actor.x - 30, actor.y + 50)
end)
