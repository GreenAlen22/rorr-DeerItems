-- DeerItems-ShineOSun
-- При убийстве с шансом 22% создаёт солнце, которое 5 секунд бьёт врагов под собой AOE-уроном от max HP жертвы.

-- Загружаем спрайт предмета
-- Загружаем спрайт солнца
-- Загружаем звуковой эффект
local sprite = Sprite.new("item/ShineOSun", PATH.."assets/sprites/items/sRedItems/ShineOSun.png", 1, 16.5, 18)
local sunSprite = Sprite.new("particle/sunSprite", PATH.."assets/sprites/particle/sun_sprite.png", 14, 128, 128)
local sound = Sound.new("ShineOSun", PATH.."assets/sounds/ShineOSun.ogg")

-- guid мода: ускоряет get_data (без обхода debug-стека на каждом кадре)
local GUID = _ENV["!guid"]

-- Максимум солнц на карте одновременно (у одного владельца)
local MAX_SUNS = 5
local SUN_Y_OFFSET = 6 * 32
local SUN_SPAWN_COOLDOWN = 5 * 60
-- Цвет отрисовки зоны действия солнца — создаётся один раз, а не каждый кадр
local SUN_COLOR = Color(0xffcc33)

-- Создание предмета ShineOSun
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("ShineOSun")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- При убийстве срабатывает шанс 22% создать "солнце" над врагом
DeerItemsCallbacks.item_kill_proc(item, function(actor, victim, stack)
    if not Net.host then return end

    if math.random() < 0.22 then
        stack = stack or 1

        -- Получение и сохранение данных о солнце
        local data = Instance.get_data(actor, nil, GUID)
        data.suns = data.suns or {}

        if (data.sun_spawn_cooldown or 0) > 0 then return end

        -- Ограничение: не больше MAX_SUNS солнц на карте одновременно
        if #data.suns >= MAX_SUNS then return end

        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)

        -- Урон за удар: 5% от максимального HP убитого — сырое число, а не коэффициент к урону игрока
        local dmg = victim.maxhp * 0.05

        -- Радиус зоны вокруг убитого зависит от количества стаков
        local radius = (12 + 2.5 * (stack - 1)) * 32

        table.insert(data.suns, {
            x = victim.x,
            y = victim.y - SUN_Y_OFFSET, -- визуально выше врага (6 метров вверх)
            dmg = dmg,
            -- Зона — круг вокруг солнца. Солнце висит на 6 м выше убитого, круг от 12 м
            -- всё равно достаёт до земли под ним.
            w = radius,                  -- полуширина зоны
            h = radius,                  -- полувысота зоны
            t = 5 * 60,                  -- общее время жизни (5 секунд)
            tick = 12                    -- интервал урона: 12 кадров
        })
        data.sun_spawn_cooldown = SUN_SPAWN_COOLDOWN
    end
end)

-- Обработка каждого активного солнца: урон по области каждые 12 кадров
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if not Net.host then return end

    local data = Instance.get_data(actor, nil, GUID)
    if (data.sun_spawn_cooldown or 0) > 0 then
        data.sun_spawn_cooldown = data.sun_spawn_cooldown - 1
    end

    if not data.suns then return end

    for i = #data.suns, 1, -1 do
        local s = data.suns[i]
        -- Обновление таймеров
        s.t = s.t - 1
        s.tick = s.tick - 1
        -- Каждые 12 кадров — наносим урон
        if s.tick <= 0 then
            s.tick = 12
            -- fire_explosion берёт полный размер зоны, а не радиус; урон он считает коэффициентом
            -- к урону игрока, поэтому use_raw_damage возвращает его к сырому числу s.dmg.
            local atk = actor:fire_explosion(s.x, s.y, s.w * 2, s.h * 2, s.dmg, sunSprite, nil, false)
            -- Урон солнца НЕ должен прокать и убивать «по-настоящему» в смысле onKillProc:
            -- иначе убитые солнцем враги вызовут onKillProc → солнце создаст само себя.
            if atk and atk.attack_info then
                atk.attack_info:use_raw_damage()
                atk.attack_info.proc = false
                atk.attack_info:set_critical(false)
            end
        end
        -- Удаляем по завершении жизни
        if s.t <= 0 then
            table.remove(data.suns, i)
        end
    end
end)

-- Визуал: показываем зону действия каждого активного солнца
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    local data = Instance.get_data(actor, nil, GUID)
    if not data.suns then return end
    gm.draw_set_colour(SUN_COLOR)
    for _, s in ipairs(data.suns) do
        -- Контур по фактическим размерам зоны взрыва (s.w по горизонтали, s.h по вертикали)
        gm.draw_ellipse(s.x - s.w, s.y - s.h, s.x + s.w, s.y + s.h, true)
    end
end)
