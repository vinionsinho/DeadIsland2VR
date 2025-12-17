local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
--local input = require("libs/input")

local M = {}

--[[
gunstock.addAdjustment({
        id = "beretta",
        label = "Beretta M9",
        rotation_offset = {0,0,0}
})
gunstock.addAdjustment({
        id = "mossberg",
        label = "Mossberg",
        rotation_offset = {0,0,0}
})
gunstock.setActive("mossberg")
]]--
local parametersFileName = "gunstock_parameters"
local parameters = {}
local isParametersDirty = false

local disableGunstockConfiguration = false
local activeAttachmentID = nil
-- parameters["attachments"] = {
--     {
--         id = "WP_BerettaAuto9_C_Beretta_Mesh",
--         label = "Beretta M9",
--         rotation = {0,0,0}
--     }
-- }

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[gunstock] " .. text, logLevel)
	end
end

-- local function executeAimRotationOffsetChangeCallback(...)
-- 	uevrUtils.executeUEVRCallbacks("aim_rotation_offset_change", table.unpack({...}))
-- end

local function executeTransformChange(...)
	uevrUtils.executeUEVRCallbacks("gunstock_transform_change", table.unpack({...}))
end


local function getDefaultConfig(saveFileName)
    if saveFileName == nil then saveFileName = "gunstock_config" end
	return  {
		{
			panelLabel = "Gunstock Config",
			saveFile = saveFileName,
			layout =
			{
			}
		}
	}
end

local function updateConfigUI(configDefinition)
    local attachmentList = parameters["attachments"]
	table.insert(configDefinition[1]["layout"],
        {
            widgetType = "checkbox",
            id = "disable_gunstock_configuration",
            label = "Disable",
            initialValue = disableGunstockConfiguration
        }
	)

	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_node",
			id = "gunstock_configuration",
			initialOpen = true,
			label = "Gunstock Configuration"
		}
	)

    for i = 1, #attachmentList do
		local id = attachmentList[i]["id"]
		local label = attachmentList[i]["label"]
		local rot = attachmentList[i]["rotation"]
        table.insert(configDefinition[1]["layout"],
            {
                widgetType = "tree_node",
                id = "gunstock_" .. id,
                initialOpen = false,
                label = label
            }
        )
		table.insert(configDefinition[1]["layout"],
            {
                id = "gunstock_" .. id .. "_rotation", label = "Rotation",
                widgetType = "drag_float3", speed = .1, range = {-360, 360}, initialValue = rot
            }
		)
		table.insert(configDefinition[1]["layout"],
            {
                widgetType = "tree_pop"
            }
		)

        configui.onUpdate("gunstock_" .. id .. "_rotation", function(value)
			M.updateAttachmentTransform(nil, value, nil, id)
		end)

    end

    table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_pop"
		}
	)
	return configDefinition
end

local function saveParameters()
	M.print("Saving gunstock parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)
end, Once.EVER)

local function getAttachment(id)
    if parameters ~= nil and parameters["attachments"] ~= nil then
        for i = 1, #parameters["attachments"] do
            if id == parameters["attachments"][i].id then
                return parameters["attachments"][i]
            end
        end
    end
    return nil
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading attachments parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating attachments parameters")
	end
	if parameters["attachments"] == nil then
		parameters["attachments"] = {}
		isParametersDirty = true
	end

    createMonitor()
end

function M.showConfiguration(saveFileName, options)
	configui.create(updateConfigUI(getDefaultConfig(saveFileName)))
end

function M.addAdjustment(attachment)
	if attachment ~= nil and attachment.id ~= nil and attachment.id ~= "" and parameters ~= nil then
		local exists = false
		if parameters["attachments"] == nil then parameters["attachments"] = {} end
        for i = 1, #parameters["attachments"] do
            if attachment.id == parameters["attachments"][i].id then
                exists = true
            end
        end
        if not exists then
            if attachment.label == nil then
                attachment.label = attachment.id
            end
            if attachment.rotation == nil then
                attachment.rotation = {0,0,0}
            end
            table.insert(parameters["attachments"], attachment)
            isParametersDirty = true

            configui.update(updateConfigUI(getDefaultConfig()))
        end
    else
        M.print("Invalid attachment parameters", LogLevel.Warning)
	end
end

-- function M.registerUpdateCallback(func)
-- 	uevrUtils.registerUEVRCallback("gunstock_update", func)
-- end

function M.updateAttachmentTransform(pos, rot, scale, id)
	if id ~= nil then
        for i = 1, #parameters["attachments"] do
            if id == parameters["attachments"][i].id then
                parameters["attachments"][i].rotation = {rot.x, rot.y, rot.z}
                isParametersDirty = true
                if disableGunstockConfiguration == false and id == activeAttachmentID then
                    executeTransformChange(id, nil, uevrUtils.rotator(rot.x, rot.y, rot.z))
                end
                break
            end
        end
	end
end

function M.setActive(id)
    activeAttachmentID = id

    local rot = nil
    if disableGunstockConfiguration == false then
        local attachment  = getAttachment(id)
        if attachment ~= nil then
            rot = uevrUtils.rotator(attachment.rotation)
            --print("Setting gunstock rotation for " .. id .. " to " .. tostring(rot.Pitch) .. ", " .. tostring(rot.Yaw) .. ", " .. tostring(rot.Roll))
            --input.setAimRotationOffset(rot)
        end
    end
    if rot == nil then rot = uevrUtils.rotator(0,0,0) end
    --executeAimRotationOffsetChangeCallback(rot)
    executeTransformChange(id, nil, rot)
    return rot
end

function M.disable(val)
    disableGunstockConfiguration = val
    configui.setValue("disable_gunstock_configuration", val, true)
    M.setActive(activeAttachmentID)
end

configui.onCreateOrUpdate("disable_gunstock_configuration", function(value)
    M.disable(value)
end)

uevrUtils.registerUEVRCallback("attachment_grip_changed", function(id, gripHand)
    M.addAdjustment({id = id})
	M.setActive(id)
end)

M.loadParameters()

return M