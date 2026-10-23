-- DeerItems-CheatDeath
-- Обман смерти: 10% (+5% за стак) полученного урона не наносится сразу, а растягивается
-- кровотечением на 5 секунд — у тебя появляется окно, чтобы перехилить удар.
-- (Адаптация Shark Teeth из RoR2.)
--
-- Что при 110%: доля «отложенного» урона ОГРАНИЧЕНА 100% (math.min). На ~19+ стаках
-- весь удар целиком превращается в кровотечение (мгновенного урона нет вовсе) — отсюда и
-- название. Без капа доля ушла бы за 100% и предмет «создавал» бы урон/лечение из воздуха.
-- Оговорка: как и Shark Teeth, не спасает от удара, который убивает мгновенно (если HP
-- ушло в 0 в тот же кадр, коллбек уже не успевает вернуть здоровье).

-- Спрайт предмета (кровь рисует движок через цвет урона DoT)
local sprite = Sprite.new("item/CheatDeath", PATH.."assets/sprites/items/sWhiteItems/CheatDeath.png", 1, 18, 18)

-- Балансные константы
local BASE_FRAC      = 0.10   -- 10% базовая доля удара уходит в кровотечение
local FRAC_PER_STACK = 0.05   -- +5% за стак
local DOT_TICKS      = 10     -- число тиков кровотечения
local DOT_RATE       = 30     -- кадров между тиками (30 = 0.5 сек) → 10 × 0.5 = 5 секунд

-- Создание предмета: белый тир, тег «утилита»: защита без лечения, как броня у ванили
local item = Item.new("CheatDeath")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
local GUID = _ENV["!guid"]
local DAMAGE_TEXT_LIFE = 45

local objDamageText = Object.new("CheatDeathDamageText")
objDamageText:set_depth(-1000)
Callback.add(objDamageText.on_create, function(self)
    self.amount = 0
    self.life = DAMAGE_TEXT_LIFE
    self.max_life = DAMAGE_TEXT_LIFE
    self.vx = 0
    self.vy = -0.45
end)
Callback.add(objDamageText.on_step, function(self)
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.life = self.life - 1
    if self.life <= 0 then self:destroy() end
end)
Callback.add(objDamageText.on_draw, function(self)
    local alpha = math.max(0, self.life / self.max_life)
    gm.draw_set_alpha(alpha)
    gm.draw_set_colour(Color.RED)
    gm.draw_text(self.x, self.y, string.format("%d", self.amount))
    gm.draw_set_colour(Color.WHITE)
    gm.draw_set_alpha(1)
end)

local function add_delayed_damage(actor, total)
    local data = Instance.get_data(actor, "CheatDeath", GUID)
    if not data.cd_ticks then data.cd_ticks = {} end
    table.insert(data.cd_ticks, {
        damage = total / DOT_TICKS,
        ticks = DOT_TICKS,
        timer = DOT_RATE,
    })
end

local function clear_delayed_damage(actor)
    if not actor or not Instance.exists(actor) then return end
    Instance.get_data(actor, "CheatDeath", GUID).cd_ticks = nil
end

-- HP удалённого игрока меняет его клиент. После смерти хост тоже обязан убрать
-- оставшийся отложенный урон, иначе следующий тик убьёт уже воскрешённого игрока,
-- хотя хост всё ещё будет считать его живым.
DeerItemsPlayerDeath.on_host(clear_delayed_damage)

local function is_invincible(actor)
    local invincible = actor.invincible
    return invincible == true or (type(invincible) == "number" and invincible > 0)
end

local function spawn_damage_text(actor, amount)
    local inst = objDamageText:create(actor.x + math.random(-8, 8), actor.y - 42)
    inst.amount = math.max(1, math.floor(amount + 0.5))
    inst.vx = math.random(-6, 6) / 20
end

local function deal_internal_damage(actor, amount)
    if amount <= 0 or actor.hp <= 0 or is_invincible(actor) then return false end

    actor.hp = actor.hp - amount
    if actor.hp <= 0 then
        actor.hp = -1000000
    end
    spawn_damage_text(actor, amount)
    return true
end

-- HP удалённого игрока принадлежит его клиенту. Хост лишь ведёт общий таймер debt и
-- передаёт владельцу итог первого восстановления и каждый последующий тик.
local packet_restore = Packet.new("CheatDeath-packet_restore")
local packet_tick = Packet.new("CheatDeath-packet_tick")

packet_restore:set_serializers(function(buffer, actor, hp)
    buffer:write_instance(actor)
    buffer:write_float(hp)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local hp = buffer:read_float()
    if not Instance.exists(actor) or actor ~= Player.get_local() then return end
    actor.hp = math.min(actor.maxhp, hp)
end)

packet_tick:set_serializers(function(buffer, actor, amount)
    buffer:write_instance(actor)
    buffer:write_float(amount)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local amount = buffer:read_float()
    if not Instance.exists(actor) or actor ~= Player.get_local() then return end
    deal_internal_damage(actor, amount)
end)

local function send_restore(actor)
    if not Net.host then return end
    packet_restore:send_to_all(actor, actor.hp)
end

local function send_tick(actor, amount)
    if not Net.host then return end
    packet_tick:send_to_all(actor, amount)
end

DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if stack <= 0 then return end
    -- КРИТИЧНО: пропускаем урон от самого себя. Иначе тики НАШЕГО же кровотечения снова
    -- зашли бы сюда и плодили новые DoT (на 100% доле — лавинообразно).
    if attacker and actor == attacker then return end

    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    -- Доля удара в кровотечение, с жёстким капом 100%
    local frac = math.min(1.0, BASE_FRAC + FRAC_PER_STACK * (stack - 1))
    local total = dmg * frac

    local is_client = Net.client
    if is_client and actor ~= Player.get_local() then return end

    -- Возвращаем отложенную часть HP в том же кадре. actor:heal() применяется сетевым
    -- событием позднее, поэтому клиент успевал увидеть полный исходный урон.
    actor.hp = math.min(actor.maxhp, actor.hp + total)

    -- Локальный игрок получает мгновенную предикцию; сам debt и последующие тики
    -- рассчитывает только хост.
    if is_client then return end

    if actor ~= Player.get_local() then send_restore(actor) end
    -- ...и списываем её как HP-only debt: это не новый damage event и не прокает on-damaged предметы.
    add_delayed_damage(actor, total)
end)

Callback.add(Callback.POST_STEP, function()
    if Net.client then return end

    for _, actor in ipairs(Instance.find_all(gm.constants.pActor)) do
        local data = Instance.get_data(actor, "CheatDeath", GUID)
        local ticks = data.cd_ticks
        if ticks then
            for i = #ticks, 1, -1 do
                local tick = ticks[i]
                tick.timer = tick.timer - 1
                if tick.timer <= 0 then
                    if actor == Player.get_local() then
                        deal_internal_damage(actor, tick.damage)
                    else
                        send_tick(actor, tick.damage)
                    end
                    tick.ticks = tick.ticks - 1
                    if tick.ticks <= 0 then
                        table.remove(ticks, i)
                    else
                        tick.timer = DOT_RATE
                    end
                end
            end

            if #ticks == 0 then data.cd_ticks = nil end
        end
    end
end)
