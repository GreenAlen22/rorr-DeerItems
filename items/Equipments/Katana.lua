-- DeerItems-Katana / «Катана» / "Katana"
-- Активка: окно парирования 1 с; отражённый удар возвращается разрезом вдвое, КД падает на 75%.

local sprite = Sprite.new("equipment/Katana", PATH.."assets/sprites/items/sEquipments/Katana.png", 1, 18, 18)

local COOLDOWN       = 30     -- КД, секунды
local WINDOW         = 60     -- окно парирования, кадры
local IMMUNE         = 30     -- после первого отражения ещё столько кадров отражаются все удары
local COUNTER_MULT   = 2.0    -- разрез = 2× урона, который пришёл бы
local SLASH_W        = 192    -- разрез вокруг игрока, px (по 3 м в обе стороны)
local SLASH_H        = 80
local SEEK_RANGE     = 640    -- поиск цели контрудара, px (20 м)
local CDR_ON_SUCCESS = 0.75   -- доля оставшегося КД, которую снимает удачное парирование

local GUID = _ENV["!guid"]

local equip = Equipment.new("Katana")
equip:set_sprite(sprite)
equip.loot_tags = Item.LootTag.CATEGORY_DAMAGE
equip.cooldown = COOLDOWN * 60

local function frame()
    return Global._current_frame or 0
end

-- on_use идёт на всех машинах (item_use_equipment.gml:44-45), поэтому окно знают все:
-- клиент отражает удар у себя, хост — у себя.
Callback.add(equip.on_use, function(actor)
    local data = Instance.get_data(actor, "Katana", GUID)
    data.window_until = frame() + WINDOW
    data.countered = false
    actor:sound_play(gm.constants.wMercenary_Parry_Ready, 1, 1)
end)

local function nearest_enemy(actor)
    local enemy_team = tonumber(actor.team) == 1 and 2 or 1
    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, SEEK_RANGE, true, enemy_team, true))
    local best, best_dist
    for _, enemy in ipairs(found) do
        local dist = math.abs(enemy.x - actor.x) + math.abs(enemy.y - actor.y)
        if not best_dist or dist < best_dist then best, best_dist = enemy, dist end
    end
    return best
end

-- Только машина с правом на игрока: fire_* синхронизируются от неё сами (Actor.lua:298-300,
-- 446-447), а срез КД меняет её alarm[0], который и решает, можно ли нажать снова
-- (item_use_equipment.gml:3); хост чужое нажатие применяет принудительно.
-- Сторону по attacker_x не берём: у ближней атаки это центр её взрыва
-- (oExplosionAttack_Step_1.gml:32), а он у врага в упор бывает за спиной игрока.
-- Поэтому разрез идёт вокруг игрока, а ближайший враг вне разреза получает удар напрямую.
local function counter(actor, damage)
    if not Instance.exists(actor) then return end

    -- counter идёт только у машины с правом на игрока: звук остальным — через сеть.
    DeerItemsSound.play_at(Sound.wrap(gm.constants.wMercenary_Parry_SuccessfulSlash), actor.x, actor.y, 1, 1)

    local coef = COUNTER_MULT * damage / math.max(actor.damage, 1)
    -- Спрайт разреза — ванильный sEfSlash2 Mercenary; через fire_explosion он виден всем машинам.
    actor:fire_explosion(actor.x, actor.y, SLASH_W, SLASH_H, coef, gm.constants.sEfSlash2, gm.constants.sSparks9, true)

    local target = nearest_enemy(actor)
    if target and (math.abs(target.x - actor.x) > SLASH_W / 2 or math.abs(target.y - actor.y) > SLASH_H / 2) then
        local direction = target.x >= actor.x and 0 or 180
        actor:fire_direct(target, coef, direction, target.x, target.y, gm.constants.sSparks9, true)
    end

    local remaining = gm.player_get_equipment_cooldown(actor.value) or 0
    if remaining > 0 then
        gm.player_grant_equipment_cooldown_reduction(actor.value, math.floor(remaining * CDR_ON_SUCCESS))
    end
end

-- Ванильное парирование Mercenary: флаг deflect в damage_get_dodge даёт надпись «DEFLECTED»
-- и гасит удар. Ближние атаки врагов (fire_explosion_local) хост по клиенту не проверяет
-- (oExplosionAttack_Step_1.gml:24, local_client_is_authority = is_local), поэтому контрудар
-- делает та машина, у которой право на игрока: без сети и у хоста это он сам.
DamageDodge.add(function(api, current_dodge)
    local actor = api.hit
    if not actor or not Instance.exists(actor) then return end
    local data = Instance.get_data(actor, "Katana", GUID)
    local now = frame()

    if (data.immune_until or -1) >= now then return DamageDodge.DEFLECTED end
    if (data.window_until or -1) < now then return end

    -- Урон по таймеру (горение, кровотечение) идёт через damage_inflict без координаты
    -- атакующего (damage_inflict.gml:26). Он отражается, но окно не тратит и контрудара не даёт.
    if api.attacker_x == nil then return DamageDodge.DEFLECTED end

    if not data.countered then
        data.countered = true
        data.window_until = -1
        data.immune_until = now + IMMUNE

        local authority = Util.bool(actor.local_client_is_authority)
        -- Временный зонд: какая машина видит отражение игрока-клиента. Убрать после прогона.
        log.info("Katana parry seen on "..(Net.host and "host" or "client")..", authority="..tostring(authority))

        if authority then
            local damage = api.damage or 0
            -- Атаку изнутри проверки уклонения не запускаем: следующий кадр.
            Alarm.add(1, function() counter(actor, damage) end)
        end
    end
    return DamageDodge.DEFLECTED
end)
