-- DeerItems-RustMite / «Ржавый клещ» / "Rust Mite"
-- Порт Symbiotic Scorpion из RoR2.
-- 100% при попадании вешает «ржавчину» на цель (навсегда, стаки не спадают).
-- Каждый стак ржавчины увеличивает ВЕСЬ получаемый целью урон на +4%.
--
-- Почему не «минус броня»: в RoRR отрицательная броня НЕ усиливает урон (движок считает
-- броню <= 0 как «нет снижения»), поэтому уводить её в минус бессмысленно. Вместо этого
-- усиливаем итоговый урон по цели напрямую в хуке расчёта урона (damager_calculate_damage) —
-- эффект гарантирован и работает от ЛЮБОГО источника урона.

-- Спрайт предмета и иконка дебаффа (болванки из template — замени текстуры по этим путям).
local sprite     = Sprite.new("item/RustMite", PATH.."assets/sprites/items/sRedItems/RustMite.png", 1, 18, 18)
local buffSprite = Sprite.new("buff/RustMite", PATH.."assets/sprites/buffs/RustMite.png", 1, 7, 7)

-- guid мода: ускоряет get_data
local GUID = _ENV["!guid"]

-- Настройки баланса
local DMG_PER_STACK = 0.04   -- +4% получаемого урона за каждый стак «ржавчины»
local MAX_STACKS    = 100    -- тех. предел стаков на ОДНУ цель (макс +400% урона);
                             -- высокий, на обычной игре не ощущается, ловит только runaway.

-- Дебафф «ржавчина»: постоянный, глубоко стакающийся. Носитель стаков + иконка.
-- Сам по себе статы не трогает — усиление урона делает хук ниже.
local buff = Buff.new("RustMite")
buff.icon_sprite         = buffSprite
buff.icon_stack_subimage = false
buff.draw_stack_number   = true
buff.stack_number_col    = Array.new(1, Color(0xb5651d))   -- ржаво-оранжевый
buff.max_stack = 999
buff.is_timed  = false     -- стаки НЕ спадают по времени = «навсегда»
buff.is_debuff = true
-- Предмет
local item = Item.new("RustMite")
item:set_sprite(sprite)
item:set_tier(ItemTier.RARE)
item.loot_tags = Item.LootTag.CATEGORY_DAMAGE
-- При попадании (100% шанс): вешаем цели стаки ржавчины = числу стаков предмета.
-- Коллбэк урона НЕ наносит → самопрок невозможен, proc=false не нужен.
DeerItemsCallbacks.item_hit_proc(item, function(actor, victim, stack, hit_info)
    if stack <= 0 then return end
    if not Net.host then return end           -- стаки вешаем на хосте (синк движком)
    if not (victim and Instance.exists(victim)) then return end
    if gm.object_is_ancestor(victim.object_index, gm.constants.pActor) ~= 1.0 then return end  -- только акторы

    local cur = victim:buff_count(buff)
    if cur >= MAX_STACKS then return end
    local add = math.min(stack, MAX_STACKS - cur)          -- +1 стак на попадание за каждый стак предмета
    if add <= 0 then return end

    victim:buff_apply(buff, 1, add)
end)

-- Усиление получаемого урона: до расчёта урона домножаем входящий урон по цели,
-- если на ней висит «ржавчина». Бьёт по итогу для ЛЮБОГО источника (игрок, союзники, эффекты).
-- В pcall: если в этой версии тулкита иная сигнатура/имя функции — фича просто выключится.
pcall(function()
    gm.pre_script_hook(gm.constants.damager_calculate_damage, function(self, other, result, args)
        local v = args[2] and args[2].value
        if not v then return end
        v = Instance.wrap(v)
        if not Instance.exists(v) then return end
        -- buff_stack_count есть только у акторов; не-акторы (бочки/ящики) тоже идут через расчёт урона.
        if gm.object_is_ancestor(v.object_index, gm.constants.pActor) ~= 1.0 then return end

        local s = v:buff_count(buff)
        if not s or s <= 0 then return end
        if s > MAX_STACKS then s = MAX_STACKS end

        local dmg = args[4] and args[4].value
        if not dmg then return end
        args[4].value = dmg * (1 + DMG_PER_STACK * s)
    end)
end)
