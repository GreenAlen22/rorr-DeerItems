-- Точка входа мода: подключает зависимости, загружает контент и применяет настройки предметов.
log.info("Загрузка мода: " .. _ENV["!guid"] .. ".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace = "DeerItems",
    mp = true
}
PATH = _ENV["!plugins_mod_folder_path"].."/"

require("./settings/ItemManifest")
require("./settings/ItemConfig")
local item_config = DeerItemsItemConfig
if not item_config then error("DeerItems failed to load item config") end

-- Keep the original loader semantics: the item directory is the source of
-- executable content, while ItemManifest controls availability settings.
local function require_items()
    for _, file in ipairs(path.get_files(PATH.."items")) do
        require(file)
    end
end

-- These non-item modules have no availability configuration and are loaded in a
-- deliberate order after vanilla content is ready.
Initialize.add(function()
    require("./helpers/ReturnsCallbacks")
    require("./Interactables/StandingRequisitionChest")
    require("./actor/Cernunnos")
    require("./elite/Bramble")
    require("./elite/Rusted")
    require("./helpers/ArtifactPlayerDeath")
    require("./helpers/ArtifactTeleporter")
    require("./artifacts/ArtefactOfDroneman")
    require("./artifacts/ArtefactOfTechnician")
    require("./artifacts/ArtifactOfStagnation")
    require("./artifacts/ArtifactOfStorm")
    require("./artifacts/ArtifactOfVictory")
    require_items()

    item_config.reload()
    local enabled_count, disabled_count = item_config.apply_availability()

    log.info("DeerItems registered all items; enabled "..enabled_count.." configured drops; disabled "..disabled_count..".")
end)
