-- DeerItems-Rusted
-- A Monsoon-only elite that creates two-stage rust spikes beneath distant players.

local GUID = _ENV["!guid"]

local METERS_TO_PIXELS = 32
local MIN_TARGET_DISTANCE = 10 * METERS_TO_PIXELS
local MAX_TARGET_DISTANCE = 40 * METERS_TO_PIXELS

local SPIKE_COOLDOWN_MIN = 10 * 60
local SPIKE_COOLDOWN_MAX_BONUS = 5 * 60
local TELEGRAPH_FRAMES = 30
local VERTICAL_FRAMES = 10
local HORIZONTAL_FRAMES = 5
local ATTACK_ANIMATION_SPEED = 0.8 -- 25% slower visual frames; gameplay timing remains unchanged.
local LAST_FRAME_HOLD = 30
local STRIKE_ANIMATION_DURATION = math.ceil((VERTICAL_FRAMES + HORIZONTAL_FRAMES) / ATTACK_ANIMATION_SPEED)
local SPIKE_VISUAL_LIFETIME = TELEGRAPH_FRAMES + STRIKE_ANIMATION_DURATION + LAST_FRAME_HOLD
local VERTICAL_WIDTH = 24
local VERTICAL_HEIGHT = 96
local HORIZONTAL_WIDTH = 96
local HORIZONTAL_HEIGHT = 24

local HEALTH_MULTIPLIER = 4.5
local DAMAGE_MULTIPLIER = 4
local SKILL_COOLDOWN_MULTIPLIER = 0.4
local GOLD_MULTIPLIER = 10
local RUST_DURATION = 4 * 60
local RUST_DAMAGE_MULTIPLIER = 1.1
local EXPENSIVE_CARD_QUANTILE = 0.90

local palette = Resources.sprite_load(
    "DeerItems",
    "elite/RustedPalette",
    PATH.."assets/sprites/elites/sRusted/PaletteRusted.png",
    1,
    0,
    0
)
local icon = Resources.sprite_load(
    "DeerItems",
    "elite/RustedIcon",
    PATH.."assets/sprites/elites/sRusted/IconRusted.png",
    1,
    10.5,
    9
)
local spike_sprite = Resources.sprite_load(
    "DeerItems",
    "elite/RustedSpike",
    PATH.."assets/sprites/elites/sRusted/RustSpike.png",
    19,
    32,
    64
)
local debuff_sprite = Resources.sprite_load(
    "DeerItems",
    "elite/RustedDebuff",
    PATH.."assets/sprites/elites/sRusted/RustDebuff.png",
    1,
    8,
    8
)
local spike_emerge_sound = Resources.sfx_load(
    "DeerItems",
    "elite/RustedSpikeEmerge",
    PATH.."assets/sounds/FearEyes.ogg"
)

local rusted = Elite.new("DeerItems", "Rusted")
rusted:set_palette(palette, Color(0x9c4d26))
rusted:set_healthbar_icon(icon)
gm.elite_generate_palettes()

local rust = Buff.new("DeerItems", "RustedDebuff")
rust.icon_sprite = debuff_sprite
rust.icon_stack_subimage = false
rust.max_stack = 1
rust.is_timed = true
rust.is_debuff = true
rust:clear_callbacks()

local function exists(inst)
    return inst and Instance.exists(inst)
end

local function is_rusted(actor)
    return exists(actor) and actor.elite_type == rusted.value
end

local function is_player(actor)
    return exists(actor) and actor.object_index == gm.constants.oP
end

local function is_monsoon_or_higher()
    local difficulty_id = gm._mod_game_getDifficulty()
    if difficulty_id == nil or difficulty_id < 0 then return false end

    local difficulty = Difficulty.wrap(difficulty_id)
    return difficulty and (difficulty.is_monsoon_or_higher == true or difficulty.is_monsoon_or_higher == 1)
end

local function remove_rusted_from_card(card)
    local elites = List.wrap(card.elite_list)
    local index = elites:find(rusted)
    while index do
        elites:delete(index)
        index = elites:find(rusted)
    end
end

-- Elite types have no independent director price in the exposed API. Restricting
-- Rusted to the most expensive monster cards keeps its director budget high and
-- makes it substantially rarer than normal elite affixes.
local function update_card_availability()
    local cards = MonsterCard.find_all()
    local costs = {}
    for _, card in ipairs(cards) do
        local cost = card.spawn_cost or 0
        if not card.is_boss and cost > 0 then costs[#costs + 1] = cost end
    end

    if #costs == 0 then return end
    table.sort(costs)
    local threshold = costs[math.max(1, math.ceil(#costs * EXPENSIVE_CARD_QUANTILE))]
    local allowed_difficulty = is_monsoon_or_higher()

    for _, card in ipairs(cards) do
        local allowed = allowed_difficulty
            and not card.is_boss
            and (card.spawn_cost or 0) >= threshold

        local elites = List.wrap(card.elite_list)
        if allowed then
            if not elites:contains(rusted) then elites:add(rusted) end
        else
            remove_rusted_from_card(card)
        end
    end
end

Callback.add(Callback.TYPE.onDirectorPopulateSpawnArrays, "DeerItems-Rusted-availability", update_card_availability)

rusted:onApply(function(actor)
    if not gm._mod_net_isHost() then return end
    if not is_rusted(actor) then return end

    local data = actor:get_data("Rusted", GUID)
    if data.stats_applied then return end
    data.stats_applied = true

    actor.maxhp = actor.maxhp * HEALTH_MULTIPLIER
    actor.hp = actor.maxhp
    actor.damage = actor.damage * DAMAGE_MULTIPLIER
    if actor.gold then actor.gold = actor.gold * GOLD_MULTIPLIER end

    for slot = 0, 3 do
        local skill = actor:get_active_skill(slot)
        if skill and skill.cooldown and skill.cooldown > 0 then
            skill.cooldown = math.max(1, math.ceil(skill.cooldown * SKILL_COOLDOWN_MULTIPLIER))
        end
    end
end)

local spikes = {}
local spike_packet = Packet.new()

local function add_spike(x, y, owner)
    spikes[#spikes + 1] = { x = x, y = y, owner = owner, age = 0 }
end

spike_packet:onReceived(function(message)
    if not gm._mod_net_isClient() then return end
    local owner = message:read_instance()
    local x = message:read_float()
    local y = message:read_float()
    add_spike(x, y, owner)
end)

local function spawn_spike(owner, x, y)
    add_spike(x, y, owner)

    if Net.is_host() then
        local message = spike_packet:message_begin()
        message:write_instance(owner)
        message:write_float(x)
        message:write_float(y)
        message:send_to_all()
    end
end

local function play_spike_emerge_sound(spike)
    if exists(spike.owner) then
        spike.owner:sound_play(spike_emerge_sound, 0.9, 1.0)
    end
end

local function fire_spike_attack(spike, width, height)
    local owner = spike.owner
    if not is_rusted(owner) then return end

    local attack = owner:fire_explosion(spike.x, spike.y, width, height, 1, nil, nil, false)
    if attack and attack.attack_info then
        attack.attack_info.proc = false
        attack.attack_info:set_critical(false)
    end
end

Actor:onAttackHit("DeerItems-Rusted-applyDebuff", function(actor, victim, hit_info)
    if not gm._mod_net_isHost() then return end
    if not is_rusted(actor) or not is_player(victim) then return end

    -- Replace rather than add so the four-second effect cannot stack and always refreshes.
    if victim:buff_stack_count(rust) > 0 then victim:buff_remove(rust) end
    victim:buff_apply(rust, RUST_DURATION, 1)
end)

pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        local raw_victim = args[2] and args[2].value
        local damage = args[4] and args[4].value
        if not raw_victim or not damage or damage <= 0 then return end

        local victim = Instance.wrap(raw_victim)
        if not exists(victim) then return end
        -- Damage calculation also receives crates, map objects, and other non-actors.
        if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return end
        if victim:buff_stack_count(rust) <= 0 then return end

        args[4].value = damage * RUST_DAMAGE_MULTIPLIER
    end)
end)

Callback.add(Callback.TYPE.postStep, "DeerItems-Rusted-spikes", function()
    for index = #spikes, 1, -1 do
        local spike = spikes[index]
        spike.age = spike.age + 1

        if gm._mod_net_isHost() then
            if spike.age == TELEGRAPH_FRAMES then
                fire_spike_attack(spike, VERTICAL_WIDTH, VERTICAL_HEIGHT)
            elseif spike.age == TELEGRAPH_FRAMES + VERTICAL_FRAMES then
                fire_spike_attack(spike, HORIZONTAL_WIDTH, HORIZONTAL_HEIGHT)
            end
        end

        if spike.age == TELEGRAPH_FRAMES then play_spike_emerge_sound(spike) end

        if spike.age >= SPIKE_VISUAL_LIFETIME then
            table.remove(spikes, index)
        end
    end

    if not gm._mod_net_isHost() then return end

    local frame = Global._current_frame or 0
    for _, actor in ipairs(Instance.find_all(gm.constants.pActor)) do
        if is_rusted(actor) then
            local data = actor:get_data("Rusted", GUID)
            local next_cast = data.next_cast or frame
            if frame >= next_cast then
                local casted = false
                for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
                    local dx = player.x - actor.x
                    local dy = player.y - actor.y
                    local distance_sq = dx * dx + dy * dy
                    if distance_sq >= MIN_TARGET_DISTANCE * MIN_TARGET_DISTANCE
                        and distance_sq <= MAX_TARGET_DISTANCE * MAX_TARGET_DISTANCE then
                        spawn_spike(actor, player.x, player.bbox_bottom or player.y)
                        casted = true
                    end
                end

                if casted then
                    data.next_cast = frame + SPIKE_COOLDOWN_MIN + math.random(0, SPIKE_COOLDOWN_MAX_BONUS)
                end
            end
        end
    end
end)

Callback.add(Callback.TYPE.onDraw, "DeerItems-Rusted-drawSpikes", function()
    for _, spike in ipairs(spikes) do
        local frame
        if spike.age < TELEGRAPH_FRAMES then
            frame = math.min(3, math.floor(spike.age * 4 / TELEGRAPH_FRAMES))
        else
            local strike_age = spike.age - TELEGRAPH_FRAMES
            frame = 4 + math.min(14, math.floor(strike_age * ATTACK_ANIMATION_SPEED))
        end
        gm.draw_sprite(spike_sprite, math.min(18, frame), spike.x, spike.y)
    end
end)
