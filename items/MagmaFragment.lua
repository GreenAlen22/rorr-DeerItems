-- Magma Fragment

local sprite = Resources.sprite_load("DeerItems", "item/MagmaFragment", PATH.."assets/sprites/items/MagmaFragment.png", 1, 16, 16)

local item = Item.new("DeerItems", "MagmaFragment")
item:set_sprite(sprite)
item:set_tier(Item.TIER.common)
item:set_loot_tags(Item.LOOT_TAG.category_damage)

item:onHit(function(actor, victim, damager, stack)
    local victim_data = victim:get_data("MagmaFragment")
    if Helper.chance(0.10 + (0.1 * (stack - 1))) then
        victim:buff_apply(Buff.find("DeerItems-MagmaFragment"), 1)
        victim_data.attacker = actor
    end
end)


-- Buff
local sprite = Resources.sprite_load("DeerItems", "buff/MagmaFragment", PATH.."assets/sprites/buffs/MagmaFragment.png", 1, 6.5, 9)
local buff = Buff.new("DeerItems", "MagmaFragment")
buff.icon_sprite = sprite
buff.icon_stack_subimage = false
buff.draw_stack_number = true
buff.stack_number_col = Array.new(1, Color(0xe46d20))
buff.max_stack = 999
buff.is_timed = false
buff.is_debuff = true

buff:onApply(function(actor, stack)
    local actorData = actor:get_data("MagmaFragment")
    if stack <= 1 then actorData.dot = Instance.wrap_invalid() end
    actorData.duration = 5*60  
end)
buff:onRemove(function(actor, stack)
    local actorData = actor:get_data("MagmaFragment")
    if actorData.dot:exists() then actorData.dot:destroy() end
end)
buff:onStep(function(actor, stack)
    local actorData = actor:get_data("MagmaFragment")

    if actorData.attacker:exists() then
        -- Create oDot if it does not exist
        if not actorData.dot:exists() then
            actorData.dot = actor:apply_dot(0, actorData.attacker, 2, 30, Color(0xA28879))
        end
        
        -- Adjust damage based on buff stack
        -- 30% damage + 20 per stack
        actorData.dot.damage = actorData.attacker.damage * 0.10 + (stack*1.20)
        actorData.dot.ticks = 2     -- Prevent oDot from expiring normally
    end
    -- Decrease buff stacks
    actorData.duration = actorData.duration - 1
    if actorData.duration <= 0 then
        actor:buff_remove(buff, 1)
        actorData.duration = 5*60
    end
end)