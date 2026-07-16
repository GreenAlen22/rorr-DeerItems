-- DeerItems-MagmaFragment
-- Союзные покупаемые дроны поджигают врагов при попадании на 50% урона.

local sprite = Resources.sprite_load("DeerItems", "item/MagmaFragment", PATH.."assets/sprites/items/sWhiteItems/MagmaFragment.png", 1, 16, 16)
local drone_indicator = Resources.sprite_load("DeerItems", "particle/MagmaFragmentDrone", PATH.."assets/sprites/particle/MagmaFragmentDrone.png", 8, 10, 7)
local sound = Resources.sfx_load("DeerItems", "sound/MagmaFragment", PATH.."assets/sounds/MagmaFragment.ogg")

local GUID = _ENV["!guid"]
local oP = gm.constants.oP
local DRONE_RADIUS = 100000
local DOT_TICKS = 5
local DOT_RATE = 60
local DOT_DAMAGE = 0.30
local IGNITE_SOUND_CHANCE = 0.25

-- Следуем рабочему критерию HeavyLungs/GlassMagnifier: купленные дроны — союзные
-- не-игроки. Cernunnos явно исключён, чтобы не считаться дроном.
local function is_not_drone(actor)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(actor)
end

local function is_drone(actor)
    return actor and actor.object_index ~= oP and not is_not_drone(actor)
end

local item = Item.new("DeerItems", "MagmaFragment")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

-- Данные хранятся по команде: игровые покупаемые дроны не всегда отдают владельца
-- в callback атаки, зато команда у них корректна и совпадает с владельцем.
local team_stacks = {}
local team_sources = {}
local team_dots = {}
local team_state_frame = -1

local function refresh_team_state()
    local frame = Global._current_frame or 0
    if team_state_frame == frame then return end
    team_state_frame = frame

    local stacks = {}
    local sources = {}
    for _, player in ipairs(Instance.find_all(oP)) do
        if Instance.exists(player) then
            local stack = player:item_stack_count(item) or 0
            if stack > 0 then
                stacks[player.team] = (stacks[player.team] or 0) + stack
                sources[player.team] = player
            end
        end
    end

    team_stacks = stacks
    team_sources = sources
end

local function active_dots(team)
    local dots = team_dots[team] or {}
    team_dots[team] = dots

    local count = 0
    for victim_id, dot in pairs(dots) do
        if Instance.exists(dot) then
            count = count + 1
        else
            dots[victim_id] = nil
        end
    end
    return dots, count
end

local function play_ignite_sound(victim)
    if math.random() <= IGNITE_SOUND_CHANCE then
        victim:sound_play(sound, 1.0, 0.9 + math.random() * 0.2)
    end
end

item:onPostStep(function(actor, stack)
    refresh_team_state()
    if gm._mod_net_isHost() then active_dots(actor.team) end
end)

-- onHitProc пропускает атаки с proc=false. Глобальный onAttackHit получает каждое
-- попадание дрона, включая стандартный выстрел Gunner Drone.
Actor:onAttackHit("DeerItems-MagmaFragment-drone", function(drone, victim, hit_info)
    if gm._mod_net_isClient() then return end
    if not is_drone(drone) or not victim or not Instance.exists(victim) then return end
    if not hit_info or not hit_info.damage then return end

    refresh_team_state()
    local stack = team_stacks[drone.team] or 0
    local source = team_sources[drone.team]
    if stack <= 0 or not source or not Instance.exists(source) then return end

    local attack_info = hit_info.attack_info
    local force_proc = attack_info and attack_info:get_attack_flag(Attack_Info.ATTACK_FLAG.force_proc)
    if not force_proc and math.random() > math.min(1, 0.10 * stack) then return end

    local dots, count = active_dots(drone.team)
    local vdata = victim:get_data("MagmaFragment", GUID)
    local dot = vdata.dot

    -- Одна команда поддерживает на цели одно горение; повторный прок обновляет его.
    if dot and Instance.exists(dot) then
        if vdata.team ~= drone.team then return end
        dots[victim.id] = dot
        dot.damage = math.max(dot.damage, hit_info.damage * DOT_DAMAGE)
        dot.ticks = DOT_TICKS
        play_ignite_sound(victim)
        return
    end

    if count >= stack + 1 then return end

    -- 5 тиков по 30% урона удара с интервалом 60 кадров = один тик в секунду 5 секунд.
    -- Источник — игрок команды, поэтому DoT не воспринимается как новый удар дрона.
    dot = victim:apply_dot(hit_info.damage * DOT_DAMAGE, source, DOT_TICKS, DOT_RATE, Color(0xff4d00), true)
    dot.textColor = Color(0xff4d00)
    dot.sprite_index = gm.constants.sSparks9
    vdata.dot = dot
    vdata.team = drone.team
    dots[victim.id] = dot
    play_ignite_sound(victim)
end)

-- Индикатор виден постоянно, пока у игрока есть предмет, на всех союзных покупаемых дронах.
item:onPostDraw(function(actor, stack)
    local drones = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    local frame = math.floor((Global._current_frame or 0) / 4) % 8
    for _, drone in ipairs(drones) do
        if is_drone(drone) then
            gm.draw_sprite(drone_indicator, frame, drone.x-10, drone.y - 16)
        end
    end
end)
