-- DeerItems-MagmaFragment
-- При попадании атакой с шансом 5% за стак накладывает дот-эффект (горение) на врага, нанося 30% от урона атаки.
-- На одной цели одновременно держится только один эффект горения (повторный прок обновляет его).

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/MagmaFragment", PATH.."assets/sprites/items/sWhiteItems/MagmaFragment.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/MagmaFragment", PATH.."assets/sounds/MagmaFragment.ogg")

-- guid мода выносим один раз — чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

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
    -- 5% за каждый стак или принудительный прок
    if math.random() <= 0.05 * stack or hit_info.attack_info:get_attack_flag(Attack_Info.ATTACK_FLAG.force_proc) then
        -- Воспроизведение звука при срабатывании
        victim:sound_play(sound, 1.0, 0.9 + math.random() * 0.2)

        local dmg = hit_info.damage * 0.3          -- 30% от урона атаки
        local vdata = victim:get_data("DeerItems_Magma", GUID)

        -- Один эффект горения на цель: если прежний дот ещё жив — обновляем его,
        -- иначе создаём новый. Так горение не накладывается несколько раз при 100% шансе.
        if vdata.dot and Instance.exists(vdata.dot) then
            vdata.dot.damage = math.max(vdata.dot.damage, dmg) -- берём больший урон
            vdata.dot.ticks = 10                               -- продлеваем длительность
        else
            -- Создание объекта дота (урон по времени)
            local dot = gm.instance_create(victim.x, victim.y, gm.constants.oDot)
            dot.target = victim.value                  -- цель дота
            dot.parent = actor.value                   -- источник дота
            dot.damage = dmg
            dot.ticks = 10                             -- число тиков (кадров)
            dot.team = actor.team                      -- команда для избежания френдли фаера
            dot.textColor = Color(0xff4d00)            -- цвет текста урона
            dot.sprite_index = gm.constants.sSparks9   -- визуальный спрайт дота
            vdata.dot = dot
        end
    end
end)
