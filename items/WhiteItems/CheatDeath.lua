-- DeerItems-CheatDeath
-- Обман смерти: 10% (+5% за стак) полученного урона не наносится сразу, а растягивается
-- кровотечением на 5 секунд — у тебя появляется окно, чтобы перехилить удар.
-- (Адаптация Shark Teeth из RoR2.)
--
-- Что при 110%: доля «отложенного» урона ОГРАНИЧЕНА 100% (math.min). На ~19+ стаках
-- весь удар целиком превращается в кровотечение (мгновенного урона нет вовсе) — отсюда и
-- название. Без капа доля ушла бы за 100% и предмет «создавал» бы урон/лечение из воздуха.
-- Оговорка: как и Shark Teeth, не спасает от удара, который убивает мгновенно (если HP
-- ушло в 0 в тот же кадр, коллбек уже не успевает вернуть здоровье).

-- Спрайт предмета (кровь рисует движок через цвет урона DoT)
local sprite = Resources.sprite_load("DeerItems", "item/CheatDeath", PATH.."assets/sprites/items/sWhiteItems/CheatDeath.png", 1, 18, 18)

-- Балансные константы
local BASE_FRAC      = 0.10   -- 10% базовая доля удара уходит в кровотечение
local FRAC_PER_STACK = 0.05   -- +5% за стак
local DOT_TICKS      = 10     -- число тиков кровотечения
local DOT_RATE       = 30     -- кадров между тиками (30 = 0.5 сек) → 10 × 0.5 = 5 секунд

-- Создание предмета: белый тир, тег «лечение» (по сути про живучесть)
local item = Item.new("DeerItems", "CheatDeath")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

item:clear_callbacks()

item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if stack <= 0 then return end
    -- КРИТИЧНО: пропускаем урон от самого себя. Иначе тики НАШЕГО же кровотечения снова
    -- зашли бы сюда и плодили новые DoT (на 100% доле — лавинообразно).
    if attacker and actor:same(attacker) then return end

    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    -- Доля удара в кровотечение, с жёстким капом 100%
    local frac = math.min(1.0, BASE_FRAC + FRAC_PER_STACK * (stack - 1))
    local total = dmg * frac

    -- Возвращаем отложенную часть HP (удар уже прошёл полностью)...
    actor:heal(total)
    -- ...и наносим её же кровотечением: total за DOT_TICKS тиков как «сырой» урон, красным.
    -- source=actor + use_raw_damage=true → урон тика берётся как есть, без ×actor.damage.
    actor:apply_dot(total / DOT_TICKS, actor, DOT_TICKS, DOT_RATE, Color.RED, true)
end)
