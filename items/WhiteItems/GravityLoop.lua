-- DeerItems-GravityLoop
-- При получении урона на низком здоровье лечит и тратит один стак, заменяя его на "GravityLoopDeactivate".

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
-- Загружаем спрайт эффекта
local sprite = Sprite.new("item/GravityLoop", PATH.."assets/sprites/items/sWhiteItems/GravityLoop.png", 1, 16, 16)
local sound = Sound.new("sound/GravityLoop", PATH.."assets/sounds/GravityLoop.ogg")
local GravityLoopBreack = Sprite.new("particle/GravityLoopBreack", PATH.."assets/sprites/particle/GravityLoopBreack.png", 15, 50, 50)

-- ленивый кэш ссылки на сломанную версию (на загрузке может быть ещё не зарегистрирована)
local deactivate

-- `sound_play` и ванильные эффекты видны только на локальной машине. Поэтому
-- хост отдельно передаёт клиентам сигнал для звука и визуального эффекта.
local packet_trigger = Packet.new("GravityLoop-packet_trigger")
packet_trigger:set_serializers(function(buffer, actor, pitch)
    buffer:write_instance(actor)
    buffer:write_float(pitch)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local pitch = buffer:read_float()
    if not Instance.exists(actor) then return end

    actor:sound_play(sound, 2.0, pitch)
    local ef = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
    ef.sprite_index = GravityLoopBreack.value
end)

-- Создание нового предмета с названием "GravityLoop" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("GravityLoop")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING

-- Обработка триггера при получении урона
DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if Net.client then return end

    -- Срабатывает, если текущее HP упало до 25% или ниже
    if actor.hp <= actor.maxhp * 0.35 then
        -- Лечение на 70% от максимального HP
        actor:heal(actor.maxhp * 0.7)

        -- Воспроизводим звуковой эффект
        local sound_pitch = 0.9 + math.random() * 0.5
        actor:sound_play(sound, 2.0, sound_pitch)

        -- Эффект искр с кастомным спрайтом
        local ef = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
        ef.sprite_index = GravityLoopBreack.value

        if Net.host then
            packet_trigger:send_to_all(actor, sound_pitch)
        end

        -- Получаем ссылку на предмет, заменяющий использованный стак
        deactivate = deactivate or Item.find("GravityLoopDeactivate", "DeerItems")
        local item_used = deactivate

        -- Удаляем 1 обычный стак и добавляем 1 сломанный
        local normal = actor:item_count(item, Item.StackKind.NORMAL)
        if normal > 0 then
            actor:item_take(item, 1)
            actor:item_give(item_used, 1)
            return
        end

        -- Если обычных стаков нет — заменяем временный/синий стак
        local temp = actor:item_count(item, Item.StackKind.TEMPORARY_BLUE)
        if temp > 0 then
            actor:item_take(item, 1, Item.StackKind.TEMPORARY_BLUE)
            actor:item_give(item_used, 1, Item.StackKind.TEMPORARY_BLUE)
            return
        end
    end
end)
