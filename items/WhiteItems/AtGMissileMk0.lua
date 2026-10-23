-- DeerItems-AtGMissileMk0
-- Даёт шанс 7% на стак запустить самонаводящуюся ракету при попадании атакой.

-- Загружаем спрайт предмета
-- Загружаем звуковые эффекты
-- Загружаем спрайты эффектов
local sprite = Sprite.new("item/AtGMissileMk0", PATH.."assets/sprites/items/sWhiteItems/AtGMissileMk0.png", 1, 16, 16)
local boom = Sound.new("sound/boom", PATH.."assets/sounds/boom.ogg")
local launch = Sound.new("sound/launch", PATH.."assets/sounds/launch.ogg")
local explosive = Sprite.new("particle/explosive", PATH.."assets/sprites/particle/Explosive.png", 5, 32, 32)
local AtgActorSprite = Sprite.new("particle/AtgActorSprite", PATH.."assets/sprites/particle/AtgActorSprite.png", 1, 34, 34)
local missile = Sprite.new("particle/missile", PATH.."assets/sprites/particle/Missile.png", 3, 13, 7)

-- Создаём объект ракеты
local oMissile = Object.new("missile")
oMissile:set_sprite(missile)
-- Инициализация ракеты при создании
Callback.add(oMissile.on_create, function(self)
    self.timer = 0
    self.mask_index = gm.constants.sSinglePixel
    self.speed = 15
    self.parent = -4
    self.target = -4
    self.team = 1
    -- Синхронизация объекта в сетевой игре
    self:projectile_sync(10)
end)

-- Логика движения и наведения ракеты
Callback.add(oMissile.on_step, function(self)
    -- Удаляем ракету, если родитель исчез
    if not Instance.exists(self.parent) then
        self:destroy()
        return
    end
    self.timer = self.timer + 1
    -- Запуск наведения после задержки
    if self.timer >= 20 then
        local t = self.target
        -- Поиск цели, если не задана
        if not Instance.exists(t) then
            t = self:find_target_nearest()
            if t ~= -4 then
                t = t.parent
                self.target = t
                self:instance_resync()
            else
                self.target = -4
            end
        end
        -- Если цель найдена и в радиусе действия
        if Instance.exists(t) and gm.point_distance(self.x, self.y, t.x, t.y) < 1000 then
            local tdir = gm.point_direction(self.x, self.y, t.x, t.y)
            -- Корректировка направления (жёстко или плавно)
            if self:distance_to_object(t) < 70 then
                self.direction = tdir
            else
                self:turn_towards(self.direction, tdir)
            end
            -- Ускорение ракеты до лимита
            self.speed = math.min(12, self.speed + 0.2)
            -- Проверка столкновения с целью
            if self:is_colliding(t) then
                if self:attack_collision_canhit(t) then
                    -- Нанесение урона цели. proc=false обязательно: иначе попадание ракеты
                    -- само сработает в onAttackHit → запустит новую ракету → бесконечный самопрок.
                    local hit = self.parent:fire_direct(t, 0.75, self.direction, self.x, self.y)
                    if hit and hit.attack_info then hit.attack_info.proc = false end
                end
                self:destroy()
            end
        else
            -- Если цель не найдена долгое время — самоликвидация
            if self.timer > 60 then
                self:destroy()
            else
                -- Колебание траектории при поиске
                self.direction = self.direction + math.sin(self.timer / 5) * 5
            end
        end
    end
    -- Поворот спрайта в соответствии с направлением
    self.image_angle = self.direction
end)

-- Взрыв и удаление при уничтожении ракеты
Callback.add(oMissile.on_destroy, function(self)
    self.parent:sound_play(boom, 1.0, 0.9 + math.random() * 0.4)
    -- Визуальный эффект взрыва
    gm.instance_create(self.x, self.y, gm.constants.oEfExplosion).sprite_index = explosive.value
    -- Удаление ракеты в сетевой игре
    self:instance_destroy_sync()
end)

-- Сохранение состояния ракеты для сетевой игры
Object.add_serializers(oMissile, function(self, buffer)
    buffer:write_instance(self.target)
    buffer:write_instance(self.parent)
    gm.write_direction(self.direction)
end, function(self, buffer)
    self.target = buffer:read_instance()
    self.parent = buffer:read_instance()
    self.team = self.parent.team
    self.direction = gm.read_direction()
end)

-- Создание предмета AtGMissileMk0
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("AtGMissileMk0")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- Очистка всех коллбеков перед переопределением
-- При попадании атакой: шанс запустить ракету
-- onHitProc (а не onAttackHit!) срабатывает ТОЛЬКО на атаках с включённым proc.
-- Попадание самой ракеты помечено proc=false (см. oMissile:onStep), поэтому её урон сюда
-- не попадает и цепочка «ракета → ракета → …» больше не зацикливается.
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end
    -- Шанс 7% за стак
    if math.random() <= (0.07 * stack) then
        actor:sound_play(launch, 1.0, 0.9 + math.random() * 0.4)
        -- Создание ракеты рядом с актёром
        local s = oMissile:create(actor.x + actor.image_xscale * 10, actor.y - 15)
        s.direction = 90 - actor.image_xscale * 45
        s.parent = actor
        s.team = actor.team
    end
end)

-- Отрисовка иконки предмета над персонажем
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    gm.draw_sprite(AtgActorSprite.value, 0, actor.x, actor.y)
end)
