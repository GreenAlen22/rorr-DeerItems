-- DeerItems-ContagionBarb / «Жало заразы» / "Contagion Barb"
-- Шанс при попадании наложить кровотечение. При убийстве кровоточащего врага кровотечение
-- распространяется на ближайших врагов.
-- (Урон кровотечения ведём списком у игрока, как «солнца» ShineOSun: так он скейлится и
--  засчитывается игроку; сам бафф — лишь визуальная метка-дебафф.)

local sprite      = Resources.sprite_load("DeerItems", "item/ContagionBarb", PATH.."assets/sprites/items/sGreenItems/ContagionBarb.png", 1, 18, 18)
local buff_sprite = Resources.sprite_load("DeerItems", "buff/ContagionBleed", PATH.."assets/sprites/buffs/ContagionBarb.png", 1, 7.5, 7.5)

local GUID = _ENV["!guid"]

-- ── Баланс ──
local CHANCE_BASE  = 0.08
local CHANCE_STACK = 0.08
local BLEED_TIME   = 4 * 60     -- кровотечение 4с
local BLEED_TICK   = 30         -- урон раз в 0.5с
local BLEED_COEF   = 0.20       -- 20% урона за тик = 40%/с
local SPREAD_BASE  = 1          -- целей распространения при 1 шт.
local SPREAD_RAD   = 200

-- Дебафф-метка кровотечения (иконка; урон ведёт список у игрока)
local bleed = Buff.new("DeerItems", "ContagionBleed")
bleed.icon_sprite = buff_sprite
bleed.icon_stack_subimage = false
bleed.draw_stack_number = false
bleed.is_debuff = true
bleed.is_timed  = true
bleed:clear_callbacks()

local item = Item.new("DeerItems", "ContagionBarb")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

-- Завести/обновить кровотечение на цели
local function apply_bleed(actor, victim)
    if not (victim and Instance.exists(victim)) then return end
    if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return end
    victim:buff_apply(bleed, BLEED_TIME)
    local data = actor:get_data("ContagionBarb", GUID)
    if not data.bleeds then data.bleeds = {} end
    data.bleeds[victim.id] = { inst = victim, t = BLEED_TIME, tick = BLEED_TICK }
end

-- При попадании: шанс наложить кровотечение
item:onHitProc(function(actor, victim, stack, hit_info)
    if not gm._mod_net_isHost() then return end
    if math.random() <= (CHANCE_BASE + CHANCE_STACK * (stack - 1)) then
        apply_bleed(actor, victim)
    end
end)

-- Тик кровотечения от лица игрока (урон скейлится и засчитывается игроку)
item:onPostStep(function(actor, stack)
    if gm._mod_net_isClient() then return end
    local data = actor:get_data("ContagionBarb", GUID)
    if not data.bleeds then return end
    for id, b in pairs(data.bleeds) do
        b.t = b.t - 1
        b.tick = b.tick - 1
        local v = b.inst
        if not (v and Instance.exists(v)) or b.t <= 0 then
            data.bleeds[id] = nil
        elseif b.tick <= 0 then
            b.tick = BLEED_TICK
            -- proc=false: тик кровотечения не прокает предметы (в т.ч. себя)
            local hit = actor:fire_direct(v, BLEED_COEF)
            if hit and hit.attack_info then hit.attack_info.proc = false end
        end
    end
end)

-- При убийстве кровоточащего врага: распространяем кровотечение на ближайших
item:onKillProc(function(actor, victim, stack)
    if not gm._mod_net_isHost() then return end
    if not (victim and Instance.exists(victim)) then return end
    local data = actor:get_data("ContagionBarb", GUID)
    if not (data.bleeds and data.bleeds[victim.id]) then return end
    data.bleeds[victim.id] = nil

    local targets = SPREAD_BASE + (stack - 1)
    local enemy_team = actor.team == 1 and 2 or 1
    local found = List.wrap(actor:find_characters_circle(victim.x, victim.y, SPREAD_RAD + 32 * (stack - 1), false, enemy_team, true))
    local picked = 0
    for _, e in ipairs(found) do
        if picked >= targets then break end
        if Instance.exists(e) and e.id ~= victim.id then
            apply_bleed(actor, e)
            picked = picked + 1
        end
    end
end)
