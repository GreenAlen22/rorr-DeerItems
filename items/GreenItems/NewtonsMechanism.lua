-- DeerItems-NewtonsMechanism
-- Даёт щит (4% от макс. HP). Пока щит есть — +30 брони (+30 за шт.).
-- Когда щит пробивают — выпускает оглушающий пульс: 100% урона + 100% (+10% за шт.) от макс. щита.

-- Загружаем спрайт предмета
-- Загружаем спрайты эффектов
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/NewtonsMechanism", PATH.."assets/sprites/items/sGreenItems/NewtonsMechanism.png", 1, 17, 17)
local voltOverload = Resources.sprite_load("DeerItems", "paticle/voltOverload", PATH.."assets/sprites/particle/voltOverload.png", 13, 64, 112)
local voltOverloadHit = Resources.sprite_load("DeerItems", "paticle/voltOverloadHit", PATH.."assets/sprites/particle/voltOverloadHit.png", 6, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/voltOverload", PATH.."assets/sounds/voltOverload.ogg")

-- guid мода выносим один раз — чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

-- Балансные константы
local ARMOR_PER_STACK   = 5     -- +5 брони за стак, пока есть щит
local PULSE_PLAYER_BASE = 1.5    -- пульс: 150% базового урона
local PULSE_PLAYER_STACK= 1.25   -- +125% базового урона за каждый доп. стак
local PULSE_SHIELD_BASE = 1.25    -- пульс: +125% от макс. щита
local PULSE_SHIELD_STACK= 1.0    -- +100% от макс. щита за стак сверх первого
local STUN_SECONDS      = 1.5    -- длительность оглушения от пульса
local RADIUS_BASE       = 3 * 32      -- базовый радиус пульса (3 м)
local RADIUS_STACK      = 0.5 * 32    -- +0.5 м радиуса за стак сверх первого

-- Создание предмета NewtonsMechanism
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("DeerItems", "NewtonsMechanism")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

item:clear_callbacks()

-- Пока у игрока есть щит из любого источника, даём броню.
item:onStatRecalc(function(actor, stack)
    if stack <= 0 then return end
    -- Броня — только пока у игрока реально есть щит.
    if (actor.shield or 0) > 0 then
        actor.armor = actor.armor + ARMOR_PER_STACK * stack
    end
end)

-- Оглушающий пульс при пробитии щита: 150%(+75%/стак) базового урона + 100%(+50%/стак) от макс. щита.
local function release_pulse(actor, stack)
    local radius = RADIUS_BASE + RADIUS_STACK * (stack - 1)
    -- ПЛОСКИЙ урон по ТЗ: 150%(+75%/стак) базового урона + 100%(+50%/стак) от макс. щита.
    -- ВНИМАНИЕ: параметр damage у fire_explosion — это КОЭФФИЦИЕНТ (движок умножает его на
    -- actor.damage). Без поправки получалось dmg×actor.damage ≈ урон в квадрате (било слишком сильно).
    -- Поэтому форсим «сырой» урон через use_raw_damage()+set_damage(), как в Домбре.
    local dmg = actor.damage * (PULSE_PLAYER_BASE + PULSE_PLAYER_STACK * (stack - 1))
              + actor.maxshield * (PULSE_SHIELD_BASE + PULSE_SHIELD_STACK * (stack - 1))

    -- Оба визуальных спрайта nil — рисуем РОВНО ОДИН спрайт вручную (без двойной молнии).
    -- proc=false: пульс не должен прокать другие предметы и сам себя.
    local attack = actor:fire_explosion(actor.x, actor.y, radius, radius, dmg, nil, nil, false)
    attack.max_hit_number = 5 + 10 * stack
    -- Оглушение поражённых врагов + фиксация плоского урона (без крита)
    if attack and attack.attack_info then
        attack.attack_info:use_raw_damage()
        attack.attack_info:set_damage(dmg)
        attack.attack_info:set_critical(false)
        attack.attack_info:set_stun(STUN_SECONDS)
    end

    -- Один спрайт молнии: высота = радиус, ширина = 0.8×высоты (пропорция арта). Спрайт 64×112 px.
    local ef = gm.instance_create(actor.x, actor.y, gm.constants.oEfExplosion)
    ef.sprite_index = voltOverload
    ef.image_yscale = radius / 112
    ef.image_xscale = (radius * 0.8) / 64

    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.2)
    actor:screen_shake(3)
end

-- Каждый кадр: ловим пробитие щита и держим бонус брони актуальным.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("DeerItems", GUID)
    if data.nm_cd and data.nm_cd > 0 then data.nm_cd = data.nm_cd - 1 end
    local shield = actor.shield or 0
    local prev = data.nm_prev_shield or 0

    -- Щит пробит (был > 0, стал ≤ 0) → выпускаем пульс. Кулдаун = защита от ДВОЙНОЙ молнии:
    -- если детект пробития срабатывает несколько кадров подряд (щит «дёргается» у нуля или из-за
    -- пересчёта статов), пульс и его визуал больше не дублируются.
    if prev > 0 and shield <= 0 and (data.nm_cd or 0) <= 0 then
        if not gm._mod_net_isClient() then
            release_pulse(actor, stack)
        end
        data.nm_cd = 30
    end

    -- Наличие щита переключилось → пересчёт, чтобы +30 брони включалось/выключалось вовремя
    if (prev > 0) ~= (shield > 0) then
        actor:recalculate_stats()
    end

    data.nm_prev_shield = shield
end)
