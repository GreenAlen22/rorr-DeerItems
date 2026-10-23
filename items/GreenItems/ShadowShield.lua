-- DeerItems-ShadowShield
-- Даёт бафф в начале этапа: увеличивает броню и скорость, но исчезает при атаке. Длительность — 20 + 10 сек за стак.

-- Загружаем спрайт предмета
-- Загружаем спрайт баффа
-- Загружаем звуковой эффект
local sprite = Sprite.new("item/ShadowShield", PATH.."assets/sprites/items/sGreenItems/ShadowShield.png", 1, 16, 16)
local buff_sprite = Sprite.new("buff/ShadowShield", PATH.."assets/sprites/buffs/ShadowShield.png", 1, 7.5, 7.5)
local sound = Sound.new("sound/ShadowShield", PATH.."assets/sounds/ShadowShield.ogg")
local SHADOW_ALPHA = 0.85

-- Создание предмета и баффа ShadowShield
local item = Item.new("ShadowShield")
local buff = Buff.new("ShadowShield")

-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- В начале этапа даёт временный бафф
DeerItemsCallbacks.item_stage_start(item, function(actor, stack)
    if Net.client then return end

    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
    -- Длительность: 20 + 10 сек за стак
    actor:buff_apply(buff, 60 * (20 + 10 * stack), stack)
end)

-- При ударе бафф исчезает полностью
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if Net.client then return end

    if actor:buff_count(buff) >= 1 then
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
DeerItemsCallbacks.buff_post_draw(buff, function(actor, stack)
    draw_shadow(actor)
end)

-- Эффекты баффа: скорость и броня
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack, api)
    -- Увеличение скорости передвижения
    api.pHmax_add(0.28 + 0.27 * stack)
    -- Увеличение брони
    api.armor_add(40 + 20 * stack)
end)
