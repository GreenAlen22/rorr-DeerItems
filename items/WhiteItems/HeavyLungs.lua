-- DeerItems-HeavyLungs
-- Увеличивает максимальное HP и реген ВСЕХ дронов владельца на 15% за стак.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/HeavyLungs", PATH.."assets/sprites/items/sWhiteItems/HeavyLungs.png", 1, 16.5, 16.5)

-- guid мода выносим один раз — чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

-- Константы поведения
local DRONE_BUFF_STACK = 0.15    -- +15% max HP/regen per stack
local DRONE_FIND_RADIUS = 100000 -- радиус поиска дронов (фактически вся арена — дроны держатся у владельца)
local COUNT_PERIOD     = 15      -- как часто (в кадрах) перепроверять число дронов

-- Итоговый множитель к HP/регену дрона: 1 + 0.15*стак.
local function drone_mult(stack)
    return 1 + DRONE_BUFF_STACK * stack
end

-- Объект игрока в RoRR. Нужен, чтобы отличать дронов (союзные «персонажи»)
-- от самих игроков среди союзников одной команды.
local oP = gm.constants.oP

-- Множитель усиления дронов по командам: g_team_stack[team] = текущее число стаков предмета
-- у игрока этой команды. Используется глобальным хуком пересчёта статов (ниже),
-- который усиливает каждого дрона на его собственном пересчёте.
local g_team_stack = {}
local g_prev_stats = {}
local team_state_frame = -1
local pending_recalculate = {}

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

-- Союзный «персонаж» считается дроном, если это не игрок.
local function is_drone(char, owner)
    return char ~= owner and char.object_index ~= oP and not is_not_drone(char)
end

-- Подсчёт дронов владельца: ищем союзных персонажей по всей арене и отбрасываем игроков.
local function count_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_FIND_RADIUS, false, actor.team, true))
    local n = 0
    for _, char in ipairs(found) do
        if is_drone(char, actor) then
            n = n + 1
        end
    end
    return n
end

-- Принудительный пересчёт статов всех дронов владельца.
-- Усиление дрона навешивается на ЕГО собственном пересчёте (см. глобальный хук ниже),
-- поэтому при смене числа стаков предмета дроны нужно пересчитать вручную —
-- иначе их HP/реген не обновятся до следующего естественного пересчёта.
local function recalc_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_FIND_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if is_drone(char, actor) then
            char:recalculate_stats()
        end
    end
end

-- Создание предмета HeavyLungs
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "HeavyLungs")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

item:clear_callbacks()

local function refresh_team_stacks()
    local frame = Global._current_frame or 0
    if team_state_frame == frame then return false end
    team_state_frame = frame

    local stacks = {}
    for _, player in ipairs(Instance.find_all(oP)) do
        if Instance.exists(player) then
            local stack = player:item_stack_count(item) or 0
            if stack > 0 then
                stacks[player.team] = (stacks[player.team] or 0) + stack
            end
        end
    end

    local changed = false
    for team, stack in pairs(stacks) do
        if g_team_stack[team] ~= stack then changed = true end
    end
    for team in pairs(g_team_stack) do
        if stacks[team] ~= g_team_stack[team] then changed = true end
    end
    g_team_stack = stacks
    return changed
end

-- Пересчёт статов владельца: запоминаем число дронов и стаки.
item:onStatRecalc(function(actor, stack)
    if stack <= 0 then return end

    -- Актуализируем стаки команды для усиления дронов (см. глобальный хук ниже)
    refresh_team_stacks()

    actor:get_data("DeerItems", GUID).hl_drones = count_drones(actor)

end)

-- При получении предмета (в т.ч. первого стака) сразу применяем усиление к уже существующим дронам.
item:onAcquire(function(actor, stack)
    refresh_team_stacks()
    recalc_drones(actor)
end)

-- Число дронов меняется само по себе (покупка/гибель), а статы так часто не пересчитываются.
-- Поэтому раз в COUNT_PERIOD кадров сверяем число дронов и при изменении ставим пересчёт в очередь.
item:onPostStep(function(actor, stack)
    local changed = refresh_team_stacks()
    if changed then
        recalc_drones(actor)
        return
    end
    if stack <= 0 then return end

    -- Держим стаки команды свежими (на случай, если пересчёт давно не вызывался)
    local data = actor:get_data("DeerItems", GUID)

    -- Изменилось число стаков предмета (новый подбор) → множитель дронов другой,
    -- но сами дроны об этом не знают. Пересчитываем их статы.
    local team_stack = g_team_stack[actor.team] or 0
    if data.hl_last_stack ~= team_stack then
        data.hl_last_stack = team_stack
        recalc_drones(actor)
    end

    data.hl_tick = (data.hl_tick or 0) + 1
    if data.hl_tick < COUNT_PERIOD then return end
    data.hl_tick = 0

    local n = count_drones(actor)
    if n ~= data.hl_drones then
        data.hl_drones = n
        recalc_drones(actor)
    end
end)

-- При полной потере предмета убираем усиление дронов этой команды.
item:onRemove(function(actor, stack)
    -- onRemove приходит со стаком ДО удаления: stack == 1 означает, что предмета не останется.
    pending_recalculate[actor.id] = actor
end)

Callback.add(Callback.TYPE.onStep, "DeerItems-HeavyLungs-remove", function()
    for id, actor in pairs(pending_recalculate) do
        pending_recalculate[id] = nil
        if Instance.exists(actor) then
            refresh_team_stacks()
            recalc_drones(actor)
        end
    end
end)

-- Глобальный хук пересчёта статов: усиливает каждого дрона на ЕГО собственном пересчёте.
-- Множим уже посчитанные движком HP/реген, поэтому усиление корректно накладывается поверх
-- любого роста характеристик дрона по ходу забега и не накапливается (база сбрасывается каждый пересчёт).
gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end
    if is_not_drone(self) then return end

    refresh_team_stacks()
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end

    g_prev_stats[self.id or self] = {
        hp = self.hp,
        maxhp = self.maxhp,
    }
end)

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- Игроков не трогаем — только их дронов
    if self.object_index == oP then return end
    if is_not_drone(self) then return end

    refresh_team_stacks()
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end

    local mult = drone_mult(s)
    self.maxhp = self.maxhp * mult
    self.hp_regen = self.hp_regen * mult

    local key = self.id or self
    local prev = g_prev_stats[key]
    g_prev_stats[key] = nil

    if prev and prev.hp and prev.hp > 0 and prev.maxhp and prev.maxhp > 0 and self.hp > 0 then
        local missing_hp = math.max(0, prev.maxhp - prev.hp)
        self.hp = math.min(self.maxhp, math.max(1, self.maxhp - missing_hp))
    end
end)
