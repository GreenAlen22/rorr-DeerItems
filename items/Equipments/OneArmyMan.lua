-- DeerItems-OneArmyMan / «Один в поле воин» / "One Army Man"
-- Активка: 30 сек играет BFG. Активатор получает скорость атаки, урон и вампиризм.
-- Директор доспавнивает врагов (часть — элиты). Враги, рождённые в окне, дают 0 опыта и 20% золота.

-- Загружаем иконку предмета и музыкальный трек (30 сек)
local sprite = Resources.sprite_load("DeerItems", "equipment/OneArmyMan", PATH.."assets/sprites/items/sEquipments/OneArmyMan.png", 1, 18, 18)
local music  = Resources.sfx_load("DeerItems", "sound/BFG", PATH.."assets/sounds/BFG.ogg")

-- Настройки баланса для тестов
local BUFF_DURATION  = 22 * 60   -- усиление атаки/урона/вампиризма, кадры (1/60 сек)
local SPAWN_DURATION = 30 * 60   -- доспавн = вся длина трека → 8-секундный «хвост» без баффов
local MUSIC_DURATION = 30 * 60   -- трек жёстко глушится на 30-й секунде
local COOLDOWN       = 180       -- мега-КД, секунды
local ELITE_CHANCE   = 0.40      -- шанс элиты в окне
local PUMP_EVERY     = 15        -- подсыпать кредиты чаще (раз в 0.25 сек)
local POINTS_MULT    = 6         -- сколько enemy_buff давать директору за подсыпку (больше врагов)
local MAX_ENEMIES    = 80        -- предохранитель от лагов
local ATK_SPEED_MULT = 0.50      -- +50% скорости атаки (от базовой)
local DAMAGE_MULT    = 0.50      -- +50% урона (от базового)
local HEAL_PER_KILL  = 0.015     -- лечение 1.5% макс. HP за килл
local GOLD_KEEP      = 0.20      -- враги в окне дают 20% золота

-- Громкость BFG = текущая громкость музыки из настроек игры.
-- TODO: после теста заменить тело на реальный источник (пробник в игре). Пока безопасный фолбэк.
local function music_gain()
    return 1.0
end

-- Состояние окна BFG (хранится в файле; директором рулит хост — см. onStep)
local spawn_timer   = 0
local elite_restore = nil
-- Состояние музыки (живёт на клиенте-активаторе, не зависит от хоста)
local music_id    = nil
local music_timer = 0

-- Создаём снаряжение
local equip = Equipment.new("DeerItems", "OneArmyMan")
equip:set_sprite(sprite)
equip:set_loot_tags(Item.LOOT_TAG.category_damage)
equip:set_cooldown(COOLDOWN)

-- Бафф усиления: иконку прячем (своего спрайта нет — иначе показалась бы дефолтная)
local buff = Buff.new("DeerItems", "OneArmyMan")
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1
buff:clear_callbacks()
-- Пока бафф активен: +скорость атаки и +урон от базовых значений
buff:onStatRecalc(function(actor, stack)
    actor.attack_speed = actor.attack_speed + actor.attack_speed_base * ATK_SPEED_MULT
    actor.damage       = actor.damage       + actor.damage_base       * DAMAGE_MULT
end)

-- Активация снаряжения (actor — обёрнутый игрок-активатор)
equip:onUse(function(actor)
    -- Глушим прошлый трек, если ещё звучит (защита от наложения при повторной активации)
    if music_id and gm.audio_is_playing(music_id) then gm.audio_stop_sound(music_id) end
    -- Музыка исходит от активатора (позиционно), громкость — из настройки музыки
    music_id = actor:sound_play(music, music_gain(), 1.0)
    music_timer = MUSIC_DURATION
    -- Усиление короче трека → после него остаётся «хвост» риска
    actor:buff_apply(buff, BUFF_DURATION, 1)
    -- Запоминаем исходный шанс элит и открываем окно доспавна
    local director = gm._mod_game_getDirector()
    if director then elite_restore = director.elite_spawn_chance end
    spawn_timer = SPAWN_DURATION
end)

-- Покадровый цикл: музыка (на активаторе) + доспавн (на хосте)
Callback.add(Callback.TYPE.onStep, "DeerItems-OneArmyMan-spawn", function()
    -- Музыка: ведём её на каждом клиенте-активаторе и жёстко глушим ровно на 30-й секунде
    if music_timer > 0 then
        music_timer = music_timer - 1
        if music_timer <= 0 then
            if music_id and gm.audio_is_playing(music_id) then gm.audio_stop_sound(music_id) end
            music_id = nil
        end
    end

    -- Доспавн: только хост; директор сам тратит подсыпанные кредиты и синкается
    if spawn_timer <= 0 then return end
    if not gm._mod_net_isHost() then return end
    spawn_timer = spawn_timer - 1

    local director = gm._mod_game_getDirector()
    if not director then return end

    -- Держим повышенный шанс элит на время окна
    director.elite_spawn_chance = ELITE_CHANCE

    -- Считаем живых врагов, чтобы не утопить арену
    local enemies = 0
    for _, e in ipairs(Instance.find_all(gm.constants.pActor)) do
        if e.team == 2 then enemies = enemies + 1 end
    end

    -- Периодически подсыпаем директору кредиты — он спавнит на них сам
    if spawn_timer % PUMP_EVERY == 0 and enemies < MAX_ENEMIES then
        director.points = director.points + director.enemy_buff * POINTS_MULT
    end

    -- По завершении окна возвращаем исходный шанс элит
    if spawn_timer <= 0 and elite_restore ~= nil then
        director.elite_spawn_chance = elite_restore
        elite_restore = nil
    end
end)

-- Урезанная награда: враги, рождённые в окне → 0 опыта, 20% золота (считает хост, синкается)
Callback.add(Callback.TYPE.onEnemyInit, "DeerItems-OneArmyMan-reward", function(actor)
    if spawn_timer <= 0 then return end
    if not gm._mod_net_isHost() then return end
    actor.exp_worth = 0
    if actor.gold then actor.gold = actor.gold * GOLD_KEEP end
end)

-- Вампиризм: лечит атакующего за килл, только пока на нём активен бафф
Callback.add(Callback.TYPE.onKillProc, "DeerItems-OneArmyMan-heal", function(victim, attacker)
    if not attacker then return end
    if attacker:buff_stack_count(buff) <= 0 then return end
    attacker:heal(attacker.maxhp * HEAL_PER_KILL)
end)
