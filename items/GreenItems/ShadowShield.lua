-- DeerItems-ShadowShield
-- Даёт бафф в начале этапа: увеличивает броню и скорость, но исчезает при атаке. Длительность — 20 + 10 сек за стак.

-- Загружаем спрайт предмета
-- Загружаем спрайт баффа
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/ShadowShield", PATH.."assets/sprites/items/sGreenItems/ShadowShield.png", 1, 16, 16)
local buff_sprite = Resources.sprite_load("DeerItems", "buff/ShadowShield", PATH.."assets/sprites/buffs/ShadowShield.png", 1, 7.5, 7.5)
local sound = Resources.sfx_load("DeerItems", "sound/ShadowShield", PATH.."assets/sounds/ShadowShield.ogg")

-- Создание предмета и баффа ShadowShield
local item = Item.new("DeerItems", "ShadowShield")
local buff = Buff.new("DeerItems", "ShadowShield")

-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- В начале этапа даёт временный бафф
item:onStageStart(function(actor, stack)
    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
    -- Длительность: 20 + 10 сек за стак
    actor:buff_apply(buff, 60 * (20 + 10 * stack), stack)
end)

-- При ударе бафф исчезает полностью
item:onHitProc(function(actor, victim, stack, hit_info)
    if actor:buff_stack_count(buff) >= 1 then
        actor:buff_remove(buff, stack)
        actor.image_blend = Color(0xffffff)
    end
end)

-- Настройки баффа
buff.icon_sprite = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = false
buff.show_icon = true
buff.is_debuff = false
buff.max_stack = 9999

-- Очистка всех старых коллбеков
buff:clear_callbacks()
-- Эффекты баффа: скорость, броня, затемнение спрайта
buff:onStatRecalc(function(actor, stack)
    -- Увеличение скорости передвижения
    actor.pHmax = actor.pHmax + (0.28 + 0.27 * stack)
    -- Увеличение брони
    actor.armor = actor.armor + (40 + 20 * stack)
    -- Затемнение цвета спрайта
    actor.image_blend = Color(0x1a1a1a)
end)
