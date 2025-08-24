-- DeerItems-NewtonsMechanism
-- При получении урона ≥ 5% от max HP выпускает электрический взрыв, наносящий AOE-урон и визуальные эффекты.

-- Загружаем спрайт предмета
-- Загружаем спрайты эффектов
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/NewtonsMechanism", PATH.."assets/sprites/items/sGreenItems/NewtonsMechanism.png", 1, 16, 16)
local voltOverload = Resources.sprite_load("DeerItems", "paticle/voltOverload", PATH.."assets/sprites/particle/voltOverload.png", 13, 64, 112)
local voltOverloadHit = Resources.sprite_load("DeerItems", "paticle/voltOverloadHit", PATH.."assets/sprites/particle/voltOverloadHit.png", 6, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/voltOverload", PATH.."assets/sounds/voltOverload.ogg")

-- Создание предмета NewtonsMechanism
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "NewtonsMechanism")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- При получении урона ≥ 5% от max HP — создаём взрыв
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    -- Проверки: валидный урон и порог в 5% от maxhp
    if not hit_info or not hit_info.damage or hit_info.damage <= 0 then return end
    if not actor or not actor.maxhp or hit_info.damage < actor.maxhp * 0.05 then return end
    -- Радиус взрыва (увеличивается с количеством стаков)
    local radius = 1.5 * stack * 32 * 2
    -- Урон: от 30% от полученного урона +10% за каждый последующий стак
    local mult = 0.3 + (stack - 1) * 0.1
    local dmg = hit_info.damage * mult

    -- Создание взрыва
    local attack = actor:fire_explosion(
        actor.x, 
        actor.y, 
        radius,
        radius, 
        dmg,
        voltOverload,
        voltOverloadHit,
        true
    )

    -- Ограничение количества целей
    attack.max_hit_number = 5 + 10 * stack
    -- 5% шанс воспроизведения звука
    if math.random() <= 0.05 then
        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.2)
    end
    -- Визуальный shake экрана
    actor:screen_shake(2)
end)
