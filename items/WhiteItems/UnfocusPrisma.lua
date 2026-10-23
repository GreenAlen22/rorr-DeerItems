-- DeerItems-UnfocusPrisma
-- Увеличивает урон по врагам на расстоянии более 8 метров на 25% (+25% за стак).

-- Загружаем спрайт предмета
local sprite = Sprite.new("item/UnfocusPrisma", PATH.."assets/sprites/items/sWhiteItems/UnfocusPrisma.png", 1, 16, 16)

-- Создание предмета UnfocusPrisma
-- Привязка спрайта к предмету
-- Назначение тега лута: предмет, усиливающий урон
local item = Item.new("UnfocusPrisma")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE

-- Порог дальности, с которого начинает действовать бонус: 8 метров (1 метр = 32 пикселя)
local RANGE = 8 * 32
local PRISM_COLOR = Color(0x8ee7ff)
local PRISM_SIDES = 6

local function draw_prism_boundary(actor)
    local phase = (Global._current_frame or 0) / 180

    gm.draw_set_alpha(0.55)
    gm.draw_set_colour(PRISM_COLOR)
    for ring = 0, 1 do
        local radius = RANGE - ring * 4
        local offset = phase * (ring == 0 and 1 or -1)
        for i = 0, PRISM_SIDES - 1 do
            local a1 = offset + math.pi * 2 * i / PRISM_SIDES
            local a2 = offset + math.pi * 2 * (i + 1) / PRISM_SIDES
            gm.draw_line(
                actor.x + math.cos(a1) * radius,
                actor.y + math.sin(a1) * radius,
                actor.x + math.cos(a2) * radius,
                actor.y + math.sin(a2) * radius
            )
        end
    end

    gm.draw_set_alpha(0.3)
    for i = 0, PRISM_SIDES - 1 do
        local angle = phase + math.pi * 2 * i / PRISM_SIDES
        local inner = RANGE - 24
        gm.draw_line(
            actor.x + math.cos(angle) * inner,
            actor.y + math.sin(angle) * inner,
            actor.x + math.cos(angle) * RANGE,
            actor.y + math.sin(angle) * RANGE
        )
    end
    gm.draw_set_colour(Color.WHITE)
    gm.draw_set_alpha(1)
end

-- При попадании: если цель дальше 8 метров — усиливаем урон по ней
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if not Net.host then return end

    if stack <= 0 then return end
    if not hit_info or not hit_info.damage or hit_info.damage <= 0 then return end
    if not Instance.exists(victim) then return end

    -- Дистанция между игроком и целью
    local dx = victim.x - actor.x
    local dy = victim.y - actor.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Бонус только по дальним целям: +40% урона за каждый стак
    if dist > RANGE then
        local mult = 1 + 0.40 * stack
        -- У HitInfo в ReturnsAPI нет set_damage: урон удара — три поля, как масштабировал RoMT.
        -- attack_info.damage RoMT тоже переписывал, но attack_info один на все цели атаки,
        -- и у многоцелевой атаки бонус копился бы; проки от attack_info.damage идут без +40%.
        hit_info.damage      = hit_info.damage * mult
        hit_info.damage_true = hit_info.damage_true * mult
        hit_info.damage_fake = hit_info.damage_fake * mult
    end
end)

-- Гранёная граница отмечает зону, в которой бонус к дальнему урону не действует.
DeerItemsCallbacks.item_post_draw(item, function(actor, stack)
    if stack <= 0 then return end
    draw_prism_boundary(actor)
end)
