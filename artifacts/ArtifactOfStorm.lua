-- Артефакт бури: чем больше предметов у команды, тем чаще в неё бьют молнии.

local sprite = Resources.sprite_load(
    "DeerItems",
    "artifact/Storm",
    PATH.."assets/sprites/artifacts/ArtifactOfStorm.png",
    3,
    16,
    16
)
local volt_overload = Resources.sprite_load(
    "DeerItems",
    "artifact/StormVoltOverload",
    PATH.."assets/sprites/particle/voltOverload.png",
    13,
    64,
    112
)
local volt_overload_sound = Resources.sfx_load(
    "DeerItems",
    "artifact/StormVoltOverload",
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
    [Item.TIER.common] = 1,
    [Item.TIER.uncommon] = 3,
    [Item.TIER.rare] = 9,
    [Item.TIER.equipment] = 6,
    [Item.TIER.boss] = 6,
    [Item.TIER.special] = 6,
    [Item.TIER.notier] = 0
}

local artifact = Artifact.new("DeerItems", "Storm")
artifact:set_sprites(sprite, sprite)
artifact:set_text(
    "artifact.Storm.name",
    "artifact.Storm.pickup",
    "artifact.Storm.description"
)

local storm_timer = 0
local pending_strikes = {}

Callback.add(Callback.TYPE.onGameStart, "DeerItems-Storm-resetTimer", function()
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
    effect.sprite_index = volt_overload
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

local function queue_strike(players)
    local target = players[math.random(#players)]
    local distance = math.random() * STRIKE_RANGE
    local angle = math.random() * math.pi * 2
    local x = target.x + math.cos(angle) * distance
    local y = target.y + math.sin(angle) * distance

    table.insert(pending_strikes, {
        x = x,
        y = y,
        timer = TELEGRAPH_DURATION,
        effect = create_effect(x, y, 0, TELEGRAPH_END_FRAME / TELEGRAPH_DURATION)
    })
end

Callback.add(Callback.TYPE.postStep, "DeerItems-Storm-update", function()
    if gm._mod_net_isClient() or not artifact.active then
        storm_timer = 0
        clear_pending_strikes()
        return
    end

    local players = {}
    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        if is_alive(player) then
            table.insert(players, player)
        end
    end
    if #players == 0 then return end

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
    if struck then
        players[1]:sound_play(volt_overload_sound, 1.5, 0.9 + math.random() * 0.2)
    end

    local item_weight = total_player_item_weight(players)
    storm_timer = storm_timer + 1
    if storm_timer < strike_interval(item_weight) then return end
    storm_timer = 0

    for _ = 1, strike_count(item_weight) do
        queue_strike(players)
    end
end)
