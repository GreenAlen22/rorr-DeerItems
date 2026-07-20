-- DeerItems-CheatDeath
-- РћР±РјР°РЅ СЃРјРµСЂС‚Рё: 10% (+5% Р·Р° СЃС‚Р°Рє) РїРѕР»СѓС‡РµРЅРЅРѕРіРѕ СѓСЂРѕРЅР° РЅРµ РЅР°РЅРѕСЃРёС‚СЃСЏ СЃСЂР°Р·Сѓ, Р° СЂР°СЃС‚СЏРіРёРІР°РµС‚СЃСЏ
-- РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµРј РЅР° 5 СЃРµРєСѓРЅРґ вЂ” Сѓ С‚РµР±СЏ РїРѕСЏРІР»СЏРµС‚СЃСЏ РѕРєРЅРѕ, С‡С‚РѕР±С‹ РїРµСЂРµС…РёР»РёС‚СЊ СѓРґР°СЂ.
-- (РђРґР°РїС‚Р°С†РёСЏ Shark Teeth РёР· RoR2.)
--
-- Р§С‚Рѕ РїСЂРё 110%: РґРѕР»СЏ В«РѕС‚Р»РѕР¶РµРЅРЅРѕРіРѕВ» СѓСЂРѕРЅР° РћР“Р РђРќРР§Р•РќРђ 100% (math.min). РќР° ~19+ СЃС‚Р°РєР°С…
-- РІРµСЃСЊ СѓРґР°СЂ С†РµР»РёРєРѕРј РїСЂРµРІСЂР°С‰Р°РµС‚СЃСЏ РІ РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ (РјРіРЅРѕРІРµРЅРЅРѕРіРѕ СѓСЂРѕРЅР° РЅРµС‚ РІРѕРІСЃРµ) вЂ” РѕС‚СЃСЋРґР° Рё
-- РЅР°Р·РІР°РЅРёРµ. Р‘РµР· РєР°РїР° РґРѕР»СЏ СѓС€Р»Р° Р±С‹ Р·Р° 100% Рё РїСЂРµРґРјРµС‚ В«СЃРѕР·РґР°РІР°Р»В» Р±С‹ СѓСЂРѕРЅ/Р»РµС‡РµРЅРёРµ РёР· РІРѕР·РґСѓС…Р°.
-- РћРіРѕРІРѕСЂРєР°: РєР°Рє Рё Shark Teeth, РЅРµ СЃРїР°СЃР°РµС‚ РѕС‚ СѓРґР°СЂР°, РєРѕС‚РѕСЂС‹Р№ СѓР±РёРІР°РµС‚ РјРіРЅРѕРІРµРЅРЅРѕ (РµСЃР»Рё HP
-- СѓС€Р»Рѕ РІ 0 РІ С‚РѕС‚ Р¶Рµ РєР°РґСЂ, РєРѕР»Р»Р±РµРє СѓР¶Рµ РЅРµ СѓСЃРїРµРІР°РµС‚ РІРµСЂРЅСѓС‚СЊ Р·РґРѕСЂРѕРІСЊРµ).

-- РЎРїСЂР°Р№С‚ РїСЂРµРґРјРµС‚Р° (РєСЂРѕРІСЊ СЂРёСЃСѓРµС‚ РґРІРёР¶РѕРє С‡РµСЂРµР· С†РІРµС‚ СѓСЂРѕРЅР° DoT)
local sprite = Sprite.new("item/CheatDeath", PATH.."assets/sprites/items/sWhiteItems/CheatDeath.png", 1, 18, 18)

-- Р‘Р°Р»Р°РЅСЃРЅС‹Рµ РєРѕРЅСЃС‚Р°РЅС‚С‹
local BASE_FRAC      = 0.10   -- 10% Р±Р°Р·РѕРІР°СЏ РґРѕР»СЏ СѓРґР°СЂР° СѓС…РѕРґРёС‚ РІ РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ
local FRAC_PER_STACK = 0.05   -- +5% Р·Р° СЃС‚Р°Рє
local DOT_TICKS      = 10     -- С‡РёСЃР»Рѕ С‚РёРєРѕРІ РєСЂРѕРІРѕС‚РµС‡РµРЅРёСЏ
local DOT_RATE       = 30     -- РєР°РґСЂРѕРІ РјРµР¶РґСѓ С‚РёРєР°РјРё (30 = 0.5 СЃРµРє) в†’ 10 Г— 0.5 = 5 СЃРµРєСѓРЅРґ

-- РЎРѕР·РґР°РЅРёРµ РїСЂРµРґРјРµС‚Р°: Р±РµР»С‹Р№ С‚РёСЂ, С‚РµРі В«Р»РµС‡РµРЅРёРµВ» (РїРѕ СЃСѓС‚Рё РїСЂРѕ Р¶РёРІСѓС‡РµСЃС‚СЊ)
local item = Item.new("CheatDeath")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_HEALING
local GUID = _ENV["!guid"]
local DAMAGE_TEXT_LIFE = 45

local objDamageText = Object.new("CheatDeathDamageText")
objDamageText:set_depth(-1000)
objDamageText:onCreate(function(self)
    self.amount = 0
    self.life = DAMAGE_TEXT_LIFE
    self.max_life = DAMAGE_TEXT_LIFE
    self.vx = 0
    self.vy = -0.45
end)
objDamageText:onStep(function(self)
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.life = self.life - 1
    if self.life <= 0 then self:destroy() end
end)
objDamageText:onDraw(function(self)
    local alpha = math.max(0, self.life / self.max_life)
    gm.draw_set_alpha(alpha)
    gm.draw_set_colour(Color.RED)
    gm.draw_text(self.x, self.y, string.format("%d", self.amount))
    gm.draw_set_colour(Color.WHITE)
    gm.draw_set_alpha(1)
end)

local function add_delayed_damage(actor, total)
    local data = actor:get_data("CheatDeath", GUID)
    if not data.cd_ticks then data.cd_ticks = {} end
    table.insert(data.cd_ticks, {
        damage = total / DOT_TICKS,
        ticks = DOT_TICKS,
        timer = DOT_RATE,
    })
end

local function clear_delayed_damage(actor)
    if not actor or not Instance.exists(actor) then return end
    actor:get_data("CheatDeath", GUID).cd_ticks = nil
end

-- HP СѓРґР°Р»С‘РЅРЅРѕРіРѕ РёРіСЂРѕРєР° РјРµРЅСЏРµС‚ РµРіРѕ РєР»РёРµРЅС‚. РџРѕСЃР»Рµ СЃРјРµСЂС‚Рё С…РѕСЃС‚ С‚РѕР¶Рµ РѕР±СЏР·Р°РЅ СѓР±СЂР°С‚СЊ
-- РѕСЃС‚Р°РІС€РёР№СЃСЏ РѕС‚Р»РѕР¶РµРЅРЅС‹Р№ СѓСЂРѕРЅ, РёРЅР°С‡Рµ СЃР»РµРґСѓСЋС‰РёР№ С‚РёРє СѓР±СЊС‘С‚ СѓР¶Рµ РІРѕСЃРєСЂРµС€С‘РЅРЅРѕРіРѕ РёРіСЂРѕРєР°,
-- С…РѕС‚СЏ С…РѕСЃС‚ РІСЃС‘ РµС‰С‘ Р±СѓРґРµС‚ СЃС‡РёС‚Р°С‚СЊ РµРіРѕ Р¶РёРІС‹Рј.
DeerItemsPlayerDeath.on_host(clear_delayed_damage)

local function is_invincible(actor)
    local invincible = actor.invincible
    return invincible == true or (type(invincible) == "number" and invincible > 0)
end

local function spawn_damage_text(actor, amount)
    local inst = objDamageText:create(actor.x + math.random(-8, 8), actor.y - 42)
    inst.amount = math.max(1, math.floor(amount + 0.5))
    inst.vx = math.random(-6, 6) / 20
end

local function deal_internal_damage(actor, amount)
    if amount <= 0 or actor.hp <= 0 or is_invincible(actor) then return false end

    actor.hp = actor.hp - amount
    if actor.hp <= 0 then
        actor.hp = -1000000
    end
    spawn_damage_text(actor, amount)
    return true
end

-- HP СѓРґР°Р»С‘РЅРЅРѕРіРѕ РёРіСЂРѕРєР° РїСЂРёРЅР°РґР»РµР¶РёС‚ РµРіРѕ РєР»РёРµРЅС‚Сѓ. РҐРѕСЃС‚ Р»РёС€СЊ РІРµРґС‘С‚ РѕР±С‰РёР№ С‚Р°Р№РјРµСЂ debt Рё
-- РїРµСЂРµРґР°С‘С‚ РІР»Р°РґРµР»СЊС†Сѓ РёС‚РѕРі РїРµСЂРІРѕРіРѕ РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёСЏ Рё РєР°Р¶РґС‹Р№ РїРѕСЃР»РµРґСѓСЋС‰РёР№ С‚РёРє.
local packet_restore = Packet.new("CheatDeath-packet_restore")
local packet_tick = Packet.new("CheatDeath-packet_tick")

packet_restore:set_serializers(function(buffer, actor, hp)
    buffer:write_instance(actor)
    buffer:write_float(hp)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local hp = buffer:read_float()
    if not Instance.exists(actor) or not actor:same(Player.get_client()) then return end
    actor.hp = math.min(actor.maxhp, hp)
end)

packet_tick:set_serializers(function(buffer, actor, amount)
    buffer:write_instance(actor)
    buffer:write_float(amount)
end, function(buffer)
    if not Net.client then return end

    local actor = buffer:read_instance()
    local amount = buffer:read_float()
    if not Instance.exists(actor) or not actor:same(Player.get_client()) then return end
    deal_internal_damage(actor, amount)
end)

local function send_restore(actor)
    if not Net.host then return end
    packet_restore:send_to_all(actor, actor.hp)
end

local function send_tick(actor, amount)
    if not Net.host then return end
    packet_tick:send_to_all(actor, amount)
end

item:onDamagedProc(function(actor, attacker, stack, hit_info)
    if stack <= 0 then return end
    -- РљР РРўРР§РќРћ: РїСЂРѕРїСѓСЃРєР°РµРј СѓСЂРѕРЅ РѕС‚ СЃР°РјРѕРіРѕ СЃРµР±СЏ. РРЅР°С‡Рµ С‚РёРєРё РќРђРЁР•Р“Рћ Р¶Рµ РєСЂРѕРІРѕС‚РµС‡РµРЅРёСЏ СЃРЅРѕРІР°
    -- Р·Р°С€Р»Рё Р±С‹ СЃСЋРґР° Рё РїР»РѕРґРёР»Рё РЅРѕРІС‹Рµ DoT (РЅР° 100% РґРѕР»Рµ вЂ” Р»Р°РІРёРЅРѕРѕР±СЂР°Р·РЅРѕ).
    if attacker and actor:same(attacker) then return end

    local dmg = hit_info and (hit_info.damage or 0) or 0
    if dmg <= 0 then return end

    -- Р”РѕР»СЏ СѓРґР°СЂР° РІ РєСЂРѕРІРѕС‚РµС‡РµРЅРёРµ, СЃ Р¶С‘СЃС‚РєРёРј РєР°РїРѕРј 100%
    local frac = math.min(1.0, BASE_FRAC + FRAC_PER_STACK * (stack - 1))
    local total = dmg * frac

    local is_client = Net.client
    if is_client and not actor:same(Player.get_client()) then return end

    -- Р’РѕР·РІСЂР°С‰Р°РµРј РѕС‚Р»РѕР¶РµРЅРЅСѓСЋ С‡Р°СЃС‚СЊ HP РІ С‚РѕРј Р¶Рµ РєР°РґСЂРµ. actor:heal() РїСЂРёРјРµРЅСЏРµС‚СЃСЏ СЃРµС‚РµРІС‹Рј
    -- СЃРѕР±С‹С‚РёРµРј РїРѕР·РґРЅРµРµ, РїРѕСЌС‚РѕРјСѓ РєР»РёРµРЅС‚ СѓСЃРїРµРІР°Р» СѓРІРёРґРµС‚СЊ РїРѕР»РЅС‹Р№ РёСЃС…РѕРґРЅС‹Р№ СѓСЂРѕРЅ.
    actor.hp = math.min(actor.maxhp, actor.hp + total)

    -- Р›РѕРєР°Р»СЊРЅС‹Р№ РёРіСЂРѕРє РїРѕР»СѓС‡Р°РµС‚ РјРіРЅРѕРІРµРЅРЅСѓСЋ РїСЂРµРґРёРєС†РёСЋ; СЃР°Рј debt Рё РїРѕСЃР»РµРґСѓСЋС‰РёРµ С‚РёРєРё
    -- СЂР°СЃСЃС‡РёС‚С‹РІР°РµС‚ С‚РѕР»СЊРєРѕ С…РѕСЃС‚.
    if is_client then return end

    if not actor:same(Player.get_client()) then send_restore(actor) end
    -- ...Рё СЃРїРёСЃС‹РІР°РµРј РµС‘ РєР°Рє HP-only debt: СЌС‚Рѕ РЅРµ РЅРѕРІС‹Р№ damage event Рё РЅРµ РїСЂРѕРєР°РµС‚ on-damaged РїСЂРµРґРјРµС‚С‹.
    add_delayed_damage(actor, total)
end)

Actor:onPostStep("DeerItems-CheatDeathTicks", function(actor)
    if Net.client then return end

    local data = actor:get_data("CheatDeath", GUID)
    local ticks = data.cd_ticks
    if not ticks then return end

    for i = #ticks, 1, -1 do
        local tick = ticks[i]
        tick.timer = tick.timer - 1
        if tick.timer <= 0 then
            if actor:same(Player.get_client()) then
                deal_internal_damage(actor, tick.damage)
            else
                send_tick(actor, tick.damage)
            end
            tick.ticks = tick.ticks - 1
            if tick.ticks <= 0 then
                table.remove(ticks, i)
            else
                tick.timer = DOT_RATE
            end
        end
    end

    if #ticks == 0 then data.cd_ticks = nil end
end)
