-- DeerItems-Bramble
-- Тернистый elite: урон из-за пределов зоны в 4 м уменьшается вдвое.

local METERS_TO_PIXELS = 32
local RADIUS = 4 * METERS_TO_PIXELS
local BOSS_RADIUS_MULTIPLIER = 3
local DAMAGE_MULTIPLIER = 0.5
local SLOW_DURATION = 60
local SLOW_MULTIPLIER = 0.75
local BRAMBLE_COLOR = Color(0x0e2a15)
local VINE_SEGMENTS = 28
local VINE_THORN_LENGTH = 12

local palette = Resources.sprite_load(
    "DeerItems",
    "elite/BramblePalette",
    PATH.."assets/sprites/elites/sBramble/PaletteBramble.png",
    1,
    0,
    0
)
local icon = Resources.sprite_load(
    "DeerItems",
    "elite/BrambleIcon",
    PATH.."assets/sprites/elites/sBramble/IconBramble.png",
    1,
    10,
    11
)

local bramble = Elite.new("DeerItems", "Bramble")
bramble:set_palette(palette, BRAMBLE_COLOR)
bramble:set_healthbar_icon(icon)
gm.elite_generate_palettes()

local slow = Buff.new("DeerItems", "BrambleSlow")
slow.show_icon = false
slow.icon_stack_subimage = false
slow.max_stack = 1
slow.is_debuff = true

local function draw_slow_tint(actor)
    gm.draw_sprite_ext(
        actor.sprite_index,
        actor.image_index,
        actor.x,
        actor.y,
        actor.image_xscale,
        actor.image_yscale,
        actor.image_angle,
        BRAMBLE_COLOR,
        0.8
    )

    if actor.actor_state_current_id ~= -1
    and not actor:actor_state_is_climb_state(actor.actor_state_current_id)
    and actor.sprite_index2 then
        gm.draw_sprite_ext(
            actor.sprite_index2,
            actor.image_index,
            actor.x,
            actor.y,
            actor.image_xscale,
            actor.image_yscale,
            actor.image_angle,
            BRAMBLE_COLOR,
            0.8
        )
    end
end

slow:onPostDraw(function(actor)
    draw_slow_tint(actor)
end)

slow:onStatRecalc(function(actor)
    actor.pHmax = actor.pHmax * SLOW_MULTIPLIER
end)

local function exists(inst)
    return inst and Instance.exists(inst)
end

local function is_bramble(inst)
    return exists(inst) and inst.elite_type == bramble.value
end

local function truthy(value)
    return value ~= nil and value ~= false and value ~= 0
end

local function radius_for(actor)
    if GM.actor_is_boss and truthy(GM.actor_is_boss(actor)) then
        return RADIUS * BOSS_RADIUS_MULTIPLIER
    end
    return RADIUS
end

local function is_player(inst)
    return exists(inst) and inst.object_index == gm.constants.oP
end

local function draw_zone(actor)
    local radius = radius_for(actor)
    local phase = (Global._current_frame or 0) / 90

    gm.draw_set_colour(BRAMBLE_COLOR)
    gm.draw_set_alpha(0.8)
    for i = 0, VINE_SEGMENTS - 1 do
        local a0 = math.pi * 2 * i / VINE_SEGMENTS
        local a1 = math.pi * 2 * (i + 0.5) / VINE_SEGMENTS
        local a2 = math.pi * 2 * (i + 1) / VINE_SEGMENTS
        local wobble = math.sin(i * 2.1 + phase) * 5
        local r0 = radius + math.sin(i * 1.3 + phase) * 3
        local r2 = radius + math.sin((i + 1) * 1.3 + phase) * 3
        local rm = radius + wobble
        local x0 = actor.x + math.cos(a0) * r0
        local y0 = actor.y + math.sin(a0) * r0
        local xm = actor.x + math.cos(a1) * rm
        local ym = actor.y + math.sin(a1) * rm
        local x2 = actor.x + math.cos(a2) * r2
        local y2 = actor.y + math.sin(a2) * r2

        gm.draw_line(x0, y0, xm, ym)
        gm.draw_line(xm, ym, x2, y2)

        if i % 2 == 0 then
            local thorn_base_radius = rm - 3
            local thorn_tip_radius = rm + VINE_THORN_LENGTH
            local bx = actor.x + math.cos(a1) * thorn_base_radius
            local by = actor.y + math.sin(a1) * thorn_base_radius
            local tx = actor.x + math.cos(a1) * thorn_tip_radius
            local ty = actor.y + math.sin(a1) * thorn_tip_radius
            gm.draw_line(bx, by, tx, ty)
        end
    end
    gm.draw_set_alpha(1)
    gm.draw_set_colour(Color.WHITE)
end

-- MonsterCard доступен после инициализации ванильного контента. Этот callback
-- вызывается перед заполнением директором массивов спавна и безопасен для правки карт.
Callback.add(Callback.TYPE.onDirectorPopulateSpawnArrays, "DeerItems-Bramble-availability", function()
    for _, card in ipairs(MonsterCard.find_all()) do
        local elite_list = List.wrap(card.elite_list)
        if not elite_list:contains(bramble) then
            elite_list:add(bramble)
        end
    end
end)

-- Расчёт выполняется до снятия HP. args[6] — актёр, создавший урон: именно его
-- позиция определяет, находится ли игрок в зоне, а не позиция попавшего снаряда.
pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        if not gm._mod_net_isHost() then return end

        local raw_victim = args[2] and args[2].value
        if not raw_victim then return end
        local victim = Instance.wrap(raw_victim)
        if not is_bramble(victim) then return end

        local damage = args[4] and args[4].value
        if not damage or damage <= 0 then return end

        local raw_attacker = args[6] and args[6].value
        local attacker = raw_attacker and Instance.wrap(raw_attacker) or nil
        if not exists(attacker) then return end

        local dx = attacker.x - victim.x
        local dy = attacker.y - victim.y
        local radius = radius_for(victim)
        if dx * dx + dy * dy <= radius * radius then return end

        args[4].value = damage * DAMAGE_MULTIPLIER

        if is_player(attacker) then
            attacker:buff_apply(slow, SLOW_DURATION, 1)
        end
    end)
end)

Callback.add(Callback.TYPE.onDraw, "DeerItems-Bramble-zone", function()
    for _, actor in ipairs(Instance.find_all(gm.constants.pActor)) do
        if is_bramble(actor) then draw_zone(actor) end
    end
end)
