-- DeerItems-GoldBar
-- При начале стадии воспроизводит звук и даёт золото, масштабированное от количества стаков.

-- Загружаем спрайт предмета
-- Загружаем звуковой эффект
local sprite = Resources.sprite_load("DeerItems", "item/GoldBar", PATH.."assets/sprites/items/sWhiteItems/GoldBar.png", 1, 16, 16)
local sound = Resources.sfx_load("DeerItems", "sound/GoldBar", PATH.."assets/sounds/GoldBar.ogg")

-- Создание нового предмета с названием "GoldBar" в категории "DeerItems"
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: утилитарный предмет
local item = Item.new("DeerItems", "GoldBar")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_utility)

-- При начале стадии: воспроизведение звука и начисление золота
item:onStageStart(function(actor, stack)
    -- Воспроизводим звук с рандомизированным питчем
    actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)

    -- Вычисляем сумму золота с учётом стаков и глобального множителя
    local money = (11 + 22 * stack) * gm.cost_get_base_gold_price_scale()

    -- Через 1 тик добавляем золото на HUD. Через 1 тик, так как если сделать это без задержки, 
    -- hud не успеет загрузиться, и начисление денег будет в пустоту. Из-за этого будет краш игры.
    Alarm.create(function()
        local hud = GM._mod_game_getHUD()
        if hud ~= -4 then
            hud:add_gold_gml_Object_oHUD_Create_0(money)
        end
    end, 1)
end)
