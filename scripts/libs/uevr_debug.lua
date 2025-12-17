--[[ 
originally based on UE4SS dump tool

Usage
	Drop the lib folder containing this file into your project folder
	At the top of your script file add 
		local debugModule = require("libs/uevr_debug")
		
	In your code call function like this
		debugModule.dump(pawn)
			
	Available functions:
	
	debugModule.dump(Object, (optional)recursive, (optional)ignoreRecursionList, (optional)logToFile) - print the Object properties to the console
		Object - The object you wish to dump
		[optional] recursive -  Whether the object dump should recursively dump child objects of the original object. Default is false
		[optional] ignoreRecursionList - A list of object full names or entire classes of objects to ignore when recursing 
			example: 
				ignoreRecursionList = {}
				ignoreRecursionList["SkeletalMeshComponentBudgeted /Game/Levels/Overland/Overland.Overland.PersistentLevel.BP_Biped_Player_C_2147461360.CharacterMesh0"] = true
				ignoreRecursionList["CameraStackComponent /Game/Levels/Overland/Overland.Overland.PersistentLevel.BP_Biped_Player_C_2147461360.CameraStack"] = true
				ignoreRecursionList["Class /Script/Engine.BodySetup"] = true
		[optional] logToFile - Sends the dump to the log file in addition to the console

		example:
			ignoreRecursionList = {}
			ignoreRecursionList["BlueprintGeneratedClass /Game/Pawn/Player/BP_Phoenix_Player_Controller.BP_Phoenix_Player_Controller_C"] = true
			local camera = uevrUtils.get_first_object_by_class("Class /Script/Phoenix.PhoenixCameraStackManager" , false)
			debugModule.dump(camera, true, ignoreRecursionList)

]]--


local M = {}

local UClassStaticClass = nil
local UScriptStructStaticClass = nil
local UEnumStaticClass = nil
local UPropertyStaticClass = nil

local function is_a_struct(Object)
	if Object.get_struct ~= nil then
		return true
	end
	return false
end

local function getObjectFromWeakPointer(ptr)
	if ptr ~= nil then
		return ptr:Get()
	end
	return nil
end

local function dumpTable(o, level)
	if level == nil then level = "" end
	if type(o) == 'table' then
		local s = "\n"
		for k,v in pairs(o) do
			--if type(k) ~= 'number' then k = ''..k..'' end
			local newLevel = level .. "\t"
			s = s .. level .. type(v) .. " " .. k .. "=" .. dumpTable(v, newLevel)
		end
		return s 
	else
		local str = tostring(o)
		if string.match(str, "FWeakObjectPtr") then
			local obj = getObjectFromWeakPointer(o)
			if obj ~= nil then
				local name = obj:GetFullName()
				if name ~= nil then
					str = name
				else
					str = str .. " <no name>"
				end
			end
		elseif string.match(tostring(o), "FNameUserdata") then
			str = o:ToString()
			--str = kismet_string_library:Conv_NameToString(o) --o:ToString()
		end
		return str .. "\n"
	end
end

local function dumpStruct(Value, level)
	if level == nil then level = "" end
	local ValueStr = ""
	local childStr = ""
	if is_a_struct(Value) then
		local ChildProperty = Value:get_struct():get_child_properties()
		if ChildProperty == nil then
			--ValueStr = string.format("%s %s %s\n\t%s", UEVR_UStruct.static_class(Value):get_full_name(), Value, Value:get_struct(), "<Empty>")
			ValueStr = string.format("%s", "<Empty>")
		else
			while ChildProperty ~= nil do
				local newLevel = level .. "\t"
				childStr = childStr .. dumpPropertyOfObject(Value, ChildProperty, newLevel)
				ChildProperty = ChildProperty:get_next()
				if ChildProperty ~= nil then 
					childStr = childStr .. "\n" 
				end
			end
			--ValueStr = string.format("%s %s %s\n%s", UEVR_UStruct.static_class(Value):get_full_name(), Value, Value:get_struct(), childStr)
			--ValueStr = string.format("%s\n%s", UEVR_UStruct.static_class(Value):get_full_name(), childStr)
			ValueStr = string.format("\n%s", childStr)
		end
	elseif string.match(string.format("%s",Value), "sol.glm::vec<3,float,0>*" ) then
		ValueStr = string.format("<%s, %s, %s>", Value.X, Value.Y, Value.Z )
	else
		print("!!!Unknown Struct type found!!!",UEVR_UStruct.static_class(Value):get_full_name(), Value)
		print(type(Value),Value:get_field_name())
		-- local ChildProperty = Value:get_child_properties()
		-- while ChildProperty ~= nil do
			-- childStr = childStr .. "\t" .. dumpPropertyOfObject(Value, ChildProperty) .. "\n"
			-- ChildProperty = ChildProperty:get_next()
		-- end
		-- print("here3\n")
		-- ValueStr = string.format("%s %s\n%s", UEVR_UStruct.static_class(Value):get_full_name(), Value, childStr)
	end
	return ValueStr
end

local function getEntityName(Object)
	local name = ""
	if type(Object) == 'table' then
		name = tostring(Object)
	elseif is_a_struct(Object) then
		name = UEVR_UStruct.static_class(Object):get_full_name()
	else
		name = Object:get_full_name()
	end
	return name
end

local function doDump(Object, level, recursive, ignoreRecursionList)
	local returnStr = ""
    -- Lets make sure that this is an object type that can be dumped.
	if type(Object) == 'table' then
		returnStr = dumpTable(Object)
	elseif is_a_struct(Object) then
		returnStr = dumpStruct(Object)
	else
		local IsClassCompatible = false
		if Object:is_a(UClassStaticClass) then IsClassCompatible = true end
		local IsUScriptStruct = Object:is_a(UScriptStructStaticClass)
		if IsUScriptStruct and not Object:IsMappedToObject() then IsClassCompatible = true end

		if IsClassCompatible then
			-- A UClass or UScriptStruct.
			local Class = Object
			while Class and Class:IsValid() do
				-- Log(string.format("=== %s properties ===\n", Class:get_full_name()))
				-- Class:ForEachProperty(function(Property)
				-- 	local OutputBuffer = string.format("0x%04X    %s %s", Property:GetOffset_Internal(), Property:get_class():get_fname():to_string(), Property:get_fname():to_string())
				-- 	if Property:is_a(PropertyTypes.ObjectProperty) then
				-- 		OutputBuffer = string.format("%s (%s)", OutputBuffer, Property:GetPropertyClass():get_full_name())
				-- 	elseif Property:is_a(PropertyTypes.BoolProperty) then
				-- 		local FieldMask = Property:GetFieldMask()
				-- 		if FieldMask ~= 255 then
				-- 			OutputBuffer = string.format("%s (FM: 0x%X, BM: 0x%X)", OutputBuffer, FieldMask, Property:GetByteMask())
				-- 		end
				-- 	end
				-- 	Log(OutputBuffer)
				-- end)

				Class = Class:GetSuperStruct()
			end
		elseif Object:is_a(UEnumStaticClass) then
			Object:ForEachName(function(Name, Value)
				--Log(string.format("%s (%i)", Name:to_string(), Value))
			end)
		elseif not Object:is_a(UPropertyStaticClass) then
			-- A UObject that isn't a UClass, UScriptStruct, or UProperty (<4.25 only)
			local ObjectClass = nil
			if IsUScriptStruct then
				ObjectClass = Object
			else
				ObjectClass = Object:get_class()
			end
			
			while ObjectClass and UEVR_UObjectHook.exists(ObjectClass) do --ObjectClass:IsValid() do
				local objStr = ""
				objStr = objStr .. string.format("\n%s(%s)\n", level, ObjectClass:get_full_name())
				local Property = ObjectClass:get_child_properties()
				while Property ~= nil do
					objStr = objStr .. dumpPropertyOfObject(Object, Property, level, recursive, ignoreRecursionList) .. "\n"
					Property = Property:get_next()
				end
				
				returnStr = returnStr .. objStr
	 
				ObjectClass = ObjectClass:get_super_struct()
			end
		end
	end
	return returnStr
end


function dumpPropertyOfObject(Object, Property, level, recursive, ignoreRecursionList)
    local ValueStr = ""
	if level == nil then level = "" end
	if ignoreRecursionList == nil then ignoreRecursionList = {} end

    -- Cannot resolve the value here because of unhandled types.
    if Property:get_class():get_name() == "Int8Property" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", Value)
    elseif Property:get_class():get_name() == "Int16Property" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", Value)
    elseif Property:get_class():get_name() == "IntProperty" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", Value)
    elseif Property:get_class():get_name() == "Int64Property" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", Value)
    elseif Property:get_class():get_name() == "NameProperty" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", Value:to_string())
    elseif Property:get_class():get_name() == "FloatProperty" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", Value)
    elseif Property:get_class():get_name() == "StrProperty" then
        local Value = Object[Property:get_fname():to_string()]
		if Value == nil then
			ValueStr = "nil"
		elseif Value.to_string ~= nil then
			ValueStr = string.format("%s", Value:to_string())
		else
			ValueStr = Value
		end
    elseif Property:get_class():get_name() == "ByteProperty" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", Value)
    elseif Property:get_class():get_name() == "ArrayProperty" then
        local Value = Object[Property:get_fname():to_string()]
		if Value == nil then
			ValueStr = "nil"
		else			
			if #Value == 0 then
				ValueStr = string.format("%s<Empty>", ValueStr)
			else
				ValueStr = string.format("%s%i", ValueStr, #Value)
			end

			local newLevel = level .. "\t"			
			local index = 0
			if #Value > 0 then
				ValueStr = string.format("%s\n", ValueStr)
				for key, elem in ipairs(Value) do
					ValueStr = ValueStr ..  string.format("%s[%i]: %s",newLevel, key, elem:get_full_name())
					index = index + 1
					if index < #Value then
						ValueStr = ValueStr .. "\n"
					end
				end
			end

		end
    elseif Property:get_class():get_name() == "MapProperty" then
        ValueStr = "UNHANDLED_VALUE"
    elseif Property:get_class():get_name() == "StructProperty" then
        local Value = Object[Property:get_fname():to_string()]
		if Value == nil then
			ValueStr = string.format("nil")
		else
			ValueStr = dumpStruct(Value, level)
		end
    elseif Property:get_class():get_name() == "ClassProperty" then
        local Value = Object[Property:get_fname():to_string()]
		if Value == nil then
			ValueStr = "nil"
		else
			ValueStr = string.format("%s", Value:get_full_name())
		end
    elseif Property:get_class():get_name() == "WeakObjectProperty" then
        local Value = Object[Property:get_fname():to_string()]
 		if Value == nil then
			ValueStr = "nil"
		else
			ValueStr = string.format("(%s)", Value:Get())
		end
    elseif Property:get_class():get_name() == "EnumProperty" then
        local Value = Object[Property:get_fname():to_string()]
		--print(Property:get_fname(),Property:get_class(),Property:get_class():get_name(),Value,"\n")
        --ValueStr = string.format("%s(%s)", Property:GetEnum():GetNameByValue(Value):to_string(), Value)
        ValueStr = string.format("(%s)", Value)
    elseif Property:get_class():get_name() == "TextProperty" then
        local Value = Object[Property:get_fname():to_string()]
		if Value == nil then
			ValueStr = "nil"
		else
			ValueStr = string.format("%s", Value:to_string())
		end
    elseif Property:get_class():get_name() == "ObjectProperty" then
        local Value = Object[Property:get_fname():to_string()]
		--print("Object Property",Object,Object["StaticMesh"],Property:get_fname():to_string(),"\n")
		if Value == nil then
			ValueStr = "nil"
		else
			ValueStr = string.format("(%s)", Value:get_full_name())
			if recursive and ignoreRecursionList[Value:get_full_name()] ~= true and ignoreRecursionList[Value:get_class():get_full_name()] ~= true  then
				ignoreRecursionList[Value:get_full_name()] = true
				local newLevel = level .. "\t"
				ValueStr = ValueStr .. doDump(Value, newLevel, recursive, ignoreRecursionList)
			end
		end
    elseif Property:get_class():get_name() == "BoolProperty" then
        local Value = Object[Property:get_fname():to_string()]
        ValueStr = string.format("%s", (Value and "true" or "false"))
    else
        ValueStr = "UNHANDLED_VALUE"
    end

    return string.format("%s%s %s=%s", level, Property:get_class():get_fname():to_string(), Property:get_fname():to_string(), ValueStr)
end

function split_string_into_chunks(str, chunk_size)
	local chunks = {}  -- Initialize an empty table to store the chunks
	local i = 1  -- Start index for extracting substrings
	while i <= #str do
		local chunk = string.sub(str, i, i + chunk_size - 1)  -- Extract a substring of the specified size
		table.insert(chunks, chunk)  -- Add the chunk to the table
		i = i + chunk_size  -- Move to the next chunk's starting index
	end
	return chunks  -- Return the table containing the chunks
end

local function Log(str, logToFile)
	if logToFile == true then
		local chunk_length = 128000 -- apparently uevr limits the string size that it will log
		local result_array = split_string_into_chunks(str, chunk_length)

		-- Print the result:
		for _, chunk in ipairs(result_array) do
			uevr.params.functions.log_info(str)
		end	
	end
	
	print(str)
end


function M.dump(Object, recursive, ignoreRecursionList, logToFile)
	if recursive ~= true then recursive = false end
	if Object == nil then
		Log("Invalid parameters passed to dump\n", logToFile)
	else	
		if UClassStaticClass == nil then UClassStaticClass = uevr.api:find_uobject("/Script/CoreUObject.Class") end
		if UScriptStructStaticClass == nil then UScriptStructStaticClass = uevr.api:find_uobject("/Script/CoreUObject.ScriptStruct") end
		if UEnumStaticClass == nil then UEnumStaticClass = uevr.api:find_uobject("/Script/CoreUObject.Enum") end
		if UPropertyStaticClass == nil then UPropertyStaticClass = uevr.api:find_uobject("/Script/CoreUObject.Property") end

		Log(string.format("\n*** Property dump for object '%s ***\n%s", getEntityName(Object), doDump(Object, "", recursive, ignoreRecursionList)), logToFile)
	end
 end
 
return M