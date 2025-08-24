-- DeerItems-RadialAlloy
-- При получении урона восстанавливает до 10 (+5 за стак после первого) HP, но не более (урон - 5).

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/RadialAlloy", PATH.."assets/sprites/items/sGreenItems/RadialAlloy.png", 1, 16, 16)

-- Создание предмета RadialAlloy
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("DeerItems", "RadialAlloy")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_survive)

-- При получении урона: лечим часть обратно
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if stack <= 0 then return end

    -- Извлекаем количество полученного урона
    local dmg = hit_info and (hit_info.damage or (hit_info.get_damage and hit_info:get_damage())) or 0
    if dmg <= 0 then return end

    -- Сколько можно восстановить: максимум (урон - 5), не более лимита от стаков
    local reduction = 10 + 5 * (stack - 1)
    local can_reduce = math.max(0, dmg - 5)
    local heal_back = math.min(reduction, can_reduce)

    -- Лечение, если есть что восстанавливать
    if heal_back > 0 then
        actor:heal(heal_back)
    end
end)
