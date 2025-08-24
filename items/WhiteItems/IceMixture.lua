-- DeerItems-IceMixture
-- При попадании с шансом накладывает дебафф, снижающий скорость передвижения и атаки на 30% на 3 секунды.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/IceMixture", PATH.."assets/sprites/items/sWhiteItems/IceMixture.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/IceMixture", PATH.."assets/sounds/IceMixture.ogg")

-- Создание предмета IceMixture
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "IceMixture")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Очистка старых коллбеков
item:clear_callbacks()
-- При попадании атакой срабатывает шанс наложить замедляющий дебафф
item:onHitProc(function(actor, victim, stack, hit_info)
    -- Шанс 7% (2+5) и + 5% за стак
	if math.random() <= 0.02 + (0.05 * stack) then
        -- Звук на цели при наложении
        victim:sound_play(sound, 1.0, 0.9 + math.random() * 0.2)
        -- Применение дебаффа
        victim:buff_apply(Buff.find("DeerItems-IceMixture"), 1)
    end
end)

-- deBuff: IceMixture
-- Дебафф, замедляющий передвижение и скорость атаки на 30% в течение 3 секунд

-- Создание дебаффа
local buff = Buff.new("DeerItems", "IceMixture")
buff.show_icon = false
buff.icon_stack_subimage = false
buff.max_stack = 1
buff.is_timed = false
buff.is_debuff = true

-- При применении — запускаем таймер и меняем визуал
buff:onApply(function(actor, stack)
    local actorData = actor:get_data("IceMixture")
    if not actorData.timers then
        actorData.timers = {}
    end
    -- Каждый стак имеет 3 секунды длительности
    table.insert(actorData.timers, 3 * 60.0)
    -- Эффект затемнения
    actor.image_blend = Color(0xa8dbff)
end)

-- Обновление таймеров каждого стека
buff:onPostStep(function(actor, stack)
    local actorData = actor:get_data("IceMixture") or {}
    -- Обновляем таймеры и удаляем истекшие
    if actorData.timers then
        for i = #actorData.timers, 1, -1 do
            actorData.timers[i] = actorData.timers[i] - 1
            if actorData.timers[i] <= 0 then
                table.remove(actorData.timers, i)
            end
        end
    end
    -- Удаляем лишние стаки, если их больше, чем оставшихся таймеров
    local diff = stack - #(actorData.timers or {})
    if diff > 0 then
        actor:buff_remove(buff, diff)
        actor:recalculate_stats()
    end
end)

-- При снятии дебаффа — восстанавливаем цвет
buff:onRemove(function(actor, stacks_removed)
    actor.image_blend = Color(0xFFFFFF)
end)

-- Изменение статов под действием дебаффа
buff:onStatRecalc(function(actor, stack)
    actor.pHmax = actor.pHmax * 0.70          -- минус 30% к скорости передвижения
    actor.attack_speed = actor.attack_speed * 0.70 -- минус 30% к скорости атаки
end)
