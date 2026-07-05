-- DeerItems-VioletFrenzy / «Лиловое неистовство» / "Violet Frenzy"
-- Порт Brainstalks из RoR2.
-- При убийстве элитного монстра (или босса) игрок входит в состояние берсерка на 4 (+4 за шт.) секунды.
-- Пока берсерк активен, перезарядка ВСЕХ умений составляет 0,5 секунды, а экран слегка подкрашивается лиловым.

-- Загружаем спрайт предмета (плейсхолдер — копия Community.png; замени на финальный арт по этому пути)
local sprite = Resources.sprite_load("DeerItems", "item/VioletFrenzy", PATH.."assets/sprites/items/sRedItems/VioletFrenzy.png", 1, 18, 17)

-- guid мода: ускоряет get_data (без обхода debug-стека на каждом кадре)
local GUID = _ENV["!guid"]

-- ── НАСТРОЙКИ ──
local CD_FRAMES   = 30   -- перезарядка умений в берсерке: 0,5 сек = 30 кадров
local SEC_PER_STACK = 4  -- длительность берсерка: 4 сек за стак (1 стак = 4с, 2 = 8с …)
local TINT        = Color(0x8A2BE2)  -- лиловый (blueviolet, RGB)
local TINT_ALPHA  = 0.16             -- сила экранной подсветки

-- Создание предмета VioletFrenzy
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: утилитарный предмет (как Brainstalks)
local item = Item.new("DeerItems", "VioletFrenzy")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Очистка старых коллбеков
item:clear_callbacks()

-- Бафф-флаг «берсерк». Сам по себе статов не меняет — служит индикатором состояния
-- (по нему экранный хук решает, красить ли экран, а HUD показывает иконку).
local buff = Buff.new("DeerItems", "VioletFrenzy")
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1
buff:clear_callbacks()

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
item:onKillProc(function(actor, victim, stack)
    if not is_elite_or_boss(victim) then return end
    stack = stack or 1
    local data = actor:get_data(nil, GUID)
    local full = SEC_PER_STACK * stack * 60
    data.berserk = math.max(data.berserk or 0, full)
end)

-- Каждый кадр у держателя: пока берсерк активен — держим перезарядку всех 4 умений ≤ 0,5 сек.
-- Раньше тут писалось несуществующее поле sk.use_next_frame — поэтому −КД и НЕ работал.
-- Правильный метод тулкита — actor:override_active_skill_cooldown(slot, frames): он ставит
-- оставшийся кулдаун. Раз в CD_FRAMES кадров обнуляем кулдаун всех умений → между сбросами
-- они тикают нормально (не «замораживаются»), а ждать готовности приходится не дольше 0,5 сек.
item:onPostStep(function(actor, stack)
    local data = actor:get_data(nil, GUID)
    local t = data.berserk or 0
    if t <= 0 then return end

    -- Поддерживаем визуальный бафф, пока идёт берсерк
    if actor:buff_stack_count(buff) <= 0 then
        actor:buff_apply(buff, 2)
    end

    if (Global._current_frame % CD_FRAMES) == 0 then
        for i = 0, 3 do
            actor:override_active_skill_cooldown(i, 0)
        end
    end

    data.berserk = t - 1
    if data.berserk <= 0 then
        data.berserk = 0
        local n = actor:buff_stack_count(buff)
        if n > 0 then actor:buff_remove(buff, n) end
    end
end)

-- Экранная подсветка: лёгкий лиловый оверлей на весь экран локального игрока, пока он в берсерке.
-- Рисуем поверх HUD в экранных координатах; rect до размеров дисплея гарантированно покрывает экран.
gm.post_script_hook(gm.constants.draw_hud, function()
    local p = Player.get_client()
    if not p or not Instance.exists(p) then return end
    if p:buff_stack_count(buff) <= 0 then return end

    local w = gm.display_get_width()
    local h = gm.display_get_height()
    gm.draw_set_colour(TINT)
    gm.draw_set_alpha(TINT_ALPHA)
    gm.draw_rectangle(0, 0, w, h, false)
    gm.draw_set_alpha(1)
    gm.draw_set_colour(Color.WHITE)
end)
