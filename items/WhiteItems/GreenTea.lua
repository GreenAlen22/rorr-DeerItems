-- DeerItems-GreenTea
-- Увеличивает макс. HP на 4% за стак, восстанавливает разницу HP при перерасчёте и даёт регенерацию.

-- Загружаем спрайт предмета
local sprite = Resources.sprite_load("DeerItems", "item/GreenTea", PATH.."assets/sprites/items/sWhiteItems/GreenTea.png", 1, 16, 16)

-- Создание предмета GreenTea
-- Привязка спрайта к предмету
-- Установка тира предмета: белый (обычный)
-- Назначение тега лута: предмет, связанный с лечением
local item = Item.new("DeerItems", "GreenTea")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

-- Переменные для сохранения значений до перерасчёта
local maxhp_old
local hp_old

-- До пересчёта статов — сохраняем старые значения HP
gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    maxhp_old = self.maxhp
    hp_old = self.hp
end)

-- После пересчёта статов — применяем бонусы
item:onPostStatRecalc(function(actor, stack)
    -- Увеличение максимального HP на 4% за стак
    actor.maxhp = actor.maxhp + math.ceil(actor.maxhp * (0.04 * stack))
    -- Вычисляем недостающее HP после изменения maxhp
    local hp_restore = hp_old - actor.hp
    -- Восстанавливаем HP, чтобы компенсировать рост maxhp и не терять здоровье
    actor.hp = math.min(actor.maxhp, actor.hp + math.max(0, actor.maxhp - maxhp_old + hp_restore))
    -- Увеличение регенерации HP на 0.007 за стак
    actor.hp_regen = actor.hp_regen + 0.007 * stack
end)
