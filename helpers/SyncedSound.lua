-- Звук в точке мира для всех игроков, когда его решает одна машина.
local M = {}

-- Для кода, который идёт не на каждой машине: колбэки попадания, убийства и урона
-- зовёт только хост, ветки за Net.client — тоже. play_synced сам играет звук и шлёт
-- его остальным (Sound.lua:201), но шлёт и офлайн, поэтому без сети играем локально.
-- Звук, который каждая машина и так проигрывает сама, сюда не нести: выйдет дважды.
function M.play_at(sound, x, y, volume, pitch)
    if Net.online then
        sound:play_synced(x, y, volume, pitch)
    else
        sound:play(x, y, volume, pitch)
    end
end

DeerItemsSound = M
return M
