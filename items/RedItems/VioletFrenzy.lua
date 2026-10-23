-- DeerItems-VioletFrenzy / «Лиловое неистовство» / "Violet Frenzy"
-- Порт Brainstalks из RoR2.
-- При убийстве элитного монстра (или босса) игрок входит в состояние берсерка на 4 (+4 за шт.) секунды.
-- Пока берсерк активен, перезарядка ВСЕХ умений составляет 0,5 секунды, а экран слегка подкрашивается лиловым.

-- Загружаем спрайт предмета (плейсхолдер — копия Community.png; замени на финальный арт по этому пути)
local sprite = Sprite.new("item/VioletFrenzy", PATH.."assets/sprites/items/sRedItems/VioletFrenzy.png", 1, 18, 17)

-- guid мода: ускоряет get_data (без обхода debug-стека на каждом кадре)
local GUID = _ENV["!guid"]

-- Настройки баланса
local BASE_SECONDS = 8
local STACK_SECONDS = 6
local SPEED_MULT  = 1.3
local TINT        = Color(0x8A2BE2)  -- лиловый (blueviolet, RGB)
local TINT_ALPHA  = 0.16             -- сила экранной подсветки

-- Создание предмета VioletFrenzy
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: утилитарный предмет (как Brainstalks)
local item = Item.new("VioletFrenzy")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Очистка старых коллбеков
-- Бафф-флаг «берсерк». Сам по себе статов не меняет — служит индикатором состояния
-- (по нему экранный хук решает, красить ли экран, а HUD показывает иконку).
local buff = Buff.new("VioletFrenzy")
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1
DeerItemsCallbacks.buff_stat_recalc(buff, function(actor, stack, api)
    api.pHmax_mult(SPEED_MULT)
end)

-- Безопасное приведение значения GML-функции (true / 1.0 / 0.0) к булеву
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

-- Является ли убитый элитой или боссом
local function is_elite_or_boss(victim)
    if not victim or not Instance.exists(victim) then return false end
    if GM.actor_is_boss and truthy(GM.actor_is_boss(victim)) then return true end
    if GM.actor_is_elite and truthy(GM.actor_is_elite(victim)) then return true end
    return false
end

-- При убийстве элиты — входим (или продлеваем) берсерк.
-- Таймер ОБНОВЛЯЕТСЯ до полной длительности (не суммируется), как в RoR2:
-- чтобы держать берсерк, нужно убивать элиту не реже, чем раз в длительность. Это естественный кэп аптайма.
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if Net.client then return end

    if not is_elite_or_boss(victim) then return end
    stack = stack or 1
    local data = Instance.get_data(actor, nil, GUID)
    local full = (BASE_SECONDS + STACK_SECONDS * (stack - 1)) * 60
    data.berserk = math.max(data.berserk or 0, full)
end)

local function is_berserk(actor)
    return actor:buff_count(buff) > 0 or (Instance.get_data(actor, nil, GUID).berserk or 0) > 0
end

local function reduce_slot_cooldown(actor, slot)
    local sk = actor:get_active_skill(slot)
    if not sk then return end

    local cooldown = sk.cooldown or sk.cooldown_base or 0
    if cooldown <= 0 then return end
    if not sk.cooldown_stopwatch or not actor:stopwatch_is_active(sk.cooldown_stopwatch) then return end

    local remaining = actor:stopwatch_get_duration_remaining(sk.cooldown_stopwatch)
    if not remaining or remaining <= 0 then return end

    local reduced = math.max(0, math.ceil(remaining - cooldown * 0.5))
    if reduced <= 0 then
        sk:override_cooldown(0)
        return
    end

    local frame = Global._current_frame or 0
    local duration = actor:stopwatch_get_duration(sk.cooldown_stopwatch) or cooldown
    local ready_frame = frame + reduced
    actor:stopwatch_stop(sk.cooldown_stopwatch)
    actor:stopwatch_start(sk.cooldown_stopwatch, ready_frame, ready_frame - duration)
end

local function reduce_other_skills(actor, used_slot)
    if not is_berserk(actor) then return end

    for _, slot in ipairs({ Skill.Slot.PRIMARY, Skill.Slot.SECONDARY, Skill.Slot.UTILITY, Skill.Slot.SPECIAL }) do
        if slot ~= used_slot then
            reduce_slot_cooldown(actor, slot)
        end
    end
end

-- Каждый кадр у держателя: пока берсерк активен, поддерживаем таймер и визуальный бафф.
-- Сокращение кулдаунов происходит только в onSecondaryUse/onUtilityUse/onSpecialUse.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if Net.client then return end

    local data = Instance.get_data(actor, nil, GUID)
    local t = data.berserk or 0
    if t <= 0 then return end

    -- Поддерживаем визуальный бафф, пока идёт берсерк
    if actor:buff_count(buff) <= 0 then
        actor:buff_apply(buff, 2)
    end

    data.berserk = t - 1
    if data.berserk <= 0 then
        data.berserk = 0
        local n = actor:buff_count(buff)
        if n > 0 then actor:buff_remove(buff, n) end
    end
end)

DeerItemsCallbacks.item_secondary_use(item, function(actor, stack, active_skill)
    reduce_other_skills(actor, Skill.Slot.SECONDARY)
end)

DeerItemsCallbacks.item_utility_use(item, function(actor, stack, active_skill)
    reduce_other_skills(actor, Skill.Slot.UTILITY)
end)

DeerItemsCallbacks.item_special_use(item, function(actor, stack, active_skill)
    reduce_other_skills(actor, Skill.Slot.SPECIAL)
end)

-- Экранная подсветка: лёгкий лиловый оверлей на весь экран локального игрока, пока он в берсерке.
-- Рисуем поверх HUD в экранных координатах; rect до размеров дисплея гарантированно покрывает экран.
gm.post_script_hook(gm.constants.draw_hud, function()
    local p = Player.get_local()
    if not p or not Instance.exists(p) then return end
    if p:buff_count(buff) <= 0 then return end

    local w = gm.display_get_width()
    local h = gm.display_get_height()
    gm.draw_set_colour(TINT)
    gm.draw_set_alpha(TINT_ALPHA)
    gm.draw_rectangle(0, 0, w, h, false)
    gm.draw_set_alpha(1)
    gm.draw_set_colour(Color.WHITE)
end)
