-- DeerItems-AssemblyBlueprint
-- При покупке дрона/турели — шанс продублировать его (20% +20% гиперболически, максимум 80%).
-- При гибели дрона/турели владельца — шанс восстановить его на 50% HP (10% +10% гиперболически, максимум 80%).
--
-- Как это устроено (в игре нет коллбеков «куплен дрон» / «погиб дрон» на уровне предмета):
--   * Покупка ловится поллингом множества союзных дронов с проверкой их владельца,
--     раз в POLL_PERIOD кадров. Новый дрон, которого мы раньше не видели и который НЕ создан нами,
--     считается «купленным» и проходит ролл дублирования.
--   * Гибель ловится глобальным хуком actor_set_dead (тот же приём, что gm.post_script_hook в HeavyLungs):
--     умерший союзный не-игрок проходит ролл восстановления.
-- Спавн дронов выполняется ТОЛЬКО на хосте (gm._mod_net_isClient → выход), готовые инстансы расходятся
-- по клиентам штатной синхронизацией движка/тулкита — так же, как делает сам RMT при клонировании элит.

-- Загружаем спрайт предмета (36x36)
local sprite = Resources.sprite_load("DeerItems", "item/AssemblyBlueprint", PATH.."assets/sprites/items/sGreenItems/AssemblyBlueprint.png", 1, 18, 18)

-- guid мода выносим один раз — чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

-- Объект игрока: всё союзное, что НЕ oP, считаем дроном/турелью/призывом
local oP = gm.constants.oP

-- Создание предмета AssemblyBlueprint
-- Привязка спрайта; тир: зелёный (необычный); тег лута: утилитарный
local item = Item.new("DeerItems", "AssemblyBlueprint")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

--==================================================================================================
-- БАЛАНСНЫЕ КОНСТАНТЫ
--==================================================================================================
local DUP_PER_STACK  = 0.20    -- шаг шанса дублирования за стак (гиперболически)
local DUP_CAP        = 0.80    -- потолок шанса дублирования (не 100% — дубликат не гарантирован)
local REV_PER_STACK  = 0.10    -- шаг шанса восстановления за стак (гиперболически)
local REV_CAP        = 0.80    -- потолок шанса восстановления (всегда остаётся шанс умереть «по-настоящему»)
local REVIVE_HP_FRAC = 0.50    -- восстановленный дрон возвращается с 50% от своего максимального HP
local POLL_PERIOD    = 15      -- период сканирования покупок, в кадрах (как в HeavyLungs)
local FIND_RADIUS    = 100000  -- радиус поиска дронов: фактически вся арена
local CLEAN_RADIUS   = 96      -- радиус, в котором НОВЫЙ «слом» относим к метке гибели копии/воскрешения

-- Гиперболический шанс: base 1-(1-p)^stack, ограниченный потолком cap.
-- p=0.2 → стак1 20%, стак2 36%, стак3 48.8%, … затухание к cap.
local function hyper_chance(per, stack, cap)
    if stack <= 0 then return 0 end
    local c = 1 - (1 - per) ^ stack
    if c > cap then c = cap end
    return c
end

local function as_existing_instance(inst)
    if not inst then return nil end
    local ok, exists = pcall(function() return Instance.exists(inst) end)
    if ok and exists then
        return Instance.wrap(inst)
    end
    return nil
end

local function same_instance(a, b)
    if not a or not b then return false end
    if a == b then return true end
    if a.id and b.id then return a.id == b.id end
    if a.value and b.value then return a.value == b.value end
    return false
end

local function drone_owner(drone)
    return as_existing_instance(drone.parent) or as_existing_instance(drone.owner)
end

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

--==================================================================================================
-- СОСТОЯНИЕ (на уровне файла — живёт весь забег)
--==================================================================================================
-- Множество уже учтённых дронов: [instance.id] = true. Раз в поллинг перестраивается из
-- актуального набора (мёртвые/исчезнувшие id отсеиваются сами).
local g_owner_state = {}

-- Базовый набор «засеян»? До первого засева существующие дроны не считаем покупками
-- (иначе подбор предмета при уже имеющейся армии раздал бы бесплатные дубликаты).
-- Кадр последнего поллинга — чтобы в мультиплеере несколько владельцев не сканировали один кадр дважды.
-- «Сломанный дрон» — покупаемый интерактив pInteractableDrone, который игра роняет при гибели ЛЮБОГО
-- дрона. Если мы дрона воскресили, эту покупаемую версию надо убрать: иначе её можно ещё и докупить,
-- получив второго дрона из одной смерти (дюп).
local DRONE_INTERACT = gm.constants.pInteractableDrone
-- Места гибели воскрешённых дронов: {x, y, frames}. Несколько кадров ищем рядом «сломанную» версию и сносим.
local g_revive_marks = {}

-- Набор id СОЗДАННЫХ нами дронов (клоны/воскрешённые). Файловый набор, не зависит от instance-data
-- (которая на момент смерти инстанса может быть уже недоступна) → надёжно опознаёт «наш» дрон при гибели.
local g_spawned = {}

-- Защита от повторной обработки одной гибели: actor_set_dead может сработать на инстансе несколько раз.
local g_handled = {}   -- [instance.id] = кадр последней обработки

-- Кадр первого появления каждого «слома»: [id] = кадр. Метка гибели копии/воскрешения сносит «слом»
-- рядом, появившийся НЕ РАНЬШЕ самой гибели (first_seen >= кадра метки). Так лежащий «слом» оригинала
-- (появился раньше) и чужие не трогаются, а задержка появления «слома» (1-2 кадра) логику не ломает.
local g_broken_seen = {}

--==================================================================================================
-- СПАВН КОПИИ ДРОНА (только хост)
--   src      — образец, чей тип объекта воспроизводим
--   x, y     — где создать
--   owner    — игрок-владелец (parent/team/level берём у него)
--   hp_frac  — если задан, выставляем hp = maxhp * hp_frac (для восстановления); иначе полное HP
--==================================================================================================
local function spawn_drone_copy(src, x, y, owner, hp_frac, lineage)
    -- Истинный индекс объекта (корректно работает и для кастомных модовых дронов)
    local obj
    local ok = pcall(function() obj = src:get_object_index_self() end)
    if not ok or not obj then obj = src.object_index end

    local inst = Instance.wrap(gm.instance_create(x, y, obj))
    if not inst:exists() then return nil end
    g_spawned[inst.id] = lineage or "dup"   -- линия дрона: "orig" (продолжение купленного) или "dup" (копия)

    -- Привязка к владельцу (паттерн из примера турели тулкита)
    inst.parent = owner
    inst.team   = owner.team
    if owner.level then inst.level = owner.level end

    -- Метка «создано нами» — чтобы поллинг покупок не принял копию за новую покупку
    -- и не запустил бесконечное самодублирование.
    inst:get_data("DeerItems", GUID).assembly_spawned = true

    pcall(function() inst:recalculate_stats() end)

    -- Пониженное HP для восстановленных (баланс: армия не становится бессмертной)
    if hp_frac and inst.maxhp then
        inst.hp = math.max(1, inst.maxhp * hp_frac)
    end

    return inst
end

--==================================================================================================
-- ЛОГИКА ПРЕДМЕТА
--==================================================================================================
item:clear_callbacks()

-- При получении предмета пересеиваем базовый набор дронов для этого владельца,
-- чтобы уже имеющиеся дроны не приняли за «только что купленные».
item:onAcquire(function(actor, stack)
    if not g_owner_state[actor.id] then
        g_owner_state[actor.id] = { known = {}, started = false, last_poll = -1 }
    end
end)

-- При полной потере предмета убираем состояние владельца
item:onRemove(function(actor, stack)
    if stack <= 1 then
        g_owner_state[actor.id] = nil
    end
end)

-- Поллинг покупок: ищем новых союзных дронов и катим дублирование.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end

    -- Спавн — только на хосте
    if gm._mod_net_isClient() then return end

    local state = g_owner_state[actor.id]
    if not state then
        state = { known = {}, started = false, last_poll = -1 }
        g_owner_state[actor.id] = state
    end

    local frame = Global._current_frame
    if frame == state.last_poll then return end
    if frame % POLL_PERIOD ~= 0 then return end
    state.last_poll = frame

    -- Сначала берём союзников по команде, затем ниже оставляем только дронов этого владельца.
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, FIND_RADIUS, false, actor.team, true))

    local seen = {}
    for _, char in ipairs(found) do
        local owner = drone_owner(char)
        if char.object_index ~= oP and not is_not_drone(char) and same_instance(owner, actor) then              -- игроков не трогаем
            local id = char.id
            seen[id] = true

            if not state.known[id] then
                -- Дрон, которого мы раньше не видели
                if state.started and not g_spawned[id] then
                    -- Настоящая покупка → ролл дублирования
                    if math.random() < hyper_chance(DUP_PER_STACK, stack, DUP_CAP) then
                        spawn_drone_copy(char, char.x, char.y, owner, nil, "dup")  -- дубликат покупки (линия "dup"), полное HP
                    end
                end
                -- (если база ещё не засеяна — просто запоминаем, без ролла)
            end
        end
    end

    state.known = seen          -- заменяем набор, отсеивая исчезнувшие id
    state.started = true
end)

--==================================================================================================
-- ВОССТАНОВЛЕНИЕ ПРИ ГИБЕЛИ
-- Глобальный хук смерти актора (тот же приём, что gm.post_script_hook в HeavyLungs).
-- self — умирающий актор. Восстановление спавним у ВЛАДЕЛЬЦА (а не на месте гибели),
-- чтобы не воскрешать дрона в пропасть/за границу карты в бесконечном цикле.
--==================================================================================================
gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    if gm._mod_net_isClient() then return end
    if self.object_index == oP then return end       -- игроки — не дроны
    if is_not_drone(self) then return end

    -- Восстанавливаем только дронов, чей реальный владелец держит предмет.
    local owner = drone_owner(self)
    if not owner or not Instance.exists(owner) then return end
    local stack = owner:item_stack_count(item) or 0
    if stack <= 0 then return end

    -- Защита от повторного срабатывания actor_set_dead на ОДНОМ инстансе (иначе двойное воскрешение
    -- и неверная пометка линии). Обрабатываем гибель конкретного дрона один раз.
    local nowf = Global._current_frame or 0
    if g_handled[self.id] and (nowf - g_handled[self.id]) < 30 then return end
    g_handled[self.id] = nowf

    local dx, dy = self.x, self.y
    -- Линия погибшего: g_spawned[id] = "orig"/"dup"; nil = КУПЛЕННЫЙ оригинал (мы его не спавнили).
    -- "orig" = купленный дрон ИЛИ цепочка его воскрешений → при финальной гибели оставляет покупаемого
    -- «слома» (можно купить заново). "dup" = копия (и её воскрешения) → исчезает без следа.
    local lineage = g_spawned[self.id]
    local is_orig = (lineage == nil) or (lineage == "orig")

    local revived = false
    if math.random() < hyper_chance(REV_PER_STACK, stack, REV_CAP) then
        -- Воскрешение ПРОДОЛЖАЕТ ту же линию (оригинал остаётся оригиналом, копия — копией)
        spawn_drone_copy(Instance.wrap(self), owner.x, owner.y, owner, REVIVE_HP_FRAC, is_orig and "orig" or "dup")
        revived = true
    end

    -- Зачищаем покупаемого «слома», если:
    --   * дрон ВОСКРЕШЁН (живая копия уже есть → иначе дюп), ИЛИ
    --   * погибла КОПИЯ ("dup") без воскрешения (её докупать нельзя — должна исчезнуть).
    -- КУПЛЕННЫЙ ОРИГИНАЛ, погибший без воскрешения, «слома» НЕ трогаем — его можно купить заново.
    if revived or (not is_orig) then
        g_revive_marks[#g_revive_marks + 1] = { x = dx, y = dy, created = nowf, expires = nowf + 90 }
    end
    g_spawned[self.id] = nil   -- инстанс мёртв — убираем из набора
end)

-- Зачистка «сломов» от гибели копий/воскрешений (только хост).
-- Сносим ТОЛЬКО НОВЫЕ pInteractableDrone, появившиеся рядом с меткой гибели копии/воскрешения.
-- «Слом» оригинала метку не создаёт → он новый, но рядом метки нет → остаётся покупаемым.
-- Уже виденные «сломы» (старый оригинальский, чужие) не трогаем никогда — это убирает дюпы от
-- путаницы «какой слом чей».
Callback.add(Callback.TYPE.onStep, "DeerItems-AssemblyBlueprint-cleanbroken", function()
    if gm._mod_net_isClient() then return end

    local nowf = Global._current_frame or 0

    -- Снимок текущих «сломов» + фиксируем кадр первого появления каждого
    local brokens = Instance.find_all(DRONE_INTERACT)
    local cur = {}
    for _, it in ipairs(brokens) do
        if Instance.exists(it) then
            cur[it.id] = true
            if not g_broken_seen[it.id] then
                g_broken_seen[it.id] = nowf
            end
        end
    end
    -- Забываем исчезнувшие «сломы»
    for id in pairs(g_broken_seen) do
        if not cur[id] then g_broken_seen[id] = nil end
    end

    -- Метки: каждая сносит ОДИН «слом» рядом, появившийся НЕ РАНЬШЕ самой гибели; затем гаснет.
    for mi = #g_revive_marks, 1, -1 do
        local m = g_revive_marks[mi]
        local done = (nowf > m.expires)        -- метка истекла — снять
        if not done then
            for _, it in ipairs(brokens) do
                if Instance.exists(it)
                   and (g_broken_seen[it.id] or nowf) >= m.created          -- «слом» от ЭТОЙ гибели, не лежавший раньше
                   and gm.point_distance(m.x, m.y, it.x, it.y) < CLEAN_RADIUS then
                    it:destroy()
                    g_broken_seen[it.id] = nil
                    done = true
                    break
                end
            end
        end
        if done then table.remove(g_revive_marks, mi) end
    end
end)
