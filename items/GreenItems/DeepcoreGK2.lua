-- DeerItems-DeepcoreGK2
-- Призывает дрона, который вращается вокруг игрока, находит врагов и наносит небольшой урон, а также увеличевает скорость игрока. Кол-во целей и радиус зависят от стаков.

-- Загружаем спрайт дрона
-- Загружаем спрайт предмета
local droneSprite = Resources.sprite_load("DeerItems", "object/bosco", PATH.."assets/sprites/particle/bosco.png", 4, 16, 8)
local sprite = Resources.sprite_load("DeerItems", "item/DeepcoreGK2", PATH.."assets/sprites/items/sGreenItems/DeepcoreGK2.png", 1, 16, 16)

-- Создание предмета DeepcoreGK2
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "DeepcoreGK2")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Создание объекта-дрона Bosco
local obj = Object.new("Bosco")
obj:set_sprite(droneSprite)
obj:set_depth(1)

-- При создании дрона: инициализация параметров
obj:onCreate(function(self)
    local data = self:get_data()
    self.persistent = true
    self.image_speed = 0.25
    data.angle = gm.irandom_range(0, 359)
    data.angle_speed = 50
    data.radius = 100
    data.fire_range = 320
    data.charge = 0
end)

-- Поведение дрона каждый кадр
obj:onStep(function(self)
    local data = self:get_data()

    -- Уничтожаем дрона, если владелец исчез
    if not data.parent or not data.parent:exists() then
        self:destroy()
        return
    end

    -- Обновляем радиус атаки по количеству предметов
    local stack = data.parent:item_stack_count(item)
    data.fire_range = 320 + stack * 32

    -- Расчёт позиции вокруг игрока по синусоиде
    data.angle = (data.angle or 0) + (data.angle_speed or 120) / 60
    local offset = gm.dcos(data.angle) * (data.radius or 48)
    self.x = data.parent.x + offset
    self.y = data.parent.y - 10

    -- Зарядка атаки дрона по времени, зависящему от скорости атаки владельца
    local req = 60 / (data.parent.attack_speed or 1)
    if data.charge < req then
        data.charge = data.charge + 1
        data.charged = nil
    else
        data.charged = true
    end

    -- Когда готов — ищем цели и атакуем
    if data.charged then
        data.charge = 0
        data.charged = nil

        local enemies = {}
        local dist = data.fire_range

        -- Поиск враждебных актёров в радиусе
        for _, actor in ipairs(Instance.find_all(gm.constants.pActor)) do
            if actor.team and actor.team ~= data.parent.team then
                local d = gm.point_distance(self.x, self.y, actor.x, actor.y)
                if d <= dist then
                    table.insert(enemies, {actor = actor, dist = d})
                end
            end
        end

        -- Сортировка по дистанции до цели
        table.sort(enemies, function(a, b) return a.dist < b.dist end)

        local max_targets = 1 + stack

        -- Атака ближайших врагов
        for i = 1, max_targets do
            local entry = enemies[i]
            if entry then
                local target = entry.actor

                -- Ориентация дрона
                self.image_xscale = (target.x < self.x) and -1 or 1

                -- Визуальные эффекты: луч + искры
                local blend = Color(0x221f00)

                local tracer = Object.find("ror-efLineTracer"):create(self.x + (self.image_xscale * 1), self.y)
                tracer.xend = target.x
                tracer.yend = target.y
                tracer.bm = 1
                tracer.rate = 0.1
                tracer.width = 1.5
                tracer.image_blend = blend

                local sparks = Object.find("ror-efSparks"):create(target.x, target.y)
                sparks.sprite_index = gm.constants.sSparks1
                sparks.image_blend = blend

                -- Усиливаем скорость движения владельца немного
                data.parent.pHmax = (data.parent.pHmax or 1) + 0.05

                -- Наносим урон напрямую цели
                local base_damage = data.parent.damage or 1
                local damage_amount = base_damage * 0.01
                local attack_info = data.parent:fire_direct(target, damage_amount).attack_info
                attack_info:set_color(blend)
            end
        end
    end
end)

-- Когда игрок получает предмет — создаём дрона, если его ещё нет
item:onAcquire(function(actor, stack)
    local data = actor:get_data("DeerItems")
    if not data.inst then
        local inst = obj:create(actor.x, actor.y)
        inst:get_data().parent = actor
        data.inst = inst
    end
end)

-- Когда предмет удаляется — уничтожаем дрона, если предмета больше нет
item:onRemove(function(actor, stack)
    local data = actor:get_data("DeerItems")
    if stack <= 1 and data.inst and data.inst:exists() then
        data.inst:destroy()
        data.inst = nil
    end
end)
