-- DeerItems-ThinWings
-- При активации взаимодействий даёт временный бафф: ускорение и случайное сокращение кулдауна одной из способностей.

-- Загружаем спрайт предмета
-- Загружаем спрайт баффа
-- Загружаем спрайт эффекта активации
local sprite = Resources.sprite_load("DeerItems", "item/ThinWings", PATH.."assets/sprites/items/sWhiteItems/ThinWings.png", 1, 16, 16)
local buffSprite = Resources.sprite_load("DeerItems", "buff/ThinWings", PATH.."assets/sprites/buffs/ThinWings.png", 1, 7, 7)
local ActivateThinWings = Resources.sprite_load("DeerItems", "particle/ActivateThinWings", PATH.."assets/sprites/particle/ActivateThinWings.png", 7, 32, 32)

-- Создание предмета и баффа
local item = Item.new("DeerItems", "ThinWings")
local buff = Buff.new("DeerItems", "ThinWings")

-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Очистка старых коллбеков
item:clear_callbacks()

-- При активации взаимодействий даёт бафф
item:onInteractableActivate(function(actor, stack, interactable)
    -- Применяем бафф на 10 секунд за стак
    actor:buff_apply(buff, 10 * 60, stack)
    -- Визуальный эффект активации
    local ef = gm.instance_create(actor.x, actor.y - 40, gm.constants.oEfSparks)
    ef.sprite_index = ActivateThinWings
end)

-- Настройки отображения баффа
buff.show_icon = true
buff.icon_sprite = buffSprite
buff.icon_stack_subimage = false
buff.max_stack = 9999

-- Очистка старых коллбеков баффа
buff:clear_callbacks()

-- Модификация статов под действием баффа
buff:onStatRecalc(function(actor, stack)
    -- Увеличение максимальной горизонтальной скорости
    actor.pHmax = actor.pHmax + (0.19 + 0.22 * stack)
    -- Получаем ссылки на активные умения
    local secondary = actor:get_active_skill(Skill.SLOT.secondary)
    local utility = actor:get_active_skill(Skill.SLOT.utility)
    local special = actor:get_active_skill(Skill.SLOT.special)
    -- Рандомно выбираем одно из трёх умений
    local roll = math.random(3)
    if roll == 1 then
        -- Уменьшаем кулдаун вторичного умения
        secondary.cooldown = math.ceil(secondary.cooldown * 0.8)
    elseif roll == 2 then
        -- Уменьшаем кулдаун утилиты
        utility.cooldown = math.ceil(utility.cooldown * 0.9)
    else
        -- Уменьшаем кулдаун специального умения
        special.cooldown = math.ceil(special.cooldown * 0.8)
    end
end)
