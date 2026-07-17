-- DeerItems-Cernunnos
-- Summoned ally actor for Ingrown Idol. Spawned only by the item, never by stage cards.

local SPRITE_PATH = PATH.."assets/sprites/actor/cernunnos/"
local GUID = _ENV["!guid"]

local sprite_mask      = Resources.sprite_load("DeerItems", "actor/CernunnosMask", SPRITE_PATH.."cernunnos.png", 1, 64, 128)
local sprite_palette   = Resources.sprite_load("DeerItems", "actor/CernunnosPalette", SPRITE_PATH.."palette.png", 1, 0, 0)
local sprite_spawn     = Resources.sprite_load("DeerItems", "actor/CernunnosSpawn", SPRITE_PATH.."spawn.png", 12, 64, 128, 0.5)
local sprite_idle      = Resources.sprite_load("DeerItems", "actor/CernunnosIdle", SPRITE_PATH.."idle.png", 6, 64, 128, 0.5)
local sprite_walk      = Resources.sprite_load("DeerItems", "actor/CernunnosWalk", SPRITE_PATH.."walk.png", 8, 64, 128, 0.5)
local sprite_jump      = Resources.sprite_load("DeerItems", "actor/CernunnosJump", SPRITE_PATH.."jump.png", 1, 64, 128)
local sprite_jump_peak = Resources.sprite_load("DeerItems", "actor/CernunnosJumpPeak", SPRITE_PATH.."jumpPeak.png", 1, 64, 128)
local sprite_fall      = Resources.sprite_load("DeerItems", "actor/CernunnosFall", SPRITE_PATH.."fall.png", 1, 64, 128)
local sprite_death     = Resources.sprite_load("DeerItems", "actor/CernunnosDeath", SPRITE_PATH.."death.png", 9, 64, 128, 0.5)
local sprite_shoot1    = Resources.sprite_load("DeerItems", "actor/CernunnosShoot1", SPRITE_PATH.."shoot1.png", 7, 64, 128, 0.5)

gm.elite_generate_palettes(sprite_palette)

local snd = Resources.sfx_load("DeerItems", "Cernunnos/beast", PATH.."assets/sounds/IngrownIdol.ogg")
local snd_spawn = Resources.sfx_load("DeerItems", "Cernunnos/spawn", PATH.."assets/sounds/CernunnosSpawn.ogg")
local snd_hit = Resources.sfx_load("DeerItems", "Cernunnos/hit", PATH.."assets/sounds/CernunnosHit.ogg")
local snd_death = Resources.sfx_load("DeerItems", "Cernunnos/death", PATH.."assets/sounds/CernunnosDeath.ogg")

local CernunnosSound = {
    spawn = 1,
    hit = 2,
    death = 3,
}
local cernunnos_sounds = {
    [CernunnosSound.spawn] = snd_spawn,
    [CernunnosSound.hit] = snd_hit,
    [CernunnosSound.death] = snd_death,
}

DeerItemsCernunnosConfig = DeerItemsCernunnosConfig or {
    life_frames = 45 * 60,
}

local LIFE_FRAMES = DeerItemsCernunnosConfig.life_frames
local BASE_HP = 1400
local BASE_SPEED = 2.2
local ATTACK_W = 256
local ATTACK_H = 128
local ATTACK_RANGE = 128
local SIGHT_RANGE = 520
local FOLLOW_RANGE = 480
local ATTACK_COOLDOWN = 22
local ATTACK_FRAME = 3
local STATE_RESYNC_PERIOD = 30
local CENTER_Y = -48
local TAUNT_RANGE = FOLLOW_RANGE / 3
local TIMER_RING_Y = -150
local TIMER_RING_R = 11
local TIMER_RING_SEGMENTS = 32
local TIMER_RING_BG = Color(0x1b1020)
local TIMER_RING_FG = Color(0xff5533)
local NOT_DRONE_KEY = "deeritems_not_drone"
local team_beasts = {}

local cernunnos = Object.new("DeerItems", "Cernunnos", Object.PARENT.enemyClassic)
cernunnos:set_sprite(sprite_idle)
cernunnos:set_depth(11)
cernunnos:clear_callbacks()

local primary = Skill.new("DeerItems", "CernunnosPrimary", ATTACK_COOLDOWN, 1, sprite_shoot1, 0, nil, true, false)
local statePrimary = State.new("DeerItems", "CernunnosPrimary")
statePrimary:clear_callbacks()

local function actor_exists(actor)
    return actor and Instance.exists(actor)
end

local function play_sound(actor, sound_id, volume, pitch)
    local sound = cernunnos_sounds[sound_id]
    if not sound or not actor_exists(actor) then return end
    actor:sound_play(sound, volume, pitch)
end

local function data_of(actor)
    return actor:get_data("DeerItems", GUID)
end

local function damage_coef(stack)
    return 3 + 1.5 * math.max(0, (stack or 1) - 1)
end

local function nearest_enemy(actor)
    local enemy_team = actor.team == 1 and 2 or 1
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, SIGHT_RANGE, false, enemy_team, true))
    local target, best = nil, math.huge

    for _, candidate in ipairs(found) do
        if actor_exists(candidate) then
            local dist = gm.point_distance(actor.x, actor.y, candidate.x, candidate.y)
            if dist < best then
                target = candidate
                best = dist
            end
        end
    end

    return target, best
end

local function face(actor, target)
    if not actor_exists(target) then return end
    actor.image_xscale = (target.x < actor.x) and -1 or 1
end

local function set_move_towards(actor, target, min_dist)
    actor.moveLeft = false
    actor.moveRight = false
    actor.moveUp = false

    if not actor_exists(target) then return end
    local dx = target.x - actor.x
    local dy = target.y - actor.y
    if math.abs(dx) > min_dist then
        actor.moveLeft = dx < 0
        actor.moveRight = dx > 0
    end
    if dy < -32 and math.random() < 0.05 then
        actor.moveUp = true
    end
    face(actor, target)
end

local function sync_move(actor)
    if actor.net_send_instance_message then
        actor:net_send_instance_message(0)
    end
end

local function enter_state(actor, state)
    if actor.enter_state then
        actor:enter_state(state)
    elseif actor.set_state then
        actor:set_state(state)
    else
        GM.actor_set_state(actor.value or actor, state.value or state)
    end
end

local packet_attack = Packet.new()
local packet_state = Packet.new()
local sync_network_state
packet_attack:onReceived(function(message)
    if not gm._mod_net_isClient() then return end

    local actor = message:read_instance()
    local facing = message:read_byte() == 1 and 1 or -1
    if not actor_exists(actor) then return end

    actor.image_xscale = facing
    enter_state(actor, statePrimary)
end)

local function set_targettable(actor, enabled)
    actor.is_targettable = enabled
    actor.is_character_enemy_targettable = enabled

    if enabled then
        if actor.__actor_update_target_marker then
            actor:__actor_update_target_marker()
        elseif actor_exists(actor.target_marker) then
            actor.target_marker.parent = actor
        else
            local ok, marker_object = pcall(Object.find, "ror-actorTargetPlayer")
            if ok and marker_object and marker_object.create then
                actor.target_marker = marker_object:create(actor.x, actor.y)
                actor.target_marker.parent = actor
            end
        end
    elseif actor_exists(actor.target_marker) then
        actor.target_marker.parent = -4
    end
end

local function targets_actor(enemy, actor)
    local target = enemy.target
    return target == actor or (actor_exists(target) and target.parent == actor)
end

local function nearest_player(enemy, team)
    local target, best = nil, math.huge
    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        if actor_exists(player) and player.team == team then
            local dist = gm.point_distance(enemy.x, enemy.y, player.x, player.y)
            if dist < best then
                target = player
                best = dist
            end
        end
    end
    return target
end

local function set_enemy_target(enemy, actor)
    enemy.target = actor
end

local function clear_enemy_target(enemy, actor)
    if not actor_exists(enemy) then return end

    local target = enemy.target
    if target == actor then
        enemy.target = -4
    elseif actor_exists(target) and target.parent == actor then
        target.parent = -4
        enemy.target = -4
    else
        return
    end

    local player = nearest_player(enemy, actor.team)
    if actor_exists(player) then
        enemy.target = player
    end

    if enemy.net_send_instance_message then
        enemy:net_send_instance_message(0)
    end
end

local function release_taunted_enemies(actor, data)
    if data.taunted_enemies then
        for id, enemy in pairs(data.taunted_enemies) do
            clear_enemy_target(enemy, actor)
            data.taunted_enemies[id] = nil
        end
    end

    for _, other in ipairs(Instance.find_all(gm.constants.pActor)) do
        if actor_exists(other) and other.team ~= actor.team and targets_actor(other, actor) then
            clear_enemy_target(other, actor)
        end
    end
end

local function update_taunted_enemies(actor, data)
    data.taunted_enemies = data.taunted_enemies or {}

    for id, enemy in pairs(data.taunted_enemies) do
        local keep = actor_exists(enemy)
            and targets_actor(enemy, actor)
            and gm.point_distance(actor.x, actor.y, enemy.x, enemy.y) <= TAUNT_RANGE
        if not keep then
            clear_enemy_target(enemy, actor)
            data.taunted_enemies[id] = nil
        end
    end

    data.target_cleanup_cd = (data.target_cleanup_cd or 0) - 1
    if data.target_cleanup_cd <= 0 then
        data.target_cleanup_cd = 15
        for _, other in ipairs(Instance.find_all(gm.constants.pActor)) do
            if actor_exists(other) and other.team ~= actor.team and targets_actor(other, actor) then
                if gm.point_distance(actor.x, actor.y, other.x, other.y) > TAUNT_RANGE then
                    clear_enemy_target(other, actor)
                    data.taunted_enemies[other.id] = nil
                else
                    data.taunted_enemies[other.id] = other
                end
            end
        end
    end

    local enemy_team = actor.team == 1 and 2 or 1
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, TAUNT_RANGE, false, enemy_team, true))
    for _, enemy in ipairs(found) do
        if actor_exists(enemy) then
            local changed = not targets_actor(enemy, actor)
            set_enemy_target(enemy, actor)
            data.taunted_enemies[enemy.id] = enemy
            if changed and enemy.net_send_instance_message then
                enemy:net_send_instance_message(0)
            end
        end
    end
end

local function draw_timer_ring(actor)
    local data = data_of(actor)
    local life = math.max(0, math.min(LIFE_FRAMES, data.life or LIFE_FRAMES))
    local frac = life / LIFE_FRAMES
    local cx = actor.x
    local cy = actor.y + TIMER_RING_Y

    gm.draw_set_alpha(0.55)
    gm.draw_set_colour(TIMER_RING_BG)
    gm.draw_circle(cx, cy, TIMER_RING_R, true)
    gm.draw_circle(cx, cy, TIMER_RING_R - 1, true)

    gm.draw_set_alpha(1)
    gm.draw_set_colour(TIMER_RING_FG)
    local segments = math.floor(TIMER_RING_SEGMENTS * frac)
    for i = 0, segments - 1 do
        local a1 = math.rad(-90 + 360 * i / TIMER_RING_SEGMENTS)
        local a2 = math.rad(-90 + 360 * (i + 0.82) / TIMER_RING_SEGMENTS)
        for r = TIMER_RING_R - 2, TIMER_RING_R do
            gm.draw_line(cx + math.cos(a1) * r, cy + math.sin(a1) * r, cx + math.cos(a2) * r, cy + math.sin(a2) * r)
        end
    end
    gm.draw_set_colour(Color.WHITE)
    gm.draw_set_alpha(1)
end

cernunnos:onCreate(function(actor)
    actor.sprite_palette = sprite_palette
    actor.sprite_spawn = sprite_spawn
    actor.sprite_idle = sprite_idle
    actor.sprite_walk = sprite_walk
    actor.sprite_jump = sprite_jump
    actor.sprite_jump_peak = sprite_jump_peak
    actor.sprite_fall = sprite_fall
    actor.sprite_death = sprite_death

    actor.can_jump = true
    actor.mask_index = sprite_mask
    actor.sound_spawn = snd_spawn
    actor.sound_hit = snd_hit
    actor.sound_death = snd_death

    actor:enemy_stats_init(1, BASE_HP, 50, 0)
    actor.pHmax_base = BASE_SPEED
    actor.z_range = ATTACK_RANGE
    actor.x_range = ATTACK_RANGE
    actor.y_range = ATTACK_RANGE
    actor.can_drop = false
    actor.exp_worth = 0
    actor.gold = 0
    actor:set_default_skill(Skill.SLOT.primary, primary)
    set_targettable(actor, false)

    local data = data_of(actor)
    data[NOT_DRONE_KEY] = true
    data.damage_scale = actor.damage or 1
    data.life = LIFE_FRAMES
    data.stack = 1
    data.attack_cd = 0
    data.taunted_enemies = {}

    actor:init_actor_late()
    actor:alarm_set(0, -1)
    play_sound(actor, CernunnosSound.spawn, 1.0, 1.0)
end)

cernunnos:onStep(function(actor)
    local data = data_of(actor)
    data[NOT_DRONE_KEY] = true

    if gm._mod_net_isClient() then return end
    actor:alarm_set(0, -1)

    data.life = (data.life or LIFE_FRAMES) - 1
    if data.life <= 0 then
        release_taunted_enemies(actor, data)
        set_targettable(actor, false)
        actor.hp = -1000000
        return
    end

    data.state_resync = (data.state_resync or 0) + 1
    if data.state_resync >= STATE_RESYNC_PERIOD then
        data.state_resync = 0
        if Net.is_host() and sync_network_state then sync_network_state(actor) end
    end

    update_taunted_enemies(actor, data)
    if actor.actor_state_current_id ~= -1 then return end

    local target, dist = nearest_enemy(actor)
    if actor_exists(target) then
        actor.target = target
        set_move_towards(actor, target, ATTACK_RANGE - 16)
        if dist <= ATTACK_RANGE and (data.attack_cd or 0) <= 0 then
            enter_state(actor, statePrimary)
            data.attack_cd = math.max(1, math.floor(ATTACK_COOLDOWN / math.max(0.1, actor.attack_speed or 1)))
            if Net.is_host() then
                local message = packet_attack:message_begin()
                message:write_instance(actor)
                message:write_byte(actor.image_xscale >= 0 and 1 or 0)
                message:send_to_all()
            end
        end
    else
        local owner = data.owner
        if actor_exists(owner) and gm.point_distance(actor.x, actor.y, owner.x, owner.y) > FOLLOW_RANGE then
            set_move_towards(actor, owner, FOLLOW_RANGE)
        else
            actor.moveLeft = false
            actor.moveRight = false
            actor.moveUp = false
        end
    end

    if (data.attack_cd or 0) > 0 then
        data.attack_cd = data.attack_cd - 1
    end
    sync_move(actor)
end)

cernunnos:onDestroy(function(actor)
    play_sound(actor, CernunnosSound.death, 1.0, 0.9 + math.random() * 0.2)
    local data = data_of(actor)
    release_taunted_enemies(actor, data)
    set_targettable(actor, false)
    if team_beasts[actor.team] and team_beasts[actor.team].id == actor.id then
        team_beasts[actor.team] = nil
    end
    if actor_exists(data.owner) then
        local od = data.owner:get_data("IngrownIdol", GUID)
        if od.beast and od.beast.id == actor.id then
            od.beast = nil
        end
    end
end)

cernunnos:onDraw(function(actor)
    draw_timer_ring(actor)
end)

statePrimary:onEnter(function(actor, data)
    actor.image_index = 0
    data.fired = false
    actor:sound_play(snd, 0.8, 0.9 + math.random() * 0.2)
end)

statePrimary:onStep(function(actor, data)
    actor:skill_util_fix_hspeed()
    actor:actor_animation_set(sprite_shoot1, 0.22 * math.max(0.1, actor.attack_speed or 1))

    if gm._mod_net_isClient() then
        actor:skill_util_exit_state_on_anim_end()
        return
    end

    local target = actor.target
    if actor_exists(target) then
        face(actor, target)
    end

    if not data.fired and actor.image_index >= ATTACK_FRAME then
        data.fired = true
        actor:fire_explosion(actor.x, actor.y + CENTER_Y, ATTACK_W, ATTACK_H, 1, nil, nil, true)
        play_sound(actor, CernunnosSound.hit, 1.0, 1.0)
    end

    actor:skill_util_exit_state_on_anim_end()
end)

local function apply_network_config(inst, owner, stack, life)
    local data = data_of(inst)
    data.owner = owner
    data.stack = stack or 1
    data.life = life or LIFE_FRAMES
    data[NOT_DRONE_KEY] = true

    if actor_exists(owner) then
        inst.parent = owner
        inst.team = owner.team
        if owner.level then inst.level = owner.level end
    end

    inst.pHmax_base = BASE_SPEED
    inst.pHmax = BASE_SPEED
    inst.can_drop = false
    inst.exp_worth = 0
    inst.gold = 0
    set_targettable(inst, false)
end

local function configure(inst, owner, stack)
    local data = data_of(inst)
    if not actor_exists(data.owner) then data.owner = owner end
    apply_network_config(inst, data.owner, stack, LIFE_FRAMES)

    local damage_scale = data.damage_scale or 1
    local damage_owner = data.owner
    inst.damage = (damage_owner.damage or 1) * damage_coef(stack) * damage_scale
    inst.damage_base = inst.damage
    release_taunted_enemies(inst, data)
end

-- enemyClassic instances already replicate themselves. Only the custom state
-- needs a packet; manually syncing the whole instance creates a second client
-- copy of the ally.
sync_network_state = function(actor)
    if not Net.is_host() or not actor_exists(actor) then return end

    local data = data_of(actor)
    if not actor_exists(data.owner) then return end

    local message = packet_state:message_begin()
    message:write_instance(actor)
    message:write_instance(data.owner)
    message:write_ushort(data.stack or 1)
    message:write_int(data.life or LIFE_FRAMES)
    message:send_to_all()
end

packet_state:onReceived(function(message)
    if not gm._mod_net_isClient() then return end

    local actor = message:read_instance()
    local owner = message:read_instance()
    local stack = message:read_ushort()
    local life = message:read_int()
    if not actor_exists(actor) or not actor_exists(owner) then return end

    apply_network_config(actor, owner, stack, life)
    owner:get_data("IngrownIdol", GUID).beast = actor
end)

local function alive(inst)
    return actor_exists(inst) and (inst.hp == nil or inst.hp > 0)
end

local function spawn(owner, stack)
    if gm._mod_net_isClient() or not actor_exists(owner) then return nil end

    local existing = team_beasts[owner.team]
    if alive(existing) then
        configure(existing, owner, stack)
        sync_network_state(existing)
        return existing
    end

    local inst = cernunnos:create(owner.x, owner.y - 16)
    configure(inst, owner, stack)
    team_beasts[owner.team] = inst
    if Net.is_host() then
        Alarm.create(function()
            if alive(inst) then sync_network_state(inst) end
        end, 1)
    end
    owner:sound_play(snd, 1.0, 0.8)
    return inst
end

local function get_for_team(team)
    local inst = team_beasts[team]
    if alive(inst) then return inst end
    team_beasts[team] = nil
    return nil
end

local function is_not_drone(actor)
    if not actor_exists(actor) then return false end
    if actor.object_index == cernunnos.value then return true end
    if not actor.get_data then return false end
    return data_of(actor)[NOT_DRONE_KEY] == true
end

Callback.add(Callback.TYPE.onStageStart, "DeerItems-Cernunnos-clear", function()
    if gm._mod_net_isClient() then return end
    team_beasts = {}
    for _, actor in ipairs(Instance.find_all(cernunnos.value)) do
        if actor_exists(actor) then actor:destroy() end
    end
end)

DeerItemsCernunnos = {
    object = cernunnos,
    life_frames = LIFE_FRAMES,
    not_drone_key = NOT_DRONE_KEY,
    spawn = spawn,
    get_for_team = get_for_team,
    is_not_drone = is_not_drone,
}
