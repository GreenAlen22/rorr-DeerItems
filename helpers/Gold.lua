-- Золото предметов: начисление в кошелёк этой машины и доставка держателю-клиенту.
local M = {}

-- Кошелёк у каждой машины свой (oHUD.gold), а награду часть предметов считает в колбэках,
-- которые зовёт только хост: ON_KILL_PROC (scr_actor_death.gml:231-273), ON_HIT_PROC и
-- ON_DAMAGED_PROC (клиент выходит из damager_attack_process до damager_hit_process).
-- Клиенту-держателю сумма идёт пакетом.
local packet = Packet.new("Gold-pay")

-- Метод oHUD.add_gold (oHUD_Create_0.gml:175): через него идёт всё золото машины — сферы
-- (oEfGold), Life Savings, камни, выплаты мода через add_local. Предметы на приход золота
-- хукают его, а не каждый источник по отдельности. Имя метода — по образцу ReturnsAPI
-- (`achievement_unlocked@gml_Object_oInit_Create_0`).
M.ADD_GOLD = gm.constants["add_gold@gml_Object_oHUD_Create_0"]
if not M.ADD_GOLD then error("DeerItems: oHUD.add_gold is missing from gm.constants") end

-- oHUD.add_gold, а не hud.gold +=: ваниль там же пишет game_report.total_gold и считает
-- ачивку Golden Gun (oHUD_Create_0.gml:175-188). oP.gold локального игрока догоняет
-- HUD сам (step_player.gml:440-448). Instance.find всегда отдаёт обёртку, а метод,
-- взятый с обёртки, привязан к ней как self (Instance.lua:713-719).
function M.add_local(amount)
    if amount <= 0 then return end
    local hud = Instance.find(gm.constants.oHUD)
    if hud == Instance.INVALID then return end
    hud.add_gold(amount)
end

packet:set_serializers(function(buffer, amount)
    buffer:write_double(amount)
end, function(buffer)
    local amount = buffer:read_double()
    if not Net.client then return end
    M.add_local(amount)
end)

-- Награда держателю-игроку за событие, которое видит только хост. Без сети все игроки
-- локальные и делят один oHUD.
function M.pay(actor, amount)
    if Net.client then error("DeerItemsGold.pay must be called on host") end
    if amount <= 0 then return end
    if actor.object_index ~= gm.constants.oP then return end

    if not Net.online or actor == Player.get_local() then
        M.add_local(amount)
    else
        packet:send_direct(actor, amount)
    end
end

DeerItemsGold = M
return M
