-- DeerItems-WildCernunnos
-- Босс телепорта: дикий Цернуннос на ванильном ИИ, вплотную бьёт когтями, издали бросается рывком, рёвом поднимает корни под игроками.

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
local sprite_roar      = Sprite.new("actor/WildCernunnosRoar", SPRITE_PATH.."roar.png", 10, 64, 128)
-- Кадр корней хелпер шипов выбирает сам по возрасту шипа: скорость ленты ему не нужна.
local sprite_roots     = Sprite.new("actor/WildCernunnosRoots", SPRITE_PATH.."roots.png", 19, 32, 64)
-- Заглушка портрета журнала: кадр 0 idle ×2 на тёмном фоне, пока нет иллюстрации (A12).
local sprite_portrait  = Sprite.new("actor/WildCernunnosPortrait", SPRITE_PATH.."portrait.png", 1, 0, 0)

-- Sprite.new скорость не берёт; 0.5 — как у союзника, ленты те же. Рывок и рёв туда же:
-- скорости в состояниях босса считаются от одной базы.
for _, s in ipairs({sprite_spawn, sprite_idle, sprite_walk, sprite_death, sprite_shoot1, sprite_charge, sprite_roar}) do
    s:set_speed(0.5)
end

-- Без сгенерированных палитр элиты не перекрашивают босса.
gm.elite_generate_palettes(sprite_palette.value)

local snd_spawn = Sound.new("WildCernunnos/spawn", PATH.."assets/sounds/CernunnosSpawn.ogg")
local snd_hit   = Sound.new("WildCernunnos/hit", PATH.."assets/sounds/CernunnosHit.ogg")
local snd_death = Sound.new("WildCernunnos/death", PATH.."assets/sounds/CernunnosDeath.ogg")
-- Рёв союзника, пока у босса нет своего.
local snd_roar  = Sound.new("WildCernunnos/roar", PATH.."assets/sounds/IngrownIdol.ogg")

-- Тот же замедлитель, что даёт Taser: минус скорость, без своего баффа.
local snare = Buff.find("snare", "ror")
-- log.error бросает: без баффа корни молча били бы без замедления.
if not snare then log.error("DeerItems: buff ror-snare not found, WildCernunnos roots would not snare") end

-- Статы общие у тела и журнала: журнал показывает их сам, с актором не сверяет.
local DAMAGE = 20
local HP = 1400
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

local ROAR_RANGE = 900
local ROAR_FRAME = 4
local ROAR_ANIM = 0.2
local ROAR_SHAKE = 4
local ROOTS_DAMAGE = 1.2
local SNARE_FRAMES = 90

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

-- 1 = книга босса: sBookDropBoss игра выбирает по log_backdrop_index один раз, при
-- создании записи, и вешает на объект книги; поздняя смена индекса книгу не меняет.
local BOSS_BACKDROP = 1

-- Игра дописывает запись в конец списка журнала. Если до нас чей-то мод дописал туда
-- обычных врагов, босс встал бы за ними, отдельно от раздела боссов: ставим его сразу
-- за последним боссом.
local function place_in_boss_section(log_id)
    local order = List.wrap(gm.variable_global_get("monster_log_display_list"))
    local own = order:find(log_id)
    if not own then log.error("WildCernunnos: monster log "..tostring(log_id).." is not in monster_log_display_list") end
    order:delete(own)

    local after = nil
    for i, id in ipairs(order) do
        if tonumber(MonsterLog.wrap(id).log_backdrop_index) == BOSS_BACKDROP then after = i end
    end
    -- i из ipairs считается с 1, insert — с 0: индекс i и есть место сразу за записью.
    order:insert(after or order:size(), log_id)
end

-- Повторная загрузка мода находит запись, созданную в первый раз: иначе журнал получил бы дубль.
local mlog = MonsterLog.find("WildCernunnos", "DeerItems")
if not mlog then
    local count_before = gm.variable_global_get("count_monster_log")
    -- log_id = nil: номер выдаёт игра (count_monster_log++). Портрет обязателен: без него
    -- игра по ошибке затирает sprite_id портретом по умолчанию, а не portrait_id.
    local log_id = gm.monster_log_create("DeerItems", "WildCernunnos", nil,
        sprite_idle.value, sprite_portrait.value, 0, HP, DAMAGE, SPEED, BOSS_BACKDROP, wild.value)
    -- Если nil не стал undefined, игра не выдала номер, а запись легла в чужой слот.
    if type(log_id) ~= "number" or log_id ~= count_before
        or gm.variable_global_get("count_monster_log") ~= count_before + 1 then
        log.error("WildCernunnos: monster_log_create did not allocate an id (got "..tostring(log_id)
            ..", count_monster_log was "..tostring(count_before).."); fallback: pass count_monster_log as log_id and increment it")
    end
    mlog = MonsterLog.wrap(log_id)
    place_in_boss_section(log_id)
    -- зонд: убрать после прогона
    log.info("WildCernunnos monster log: id="..tostring(log_id)
        ..", log_backdrop_index="..tostring(mlog.log_backdrop_index)
        ..", object_id="..tostring(mlog.object_id))
end

local claws = Skill.new("WildCernunnosClaws")
claws.cooldown = 90
claws.damage = 1.6

local state_claws = ActorState.new("WildCernunnosClaws")

local charge = Skill.new("WildCernunnosCharge")
charge.cooldown = 360
charge.damage = 2.5

local state_charge = ActorState.new("WildCernunnosCharge")

local roar = Skill.new("WildCernunnosRoar")
roar.cooldown = 600

local state_roar = ActorState.new("WildCernunnosRoar")

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
    -- Книгу журнала роняет смерть актора, пока запись не открыта (scr_actor_death).
    actor.monster_log_drop_id = mlog.value

    -- Урон, HP, порог стана, опыт — уровень боссов первого этапа (Colossus, Vagrant).
    actor:enemy_stats_init(DAMAGE, HP, 100, 50)
    actor.pHmax_base = SPEED
    actor.z_range = CLAWS_RANGE
    actor:set_default_skill(Skill.Slot.PRIMARY, claws)
    actor.x_range = CHARGE_RANGE
    actor:set_default_skill(Skill.Slot.SECONDARY, charge)
    actor.c_range = ROAR_RANGE
    actor:set_default_skill(Skill.Slot.UTILITY, roar)

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

-- Проверка Rusted; object_index — не Lua-число (knowledge/objects.md), отсюда tonumber.
local function is_player(actor)
    return exists(actor) and tonumber(actor.object_index) == gm.constants.oP
end

-- Мёртвый игрок остаётся инстансом oP: мёртвым его помечает поле dead (actor_set_dead).
local function player_alive(player)
    return not Util.bool(player.dead) and tonumber(player.hp) > 0
end

local roots = DeerItemsGroundSpikes.kind("WildCernunnosRoots", {
    sprite = sprite_roots,
    sound = snd_hit,
    damage = ROOTS_DAMAGE,
    -- Корни переживают босса: убитый или исчезнувший больше не бьёт.
    -- object_index инстанса — объект-носитель, свой объект отдаёт get_object_index.
    can_fire = function(owner)
        return exists(owner) and owner:get_object_index() == wild.value and tonumber(owner.hp) > 0
    end,
    -- Хелпер зовёт on_hit на любую жертву удара корней, а замедление — только игрокам.
    on_hit = function(hit_info)
        local victim = hit_info.target
        if not is_player(victim) then return end
        -- У snare max_stack 1: на висящем баффе buff_apply стака не прибавит, но таймер
        -- поставит max(остаток, 90) и пакетом донесёт клиенту, то есть обновит, как Taser.
        -- Снимать перед наложением нельзя: у snare client_handles_removal, снятие не синхронно.
        victim:buff_apply(snare, SNARE_FRAMES)
    end,
})

-- Флаг рёва — в данных инстанса, как у рывка: булево в структуре состояния
-- может вернуться числом.
local function roar_data(actor)
    return Instance.get_data(actor, "WildCernunnosRoar", GUID)
end

-- Хост: корни под каждым живым игроком в радиусе, клиентам их донесёт пакет хелпера.
local function roar_spawn_roots(actor)
    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        if player_alive(player)
            and gm.point_distance(actor.x, actor.y, player.x, player.y) <= ROAR_RANGE then
            roots:spawn(actor, player.x, player.bbox_bottom)
        end
    end
end

Callback.add(roar.on_activate, function(actor, skill, slot)
    actor:set_state(state_roar)
end)

Callback.add(state_roar.on_enter, function(actor, data)
    actor.image_index = 0
    roar_data(actor).fired = false
end)

Callback.add(state_roar.on_step, function(actor, data)
    actor:skill_util_fix_hspeed()
    actor:actor_animation_set(sprite_roar, ROAR_ANIM)

    local roar_state = roar_data(actor)
    if not roar_state.fired and tonumber(actor.image_index) >= ROAR_FRAME then
        roar_state.fired = true
        -- Звук и тряска локальны, каждая машина делает их себе.
        actor:sound_play(snd_roar, 1.0, 1.0)
        actor:screen_shake(ROAR_SHAKE)
        -- kind:spawn и сам откажет клиенту; проверка здесь — чтобы роль была видна.
        if Net.host then
            roar_spawn_roots(actor)
        end
    end

    actor:skill_util_exit_state_on_anim_end()
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
