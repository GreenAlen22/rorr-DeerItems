-- DeerItems-IngrownIdol
-- Kills feed the idol. At the threshold it summons or refreshes one team Cernunnos.

local sprite = Resources.sprite_load("DeerItems", "item/IngrownIdol", PATH.."assets/sprites/items/sRedItems/IngrownIdol.png", 1, 16, 16)
local indicatorSprite = Resources.sprite_load("DeerItems", "particle/IngrownIdolIndicator", PATH.."assets/sprites/particle/IngrownIdolIndicator.png", 15, 0, 0)

local GUID = _ENV["!guid"]

local THRESHOLD = 30
local OFFERINGS_PER_FRAME = 2
local INDICATOR_MAX_FRAME = 14
local LATE_MINUTE = 20
local HUD_SKILLBAR_DX = 224
local HUD_Y = 56

local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

local function actor_exists(actor)
    return actor and Instance.exists(actor)
end

local function beast_alive(beast)
    return actor_exists(beast) and (beast.hp == nil or beast.hp > 0)
end

local function is_boss(victim)
    return actor_exists(victim) and GM.actor_is_boss and truthy(GM.actor_is_boss(victim))
end

local function is_elite(victim)
    return actor_exists(victim) and GM.actor_is_elite and truthy(GM.actor_is_elite(victim))
end

local function run_minute()
    local ok, dir = pcall(gm._mod_game_getDirector)
    if ok and dir and type(dir.minute_current) == "number" then
        return dir.minute_current
    end
    return 0
end

local function offering_for(victim)
    local late = run_minute() >= LATE_MINUTE
    if is_boss(victim) then return late and 2 or 3 end
    if is_elite(victim) then return late and 1 or 2 end
    return late and 0.5 or 1
end

local item = Item.new("DeerItems", "IngrownIdol")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_damage)
item:clear_callbacks()

local function total_team_stacks(team)
    local total = 0
    for _, player in ipairs(Instance.find_all(gm.constants.oP)) do
        if actor_exists(player) and player.team == team then
            total = total + (player:item_stack_count(item, Item.STACK_KIND.any) or 0)
        end
    end
    return math.max(1, total)
end

item:onKillProc(function(actor, victim, stack)
    local data = actor:get_data("IngrownIdol", GUID)
    data.fed = (data.fed or 0) + offering_for(victim)
end)

item:onPostStep(function(actor, stack)
    if stack <= 0 then return end

    local data = actor:get_data("IngrownIdol", GUID)
    if (data.fed or 0) < THRESHOLD then return end
    data.fed = data.fed - THRESHOLD

    if gm._mod_net_isClient() then return end
    if not DeerItemsCernunnos or not DeerItemsCernunnos.spawn then
        error("IngrownIdol requires actor/Cernunnos.lua to be loaded before items")
    end

    data.beast = DeerItemsCernunnos.spawn(actor, total_team_stacks(actor.team))
end)

item:onRemove(function(actor, stack)
    if stack <= 1 then
        local data = actor:get_data("IngrownIdol", GUID)
        data.fed = 0
    end
end)

item:onStageStart(function(actor, stack)
    actor:get_data("IngrownIdol", GUID).beast = nil
end)

local g_bar = { x = 0, frame = -1 }
pcall(function()
    if not gm.constants.hud_draw_skills then return end
    gm.pre_script_hook(gm.constants.hud_draw_skills, function(self, other, result, args)
        local ok, x = pcall(function() return args[2].value end)
        if ok and type(x) == "number" then
            g_bar.x = x
            g_bar.frame = Global._current_frame or 0
        end
    end)
end)

gm.post_script_hook(gm.constants.draw_hud, function()
    if g_bar.frame ~= (Global._current_frame or 0) then return end

    local player = Player.get_client()
    if not actor_exists(player) then return end
    if (player:item_stack_count(item, Item.STACK_KIND.any) or 0) <= 0 then return end

    local data = player:get_data("IngrownIdol", GUID)
    local fed = data.fed or 0
    local beast = data.beast
    if DeerItemsCernunnos and DeerItemsCernunnos.get_for_team then
        beast = DeerItemsCernunnos.get_for_team(player.team) or beast
    end
    local frame = beast_alive(beast) and INDICATOR_MAX_FRAME
        or math.min(INDICATOR_MAX_FRAME, math.floor(fed / OFFERINGS_PER_FRAME))
    gm.draw_sprite(indicatorSprite, frame, g_bar.x + HUD_SKILLBAR_DX, HUD_Y)
end)
