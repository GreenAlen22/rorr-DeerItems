-- Артефакт бури: чем больше предметов у команды, тем чаще в неё бьют молнии.

local sprite = Sprite.new("artifact/Storm",
    PATH.."assets/sprites/artifacts/ArtifactOfStorm.png",
    3,
    16,
    16
)
local volt_overload = Sprite.new("artifact/StormVoltOverload",
    PATH.."assets/sprites/particle/voltOverload.png",
    13,
    64,
    112
)
local volt_overload_sound = Sound.new("artifact/StormVoltOverload",
    PATH.."assets/sounds/voltOverload.ogg"
)

local BASE_INTERVAL = 15 * 60
local MIN_INTERVAL = 60
local FREQUENCY_MULTIPLIER = 1.25
local ITEMS_PER_INTERVAL_HALVING = 25
local ITEMS_PER_EXTRA_STRIKE = 25
local MIN_STRIKES_PER_WAVE = 3
local STRIKE_RANGE = 8 * 32
local STRIKE_RADIUS = 2 * 32
local MAX_HP_DAMAGE = 0.05
local TELEGRAPH_DURATION = 60
-- Предупреждение занимает кадры 1–4. На пятом кадре начинается анимация удара.
local TELEGRAPH_END_FRAME = 4

local TIER_WEIGHTS = {
    [ItemTier.COMMON] = 1,
    [ItemTier.UNCOMMON] = 3,
    [ItemTier.RARE] = 9,
    [ItemTier.EQUIPMENT] = 6,
    [ItemTier.BOSS] = 6,
    [ItemTier.SPECIAL] = 6,
    [ItemTier.NOTIER] = 0
}

local artifact = Artifact.new("Storm")
artifact.sprite_loadout_id = sprite
artifact.sprite_pickup_id = sprite
artifact.token_name = "artifact.Storm.name"
artifact.token_pickup_name = "artifact.Storm.pickup"
artifact.token_description = "artifact.Storm.description"

local storm_timer = 0
local pending_strikes = {}
-- Волны и урон считает хост. Эффекты oEfExplosion локальные, поэтому хост
-- рассылает точку удара, а клиент сам ведёт предупреждение и вспышку.
local packet_strike = Packet.new("ArtifactOfStorm-packet_strike")

Callback.add(Callback.ON_GAME_START, function()
    storm_timer = 0
    pending_strikes = {}
end)

local function is_alive(player)
    return player
        and Instance.exists(player)
        and not player.dead
        and (player.hp or 0) > 0
end

local function total_player_item_weight(players)
    local total = 0
    for _, player in ipairs(players) do
        for _, item_id in ipairs(player.inventory_item_order) do
            local item = Item.wrap(item_id)
            local stack = math.max(0, player.inventory_item_stack[item_id + 1] or 0)
            total = total + stack * (TIER_WEIGHTS[item.tier] or 0)
        end
    end
    return total
end

local function strike_interval(item_weight)
    return math.max(
        MIN_INTERVAL / FREQUENCY_MULTIPLIER,
        math.floor(
            BASE_INTERVAL / (FREQUENCY_MULTIPLIER * (1 + item_weight / ITEMS_PER_INTERVAL_HALVING))
        )
    )
end

local function strike_count(item_weight)
    return MIN_STRIKES_PER_WAVE + math.floor(item_weight / ITEMS_PER_EXTRA_STRIKE)
end

local function create_effect(x, y, frame, speed)
    local effect = gm.instance_create(x, y, gm.constants.oEfExplosion)
    effect.sprite_index = volt_overload.value
    effect.image_yscale = 0.8
    effect.image_xscale = 0.8
    effect.image_index = frame
    effect.image_speed = speed
    return effect
end

local function strike(x, y, players)
    create_effect(x, y, TELEGRAPH_END_FRAME, 1)

    for _, player in ipairs(players) do
        local dx = player.x - x
        local dy = player.y - y
        if dx * dx + dy * dy <= STRIKE_RADIUS * STRIKE_RADIUS then
            player.hp = player.hp - player.maxhp * MAX_HP_DAMAGE
            if player.hp <= 0 then player.hp = -1000000 end
            player:screen_shake(3)
            player:instance_resync()
        end
    end

end

local function clear_pending_strikes()
    for _, pending in ipairs(pending_strikes) do
        if Instance.exists(pending.effect) then gm.instance_destroy(pending.effect) end
    end
    pending_strikes = {}
end

local function add_pending_strike(x, y)
    table.insert(pending_strikes, {
        x = x,
        y = y,
        timer = TELEGRAPH_DURATION,
        effect = create_effect(x, y, 0, TELEGRAPH_END_FRAME / TELEGRAPH_DURATION)
    })
end

packet_strike:set_serializers(function(buffer, x, y)
    buffer:write_float(x)
    buffer:write_float(y)
end, function(buffer)
    local x = buffer:read_float()
    local y = buffer:read_float()
    if not Net.client or not artifact.active then return end
    add_pending_strike(x, y)
end)

local function queue_strike(players)
    local target = players[math.random(#players)]
    local distance = math.random() * STRIKE_RANGE
    local angle = math.random() * math.pi * 2
    local x = target.x + math.cos(angle) * distance
    local y = target.y + math.sin(angle) * distance

    add_pending_strike(x, y)
    packet_strike:send_to_all(x, y)
end

Callback.add(Callback.POST_STEP, function()
    if not artifact.active then
        storm_timer = 0
        clear_pending_strikes()
        return
    end

    -- У клиента список игроков пуст: урон по ним наносит хост.
    local players = {}
    if not Net.client then
        for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
            if is_alive(player) then
                table.insert(players, player)
            end
        end
    end

    local struck = false
    for index = #pending_strikes, 1, -1 do
        local pending = pending_strikes[index]
        pending.timer = pending.timer - 1
        if pending.timer <= 0 then
            if Instance.exists(pending.effect) then gm.instance_destroy(pending.effect) end
            strike(pending.x, pending.y, players)
            table.remove(pending_strikes, index)
            struck = true
        end
    end
    local listener = Player.get_local()
    if struck and listener and Instance.exists(listener) then
        listener:sound_play(volt_overload_sound, 1.5, 0.9 + math.random() * 0.2)
    end

    if Net.client or #players == 0 then return end

    local item_weight = total_player_item_weight(players)
    storm_timer = storm_timer + 1
    if storm_timer < strike_interval(item_weight) then return end
    storm_timer = 0

    for _ = 1, strike_count(item_weight) do
        queue_strike(players)
    end
end)
