--[[
Create a function to get a lerp alpha in lua that works with unreal and takes a delta input and includes a callback function 
that updates as alpha progresses and allows a configurable start and end alpha. It should also allow you to update the start 
and end alpha while it's running. Duration should be user configurable. Include the ability to pass userdata through
]]--

-- LerpAlpha implementation for Unreal Engine
local M = {}

-- Creates a new lerp alpha instance
function M.new(startAlpha, endAlpha, duration, userdata, callback)
    local self = {}
    
    -- Configurable properties
    self.startAlpha = startAlpha or 0
    self.endAlpha = endAlpha or 1
    self.duration = duration or 1 -- Duration in seconds, default to 1
    self.currentAlpha = self.startAlpha
    self.callback = callback
    self.userdata = userdata -- Custom userdata to pass to callback
    self.isRunning = false
    self.progress = 0
    
    -- Updates the lerp with delta time
    function self:tick(deltaTime)
        if not self.isRunning then return end
        
        -- Calculate progress (0 to 1)
        self.progress = self.progress + deltaTime
        local t = self.duration == 0 and 1 or math.min(self.progress / self.duration, 1)
        
        -- Perform lerp
        self.currentAlpha = self.duration == 0 and self.endAlpha or (self.startAlpha + (self.endAlpha - self.startAlpha) * t)
        
        -- Fire callback with current alpha, progress, and userdata
        if self.callback then
            self.callback(self.currentAlpha, t, self.userdata)
        end
        
        -- Stop when complete
        if t >= 1 then
            self.isRunning = false
        end
    end
    
    -- Starts or restarts the lerp
    function self:start()
        self.isRunning = true
        self.progress = 0
        self.currentAlpha = self.startAlpha
    end
    
    -- Stops the lerp
    function self:stop()
        self.isRunning = false
    end
    
    function self:isFinished()
        return self.isRunning == false
    end
    
    -- Updates start and end alpha values, duration, and optionally userdata
    function self:update(newStartAlpha, newEndAlpha, newDuration, newUserdata)
       -- If running, adjust current duration to maintain relative progress
		--print("Start", newStartAlpha, newEndAlpha, newDuration, "--", self.currentAlpha, self.startAlpha, self.endAlpha, self.duration, self.progress, "\n")
		newDuration = (newEndAlpha - self.currentAlpha) / (newEndAlpha - newStartAlpha) * newDuration
		self.progress = 0
        self.startAlpha = self.currentAlpha
        self.endAlpha = newEndAlpha or self.endAlpha
        self.duration = newDuration or self.duration
        self.userdata = newUserdata or self.userdata
 		--print("Final", self.currentAlpha, self.startAlpha, self.endAlpha, self.duration, self.progress, "\n")
     end
    
    return self
end

return M

-- Example usage in Unreal Lua
--[[
local function OnLerpUpdate(alpha, progress, userdata)
    print("Alpha: " .. alpha .. ", Progress: " .. progress .. ", Userdata: " .. tostring(userdata))
    -- Example: Update material parameter with userdata
    -- if userdata.actor then
    --     userdata.actor:SetMaterialScalarParameter(userdata.paramName, alpha)
    -- end
end

-- Create lerp instance with custom duration (2 seconds) and userdata
local myUserdata = { actor = SomeActor, paramName = "Opacity" }
local lerp = M.new(0, 1, 2, OnLerpUpdate, myUserdata)

-- Start lerp
lerp:start()

-- In Tick function:
function Tick(deltaTime)
    lerp:tick(deltaTime)
end

-- Update range, duration, and userdata while running
local newUserdata = { actor = AnotherActor, paramName = "Transparency" }
lerp:update(0.2, 0.8, 1.5, newUserdata)
--]]