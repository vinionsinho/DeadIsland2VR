local uevrUtils = require("libs/uevr_utils")

local M = {}

function testVector()
	print("Vector Test 1 passed:", uevrUtils.vector(30, 40, 50).X == 30)
	print("Vector Test 2 passed:", uevrUtils.vector(30, 40, 50).Y == 40)
	print("Vector Test 3 passed:", uevrUtils.vector(30, 40, 50).Z == 50)
	print("Vector Test 4 passed:", uevrUtils.vector({X=30,Y=40,Z=50}).X == 30)
	print("Vector Test 5 passed:", uevrUtils.vector({X=30,Y=40,Z=50}).Y == 40)
	print("Vector Test 6 passed:", uevrUtils.vector({X=30,Y=40,Z=50}).Z == 50)
	print("Vector Test 7 passed:", uevrUtils.vector({x=30,y=40,z=50}).X == 30)
	print("Vector Test 8 passed:", uevrUtils.vector({x=30,y=40,z=50}).Y == 40)
	print("Vector Test 9 passed:", uevrUtils.vector({x=30,y=40,z=50}).Z == 50)
	temp_vec3f:set(30,40,50)
	print("Vector Test 10 passed:", uevrUtils.vector(temp_vec3f).X == 30)
	print("Vector Test 11 passed:", uevrUtils.vector(temp_vec3f).Y == 40)
	print("Vector Test 12 passed:", uevrUtils.vector(temp_vec3f).Z == 50)
	local vector = uevrUtils.vector(30, 40, 50)
	print("Vector Test 13 passed:", uevrUtils.vector(vector).X == 30)
	print("Vector Test 14 passed:", uevrUtils.vector(vector).Y == 40)
	print("Vector Test 15 passed:", uevrUtils.vector(vector).Z == 50)

end

function M.run()
	print("Unit test begin")
	testVector()
	print("Unit test end")
end

return M