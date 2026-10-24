-- DeerItems-GoldStandard / «Золотой стандарт» / "Gold Standard"
-- Получаемое золото даёт долю опыта до следующего уровня; золото остаётся у игрока.

local sprite = Sprite.new("item/GoldStandard", PATH.."assets/sprites/items/sRedItems/GoldStandard.png", 1, 18, 18)

-- Математика Longstanding Solitude из RoR2 без проклятия: «порция» — цена малого сундука
-- (oChest1_Create_0.gml:9, $25 × множитель цены), и каждая порция даёт долю от опыта,
-- нужного до следующего уровня. Доля от уровня, а не от сырого опыта, потому что уровень
-- в RoRR дорожает в 1.6 раза (oDirectorControl_Create_0, player_level_up): множитель
-- сырого опыта прибавлял бы лишь логарифм уровней.
local CHEST_PRICE = 25     -- порция золота, $ до множителя цены
local RATE_BASE   = 0.06   -- доля уровня за порцию на первом стаке
local RATE_STACK  = 0.03   -- прибавка доли за следующий стак

local item = Item.new("GoldStandard")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Опыт, ещё не влитый в полосу. Он локальный для машины: опыт добавляет тот, кто получил
-- золото, как сфера опыта (oEfExp_Alarm_2.gml).
local pending = 0

local function local_holder_stack()
    local player = Player.get_local()
    if player == Instance.INVALID or not Instance.exists(player) then return 0 end
    return player:item_count(item, Item.StackKind.ANY) or 0
end

-- Директор без забега — instance_find вернул -4 (scr_luaApi_game.gml:8), а -4 в Lua истинно.
-- Сырой CInstance оборачивается: метод на нём не проверен (hooks-and-wrappers.md).
local function get_director()
    local director = Instance.wrap(gm._mod_game_getDirector())
    if director == Instance.INVALID or not Instance.exists(director) then return nil end
    return director
end

-- Ваниль при новом уровне обнуляет player_exp, перелив пропадает (player_level_up в
-- oDirectorControl_Create_0). Поэтому за кадр вливается не больше остатка до уровня, а
-- остальное ждёт следующих кадров. Уровень растёт только при строгом player_exp > required
-- (oDirectorControl_Step_2.gml:1): к остатку добавлен LEVEL_EPSILON, иначе полоса встанет
-- полной и уровень придёт только со следующей сферой опыта.
local LEVEL_EPSILON = 0.01

local function flush(director)
    if pending <= 0 then return end
    local required = tonumber(director.player_exp_required) or 0
    local current  = tonumber(director.player_exp) or 0
    local room = required - current + LEVEL_EPSILON
    if room <= 0 then return end

    local amount = math.min(pending, room)
    pending = pending - amount
    director.player_exp = current + amount

    -- Клиент копит опыт для хоста и шлёт его пачкой через alarm[2] директора — тот же
    -- путь, что у сферы опыта (oEfExp_Alarm_2.gml:3-9, proc_server.gml:227).
    if Net.client then
        director.player_exp_client_value_to_network = (tonumber(director.player_exp_client_value_to_network) or 0) + amount
        if director:alarm_get(2) == -1 then director:alarm_set(2, 12) end
    end
end

-- Post-хук: TipJar в pre-хуке уже увеличил сумму, сюда приходит итоговая.
Hook.add_post(DeerItemsGold.ADD_GOLD, function(self, other, result, args)
    local amount = args[1].value
    if type(amount) ~= "number" or amount <= 0 then return end

    local stack = local_holder_stack()
    if stack <= 0 then return end

    local director = get_director()
    if not director then return end

    local chunk = CHEST_PRICE * gm.cost_get_base_gold_price_scale()
    if chunk <= 0 then return end
    local rate = RATE_BASE + RATE_STACK * (stack - 1)

    pending = pending + amount / chunk * rate * (tonumber(director.player_exp_required) or 0)
    flush(director)
end)

Callback.add(Callback.POST_STEP, function()
    if pending <= 0 then return end
    local director = get_director()
    if director then flush(director) end
end)

-- Недолитый опыт прошлого прогона не должен перейти в новый и висеть в меню.
local function reset() pending = 0 end
Callback.add(Callback.ON_GAME_START, reset)
Callback.add(Callback.ON_GAME_END, reset)
