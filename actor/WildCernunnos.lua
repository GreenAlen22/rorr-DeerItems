-- DeerItems-WildCernunnos
-- Босс телепорта: дикий Цернуннос на ванильном ИИ, вплотную бьёт когтями, издали бросается рывком.

local GUID = _ENV["!guid"]
local SPRITE_PATH = PATH.."assets/sprites/actor/sWildCernunnos/"

-- Тот же идентификатор, что у союзника: Sprite.new отдаст уже загруженную маску, а
-- если союзник ещё не загружен, создаст её сам. Тело у босса то же, копия файла не нужна.
local sprite_mask      = Sprite.new("actor/CernunnosMask", PATH.."assets/sprites/actor/sCernunnos/cernunnos.png", 1, 64, 128)
local sprite_palette   = Sprite.new("actor/WildCernunnosPalette", SPRITE_PATH.."palette.png", 1, 0, 0)
local sprite_spawn     = Sprite.new("actor/WildCernunnosSpawn", SPRITE_PATH.."spawn.png", 12, 64, 128)
local sprite_idle      = Sprite.new("actor/WildCernunnosIdle", SPRITE_PATH.."idle.png", 6, 64, 128)
local sprite_walk      = Sprite.new("actor/WildCernunnosWalk", SPRITE_PATH.."walk.png", 6, 64, 128)
local sprite_jump      = Sprite.new("actor/WildCernunnosJump", SPRITE_PATH.."jump.png", 1, 64, 128)
local sprite_jump_peak = Sprite.new("actor/WildCernunnosJumpPeak", SPRITE_PATH.."jumpPeak.png", 1, 64, 128)
local sprite_fall      = Sprite.new("actor/WildCernunnosFall", SPRITE_PATH.."fall.png", 1, 64, 128)
-- Лежащее тело шире 128: кадр 160, origin — тот же центр под ногами.
local sprite_death     = Sprite.new("actor/WildCernunnosDeath", SPRITE_PATH.."death.png", 9, 80, 128)
local sprite_shoot1    = Sprite.new("actor/WildCernunnosShoot1", SPRITE_PATH.."shoot1.png", 7, 64, 128)
-- Рога вперёд и вытянутый бег шире 128, как и лежащее тело.
local sprite_charge    = Sprite.new("actor/WildCernunnosCharge", SPRITE_PATH.."charge.png", 12, 80, 128)

-- Sprite.new скорость не берёт; 0.5 — как у союзника, ленты те же. Рывок туда же:
-- скорости в состояниях босса считаются от одной базы.
for _, s in ipairs({sprite_spawn, sprite_idle, sprite_walk, sprite_death, sprite_shoot1, sprite_charge}) do
    s:set_speed(0.5)
end

-- Без сгенерированных палитр элиты не перекрашивают босса.
gm.elite_generate_palettes(sprite_palette.value)

local snd_spawn = Sound.new("WildCernunnos/spawn", PATH.."assets/sounds/CernunnosSpawn.ogg")
local snd_hit   = Sound.new("WildCernunnos/hit", PATH.."assets/sounds/CernunnosHit.ogg")
local snd_death = Sound.new("WildCernunnos/death", PATH.."assets/sounds/CernunnosDeath.ogg")

local SPEED = 2.4
local CLAWS_RANGE = 120
local CLAWS_FRAME = 3
local CLAWS_W = 256
local CLAWS_H = 128
local CLAWS_CENTER_Y = -48

local CHARGE_RANGE = 520
local CHARGE_STEP = 7
local CHARGE_FRAMES = 45
local CHARGE_WINDUP_ANIM = 0.2
local CHARGE_RUN_FIRST = 5
local CHARGE_RUN_COUNT = 4
-- Кадров ленты за игровой кадр: бег привязан к шагу 7 px, а не к скорости атаки,
-- поэтому цикл ведётся по счётчику кадров бега, а не image_speed.
local CHARGE_RUN_ANIM = 0.25
local CHARGE_BRAKE_FIRST = 9
local CHARGE_BRAKE_ANIM = 0.2
local CHARGE_AHEAD = 40
local CHARGE_GROUND_PROBE_Y = 8
local CHARGE_HIT_Y = -48
local CHARGE_HIT_R = 48
local CHARGE_BLAST = 96
local CHARGE_KNOCK_FRAMES = 20
local CHARGE_KNOCK_FORCE = 6
-- Пол под ногами касается низа bbox; без отступа он читался бы стеной.
local CHARGE_WALL_FLOOR_GAP = 2

local PHASE_WINDUP = 0
local PHASE_RUN = 1
local PHASE_BRAKE = 2

-- -4 и INVALID отсекаются до Instance.exists: INVALID разворачивается в Lua-таблицу,
-- а -4 для exists опасен (knowledge/mechanics.md, «Агро»).
local function exists(inst)
    return inst ~= nil and inst ~= -4 and inst ~= Instance.INVALID and Instance.exists(inst)
end

-- Коэффициент держит навык, а не код состояния: правка цифры — в одном месте.
local function skill_damage(skill)
    local damage = tonumber(skill.damage)
    if not damage then log.error("WildCernunnos: skill "..tostring(skill.identifier).." has no damage") end
    return damage
end

local wild = Object.new("WildCernunnos", Object.Parent.BOSS_CLASSIC)
wild:set_sprite(sprite_idle)
wild:set_depth(11)

local claws = Skill.new("WildCernunnosClaws")
claws.cooldown = 90
claws.damage = 1.6

local state_claws = ActorState.new("WildCernunnosClaws")

local charge = Skill.new("WildCernunnosCharge")
charge.cooldown = 360
charge.damage = 2.5

local state_charge = ActorState.new("WildCernunnosCharge")

Callback.add(wild.on_create, function(actor)
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

    -- Урон, HP, порог стана, опыт — уровень боссов первого этапа (Colossus, Vagrant).
    actor:enemy_stats_init(20, 1400, 100, 50)
    actor.pHmax_base = SPEED
    actor.z_range = CLAWS_RANGE
    actor:set_default_skill(Skill.Slot.PRIMARY, claws)
    actor.x_range = CHARGE_RANGE
    actor:set_default_skill(Skill.Slot.SECONDARY, charge)

    actor:init_actor_late()
end)

-- activate_skill приходит на каждую машину, поэтому состояние идёт везде;
-- урон наносит только хост, иначе каждый клиент ударит ещё раз.
Callback.add(claws.on_activate, function(actor, skill, slot)
    actor:set_state(state_claws)
end)

Callback.add(state_claws.on_enter, function(actor, data)
    actor.image_index = 0
    data.struck = false
end)

Callback.add(state_claws.on_step, function(actor, data)
    actor:skill_util_fix_hspeed()
    -- attack_speed умножает сам actor_animation_set (scale_animspeed по умолчанию true).
    actor:actor_animation_set(sprite_shoot1, 0.22)

    -- Util.bool: в структуре состояния булево может вернуться числом, а 0 в Lua истинно.
    if not Util.bool(data.struck) and actor.image_index >= CLAWS_FRAME then
        data.struck = true
        -- Звук каждая машина играет себе: пакета ждать незачем.
        actor:sound_play(snd_hit, 1.0, 1.0)
        if Net.host then
            actor:fire_explosion(actor.x, actor.y + CLAWS_CENTER_Y, CLAWS_W, CLAWS_H, skill_damage(claws))
        end
    end

    actor:skill_util_exit_state_on_anim_end()
end)

-- Флаг остановки по пакету живёт в данных инстанса: структуру состояния
-- десериализатор не видит.
local function charge_data(actor)
    return Instance.get_data(actor, "WildCernunnosCharge", GUID)
end

-- collision_* отдают инстанс или noone (-4); инстанс — не число, -4 может прийти
-- не Lua-числом, отсюда tonumber.
local function found_block(result)
    return result ~= nil and tonumber(result) ~= -4
end

local function wall_ahead(actor, side)
    local step = side * CHARGE_STEP
    return found_block(gm.collision_rectangle(
        tonumber(actor.bbox_left) + step, tonumber(actor.bbox_top),
        tonumber(actor.bbox_right) + step, tonumber(actor.bbox_bottom) - CHARGE_WALL_FLOOR_GAP,
        gm.constants.pBlock, false, true))
end

local function ground_ahead(actor, side)
    return found_block(gm.collision_point(
        tonumber(actor.x) + side * CHARGE_AHEAD, tonumber(actor.y) + CHARGE_GROUND_PROBE_Y,
        gm.constants.pBlock, false, true))
end

local function charge_brake(actor, data)
    data.phase = PHASE_BRAKE
    actor.image_index = CHARGE_BRAKE_FIRST
end

local packet_charge_stop = Packet.new("WildCernunnos-charge_stop")
packet_charge_stop:set_serializers(function(buffer, actor, x)
    buffer:write_instance(actor)
    buffer:write_float(x)
end, function(buffer)
    local actor = buffer:read_instance()
    local x = buffer:read_float()
    if not Net.client then return end
    if not exists(actor) then return end

    -- Позиция хоста при ударе: клиент мог убежать дальше, пока шёл пакет.
    actor.x = x
    charge_data(actor).stop = true
    actor:sound_play(snd_hit, 1.0, 1.0)
end)

-- Хост: первый враг перед рогами получает один удар, и рывок кончается.
local function charge_try_hit(actor, data, side)
    local enemy_team = tonumber(actor.team) == 1 and 2 or 1
    local hit_x = tonumber(actor.x) + side * CHARGE_AHEAD
    local hit_y = tonumber(actor.y) + CHARGE_HIT_Y
    local found = List.wrap(actor:find_characters_circle(hit_x, hit_y, CHARGE_HIT_R, false, enemy_team, true))

    for _, victim in ipairs(found) do
        if exists(victim) then
            local attack = actor:fire_explosion(hit_x, hit_y, CHARGE_BLAST, CHARGE_BLAST, skill_damage(charge))
            -- Игроков отбрасывание может и не сдвинуть (порог стана 1e+25): тогда только урон.
            attack.attack_info:set_knockback(side, CHARGE_KNOCK_FRAMES, CHARGE_KNOCK_FORCE)
            actor:sound_play(snd_hit, 1.0, 1.0)
            charge_brake(actor, data)
            packet_charge_stop:send_to_all(actor, actor.x)
            return
        end
    end
end

local function charge_run(actor, data)
    local frames = tonumber(data.run_frames)
    local side = tonumber(data.side)

    -- image_speed 0: кадр бега ставится по счётчику, иначе движок дошёл бы до торможения сам.
    actor:actor_animation_set(sprite_charge, 0)
    actor.image_index = CHARGE_RUN_FIRST + math.floor(frames * CHARGE_RUN_ANIM) % CHARGE_RUN_COUNT

    -- Стену, обрыв и время каждая машина видит одинаково: пакет нужен только удару.
    if frames >= CHARGE_FRAMES or wall_ahead(actor, side) or not ground_ahead(actor, side) then
        charge_brake(actor, data)
        return
    end

    actor.x = tonumber(actor.x) + side * CHARGE_STEP
    data.run_frames = frames + 1

    if Net.host then
        charge_try_hit(actor, data, side)
    end
end

-- Состояние, как у когтей, идёт на каждой машине; движение тоже, как у Bison.
Callback.add(charge.on_activate, function(actor, skill, slot)
    actor:set_state(state_charge)
end)

Callback.add(state_charge.on_enter, function(actor, data)
    actor.image_index = 0
    data.phase = PHASE_WINDUP
    data.run_frames = 0
    data.side = tonumber(actor.image_xscale) < 0 and -1 or 1
    charge_data(actor).stop = false
    actor:sound_play(snd_hit, 1.0, 1.0)
end)

Callback.add(state_charge.on_step, function(actor, data)
    -- Без гашения pHspeed движок добавил бы к шагу рывка свой ход.
    actor:skill_util_fix_hspeed()

    if tonumber(data.phase) ~= PHASE_BRAKE and charge_data(actor).stop then
        charge_brake(actor, data)
    end

    if tonumber(data.phase) == PHASE_WINDUP then
        actor:actor_animation_set(sprite_charge, CHARGE_WINDUP_ANIM)
        if tonumber(actor.image_index) >= CHARGE_RUN_FIRST then
            data.phase = PHASE_RUN
        end
    end

    if tonumber(data.phase) == PHASE_RUN then
        charge_run(actor, data)
    end

    if tonumber(data.phase) == PHASE_BRAKE then
        actor:actor_animation_set(sprite_charge, CHARGE_BRAKE_ANIM)
        actor:skill_util_exit_state_on_anim_end()
    end
end)

local card = MonsterCard.new("WildCernunnos")
card.object_id = wild.value
card.spawn_type = 0
card.spawn_cost = 800
card.is_boss = true
card.can_be_blighted = false

for _, id in ipairs({ "desolateForest", "skyMeadow" }) do
    local stage = Stage.find(id, "ror")
    -- Без этапа босс молча пропал бы из игры: log.error бросает и останавливает загрузку файла.
    if not stage then log.error("DeerItems: stage ror-"..id.." not found, WildCernunnos card not added") end
    stage:add_monster(card)
end

DeerItemsWildCernunnos = {
    object = wild,
    card = card,
}
