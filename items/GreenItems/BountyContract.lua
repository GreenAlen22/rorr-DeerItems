-- DeerItems-BountyContract / «Контракт на отстрел» / "Bounty Contract"
-- Награда за головы элит:
--   (a) Добивание: элита (не босс) с HP ниже порога мгновенно казнится.
--   (b) Деньги дают ТОЛЬКО убийства элит. Обычные убийства золота НЕ приносят.

local sprite = Resources.sprite_load("DeerItems", "item/BountyContract", PATH.."assets/sprites/items/sGreenItems/BountyContract.png", 1, 18, 18)

local GUID = _ENV["!guid"]

-- ── Баланс ──
local THRESH_BASE  = 0.15   -- казнь элиты ниже 15% HP (1 шт.)
local THRESH_STACK = 0.05   -- +5% к порогу за шт. (с стаком добивать ЛЕГЧЕ)
local THRESH_MAX   = 0.50   -- но не выше 50%
local GOLD_BASE    = 40     -- золото за убийство элиты (×множитель цен)
local GOLD_STACK   = 20     -- +20 за шт.

-- Безопасное приведение значения GML-функции (true / 1.0 / 0.0) к булеву.
-- Важно: GM.* возвращает double, и 0.0 в Lua ИСТИННО, поэтому без обёртки фильтр не работает.
local function truthy(v) return v ~= nil and v ~= false and v ~= 0 end

local item = Item.new("DeerItems", "BountyContract")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

-- Является ли жертва элитой (актёр + элитный флаг). Босса добивать нельзя (см. ниже),
-- но если босс ещё и элита — он естественно попадёт под награду за элит.
local function is_elite(victim)
    if not (victim and Instance.exists(victim)) then return false end
    if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return false end
    return GM.actor_is_elite and truthy(GM.actor_is_elite(victim))
end

-- Элиты, за которых золото уже выдано (victim.id → true). Защищает от двойной выплаты,
-- если добитая элита ещё и вызовет onKillProc. Сбрасывается на старте этапа.
local paid = {}

-- Золото пишем только ЛОКАЛЬНОМУ игроку (HUD-золото клиентское), масштаб по времени.
-- paid[id] гарантирует одну выплату на элиту независимо от того, какой коллбек сработал.
local function reward(actor, victim, stack)
    if not (victim and victim.id) then return end
    if paid[victim.id] then return end
    paid[victim.id] = true
    if not actor:same(Player.get_client()) then return end
    local hud = GM._mod_game_getHUD()
    if hud and hud ~= -4 then
        hud.gold = hud.gold + (GOLD_BASE + GOLD_STACK * (stack - 1)) * gm.cost_get_base_gold_price_scale()
    end
end

-- (a) Добивание элит по порогу HP (на хосте — он владеет HP врагов).
-- Награду выдаём ПРЯМО здесь (мы знаем, что это убийство), не полагаясь на onKillProc после
-- прямой записи HP. Босса не добиваем.
item:onHitProc(function(actor, victim, stack, hit_info)
    if not gm._mod_net_isHost() then return end
    if not is_elite(victim) then return end
    if GM.actor_is_boss and truthy(GM.actor_is_boss(victim)) then return end
    if not (victim.maxhp and victim.maxhp > 0) then return end
    if paid[victim.id] then return end

    local thresh = math.min(THRESH_MAX, THRESH_BASE + THRESH_STACK * (stack - 1))
    if (victim.hp / victim.maxhp) < thresh then
        reward(actor, victim, stack)   -- награда за добивание
        victim.hp = -1000000           -- мгновенная казнь
    end
end)

-- (b) Награда за обычное убийство элиты (большим ударом, без добивания).
-- paid[id] не даст заплатить дважды за уже добитую элиту.
item:onKillProc(function(actor, victim, stack)
    if not is_elite(victim) then return end
    reward(actor, victim, stack)
end)

-- Сброс меток на новом этапе
Callback.add(Callback.TYPE.onStageStart, "DeerItems-BountyContract-reset", function(...)
    paid = {}
end)
