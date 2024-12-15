-- Ice Mixture

local sprite = Resources.sprite_load("DeerItems", "item/IceMixture", PATH.."assets/sprites/items/IceMixture.png", 1, 16, 16)

local item = Item.new("DeerItems", "IceMixture")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

item:onHit(function(actor, victim, damager, stack)
    local victim_data = victim:get_data("IceMixture")
    if Helper.chance(0.07 + (stack*0.05)) then
        victim:buff_apply(Buff.find("DeerItems-IceMixture"), 1)
        victim_data.attacker = actor
    end
end)


-- Buff
local buff = Buff.new("DeerItems", "IceMixture")
buff.show_icon = false
buff.icon_stack_subimage = false
buff.max_stack = 1
buff.is_timed = false
buff.is_debuff = true

buff:onApply(function(actor, stack)
    local actorData = actor:get_data("IceMixture")
    if not actorData.timers then actorData.timers = {} end
    table.insert(actorData.timers, 4 * 60.0)
end)
-- Buff remove
buff:onStep(function(actor, stack)
    local actorData = actor:get_data("IceMixture")

    -- Decrease stack timers
    -- and remove if expired
    for i, time in ipairs(actorData.timers) do
        actorData.timers[i] = time - 1
        if time <= 0 then table.remove(actorData.timers, i) end
    end
    -- Remove buff stacks if more than ds_list size
    if stack > #actorData.timers then
        local diff = stack - #actorData.timers
        actor:buff_remove(buff, diff)
        actor:recalculate_stats()
    end
    -- Remove buff stacks if more than stack size
    local diff = stack - #actorData.timers
    actor:buff_remove(buff, diff)
    actor:recalculate_stats()
end)

buff:onStatRecalc(function(actor, stack)
    actor.pHmax = actor.pHmax * 0.60
    actor.attack_speed = actor.attack_speed * 0.60
end)