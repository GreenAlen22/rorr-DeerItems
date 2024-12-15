local envy = mods["MGReturns-ENVY"]
envy.auto()
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()
Cooldown = mods["Klehrik-CooldownHelper"].setup()

PATH = _ENV["!plugins_mod_folder_path"].."/"

Initialize(function()
    -- Require all files in content folders
    local folders = {
        "items",
        "equipment",
    }
    for _, folder in ipairs(folders) do
        local names = path.get_files(PATH..folder)
        for _, name in ipairs(names) do require(name) end
    end
end)