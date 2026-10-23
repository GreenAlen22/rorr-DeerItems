-- DeerItems-Concentration
-- Заряжается через SAFE_FRAMES кадров. Полученный урон таймер не сбрасывает.
-- Заряд тратится только при попадании, которое нанесло положительный урон.

-- Спрайт предмета
-- Партикл готовности усиленного удара
-- Звук в момент готовности
local sprite = Sprite.new("item/Concentration", PATH.."assets/sprites/items/sWhiteItems/Concentration.png", 1, 18, 18)
local critParticle = Sprite.new("particle/ConcentrationCrit", PATH.."assets/sprites/particle/ConcentrationCrit.png", 1, 8, 8)
local readySound = Sound.new("sound/Concentration", PATH.."assets/sounds/Concentration.ogg")

local GUID = _ENV["!guid"]

-- Заряд тратит ON_HIT_PROC, а его зовёт только хост: клиент выходит из
-- damager_attack_process раньше damager_hit_process. Клиенту трата нужна для партикла
-- и звука готовности, поэтому едет пакетом. Шлём событие, а не кадр: _current_frame
-- у каждой машины свой.
local packet_spent = Packet.new("Concentration-packet_spent")

-- Балансные константы
local SAFE_FRAMES   = 3 * 60   -- 3 секунд без урона до зарядки
local DMG_PER_STACK = 0.60     -- +60% урона за стак на усиленном ударе

-- Создание предмета: белый тир, тег «урон»
local item = Item.new("Concentration")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- «Заряжено», если с последнего полученного урона прошло >= SAFE_FRAMES кадров
local function is_ready(data)
    return (Global._current_frame - (data.cc_last_hit or -math.huge)) >= SAFE_FRAMES
end

DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    local data = Instance.get_data(actor, "Concentration", GUID)
    data.cc_last_hit = Global._current_frame
    data.cc_was_ready = false
end)

packet_spent:set_serializers(function(buffer, actor)
    buffer:write_instance(actor)
end, function(buffer)
    local actor = buffer:read_instance()
    if not Net.client then return end
    if actor ~= Instance.INVALID and Instance.exists(actor) then
        Instance.get_data(actor, "Concentration", GUID).cc_last_hit = Global._current_frame
    end
end)

-- Усиленный удар: при попадании, если заряжено — добавляем +60%/стак отдельным хитом
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    local data = Instance.get_data(actor, "Concentration", GUID)
    if not is_ready(data) then return end

    local base = actor.damage or 0
    if base > 0 then
        -- coef переводит «+60%/стак от урона этого попадания» в коэффициент fire_direct
        local coef = (DMG_PER_STACK * stack * dmg) / base
        actor:fire_direct(victim, coef, nil, nil, nil, nil, false)
    end

    -- Тратим заряд: таймер стартует заново
    data.cc_last_hit = Global._current_frame
    packet_spent:send_to_all(actor)
end)

-- Звук ровно в момент, когда удар стал готов (переход «не готово → готово»)
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if stack <= 0 then return end
    local data = Instance.get_data(actor, "Concentration", GUID)
    local ready = is_ready(data)
    if ready and not data.cc_was_ready then
        actor:sound_play(readySound, 1.0, 1.0 + math.random() * 0.1)
    end
    data.cc_was_ready = ready
end)

-- Партикл ровно ПОД персонажем, пока усиленный удар готов
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    if stack <= 0 then return end
    if is_ready(Instance.get_data(actor, "Concentration", GUID)) then
        gm.draw_sprite(critParticle.value, 0, actor.x, actor.y + 60)
    end
end)
