-- DeerItems-ReserveCapacitor
-- Даёт дополнительный заряд снаряжения (+1 за шт.). Каждый запасной заряд восстанавливается
-- за время, вдвое большее обычного кулдауна снаряжения. Сам кулдаун активки предмет НЕ ускоряет.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/ReserveCapacitor", PATH.."assets/sprites/items/sGreenItems/ReserveCapacitor.png", 1, 18, 18)

-- Выносим guid мода один раз (чтобы get_data не искал его через debug-стек каждый кадр)
local GUID = _ENV["!guid"]

-- Множитель кулдауна запасного заряда: восстанавливается за 2× обычного кулдауна снаряжения.
local CHARGE_CD_MULT = 2

-- Создание предмета ReserveCapacitor
-- Привязка спрайта к предмету
-- Установка тира предмета: зелёный (необычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "ReserveCapacitor")
item:set_sprite(sprite)
item:set_tier(Item.TIER.uncommon)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Очистка старых коллбеков
item:clear_callbacks()

-- В RoRR снаряжение хранит только один заряд (кулдаун), механики «нескольких зарядов» в движке нет.
-- Эмулируем «+1 заряд за шт.» как пул запасных зарядов, где КАЖДЫЙ заряд восстанавливается
-- НЕЗАВИСИМО за ВДВОЕ больший кулдаун активки (а не пополняются все разом).
--   * При использовании активки, если в пуле есть заряд — расходуем его и быстро (но не мгновенно)
--     откатываем кулдаун, чтобы активку можно было применить снова. Израсходованный заряд встаёт
--     в очередь на восстановление со своим таймером = 2× полного КД активки.
--   * Когда таймер заряда истекает — заряд возвращается в пул (по одному, независимо друг от друга).

-- Сколько кадров кулдауна оставлять после расхода заряда (~0.2 сек).
-- Если сбрасывать кулдаун в 0 мгновенно, одно нажатие успевает сработать дважды за момент.
-- Маленькая пауза убирает двойное срабатывание, оставаясь незаметной игроку.
local ANTI_DOUBLE = 12

-- При получении предмета — наполняем пул зарядов и сбрасываем очередь восстановления
item:onAcquire(function(actor, stack)
    local data = actor:get_data("DeerItems", GUID)
    data.rc_charges = stack      -- доступные запасные заряды
    data.rc_max     = stack      -- потолок пула
    data.rc_timers  = {}         -- таймеры восстановления израсходованных зарядов (кадры)
end)

-- Каждый кадр: независимая перезарядка запасных зарядов (кулдаун самой активки НЕ трогаем)
item:onPostStep(function(actor, stack)
    local data = actor:get_data("DeerItems", GUID)
    data.rc_max = stack
    if data.rc_charges == nil then data.rc_charges = stack end
    data.rc_timers = data.rc_timers or {}

    -- Независимая перезарядка: каждый израсходованный заряд возвращается через свой таймер (2× КД)
    for i = #data.rc_timers, 1, -1 do
        data.rc_timers[i] = data.rc_timers[i] - 1
        if data.rc_timers[i] <= 0 then
            table.remove(data.rc_timers, i)
            data.rc_charges = math.min(data.rc_charges + 1, data.rc_max)
        end
    end
end)

-- При использовании активки: если в пуле есть заряд — расходуем его и быстро откатываем кулдаун
item:onEquipmentUse(function(actor, stack)
    local data = actor:get_data("DeerItems", GUID)
    data.rc_timers = data.rc_timers or {}
    -- Движок только что выставил полный КД активки — это и есть «КД одного заряда»
    local cd_full = actor:get_equipment_cooldown()
    if (data.rc_charges or 0) > 0 and cd_full and cd_full > 0 then
        data.rc_charges = data.rc_charges - 1
        table.insert(data.rc_timers, cd_full * CHARGE_CD_MULT)  -- заряд вернётся через 2× полного КД
        -- быстрый, но НЕ мгновенный откат активки, иначе одно нажатие сработает дважды
        if cd_full > ANTI_DOUBLE then
            actor:reduce_equipment_cooldown(cd_full - ANTI_DOUBLE)
        end
    end
end)

-- Визуал: счётчик доступных запасных зарядов — НАД иконкой активки в HUD (у локального игрока).
--
-- Привязка как в ThinWings: ловим РЕАЛЬНУЮ базу панели навыков, которую движок сам передаёт в
-- hud_draw_skills (arg[2]=baseX, arg[3]=baseY в координатах HUD-отрисовки), и рисуем относительно неё.
-- Позицию бара считает САМА игра → цифра попадает к иконке активки при любом разрешении/окне/
-- соотношении/hud_scale, без калибровки экрана. (Раньше через display_get_width это промахивалось,
-- из-за чего текст оказывался не там.)
--
-- Остаётся лишь фиксированный сдвиг от базы бара до иконки активки — раскладка HUD, одна на всех.
local TEXT_COLOR = Color(0xFFFFFF)
local EQUIP_DX   = 150   -- сдвиг от базы скилл-бара ВПРАВО до иконки активки (HUD-ед.)
local EQUIP_DY   = -18   -- сдвиг по вертикали до места цифры (над иконкой; −вверх)

-- База скилл-бара, пойманная в этом кадре (откуда игра рисует панель навыков)
local g_bar = { x = 0, y = 0, frame = -1 }
pcall(function()
    if not gm.constants.hud_draw_skills then return end
    gm.pre_script_hook(gm.constants.hud_draw_skills, function(self, other, result, args)
        local okx, bx = pcall(function() return args[2].value end)
        local oky, by = pcall(function() return args[3].value end)
        if okx and oky and type(bx) == "number" and type(by) == "number" then
            g_bar.x, g_bar.y, g_bar.frame = bx, by, (Global._current_frame or 0)
        end
    end)
end)

gm.post_script_hook(gm.constants.draw_hud, function()
    if g_bar.frame ~= (Global._current_frame or 0) then return end   -- базу поймали в этом кадре
    local p = Player.get_client()
    if not p or not Instance.exists(p) then return end
    if (p:item_stack_count(item) or 0) <= 0 then return end

    local n = math.floor((p:get_data("DeerItems", GUID).rc_charges) or 0)

    gm.draw_set_colour(TEXT_COLOR)
    gm.draw_text(g_bar.x + EQUIP_DX - 3, g_bar.y + EQUIP_DY, string.format("%d", n))
    gm.draw_set_colour(Color.WHITE)
end)
