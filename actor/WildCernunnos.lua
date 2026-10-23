-- DeerItems-WildCernunnos
-- Босс телепорта: дикий Цернуннос на ванильном ИИ, вплотную бьёт когтями.

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

-- Sprite.new скорость не берёт; 0.5 — как у союзника, ленты те же.
for _, s in ipairs({sprite_spawn, sprite_idle, sprite_walk, sprite_death, sprite_shoot1}) do
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
