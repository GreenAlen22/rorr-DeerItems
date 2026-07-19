-- Читает настройки доступности предметов, создаёт пункты меню и меняет таблицы лута.
local manifest = DeerItemsItemManifest

local M = {}

if not TOML then error("DeerItems item config requires ReturnsAPI TOML") end
if not ModOptions then error("DeerItems item config requires ReturnsAPI ModOptions") end
if not manifest then error("DeerItems item config requires ItemManifest") end

local file = TOML.new("item_config")
local settings = file:read() or {}

-- Формирует имя настройки одного предмета в TOML-файле.
local function setting_key(category_key, item_id)
    return "item_"..category_key.."_"..item_id
end

-- Приводит значения из TOML и интерфейса к булеву типу. Некорректное значение заменяет default.
local function to_bool(value, default)
    if value == nil then return default end
    if value == true then return true end
    if value == false then return false end
    if value == 1 then return true end
    if value == 0 then return false end

    local text = string.lower(tostring(value))
    if text == "true" then return true end
    if text == "false" then return false end

    return default
end

-- Добавляет в файл настроек отсутствующие поля, сохраняя значения из старого формата.
local function ensure_defaults()
    local changed = false

    if settings.allItemsEnabled == nil then
        settings.allItemsEnabled = true
        changed = true
    end

    for _, category in ipairs(manifest.categories) do
        local old_category_settings
        if type(settings.enabledItems) == "table" then
            old_category_settings = settings.enabledItems[category.key]
        end

        for _, item in ipairs(category.items) do
            local key = setting_key(category.key, item.id)
            if settings[key] == nil then
                local old_value
                if type(old_category_settings) == "table" then
                    old_value = old_category_settings[item.id]
                end
                settings[key] = to_bool(old_value, true)
                changed = true
            end
        end
    end

    if changed then
        file:write(settings)
    end
end

-- Глобальное отключение предметов имеет приоритет над настройкой отдельного предмета.
local function is_enabled(category_key, item_id)
    if not to_bool(settings.allItemsEnabled, true) then return false end
    return to_bool(settings[setting_key(category_key, item_id)], true)
end

local function set_enabled(category_key, item_id, value)
    settings[setting_key(category_key, item_id)] = to_bool(value, false)
    file:write(settings)
end

local function set_all_enabled(value)
    settings.allItemsEnabled = to_bool(value, false)
    file:write(settings)
end

local function set_every_item_enabled(value)
    local enabled = to_bool(value, false)

    settings.allItemsEnabled = true
    for _, category in ipairs(manifest.categories) do
        for _, item in ipairs(category.items) do
            settings[setting_key(category.key, item.id)] = enabled
        end
    end

    file:write(settings)
end

-- Снаряжение и обычные предметы регистрируются разными API-вызовами.
local function find_registered_item(category_key, item_id)
    if category_key == "Equipments" then
        return Equipment.find("DeerItems", item_id)
    end

    return Item.find("DeerItems", item_id)
end

-- Применяет настройки к уже зарегистрированным предметам и скрывает служебные зависимости из лута.
local function apply_item_availability()
    local enabled_count = 0
    local disabled_count = 0

    for _, category in ipairs(manifest.categories) do
        for _, item in ipairs(category.items) do
            local enabled = is_enabled(category.key, item.id)
            local registered_item = find_registered_item(category.key, item.id)

            if registered_item then
                registered_item:toggle_loot(enabled)
            end

            if enabled then
                enabled_count = enabled_count + 1
            else
                disabled_count = disabled_count + 1
            end

            for _, dependency in ipairs(item.dependencies or {}) do
                local dependency_item = find_registered_item(category.key, dependency)
                if dependency_item then
                    dependency_item:toggle_loot(false)
                end
            end
        end
    end

    return enabled_count, disabled_count
end

-- Создаёт элементы меню настроек: общий переключатель, массовые действия и один флажок на предмет.
local function add_options()
    local options = ModOptions.new()

    local all_checkbox = options:add_checkbox("items.all")
    all_checkbox:add_getter(function()
        return to_bool(settings.allItemsEnabled, true)
    end)
    all_checkbox:add_setter(function(value)
        set_all_enabled(value)
        apply_item_availability()
    end)

    local enable_all_button = options:add_button("items.enableAll")
    enable_all_button:add_callback(function()
        set_every_item_enabled(true)
        apply_item_availability()
    end)

    local disable_all_button = options:add_button("items.disableAll")
    disable_all_button:add_callback(function()
        set_every_item_enabled(false)
        apply_item_availability()
    end)

    local apply_button = options:add_button("items.apply")
    apply_button:add_callback(function()
        settings = file:read() or settings
        ensure_defaults()
        apply_item_availability()
    end)

    for _, category in ipairs(manifest.categories) do
        for _, item in ipairs(category.items) do
            local category_key = category.key
            local item_id = item.id
            local checkbox = options:add_checkbox(category.option.."."..item_id)
            checkbox:add_getter(function()
                return is_enabled(category_key, item_id)
            end)
            checkbox:add_setter(function(value)
                set_enabled(category_key, item_id, value)
                apply_item_availability()
            end)
        end
    end
end

ensure_defaults()
add_options()

M.manifest = manifest
M.is_enabled = is_enabled
M.apply_availability = apply_item_availability
M.enable_all = function()
    set_every_item_enabled(true)
end
M.reload = function()
    settings = file:read() or {}
    ensure_defaults()
end

DeerItemsItemConfig = M

return M
