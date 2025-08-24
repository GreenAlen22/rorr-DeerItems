log.info("Загрузка мода: " .. _ENV["!guid"] .. ".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
PATH = _ENV["!plugins_mod_folder_path"].."/"


Initialize(function()
    -- Require all files in content folders
    local folders = {
        "items",
    }
    for _, folder in ipairs(folders) do
        local names = path.get_files(PATH..folder)
        for _, name in ipairs(names) do require(name) end
    end
end)