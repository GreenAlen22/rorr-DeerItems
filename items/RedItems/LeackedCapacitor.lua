-- DeerItems-LeackedCapacitor / «Аварийный сверхпроводник» / "Faulty Conductor"
-- Порт Faulty Conductor из RoR2 (+ авторская добавка про урон дронов).
-- Каждые 15 сек (−20% за стак) волна заряжает союзников на 7 сек: +30% скорости атаки и передвижения.
-- Дроны постоянно получают +15% (+15% за стак) к урону.

-- Спрайт предмета, иконка баффа «заряжен», частица-вспышка пульса и звук — болванки из template (заменишь сам).
local sprite      = Sprite.new("item/LeackedCapacitor", PATH.."assets/sprites/items/sRedItems/LeackedCapacitor.png", 1, 18, 18)
local buffSprite  = Sprite.new("buff/LeackedCapacitor", PATH.."assets/sprites/buffs/LeackedCapacitor.png", 1, 4, 8)
local pulseSprite = Sprite.new("particle/LeackedCapacitor", PATH.."assets/sprites/particle/LeackedCapacitor.png", 5, 10, 10)
local sound       = Sound.new("LeackedCapacitor/pulse", PATH.."assets/sounds/LeackedCapacitor.ogg")

local GUID = _ENV["!guid"]
local oP   = gm.constants.oP

-- Настройки баланса: оригинальные значения и отдельный бонус для дронов.
local BASE_PERIOD  = 15 * 60   -- базовый период волны: 15 сек
local MIN_PERIOD   = 240       -- пол периода (4 сек), чтобы на высоких стаках не стало статичной аурой
local DURATION     = 7 * 60    -- длительность заряда: 7 сек
local ATK_PCT      = 0.30      -- +30% скорости атаки (плоско, не за стак — масштабируется ЧАСТОТА)
local MOVE_PCT     = 0.30      -- +30% скорости передвижения
local RADIUS       = 500       -- радиус волны
local DRONE_AS_STACK  = 0.15   -- +15% attack speed per stack
local DRONE_RADIUS = 100000    -- радиус поиска дронов (вся арена)

-- Бафф «заряжен»: +скорость атаки и передвижения, пока активен.
local energize = Buff.new("Energize")
energize.icon_sprite = buffSprite
energize.show_icon = true
energize.is_debuff = false
energize.max_stack = 1          -- НЕ -1; max_stack=1 → повторный пульс ОБНОВЛЯЕТ длительность, не складывает
DeerItemsCallbacks.buff_stat_recalc(energize, function(a, s, api)
    api.attack_speed_mult(1 + ATK_PCT)
    api.pHmax_mult(1 + MOVE_PCT)
end)

-- Текущее число стаков предмета по командам — для глобального хука усиления дронов.
local g_team_stack = {}

local function is_not_drone(char)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(char)
end

-- Принудительный пересчёт дронов владельца (их урон множит хук на ИХ пересчёте,
-- поэтому при смене числа стаков их надо пересчитать вручную).
local function recalc_drones(actor)
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP and not is_not_drone(char) then
            char:recalculate_stats()
        end
    end
end

-- Обратная связь: звук + вспышка-кольцо у игрока.
local function pulse_visual(actor)
    actor:sound_play(sound, 0.9, 0.95 + math.random() * 0.2)
    local fx = gm.instance_create(actor.x, actor.y, gm.constants.oEfSparks)
    if fx then fx.sprite_index = pulseSprite.value end
end

-- Волну по таймеру запускает хост; oEfSparks локальный, поэтому клиентам — пакет.
local packet_pulse = Packet.new("LeackedCapacitor-packet_pulse")
packet_pulse:set_serializers(function(buffer, actor)
    buffer:write_instance(actor)
end, function(buffer)
    local actor = buffer:read_instance()
    if not Net.client or not Instance.exists(actor) then return end
    pulse_visual(actor)
end)

local item = Item.new("LeackedCapacitor")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack)
    if stack > 0 then g_team_stack[actor.team] = stack end
end)

DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    g_team_stack[actor.team] = stack
    recalc_drones(actor)
end)

DeerItemsCallbacks.item_removed(item, function(actor, stack)
    if stack <= 1 then g_team_stack[actor.team] = nil end
end)

-- Пульс заряда по союзникам + поддержание стаков команды.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if stack <= 0 then return end
    g_team_stack[actor.team] = stack

    local data = Instance.get_data(actor, "LeackedCapacitor", GUID)

    -- Сменилось число стаков → у дронов другой множитель урона; пересчитываем их.
    if data.fc_last_stack ~= stack then
        data.fc_last_stack = stack
        recalc_drones(actor)
    end

    -- Период волны сокращается на 20% за стак (умножаем кадры на 0.8^(stack-1)), но не ниже пола.
    if Net.client then return end

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

    pulse_visual(actor)
    packet_pulse:send_to_all(actor)
end)

-- Глобальный хук пересчёта статов: усиливает урон каждого дрона на ЕГО пересчёте.
-- Множим уже посчитанное движком значение → не накапливается (база сбрасывается каждый пересчёт),
-- тот же приём, что в HeavyLungs.lua.
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end
    if is_not_drone(self) then return end
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end
    self.attack_speed = self.attack_speed * (1 + DRONE_AS_STACK * s)
end)
