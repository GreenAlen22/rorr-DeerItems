-- DeerItems-StandingRequisitionChest

local GUID = _ENV["!guid"]

local M = {}

M.SPAWN_COST = 25

local CHEST_SPAWN_RARITY = 1
local CHEST_ANIM_DELAY = 10

local CAPSULE_A_X = 31
local CAPSULE_B_X = 62
local CAPSULE_Y = 21
local CHEST_ORIGIN_X = 45
local CHEST_ORIGIN_Y = 40
local ITEM_ICON_SCALE = 1.0
local PROMPT_TOKEN = "item.StandingRequisition.interact"
local NAME_TOKEN = "item.StandingRequisition.name"

local chest_sprite = Resources.sprite_load("DeerItems", "interactable/StandingRequisitionChest", PATH.."assets/sprites/Interactables/StandingRequisitionChest.png", 9, CHEST_ORIGIN_X, CHEST_ORIGIN_Y)

local chest_obj = Object.new("DeerItems", "StandingRequisitionChest", Object.PARENT.interactableCrate)
chest_obj:set_sprite(chest_sprite)
chest_obj:set_depth(1)
chest_obj:clear_callbacks()

local chest_card = Interactable_Card.new("DeerItems", "StandingRequisitionChest")
chest_card.object_id = chest_obj
chest_card.required_tile_space = 3
chest_card.spawn_with_sacrifice = false
chest_card.spawn_cost = M.SPAWN_COST
chest_card.spawn_weight = 0
chest_card.default_spawn_rarity_override = CHEST_SPAWN_RARITY
chest_card.decrease_weight_on_spawn = true

local stages_registered = false

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

local function set_chest_contents(inst, a_id, b_id)
    local a = Item.wrap(a_id)
    local b = Item.wrap(b_id)
    local arr = Array.new()
    arr:push(a.object_id)
    arr:push(b.object_id)
    inst.contents = arr

    if Net.is_host() then
        Alarm.create(function()
            if Instance.exists(inst) then Helper.sync_crate_contents(inst) end
        end, 1)
    end
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
    inst.sr_chosen = 0
    inst.active = 0
    inst.image_index = 0
    inst.image_speed = 0

    set_chest_contents(inst, plan.a, plan.b)
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
    self.sr_chosen = 0
end)

chest_obj:onCheckCost(function(self)
    return self.sr_chosen ~= 1 and (self.sr_choice_a or -1) >= 0 and (self.sr_choice_b or -1) >= 0
end)

chest_obj:onStep(function(self)
    if self.sr_chosen == 1 then
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

    if self.active == 3 then
        release_activator(self)

        if gm._mod_net_isClient() then
            self.active = 100
            return
        end

        local selected = item_from_contents(self, self.selection or 0)
        if selected then
            selected:create(self.x, self.y - 16, self)
        end

        self.sr_chosen = 1
        self.active = 4
        self.image_index = 1
        self.image_speed = 0
        self.contents = Array.new()
    end
end)

chest_obj:onDraw(function(self)
    if self.sr_chosen == 1 then return end
    draw_choice(self, self.sr_choice_a, CAPSULE_A_X)
    draw_choice(self, self.sr_choice_b, CAPSULE_B_X)
end)

chest_obj:onSerialize(function(self, buffer)
    buffer:write_int(self.sr_owner_id or -1)
    buffer:write_int(self.sr_choice_a or -1)
    buffer:write_int(self.sr_choice_b or -1)
    buffer:write_byte(self.sr_chosen or 0)
end)

chest_obj:onDeserialize(function(self, buffer)
    self.sr_owner_id = buffer:read_int()
    self.sr_choice_a = buffer:read_int()
    self.sr_choice_b = buffer:read_int()
    self.sr_chosen = buffer:read_byte()
end)

M.object = chest_obj
M.card = chest_card

_G.DeerItemsStandingRequisitionChest = M

return M
