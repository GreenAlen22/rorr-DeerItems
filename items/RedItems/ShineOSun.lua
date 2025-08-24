-- DeerItems-ShineOSun
-- При убийстве с шансом 22% создаёт солнце, которое 5 секунд бьёт врагов под собой AOE-уроном от max HP жертвы.

-- Загружаем спрайт предмета
-- Загружаем спрайт солнца
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/ShineOSun", PATH.."assets/sprites/items/sRedItems/ShineOSun.png", 1, 16, 18)
local sunSprite = Resources.sprite_load("DeerItems", "particle/sunSprite", PATH.."assets/sprites/particle/sun_sprite.png", 14, 128, 128)
local sound = Resources.sfx_load("DeerItems", "ShineOSun", PATH.."assets/sounds/ShineOSun.ogg")

-- Создание предмета ShineOSun
-- Привязка спрайта к предмету
-- Установка тира предмета: красный (легендарный)
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("DeerItems", "ShineOSun")
item:set_sprite(sprite)
item:set_tier(Item.TIER.rare)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

-- При убийстве срабатывает шанс 22% создать "солнце" над врагом
item:onKillProc(function(actor, victim, stack)
    if math.random() < 0.22 then
        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)
        stack = stack or 1

        -- Урон: 5% от максимального HP убитого
        local dmg = victim.maxhp * 0.005

        -- Размер зоны действия зависит от количества стаков
        local radius = (12 + 2.5 * (stack - 1)) * 32

        -- Получение и сохранение данных о солнце
        local data = actor:get_data()
        data.suns = data.suns or {}

        table.insert(data.suns, {
            x = victim.x,
            y = victim.y - (6 * 32),     -- визуально выше врага (4 метра вверх)
            dmg = dmg,
            w = radius,
            h = radius + (6 * 32),       -- вертикальное растяжение зоны
            t = 5 * 60,                  -- общее время жизни (5 секунд)
            tick = 12                    -- интервал урона: 12 кадров
        })
    end
end)

-- Обработка каждого активного солнца: урон по области каждые 12 кадров
item:onPostStep(function(actor, stack)
    local data = actor:get_data()
    if not data.suns then return end

    for i = #data.suns, 1, -1 do
        local s = data.suns[i]
        -- Обновление таймеров
        s.t = s.t - 1
        s.tick = s.tick - 1
        -- Каждые 12 кадров — наносим урон
        if s.tick <= 0 then
            s.tick = 12
            actor:fire_explosion(s.x, s.y, s.w, s.h, s.dmg, sunSprite, nil, false)
        end
        -- Удаляем по завершении жизни
        if s.t <= 0 then
            table.remove(data.suns, i)
        end
    end
end)
