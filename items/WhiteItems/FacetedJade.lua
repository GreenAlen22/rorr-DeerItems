-- DeerItems-FacetedJade
-- Граненый нефрит: если не получать урон 5 секунд — даёт +45 брони за стак.
-- После удара активный бонус держится ещё 3 секунды, затем восстанавливается снова после 5 секунд покоя.
-- (Адаптация Oddly-shaped Opal из RoR2: щит «вне опасности», только через броню.)

-- Спрайт предмета
-- Спрайт-щит, который рисуется вокруг тела, пока бонус активен
-- Звук восстановления щита
local sprite = Resources.sprite_load("DeerItems", "item/FacetedJade", PATH.."assets/sprites/items/sWhiteItems/FacetedJade.png", 1, 18, 18)
local shieldSprite = Resources.sprite_load("DeerItems", "particle/FacetedJadeShield", PATH.."assets/sprites/particle/FacetedJadeShield.png", 1, 24, 24)  -- 48x48, origin по центру
local restoreSound = Resources.sfx_load("DeerItems", "sound/FacetedJade", PATH.."assets/sounds/FacetedJade.ogg")

-- guid мода выносим один раз, чтобы get_data не искал его через debug-стек каждый кадр
local GUID = _ENV["!guid"]

-- Балансные константы
local SAFE_FRAMES     = 5 * 60   -- сколько кадров без урона нужно, чтобы щит «зарядился» (5 сек)
local GRACE_FRAMES    = 3 * 60   -- сколько кадров бонус держится после удара
local ARMOR_PER_STACK = 45       -- +45 брони за стак, пока щит активен

-- Создание предмета: белый тир, тег «утилита» (защитный)
local item = Item.new("DeerItems", "FacetedJade")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_healing)

item:clear_callbacks()

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
local objShield = Object.new("DeerItems", "FacetedJadeShield")
objShield:set_sprite(shieldSprite)
objShield:clear_callbacks()
objShield:onCreate(function(self)
    self.parent      = -4
    self.image_alpha = SHIELD_ALPHA
    self:projectile_sync(8)
end)
objShield:onStep(function(self)
    if not Instance.exists(self.parent) then
        if gm._mod_net_isClient() then return end
        self:destroy()
        return
    end
    self.x           = self.parent.x
    self.y           = self.parent.y
    self.depth       = self.parent.depth + 1   -- больше depth → рисуется ЗА игроком
    self.image_alpha = SHIELD_ALPHA
end)

-- Включить/выключить щит-объект у владельца (идемпотентно — можно звать каждый кадр)
objShield:onDestroy(function(self)
    self:instance_destroy_sync()
end)

objShield:onSerialize(function(self, buffer)
    buffer:write_instance(self.parent)
end)

objShield:onDeserialize(function(self, buffer)
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
item:onAcquire(function(actor, stack)
    local data = actor:get_data("FacetedJade", GUID)
    data.fj_last_hit = Global._current_frame
    data.fj_was_active = false
    data.fj_grace_until = nil
end)

-- Запоминаем кадр последнего полученного урона (это сбрасывает «вне опасности»)
item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if gm._mod_net_isClient() then return end

    -- Игнорируем урон от самого себя (чужие самоповреждающие эффекты не должны сбивать щит)
    if attacker and actor:same(attacker) then return end
    local data = actor:get_data("FacetedJade", GUID)
    if is_bonus_active(data) then
        data.fj_grace_until = Global._current_frame + GRACE_FRAMES
    end
    data.fj_last_hit = Global._current_frame
end)

-- Пока «вне опасности» — даём броню (применяется при каждом пересчёте статов)
item:onPostStatRecalc(function(actor, stack)
    if gm._mod_net_isClient() then return end

    if stack <= 0 then return end
    if is_bonus_active(actor:get_data("FacetedJade", GUID)) then
        actor.armor = actor.armor + ARMOR_PER_STACK * stack
    end
end)

-- Каждый кадр ловим переход «опасно <-> безопасно»: порог завязан на ВРЕМЯ, а не на событие,
-- поэтому форсим пересчёт статов вручную, чтобы +броня включалась/выключалась вовремя.
item:onPostStep(function(actor, stack)
    if gm._mod_net_isClient() then return end

    if stack <= 0 then return end
    local data = actor:get_data("FacetedJade", GUID)
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
item:onRemove(function(actor, stack)
    if gm._mod_net_isClient() then return end

    set_shield(actor, actor:get_data("FacetedJade", GUID), false)
end)
