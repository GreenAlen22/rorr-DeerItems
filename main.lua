-- Точка входа мода: подключает зависимости, загружает контент и применяет настройки предметов.
log.info("Загрузка мода: " .. _ENV["!guid"] .. ".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace = "DeerItems",
    mp = true
}
PATH = _ENV["!plugins_mod_folder_path"].."/"

-- LuaENVY's import preserves the DeerItems environment for every loaded module.
-- Native require resolves against LuaENVY once initialization callbacks run.
-- `import` is the global LuaENVY puts into the mod environment: the value returned
-- by envy.auto() is nil on hotload, when the environment is already set up.
local function import_local(module_path)
    return import(module_path..".lua")
end

import_local("settings/ItemManifest")
import_local("settings/ItemConfig")
local item_config = DeerItemsItemConfig
if not item_config then error("DeerItems failed to load item config") end

-- The manifest is the source of truth for both item modules and availability.
local function require_items()
    for _, category in ipairs(DeerItemsItemManifest.categories) do
        for _, item in ipairs(category.items) do
            import_local("items/"..category.key.."/"..item.id)
            for _, dependency in ipairs(item.dependencies or {}) do
                import_local("items/"..category.key.."/"..dependency)
            end
        end
    end
end

local function register_item_logs()
    for _, category in ipairs(DeerItemsItemManifest.categories) do
        local finder = category.key == "Equipments" and Equipment.find or Item.find
        for _, item in ipairs(category.items) do
            local registered_item = finder(item.id, "DeerItems")
            if not registered_item then
                error("DeerItems failed to register "..category.key.."/"..item.id)
            end

            -- ReturnsAPI keeps item-log creation separate from Item/Equipment.new.
            -- Only public manifest entries belong in the log.
            if category.key == "Equipments" then
                ItemLog.new_from_equipment(registered_item)
            else
                ItemLog.new_from_item(registered_item)
            end
        end
    end
end

-- These non-item modules have no availability configuration and are loaded in a
-- deliberate order after vanilla content is ready.
Initialize.add(function()
    import_local("helpers/ReturnsCallbacks")
    import_local("helpers/ItemPool")
    import_local("helpers/Gold")
    import_local("helpers/SyncedSound")
    import_local("helpers/GroundSpikes")
    import_local("Interactables/StandingRequisitionChest")
    import_local("actor/Cernunnos")
    import_local("elite/Bramble")
    import_local("elite/Rusted")
    import_local("helpers/ArtifactPlayerDeath")
    import_local("helpers/ArtifactTeleporter")
    import_local("artifacts/ArtefactOfDroneman")
    import_local("artifacts/ArtefactOfTechnician")
    import_local("artifacts/ArtifactOfStagnation")
    import_local("artifacts/ArtifactOfStorm")
    import_local("artifacts/ArtifactOfVictory")
    require_items()
    register_item_logs()

    item_config.reload()
    local enabled_count, disabled_count = item_config.apply_availability()

    log.info("DeerItems registered all items; enabled "..enabled_count.." configured drops; disabled "..disabled_count..".")

    import_local("helpers/DebugCommands")
end)
