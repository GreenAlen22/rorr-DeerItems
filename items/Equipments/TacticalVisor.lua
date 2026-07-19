-- DeerItems-TacticalVisor / «Тактический визор» / "Tactical Visor"
-- Активка (адаптация Ocular HUD из RoR2): на 8 секунд даёт +100% к шансу крита. Без звука. cd 60с.

-- Иконка снаряжения (заглушка-шаблон — замени текстуру по этому пути)
local sprite = Resources.sprite_load("DeerItems", "equipment/TacticalVisor", PATH.."assets/sprites/items/sEquipments/TacticalVisor.png", 1, 18, 18)

-- Настройки баланса
local BUFF_DURATION = 8 * 60   -- длительность баффа, кадры (8 сек)
local COOLDOWN      = 60       -- кулдаун, секунды
local CRIT_BONUS    = 100      -- +100% к шансу крита

-- Создаём снаряжение (тир equipment назначается автоматически — set_tier не нужен)
local equip = Equipment.new("DeerItems", "TacticalVisor")
equip:set_sprite(sprite)
equip:set_loot_tags(Item.LOOT_TAG.category_damage)
equip:set_cooldown(COOLDOWN)

-- Бафф крита (иконку показываем — игрок видит таймер 8 сек)
local buff = Buff.new("DeerItems", "TacticalVisor")
buff.show_icon = false
buff.is_debuff = false
buff.max_stack = 1
buff:clear_callbacks()
buff:onStatRecalc(function(actor, stack)
    actor.critical_chance = actor.critical_chance + CRIT_BONUS
end)

-- Активация: вешаем бафф крита на 8 секунд
equip:onUse(function(actor)
    actor:buff_apply(buff, BUFF_DURATION, 1)
end)
