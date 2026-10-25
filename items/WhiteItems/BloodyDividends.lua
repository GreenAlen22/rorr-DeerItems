-- DeerItems-BloodyDividends
-- Кровавые дивиденды: при получении урона от врага даёт золото (8 за стак за удар), растёт со временем.
-- (Адаптация Roll of Pennies из RoR2.)

-- Спрайт предмета
-- Звук монеты (редкий шанс + защита от спама)
local sprite = Sprite.new("item/BloodyDividends", PATH.."assets/sprites/items/sWhiteItems/BloodyDividends.png", 1, 18, 18)
local coinSound = Sound.new("sound/BloodyDividends", PATH.."assets/sounds/BloodyDividends.ogg")

local GUID = _ENV["!guid"]

-- Балансные константы
local GOLD_PER_STACK = 6     -- золото за стак за каждый удар
local SOUND_CHANCE   = 0.15  -- шанс звука при начислении
local SOUND_COOLDOWN = 60    -- минимум кадров между звуками (анти-спам, 1 сек)

-- Создание предмета: белый тир, тег «утилита»
local function play_coin(actor)
    actor:sound_play(coinSound, 1.0, 0.95 + math.random() * 0.1)
end

local packet_coin = Packet.new("BloodyDividends-packet_coin")
packet_coin:set_serializers(function(buffer) end, function(buffer)
    if not Net.client then return end
    local player = Player.get_local()
    if player and Instance.exists(player) then play_coin(player) end
end)

local item = Item.new("BloodyDividends")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if stack <= 0 then return end
    if not (attacker and Instance.exists(attacker)) then return end
    if actor == attacker or actor.team == attacker.team then return end

    -- Сумма масштабируется глобальным множителем цен — «растёт со временем»
    local dmg = hit_info and (hit_info.damage or 0) or 0
    local big_hit_mult = dmg > (actor.maxhp or 0) * 0.25 and 2 or 1
    local money = GOLD_PER_STACK * stack * big_hit_mult * gm.cost_get_base_gold_price_scale()
    -- ON_DAMAGED_PROC зовёт только хост: держателю-клиенту золото уходит пакетом
    DeerItemsGold.pay(actor, money)

    -- Звук с редким шансом и анти-спамом
    local data = Instance.get_data(actor, "BloodyDividends", GUID)
    local now = Global._current_frame
    if (now - (data.pt_last_sound or -SOUND_COOLDOWN)) >= SOUND_COOLDOWN and math.random() < SOUND_CHANCE then
        data.pt_last_sound = now
        -- Звон слышит только сам держатель: у хоста он свой, клиенту — личным пакетом.
        if not Net.online or actor == Player.get_local() then
            play_coin(actor)
        elseif actor.object_index == gm.constants.oP then
            packet_coin:send_direct(actor)
        end
    end
end)
