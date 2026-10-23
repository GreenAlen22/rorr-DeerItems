-- DeerItems-Cernunnos
-- Призываемый союзник для Ingrown Idol. Создаётся только предметом, а не картами этапа.

local SPRITE_PATH = PATH.."assets/sprites/actor/sCernunnos/"
local GUID = _ENV["!guid"]

local sprite_mask      = Sprite.new("actor/CernunnosMask", SPRITE_PATH.."cernunnos.png", 1, 64, 128)
local sprite_palette   = Sprite.new("actor/CernunnosPalette", SPRITE_PATH.."palette.png", 1, 0, 0)
local sprite_spawn     = Sprite.new("actor/CernunnosSpawn", SPRITE_PATH.."spawn.png", 12, 64, 128)
local sprite_idle      = Sprite.new("actor/CernunnosIdle", SPRITE_PATH.."idle.png", 6, 64, 128)
local sprite_walk      = Sprite.new("actor/CernunnosWalk", SPRITE_PATH.."walk.png", 6, 64, 128)
local sprite_jump      = Sprite.new("actor/CernunnosJump", SPRITE_PATH.."jump.png", 1, 64, 128)
local sprite_jump_peak = Sprite.new("actor/CernunnosJumpPeak", SPRITE_PATH.."jumpPeak.png", 1, 64, 128)
local sprite_fall      = Sprite.new("actor/CernunnosFall", SPRITE_PATH.."fall.png", 1, 64, 128)
-- Кадр смерти 160 в ширину: лежащее тело длиннее 128. Origin — тот же центр под ногами.
local sprite_death     = Sprite.new("actor/CernunnosDeath", SPRITE_PATH.."death.png", 9, 80, 128)
local sprite_shoot1    = Sprite.new("actor/CernunnosShoot1", SPRITE_PATH.."shoot1.png", 7, 64, 128)

-- Скорость анимации в RoMT была шестым аргументом загрузки; Sprite.new в ReturnsAPI её не берёт.
for _, s in ipairs({sprite_spawn, sprite_idle, sprite_walk, sprite_death, sprite_shoot1}) do
    s:set_speed(0.5)
end

gm.elite_generate_palettes(sprite_palette.value)

local snd = Sound.new("Cernunnos/beast", PATH.."assets/sounds/IngrownIdol.ogg")
local snd_spawn = Sound.new("Cernunnos/spawn", PATH.."assets/sounds/CernunnosSpawn.ogg")
local snd_hit = Sound.new("Cernunnos/hit", PATH.."assets/sounds/CernunnosHit.ogg")
local snd_death = Sound.new("Cernunnos/death", PATH.."assets/sounds/CernunnosDeath.ogg")

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

local cernunnos = Object.new("Cernunnos", Object.Parent.ENEMY_CLASSIC)
cernunnos:set_sprite(sprite_idle)
cernunnos:set_depth(11)
local primary = Skill.new("CernunnosPrimary")
primary.cooldown = ATTACK_COOLDOWN
primary.damage = 1
primary.sprite = sprite_shoot1
primary.subimage = 0
primary.is_primary = true

local statePrimary = ActorState.new("CernunnosPrimary")
-- -4 и INVALID отсекаются до Instance.exists: обёртка INVALID разворачивается в саму
-- Lua-таблицу, а -4 база знаний считает опасным для exists (mechanics.md, «Агро»).
local function actor_exists(actor)
    return actor ~= nil and actor ~= -4 and actor ~= Instance.INVALID and Instance.exists(actor)
end

local function play_sound(actor, sound_id, volume, pitch)
    local sound = cernunnos_sounds[sound_id]
    if not sound or not actor_exists(actor) then return end
    actor:sound_play(sound, volume, pitch)
end

local function data_of(actor)
    return Instance.get_data(actor, "DeerItems", GUID)
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

local packet_attack = Packet.new("Cernunnos-packet_attack")
local packet_state = Packet.new("Cernunnos-packet_state")
local sync_network_state
packet_attack:set_serializers(function(buffer, actor, facing)
    buffer:write_instance(actor)
    buffer:write_byte(facing >= 0 and 1 or 0)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local facing = buffer:read_byte() == 1 and 1 or -1
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

-- Таунт: враг в радиусе получает в target маркер Cernunnos. ИИ врага держит в target не
-- саму цель, а маркер и читает её из target.parent (alarm_ai_default_try_find_nav_path:
-- target.parent.bbox_bottom). Ванильный маркер oActorTargetPlayer находит любой враг через
-- find_target, а Cernunnos задуман нецелевым: свой объект видит только тот, кому таунт
-- записал его в target. Маркер живёт у хоста — ИИ врагов и таунт идут только там.
local taunt_marker = Object.new("CernunnosTauntMarker")

local function taunt_marker_of(actor, data)
    local id = data.taunt_marker_id
    if id and Instance.exists(id) then return Instance.wrap(id) end

    local marker = taunt_marker:create(actor.x, actor.y)
    marker.parent = actor.id
    -- distance_to_object врага меряет до маски маркера; ваниль даёт маркеру маску актёра.
    marker.mask_index = sprite_mask.value
    data.taunt_marker_id = marker.id
    return marker
end

local function targets_marker(enemy, data)
    local target = enemy.target
    if target == nil or target == -4 then return false end
    local id = type(target) == "number" and target or target.id
    return id == data.taunt_marker_id
end

local function clear_enemy_target(enemy, data)
    if not actor_exists(enemy) or not targets_marker(enemy, data) then return end

    -- -4: на следующем ходу ИИ сам выберет цель (alarm_ai_default_do_targetting).
    enemy.target = -4
    if enemy.net_send_instance_message then
        enemy:net_send_instance_message(0)
    end
end

local function release_taunted_enemies(actor, data)
    for id in pairs(data.taunted_enemies or {}) do
        if Instance.exists(id) then clear_enemy_target(Instance.wrap(id), data) end
    end
    data.taunted_enemies = {}

    local id = data.taunt_marker_id
    data.taunt_marker_id = nil
    if id and Instance.exists(id) then Instance.wrap(id):destroy() end
end

local function update_taunted_enemies(actor, data)
    data.taunted_enemies = data.taunted_enemies or {}
    local marker = taunt_marker_of(actor, data)
    marker.x = actor.x
    marker.y = actor.y

    -- Ключ — id врага: обёртка, хранимая между кадрами, после его смерти смотрит в чужую память.
    for id in pairs(data.taunted_enemies) do
        local enemy = Instance.exists(id) and Instance.wrap(id)
        local keep = enemy
            and targets_marker(enemy, data)
            and gm.point_distance(actor.x, actor.y, enemy.x, enemy.y) <= TAUNT_RANGE
        if not keep then
            if enemy then clear_enemy_target(enemy, data) end
            data.taunted_enemies[id] = nil
        end
    end

    -- Ваниль переводит врага на игрока, если тот заметно ближе (do_targetting), поэтому
    -- маркер ставится заново каждый шаг, а пакет уходит только при смене цели.
    local enemy_team = actor.team == 1 and 2 or 1
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, TAUNT_RANGE, false, enemy_team, true))
    for _, enemy in ipairs(found) do
        if actor_exists(enemy) and not targets_marker(enemy, data) then
            enemy.target = marker.id
            data.taunted_enemies[enemy.id] = true
            if enemy.net_send_instance_message then
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

Callback.add(cernunnos.on_create, function(actor)
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
    actor:set_default_skill(Skill.Slot.PRIMARY, primary)
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

Callback.add(cernunnos.on_step, function(actor)
    local data = data_of(actor)
    data[NOT_DRONE_KEY] = true

    if Net.client then return end
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
        if Net.host and sync_network_state then sync_network_state(actor) end
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
            if Net.host then
                packet_attack:send_to_all(actor, actor.image_xscale)
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

Callback.add(cernunnos.on_destroy, function(actor)
    play_sound(actor, CernunnosSound.death, 1.0, 0.9 + math.random() * 0.2)
    local data = data_of(actor)
    release_taunted_enemies(actor, data)
    set_targettable(actor, false)
    if team_beasts[actor.team] and team_beasts[actor.team].id == actor.id then
        team_beasts[actor.team] = nil
    end
    if actor_exists(data.owner) then
        local od = Instance.get_data(data.owner, "IngrownIdol", GUID)
        if od.beast and od.beast.id == actor.id then
            od.beast = nil
        end
    end
end)

Callback.add(cernunnos.on_draw, function(actor)
    draw_timer_ring(actor)
end)

Callback.add(statePrimary.on_enter, function(actor, data)
    actor.image_index = 0
    data.fired = false
    actor:sound_play(snd, 0.8, 0.9 + math.random() * 0.2)
end)

Callback.add(statePrimary.on_step, function(actor, data)
    actor:skill_util_fix_hspeed()
    actor:actor_animation_set(sprite_shoot1, 0.22 * math.max(0.1, actor.attack_speed or 1))

    if Net.client then
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

-- Экземпляры enemyClassic уже синхронизируются сами. Пакет нужен только для
-- дополнительного состояния: ручная синхронизация всего экземпляра создаст у клиента
-- вторую копию союзника.
sync_network_state = function(actor)
    if not Net.host or not actor_exists(actor) then return end

    local data = data_of(actor)
    if not actor_exists(data.owner) then return end

    packet_state:send_to_all(actor, data.owner, data.stack or 1, data.life or LIFE_FRAMES)
end

packet_state:set_serializers(function(buffer, actor, owner, stack, life)
    buffer:write_instance(actor)
    buffer:write_instance(owner)
    buffer:write_ushort(stack)
    buffer:write_int(life)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local owner = buffer:read_instance()
    local stack = buffer:read_ushort()
    local life = buffer:read_int()
    if not actor_exists(actor) or not actor_exists(owner) then return end

    apply_network_config(actor, owner, stack, life)
    Instance.get_data(owner, "IngrownIdol", GUID).beast = actor
end)

local function alive(inst)
    return actor_exists(inst) and (inst.hp == nil or inst.hp > 0)
end

local function spawn(owner, stack)
    if Net.client or not actor_exists(owner) then return nil end

    local existing = team_beasts[owner.team]
    if alive(existing) then
        configure(existing, owner, stack)
        sync_network_state(existing)
        return existing
    end

    local inst = cernunnos:create(owner.x, owner.y - 16)
    configure(inst, owner, stack)
    team_beasts[owner.team] = inst
    if Net.host then
        Alarm.add(1, function()
            if alive(inst) then sync_network_state(inst) end
        end)
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
    if actor == nil then return false end
    -- Сюда приходит и сырой self из gm.*_script_hook.
    actor = Instance.wrap(actor)
    if not actor_exists(actor) then return false end
    -- object_index своего объекта — объект-носитель, с cernunnos.value он не совпадает никогда.
    if actor:get_object_index() == cernunnos.value then return true end
    return data_of(actor)[NOT_DRONE_KEY] == true
end

Callback.add(Callback.ON_STAGE_START, function()
    if Net.client then return end
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
