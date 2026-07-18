log.info("Загрузка мода: " .. _ENV["!guid"] .. ".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace = "DeerItems",
    mp = true
}
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
PATH = _ENV["!plugins_mod_folder_path"].."/"

local function file_basename(file_path)
    return file_path:gsub("\\", "/"):match("([^/]+)$")
end

local function require_file(folder_path, file_name)
    for _, name in ipairs(path.get_files(folder_path)) do
        if file_basename(name) == file_name then
            require(name)
            return
        end
    end

    error("DeerItems failed to find "..file_name)
end

require_file(PATH.."settings", "ItemManifest.lua")
require_file(PATH.."settings", "ItemConfig.lua")
local item_config = DeerItemsItemConfig
if not item_config then error("DeerItems failed to load item config") end

local item_files
local item_file_list

local function require_items()
    if not item_files then
        item_files = {}
        item_file_list = {}

        for _, name in ipairs(path.get_files(PATH.."items")) do
            local normalized = name:gsub("\\", "/")
            local category, file_name = normalized:match("/items/([^/]+)/([^/]+%.lua)$")
            if category and file_name then
                item_files[category.."/"..file_name] = name
                table.insert(item_file_list, name)
            end
        end
    end

    for _, require_name in ipairs(item_file_list) do
        require(require_name)
    end
end

local function require_folder(folder_path)
    for _, name in ipairs(path.get_files(folder_path)) do
        require(name)
    end
end

Initialize(function()
    require_folder(PATH.."Interactables")
    require_folder(PATH.."actor")
    require_folder(PATH.."helpers")
    require_folder(PATH.."artifacts")
    require_items()

    item_config.reload()
    local enabled_count, disabled_count = item_config.apply_availability()

    log.info("DeerItems registered all items; enabled "..enabled_count.." configured drops; disabled "..disabled_count..".")
end)
