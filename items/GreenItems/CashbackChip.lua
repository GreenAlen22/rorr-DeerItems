-- DeerItems-CashbackChip / «Кэшбэк-Чип» / "Cashback Chip"
-- Пассивка (адаптация Executive Card из RoR2). Два независимых эффекта:
--   (a) С ЛЮБОЙ покупки за золото возвращается 10% потраченного за стак гиперболически.
--   (b) Раз за этап первый сундук бесплатный, доп. стаки дают +10% к следующему бесплатному сундуку.

-- Иконка предмета (заглушка-шаблон — замени текстуру по этому пути)
local sprite = Resources.sprite_load("DeerItems", "item/CashbackChip", PATH.."assets/sprites/items/sGreenItems/CashbackChip.png", 1, 18, 18)
local sound = Resources.sfx_load("DeerItems", "sound/GoldBar", PATH.."assets/sounds/GoldBar.ogg")

-- ── Настройки баланса ──
local CASHBACK_BASE = 0.10
local FREE_CHEST_BASE = 1
local FREE_CHEST_STACK_CHANCE = 0.10

-- Сколько бесплатных сундуков уже использовано в этом этапе у каждого игрока: [actor.id] → число
local free_used = {}

local item = Item.new("DeerItems", "CashbackChip")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)
item:clear_callbacks()

-- Начисление золота ЛОКАЛЬНОМУ игроку через HUD (как все денежные предметы мода: GoldBar/PainTax/BountyTag)
local function give_gold(amount)
    if amount <= 0 then return end
    local hud = GM._mod_game_getHUD()
    if hud and hud ~= -4 then
        hud.gold = hud.gold + amount
    end
end

-- Безопасное приведение значения GML-функции (true / 1.0 / 0.0) к булеву
local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

-- Является ли интерактив сундуком (для бесплатного сундука)
local function is_chest(interactable)
    if not interactable or not Instance.exists(interactable) then return false end
    local ok, res = pcall(function()
        return gm.object_is_ancestor(interactable.object_index, gm.constants.pInteractableChest)
    end)
    return ok and truthy(res)
end

local function cashback_fraction(stack)
    if stack <= 0 then return 0 end
    return 1 - 1 / (CASHBACK_BASE * stack + 1)
end

local function should_refund_chest(actor_id, stack)
    local used = free_used[actor_id] or 0
    local budget = FREE_CHEST_BASE + FREE_CHEST_STACK_CHANCE * math.max(0, stack - 1)
    local guaranteed = math.floor(budget)

    if used < guaranteed or (used == guaranteed and math.random() < (budget - guaranteed)) then
        free_used[actor_id] = used + 1
        return true
    end

    return false
end

-- Возврат денег при покупке. onInteractableActivate (тип 37) срабатывает ТОЛЬКО у держателей
-- предмета и передаёт (actor, stack, interactable). Деньги пишем только локальному игроку.
item:onInteractableActivate(function(actor, stack, interactable)
    if not interactable or not Instance.exists(interactable) then return end

    -- Кредитуем только HUD локального игрока (в сетевой игре чужие покупки не трогаем)
    local p = Player.get_client()
    if not p or not Instance.exists(p) or actor.id ~= p.id then return end

    -- Только покупки за ЗОЛОТО (cost_type 0). Для hp/percent_hp покупок .cost — не деньги.
    if interactable.cost_type ~= 0 then return end
    local cost = interactable.cost or 0
    if cost <= 0 then return end

    -- (b) Бесплатный сундук: 1 гарантированно, затем +10% к следующему за каждый доп. стак.
    if is_chest(interactable) and should_refund_chest(actor.id, stack) then
        give_gold(cost)
        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
        return   -- бесплатный сундук не комбинируем с 10%-возвратом (и так вернули всё)
    end

    -- (a) 10% кэшбэк с любой покупки за золото, настакивается гиперболически без капа.
    give_gold(math.floor(cost * cashback_fraction(stack)))
end)

-- Сброс счётчика бесплатных сундуков на новом этапе
item:onStageStart(function(actor, stack)
    free_used[actor.id] = 0
end)
