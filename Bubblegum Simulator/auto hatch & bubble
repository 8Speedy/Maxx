-- Bubblegum Simulator auto hatch/bubble (LEGIT)
-- Lua language

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- State variables
local rKeyEnabled = false
local autoBubbleEnabled = false
local autoBlowRunning = false
local lastRTime = 0

-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "BubblegumAuto"
gui.ResetOnSpawn = false

-- Try multiple parent options for compatibility
local success = pcall(function()
    gui.Parent = CoreGui
end)

if not success then
    pcall(function()
        gui.Parent = player:WaitForChild("PlayerGui")
    end)
end

-- Create main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 80)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

-- R Key Spam Button
local rButton = Instance.new("TextButton")
rButton.Size = UDim2.new(0, 90, 0, 30)
rButton.Position = UDim2.new(0, 5, 0, 5)
rButton.Text = "R Spam: OFF"
rButton.TextColor3 = Color3.new(1, 1, 1)
rButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
rButton.BorderSizePixel = 1
rButton.Font = Enum.Font.SourceSans
rButton.TextSize = 14
rButton.Parent = frame

-- Auto Bubble Button
local bubbleButton = Instance.new("TextButton")
bubbleButton.Size = UDim2.new(0, 90, 0, 30)
bubbleButton.Position = UDim2.new(0, 105, 0, 5)
bubbleButton.Text = "Bubble: OFF"
bubbleButton.TextColor3 = Color3.new(1, 1, 1)
bubbleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)
bubbleButton.BorderSizePixel = 1
bubbleButton.Font = Enum.Font.SourceSans
bubbleButton.TextSize = 14
bubbleButton.Parent = frame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(0, 175, 0, 55)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
closeButton.BorderSizePixel = 1
closeButton.Font = Enum.Font.SourceSans
closeButton.TextSize = 12
closeButton.Parent = frame

-- Virtual R key function
local function pressRKey()
    spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end)
    end)
end

-- Optimized auto bubble method from EXAMPLE_script
local function autoBubbleLoop()
    if autoBlowRunning then return end
    autoBlowRunning = true



    --Cache the most likely bubble remotes to avoid repeated searches
    local bubbleRemotes = {}
    local searchComplete = false

    --Find and cache bubble - related remotes only once
    spawn(function()
        --Common remote names related to bubbles in these types of games
        local bubbleKeywords = { "blow", "bubble", "gum", "inflate", "chew" }

        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                local name = v.Name:lower()
                --Check if name contains bubble - related keywords
                for _, keyword in pairs(bubbleKeywords) do
                    if name:find(keyword) then
                        table.insert(bubbleRemotes, v)
                        break
                    end
                end
            end
        end

        -- If no specific bubble remotes found, add a few general remotes as fallback
        if #bubbleRemotes < 2 then
            local count = 0
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and count < 5 then
                    table.insert(bubbleRemotes, v)
                    count = count + 1
                end
            end
        end

        searchComplete = true
    end)

    --Actual auto blow loop
    spawn(function()
        while autoBubbleEnabled do
            -- Wait for cache to be ready
            if searchComplete then
                if #bubbleRemotes > 0 then
                    -- Try specific cached remotes first(more efficient)
                    for _, remote in pairs(bubbleRemotes) do
                        pcall(function() remote:FireServer() end)
                        pcall(function() remote:FireServer("BlowBubble") end)
                    end
                else
                    --Fallback to original method
                    pcall(function()
                        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                                pcall(function() v:FireServer("BlowBubble") end)
                            end
                        end
                    end)
                end
            end

            -- Constant wait time
            wait(0.4)
        end

        -- Clean up
        autoBlowRunning = false
    end)
end

-- Button click events
rButton.MouseButton1Click:Connect(function()
    rKeyEnabled = not rKeyEnabled
    rButton.Text = "R Spam: " .. (rKeyEnabled and "ON" or "OFF")
    rButton.BackgroundColor3 = rKeyEnabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
end)

bubbleButton.MouseButton1Click:Connect(function()
    autoBubbleEnabled = not autoBubbleEnabled
    bubbleButton.Text = "Bubble: " .. (autoBubbleEnabled and "ON" or "OFF")
    bubbleButton.BackgroundColor3 = autoBubbleEnabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.2, 0.2, 0.8)
    
    if autoBubbleEnabled then
        autoBubbleLoop()
    end
end)

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Main execution loop (Only R Key spam now)
spawn(function()
    while gui.Parent do
        local currentTime = tick()
        
        -- R Key spam every 0.4 seconds
        if rKeyEnabled and (currentTime - lastRTime) >= 0.4 then
            pressRKey()
            lastRTime = currentTime
        end
        
        wait(0.1) -- Consistent loop timing
    end
end)
