-- DeerItems-SporeOBloom
-- При убийстве с шансом 44% создаёт ядовитое облако, наносящее урон от силы убийцы.

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/SporeOBloom", PATH.."assets/sprites/items/sWhiteItems/SporeOBloom.png", 1, 16.5, 18)

-- Создание предмета SporeOBloom
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("SporeOBloom")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- Очистка старых коллбеков
-- При убийстве врага срабатывает шанс на создание облака
DeerItemsCallbacks.item_kill_proc(item, function(killer, victim, stack)
    if not Net.host then return end

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
