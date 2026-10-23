-- DeerItems-GroundSpikes
-- Двухэтапные шипы из земли: телеграф, вертикальный удар, горизонтальный удар; вид задаёт спрайт, звук и урон.

local M = {}

local TELEGRAPH_FRAMES = 30
local VERTICAL_FRAMES = 10
local HORIZONTAL_FRAMES = 5
local ATTACK_ANIMATION_SPEED = 0.8 -- 25% slower visual frames; gameplay timing remains unchanged.
local LAST_FRAME_HOLD = 30
local STRIKE_ANIMATION_DURATION = math.ceil((VERTICAL_FRAMES + HORIZONTAL_FRAMES) / ATTACK_ANIMATION_SPEED)
local SPIKE_VISUAL_LIFETIME = TELEGRAPH_FRAMES + STRIKE_ANIMATION_DURATION + LAST_FRAME_HOLD
local VERTICAL_WIDTH = 24
local VERTICAL_HEIGHT = 96
local HORIZONTAL_WIDTH = 96
local HORIZONTAL_HEIGHT = 24

-- Метка на attack_info: ключ с префиксом неймспейса, чужие моды пишут в тот же struct.
-- По сети она не едет, поэтому читается только у хоста, где удар и создан.
local ATTACK_TAG = "DeerItems_spike"

local kinds = {}
local spikes = {}

local function exists(inst)
    return inst and Instance.exists(inst)
end

local function add_spike(kind, x, y, owner)
    spikes[#spikes + 1] = { kind = kind, x = x, y = y, owner = owner, age = 0 }
end

local Kind = {}
Kind.__index = Kind

-- Вызывать у хоста: клиенты получают шип пакетом и сами ничего не создают.
function Kind:spawn(owner, x, y)
    if not Net.host then return end

    add_spike(self, x, y, owner)
    self.packet:send_to_all(owner, x, y)
end

-- opts.can_fire(owner) обязан сам обрабатывать мёртвого или уничтоженного владельца: шип его пережить может.
function M.kind(id, opts)
    if kinds[id] then error("DeerItemsGroundSpikes: kind '"..tostring(id).."' already registered") end
    assert(opts and opts.sprite and opts.sound and opts.damage and opts.can_fire,
        "DeerItemsGroundSpikes: sprite, sound, damage and can_fire are required")

    local kind = setmetatable({
        id = id,
        sprite = opts.sprite,
        sound = opts.sound,
        damage = opts.damage,
        can_fire = opts.can_fire,
        on_hit = opts.on_hit,
        packet = Packet.new("GroundSpikes-"..id),
    }, Kind)

    kind.packet:set_serializers(function(buffer, owner, x, y)
        buffer:write_instance(owner)
        buffer:write_float(x)
        buffer:write_float(y)
    end, function(buffer)
        local owner = buffer:read_instance()
        local x = buffer:read_float()
        local y = buffer:read_float()
        if not Net.client then return end
        add_spike(kind, x, y, owner)
    end)

    kinds[id] = kind
    return kind
end

local function fire_spike_attack(spike, width, height)
    local kind = spike.kind
    local owner = spike.owner
    if not kind.can_fire(owner) then return end

    local attack = owner:fire_explosion(spike.x, spike.y, width, height, kind.damage, nil, nil, false)
    if attack and attack.attack_info then
        attack.attack_info.proc = false
        attack.attack_info:set_critical(false)
        attack.attack_info[ATTACK_TAG] = kind.id
    end
end

local function play_spike_emerge_sound(spike)
    if exists(spike.owner) then
        spike.owner:sound_play(spike.kind.sound, 0.9, 1.0)
    end
end

Callback.add(Callback.ON_ATTACK_HIT, function(hit_info)
    if not Net.host then return end

    local attack_info = hit_info.attack_info
    if not attack_info then return end

    local kind = kinds[attack_info[ATTACK_TAG]]
    if kind and kind.on_hit then kind.on_hit(hit_info) end
end)

Callback.add(Callback.POST_STEP, function()
    for index = #spikes, 1, -1 do
        local spike = spikes[index]
        spike.age = spike.age + 1

        if Net.host then
            if spike.age == TELEGRAPH_FRAMES then
                fire_spike_attack(spike, VERTICAL_WIDTH, VERTICAL_HEIGHT)
            elseif spike.age == TELEGRAPH_FRAMES + VERTICAL_FRAMES then
                fire_spike_attack(spike, HORIZONTAL_WIDTH, HORIZONTAL_HEIGHT)
            end
        end

        if spike.age == TELEGRAPH_FRAMES then play_spike_emerge_sound(spike) end

        if spike.age >= SPIKE_VISUAL_LIFETIME then
            table.remove(spikes, index)
        end
    end
end)

Callback.add(Callback.ON_DRAW, function()
    for _, spike in ipairs(spikes) do
        local frame
        if spike.age < TELEGRAPH_FRAMES then
            frame = math.min(3, math.floor(spike.age * 4 / TELEGRAPH_FRAMES))
        else
            local strike_age = spike.age - TELEGRAPH_FRAMES
            frame = 4 + math.min(14, math.floor(strike_age * ATTACK_ANIMATION_SPEED))
        end
        gm.draw_sprite(spike.kind.sprite.value, math.min(18, frame), spike.x, spike.y)
    end
end)

DeerItemsGroundSpikes = M
return M
