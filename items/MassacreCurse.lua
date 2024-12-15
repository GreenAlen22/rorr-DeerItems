-- Amulet Of Massacre

local sprite = Resources.sprite_load("DeerItems", "item/MassacreCurse", PATH.."assets/sprites/items/MassacreCurse.png", 1, 16, 16)
local item = Item.new("DeerItems", "MassacreCurse")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)


item:onPickup(function(actor, stack)
    local actorData = actor:get_data("MassacreCurse")
    if not actorData.count then
        actorData.count = 0
    end
end)

item:onKill(function(actor, victim, damager, stack)
    local buff = Buff.find("DeerItems-MassacreCurse")
    local actorData = actor:get_data("MassacreCurse")
    actorData.count = actorData.count + 1
    if actorData.count >= 3 then
        local count = 1
        if actor:buff_stack_count(buff) <= 0 then count = 3 end
        actor:buff_apply(buff, 1, count)
    end
end)



-- Buff
local sprite = Resources.sprite_load("DeerItems", "buff/MassacreCurse", PATH.."assets/sprites/buffs/MassacreCurse.png", 1, 7, 7)

local buff = Buff.new("DeerItems", "MassacreCurse")
buff.icon_sprite = sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0xa0735b))
buff.max_stack = 999
buff.is_timed = false

buff:onApply(function(actor, stack)
    local actorData = actor:get_data("MassacreCurse")
    if not actorData.timers then actorData.timers = {} end
    table.insert(actorData.timers, (3.5 + (2.5 * actor:item_stack_count(item))) * 60.0)
end)

buff:onStep(function(actor, stack)
    local actorData = actor:get_data("MassacreCurse")

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

    if stack == 0 then
        actorData.count = 0
    end
end)

buff:onStatRecalc(function(actor, stack)
    actor.damage = actor.damage+((actor.damage*0.03)*stack)
    actor.armor = actor.armor+((actor.armor*0.03)*stack)
end)