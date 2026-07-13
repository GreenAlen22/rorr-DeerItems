-- DeerItems-IngrownIdol
-- Kills feed the idol. At the threshold it summons or refreshes one team Cernunnos.

local sprite = Resources.sprite_load("DeerItems", "item/IngrownIdol", PATH.."assets/sprites/items/sRedItems/IngrownIdol.png", 1, 16, 16)
local barSprite = Resources.sprite_load("DeerItems", "particle/IngrownIdolCustomBar", PATH.."assets/sprites/particle/TwistedOpinionCustomBar.png", 1, 0, 0)

local GUID = _ENV["!guid"]

local THRESHOLD = 30
local LATE_MINUTE = 20
local HUD_ENABLED = false

local HUD_FILL_X = 4
local HUD_FILL_Y = 8
local HUD_FILL_W = 50
local HUD_FILL_H = 6
local HUD_FRAME_W = 58
local HUD_X = 314
local HUD_Y = 36
local HUD_SKILLBAR_DX = 244
local HUD_FILL_BG = Color(0x1b1020)
local HUD_FILL_FG = Color(0xff5533)
local HUD_FILL_LIVE = Color(0x55ff66)

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

local g_bar = { x = 0, y = 0, frame = -1 }
pcall(function()
    if not gm.constants.hud_draw_skills then return end
    gm.pre_script_hook(gm.constants.hud_draw_skills, function(self, other, result, args)
        local okx, bx = pcall(function() return args[2].value end)
        local oky, by = pcall(function() return args[3].value end)
        if okx and oky and type(bx) == "number" and type(by) == "number" then
            g_bar.x, g_bar.y, g_bar.frame = bx, by, (Global._current_frame or 0)
        end
    end)
end)

local function hud_position()
    if g_bar.frame == (Global._current_frame or 0) then
        return g_bar.x + HUD_SKILLBAR_DX, HUD_Y
    end
    return HUD_X, HUD_Y
end

gm.post_script_hook(gm.constants.draw_hud, function()
    if not HUD_ENABLED then return end

    local player = Player.get_client()
    if not actor_exists(player) then return end
    if (player:item_stack_count(item, Item.STACK_KIND.any) or 0) <= 0 then return end

    local data = player:get_data("IngrownIdol", GUID)
    local fed = data.fed or 0
    local frac = math.min(1, fed / THRESHOLD)
    local beast = data.beast
    if DeerItemsCernunnos and DeerItemsCernunnos.get_for_team then
        beast = DeerItemsCernunnos.get_for_team(player.team) or beast
    end
    local live = beast_alive(beast)

    local x, y = hud_position()
    local fx = x + HUD_FILL_X
    local fy = y + HUD_FILL_Y
    local fill = math.floor(HUD_FILL_W * frac)

    gm.draw_set_alpha(1)
    gm.draw_set_colour(HUD_FILL_BG)
    gm.draw_rectangle(fx, fy, fx + HUD_FILL_W - 1, fy + HUD_FILL_H - 1, false)
    if fill > 0 then
        gm.draw_set_colour(live and HUD_FILL_LIVE or HUD_FILL_FG)
        gm.draw_rectangle(fx, fy, fx + fill - 1, fy + HUD_FILL_H - 1, false)
    end
    gm.draw_set_colour(Color.WHITE)
    gm.draw_sprite(barSprite, 0, x, y)
    gm.draw_sprite(sprite, 0, x + HUD_FRAME_W + 16, y + 17)
end)
