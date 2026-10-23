-- DeerItems-Rusted
-- Элитный враг только для «Муссона»: создаёт под дальними игроками двухэтапные ржавые шипы.

local GUID = _ENV["!guid"]

local METERS_TO_PIXELS = 32
local MIN_TARGET_DISTANCE = 10 * METERS_TO_PIXELS
local MAX_TARGET_DISTANCE = 40 * METERS_TO_PIXELS

local SPIKE_COOLDOWN_MIN = 10 * 60
local SPIKE_COOLDOWN_MAX_BONUS = 5 * 60

local HEALTH_MULTIPLIER = 4.5
local DAMAGE_MULTIPLIER = 4
local SKILL_COOLDOWN_MULTIPLIER = 0.4
local GOLD_MULTIPLIER = 10
local RUST_DURATION = 4 * 60
local RUST_DAMAGE_MULTIPLIER = 1.1
local EXPENSIVE_CARD_QUANTILE = 0.90

local palette = Sprite.new("elite/RustedPalette",
    PATH.."assets/sprites/elites/sRusted/PaletteRusted.png",
    1,
    0,
    0
)
local icon = Sprite.new("elite/RustedIcon",
    PATH.."assets/sprites/elites/sRusted/IconRusted.png",
    1,
    10.5,
    9
)
local spike_sprite = Sprite.new("elite/RustedSpike",
    PATH.."assets/sprites/elites/sRusted/RustSpike.png",
    19,
    32,
    64
)
local debuff_sprite = Sprite.new("elite/RustedDebuff",
    PATH.."assets/sprites/elites/sRusted/RustDebuff.png",
    1,
    8,
    8
)
local spike_emerge_sound = Sound.new("elite/RustedSpikeEmerge",
    PATH.."assets/sounds/FearEyes.ogg"
)

local rusted = Elite.new("Rusted")
-- set_palette в ReturnsAPI берёт одну палитру и сам перегенерирует палитры элит;
-- цвет, который RoMT принимал вторым аргументом, — отдельное поле.
rusted.blend_col = Color(0x9c4d26)
rusted:set_palette(palette)
rusted.healthbar_icon = icon

local rust = Buff.new("RustedDebuff")
rust.icon_sprite = debuff_sprite
rust.icon_stack_subimage = false
rust.max_stack = 1
rust.is_timed = true
rust.is_debuff = true
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

-- В доступном API у элит нет отдельной цены директора. Поэтому Rusted добавлен
-- только к самым дорогим картам монстров: так он требует большой бюджет директора
-- и появляется заметно реже обычных элит.
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

Callback.add(Callback.ON_DIRECTOR_POPULATE_SPAWN_ARRAYS, update_card_availability)

-- HP и урон — через api на каждом пересчёте и на каждой машине. Прямая запись в
-- maxhp/damage жила до первого пересчёта, а его запускает любой бафф на враге
-- (apply_buff_internal → actor_queue_dirty): элита теряла множители, HP обрезалось.
RecalculateStats.add(function(actor, api)
    if not is_rusted(actor) then return end
    api.maxhp_mult(HEALTH_MULTIPLIER)
    api.damage_mult(DAMAGE_MULTIPLIER)
end)

Callback.add(rusted.on_apply, function(actor)
    if not Net.host then return end
    if not is_rusted(actor) then return end

    local data = Instance.get_data(actor, "Rusted", GUID)
    if data.stats_applied then return end
    data.stats_applied = true

    actor:recalculate_stats()
    actor.hp = actor.maxhp
    if actor.gold then actor.gold = actor.gold * GOLD_MULTIPLIER end

    for slot = 0, 3 do
        local skill = actor:get_active_skill(slot)
        if skill and skill.cooldown and skill.cooldown > 0 then
            skill.cooldown = math.max(1, math.ceil(skill.cooldown * SKILL_COOLDOWN_MULTIPLIER))
        end
    end
end)

local spike_kind = DeerItemsGroundSpikes.kind("Rusted", {
    sprite = spike_sprite,
    sound = spike_emerge_sound,
    damage = 1,
    can_fire = is_rusted,
})

Callback.add(Callback.ON_ATTACK_HIT, function(hit_info)
    local actor = hit_info.inflictor
    local victim = hit_info.target
    if not Net.host then return end
    if not is_rusted(actor) or not is_player(victim) then return end

    -- Сначала снимаем эффект, чтобы четыре секунды не складывались, а обновлялись.
    if victim:buff_count(rust) > 0 then victim:buff_remove(rust) end
    victim:buff_apply(rust, RUST_DURATION, 1)
end)

pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        local raw_victim = args[2] and args[2].value
        local damage = args[4] and args[4].value
        if not raw_victim or not damage or damage <= 0 then return end

        local victim = Instance.wrap(raw_victim)
        if not exists(victim) then return end
        -- Расчёт урона приходит и для ящиков, объектов карты и прочих не-актёров.
        if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return end
        if victim:buff_count(rust) <= 0 then return end

        args[4].value = damage * RUST_DAMAGE_MULTIPLIER
    end)
end)

Callback.add(Callback.POST_STEP, function()
    if not Net.host then return end

    local frame = Global._current_frame or 0
    for _, actor in ipairs(Instance.find_all(gm.constants.pActor)) do
        if is_rusted(actor) then
            local data = Instance.get_data(actor, "Rusted", GUID)
            local next_cast = data.next_cast or frame
            if frame >= next_cast then
                local casted = false
                for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
                    local dx = player.x - actor.x
                    local dy = player.y - actor.y
                    local distance_sq = dx * dx + dy * dy
                    if distance_sq >= MIN_TARGET_DISTANCE * MIN_TARGET_DISTANCE
                        and distance_sq <= MAX_TARGET_DISTANCE * MAX_TARGET_DISTANCE then
                        spike_kind:spawn(actor, player.x, player.bbox_bottom or player.y)
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
