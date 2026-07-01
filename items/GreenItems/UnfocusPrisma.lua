-- DeerItems-UnfocusPrisma
-- Увеличивает урон по врагам на расстоянии более 13 метров на 25% (+25% за стак).

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/UnfocusPrisma", PATH.."assets/sprites/items/sGreenItems/UnfocusPrisma.png", 1, 16, 16)

-- Создание предмета UnfocusPrisma
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "UnfocusPrisma")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Порог дальности, с которого начинает действовать бонус: 13 метров (1 метр = 32 пикселя)
local RANGE = 13 * 32

-- При попадании: если цель дальше 13 метров — усиливаем урон по ней
item:onHitProc(function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    if not hit_info or not hit_info.damage or hit_info.damage <= 0 then return end
    if not Instance.exists(victim) then return end

    -- Дистанция между игроком и целью
    local dx = victim.x - actor.x
    local dy = victim.y - actor.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Бонус только по дальним целям: +25% урона за каждый стак
    if dist > RANGE then
        local mult = 1 + 0.25 * stack
        hit_info:set_damage(hit_info.damage * mult)
    end
end)
