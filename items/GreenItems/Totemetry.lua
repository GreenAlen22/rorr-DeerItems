-- DeerItems-Totemetry
-- Раз в 2 минуты спавнит тотем, лечащий всех союзников в радиусе. Также даёт владельцу +10% скорости атаки на 45 сек.

-- Загружаем спрайт предмета
-- Загружаем спрайт тотема
-- Загружаем звуковой эффект
local sprite = Sprite.new("item/Totemetry", PATH.."assets/sprites/items/sGreenItems/Totemetry.png", 1, 16, 16)
local LevelTotem = Sprite.new("particle/LevelTotem", PATH.."assets/sprites/particle/LevelTotem.png", 1, 100, 180)
local sound = Sound.new("sound/Totemetry", PATH.."assets/sounds/Totemetry.ogg")

-- Создание предмета Totemetry
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("Totemetry")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING + Item.LootTag.ITEM_BLACKLIST_ENGI_TURRETS

-- Константы поведения тотема
local RADIUS_BASE   = 7.5 * 32 * 2      -- Базовый радиус (480 px)
local RADIUS_STACK  = 2 * 32 * 2        -- Увеличение радиуса за стак
local HEAL_TICK     = 180               -- Период лечения: раз в 3 сек
local TOTEM_LIFE    = 60 * 45           -- Время жизни тотема: 45 сек
local COOLDOWN      = 60 * 120          -- Время кулдауна: 2 минуты
local AS_BUFF_TIME  = TOTEM_LIFE        -- Длительность бонуса к атак-спиду: 45 сек

-- Цвет отрисовки радиуса тотема — создаётся один раз, а не каждый кадр в onDraw
local TOTEM_COLOR   = Color(0x63494f)

-- Объект тотема
local objTotem = Object.new("EfHealingTotem")
objTotem.obj_sprite = LevelTotem
objTotem.obj_depth = 50
-- При создании тотема
Callback.add(objTotem.on_create, function(self)
    self.life = TOTEM_LIFE
    self.radius = RADIUS_BASE
    self.stack = 1
    self:instance_sync()
end)

-- Поведение тотема: лечение союзников в радиусе раз в 3 секунды
Callback.add(objTotem.on_step, function(self)
    if Net.client then return end

    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    if Global._current_frame % HEAL_TICK == 0 then
        local targets = List.wrap(self:find_characters_circle(self.x, self.y - 40, self.radius, false, 1, true))
        for _, actor in ipairs(targets) do
            local heal = actor.maxhp * (0.02 * self.stack) -- 2% +2% за стак
            actor:heal(heal)
        end
    end
end)

-- Визуализация радиуса тотема
Callback.add(objTotem.on_draw, function(self)
    -- Координаты и радиус читаем из инстанса один раз за кадр
    local x, y, r = self.x, self.y - 40, self.radius
    gm.draw_set_colour(TOTEM_COLOR)
    gm.draw_circle(x, y, r, true)
    gm.draw_circle(x, y, r / 3, true)
    gm.draw_rectangle(x - r / 1.2, y - r / 1.2, x + r / 1.2, y + r / 1.2, true)
    gm.draw_roundrect(x - r / 1.4, y - r / 1.4, x + r / 1.4, y + r / 1.4, true)
end)

-- Синхронизация при удалении
Callback.add(objTotem.on_destroy, function(self)
    self:instance_destroy_sync()
end)

local last_totem_frame = {}   -- [actor.id] → кадр последнего спавна

-- Бонус к скорости атаки — бафф, а не таблица кадров: спавн тотема идёт только у хоста,
-- а бафф игра рассылает клиентам сама (apply_buff.gml) и на наложении и снятии
-- пересчитывает статы (apply_buff_internal.gml: actor_queue_dirty).
local asBuff = Buff.new("TotemetryAttackSpeed")
asBuff.show_icon = false
asBuff.is_debuff = false
asBuff.max_stack = 1
DeerItemsCallbacks.buff_stat_recalc(asBuff, function(actor, stack, api)
    api.attack_speed_mult(1.10)
end)

-- Очистка коллбеков
-- Проверка времени и спавн тотема (каждые 2 минуты)
DeerItemsCallbacks.item_pre_step(item, function(actor, stack)
    if Net.client then return end

    local now = Global._current_frame
    local next_frame = (last_totem_frame[actor.id] or -10000) + COOLDOWN

    if now >= next_frame then
        -- Воспроизводим звук
        DeerItemsSound.play_at(sound, actor.x, actor.y, 2.0, 0.9 + math.random() * 0.5)

        -- Спавним тотем
        local inst = objTotem:create(actor.x, actor.y)
        inst.radius = RADIUS_BASE + RADIUS_STACK * (stack - 1)
        inst.stack = stack

        last_totem_frame[actor.id] = now
        actor:buff_apply(asBuff, AS_BUFF_TIME, 1)
    end
end)
