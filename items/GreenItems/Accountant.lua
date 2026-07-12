-- DeerItems-Accountant
-- При использовании оборудования даёт бафф на 6 + 3 сек за стак. Бонус скорости атаки зависит от КД снаряжения.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/Accountant", PATH.."assets/sprites/items/sGreenItems/Accountant.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/Accountant", PATH.."assets/sounds/Accountant.ogg")

local GUID = _ENV["!guid"]

local MAX_ATTACK_SPEED_BONUS = 0.60
local MAX_BONUS_COOLDOWN = 135

-- Создание предмета и баффа Accountant
local item = Item.new("DeerItems", "Accountant")
local buff = Buff.new("DeerItems", "Accountant")

-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- Очистка предыдущих коллбеков
item:clear_callbacks()

local function cooldown_seconds(value)
    if not value or value <= 0 then return 0 end
    return value > 300 and (value / 60) or value
end

local function attack_speed_bonus(actor, equipment)
    local cd
    if equipment then
        local ok, value = pcall(function()
            return equipment.cooldown
        end)
        if ok then cd = value end
    end

    if not cd or cd <= 0 then
        cd = (actor:get_equipment_cooldown() or 0) / 60
    else
        cd = cooldown_seconds(cd)
    end

    return MAX_ATTACK_SPEED_BONUS * (math.min(cd, MAX_BONUS_COOLDOWN) / MAX_BONUS_COOLDOWN)
end

-- При использовании снаряжения — применяем бафф
item:onEquipmentUse(function(actor, stack, equipment)
    actor:get_data("Accountant", GUID).attack_speed_bonus = attack_speed_bonus(actor, equipment)
    actor:buff_apply(buff, 60 * (6 + 3 * (stack - 1)), 1)

    -- Воспроизведение звука активации: всегда случайные громкость и интонация
    actor:sound_play(sound, 1.6 + math.random() * 0.8, 0.7 + math.random() * 0.6)
end)

-- Настройки баффа: скрыт, не дебафф, максимум 1 стак
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1

-- Очистка предыдущих коллбеков баффа
buff:clear_callbacks()
buff:onStatRecalc(function(actor, stack)
    local data = actor:get_data("Accountant", GUID)
    actor.attack_speed = actor.attack_speed * (1 + (data.attack_speed_bonus or 0))
end)
