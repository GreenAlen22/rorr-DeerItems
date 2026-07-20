-- DeerItems-Obereg
-- Даёт +20 брони за стак, если здоровье персонажа ≤ 50% от максимума.

-- Загружаем спрайт предмета
-- Загружаем спрайт партикла, отображаемого над игроком, пока предмет активен
local sprite = Sprite.new("item/Obereg", PATH.."assets/sprites/items/sWhiteItems/Obereg.png", 1, 16, 16)
local oberegParticle = Sprite.new("particle/Obereg", PATH.."assets/sprites/buffs/Obereg.png", 1, 7.5, 7.5)

-- Создание предмета Obereg
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("Obereg")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- Пересчёт брони после базового расчёта статистики
item:onPostStatRecalc(function(actor, stack)
    -- Если текущее здоровье ≤ 50% от максимального — даём бонус к броне
    if actor.hp <= actor.maxhp * 0.50 then
        actor.armor = actor.armor + (20 * stack)
    end
end)

-- Отображение партикла над игроком, пока предмет активен (hp ≤ 50%)
item:onPostDraw(function(actor, stack)
    if actor.hp <= actor.maxhp * 0.50 then
        gm.draw_sprite(oberegParticle, 0, actor.x, actor.y - 30)
    end
end)
