-- DeerItems-MagmaFragment
-- РЎРѕСЋР·РЅС‹Рµ РїРѕРєСѓРїР°РµРјС‹Рµ РґСЂРѕРЅС‹ РїРѕРґР¶РёРіР°СЋС‚ РІСЂР°РіРѕРІ РїСЂРё РїРѕРїР°РґР°РЅРёРё РЅР° 50% СѓСЂРѕРЅР°.

local sprite = Sprite.new("item/MagmaFragment", PATH.."assets/sprites/items/sWhiteItems/MagmaFragment.png", 1, 16, 16)
local drone_indicator = Sprite.new("particle/MagmaFragmentDrone", PATH.."assets/sprites/particle/MagmaFragmentDrone.png", 8, 10, 7)
local sound = Sound.new("sound/MagmaFragment", PATH.."assets/sounds/MagmaFragment.ogg")

local GUID = _ENV["!guid"]
local oP = gm.constants.oP
local DRONE_RADIUS = 100000
local DOT_TICKS = 5
local DOT_RATE = 60
local DOT_DAMAGE = 0.30
local IGNITE_SOUND_CHANCE = 0.25

-- РЎР»РµРґСѓРµРј СЂР°Р±РѕС‡РµРјСѓ РєСЂРёС‚РµСЂРёСЋ HeavyLungs/GlassMagnifier: РєСѓРїР»РµРЅРЅС‹Рµ РґСЂРѕРЅС‹ вЂ” СЃРѕСЋР·РЅС‹Рµ
-- РЅРµ-РёРіСЂРѕРєРё. Cernunnos СЏРІРЅРѕ РёСЃРєР»СЋС‡С‘РЅ, С‡С‚РѕР±С‹ РЅРµ СЃС‡РёС‚Р°С‚СЊСЃСЏ РґСЂРѕРЅРѕРј.
local function is_not_drone(actor)
    return DeerItemsCernunnos and DeerItemsCernunnos.is_not_drone and DeerItemsCernunnos.is_not_drone(actor)
end

local function is_drone(actor)
    return actor and actor.object_index ~= oP and not is_not_drone(actor)
end

local item = Item.new("MagmaFragment")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- Р”Р°РЅРЅС‹Рµ С…СЂР°РЅСЏС‚СЃСЏ РїРѕ РєРѕРјР°РЅРґРµ: РёРіСЂРѕРІС‹Рµ РїРѕРєСѓРїР°РµРјС‹Рµ РґСЂРѕРЅС‹ РЅРµ РІСЃРµРіРґР° РѕС‚РґР°СЋС‚ РІР»Р°РґРµР»СЊС†Р°
-- РІ callback Р°С‚Р°РєРё, Р·Р°С‚Рѕ РєРѕРјР°РЅРґР° Сѓ РЅРёС… РєРѕСЂСЂРµРєС‚РЅР° Рё СЃРѕРІРїР°РґР°РµС‚ СЃ РІР»Р°РґРµР»СЊС†РµРј.
local team_stacks = {}
local team_sources = {}
local team_dots = {}
local team_state_frame = -1

local function refresh_team_state()
    local frame = Global._current_frame or 0
    if team_state_frame == frame then return end
    team_state_frame = frame

    local stacks = {}
    local sources = {}
    for _, player in ipairs(Instance.find_all(oP)) do
        if Instance.exists(player) then
            local stack = player:item_count(item) or 0
            if stack > 0 then
                stacks[player.team] = (stacks[player.team] or 0) + stack
                sources[player.team] = player
            end
        end
    end

    team_stacks = stacks
    team_sources = sources
end

local function active_dots(team)
    local dots = team_dots[team] or {}
    team_dots[team] = dots

    local count = 0
    for victim_id, dot in pairs(dots) do
        if Instance.exists(dot) then
            count = count + 1
        else
            dots[victim_id] = nil
        end
    end
    return dots, count
end

local function play_ignite_sound(victim)
    if math.random() <= IGNITE_SOUND_CHANCE then
        victim:sound_play(sound, 1.0, 0.9 + math.random() * 0.2)
    end
end

DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    refresh_team_state()
    if Net.host then active_dots(actor.team) end
end)

-- onHitProc РїСЂРѕРїСѓСЃРєР°РµС‚ Р°С‚Р°РєРё СЃ proc=false. Р“Р»РѕР±Р°Р»СЊРЅС‹Р№ onAttackHit РїРѕР»СѓС‡Р°РµС‚ РєР°Р¶РґРѕРµ
-- РїРѕРїР°РґР°РЅРёРµ РґСЂРѕРЅР°, РІРєР»СЋС‡Р°СЏ СЃС‚Р°РЅРґР°СЂС‚РЅС‹Р№ РІС‹СЃС‚СЂРµР» Gunner Drone.
Callback.add(Callback.ON_ATTACK_HIT, function(hit_info)
    local drone = hit_info.inflictor
    local victim = hit_info.target
    if Net.client then return end
    if not is_drone(drone) or not victim or not Instance.exists(victim) then return end
    if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return end
    if not hit_info or not hit_info.damage then return end

    refresh_team_state()
    local stack = team_stacks[drone.team] or 0
    local source = team_sources[drone.team]
    if stack <= 0 or not source or not Instance.exists(source) then return end

    local attack_info = hit_info.attack_info
    local force_proc = attack_info and attack_info:get_flag(AttackFlag.FORCE_PROC)
    if not force_proc and math.random() > math.min(1, 0.10 * stack) then return end

    local dots, count = active_dots(drone.team)
    local vdata = victim:get_data("MagmaFragment", GUID)
    local dot = vdata.dot

    -- РћРґРЅР° РєРѕРјР°РЅРґР° РїРѕРґРґРµСЂР¶РёРІР°РµС‚ РЅР° С†РµР»Рё РѕРґРЅРѕ РіРѕСЂРµРЅРёРµ; РїРѕРІС‚РѕСЂРЅС‹Р№ РїСЂРѕРє РѕР±РЅРѕРІР»СЏРµС‚ РµРіРѕ.
    if dot and Instance.exists(dot) then
        if vdata.team ~= drone.team then return end
        dots[victim.id] = dot
        dot.damage = math.max(dot.damage, hit_info.damage * DOT_DAMAGE)
        dot.ticks = DOT_TICKS
        play_ignite_sound(victim)
        return
    end

    if count >= stack + 1 then return end

    -- 5 С‚РёРєРѕРІ РїРѕ 30% СѓСЂРѕРЅР° СѓРґР°СЂР° СЃ РёРЅС‚РµСЂРІР°Р»РѕРј 60 РєР°РґСЂРѕРІ = РѕРґРёРЅ С‚РёРє РІ СЃРµРєСѓРЅРґСѓ 5 СЃРµРєСѓРЅРґ.
    -- РСЃС‚РѕС‡РЅРёРє вЂ” РёРіСЂРѕРє РєРѕРјР°РЅРґС‹, РїРѕСЌС‚РѕРјСѓ DoT РЅРµ РІРѕСЃРїСЂРёРЅРёРјР°РµС‚СЃСЏ РєР°Рє РЅРѕРІС‹Р№ СѓРґР°СЂ РґСЂРѕРЅР°.
    dot = victim:apply_dot(hit_info.damage * DOT_DAMAGE, DOT_TICKS, DOT_RATE, source, Color(0xff4d00), true)
    dot.textColor = Color(0xff4d00)
    dot.sprite_index = gm.constants.sSparks9
    vdata.dot = dot
    vdata.team = drone.team
    dots[victim.id] = dot
    play_ignite_sound(victim)
end)

-- РРЅРґРёРєР°С‚РѕСЂ РІРёРґРµРЅ РїРѕСЃС‚РѕСЏРЅРЅРѕ, РїРѕРєР° Сѓ РёРіСЂРѕРєР° РµСЃС‚СЊ РїСЂРµРґРјРµС‚, РЅР° РІСЃРµС… СЃРѕСЋР·РЅС‹С… РїРѕРєСѓРїР°РµРјС‹С… РґСЂРѕРЅР°С….
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    local drones = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    local frame = math.floor((Global._current_frame or 0) / 4) % 8
    for _, drone in ipairs(drones) do
        if is_drone(drone) then
            gm.draw_sprite(drone_indicator, frame, drone.x-10, drone.y - 16)
        end
    end
end)
