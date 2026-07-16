-- DeerItems-ShadowShield
-- Даёт бафф в начале этапа: увеличивает броню и скорость, но исчезает при атаке. Длительность — 20 + 10 сек за стак.

-- Загружаем спрайт предмета
-- Загружаем спрайт баффа
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/ShadowShield", PATH.."assets/sprites/items/sGreenItems/ShadowShield.png", 1, 16, 16)
local buff_sprite = Resources.sprite_load("DeerItems", "buff/ShadowShield", PATH.."assets/sprites/buffs/ShadowShield.png", 1, 7.5, 7.5)
local sound = Resources.sfx_load("DeerItems", "sound/ShadowShield", PATH.."assets/sounds/ShadowShield.ogg")
local SHADOW_ALPHA = 0.85

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
    if gm._mod_net_isClient() then return end

    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
    -- Длительность: 20 + 10 сек за стак
    actor:buff_apply(buff, 60 * (20 + 10 * stack), stack)
end)

-- При ударе бафф исчезает полностью
item:onHitProc(function(actor, victim, stack, hit_info)
    if gm._mod_net_isClient() then return end

    if actor:buff_stack_count(buff) >= 1 then
        actor:buff_remove(buff, stack)
    end
end)

-- Настройки баффа
buff.icon_sprite = buff_sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = false
buff.show_icon = true
buff.is_debuff = false
buff.max_stack = 9999
local function draw_shadow(actor)
    gm.draw_sprite_ext(
        actor.sprite_index,
        actor.image_index,
        actor.x,
        actor.y,
        actor.image_xscale,
        actor.image_yscale,
        actor.image_angle,
        Color.BLACK,
        SHADOW_ALPHA
    )

    if actor.actor_state_current_id ~= -1
    and not actor:actor_state_is_climb_state(actor.actor_state_current_id)
    and actor.sprite_index2 then
        gm.draw_sprite_ext(
            actor.sprite_index2,
            actor.image_index,
            actor.x,
            actor.y,
            actor.image_xscale,
            actor.image_yscale,
            actor.image_angle,
            Color.BLACK,
            SHADOW_ALPHA
        )
    end
end

-- Очистка всех старых коллбеков
buff:clear_callbacks()

buff:onPostDraw(function(actor, stack)
    draw_shadow(actor)
end)

-- Эффекты баффа: скорость и броня
buff:onStatRecalc(function(actor, stack)
    -- Увеличение скорости передвижения
    actor.pHmax = actor.pHmax + (0.28 + 0.27 * stack)
    -- Увеличение брони
    actor.armor = actor.armor + (40 + 20 * stack)
end)
