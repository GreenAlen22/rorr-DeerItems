-- DeerItems-Totemetry
-- Р Р°Р· РІ 2 РјРёРЅСѓС‚С‹ СЃРїР°РІРЅРёС‚ С‚РѕС‚РµРј, Р»РµС‡Р°С‰РёР№ РІСЃРµС… СЃРѕСЋР·РЅРёРєРѕРІ РІ СЂР°РґРёСѓСЃРµ. РўР°РєР¶Рµ РґР°С‘С‚ РІР»Р°РґРµР»СЊС†Сѓ +10% СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё РЅР° 45 СЃРµРє.

-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р°
-- Р—Р°РіСЂСѓР¶Р°РµРј СЃРїСЂР°Р№С‚ С‚РѕС‚РµРјР°
-- Р—Р°РіСЂСѓР¶Р°РµРј Р·РІСѓРєРѕРІРѕР№ СЌС„С„РµРєС‚
local sprite = Sprite.new("item/Totemetry", PATH.."assets/sprites/items/sGreenItems/Totemetry.png", 1, 16, 16)
local LevelTotem = Sprite.new("particle/LevelTotem", PATH.."assets/sprites/particle/LevelTotem.png", 1, 100, 180)
local sound = Sound.new("sound/Totemetry", PATH.."assets/sounds/Totemetry.ogg")

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р° Totemetry
-- РџСЂРёРІСЏР·РєР° СЃРїСЂР°Р№С‚Р° Рє РїСЂРµРґРјРµС‚Сѓ
-- РЈСЃС‚Р°РЅРѕРІРєР° С‚РёСЂР° РїСЂРµРґРјРµС‚Р°: Р·РµР»С‘РЅС‹Р№ (РЅРµРѕР±С‹С‡РЅС‹Р№)
-- РќР°Р·РЅР°С‡РµРЅРёРµ С‚РµРіР° Р»СѓС‚Р°: РїСЂРµРґРјРµС‚, РїРѕРІС‹С€Р°СЋС‰РёР№ Р¶РёРІСѓС‡РµСЃС‚СЊ
local item = Item.new("Totemetry")
item:set_sprite(sprite)
item:set_tier(ItemTier.UNCOMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING + Item.LootTag.ITEM_BLACKLIST_ENGI_TURRETS

-- РљРѕРЅСЃС‚Р°РЅС‚С‹ РїРѕРІРµРґРµРЅРёСЏ С‚РѕС‚РµРјР°
local RADIUS_BASE   = 7.5 * 32 * 2      -- Р‘Р°Р·РѕРІС‹Р№ СЂР°РґРёСѓСЃ (480 px)
local RADIUS_STACK  = 2 * 32 * 2        -- РЈРІРµР»РёС‡РµРЅРёРµ СЂР°РґРёСѓСЃР° Р·Р° СЃС‚Р°Рє
local HEAL_TICK     = 180               -- РџРµСЂРёРѕРґ Р»РµС‡РµРЅРёСЏ: СЂР°Р· РІ 3 СЃРµРє
local TOTEM_LIFE    = 60 * 45           -- Р’СЂРµРјСЏ Р¶РёР·РЅРё С‚РѕС‚РµРјР°: 45 СЃРµРє
local COOLDOWN      = 60 * 120          -- Р’СЂРµРјСЏ РєСѓР»РґР°СѓРЅР°: 2 РјРёРЅСѓС‚С‹
local AS_BUFF_TIME  = TOTEM_LIFE        -- Р”Р»РёС‚РµР»СЊРЅРѕСЃС‚СЊ Р±РѕРЅСѓСЃР° Рє Р°С‚Р°Рє-СЃРїРёРґСѓ: 45 СЃРµРє

-- Р¦РІРµС‚ РѕС‚СЂРёСЃРѕРІРєРё СЂР°РґРёСѓСЃР° С‚РѕС‚РµРјР° вЂ” СЃРѕР·РґР°С‘С‚СЃСЏ РѕРґРёРЅ СЂР°Р·, Р° РЅРµ РєР°Р¶РґС‹Р№ РєР°РґСЂ РІ onDraw
local TOTEM_COLOR   = Color(0x63494f)

-- РћР±СЉРµРєС‚ С‚РѕС‚РµРјР°
local objTotem = Object.new("EfHealingTotem")
objTotem.obj_sprite = LevelTotem
objTotem.obj_depth = 50
-- РџСЂРё СЃРѕР·РґР°РЅРёРё С‚РѕС‚РµРјР°
Callback.add(objTotem.on_create, function(self)
    self.life = TOTEM_LIFE
    self.radius = RADIUS_BASE
    self.stack = 1
    self:instance_sync()
end)

-- РџРѕРІРµРґРµРЅРёРµ С‚РѕС‚РµРјР°: Р»РµС‡РµРЅРёРµ СЃРѕСЋР·РЅРёРєРѕРІ РІ СЂР°РґРёСѓСЃРµ СЂР°Р· РІ 3 СЃРµРєСѓРЅРґС‹
Callback.add(objTotem.on_step, function(self)
    if Net.client then return end

    self.life = self.life - 1
    if self.life <= 0 then self:destroy(); return end

    if Global._current_frame % HEAL_TICK == 0 then
        local targets = List.wrap(self:find_characters_circle(self.x, self.y - 40, self.radius, false, 1, true))
        for _, actor in ipairs(targets) do
            local heal = actor.maxhp * (0.02 * self.stack) -- 2% +2% Р·Р° СЃС‚Р°Рє
            actor:heal(heal)
        end
    end
end)

-- Р’РёР·СѓР°Р»РёР·Р°С†РёСЏ СЂР°РґРёСѓСЃР° С‚РѕС‚РµРјР°
Callback.add(objTotem.on_draw, function(self)
    -- РљРѕРѕСЂРґРёРЅР°С‚С‹ Рё СЂР°РґРёСѓСЃ С‡РёС‚Р°РµРј РёР· РёРЅСЃС‚Р°РЅСЃР° РѕРґРёРЅ СЂР°Р· Р·Р° РєР°РґСЂ
    local x, y, r = self.x, self.y - 40, self.radius
    gm.draw_set_colour(TOTEM_COLOR)
    gm.draw_circle(x, y, r, true)
    gm.draw_circle(x, y, r / 3, true)
    gm.draw_rectangle(x - r / 1.2, y - r / 1.2, x + r / 1.2, y + r / 1.2, true)
    gm.draw_roundrect(x - r / 1.4, y - r / 1.4, x + r / 1.4, y + r / 1.4, true)
end)

-- РЎРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏ РїСЂРё СѓРґР°Р»РµРЅРёРё
Callback.add(objTotem.on_destroy, function(self)
    self:instance_destroy_sync()
end)

-- РЎР»РѕРІР°СЂРё РґР»СЏ РѕС‚СЃР»РµР¶РёРІР°РЅРёСЏ РІСЂРµРјРµРЅРё РґРµР№СЃС‚РІРёСЏ Р±РѕРЅСѓСЃРѕРІ
local last_totem_frame = {}   -- [actor.id] в†’ РєР°РґСЂ РїРѕСЃР»РµРґРЅРµРіРѕ СЃРїР°РІРЅР°
local as_buff_until    = {}   -- [actor.id] в†’ РґРѕ РєР°РєРѕРіРѕ РєР°РґСЂР° Р°РєС‚РёРІРµРЅ Р°С‚Р°Рє-СЃРїРёРґ Р±Р°С„С„

-- РћС‡РёСЃС‚РєР° РєРѕР»Р»Р±РµРєРѕРІ
-- РџСЂРѕРІРµСЂРєР° РІСЂРµРјРµРЅРё Рё СЃРїР°РІРЅ С‚РѕС‚РµРјР° (РєР°Р¶РґС‹Рµ 2 РјРёРЅСѓС‚С‹)
DeerItemsCallbacks.item_pre_step(item, function(actor, stack)
    if Net.client then return end

    local now = Global._current_frame
    local next_frame = (last_totem_frame[actor.id] or -10000) + COOLDOWN

    if now >= next_frame then
        -- Р’РѕСЃРїСЂРѕРёР·РІРѕРґРёРј Р·РІСѓРє
        actor:sound_play(sound, 2.0, 0.9 + math.random() * 0.5)

        -- РЎРїР°РІРЅРёРј С‚РѕС‚РµРј
        local inst = objTotem:create(actor.x, actor.y)
        inst.radius = RADIUS_BASE + RADIUS_STACK * (stack - 1)
        inst.stack = stack

        -- РћР±РЅРѕРІР»СЏРµРј С‚Р°Р№РјРµСЂС‹
        last_totem_frame[actor.id] = now
        as_buff_until[actor.id] = now + AS_BUFF_TIME
    end
end)

-- Р‘РѕРЅСѓСЃ Рє СЃРєРѕСЂРѕСЃС‚Рё Р°С‚Р°РєРё, РµСЃР»Рё Р°РєС‚РёРІРµРЅ СЌС„С„РµРєС‚
DeerItemsCallbacks.item_stat_recalc(item, function(actor, stack)
    local until_frame = as_buff_until[actor.id]
    if until_frame and Global._current_frame < until_frame then
        actor.attack_speed = actor.attack_speed * 1.10
    end
end)
