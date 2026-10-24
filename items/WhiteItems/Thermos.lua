-- DeerItems-Thermos / «Термос» / "Thermos"
-- Положительные эффекты держателя длятся на 25% (+25% за стак, гиперболически) дольше.

local sprite = Sprite.new("item/Thermos", PATH.."assets/sprites/items/sWhiteItems/Thermos.png", 1, 18, 18)

-- Стак гиперболический (Util.mixed_hyperbolic): 1 → +25%, 4 → +50%, 20 → +83%, к +100% не
-- доходит. На линейном Prescriptions (8 с при КД 45 с) рано или поздно висели бы без перерыва.
local BONUS = 0.25

-- Флаг is_debuff для ванили бесполезен: buff_create ставит его всем (scr_buff.gml:41), игра
-- его не читает. Поэтому хорошие эффекты перечислены явно.
-- Не вошли: medkit (задержка перед лечением), cape/capeImmunity, reflectorCharge, reflecting,
-- shadowClone, hourglassCd, tentacleCd, dice, droneEmpower, mercAfterimage — внутренние таймеры;
-- loaderSpeed2 и poisonSpeedBoost — продлеваются умением каждые 2–15 кадров, удлинение меняет
-- ощущение умения; superShield и hot2 — их накладывают только боссам и ИИ; burstSpeed, hot,
-- dash, attackSpeed — в коде игры их никто не накладывает; VioletFrenzy — маркер, его таймер
-- живёт в данных предмета.
local ALLOWED_NAMES = {
    ror = {
        "overclock", "loaderShield", "redWhip", "harpoon", "smokebomb", "pills", "leech",
        "pillage", "banditSkull", "arcaneBlades", "handDroneSpeed", "warbanner", "umbrella",
    },
    DeerItems = {
        "OneArmyMan", "TacticalVisor", "TotemetryAttackSpeed", "Energize", "Accountant",
        "ShadowShield", "ThinWings",
    },
}

local item = Item.new("Thermos")
item:set_sprite(sprite)
item:set_tier(ItemTier.COMMON)
item.loot_tags = Item.LootTag.CATEGORY_UTILITY

-- Баффы мода регистрируются файлами, которые грузятся после этого (зелёные и красные
-- предметы, снаряжение), поэтому набор собирается при первом наложении, а не при загрузке.
local allowed

local function build_allowed()
    local set = {}
    for namespace, names in pairs(ALLOWED_NAMES) do
        for _, name in ipairs(names) do
            local buff = Buff.find(name, namespace)
            if not buff then error("Thermos: buff "..namespace.."-"..name.." not found") end
            set[buff.value] = true
        end
    end
    return set
end

local function duration_mult(stack)
    return 1 + Util.mixed_hyperbolic(stack, BONUS)
end

-- apply_buff и set_buff_time: (цель, id баффа, длительность в кадрах). Хук на apply_buff, а не на
-- apply_buff_internal: хост шлёт клиентам уже удлинённое значение (apply_buff.gml:7).
-- set_buff_time — путь повторного включения снаряжения при живом баффе (apply_equipment_buff).
local function extend(self, other, result, args)
    local duration = args[3] and args[3].value
    if type(duration) ~= "number" or duration <= 0 then return end

    allowed = allowed or build_allowed()
    if not allowed[args[2].value] then return end

    -- Ваниль передаёт и CInstance, и голый id (`apply_buff(id, …)`); Instance.wrap берёт оба.
    local target = Instance.wrap(args[1].value)
    if target == Instance.INVALID or not Instance.exists(target) then return end
    local stack = target:item_count(item, Item.StackKind.ANY) or 0
    if stack <= 0 then return end

    args[3].value = math.floor(duration * duration_mult(stack))
end

Hook.add_pre(gm.constants.apply_buff, extend)
Hook.add_pre(gm.constants.set_buff_time, extend)
