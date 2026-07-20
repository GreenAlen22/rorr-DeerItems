-- Точка входа мода: подключает зависимости, загружает контент и применяет настройки предметов.
log.info("Загрузка мода: " .. _ENV["!guid"] .. ".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace = "DeerItems",
    mp = true
}
PATH = _ENV["!plugins_mod_folder_path"].."/"

-- Manifest is the single source of truth for item files and availability.
require("./settings/ItemManifest")
require("./settings/ItemConfig")
local item_config = DeerItemsItemConfig
if not item_config then error("DeerItems failed to load item config") end

-- Loads every item declared by the manifest, including hidden dependency items.
local function require_items()
    for _, category in ipairs(DeerItemsItemManifest.categories) do
        for _, item in ipairs(category.items) do
            require("./items/"..category.key.."/"..item.id)
            for _, dependency in ipairs(item.dependencies or {}) do
                require("./items/"..category.key.."/"..dependency)
            end
        end
    end
end

-- These non-item modules have no availability configuration and are loaded in a
-- deliberate order after vanilla content is ready.
Initialize.add(function()
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
