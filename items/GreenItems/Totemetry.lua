-- DeerItems-Totemetry
-- Раз в 2 минуты спавнит тотем, лечащий всех союзников в радиусе. Также даёт владельцу +10% скорости атаки на 45 сек.

-- Загружаем спрайт предмета
-- Загружаем спрайт тотема
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/Totemetry", PATH.."assets/sprites/items/sGreenItems/Totemetry.png", 1, 16, 16)
local LevelTotem = Resources.sprite_load("DeerItems", "particle/LevelTotem", PATH.."assets/sprites/particle/LevelTotem.png", 1, 100, 180)
local sound = Resources.sfx_load("DeerItems", "sound/Totemetry", PATH.."assets/sounds/Totemetry.ogg")

-- Создание предмета Totemetry
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: предмет, повышающий живучесть
local item = Item.new("DeerItems", "Totemetry")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_survive)

-- Константы поведения тотема
local RADIUS_BASE   = 7.5 * 32 * 2      -- Базовый радиус (480 px)
local RADIUS_STACK  = 2 * 32 * 2        -- Увеличение радиуса за стак
local HEAL_TICK     = 180               -- Период лечения: раз в 3 сек
local TOTEM_LIFE    = 60 * 45           -- Время жизни тотема: 45 сек
local COOLDOWN      = 60 * 120          -- Время кулдауна: 2 минуты
local AS_BUFF_TIME  = TOTEM_LIFE        -- Длительность бонуса к атак-спиду: 45 сек

-- Объект тотема
local objTotem = Object.new("DeerItems", "EfHealingTotem")
objTotem.obj_sprite = LevelTotem
objTotem.obj_depth = 50

objTotem:clear_callbacks()

-- При создании тотема
objTotem:onCreate(function(self)
    self.life = TOTEM_LIFE
    self.radius = RADIUS_BASE
    self.stack = 1
    self:instance_sync()
end)

-- Поведение тотема: лечение союзников в радиусе раз в 3 секунды
objTotem:onStep(function(self)
    if gm._mod_net_isClient() then return end

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
objTotem:onDraw(function(self)
    gm.draw_set_colour(Color(0x63494f))
    gm.draw_circle(self.x, self.y - 40, self.radius, true)
    gm.draw_circle(self.x, self.y - 40, self.radius / 3, true)
    gm.draw_rectangle(self.x - self.radius / 1.2, self.y - self.radius / 1.2 - 40,
                      self.x + self.radius / 1.2, self.y + self.radius / 1.2 - 40, true)
    gm.draw_roundrect(self.x - self.radius / 1.4, self.y - self.radius / 1.4 - 40,
                      self.x + self.radius / 1.4, self.y + self.radius / 1.4 - 40, true)
end)

-- Синхронизация при удалении
objTotem:onDestroy(function(self)
    self:instance_destroy_sync()
end)

-- Словари для отслеживания времени действия бонусов
local last_totem_frame = {}   -- [actor.id] → кадр последнего спавна
local as_buff_until    = {}   -- [actor.id] → до какого кадра активен атак-спид бафф

-- Очистка коллбеков
item:clear_callbacks()
-- Проверка времени и спавн тотема (каждые 2 минуты)
item:onPreStep(function(actor, stack)
    if gm._mod_net_isClient() then return end

    local now = Global._current_frame
    local next_frame = (last_totem_frame[actor.id] or -10000) + COOLDOWN

    if now >= next_frame then
        -- Воспроизводим звук
        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)

        -- Спавним тотем
        local inst = objTotem:create(actor.x, actor.y)
        inst.radius = RADIUS_BASE + RADIUS_STACK * (stack - 1)
        inst.stack = stack

        -- Обновляем таймеры
        last_totem_frame[actor.id] = now
        as_buff_until[actor.id] = now + AS_BUFF_TIME
    end
end)

-- Бонус к скорости атаки, если активен эффект
item:onStatRecalc(function(actor, stack)
    local until_frame = as_buff_until[actor.id]
    if until_frame and Global._current_frame < until_frame then
        actor.attack_speed = actor.attack_speed * 1.10
    end
end)
