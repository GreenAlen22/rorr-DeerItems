-- DeerItems-MagmaFragment
-- При попадании атакой с шансом 10% за стак накладывает дот-эффект (горение) на врага, нанося 30% от урона атаки.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/MagmaFragment", PATH.."assets/sprites/items/sWhiteItems/MagmaFragment.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/MagmaFragment", PATH.."assets/sounds/MagmaFragment.ogg")

-- Создание предмета MagmaFragment
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "MagmaFragment")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Очистка всех предыдущих коллбеков
item:clear_callbacks()

-- При попадании атакой срабатывает шанс наложить эффект горения
item:onHitProc(function(actor, victim, stack, hit_info)
    -- 10% за каждый стак или принудительный прок
    if math.random() <= 0.1 * stack or hit_info.attack_info:get_attack_flag(Attack_Info.ATTACK_FLAG.force_proc) then
        -- Воспроизведение звука при срабатывании
        victim:sound_play(sound, 1.0, 0.9 + math.random() * 0.2)

        -- Создание объекта дота (урон по времени)
        local dot = gm.instance_create(victim.x, victim.y, gm.constants.oDot)

        -- Настройка параметров дота
        dot.target = victim.value                  -- цель дота
        dot.parent = actor.value                   -- источник дота
        dot.damage = hit_info.damage * 0.3         -- 30% от урона атаки
        dot.ticks = 10                             -- число тиков (кадров)
        dot.team = actor.team                      -- команда для избежания френдли фаера
        dot.textColor = Color(0xff4d00)            -- цвет текста урона
        dot.sprite_index = gm.constants.sSparks9   -- визуальный спрайт дота
    end
end)
