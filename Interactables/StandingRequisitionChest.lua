-- DeerItems-StandingRequisitionChest

local GUID = _ENV["!guid"]

local M = {}

M.SPAWN_COST = 25

local CHEST_SPAWN_RARITY = 1
local CHEST_ANIM_DELAY = 10
local GOLDEN_CHEST_BASE_COST = 400

local CAPSULE_A_X = 31
local CAPSULE_B_X = 62
local CAPSULE_Y = 21
local PRICE_TEXT_Y = -54
local PRICE_HINT_X_RADIUS = 64
local PRICE_HINT_TOP = 72
local PRICE_HINT_BOTTOM = 32
local CHEST_ORIGIN_X = 45
local CHEST_ORIGIN_Y = 40
local ITEM_ICON_SCALE = 1.0
local CHOICE_ORIGIN_X = 15
local CHOICE_ORIGIN_Y = 11
local PROMPT_TOKEN = "item.StandingRequisition.interact"
local NAME_TOKEN = "item.StandingRequisition.name"

local chest_sprite = Resources.sprite_load("DeerItems", "interactable/StandingRequisitionChest", PATH.."assets/sprites/Interactables/StandingRequisitionChest.png", 9, CHEST_ORIGIN_X, CHEST_ORIGIN_Y)
local choice_sprite = Resources.sprite_load("DeerItems", "interactable/StandingRequisitionChoice", PATH.."assets/sprites/Interactables/StandingRequisitionChoice.png", 1, CHOICE_ORIGIN_X, CHOICE_ORIGIN_Y)

local chest_obj = Object.new("DeerItems", "StandingRequisitionChest", Object.PARENT.interactableCrate)
chest_obj:set_sprite(chest_sprite)
chest_obj:set_depth(90)
chest_obj:clear_callbacks()

local packet_select = Packet.new()

local chest_card = Interactable_Card.new("DeerItems", "StandingRequisitionChest")
chest_card.object_id = chest_obj
chest_card.required_tile_space = 3
chest_card.spawn_with_sacrifice = false
chest_card.spawn_cost = M.SPAWN_COST
chest_card.spawn_weight = 0
chest_card.default_spawn_rarity_override = CHEST_SPAWN_RARITY
chest_card.decrease_weight_on_spawn = true

local stages_registered = false

packet_select:onReceived(function(message)
    local inst = message:read_instance()
    local selection = message:read_ushort()
    if not Instance.exists(inst) then return end

    local object_index = inst.__object_index or inst.object_index
    if object_index == chest_obj.value then
        inst.selection = selection
    end
end)

local function item_from_contents(inst, index)
    if not inst.contents then return nil end
    local ok, object_id = pcall(function()
        return inst.contents:get(index)
    end)
    if not ok or not object_id then return nil end

    local item_id = gm.object_to_item(object_id)
    if not item_id or item_id < 0 then return nil end
    return Item.wrap(item_id)
end

local function golden_chest_cost()
    return math.floor(GOLDEN_CHEST_BASE_COST * gm.cost_get_base_gold_price_scale() + 0.5)
end

local function refresh_cost(inst)
    inst.cost = (inst.sr_chosen or 0) <= 0 and 0 or golden_chest_cost()
end

local function sync_contents_later(inst)
    if Net.is_host() then
        Alarm.create(function()
            if Instance.exists(inst) then Helper.sync_crate_contents(inst) end
        end, 1)
    end
end

local function set_chest_contents(inst, items)
    local arr = Array.new()
    for _, item_id in ipairs(items) do
        local it = Item.wrap(item_id)
        if it and it.object_id then
            arr:push(it.object_id)
        end
    end
    inst.contents = arr

    sync_contents_later(inst)
end

local function set_initial_contents(inst)
    local items = {}
    if (inst.sr_choice_a or -1) >= 0 then items[#items + 1] = inst.sr_choice_a end
    if (inst.sr_choice_b or -1) >= 0 then items[#items + 1] = inst.sr_choice_b end
    set_chest_contents(inst, items)
end

local function is_excluded(value, exclude)
    if not exclude then return false end
    if type(exclude) ~= "table" then return value == exclude end

    for _, excluded in ipairs(exclude) do
        if value == excluded then return true end
    end
    return false
end

local function paid_choice_ids(inst)
    local tier = inst.sr_paid_tier
    if tier == nil or tier < 0 then return {} end

    local ids = {}
    for _, it in ipairs(Item.find_all(tier, Item.ARRAY.tier)) do
        if it
        and it:is_loot()
        and it:is_unlocked()
        and not is_excluded(it.value, inst.sr_exclude_item)
        then
            ids[#ids + 1] = it.value
        end
    end
    return ids
end

local function set_paid_contents(inst)
    set_chest_contents(inst, paid_choice_ids(inst))
end

local function actor_can_pay(actor, cost)
    return actor and Instance.exists(actor) and ((actor.gold or 0) >= cost)
end

local function draw_price_hint(inst)
    if (inst.sr_chosen or 0) ~= 1 then return end

    local data = inst:get_data("DeerItems", GUID)
    local frame = Global._current_frame or 0
    if (frame - (data.price_hint_frame or -9999)) > 1 then return end

    local text = "$"..tostring(inst.cost or 0)
    local x = inst.x - (#text * 3)
    local y = inst.y + PRICE_TEXT_Y
    gm.draw_set_colour(data.price_hint_can_pay and Color.TEXT_YELLOW or Color.TEXT_RED)
    gm.draw_text(x, y, text)
    gm.draw_set_colour(Color.WHITE)
end

local function update_price_hint(inst)
    local data = inst:get_data("DeerItems", GUID)
    if (inst.sr_chosen or 0) ~= 1 then
        data.price_hint_frame = nil
        return
    end

    local players = Instance.find_all(gm.constants.oP)
    for _, actor in ipairs(players) do
        if Instance.exists(actor)
        and actor.is_local
        and actor.x >= inst.x - PRICE_HINT_X_RADIUS
        and actor.x <= inst.x + PRICE_HINT_X_RADIUS
        and actor.y >= inst.y - PRICE_HINT_TOP
        and actor.y <= inst.y + PRICE_HINT_BOTTOM
        then
            data.price_hint_frame = Global._current_frame or 0
            data.price_hint_can_pay = actor_can_pay(actor, inst.cost or 0)
            return
        end
    end

    data.price_hint_frame = nil
end

local function release_activator(inst)
    inst.last_move_was_mouse = true
    inst.owner = -4

    if inst.activator and Instance.exists(inst.activator) then
        pcall(function() GM.actor_activity_set(inst.activator, 0) end)
    end
end

local function translate(token)
    return Language.translate_token(token)
end

local function draw_choice(inst, item_id, rel_x)
    if not item_id or item_id < 0 then return end

    local choice = Item.wrap(item_id)
    if not choice or not choice.sprite_id then return end

    local x = inst.x - CHEST_ORIGIN_X + rel_x
    local y = inst.y - CHEST_ORIGIN_Y + CAPSULE_Y

    if draw_item_sprite then
        draw_item_sprite(choice.sprite_id, x, y, ITEM_ICON_SCALE)
    else
        gm.draw_sprite_ext(choice.sprite_id, 0, x, y, ITEM_ICON_SCALE, ITEM_ICON_SCALE, 0, Color.WHITE, 1)
    end
end

local function draw_choice_prompt(inst, rel_x)
    local x = inst.x - CHEST_ORIGIN_X + rel_x
    local y = inst.y - CHEST_ORIGIN_Y + CAPSULE_Y
    gm.draw_sprite_ext(choice_sprite, 0, x, y, ITEM_ICON_SCALE, ITEM_ICON_SCALE, 0, Color.WHITE, 1)
end

local function stage_has_card(stage)
    local list = List.wrap(stage.spawn_interactables)
    return list:contains(chest_card)
end

function M.register_for_all_stages()
    if stages_registered then return end

    local stages = Stage.find_all()
    for _, stage in ipairs(stages) do
        if not stage_has_card(stage) then
            stage:add_interactable(chest_card)
        end
    end

    stages_registered = true
end

function M.set_spawn_weight(weight)
    chest_card.spawn_weight = weight or 0
end

function M.apply_plan(inst, plan)
    if not inst or not Instance.exists(inst) or not plan then return end

    inst.sr_owner_id = plan.owner_id
    inst.sr_choice_a = plan.a
    inst.sr_choice_b = plan.b
    inst.sr_paid_tier = plan.paid_tier
    inst.sr_paid_slot = 1
    inst.sr_exclude_item = plan.exclude_item or -1
    inst.sr_chosen = 0
    inst.active = 0
    inst.image_index = 0
    inst.image_speed = 0

    set_initial_contents(inst)
end

function M.get_instances()
    local chests = Instance.find_all(chest_obj)
    local live = {}
    for _, chest in ipairs(chests) do
        if Instance.exists(chest) then
            live[#live + 1] = chest
        end
    end
    return live
end

function M.create_at(x, y)
    return chest_obj:create(x, y)
end

chest_obj:onCreate(function(self)
    self:interactable_init()
    self:interactable_init_name()
    self:instance_sync()

    self.mask_index = chest_sprite
    self.cost = 0
    self.cost_type = Interactable_Object.COST_TYPE.gold
    self.text = translate(PROMPT_TOKEN)
    self.name_text = translate(NAME_TOKEN)
    self.text_offset_x = -20
    self.text_offset_y = -24
    self.image_index = 0
    self.image_speed = 0
    self.sr_owner_id = -1
    self.sr_choice_a = -1
    self.sr_choice_b = -1
    self.sr_paid_tier = -1
    self.sr_paid_slot = 1
    self.sr_exclude_item = -1
    self.sr_chosen = 0
end)

chest_obj:onCheckCost(function(self, actor)
    refresh_cost(self)
    local chosen = self.sr_chosen or 0
    if chosen >= 2 then return false end
    if chosen == 0 then
        return (self.sr_choice_a or -1) >= 0 and (self.sr_choice_b or -1) >= 0
    end

    return #paid_choice_ids(self) > 0 and actor_can_pay(actor, self.cost or 0)
end)

chest_obj:onStep(function(self)
    refresh_cost(self)
    update_price_hint(self)

    if self.sr_chosen >= 2 then
        if self.active ~= 9 then
            release_activator(self)
        end
        self.image_speed = 0

        if self.image_index < 8 then
            local data = self:get_data("DeerItems", GUID)
            data.anim_timer = (data.anim_timer or 0) + 1
            if data.anim_timer >= CHEST_ANIM_DELAY then
                data.anim_timer = 0
                self.image_index = math.min(8, math.floor(self.image_index) + 1)
            end
        else
            self.image_index = 8
            self.active = 9
        end

        return
    end

    self.image_index = 0
    self.image_speed = 0

    if self.active == 0 then
        local data = self:get_data("DeerItems", GUID)
        data.contents_phase = nil
        data.prev_selection = nil
    elseif self.active == 1 then
        local data = self:get_data("DeerItems", GUID)
        local phase = self.sr_chosen or 0
        if data.contents_phase ~= phase then
            if phase == 0 then
                set_initial_contents(self)
            elseif phase == 1 then
                set_paid_contents(self)
            end
            data.contents_phase = phase
        end

        if Net.is_client() and self.activator and Instance.exists(self.activator) and self.activator.is_local then
            data.prev_selection = data.prev_selection or 0
            if data.prev_selection ~= self.selection then
                data.prev_selection = self.selection
                local message = packet_select:message_begin()
                message:write_instance(self)
                message:write_ushort(self.selection or 0)
                message:send_to_host()
            end
        end
    end

    if self.active == 3 then
        release_activator(self)

        if gm._mod_net_isClient() then
            self.active = 100
            return
        end

        local selected_index = math.floor(self.selection or 0)
        local selected = item_from_contents(self, selected_index)
        if not selected then
            self.active = 0
            return
        end

        selected:create(self.x, self.y - 16, self)

        local remaining_index = selected_index == 0 and 1 or 0
        if self.sr_chosen == 0 then
            self.contents = Array.new()
            self.sr_choice_a = -1
            self.sr_choice_b = -1
            self.sr_paid_slot = remaining_index
            self.sr_chosen = 1
            refresh_cost(self)
            sync_contents_later(self)

            self.active = 0
            self.image_index = 0
            self.image_speed = 0
            return
        end

        self.sr_chosen = 2
        self.active = 4
        self.image_index = 1
        self.image_speed = 0
        self.contents = Array.new()
    end
end)

chest_obj:onDraw(function(self)
    if self.sr_chosen >= 2 then return end
    if self.sr_chosen == 1 then
        draw_choice_prompt(self, (self.sr_paid_slot or 1) == 0 and CAPSULE_A_X or CAPSULE_B_X)
        draw_price_hint(self)
        return
    end

    draw_choice(self, self.sr_choice_a, CAPSULE_A_X)
    draw_choice(self, self.sr_choice_b, CAPSULE_B_X)
end)

chest_obj:onSerialize(function(self, buffer)
    buffer:write_int(self.sr_owner_id or -1)
    buffer:write_int(self.sr_choice_a or -1)
    buffer:write_int(self.sr_choice_b or -1)
    buffer:write_int(self.sr_paid_tier or -1)
    buffer:write_int(self.sr_exclude_item or -1)
    buffer:write_byte(self.sr_paid_slot or 1)
    buffer:write_byte(self.sr_chosen or 0)
end)

chest_obj:onDeserialize(function(self, buffer)
    self.sr_owner_id = buffer:read_int()
    self.sr_choice_a = buffer:read_int()
    self.sr_choice_b = buffer:read_int()
    self.sr_paid_tier = buffer:read_int()
    self.sr_exclude_item = buffer:read_int()
    self.sr_paid_slot = buffer:read_byte()
    self.sr_chosen = buffer:read_byte()
    if (self.sr_chosen or 0) == 0 then
        set_initial_contents(self)
    end
end)

M.object = chest_obj
M.card = chest_card

_G.DeerItemsStandingRequisitionChest = M

return M
