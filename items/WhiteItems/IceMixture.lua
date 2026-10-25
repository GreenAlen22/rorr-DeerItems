-- DeerItems-IceMixture
-- При попадании с шансом накладывает дебафф, снижающий скорость передвижения и атаки на 30% на 3 секунды.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Sprite.new("item/IceMixture", PATH.."assets/sprites/items/sWhiteItems/IceMixture.png", 1, 16, 16)
local sound = Sound.new("sound/IceMixture", PATH.."assets/sounds/IceMixture.ogg")

-- Создание предмета IceMixture
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилита — замедление при ударе, как у ванильных Prison Shackles
local item = Item.new("IceMixture")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- guid мода (ускоряет get_data) и ленивый кэш ссылки на дебафф
local GUID = _ENV["!guid"]
local iceBuff

-- Очистка старых коллбеков
-- При попадании атакой срабатывает шанс наложить замедляющий дебафф
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end

    -- Шанс 7% (2+5) и + 5% за стак
	if math.random() <= 0.02 + (0.05 * stack) then
        -- Звук на цели при наложении: всегда случайные громкость и интонация
        DeerItemsSound.play_at(sound, victim.x, victim.y, 0.8 + math.random() * 0.6, 0.7 + math.random() * 0.6)
        -- Применение дебаффа
        iceBuff = iceBuff or Buff.find("IceMixture", "DeerItems")
        victim:buff_apply(iceBuff, 1)
    end
end)

-- Дебафф предмета IceMixture.
-- Дебафф, замедляющий передвижение и скорость атаки на 30% в течение 3 секунд

-- Создание дебаффа
local buff = Buff.new("IceMixture")
buff.show_icon = false
buff.icon_stack_subimage = false
buff.max_stack = 1
buff.is_timed = false
buff.is_debuff = true

-- При применении — запускаем таймер и меняем визуал
DeerItemsCallbacks.buff_apply(buff, function(actor, stack)
    local actorData = Instance.get_data(actor, "IceMixture", GUID)
    if not actorData.timers then
        actorData.timers = {}
    end
    -- Каждый стак имеет 3 секунды длительности
    table.insert(actorData.timers, 3 * 60.0)
    -- Эффект затемнения
    actor.image_blend = Color(0xa8dbff)
end)

-- Обновление таймеров каждого стека
DeerItemsCallbacks.buff_post_step(buff, function(actor, stack)
    local actorData = Instance.get_data(actor, "IceMixture", GUID) or {}
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
DeerItemsCallbacks.buff_remove(buff, function(actor, stacks_removed)
    actor.image_blend = Color(0xFFFFFF)
end)

-- Изменение статов под действием дебаффа
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack, api)
    api.pHmax_mult(0.70)                      -- минус 30% к скорости передвижения
    api.attack_speed_mult(0.70)               -- минус 30% к скорости атаки
end)
