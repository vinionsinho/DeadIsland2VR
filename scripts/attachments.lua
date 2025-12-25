local uevrUtils = require('libs/uevr_utils')
local attachments = require('libs/attachments')
local controllers = require('libs/controllers')
local hands = require('libs/hands')
uevrUtils.setDeveloperMode(true)
attachments.setLogLevel(LogLevel.Debug)
uevrUtils.setLogLevel(LogLevel.Debug)


-- You will need to find the way to retrieve the weapon skeletal mesh or static mesh
-- for your specific game and replace getWeaponMesh() function with your own implemetation

-- replace this --
attachments.init()
function getWeaponMesh()
local pawn = uevrUtils.get_local_pawn()
    if not pawn then
	return
    end
local melee_root = nil
local ranged_root = nil
local attached_actors = {}
	if pawn then
		pawn:GetAttachedActors(attached_actors, true)
		for i, actor in ipairs(attached_actors) do
			if uevrUtils.getValid(actor) and not string.find(actor:get_full_name(),"DESTROYED") then
				local melee_mesh_component = actor.WeaponMesh
				local ranged_mesh_component = actor.SkeletalMesh
				if melee_mesh_component and melee_mesh_component.bOnlyOwnerSee 
					and not string.find(melee_mesh_component:get_full_name(), "DESTROYED") then
					melee_root = melee_mesh_component
					-- print ("A:" .. melee_root:get_full_name())
					break 
				end
				if ranged_mesh_component and ranged_mesh_component.bOnlyOwnerSee 
					and not string.find(ranged_mesh_component:get_full_name(), "DESTROYED") then
					ranged_root = ranged_mesh_component
					-- print ("B:" .. ranged_root:get_full_name())
					break 
				end
			end
		end
		return melee_root or ranged_root
	end
end
------------------

------------------------------------------------------------------------------
-- This works for Robocop: Rogue City and Robocop: Unfinished Business
--[[
attachments.init()

local currentGrabbedComponent = nil
function getWeaponMesh()
	local isHidden = false
	--see if we're grabbing a destructible world item first
	local weaponMesh = uevrUtils.getValid(pawn,{"PhysicsHandle","GrabbedComponent"})
	if weaponMesh ~= nil then
		--if bForceRefpose is not true then the grabbed item tries to animate on its own in
		--a different relative location when your hand isnt moving. So we force it to true
		if weaponMesh.bForceRefpose ~= nil then weaponMesh.bForceRefpose = true end
		currentGrabbedComponent = weaponMesh
	else
		--If we were previously holding a destructible world item then unset bForceRefpose
		if currentGrabbedComponent ~= nil and currentGrabbedComponent.bForceRefpose ~= nil then 
			currentGrabbedComponent.bForceRefpose = false
		end
		currentGrabbedComponent = nil
		
		--we're not grabbing a destructible so see if we have a weapon
		weaponMesh = uevrUtils.getValid(pawn,{"Weapon","WeaponMesh"})
		if weaponMesh == nil then
			local weaponComponent = uevrUtils.getValid(pawn,{"WeaponComponent"})
			if weaponComponent ~= nil and weaponComponent.GetCurrentWeapon ~= nil then
				local currentWeapon = pawn.WeaponComponent:GetCurrentWeapon()
				if currentWeapon ~= nil then
					isHidden = currentWeapon.bHidden
					weaponMesh = currentWeapon.WeaponMesh
				end
			end
		else
			isHidden = pawn.Weapon.bHidden
		end
	end
	if weaponMesh ~= nil then uevrUtils.fixMeshFOV(weaponMesh, "UsePanini", 0.0, true, true, false) end
	return weaponMesh
end
]]--

------------------------------------------------------------------------------

-- This works for Atomic Heart
--[[
attachments.init()

function getWeaponMesh()
	if uevrUtils.getValid(pawn) ~= nil and pawn.GetCurrentWeapon ~= nil then
		local currentWeapon = pawn:GetCurrentWeapon()
		if currentWeapon ~= nil then return currentWeapon.RootComponent end
	end
	return nil
end
]]--

------------------------------------------------------------------------------


-- This works for Outer Worlds Spacers Choice Edition
--[[
attachments.init(nil, nil, {0,0,0}, {0,-90,0}) --all attachments in OW have a 90 degree yaw offset so compensate here rather than manually for every individual weapon in the config ui

function getWeaponMesh()
	if uevrUtils.getValid(pawn) ~= nil and pawn.GetCurrentWeapon ~= nil then
		local currentWeapon = pawn:GetCurrentWeapon()
		if currentWeapon ~= nil then 
			local weaponMesh = currentWeapon.SkeletalMeshComponent
			if weaponMesh ~= nil then
				--some games mess with the weapon FOV and that needs to be fixed programatically
				uevrUtils.fixMeshFOV(weaponMesh, "ForegroundPriorityEnabled", 0.0, true, true, false)
				return weaponMesh
			end
		end
	end
	return nil
end
]]--

------------------------------------------------------------------------------

attachments.registerOnGripUpdateCallback(function()	
	-- return getWeaponMesh()
	-- return getWeaponMesh(), controllers.getController(Handed.Right)
	return getWeaponMesh(), hands.getHandComponent(Handed.Right)
end)

