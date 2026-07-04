-- DeerItems-FaultyConductor / «Аварийный сверхпроводник» / "Faulty Conductor"
-- Порт Faulty Conductor из RoR2 (+ авторская добавка про урон дронов).
-- Каждые 15 сек (−20% за стак) волна заряжает союзников на 7 сек: +30% скорости атаки и передвижения.
-- Дроны постоянно получают +15% (+15% за стак) к урону.

-- Спрайт предмета, иконка баффа «заряжен», частица-вспышка пульса и звук — болванки из template (заменишь сам).
local sprite      = Resources.sprite_load("DeerItems", "item/FaultyConductor", PATH.."assets/sprites/items/sRedItems/FaultyConductor.png", 1, 18, 18)
local buffSprite  = Resources.sprite_load("DeerItems", "buff/FaultyConductor", PATH.."assets/sprites/buffs/FaultyConductor.png", 1, 4, 8)
local pulseSprite = Resources.sprite_load("DeerItems", "particle/FaultyConductor", PATH.."assets/sprites/particle/FaultyConductor.png", 5, 10, 10)
local sound       = Resources.sfx_load("DeerItems", "FaultyConductor/pulse", PATH.."assets/sounds/FaultyConductor.ogg")

local GUID = _ENV["!guid"]
local oP   = gm.constants.oP

-- ── Баланс (как в оригинале + авторская добавка про дронов) ─────────────────────
local BASE_PERIOD  = 15 * 60   -- базовый период волны: 15 сек
local MIN_PERIOD   = 240       -- пол периода (4 сек), чтобы на высоких стаках не стало статичной аурой
local DURATION     = 7 * 60    -- длительность заряда: 7 сек
local ATK_PCT      = 0.30      -- +30% скорости атаки (плоско, не за стак — масштабируется ЧАСТОТА)
local MOVE_PCT     = 0.30      -- +30% скорости передвижения
local RADIUS       = 500       -- радиус волны
local DRONE_DMG_BASE  = 0.15   -- +15% к урону дронов (база)
local DRONE_DMG_STACK = 0.15   -- +15% за каждый стак сверх первого
local DRONE_RADIUS = 100000    -- радиус поиска дронов (вся арена)
-- ──────────────────────────────────────────────────────────────────────────────

-- Бафф «заряжен»: +скорость атаки и передвижения, пока активен.
local energize = Buff.new("DeerItems", "Energize")
energize.icon_sprite = buffSprite
energize.show_icon = true
energize.is_debuff = false
energize.max_stack = 1          -- НЕ -1; max_stack=1 → повторный пульс ОБНОВЛЯЕТ длительность, не складывает
energize:clear_callbacks()
energize:onStatRecalc(function(a, s)
    a.attack_speed = a.attack_speed * (1 + ATK_PCT)
    a.pHmax        = a.pHmax        * (1 + MOVE_PCT)
end)

-- Текущее число стаков предмета по командам — для глобального хука усиления дронов.
local g_team_stack = {}

-- Принудительный пересчёт дронов владельца (их урон множит хук на ИХ пересчёте,
-- поэтому при смене числа стаков их надо пересчитать вручную).
local function recalc_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP then
            char:recalculate_stats()
        end
    end
end

local item = Item.new("DeerItems", "FaultyConductor")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

item:onStatRecalc(function(actor, stack)
    if stack > 0 then g_team_stack[actor.team] = stack end
end)

item:onAcquire(function(actor, stack)
    g_team_stack[actor.team] = stack
    recalc_drones(actor)
end)

item:onRemove(function(actor, stack)
    if stack <= 1 then g_team_stack[actor.team] = nil end
end)

-- Пульс заряда по союзникам + поддержание стаков команды.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    g_team_stack[actor.team] = stack

    local data = actor:get_data("FaultyConductor", GUID)

    -- Сменилось число стаков → у дронов другой множитель урона; пересчитываем их.
    if data.fc_last_stack ~= stack then
        data.fc_last_stack = stack
        recalc_drones(actor)
    end

    -- Период волны сокращается на 20% за стак (умножаем кадры на 0.8^(stack-1)), но не ниже пола.
    local period = math.max(MIN_PERIOD, math.floor(BASE_PERIOD * (0.8 ^ (stack - 1))))
    local frame  = Global._current_frame
    if data.fc_next == nil then data.fc_next = frame + period end
    if frame < data.fc_next then return end
    data.fc_next = frame + period

    -- Заряжаем всех союзников в радиусе (find_characters_circle возвращает И игроков, И дронов).
    local allies = List.wrap(actor:find_characters_circle(actor.x, actor.y, RADIUS, false, actor.team, true))
    for _, ally in ipairs(allies) do
        ally:buff_apply(energize, DURATION, 1)
    end

    -- Обратная связь: звук + вспышка-кольцо у игрока.
    actor:sound_play(sound, 0.9, 0.95 + math.random() * 0.2)
    local fx = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
    if fx then fx.sprite_index = pulseSprite end
end)

-- Глобальный хук пересчёта статов: усиливает урон каждого дрона на ЕГО пересчёте.
-- Множим уже посчитанное движком значение → не накапливается (база сбрасывается каждый пересчёт),
-- тот же приём, что в HeavyLungs.lua.
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end
    self.damage = self.damage * (1 + DRONE_DMG_BASE + DRONE_DMG_STACK * (s - 1))
end)
