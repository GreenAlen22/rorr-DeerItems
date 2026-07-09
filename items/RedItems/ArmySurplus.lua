-- DeerItems-ArmySurplus / «Армейские излишки» / "Army Surplus"
-- Порт Spare Drone Parts из RoR2.
-- Призывает НАСТОЯЩЕГО игрового боевого дрона (oDrone10 — редкий «красный» боевой дрон) — такого же,
-- как покупаемые у сломанных дронов-интерактивов. Он сам летает, наводится и стреляет своим ИИ
-- и НЕ управляется как второй персонаж (в отличие от oPDrone + set_player, который делал именно так).
-- Спавн — проверенным способом из примера Artifact of Assembly:
--   gm.instance_create_depth(x, y, depth, gm.constants.oDrone1)  → готовый дрон-союзник.
-- Все настоящие дроны/союзники владельца (включая этого) получают +60% урона за стак.
-- Часть дополнительного лечения владельца передается дронам.

local sprite = Resources.sprite_load("DeerItems", "item/ArmySurplus", PATH.."assets/sprites/items/sRedItems/ArmySurplus.png", 1, 18, 18)

local GUID = _ENV["!guid"]
local oP   = gm.constants.oP

-- Какого игрового дрона разворачивать. oDrone10 = редкий боевой дрон из «красной» группы
-- (по разбивке Artifact of Assembly: red = {oDrone8, oDrone9, oDrone10}). Если в этой сборке
-- такой константы нет — откатываемся на надёжного базового oDrone1, чтобы предмет не «молчал».
local DRONE_OBJ = gm.constants.oDrone10 or gm.constants.oDrone1

-- ── Баланс ────────────────────────────────────────────────────────────────────
local DRONE_DMG_STACK = 0.60    -- +60% drone damage per stack
local HEAL_SHARE = 0.25
local DRONE_RADIUS = 100000
-- ──────────────────────────────────────────────────────────────────────────────

local g_team_stack = {}   -- стаки предмета по командам — для хука усиления дронов

local item = Item.new("DeerItems", "ArmySurplus")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

-- Жив ли наш дрон? Это RAW-инстанс (из gm.instance_create_depth), поэтому проверяем нативно.
-- gm.instance_exists возвращает 1.0/0.0 — сравниваем с 1.0 (помним про «0.0 truthy» в Lua).
-- Доп. сверка object_index страхует от переиспользования id движком после смерти дрона.
local function drone_alive(inst)
    return inst ~= nil and gm.instance_exists(inst) == 1.0 and inst.object_index == DRONE_OBJ
end

-- Разворачиваем настоящего дрона у владельца, если его ещё нет. Только на хосте: дрон — сетевая
-- сущность, хост её спавнит, а клиентам игра синхронизирует дрона своими средствами сама.
local function ensure_drone(actor)
    if gm._mod_net_isClient() then return end
    if not DRONE_OBJ then return end                 -- константа недоступна — тихо выходим
    local data = actor:get_data("ArmySurplus", GUID)
    if drone_alive(data.inst) then return end
    local inst = gm.instance_create_depth(actor.x, actor.y, actor.depth, DRONE_OBJ)
    -- Привязываем дрона к ВЛАДЕЛЬЦУ. owner — реальное поле дронов (его читает voidCore.lua);
    -- кладём именно raw-CInstance (actor.value), а не тулкит-обёртку, иначе GML получит мусор.
    inst.owner = actor.value
    data.inst  = inst
end

local function heal_drones(actor, amount)
    if amount <= 0 then return end

    local found = List.wrap(actor:find_characters_circle(actor.x, actor.y, DRONE_RADIUS, false, actor.team, true))
    for _, char in ipairs(found) do
        if char ~= actor and char.object_index ~= oP then
            char:heal(amount)
        end
    end
end

local function share_bonus_healing(actor)
    local data = actor:get_data("ArmySurplus", GUID)
    local hp = actor.hp
    local maxhp = actor.maxhp
    if not hp or not maxhp then return end

    if data.as_prev_hp == nil or data.as_prev_maxhp ~= maxhp then
        data.as_prev_hp = hp
        data.as_prev_maxhp = maxhp
        return
    end

    local gained = hp - data.as_prev_hp
    if gained > 0 then
        local expected_regen = math.max(0, actor.hp_regen or 0)
        local bonus_heal = gained - expected_regen
        if bonus_heal > 0 then
            heal_drones(actor, bonus_heal * HEAL_SHARE)
        end
    end

    data.as_prev_hp = actor.hp
    data.as_prev_maxhp = maxhp
end

item:onStatRecalc(function(actor, stack)
    if stack > 0 then g_team_stack[actor.team] = stack end
end)

item:onAcquire(function(actor, stack)
    g_team_stack[actor.team] = stack
    ensure_drone(actor)
    local data = actor:get_data("ArmySurplus", GUID)
    data.as_prev_hp = actor.hp
    data.as_prev_maxhp = actor.maxhp
end)

item:onRemove(function(actor, stack)
    if stack <= 1 then
        g_team_stack[actor.team] = nil
        if gm._mod_net_isClient() then return end
        local data = actor:get_data("ArmySurplus", GUID)
        if drone_alive(data.inst) then gm.instance_destroy(data.inst) end
        data.inst = nil
    end
end)

-- Держим стак свежим + переустанавливаем дрона, если игра его убрала. Купленные дроны не
-- переходят между этапами — на новой локации drone_alive вернёт false и мы развернём своего заново.
item:onPostStep(function(actor, stack)
    if stack <= 0 then return end
    g_team_stack[actor.team] = stack
    ensure_drone(actor)
    share_bonus_healing(actor)
end)

-- Усиление урона ВСЕХ дронов/союзников владельца — на пересчёте их статов
-- (приём из HeavyLungs: ванильные дроны не зовут item:onStatRecalc, ловим их в хуке).
-- Наш развёрнутый oDrone1 — тоже дрон, поэтому усиливается этим же хуком (как и задумано).
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    if self.object_index == oP then return end       -- не трогаем самих игроков
    local s = g_team_stack[self.team]
    if not s or s <= 0 then return end
    self.damage = self.damage * (1 + DRONE_DMG_STACK * s)
end)
