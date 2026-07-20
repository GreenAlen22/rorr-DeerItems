-- DeerItems-OneArmyMan / В«РћРґРёРЅ РІ РїРѕР»Рµ РІРѕРёРЅВ» / "One Army Man"
-- РђРєС‚РёРІРєР°: 30 СЃРµРє РёРіСЂР°РµС‚ BFG. РђРєС‚РёРІР°С‚РѕСЂ РїРѕР»СѓС‡Р°РµС‚ СЃРєРѕСЂРѕСЃС‚СЊ Р°С‚Р°РєРё, СѓСЂРѕРЅ Рё РІР°РјРїРёСЂРёР·Рј.
-- Р”РёСЂРµРєС‚РѕСЂ РґРѕСЃРїР°РІРЅРёРІР°РµС‚ РІСЂР°РіРѕРІ (С‡Р°СЃС‚СЊ вЂ” СЌР»РёС‚С‹). Р’СЂР°РіРё, СЂРѕР¶РґС‘РЅРЅС‹Рµ РІ РѕРєРЅРµ, РґР°СЋС‚ 0 РѕРїС‹С‚Р° Рё 20% Р·РѕР»РѕС‚Р°.

-- Р—Р°РіСЂСѓР¶Р°РµРј РёРєРѕРЅРєСѓ РїСЂРµРґРјРµС‚Р° Рё РјСѓР·С‹РєР°Р»СЊРЅС‹Р№ С‚СЂРµРє (30 СЃРµРє)
local sprite = Sprite.new("equipment/OneArmyMan", PATH.."assets/sprites/items/sEquipments/OneArmyMan.png", 1, 18, 18)
local music  = Sound.new("sound/BFG", PATH.."assets/sounds/BFG.ogg")

-- РќР°СЃС‚СЂРѕР№РєРё Р±Р°Р»Р°РЅСЃР° РґР»СЏ С‚РµСЃС‚РѕРІ
local BUFF_DURATION  = 22 * 60   -- СѓСЃРёР»РµРЅРёРµ Р°С‚Р°РєРё/СѓСЂРѕРЅР°/РІР°РјРїРёСЂРёР·РјР°, РєР°РґСЂС‹ (1/60 СЃРµРє)
local SPAWN_DURATION = 30 * 60   -- РґРѕСЃРїР°РІРЅ = РІСЃСЏ РґР»РёРЅР° С‚СЂРµРєР° в†’ 8-СЃРµРєСѓРЅРґРЅС‹Р№ В«С…РІРѕСЃС‚В» Р±РµР· Р±Р°С„С„РѕРІ
local MUSIC_DURATION = 30 * 60   -- С‚СЂРµРє Р¶С‘СЃС‚РєРѕ РіР»СѓС€РёС‚СЃСЏ РЅР° 30-Р№ СЃРµРєСѓРЅРґРµ
local COOLDOWN       = 180       -- РјРµРіР°-РљР”, СЃРµРєСѓРЅРґС‹
local ELITE_CHANCE   = 0.40      -- С€Р°РЅСЃ СЌР»РёС‚С‹ РІ РѕРєРЅРµ
local PUMP_EVERY     = 15        -- РїРѕРґСЃС‹РїР°С‚СЊ РєСЂРµРґРёС‚С‹ С‡Р°С‰Рµ (СЂР°Р· РІ 0.25 СЃРµРє)
local POINTS_MULT    = 6         -- СЃРєРѕР»СЊРєРѕ enemy_buff РґР°РІР°С‚СЊ РґРёСЂРµРєС‚РѕСЂСѓ Р·Р° РїРѕРґСЃС‹РїРєСѓ (Р±РѕР»СЊС€Рµ РІСЂР°РіРѕРІ)
local MAX_ENEMIES    = 80        -- РїСЂРµРґРѕС…СЂР°РЅРёС‚РµР»СЊ РѕС‚ Р»Р°РіРѕРІ
local ATK_SPEED_MULT = 0.50      -- +50% СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё (РѕС‚ Р±Р°Р·РѕРІРѕР№)
local DAMAGE_MULT    = 0.50      -- +50% СѓСЂРѕРЅР° (РѕС‚ Р±Р°Р·РѕРІРѕРіРѕ)
local HEAL_PER_KILL  = 0.015     -- Р»РµС‡РµРЅРёРµ 1.5% РјР°РєСЃ. HP Р·Р° РєРёР»Р»
local GOLD_KEEP      = 0.20      -- РІСЂР°РіРё РІ РѕРєРЅРµ РґР°СЋС‚ 20% Р·РѕР»РѕС‚Р°

-- Р“СЂРѕРјРєРѕСЃС‚СЊ BFG = С‚РµРєСѓС‰Р°СЏ РіСЂРѕРјРєРѕСЃС‚СЊ РјСѓР·С‹РєРё РёР· РЅР°СЃС‚СЂРѕРµРє РёРіСЂС‹.
-- TODO: РїРѕСЃР»Рµ С‚РµСЃС‚Р° Р·Р°РјРµРЅРёС‚СЊ С‚РµР»Рѕ РЅР° СЂРµР°Р»СЊРЅС‹Р№ РёСЃС‚РѕС‡РЅРёРє (РїСЂРѕР±РЅРёРє РІ РёРіСЂРµ). РџРѕРєР° Р±РµР·РѕРїР°СЃРЅС‹Р№ С„РѕР»Р±СЌРє.
local function music_gain()
    return 1.0
end

-- РЎРѕСЃС‚РѕСЏРЅРёРµ РѕРєРЅР° BFG (С…СЂР°РЅРёС‚СЃСЏ РІ С„Р°Р№Р»Рµ; РґРёСЂРµРєС‚РѕСЂРѕРј СЂСѓР»РёС‚ С…РѕСЃС‚ вЂ” СЃРј. onStep)
local spawn_timer   = 0
local elite_restore = nil
-- РЎРѕСЃС‚РѕСЏРЅРёРµ РјСѓР·С‹РєРё (Р¶РёРІС‘С‚ РЅР° РєР»РёРµРЅС‚Рµ-Р°РєС‚РёРІР°С‚РѕСЂРµ, РЅРµ Р·Р°РІРёСЃРёС‚ РѕС‚ С…РѕСЃС‚Р°)
local music_id    = nil
local music_timer = 0

-- РЎРѕР·РґР°С‘Рј СЃРЅР°СЂСЏР¶РµРЅРёРµ
local equip = Equipment.new("OneArmyMan")
equip:set_sprite(sprite)
equip.loot_tags = Item.LootTag.CATEGORY_DAMAGE
equip.cooldown = COOLDOWN * 60

-- Р‘Р°С„С„ СѓСЃРёР»РµРЅРёСЏ: РёРєРѕРЅРєСѓ РїСЂСЏС‡РµРј (СЃРІРѕРµРіРѕ СЃРїСЂР°Р№С‚Р° РЅРµС‚ вЂ” РёРЅР°С‡Рµ РїРѕРєР°Р·Р°Р»Р°СЃСЊ Р±С‹ РґРµС„РѕР»С‚РЅР°СЏ)
local buff = Buff.new("OneArmyMan")
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1
-- РџРѕРєР° Р±Р°С„С„ Р°РєС‚РёРІРµРЅ: +СЃРєРѕСЂРѕСЃС‚СЊ Р°С‚Р°РєРё Рё +СѓСЂРѕРЅ РѕС‚ Р±Р°Р·РѕРІС‹С… Р·РЅР°С‡РµРЅРёР№
buff:onStatRecalc(function(actor, stack)
    actor.attack_speed = actor.attack_speed + actor.attack_speed_base * ATK_SPEED_MULT
    actor.damage       = actor.damage       + actor.damage_base       * DAMAGE_MULT
end)

-- РђРєС‚РёРІР°С†РёСЏ СЃРЅР°СЂСЏР¶РµРЅРёСЏ (actor вЂ” РѕР±С‘СЂРЅСѓС‚С‹Р№ РёРіСЂРѕРє-Р°РєС‚РёРІР°С‚РѕСЂ)
equip:onUse(function(actor)
    -- Р“Р»СѓС€РёРј РїСЂРѕС€Р»С‹Р№ С‚СЂРµРє, РµСЃР»Рё РµС‰С‘ Р·РІСѓС‡РёС‚ (Р·Р°С‰РёС‚Р° РѕС‚ РЅР°Р»РѕР¶РµРЅРёСЏ РїСЂРё РїРѕРІС‚РѕСЂРЅРѕР№ Р°РєС‚РёРІР°С†РёРё)
    if music_id and gm.audio_is_playing(music_id) then gm.audio_stop_sound(music_id) end
    -- РњСѓР·С‹РєР° РёСЃС…РѕРґРёС‚ РѕС‚ Р°РєС‚РёРІР°С‚РѕСЂР° (РїРѕР·РёС†РёРѕРЅРЅРѕ), РіСЂРѕРјРєРѕСЃС‚СЊ вЂ” РёР· РЅР°СЃС‚СЂРѕР№РєРё РјСѓР·С‹РєРё
    music_id = actor:sound_play(music, music_gain(), 1.0)
    music_timer = MUSIC_DURATION
    -- РЈСЃРёР»РµРЅРёРµ РєРѕСЂРѕС‡Рµ С‚СЂРµРєР° в†’ РїРѕСЃР»Рµ РЅРµРіРѕ РѕСЃС‚Р°С‘С‚СЃСЏ В«С…РІРѕСЃС‚В» СЂРёСЃРєР°
    actor:buff_apply(buff, BUFF_DURATION, 1)
    -- Р—Р°РїРѕРјРёРЅР°РµРј РёСЃС…РѕРґРЅС‹Р№ С€Р°РЅСЃ СЌР»РёС‚ Рё РѕС‚РєСЂС‹РІР°РµРј РѕРєРЅРѕ РґРѕСЃРїР°РІРЅР°
    local director = gm._mod_game_getDirector()
    if director then elite_restore = director.elite_spawn_chance end
    spawn_timer = SPAWN_DURATION
end)

-- РџРѕРєР°РґСЂРѕРІС‹Р№ С†РёРєР»: РјСѓР·С‹РєР° (РЅР° Р°РєС‚РёРІР°С‚РѕСЂРµ) + РґРѕСЃРїР°РІРЅ (РЅР° С…РѕСЃС‚Рµ)
Callback.add(Callback.ON_STEP, function()
    -- РњСѓР·С‹РєР°: РІРµРґС‘Рј РµС‘ РЅР° РєР°Р¶РґРѕРј РєР»РёРµРЅС‚Рµ-Р°РєС‚РёРІР°С‚РѕСЂРµ Рё Р¶С‘СЃС‚РєРѕ РіР»СѓС€РёРј СЂРѕРІРЅРѕ РЅР° 30-Р№ СЃРµРєСѓРЅРґРµ
    if music_timer > 0 then
        music_timer = music_timer - 1
        if music_timer <= 0 then
            if music_id and gm.audio_is_playing(music_id) then gm.audio_stop_sound(music_id) end
            music_id = nil
        end
    end

    -- Р”РѕСЃРїР°РІРЅ: С‚РѕР»СЊРєРѕ С…РѕСЃС‚; РґРёСЂРµРєС‚РѕСЂ СЃР°Рј С‚СЂР°С‚РёС‚ РїРѕРґСЃС‹РїР°РЅРЅС‹Рµ РєСЂРµРґРёС‚С‹ Рё СЃРёРЅРєР°РµС‚СЃСЏ
    if spawn_timer <= 0 then return end
    if not Net.host then return end
    spawn_timer = spawn_timer - 1

    local director = gm._mod_game_getDirector()
    if not director then return end

    -- Р”РµСЂР¶РёРј РїРѕРІС‹С€РµРЅРЅС‹Р№ С€Р°РЅСЃ СЌР»РёС‚ РЅР° РІСЂРµРјСЏ РѕРєРЅР°
    director.elite_spawn_chance = ELITE_CHANCE

    -- РЎС‡РёС‚Р°РµРј Р¶РёРІС‹С… РІСЂР°РіРѕРІ, С‡С‚РѕР±С‹ РЅРµ СѓС‚РѕРїРёС‚СЊ Р°СЂРµРЅСѓ
    local enemies = 0
    for _, e in ipairs(Instance.find_all(gm.constants.pActor)) do
        if e.team == 2 then enemies = enemies + 1 end
    end

    -- РџРµСЂРёРѕРґРёС‡РµСЃРєРё РїРѕРґСЃС‹РїР°РµРј РґРёСЂРµРєС‚РѕСЂСѓ РєСЂРµРґРёС‚С‹ вЂ” РѕРЅ СЃРїР°РІРЅРёС‚ РЅР° РЅРёС… СЃР°Рј
    if spawn_timer % PUMP_EVERY == 0 and enemies < MAX_ENEMIES then
        director.points = director.points + director.enemy_buff * POINTS_MULT
    end

    -- РџРѕ Р·Р°РІРµСЂС€РµРЅРёРё РѕРєРЅР° РІРѕР·РІСЂР°С‰Р°РµРј РёСЃС…РѕРґРЅС‹Р№ С€Р°РЅСЃ СЌР»РёС‚
    if spawn_timer <= 0 and elite_restore ~= nil then
        director.elite_spawn_chance = elite_restore
        elite_restore = nil
    end
end)

-- РЈСЂРµР·Р°РЅРЅР°СЏ РЅР°РіСЂР°РґР°: РІСЂР°РіРё, СЂРѕР¶РґС‘РЅРЅС‹Рµ РІ РѕРєРЅРµ в†’ 0 РѕРїС‹С‚Р°, 20% Р·РѕР»РѕС‚Р° (СЃС‡РёС‚Р°РµС‚ С…РѕСЃС‚, СЃРёРЅРєР°РµС‚СЃСЏ)
Callback.add(Callback.ON_ENEMY_INIT, function(actor)
    if spawn_timer <= 0 then return end
    if not Net.host then return end
    actor.exp_worth = 0
    if actor.gold then actor.gold = actor.gold * GOLD_KEEP end
end)

-- Р’Р°РјРїРёСЂРёР·Рј: Р»РµС‡РёС‚ Р°С‚Р°РєСѓСЋС‰РµРіРѕ Р·Р° РєРёР»Р», С‚РѕР»СЊРєРѕ РїРѕРєР° РЅР° РЅС‘Рј Р°РєС‚РёРІРµРЅ Р±Р°С„С„
Callback.add(Callback.ON_KILL_PROC, function(victim, attacker)
    if not attacker then return end
    if attacker:buff_count(buff) <= 0 then return end
    attacker:heal(attacker.maxhp * HEAL_PER_KILL)
end)
