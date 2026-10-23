-- DeerItems-FacetedJade
-- Граненый нефрит: если не получать урон 5 секунд — даёт +45 брони за стак.
-- После удара активный бонус держится ещё 3 секунды, затем восстанавливается снова после 5 секунд покоя.
-- (Адаптация Oddly-shaped Opal из RoR2: щит «вне опасности», только через броню.)

-- Спрайт предмета
-- Спрайт-щит, который рисуется вокруг тела, пока бонус активен
-- Звук восстановления щита
local sprite = Sprite.new("item/FacetedJade", PATH.."assets/sprites/items/sWhiteItems/FacetedJade.png", 1, 18, 18)
local shieldSprite = Sprite.new("particle/FacetedJadeShield", PATH.."assets/sprites/particle/FacetedJadeShield.png", 1, 24, 24)  -- 48x48, origin по центру
local restoreSound = Sound.new("sound/FacetedJade", PATH.."assets/sounds/FacetedJade.ogg")

-- guid мода выносим один раз, чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

-- Балансные константы
local SAFE_FRAMES     = 5 * 60   -- сколько кадров без урона нужно, чтобы щит «зарядился» (5 сек)
local GRACE_FRAMES    = 3 * 60   -- сколько кадров бонус держится после удара
local ARMOR_PER_STACK = 45       -- +45 брони за стак, пока щит активен

-- Создание предмета: белый тир, тег «утилита» (защитный)
local item = Item.new("FacetedJade")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY
-- «Вне опасности», если с последнего полученного урона прошло >= SAFE_FRAMES кадров
local function is_safe(data)
    return (Global._current_frame - (data.fj_last_hit or -math.huge)) >= SAFE_FRAMES
end

local function is_bonus_active(data)
    return is_safe(data) or (data.fj_grace_until or -math.huge) > Global._current_frame
end

-- Спрайт-щит рисуем ОТДЕЛЬНЫМ объектом ЗА игроком (depth = parent.depth+1 → за спиной),
-- с видимостью 35% (прозрачность 65%). Спрайт центрируется на игроке (origin 24,24 для 48x48).
local SHIELD_ALPHA = 0.35
local objShield = Object.new("FacetedJadeShield")
objShield:set_sprite(shieldSprite)
Callback.add(objShield.on_create, function(self)
    self.parent      = -4
    self.image_alpha = SHIELD_ALPHA
    self:projectile_sync(8)
end)
Callback.add(objShield.on_step, function(self)
    if not Instance.exists(self.parent) then
        if Net.client then return end
        self:destroy()
        return
    end
    self.x           = self.parent.x
    self.y           = self.parent.y
    self.depth       = self.parent.depth + 1   -- больше depth → рисуется ЗА игроком
    self.image_alpha = SHIELD_ALPHA
end)

-- Включить/выключить щит-объект у владельца (идемпотентно — можно звать каждый кадр)
Callback.add(objShield.on_destroy, function(self)
    self:instance_destroy_sync()
end)

Object.add_serializers(objShield, function(self, buffer)
    buffer:write_instance(self.parent)
end, function(self, buffer)
    self.parent = buffer:read_instance()
end)

local function set_shield(actor, data, on)
    local sh = data.fj_shield
    if on then
        if not (sh and Instance.exists(sh)) then
            sh = objShield:create(actor.x, actor.y)
            sh.parent = actor
            data.fj_shield = sh
        end
    elseif sh and Instance.exists(sh) then
        sh:destroy()
        data.fj_shield = nil
    end
end

-- При получении предмета запускаем таймер покоя (щит зарядится через 5 сек после подбора)
DeerItemsCallbacks.item_acquired(item, function(actor, stack)
    local data = Instance.get_data(actor, "FacetedJade", GUID)
    data.fj_last_hit = Global._current_frame
    data.fj_was_active = false
    data.fj_grace_until = nil
end)

-- Запоминаем кадр последнего полученного урона (это сбрасывает «вне опасности»)
DeerItemsCallbacks.item_damaged_proc(item, function(actor, attacker, stack, hit_info)
    if Net.client then return end

    -- Игнорируем урон от самого себя (чужие самоповреждающие эффекты не должны сбивать щит)
    if attacker and actor == attacker then return end
    local data = Instance.get_data(actor, "FacetedJade", GUID)
    if is_bonus_active(data) then
        data.fj_grace_until = Global._current_frame + GRACE_FRAMES
    end
    data.fj_last_hit = Global._current_frame
end)

-- Пока «вне опасности» — даём броню (применяется при каждом пересчёте статов)
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack, api)
    if Net.client then return end

    if stack <= 0 then return end
    if is_bonus_active(Instance.get_data(actor, "FacetedJade", GUID)) then
        api.armor_add(ARMOR_PER_STACK * stack)
    end
end)

-- Каждый кадр ловим переход «опасно <-> безопасно»: порог завязан на ВРЕМЯ, а не на событие,
-- поэтому форсим пересчёт статов вручную, чтобы +броня включалась/выключалась вовремя.
DeerItemsCallbacks.item_post_step(item, function(actor, stack)
    if Net.client then return end

    if stack <= 0 then return end
    local data = Instance.get_data(actor, "FacetedJade", GUID)
    local active = is_bonus_active(data)
    local safe = is_safe(data)
    if active ~= data.fj_was_active then
        actor:recalculate_stats()
        if safe then
            actor:sound_play(restoreSound, 1.0, 0.95 + math.random() * 0.1)
        end
        data.fj_was_active = active
    end
    -- Держим щит-объект в актуальном состоянии (за спиной игрока, пока бонус активен)
    set_shield(actor, data, active)
end)

-- При потере предмета — убираем объект-щит (иначе остался бы висеть)
DeerItemsCallbacks.item_removed(item, function(actor, stack)
    if Net.client then return end

    set_shield(actor, Instance.get_data(actor, "FacetedJade", GUID), false)
end)
