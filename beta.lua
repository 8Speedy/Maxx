-- Bubblegum Simulator Auto Hatch/Bubble
-- Lua language

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Constants
local SPAM_INTERVAL = 0.4
local BUBBLE_INTERVAL = 0.4
local LOOP_WAIT = 0.1
local GUI_SIZE = UDim2.new(0, 200, 0, 120)
local GUI_SIZE_MINIMIZED = UDim2.new(0, 80, 0, 30)
local GUI_POSITION = UDim2.new(0, 10, 0, 10)

-- Bubble keywords for remote detection
local BUBBLE_KEYWORDS = {"blow", "bubble", "gum", "inflate", "chew", "pop"}

local player = Players.LocalPlayer

-- State management
local State = {
    rKeyEnabled = false,
    autoBubbleEnabled = false,
    autoBlowRunning = false,
    lastRTime = 0,
    bubbleRemotes = {},
    remotesCached = false,
    minimized = false
}

-- Utility functions
local function safeCall(func)
    local success, result = pcall(func)
    return success and result
end

local function createGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BubblegumAuto"
    gui.ResetOnSpawn = false
    
    -- Try CoreGui first, fallback to PlayerGui
    if not safeCall(function() gui.Parent = CoreGui end) then
        safeCall(function() gui.Parent = player:WaitForChild("PlayerGui") end)
    end
    
    return gui
end

local function createButton(text, size, position, color, parent)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.new(0.2, 0.2, 0.2)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.Parent = parent
    
    -- Add hover effect
    local hoverTween = TweenService:Create(
        button,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {BackgroundTransparency = 0.1}
    )
    
    button.MouseEnter:Connect(function() hoverTween:Play() end)
    button.MouseLeave:Connect(function() hoverTween:Reverse() end)
    
    return button
end

local function cacheRemotes()
    if State.remotesCached then return end
    
    spawn(function()
        local remotes = {}
        
        -- Search for bubble-related remotes
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                for _, keyword in pairs(BUBBLE_KEYWORDS) do
                    if name:find(keyword) then
                        table.insert(remotes, obj)
                        break
                    end
                end
            end
        end
        
        -- Fallback: get first few remotes if no specific ones found
        if #remotes < 2 then
            local count = 0
            for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and count < 5 then
                    table.insert(remotes, obj)
                    count = count + 1
                end
            end
        end
        
        State.bubbleRemotes = remotes
        State.remotesCached = true
    end)
end

local function pressRKey()
    spawn(function()
        safeCall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end)
    end)
end

local function fireBubbleRemotes()
    if not State.remotesCached then return end
    
    if #State.bubbleRemotes > 0 then
        -- Use cached remotes (more efficient)
        for _, remote in pairs(State.bubbleRemotes) do
            safeCall(function() remote:FireServer() end)
            safeCall(function() remote:FireServer("BlowBubble") end)
        end
    else
        -- Fallback method
        safeCall(function()
            for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    safeCall(function() obj:FireServer("BlowBubble") end)
                end
            end
        end)
    end
end

local function startAutoBubble()
    if State.autoBlowRunning then return end
    State.autoBlowRunning = true
    
    spawn(function()
        while State.autoBubbleEnabled do
            fireBubbleRemotes()
            wait(BUBBLE_INTERVAL)
        end
        State.autoBlowRunning = false
    end)
end

local function updateButtonState(button, enabled, onText, offText, onColor, offColor)
    button.Text = (enabled and onText or offText)
    button.BackgroundColor3 = enabled and onColor or offColor
end

local function createInterface()
    local gui = createGui()
    if not gui then return end
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = GUI_SIZE
    frame.Position = GUI_POSITION
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    
    -- Minimized button (initially hidden)
    local minimizedButton = createButton(
        "Auto-Lua",
        GUI_SIZE_MINIMIZED,
        UDim2.new(0, 0, 0, 0),
        Color3.new(0.2, 0.6, 0.2),
        gui
    )
    minimizedButton.Visible = false
    minimizedButton.Active = true
    minimizedButton.Draggable = true
    
    -- Control buttons container
    local controlsContainer = Instance.new("Frame")
    controlsContainer.Size = UDim2.new(1, -10, 0, 25)
    controlsContainer.Position = UDim2.new(0, 5, 0, 5)
    controlsContainer.BackgroundTransparency = 1
    controlsContainer.Parent = frame
    
    -- Minimize button
    local minimizeButton = createButton(
        "-",
        UDim2.new(0, 20, 0, 20),
        UDim2.new(1, -50, 0, 2),
        Color3.new(0.6, 0.6, 0.2),
        controlsContainer
    )
    minimizeButton.TextSize = 16
    
    -- Close button
    local closeButton = createButton(
        "X",
        UDim2.new(0, 20, 0, 20),
        UDim2.new(1, -25, 0, 2),
        Color3.new(0.8, 0.2, 0.2),
        controlsContainer
    )
    closeButton.TextSize = 12
    
    -- Feature buttons
    local rButton = createButton(
        "R Spam: OFF",
        UDim2.new(0, 180, 0, 30),
        UDim2.new(0, 10, 0, 35),
        Color3.new(0.8, 0.2, 0.2),
        frame
    )
    
    local bubbleButton = createButton(
        "Bubble: OFF",
        UDim2.new(0, 180, 0, 30),
        UDim2.new(0, 10, 0, 70),
        Color3.new(0.2, 0.2, 0.8),
        frame
    )
    
    local function toggleMinimize()
        State.minimized = not State.minimized
        
        if State.minimized then
            -- Minimize
            frame.Visible = false
            minimizedButton.Visible = true
            minimizedButton.Position = frame.Position
        else
            -- Restore
            frame.Visible = true
            minimizedButton.Visible = false
        end
    end
    
    -- Button events
    minimizeButton.MouseButton1Click:Connect(toggleMinimize)
    
    minimizedButton.MouseButton1Click:Connect(toggleMinimize)
    
    rButton.MouseButton1Click:Connect(function()
        State.rKeyEnabled = not State.rKeyEnabled
        updateButtonState(
            rButton,
            State.rKeyEnabled,
            "R Spam: ON",
            "R Spam: OFF",
            Color3.new(0.2, 0.8, 0.2),
            Color3.new(0.8, 0.2, 0.2)
        )
    end)
    
    bubbleButton.MouseButton1Click:Connect(function()
        State.autoBubbleEnabled = not State.autoBubbleEnabled
        updateButtonState(
            bubbleButton,
            State.autoBubbleEnabled,
            "Bubble: ON",
            "Bubble: OFF",
            Color3.new(0.2, 0.8, 0.2),
            Color3.new(0.2, 0.2, 0.8)
        )
        
        if State.autoBubbleEnabled then
            startAutoBubble()
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    return gui
end

-- Main execution
local function main()
    -- Cache remotes on startup
    cacheRemotes()
    
    -- Create interface
    local gui = createInterface()
    if not gui then return end
    
    -- Main loop
    spawn(function()
        while gui.Parent do
            local currentTime = tick()
            
            -- R Key spam
            if State.rKeyEnabled and (currentTime - State.lastRTime) >= SPAM_INTERVAL then
                pressRKey()
                State.lastRTime = currentTime
            end
            
            wait(LOOP_WAIT)
        end
    end)
end

-- Initialize
main()
