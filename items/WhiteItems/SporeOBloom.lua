-- DeerItems-SporeOBloom
-- При убийстве с шансом 44% создаёт ядовитое облако, наносящее урон от силы убийцы.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/SporeOBloom", PATH.."assets/sprites/items/sWhiteItems/SporeOBloom.png", 1, 16, 18)

-- Создание предмета SporeOBloom
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "SporeOBloom")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Очистка старых коллбеков
item:clear_callbacks()
-- При убийстве врага срабатывает шанс на создание облака
item:onKillProc(function(killer, victim, stack)
    if math.random() < 0.44 then
        -- Создаём ядовитое облако чуть выше трупа
        local cloud = GM.instance_create(victim.x, victim.y - 20, gm.constants.oMushDust)
        -- Указываем владельца и команду для корректной работы
        cloud.parent = killer
        cloud.team = killer.team
        -- Урон зависит от урона убийцы(игрока) и количества стаков (60% на стак)
        cloud.damage = killer.damage * (0.6 * stack)
        -- Облако существует 5 секунд
        cloud:alarm_set(0, 60 * 5)
    end
end)
