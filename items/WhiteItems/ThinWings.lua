-- DeerItems-ThinWings
-- При активации взаимодействий даёт временный бафф: ускорение и случайное сокращение кулдауна одной из способностей.

-- Загружаем спрайт предмета
-- Загружаем спрайт баффа
-- Загружаем спрайт эффекта активации
local sprite = Resources.sprite_load("DeerItems", "item/ThinWings", PATH.."assets/sprites/items/sWhiteItems/ThinWings.png", 1, 16, 16)
local buffSprite = Resources.sprite_load("DeerItems", "buff/ThinWings", PATH.."assets/sprites/buffs/ThinWings.png", 1, 7, 7)
local ActivateThinWings = Resources.sprite_load("DeerItems", "particle/ActivateThinWings", PATH.."assets/sprites/particle/ActivateThinWings.png", 7, 32, 32)

-- guid мода выносим один раз — чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]
-- Цвет рамки-индикатора выбранного навыка
local FRAME_COLOR = Color(0xFFFFFF)

-- Создание предмета и баффа
local item = Item.new("DeerItems", "ThinWings")
local buff = Buff.new("DeerItems", "ThinWings")

-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- Очистка старых коллбеков
item:clear_callbacks()

-- При активации взаимодействий даёт бафф
item:onInteractableActivate(function(actor, stack, interactable)
    -- Применяем бафф на 10 секунд за стак
    actor:buff_apply(buff, 10 * 60, stack)
    -- Один раз за активацию выбираем, какой навык получит ускоренную перезарядку,
    -- и фиксируем выбор на всё время баффа (раньше он перебрасывался каждый пересчёт статов).
    -- tw_slot = 1/2/3 = вторичное/утилита/спец (как Skill.SLOT.secondary/utility/special).
    local data = actor:get_data("DeerItems", GUID)
    data.tw_slot = math.random(3)
    -- Визуальный эффект активации
    local ef = gm.instance_create(actor.x, actor.y - 40, gm.constants.oEfSparks)
    ef.sprite_index = ActivateThinWings
end)

--==================================================================================================
-- ПОДСВЕТКА ВЫБРАННОГО НАВЫКА НА ИКОНКЕ В HUD — умная привязка БЕЗ калибровки позиции.
--
-- Игровой скрипт hud_draw_skills, рисующий панель навыков, ПОЛУЧАЕТ от движка точку, откуда рисует
-- бар (разведка через лог: arg[2]=baseX, arg[3]=baseY в координатах HUD-отрисовки; arg[1]=актёр).
-- Эту базу ловим в pre-хуке и запоминаем на кадр, а рамку рисуем в gm.post_script_hook(draw_hud) — поверх
-- всего бара и в ТОЙ ЖЕ системе координат. Позицию бара считает САМА игра, поэтому она автоматически
-- верна при любом разрешении/окне/соотношении/hud_scale — калибровать центр/масштаб не нужно.
--
-- Остаются лишь маленькие ФИКСИРОВАННЫЕ сдвиги от базы бара до центра каждой иконки (внутренняя
-- раскладка панели, одна на всех). Если рамка чуть мимо иконки — правь ТОЛЬКО эти 4 числа:
--   x(slot) = baseX + ICON_FIRST + slot*ICON_STEP   (slot: 0=осн, 1=втор, 2=утил, 3=спец)
--   y       = baseY + ICON_DY
--==================================================================================================
local ICON_FIRST = 15.8    -- сдвиг от базы бара до ЦЕНТРА иконки слота 0 (после блока «LV»)
local ICON_STEP  = 29    -- шаг между центрами соседних иконок навыков
local ICON_DY    = 12    -- вертикальная поправка от базы бара до центра иконок (+вниз / −вверх)
local ICON_HALF  = 14    -- полусторона рамки (≈ половина иконки)

-- База скилл-бара, пойманная в этом кадре (откуда игра рисует панель навыков)
local g_bar = { x = 0, y = 0, frame = -1 }

-- pre-хук hud_draw_skills: только запоминаем baseX/baseY (рисовать здесь нельзя — бар ещё не нарисован).
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

-- Рисуем рамку ПОВЕРХ HUD, по пойманной в этом же кадре базе бара.
gm.post_script_hook(gm.constants.draw_hud, function()
    local frame = Global._current_frame or 0
    if g_bar.frame ~= frame then return end        -- базу поймали именно в этом кадре (бар нарисован)

    local p = Player.get_client()
    if not p or not Instance.exists(p) then return end
    -- Подсветка живёт РОВНО пока активен бафф (т.е. пока реально срезан КД этого навыка)
    if (p:buff_stack_count(buff) or 0) <= 0 then return end
    local slot = p:get_data("DeerItems", GUID).tw_slot
    if not slot then return end

    local cx = g_bar.x + ICON_FIRST + slot * ICON_STEP
    local cy = g_bar.y + ICON_DY

    -- Лёгкая пульсация рамки для заметности (Global._current_frame доступен в этом тулките)
    local a = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(frame * 0.15))
    local h = ICON_HALF

    gm.draw_set_colour(FRAME_COLOR)
    gm.draw_set_alpha(a * 0.22)
    gm.draw_rectangle(cx - h, cy - h, cx + h, cy + h, false)  -- полупрозрачная заливка
    gm.draw_set_alpha(a)
    gm.draw_rectangle(cx - h, cy - h, cx + h, cy + h, true)   -- яркий контур
    gm.draw_set_alpha(1)
    gm.draw_set_colour(Color.WHITE)
end)

-- Настройки отображения баффа
buff.show_icon = true
buff.icon_sprite = buffSprite
buff.icon_stack_subimage = false
buff.max_stack = 9999

-- Очистка старых коллбеков баффа
buff:clear_callbacks()

-- Модификация статов под действием баффа
buff:onStatRecalc(function(actor, stack)
    -- Увеличение максимальной горизонтальной скорости
    actor.pHmax = actor.pHmax + (0.19 + 0.22 * stack)
    -- Берём ЗАФИКСИРОВАННЫЙ при активации навык (а не новый рандом на каждом пересчёте)
    local slot = actor:get_data("DeerItems", GUID).tw_slot or 1
    if slot == 1 then
        -- Уменьшаем кулдаун вторичного умения
        local secondary = actor:get_active_skill(Skill.SLOT.secondary)
        secondary.cooldown = math.ceil(secondary.cooldown * 0.8)
    elseif slot == 2 then
        -- Уменьшаем кулдаун утилиты
        local utility = actor:get_active_skill(Skill.SLOT.utility)
        utility.cooldown = math.ceil(utility.cooldown * 0.9)
    else
        -- Уменьшаем кулдаун специального умения
        local special = actor:get_active_skill(Skill.SLOT.special)
        special.cooldown = math.ceil(special.cooldown * 0.8)
    end
end)
