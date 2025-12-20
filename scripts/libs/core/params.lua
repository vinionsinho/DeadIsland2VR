local uevrUtils = require("libs/uevr_utils")

local M = {}
M.__index = M

-- Constructor: Creates a new M instance
function M.new(fileName, defaultParams, autoSave)
    local self = setmetatable({}, M)
    self.fileName = fileName or "parameters"
    self.parameters = defaultParams or {}
    self.isDirty = false
    self.autoSaveInterval = nil
    if autoSave then
        self:autoSaveInit()
    end
    return self
end

-- Saves parameters to JSON file
function M:save()
    uevrUtils.print("[parameters] Saving parameters to " .. self.fileName .. ".json")
    if self.fileName ~= nil and self.fileName ~= "" then
        json.dump_file(self.fileName .. ".json", self.parameters, 4)
    else
        uevrUtils.print("[parameters] File name not set, cannot save parameters", LogLevel.Warning)
    end
end

-- Loads parameters from JSON file
function M:load()
    uevrUtils.print("[parameters] Loading parameters from " .. self.fileName .. ".json")
    local params = json.load_file(self.fileName .. ".json")
    if params ~= nil then
        self.parameters = params
    end
end

-- Sets a parameter value and marks as dirty for autosave
function M:set(key, value, persist)
    if type(key) == "table" then
        local field = self.parameters
        for i = 1, #key-1 do
            local k = key[i]
            if type(field[k]) ~= "table" then
                field[k] = {}   -- auto-create missing table
            end
            field = field[k]
        end
        field[key[#key]] = value
    else
        self.parameters[key] = value
    end
    self.isDirty = persist == nil and false or persist
end

-- Gets a parameter value by key
function M:get(key)
    if type(key) == "table" then
        local field = self.parameters
        for i = 1, #key do
            field = field[key[i]]
            if field == nil then return nil end
        end
        return field
    else
        return self.parameters[key]
    end
end

function M:getAll()
    return self.parameters
end

-- Initializes autosave with a timer
function M:autoSaveInit(interval)
    interval = interval or 1000  -- Default 1 second
    self.autoSaveInterval = uevrUtils.setInterval(interval, function()
        if self.isDirty then
            self:save()
            self.isDirty = false
        end
    end)
end

-- Stops autosave
function M:autoSaveStop()
    if self.autoSaveInterval then
        uevrUtils.clearInterval(self.autoSaveInterval)
        self.autoSaveInterval = nil
    end
end

return M