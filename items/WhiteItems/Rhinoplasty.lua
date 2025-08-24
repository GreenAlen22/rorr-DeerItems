-- DeerItems-Rhinoplasty
-- За каждые 4 убийства даёт временный бафф, который по истечении времени лечит. Имеет кулдаун 20 секунд между срабатываниями.

-- Загружаем спрайт предмета
-- Загружаем спрайт баффа
local sprite = Resources.sprite_load("DeerItems", "item/Rhinoplasty", PATH.."assets/sprites/items/sWhiteItems/Rhinoplasty.png", 1, 16, 16)
local spriteBuff = Resources.sprite_load("DeerItems", "buff/Rhinoplasty", PATH.."assets/sprites/buffs/Rhinoplasty.png", 1, 6, 8)

-- Создание предмета Rhinoplasty
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("DeerItems", "Rhinoplasty")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- Создание баффа, применяемого за убийства
local buff = Buff.new("DeerItems", "Rhinoplasty")
buff.icon_sprite = spriteBuff
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.max_stack = 999
buff.is_timed = true

-- При убийстве увеличиваем счётчик убийств
item:onKillProc(function(actor, victim, stack)
    local data = actor:get_data("Rhinoplasty")
    if not data or type(data) ~= "table" then
        data = { kills = 0, cooldown = 0 }
        actor:set_data("Rhinoplasty", data)
    end
    -- Безопасная инициализация значений
    if data.cooldown == nil then data.cooldown = 0 end
    if data.kills == nil then data.kills = 0 end
    -- Увеличиваем счётчик убийств
    data.kills = data.kills + 1
end)

-- Проверка условий применения баффа каждый кадр
item:onPostStep(function(actor, stack)
    local data = actor:get_data("Rhinoplasty")
    if not data or type(data) ~= "table" then
        data = { kills = 0, cooldown = 0 }
        actor:set_data("Rhinoplasty", data)
    end

    if data.cooldown == nil then data.cooldown = 0 end
    if data.kills == nil then data.kills = 0 end

    -- Отсчёт кулдауна
    if data.cooldown > 0 then
        data.cooldown = data.cooldown - 1

    -- Если достигнуто 4+ убийства и кулдаун отсутствует — даём бафф
    elseif data.kills >= 4 then
        local stacksToGive = math.floor(data.kills / 4)

        -- Применение баффа на 10 секунд за каждые 4 убийства
        actor:buff_apply(buff, 60 * 10, stacksToGive)

        -- Сохраняем остаток убийств, сбрасываем кулдаун
        data.kills = data.kills % 4
        data.cooldown = 60 * 20
    end
end)

-- Когда бафф истекает — лечим
buff:onRemove(function(actor, stacks)
    stacks = stacks or 1
    -- Лечение: 40 за 1 стак, +20 за каждый дополнительный
    local healAmount = 40 + (stacks - 1) * 20
    actor:heal(healAmount)
    actor:sound_play_at(gm.constants.wUse, 1.0, 0.7, actor.x, actor.y)
end)
