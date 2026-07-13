-- DeerItems-Concentration
-- Charges after SAFE_FRAMES; incoming damage does not reset it.
-- The charge is spent only when the actor deals positive hit damage.

-- Спрайт предмета
-- Партикл готовности усиленного удара
-- Звук в момент готовности
local sprite = Resources.sprite_load("DeerItems", "item/Concentration", PATH.."assets/sprites/items/sWhiteItems/Concentration.png", 1, 18, 18)
local critParticle = Resources.sprite_load("DeerItems", "particle/ConcentrationCrit", PATH.."assets/sprites/particle/ConcentrationCrit.png", 1, 8, 8)
local readySound = Resources.sfx_load("DeerItems", "sound/Concentration", PATH.."assets/sounds/Concentration.ogg")

local GUID = _ENV["!guid"]

-- Балансные константы
local SAFE_FRAMES   = 3 * 60   -- 3 секунд без урона до зарядки
local DMG_PER_STACK = 0.60     -- +60% урона за стак на усиленном ударе

-- Создание предмета: белый тир, тег «урон»
local item = Item.new("DeerItems", "Concentration")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

item:clear_callbacks()

-- «Заряжено», если с последнего полученного урона прошло >= SAFE_FRAMES кадров
local function is_ready(data)
    return (Global._current_frame - (data.cc_last_hit or -math.huge)) >= SAFE_FRAMES
end

item:onAcquire(function(actor, stack)
    local data = actor:get_data("Concentration", GUID)
    data.cc_last_hit = Global._current_frame
    data.cc_was_ready = false
end)

-- Усиленный удар: при попадании, если заряжено — добавляем +60%/стак отдельным хитом
item:onHitProc(function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    local data = actor:get_data("Concentration", GUID)
    if not is_ready(data) then return end

    -- Урон — только на хосте (чтобы в сетевой игре не было двойного бонус-хита),
    -- но заряд тратим на всех клиентах, иначе партикл/звук готовности рассинхронятся.
    if gm._mod_net_isHost() then
        local base = actor.damage or 0
        if base > 0 and dmg > 0 then
            -- coef переводит «+60%/стак от урона этого попадания» в коэффициент fire_direct
            local coef = (DMG_PER_STACK * stack * dmg) / base
            actor:fire_direct(victim, coef, nil, nil, nil, nil, false)
        end
    end

    -- Тратим заряд: таймер 5 секунд стартует заново
    data.cc_last_hit = Global._current_frame
end)

-- Звук ровно в момент, когда удар стал готов (переход «не готово → готово»)
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    local data = actor:get_data("Concentration", GUID)
    local ready = is_ready(data)
    if ready and not data.cc_was_ready then
        actor:sound_play(readySound, 1.0, 1.0 + math.random() * 0.1)
    end
    data.cc_was_ready = ready
end)

-- Партикл ровно ПОД персонажем, пока усиленный удар готов
item:onPostDraw(function(actor, stack)
    if stack <= 0 then return end
    if is_ready(actor:get_data("Concentration", GUID)) then
        gm.draw_sprite(critParticle, 0, actor.x, actor.y + 60)
    end
end)
