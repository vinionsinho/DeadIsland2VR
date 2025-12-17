local uevrUtils = require("libs/uevr_utils")

local M = {}

local animations = {}
local boneVisualizers = {}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[animation] " .. text, logLevel)
	end
end

function M.createPoseableComponent(skeletalMeshComponent, parent, useDefaultPose)
	local poseableComponent = nil
	if skeletalMeshComponent ~= nil then
		poseableComponent = uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, {parent=parent, useDefaultPose = useDefaultPose, showDebug = currentLogLevel==LogLevel.Debug})

		-- poseableComponent.SkeletalMesh.PositiveBoundsExtension.X = 100
		-- poseableComponent.SkeletalMesh.PositiveBoundsExtension.Y = 100
		-- poseableComponent.SkeletalMesh.PositiveBoundsExtension.Z = 100
		-- poseableComponent.SkeletalMesh.NegativeBoundsExtension.X = -100
		-- poseableComponent.SkeletalMesh.NegativeBoundsExtension.Y = -100
		-- poseableComponent.SkeletalMesh.NegativeBoundsExtension.Z = -100
	else
		M.print("SkeletalMeshComponent was not valid in createPoseableComponent", LogLevel.Warning)
	end

	return poseableComponent
end

-- boneName - the name of the bone that will serve as the root of the hand. It could be the hand bone or the forearm bone
-- hideBoneName - if showing the right hand then you would hide the left shoulder and vice versa
-- M.initPoseableComponent(poseableComponent, "RightForeArm", "LeftShoulder", location, rotation, scale)
-- because we hide parts of the mesh using scale, the end of a mesh will taper to a point. We can adjust the location of that
-- point with taperOffset. For example to make a hollow arm we could use taperOffset = uevrUtils.vector(0, 0, 15)
function M.initPoseableComponent(poseableComponent, boneName, shoulderBoneName, hideBoneName, location, rotation, scale, rootBoneName, taperOffset)
	if uevrUtils.validate_object(poseableComponent) ~= nil then
		if rootBoneName == nil then
			rootBoneName = M.getRootBoneOfBone(poseableComponent, boneName) --poseableComponent:GetBoneName(1) 
			M.print("Found root bone " .. rootBoneName:to_string(), LogLevel.Info)
		else
			rootBoneName = uevrUtils.fname_from_string(rootBoneName)
		end
		local boneSpace = 0

		local parentTransform = poseableComponent:GetBoneTransformByName(rootBoneName, boneSpace)

		if taperOffset == nil then taperOffset = uevrUtils.vector(0, 0, 0) end
		--scale the shoulder bone to almost 0 so it and its children dont display
		local localTransform = kismet_math_library:MakeTransform(kismet_math_library:Add_VectorVector(location, taperOffset), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
		M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(shoulderBoneName), localTransform, boneSpace, parentTransform)

		--apply a transform of the specified bone with respect the the tranform of the root bone of the skeleton
		local localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
		M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(boneName), localTransform, boneSpace, parentTransform)

		--scale the hidden bone to 0 so it and its children dont display
		poseableComponent:SetBoneScaleByName(uevrUtils.fname_from_string(hideBoneName), vector_3f(0.001, 0.001, 0.001), boneSpace)

	end
end

-- use transformBoneToRoot with parentPathOnly = true instead
-- function M.transformBoneToRootOptimized(poseableComponent, targetBoneName, location, rotation, scale, taperOffset)
-- 	if uevrUtils.validate_object(poseableComponent) ~= nil then
-- 		local boneSpace = 0
-- 		local rootBoneName = M.getRootBoneOfBone(poseableComponent, targetBoneName) --should always be the 0 index bone but just to be safe we trace it back
-- 		--M.print("Found root bone " .. rootBoneName:to_string())		
-- 		local rootTransform = poseableComponent:GetBoneTransformByName(rootBoneName, boneSpace)

-- 		local parentFName = poseableComponent:GetParentBone(uevrUtils.fname_from_string(targetBoneName)) --the bone above the target bone

-- 		local boneName = parentFName
-- 		local localTransform = kismet_math_library:MakeTransform(uevrUtils.vector(0, 0, 0), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
-- 		while boneName:to_string() ~= "None" do
-- 			M.setBoneSpaceLocalTransform(poseableComponent, boneName, localTransform, boneSpace, rootTransform)
-- 			boneName = poseableComponent:GetParentBone(boneName)
-- 		end

-- 		--special handling for the bone above the target bone to allow for a taper
-- 		if taperOffset == nil then taperOffset = uevrUtils.vector(0, 0, 0) end
-- 		localTransform = kismet_math_library:MakeTransform(kismet_math_library:Add_VectorVector(location, taperOffset), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
-- 		M.setBoneSpaceLocalTransform(poseableComponent, parentFName, localTransform, boneSpace, rootTransform)

-- 		--apply a transform of the target bone with respect the the tranform of the root bone of the skeleton
-- 		local localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
-- 		M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(targetBoneName), localTransform, boneSpace, rootTransform)
-- 	end
-- end

-- Parent bone is upperarm_l
-- lowerarm_l
-- upperarm_l
-- clavicle_l
-- spine_03
-- spine_02
-- spine_01
-- Pelvis
-- Root
-- function M.transformBoneToRoot2(poseableComponent, targetBoneName, location, rotation, scale, taperOffset, parentPathOnly)
-- 	if uevrUtils.validate_object(poseableComponent) ~= nil then
-- 		local boneSpace = 0
-- 		local rootBoneName = M.getRootBoneOfBone(poseableComponent, targetBoneName) --should always be the 0 index bone but just to be safe we trace it back
-- 		--M.print("Found root bone " .. rootBoneName:to_string())		
-- 		--local rootTransform = poseableComponent:GetBoneTransformByName(uevrUtils.fname_from_string("clavicle_l"), boneSpace)
-- 		local rootTransform = poseableComponent:GetBoneTransformByName(rootBoneName, boneSpace)

-- 		local parentFName = poseableComponent:GetParentBone(uevrUtils.fname_from_string(targetBoneName)) --the bone above the target bone
-- 		print("Parent bone is " .. parentFName:to_string())
-- 		local boneName = nil
-- 		local localTransform = nil

-- 		parentFName = poseableComponent:GetParentBone(uevrUtils.fname_from_string(targetBoneName)) --the bone above the target bone
-- 		boneName = parentFName
-- 		localTransform = kismet_math_library:MakeTransform(uevrUtils.vector(0, 0, 0), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
-- 			--while boneName:to_string() ~= "None" do
-- 				M.setBoneSpaceLocalTransform(poseableComponent, boneName, localTransform, boneSpace, rootTransform)

-- 		parentFName = uevrUtils.fname_from_string(targetBoneName)
-- 		--if parentPathOnly == true then
-- 			--only affect bones in the parent hierarchy
-- 		boneName = parentFName
-- 		localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
-- 			--while boneName:to_string() ~= "None" do
-- 				M.setBoneSpaceLocalTransform(poseableComponent, boneName, localTransform, boneSpace, rootTransform)
-- 				--boneName = poseableComponent:GetParentBone(boneName)
-- 			--end

-- 		-- else
-- 		-- 	--loop through all other bones of the skeleton and set their transforms with respect to the root to 0. Do not do this for bones that are children of the target
-- 		-- 	local localTransform = kismet_math_library:MakeTransform(uevrUtils.vector(0, 0, 0), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
-- 		-- 	local count = poseableComponent:GetNumBones()
-- 		-- 	for index = 1 , count do	
-- 		-- 		local childFName = poseableComponent:GetBoneName(index)
-- 		-- 		if not poseableComponent:BoneIsChildOf(childFName, parentFName) then	
-- 		-- 			M.setBoneSpaceLocalTransform(poseableComponent, childFName, localTransform, boneSpace, rootTransform)
-- 		-- 		end
-- 		-- 	end
-- 		-- end

-- 		-- --special handling for the bone above the target bone to allow for a taper
-- 		-- if taperOffset == nil then taperOffset = uevrUtils.vector(0, 0, 0) end
-- 		-- local localTransform = kismet_math_library:MakeTransform(kismet_math_library:Add_VectorVector(location, taperOffset), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
-- 		-- M.setBoneSpaceLocalTransform(poseableComponent, parentFName, localTransform, boneSpace, rootTransform)

-- 		-- --apply a transform of the target bone with respect the the tranform of the root bone of the skeleton
-- 		-- localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
-- 		-- M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(targetBoneName), localTransform, boneSpace, rootTransform)
-- 	end
-- end

-- This traverses the bone hierarchy and any bones that are not children of the target bone are set to 0 transform
-- so that all other bones collapse down to the root 
-- Set parentPathOnly to true to only affect the bones in the parent path of the target bone. For example if you are
-- calling this function on the tick and need the best performance
function M.transformBoneToRoot(poseableComponent, targetBoneName, location, rotation, scale, taperOffset, parentPathOnly, rootBoneForPath)
	if uevrUtils.validate_object(poseableComponent) ~= nil then
		local boneSpace = 0
		local rootBoneName = M.getRootBoneOfBone(poseableComponent, targetBoneName) --should always be the 0 index bone but just to be safe we trace it back
		--M.print("Found root bone " .. rootBoneName:to_string())		
		local rootTransform = poseableComponent:GetBoneTransformByName(rootBoneName, boneSpace)

		local parentFName = poseableComponent:GetParentBone(uevrUtils.fname_from_string(targetBoneName)) --the bone above the target bone

		if parentPathOnly == true then
			--only affect bones in the parent hierarchy
			local boneName = parentFName
			local localTransform = kismet_math_library:MakeTransform(uevrUtils.vector(0, 0, 0), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
			--while boneName:to_string() ~= "None" do 
			if rootBoneForPath == nil or rootBoneForPath == "" then
				rootBoneForPath = "None"
			else
				local pName = poseableComponent:GetParentBone(uevrUtils.fname_from_string(rootBoneForPath))
				rootBoneForPath = pName:to_string()
			end
			while boneName:to_string() ~= rootBoneForPath do
				M.setBoneSpaceLocalTransform(poseableComponent, boneName, localTransform, boneSpace, rootTransform)
				boneName = poseableComponent:GetParentBone(boneName)
			end
		else
			--loop through all other bones of the skeleton and set their transforms with respect to the root to 0. Do not do this for bones that are children of the target
			local localTransform = kismet_math_library:MakeTransform(uevrUtils.vector(0, 0, 0), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
			local count = poseableComponent:GetNumBones()
			for index = 1 , count do
				local childFName = poseableComponent:GetBoneName(index)
				if not poseableComponent:BoneIsChildOf(childFName, parentFName) then
					M.setBoneSpaceLocalTransform(poseableComponent, childFName, localTransform, boneSpace, rootTransform)
				end
			end
		end

		--special handling for the bone above the target bone to allow for a taper
		if taperOffset == nil then taperOffset = uevrUtils.vector(0, 0, 0) end
		local localTransform = kismet_math_library:MakeTransform(kismet_math_library:Add_VectorVector(location, taperOffset), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
		M.setBoneSpaceLocalTransform(poseableComponent, parentFName, localTransform, boneSpace, rootTransform)

		--apply a transform of the target bone with respect the the tranform of the root bone of the skeleton
		localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
		M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(targetBoneName), localTransform, boneSpace, rootTransform)
	end
end

function M.getBoneSpaceLocalRotator(component, boneFName, fromBoneSpace)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if fromBoneSpace == nil then fromBoneSpace = 0 end
		local parentTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), fromBoneSpace)
		local wTranform = component:GetBoneTransformByName(boneFName, fromBoneSpace)
		local localTransform = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(parentTransform))
		--fix for non-working BreakTransform in robocop UB
		local localRotator = kismet_math_library:TransformRotation(localTransform, uevrUtils.rotator(0,0,0))
--		print("here", localRotator.pitch, localRotator.Pitch)
--		local localRotator = uevrUtils.rotator(0, 0, 0)
--		kismet_math_library:BreakTransform(localTransform,temp_vec3, localRotator, temp_vec3)
--		print("here 2", localRotator.pitch, localRotator.Pitch)
		return localRotator, parentTransform
	end
	return nil, nil
end

-- function M.getBoneSpaceLocalTransform(component, boneFName, fromBoneSpace)
	-- --print(component, boneFName)
	-- if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		-- if fromBoneSpace == nil then fromBoneSpace = 0 end
		-- local parentTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), fromBoneSpace)
		-- local wTranform = component:GetBoneTransformByName(boneFName, fromBoneSpace)
		-- --print("Here",kismet_string_library:Conv_TransformToString(wTranform))
		-- local localTransform = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(parentTransform))
		-- --local localLocation = uevrUtils.vector(0, 0, 0)
		-- --local localRotation = uevrUtils.rotator(0, 0, 0)
		-- --local localScale = uevrUtils.vector(0, 0, 0)
		-- --kismet_math_library:BreakTransform(localTransform, localLocation, localRotation, localScale)
		-- --fix for non-working BreakTransform in robocop UB
		-- localRotation = kismet_math_library:TransformRotation(localTransform, uevrUtils.rotator(0, 0, 0))
		-- --localLocation = kismet_math_library:TransformLocation(localTransform, localLocation);
		-- --print(localRotation, wTranform.Translation, wTranform.Scale3D)
		-- --print("here 1")
		-- return localRotation, wTranform.Translation, wTranform.Scale3D, parentTransform
	-- end
	-- --print("Here 2")
	-- return nil, nil, nil, nil
-- end

function M.getBoneSpaceLocalTransform(component, boneFName, fromBoneSpace)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if fromBoneSpace == nil then fromBoneSpace = 0 end
		local parentTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), fromBoneSpace)
		local wTranform = component:GetBoneTransformByName(boneFName, fromBoneSpace)
		local localTransform = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(parentTransform))
		-- local localTransform2 = component:GetDeltaTransformFromRefPose(boneFName,component:GetParentBone(boneFName))
		-- --component:GetCurrentJointAngles(FName InBoneName, float& Swing1Angle, float& TwistAngle, float& Swing2Angle);
-- print("Here 1",kismet_string_library:Conv_TransformToString(localTransform))
-- print("Here 2",kismet_string_library:Conv_TransformToString(localTransform2))

		local localLocation = uevrUtils.vector(0, 0, 0)
		local localRotation = uevrUtils.rotator(0, 0, 0)
		local localScale = uevrUtils.vector(0, 0, 0)
		kismet_math_library:BreakTransform(localTransform, localLocation, localRotation, localScale)
		--fix for non-working BreakTransform in robocop UB
		localRotation = kismet_math_library:TransformRotation(localTransform, uevrUtils.rotator(0, 0, 0))
		if localScale == nil then localScale = wTranform.Scale3D end
		return localRotation, localLocation, localScale, parentTransform
	end
	return nil, nil, nil, nil
end


function M.getChildSkeletalMeshComponent(parent, name)
	return uevrUtils.getChildComponent(parent, name)
end

--if you know the parent transform then pass it in to save a step
function M.setBoneSpaceLocalRotator(component, boneFName, localRotator, toBoneSpace, pTransform)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if component.GetParentBone ~= nil then
			if toBoneSpace == nil then toBoneSpace = 0 end
			if pTransform == nil then pTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), toBoneSpace) end
			--print("Before",localRotator.Pitch,localRotator.Yaw,localRotator.Roll)
			local wRotator = kismet_math_library:TransformRotation(pTransform, localRotator);
			--print("After",wRotator.Pitch,wRotator.Yaw,wRotator.Roll)
			component:SetBoneRotationByName(boneFName, wRotator, toBoneSpace)
		else
			M.print("In setBoneSpaceLocalRotator() component.GetParentBone was nil for " .. component:get_full_name(), LogLevel.Warning)
		end
	end
end

function M.setBoneSpaceLocalLocation(component, boneFName, localLocation, toBoneSpace, pTransform)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if component.GetParentBone ~= nil then
			if toBoneSpace == nil then toBoneSpace = 0 end
			if pTransform == nil then pTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), toBoneSpace) end
			--print("Before",localLocation.X,localLocation.Y,localLocation.Z)
			local wLocation = kismet_math_library:TransformLocation(pTransform, localLocation);
			--print("After",wRotator.Pitch,wRotator.Yaw,wRotator.Roll)
			component:SetBoneLocationByName(boneFName, wLocation, toBoneSpace)
		else
			M.print("In setBoneSpaceLocalPosition() component.GetParentBone was nil for " .. component:get_full_name(), LogLevel.Warning)
		end
	end
end

function M.setBoneSpaceLocalTransform(component, boneFName, localTransform, toBoneSpace, pTransform)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if toBoneSpace == nil then toBoneSpace = 0 end
		if pTransform == nil then pTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), toBoneSpace) end
		local wTransform = kismet_math_library:ComposeTransforms(localTransform, pTransform)
		component:SetBoneTransformByName(boneFName, wTransform, toBoneSpace)
	end
end

function M.hasBone(component, boneName)
	local index = component:GetBoneIndex(uevrUtils.fname_from_string(boneName))
	--print("Has bone",boneName,index,"\n")
	return index ~= -1
end

function M.doAnimate(anim, component, mirrorPitch, mirrorYaw, mirrorRoll)
	local boneSpace = 0
	if anim ~= nil and component ~= nil then
		for boneName, angles in pairs(anim) do
			local localRotator = uevrUtils.rotator(angles[1] * (mirrorPitch==true and -1 or 1), angles[2] * (mirrorYaw==true and -1 or 1), angles[3] * (mirrorRoll==true and -1 or 1))
			M.print("Animating " .. boneName .. " " .. localRotator.X .. " " .. localRotator.Y .. " " .. localRotator.Z, LogLevel.Info)
			M.setBoneSpaceLocalRotator(component, uevrUtils.fname_from_string(boneName), localRotator, boneSpace)
		end
	end
end

function M.doAnimateForFinger(anim, component, boneList, fingerIndex)
	local boneSpace = 0
	local filteredAnim = {}
	local bone1Name = component:GetBoneName(boneList[fingerIndex], boneSpace):to_string()
	local bone2Name = component:GetBoneName(boneList[fingerIndex] + 1, boneSpace):to_string()
	local bone3Name = component:GetBoneName(boneList[fingerIndex] + 2, boneSpace):to_string()
	for name, item in pairs(anim) do
		if name == bone1Name or name == bone2Name or name == bone3Name then
			filteredAnim[name] = item
		end
	end
	M.doAnimate(filteredAnim, component)
end

function M.animate(animID, animName, val)
	M.print("Called animate with " .. animID .. " " .. animName .. " " .. val, LogLevel.Info)
	local animation = animations[animID]
	if animation ~= nil then
		local component = animation["component"]
		if component ~= nil and animation["definitions"] ~= nil and animation["definitions"]["positions"] ~= nil then
			local subAnim = animation["definitions"]["positions"][animName]
			if subAnim ~= nil then
				local anim = subAnim[val]
				M.doAnimate(anim, component)
				-- if anim ~= nil then
					-- local boneSpace = 0
					-- for boneName, angles in pairs(anim) do
						-- local localRotator = uevrUtils.rotator(angles[1], angles[2], angles[3])
						-- M.print("Animating " .. boneName .. " " .. val, LogLevel.Info)
						-- M.setBoneSpaceLocalRotator(component, uevrUtils.fname_from_string(boneName), localRotator, boneSpace)
					-- end
				-- end
			end
		else
			M.print("Component was nil in animate", LogLevel.Warning)
		end
	end
end

local function lerpAnimation(animID, animName, alpha)
	M.print("Called lerp with " .. animID .. " " .. animName .. " " .. alpha, LogLevel.Info)
	local animation = animations[animID]
	if animation ~= nil then
		local component = animation["component"]
		if component ~= nil and animation["definitions"] ~= nil and animation["definitions"]["positions"] ~= nil then
			local boneSpace = 0
			local subAnim = animation["definitions"]["positions"][animName]
			if subAnim ~= nil then
				local startPose = subAnim["off"]
				local endPose = subAnim["on"]
				if startPose == nil and endPose ~= nil then
					startPose = endPose
				elseif endPose == nil and startPose ~= nil then
					endPose = startPose
				end
				if startPose ~= nil and endPose ~= nil then
					for boneName, angles in pairs(startPose) do
						local startRotator = uevrUtils.rotator(angles[1], angles[2], angles[3])
						local endRotator = uevrUtils.rotator(endPose[boneName][1], endPose[boneName][2], endPose[boneName][3])
						--M.print("Lerping " .. boneName .. " " .. alpha, LogLevel.Info)
						local localRotator = kismet_math_library:RLerp(startRotator, endRotator, alpha, true)
						M.setBoneSpaceLocalRotator(component, uevrUtils.fname_from_string(boneName), localRotator, boneSpace)
					end
				end
			end
		else
			M.print("Component was nil in lerpAnimation", LogLevel.Warning)
		end
	end
end

function M.pose(animID, poseID)
	M.print("Called pose " .. poseID .. " for animationID " .. animID, LogLevel.Debug)
	--uevrUtils.dumpJson("test", animations)
	if animations ~= nil and animations[animID] ~= nil and animations[animID]["definitions"] ~= nil and animations[animID]["definitions"]["poses"] ~= nil then
		local pose = animations[animID]["definitions"]["poses"][poseID]
		if pose ~= nil then
			M.print("Found pose " .. poseID, LogLevel.Debug)
			for i, positions in ipairs(pose) do
				local animName = positions[1]
				local val = positions[2]
				M.print("Animating pose index " .. i .. " " .. animID .. " " .. animName .. " " .. val, LogLevel.Info)
				--need to stop all lerps that may be currently happening for this animation id?
				--uevrUtils.cancelLerp(animID.."-"..animName)			

				M.animate(animID, animName, val)
			end
		end
	end
end

--initial["right_hand"]["thumb_01_r"]["rotation"] = {-49.577805387668, -13.69705658123, 96.563956884076}
--initial["right_hand"]["thumb_01_r"]["location"] = {-4.7485139256969, 1.6324441527213, 3.5768162332388}

function M.initializeBones(skeletalMeshComponent, initialTransform)
	if skeletalMeshComponent ~= nil and initialTransform ~= nil then
		for boneName, transforms in pairs(initialTransform) do
			local rotation, location, scale = M.getBoneSpaceLocalTransform(skeletalMeshComponent, uevrUtils.fname_from_string(boneName))
			--print("AAA",rotation, location, scale)
			--print("Scale",scale.X,scale.Y,scale.Z)
			if transforms["rotation"] ~= nil then
				rotation = uevrUtils.rotator(transforms["rotation"][1], transforms["rotation"][2], transforms["rotation"][3])
			end
			if transforms["location"] ~= nil then
				location = uevrUtils.vector(transforms["location"][1], transforms["location"][2], transforms["location"][3])
			end
			if transforms["scale"] ~= nil then
				scale = uevrUtils.vector(transforms["scale"][1], transforms["scale"][2], transforms["scale"][3])
			end
			-- print(rotation.Pitch,rotation.Yaw,rotation.Roll)
			-- print(location.X,location.Y,location.Z)
			-- print(scale.X,scale.Y,scale.Z)
			local localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
			M.setBoneSpaceLocalTransform(skeletalMeshComponent, uevrUtils.fname_from_string(boneName), localTransform)
		end
	end

end

function M.initialize(animID, skeletalMeshComponent)
	if animations ~= nil and animations[animID] ~= nil and animations[animID]["definitions"] ~= nil and animations[animID]["definitions"]["initialTranform"] ~= nil then
		local initialTransform = animations[animID]["definitions"]["initialTranform"]
		M.initializeBones(skeletalMeshComponent, initialTransform[animID])
		-- if initialTransform[animID] ~= nil then
			-- for boneName, transforms in pairs(initialTransform[animID]) do				
				-- local rotation, location, scale = M.getBoneSpaceLocalTransform(skeletalMeshComponent, uevrUtils.fname_from_string(boneName))
				-- if transforms["rotation"] ~= nil then
					-- rotation = uevrUtils.rotator(transforms["rotation"][1], transforms["rotation"][2], transforms["rotation"][3]) 
				-- end
				-- if transforms["location"] ~= nil then
					-- location = uevrUtils.vector(transforms["location"][1], transforms["location"][2], transforms["location"][3]) 
				-- end
				-- if transforms["scale"] ~= nil then
					-- location = uevrUtils.vector(transforms["scale"][1], transforms["scale"][2], transforms["scale"][3]) 
				-- end

				-- local localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
				-- M.setBoneSpaceLocalTransform(skeletalMeshComponent, uevrUtils.fname_from_string(boneName), localTransform)
			-- end		
		-- end
	else
		M.print("Initial tranform definitions not found", LogLevel.Info)
	end
end

function M.add(animID, skeletalMeshComponent, animationDefinitions)
	animations[animID] = {}
	animations[animID]["component"] = skeletalMeshComponent
	animations[animID]["definitions"] = animationDefinitions
end

-- function lerpCallback(animID, animName, alpha)
	-- print(animID, animName, alpha)
	-- lerpAnimation(animID, animName, alpha)
-- end

local function lerpCallback(alpha, progress, userdata)
	--print(alpha, progress, userdata.animID, userdata.animName,"\n")
	lerpAnimation(userdata.animID, userdata.animName, alpha)
end

local animStates = {}
function M.updateAnimation(animID, animName, isPressed, lerpParam)
	if animStates[animID] == nil then
		animStates[animID] = {}
		if animStates[animID][animName] == nil then
			animStates[animID][animName] = false
		end
	end
	if isPressed then
		if not animStates[animID][animName] == true then
			if lerpParam ~= nil then
				uevrUtils.lerp(animID.."-"..animName, lerpParam.startAlpha == nil and 0.0 or lerpParam.startAlpha, lerpParam.endAlpha == nil and 1.0 or lerpParam.endAlpha, lerpParam.duration == nil and 0.3 or lerpParam.duration, {animID = animID, animName = animName}, lerpCallback)
			else
				M.animate(animID, animName, "on")
			end
		end
		animStates[animID][animName] = true
	else
		if animStates[animID][animName] == true then
			if lerpParam ~= nil then
				uevrUtils.lerp(animID.."-"..animName, lerpParam.startAlpha == nil and 1.0 or lerpParam.startAlpha, lerpParam.endAlpha == nil and 0.0 or lerpParam.endAlpha, lerpParam.duration == nil and 0.3 or lerpParam.duration, {animID = animID, animName = animName}, lerpCallback)
			else
				M.animate(animID, animName, "off")
			end
		end
		animStates[animID][animName] = false
	end
end

function M.resetAnimation(animID, animName, isPressed)
	M.print("Resetting animation state for " .. animID .. " " .. animName .. " to " .. tostring(isPressed), LogLevel.Info)
	if animStates[animID] == nil then
		animStates[animID] = {}
	end
	animStates[animID][animName] = isPressed
end

-- creates a set of spheres that are positioned at each bone joint in order to visualize the bone hierarchy
function M.createSkeletalVisualization(skeletalMeshComponent, scale)
	if skeletalMeshComponent ~= nil then
		if scale == nil then scale = 0.003 end
		boneVisualizers = {}
		local count = skeletalMeshComponent:GetNumBones()
		M.print("Creating Skeletal Visualization with " .. count .. " bones", LogLevel.Info)
		for index = 1 , count do
			--uevrUtils.print(index .. " " .. skeletalMeshComponent:GetBoneName(index):to_string())
			boneVisualizers[index] = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			boneVisualizers[index]:SetVisibility(false,true)
			boneVisualizers[index]:SetVisibility(true,true)
			boneVisualizers[index]:SetHiddenInGame(true,true)
			boneVisualizers[index]:SetHiddenInGame(false,true)

			uevrUtils.set_component_relative_transform(boneVisualizers[index], nil, nil, {X=scale, Y=scale, Z=scale})
		end
	end
end

--call on the tick to do the actual position update
function M.updateSkeletalVisualization(skeletalMeshComponent)
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil and skeletalMeshComponent.GetNumBones ~= nil and #boneVisualizers > 0 then
		local count = skeletalMeshComponent:GetNumBones()
		local boneSpace = 0
		--print("updateSkeletalVisualization", skeletalMeshComponent, #boneVisualizers, "\n")
		for index = 1 , count do
			if boneVisualizers[index] ~= nil then
				local location = skeletalMeshComponent:GetBoneLocationByName(skeletalMeshComponent:GetBoneName(index), boneSpace)
				boneVisualizers[index]:K2_SetWorldLocation(location, false, reusable_hit_result, false)
				--location = skeletalMeshComponent:K2_GetComponentLocation()
				--print(location.X, location.Y, location.Z)
			end
		end
	end
end

function M.destroySkeletalVisualization()
	local count = #boneVisualizers
	M.print("Creating Skeletal Visualization with " .. count .. " bones", LogLevel.Info)
	for index = 1 , count do
		uevrUtils.destroyComponent( boneVisualizers[index], true)
	end
	boneVisualizers = {}
end

--scale a specific sphere in the hierarchy to a larger size and print that bone's name
function M.setSkeletalVisualizationBoneScale(skeletalMeshComponent, index, scale)
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		if index < 1 then index = 1 end
		if index > skeletalMeshComponent:GetNumBones() then index = skeletalMeshComponent:GetNumBones() end
		uevrUtils.print("Visualizing " .. index .. " " .. skeletalMeshComponent:GetBoneName(index):to_string())
		local component = boneVisualizers[index]
		component.RelativeScale3D.X = scale
		component.RelativeScale3D.Y = scale
		component.RelativeScale3D.Z = scale
	end
end
-- end of skeletal visualization

function M.getRootBoneOfBone(skeletalMeshComponent, boneName)
	local fName = uevrUtils.fname_from_string(boneName)
	local boneName = fName
	while fName:to_string() ~= "None" do
		boneName = fName
--		print(boneName:to_string())
		fName = skeletalMeshComponent:GetParentBone(fName)
	end
	return boneName
end

function M.getHierarchyForBone(skeletalMeshComponent, boneName)
	local str = ""
	local fName = uevrUtils.fname_from_string(boneName)
	while fName:to_string() ~= "None" do
		if str ~= "" then str = str .. " -> " end
		str = str .. fName:to_string()
		fName = skeletalMeshComponent:GetParentBone(fName)
	end
	-- repeat 
		-- fName = skeletalMeshComponent:GetParentBone(fName)
		-- str = str .. " -> " .. fName:to_string()
	-- until (fName == nil or fName:to_string() == "None")
	M.print(str, LogLevel.Critical)
end

function M.setBoneRotation(component, boneName, rotation, isDelta)
	if uevrUtils.validate_object(component) ~= nil and boneName ~= nil and rotation ~= nil then
		local boneSpace = 0
		local boneFName = uevrUtils.fname_from_string(boneName)
		local localRotator, pTransform = M.getBoneSpaceLocalRotator(component, boneFName, boneSpace)
		if localRotator ~= nil then
			if isDelta == true then
				localRotator.Pitch = localRotator.Pitch + rotation.Pitch
				localRotator.Yaw = localRotator.Yaw + rotation.Yaw
				localRotator.Roll = localRotator.Roll + rotation.Roll
			else
				localRotator = rotation
			end
			M.setBoneSpaceLocalRotator(component, boneFName, localRotator, boneSpace, pTransform)
		end
	end
end

--used by mod devs to update bone angles interactively
function M.setFingerAngles(component, boneList, fingerIndex, jointIndex, angleID, angle, isDelta, showDebug)
	if showDebug == nil then showDebug = true end
	if isDelta == nil then isDelta = true end
	local boneSpace = 0
	local boneFName = component:GetBoneName(boneList[fingerIndex] + jointIndex - 1, boneSpace)

	local localRotator, pTransform = M.getBoneSpaceLocalRotator(component, boneFName, boneSpace)
	if showDebug and localRotator ~= nil then M.print(boneFName:to_string() .. " Local Space Before: " .. fingerIndex .. " " .. jointIndex .. " " .. localRotator.Pitch .. " " .. localRotator.Yaw .. " " .. localRotator.Roll, LogLevel.Info) end
	if angleID == 0 then
		if isDelta and localRotator ~= nil then
			localRotator.Pitch = localRotator.Pitch + angle
		else
			localRotator.Pitch = angle
		end
	elseif angleID == 1 then
		if isDelta and localRotator ~= nil then
			localRotator.Yaw = localRotator.Yaw + angle
		else
			localRotator.Yaw = angle
		end
	elseif angleID == 2 then
		if isDelta and localRotator ~= nil then
			localRotator.Roll = localRotator.Roll + angle
		else
			localRotator.Roll = angle
		end
	end
	if showDebug and localRotator ~= nil then M.print(boneFName:to_string() .. " Local Space After: " .. fingerIndex .. " " .. jointIndex .. " " .. localRotator.Pitch .. " " .. localRotator.Yaw .. " " .. localRotator.Roll, LogLevel.Info) end
	M.setBoneSpaceLocalRotator(component, boneFName, localRotator, boneSpace, pTransform)

	if showDebug then M.logBoneRotators(component, boneList) end
end


function cleanFloat(num)
	if num < 0.0001 and num > -0.0001 then num = 0 end
	num = math.floor(num * 10000) / 10000
	return num
end

function M.getBoneRotator(component, boneList, fingerIndex, jointIndex)
	local boneSpace = 0
	local boneFName = component:GetBoneName(boneList[fingerIndex] + jointIndex - 1, boneSpace)

	local localRotator, pTransform = M.getBoneSpaceLocalRotator(component, boneFName, boneSpace)
	--M.print(boneFName:to_string() .. " Local Space Before: " .. fingerIndex .. " " .. jointIndex .. " " .. localRotator.Pitch .. " " .. localRotator.Yaw .. " " .. localRotator.Roll, LogLevel.Info)
	return localRotator
end

-- only set one of includeRotation, includeLocation, includeScale to true for any call
function M.getBoneTransforms(component, boneList, includeRotation, includeLocation, includeScale)
	if includeRotation == nil then includeRotation = true end
	if includeLocation == nil then includeLocation = false end
	if includeScale == nil then includeScale = false end
	local boneSpace = 0
	local rotators = {}
	if component ~= nil  then
		if component.GetBoneTransformByName == nil then
			M.print("Component does not support retrieval of bone transforms in function logBoneRotators() (eg not a poseableMeshComponent)")
		else
			for j = 1, #boneList do
				for index = 1 , 3 do
					local fName = component:GetBoneName(boneList[j] + index - 1)
					local rotation, location, scale = M.getBoneSpaceLocalTransform(component, fName, boneSpace)

					if includeRotation and rotation ~= nil then
						rotators[fName:to_string()] = {cleanFloat(rotation.Pitch), cleanFloat(rotation.Yaw), cleanFloat(rotation.Roll)}
					end
					if includeLocation and location ~= nil then
						rotators[fName:to_string()] = {cleanFloat(location.X), cleanFloat(location.Y), cleanFloat(location.Z)}
					end
					if includeScale and scale ~= nil then
						rotators[fName:to_string()] = {cleanFloat(scale.X), cleanFloat(scale.Y), cleanFloat(scale.Z)}
					end
				end
			end
		end
	end
	return rotators
end

function M.getDescendantBones(component, targetBoneName, includeRoot)
	if includeRoot == nil then includeRoot = false end
	local boneNames = {}
	if uevrUtils.getValid(component) ~= nil and targetBoneName ~= nil then
		local parentFName = uevrUtils.fname_from_string(targetBoneName)
		if includeRoot then
			parentFName = component:GetParentBone(uevrUtils.fname_from_string(targetBoneName)) --the bone above the target bone
		end
		local count = component:GetNumBones()
		local text = ""
		for index = 1 , count do
			local childFName = component:GetBoneName(index)
			if component:BoneIsChildOf(childFName, parentFName) then
				table.insert(boneNames, childFName:to_string())
			end
		end
	end
	return boneNames
end

function M.getAncestorBones(component, boneName)
	if component == nil then return {} end
	if boneName == nil or boneName == "" then return {component:GetBoneName(1)} end
	local boneNames = {}
	local fName = uevrUtils.fname_from_string(boneName)
	while fName:to_string() ~= "None" do
		table.insert(boneNames, fName:to_string())
		fName = component:GetParentBone(fName)
	end
	return boneNames
end

function M.logDescendantBoneTransforms(component, targetBoneName, includeRotation, includeLocation, includeScale)
	local parentFName = component:GetParentBone(uevrUtils.fname_from_string(targetBoneName)) --the bone above the target bone
	local count = component:GetNumBones()
	local text = ""
	for index = 1 , count do
		local childFName = component:GetBoneName(index)
		if component:BoneIsChildOf(childFName, parentFName) then
			local str = ""
			local rotation, location, scale = M.getBoneSpaceLocalTransform(component, childFName)
			if includeRotation and rotation ~= nil then
				str = str .. "rotation = {" .. cleanFloat(rotation.Pitch) .. ", " .. cleanFloat(rotation.Yaw) .. ", " .. cleanFloat(rotation.Roll) .. "}"
			end
			if includeLocation and location ~= nil then
				if str ~= "" then str = str .. ", " end
				str = str .. "location = {" .. cleanFloat(location.X) .. ", " .. cleanFloat(location.Y) .. ", " .. cleanFloat(location.Z) .. "}"
			end
			if includeScale and scale ~= nil then
				if str ~= "" then str = str .. ", " end
				str = str .. "scale = {" .. cleanFloat(scale.X) .. ", " .. cleanFloat(scale.Y) .. ", " .. cleanFloat(scale.Z) .. "}"
			end
			text = text .. "[\"" .. childFName:to_string() .. "\"] = {" .. str .. "}" .. "\n"
		end
	end
	M.print(text, LogLevel.Critical)
end

function M.logBoneRotators(component, boneList, includeRotation, includeLocation, includeScale)
	if includeRotation == nil then includeRotation = true end
	if includeLocation == nil then includeLocation = false end
	if includeScale == nil then includeScale = false end
	local boneSpace = 0
	if component ~= nil  then
		local text = ""
		if component.GetBoneTransformByName == nil then
			text = "Component does not support retrieval of bone transforms in function logBoneRotators() (eg not a poseableMeshComponent)"
		else
			--local pc = component
			--local parentFName =  uevrUtils.fname_from_string("r_Hand_JNT") --pc:GetParentBone(pc:GetBoneName(1))
			--local pTransform = pc:GetBoneTransformByName(parentFName, boneSpace)
			--local pRotator = pc:GetBoneRotationByName(parentFName, boneSpace)
			text = "Rotators for " .. component:get_full_name() .. "\n"

			for j = 1, #boneList do
				for index = 1 , 3 do
					local fName = component:GetBoneName(boneList[j] + index - 1)
					local rotation, location, scale = M.getBoneSpaceLocalTransform(component, fName, boneSpace)

					-- local pTransform = component:GetBoneTransformByName(component:GetParentBone(fName), boneSpace)
					-- local wTranform = component:GetBoneTransformByName(fName, boneSpace)
					-- --local localTransform = kismet_math_library:InvertTransform(pTransform) * wTranform
					-- --local localTransform = kismet_math_library:ComposeTransforms(kismet_math_library:InvertTransform(pTransform), wTranform)
					-- local localTransform = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(pTransform))
					-- local localRotator = uevrUtils.rotator(0, 0, 0)
					-- local localVector = uevrUtils.vector(0, 0, 0)
					-- local localScale = uevrUtils.vector(1, 1, 1)
					-- --kismet_math_library:BreakTransform(localTransform,temp_vec3, localRotator, temp_vec3)
					-- --print("Local Space1",index, localRotator.Pitch, localRotator.Yaw, localRotator.Roll)
					-- kismet_math_library:BreakTransform(localTransform, localVector, localRotator, localScale)
					-- --fix for non-working BreakTransform in robocop UB
					-- localRotator = kismet_math_library:TransformRotation(localTransform, uevrUtils.rotator(0,0,0))

					if includeRotation and rotation ~= nil then
						text = text .. "[\"" .. fName:to_string() .. "\"] = {" .. cleanFloat(rotation.Pitch) .. ", " .. cleanFloat(rotation.Yaw) .. ", " .. cleanFloat(rotation.Roll) .. "}" .. "\n"
					end
					if includeLocation and location ~= nil then
						text = text .. "[\"" .. fName:to_string() .. "\"] = {" .. cleanFloat(location.X) .. ", " .. cleanFloat(location.Y) .. ", " .. cleanFloat(location.Z) .. "}" .. "\n"
					end
					if includeScale and scale ~= nil then
						text = text .. "[\"" .. fName:to_string() .. "\"] = {" .. cleanFloat(scale.X) .. ", " .. cleanFloat(scale.Y) .. ", " .. cleanFloat(scale.Z) .. "}" .. "\n"
					end
					--["RightHandIndex1_JNT"] = {13.954909324646, 19.658151626587, 12.959843635559}
					-- local wRotator = pc:GetBoneRotationByName(pc:GetBoneName(index), boneSpace)
					-- --local relativeRotator = GetRelativeRotation(wRotator, pRotator) --wRotator - pRotator
					-- local relativeRotator = GetRelativeRotation(wRotator, pRotator)
					-- print("Local Space",index, relativeRotator.Pitch, relativeRotator.Yaw, relativeRotator.Roll)

					--[[
					print("World Space",index, wRotator.Pitch, wRotator.Yaw, wRotator.Roll)
					boneSpace = 1
					local cRotator = pc:GetBoneRotationByName(pc:GetBoneName(index), boneSpace)
					print("Component Space",index, cRotator.Pitch, cRotator.Yaw, cRotator.Roll)
					local boneRotator = uevrUtils.rotator(0, 0, 0)
					wRotator.Pitch = 0
					wRotator.Yaw = 0
					wRotator.Roll = 0
					pc:TransformToBoneSpace(pc:GetBoneName(index), temp_vec3, wRotator, temp_vec3, boneRotator)
					print("Bone Space",index, boneRotator.Pitch, boneRotator.Yaw, boneRotator.Roll)
					--pc:TransformFromBoneSpace(class FName BoneName, const struct FVector& InPosition, const struct FRotator& InRotation, struct FVector* OutPosition, struct FRotator* OutRotation);

					if pc.CachedBoneSpaceTransforms ~= nil then
						local transform = pc.CachedBoneSpaceTransforms[index]
						local boneRotator = uevrUtils.rotator(0, 0, 0)
						kismet_math_library:BreakTransform(transform, temp_vec3, boneRotator, temp_vec3)
						print("Bone Space",index, boneRotator.Pitch, boneRotator.Yaw, boneRotator.Roll)
					else
						print(pc.CachedBoneSpaceTransforms, pc.CachedComponentSpaceTransforms, pawn.FPVMesh.CachedBoneSpaceTransforms)
					end
					]]--
				end
			end
		end

		M.print(text, LogLevel.Critical)
	end
end

function M.getBoneNames(component)
	local boneNames = {}
	if component ~= nil then
		local count = component:GetNumBones()
		for index = 0 , count - 1 do
			table.insert(boneNames, component:GetBoneName(index):to_string())
		end
	else
		M.print("Can't get bone names because component was nil", LogLevel.Warning)
	end
	return boneNames
end


function M.logBoneNames(component)
	if component ~= nil then
		local count = component:GetNumBones()
		M.print(count .. " bones for " .. component:get_full_name(), LogLevel.Critical)
		for index = 0 , count - 1 do
			M.print(index .. " " .. component:GetBoneName(index):to_string(), LogLevel.Critical)
		end
	else
		M.print("Can't log bone name because component was nil", LogLevel.Warning)
	end
end

return M