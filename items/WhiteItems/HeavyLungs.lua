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

-- Союзный «персонаж» считается дроном, если это не игрок.
local function is_drone(char, owner)
    return char ~= owner and char.object_index ~= oP
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

-- Пересчёт статов владельца: запоминаем число дронов и стаки.
item:onStatRecalc(function(actor, stack)
    if stack <= 0 then return end

    -- Актуализируем стаки команды для усиления дронов (см. глобальный хук ниже)
    g_team_stack[actor.team] = stack

    actor:get_data("DeerItems", GUID).hl_drones = count_drones(actor)

end)

-- При получении предмета (в т.ч. первого стака) сразу применяем усиление к уже существующим дронам.
item:onAcquire(function(actor, stack)
    g_team_stack[actor.team] = stack
    recalc_drones(actor)
end)

-- Число дронов меняется само по себе (покупка/гибель), а статы так часто не пересчитываются.
-- Поэтому раз в COUNT_PERIOD кадров сверяем число дронов и при изменении ставим пересчёт в очередь.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end

    -- Держим стаки команды свежими (на случай, если пересчёт давно не вызывался)
    g_team_stack[actor.team] = stack

    local data = actor:get_data("DeerItems", GUID)

    -- Изменилось число стаков предмета (новый подбор) → множитель дронов другой,
    -- но сами дроны об этом не знают. Пересчитываем их статы.
    if data.hl_last_stack ~= stack then
        data.hl_last_stack = stack
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
    if stack <= 1 then
        g_team_stack[actor.team] = nil
    end
end)

-- Глобальный хук пересчёта статов: усиливает каждого дрона на ЕГО собственном пересчёте.
-- Множим уже посчитанные движком HP/реген, поэтому усиление корректно накладывается поверх
-- любого роста характеристик дрона по ходу забега и не накапливается (база сбрасывается каждый пересчёт).
gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end

    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end

    local data = self:get_data("DeerItems", GUID)
    data.hl_prev_hp = self.hp
    data.hl_prev_maxhp = self.maxhp
end)

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- Игроков не трогаем — только их дронов
    if self.object_index == oP then return end

    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end

    local mult = drone_mult(s)
    self.maxhp = self.maxhp * mult
    self.hp_regen = self.hp_regen * mult

    local data = self:get_data("DeerItems", GUID)
    if data.hl_prev_hp and data.hl_prev_maxhp then
        local missing_hp = math.max(0, data.hl_prev_maxhp - data.hl_prev_hp)
        self.hp = math.min(self.maxhp, math.max(1, self.maxhp - missing_hp))
    end
end)
