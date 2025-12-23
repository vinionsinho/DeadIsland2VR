require(".\\Subsystems\\UEHelper")

local kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")

local function get_struct_object(structClassName)
	local class = find_required_object(structClassName)
	if class ~= nil then
		return StructObject.new(class)
	end
	return nil
end

local function splitStr(inputstr, sep)
   if sep == nil then
      sep = '%s'
   end
   local t={}
   for str in string.gmatch(inputstr, '([^'..sep..']+)') 
   do
     table.insert(t, str)
   end
   return t
end

local function find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  find_required_object(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end

local function fname_from_string(str)
	return kismet_string_library:Conv_StringToName(str)
end

local function getAssetDataFromPath(pathStr)
	local fAssetData = get_struct_object("ScriptStruct /Script/CoreUObject.AssetData")
	local arr = splitStr(pathStr, " ")
	fAssetData.AssetClass = fname_from_string(arr[1])
	fAssetData.ObjectPath = fname_from_string(arr[2])
	arr = splitStr(arr[2], "/")
	local arr2 = splitStr(arr[#arr], ".")
	fAssetData.AssetName = fname_from_string(arr2[2])
	local packagePath = table.concat(arr, "/", 1, #arr - 1)
	fAssetData.PackagePath = packagePath
	fAssetData.PackageName = packagePath .. "/" .. arr2[1]
	return fAssetData
end

function CreateAssetData(PackageName, PackagePath, AssetName, AssetPackageName, AssetClassAssetName)
	local fAssetData = get_struct_object("ScriptStruct /Script/CoreUObject.AssetData")
	fAssetData.PackageName = fname_from_string(PackageName)
	fAssetData.PackagePath = fname_from_string(PackagePath)
	fAssetData.AssetName = fname_from_string(AssetName)
	local AssetClass = get_struct_object("ScriptStruct /Script/CoreUObject.TopLevelAssetPath")
	AssetClass = fname_from_string(AssetPackageName)
	AssetClass = fname_from_string(AssetClassAssetName)
	fAssetData.AssetClass = AssetClass
	return fAssetData
end

function GetLoadedAsset(fAssetData)
	-- local fAssetData = getAssetDataFromPath(pathStr)
	local assetRegistryHelper = find_first_of("Class /Script/AssetRegistry.AssetRegistryHelpers",  true)
	if not assetRegistryHelper:IsAssetLoaded(fAssetData) then
		local fSoftObjectPath = assetRegistryHelper:ToSoftObjectPath(fAssetData)
		kismet_system_library:LoadAsset_Blocking(fSoftObjectPath)
	end
	return assetRegistryHelper:GetAsset(fAssetData)
end