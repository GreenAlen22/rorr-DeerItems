-- DeerItems-CascadeFailure / «Каскадный отказ» / "Cascade Failure"
-- Порт Networked Suffering из RoR2 (RoRR-вариант: копим урон, который наносим заражённым).
-- Заражает до 4 (+2 за стак) врагов. 50% урона, который вы наносите заражённым, копится в общий пул.
-- Каждые 3 сек все заражённые получают 100% накопленного урона.

-- Спрайт предмета (болванка из template), импакт-эффект из готового Explosive.png, звук детонации (его даёшь ты).
local sprite    = Resources.sprite_load("DeerItems", "item/CascadeFailure", PATH.."assets/sprites/items/sRedItems/CascadeFailure.png", 1, 18, 18)
local explosive = Resources.sprite_load("DeerItems", "particle/CascadeBurst", PATH.."assets/sprites/particle/voltOverloadHit.png", 6, 16, 16)
local mark      = Resources.sprite_load("DeerItems", "particle/CascadeFailureMark", PATH.."assets/sprites/particle/CascadeFailureMark.png", 1, 9.5, 8.5)
local sound     = Resources.sfx_load("DeerItems", "CascadeFailure/detonate", PATH.."assets/sounds/CascadeFailure.ogg")

local GUID = _ENV["!guid"]

-- Логику считает хост, а данные предмета у каждого игрока локальные. Передаём
-- клиентам состояние для отрисовки: заражённые цели, размер пула, эффект и звук
-- взрыва должны выглядеть одинаково у всех.
local packet_state = Packet.new()
local packet_release = Packet.new()

-- Настройки баланса
local CAP_BASE       = 4      -- максимум заражённых при 1 стаке
local CAP_STACK      = 2      -- +2 заражённых за стак
local CAPTURE_FRAC   = 0.5    -- 50% наносимого заражённым урона уходит в пул
local RELEASE_PERIOD = 180    -- детонация каждые 3 сек
local POOL_CAP_COEF  = 25     -- кап детонации: не больше 2500% урона игрока на одну цель (анти-runaway)
local POOL_TEXT_COLOR = Color(0x6a2cff)

-- Метка заражения: постоянная (is_timed=false), служит только индикатором — статов не меняет.
-- Внешний вид заражённых рисуем сами встроенной графикой (см. onPostDraw), иконку не показываем.
local function round_pool(pool)
    return math.floor((pool or 0) + 0.5)
end

local infectBuff = Buff.new("DeerItems", "CascadeInfect")
infectBuff.show_icon = false
infectBuff.is_debuff = true
infectBuff.max_stack = 1
infectBuff.is_timed  = false
infectBuff:clear_callbacks()

local function is_infected_actor(actor)
    return actor
        and Instance.exists(actor)
        and actor.buff_stack ~= nil
        and actor:buff_stack_count(infectBuff) > 0
end

local function sync_visual_state(actor, data)
    if not Net.is_host() then return end

    local infected = {}
    for vid, victim in pairs(data.infected or {}) do
        if is_infected_actor(victim) then
            infected[#infected + 1] = victim
        else
            data.infected[vid] = nil
        end
    end

    data.cf_synced_count = #infected
    local message = packet_state:message_begin()
    message:write_instance(actor)
    message:write_float(data.pool or 0)
    message:write_ushort(#infected)
    for _, victim in ipairs(infected) do
        message:write_instance(victim)
    end
    message:send_to_all()
end

packet_state:onReceived(function(message)
    if not gm._mod_net_isClient() then return end

    local actor = message:read_instance()
    local pool = message:read_float()
    local count = message:read_ushort()
    local victims = {}
    for i = 1, count do
        victims[i] = message:read_instance()
    end
    if not Instance.exists(actor) then return end

    local data = actor:get_data("CascadeFailure", GUID)
    data.infected = {}
    data.pool = pool
    for _, victim in ipairs(victims) do
        if Instance.exists(victim) then
            data.infected[victim.id] = victim
        end
    end
end)

packet_release:onReceived(function(message)
    if not gm._mod_net_isClient() then return end

    local actor = message:read_instance()
    local pitch = message:read_float()
    local count = message:read_ushort()
    for _ = 1, count do
        local x = message:read_float()
        local y = message:read_float()
        local ef = gm.instance_create(x, y, gm.constants.oEfExplosion)
        ef.sprite_index = explosive
    end
    if Instance.exists(actor) then
        actor:sound_play(sound, 1.0, pitch)
    end
end)

local item = Item.new("DeerItems", "CascadeFailure")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

-- Чистим набор заражённых от мёртвых/исчезнувших, попутно считая живых.
local function prune_count(data)
    local cnt = 0
    for vid, v in pairs(data.infected) do
        if is_infected_actor(v) then
            cnt = cnt + 1
        else
            data.infected[vid] = nil
        end
    end
    return cnt
end

-- При попадании: заражаем (если есть слот) и копим 50% урона по заражённым. Всё на хосте.
item:onHitProc(function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    if not gm._mod_net_isHost() then return end
    if not (victim and Instance.exists(victim)) then return end
    if victim.buff_stack == nil then return end

    local data = actor:get_data("CascadeFailure", GUID)
    data.infected = data.infected or {}
    data.pool     = data.pool or 0

    local id    = victim.id
    local isInf = victim:buff_stack_count(infectBuff) > 0
    if not isInf then
        local cap = CAP_BASE + CAP_STACK * (stack - 1)
        if prune_count(data) < cap then
            victim:buff_apply(infectBuff, 1, 1)
            data.infected[id] = victim
            isInf = true
        end
    end

    if isInf then
        local d = hit_info and (hit_info.damage or 0) or 0
        if d > 0 then data.pool = data.pool + d * CAPTURE_FRAC end
    end

    sync_visual_state(actor, data)
end)

-- Каждые 3 сек выливаем весь пул во всех заражённых. Всё на хосте.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    if not gm._mod_net_isHost() then return end

    local data = actor:get_data("CascadeFailure", GUID)
    data.infected = data.infected or {}
    data.pool     = data.pool or 0

    if prune_count(data) ~= (data.cf_synced_count or 0) then
        sync_visual_state(actor, data)
    end

    data.cf_t = (data.cf_t or 0) + 1
    if data.cf_t < RELEASE_PERIOD then return end
    data.cf_t = 0
    if data.pool <= 0 then return end

    local base = actor.damage or 0
    if base <= 0 then return end

    -- Кап на один залп + перевод плоского пула в коэффициент fire_direct (×урон игрока).
    local capped = math.min(data.pool, base * POOL_CAP_COEF)
    local coef   = capped / base

    local fired = false
    local positions = {}
    for vid, v in pairs(data.infected) do
        if is_infected_actor(v) then
            -- proc=false/без крита ОБЯЗАТЕЛЬНО: иначе детонация снова попадёт в onHitProc и зациклится.
            local atk = actor:fire_direct(v, coef, nil, nil, nil, nil, false)
            if atk and atk.attack_info then
                atk.attack_info.proc = false
                atk.attack_info:set_critical(false)
            end
            gm.instance_create(v.x, v.y, gm.constants.oEfExplosion).sprite_index = explosive
            positions[#positions + 1] = { x = v.x, y = v.y }
            fired = true
        else
            data.infected[vid] = nil
        end
    end

    if fired then
        local sound_pitch = 0.9 + math.random() * 0.3
        actor:sound_play(sound, 1.0, sound_pitch)

        if Net.is_host() then
            local message = packet_release:message_begin()
            message:write_instance(actor)
            message:write_float(sound_pitch)
            message:write_ushort(#positions)
            for _, position in ipairs(positions) do
                message:write_float(position.x)
                message:write_float(position.y)
            end
            message:send_to_all()
        end
    end
    data.pool = 0
    sync_visual_state(actor, data)
end)

-- При полной потере предмета снимаем заражение с уцелевших врагов.
item:onRemove(function(actor, stack)
    if stack > 1 then return end
    local data = actor:get_data("CascadeFailure", GUID)
    if not data.infected then return end
    for vid, v in pairs(data.infected) do
        if is_infected_actor(v) then
            v:buff_remove(infectBuff, v:buff_stack_count(infectBuff))
        end
    end
    data.infected = {}
    data.pool = 0
    sync_visual_state(actor, data)
end)

-- Внешний вид заражённых: маркер над врагом встроенной отрисовкой (ассет не нужен).
item:onPostDraw(function(actor, stack)
    local data = actor:get_data("CascadeFailure", GUID)
    if not data.infected then return end
    local pool_text = string.format("%d", round_pool(data.pool))
    for vid, v in pairs(data.infected) do
        if Instance.exists(v) and (gm._mod_net_isClient() or is_infected_actor(v)) then
            gm.draw_sprite(mark, 0, v.x, v.y - 14)
            gm.draw_set_colour(POOL_TEXT_COLOR)
            gm.draw_text(v.x - (#pool_text * 3) - 9, v.y + 2, pool_text)
            gm.draw_set_colour(Color.WHITE)
        else
            data.infected[vid] = nil
        end
    end
end)
