-- Bubblegum Simulator Auto lua

-- UI COLOR CONFIGURATION
local COLORS = {
    background = Color3.new(0.1, 0.1, 0.1),           -- Dark grey background
    background_transparency = 0.1,                    -- Background transparency
    text = Color3.new(1, 1, 1),                       -- White text
    
    enabled_button = Color3.new(0.2, 0.8, 0.2),       -- Green when ON
    disabled_button = Color3.new(0.220,0.220,0.220),  -- Grey when OFF
    
    minimize = Color3.new(0.220,0.220,0.220),         -- Grey minimize
    close = Color3.new(0.8, 0.2, 0.2),                -- Red close
    minimized_button = Color3.new(0.1, 0.1, 0.1),     -- Dark grey background
    
    hover_transparency = 0.1                          -- Button hover transparency
}

-- CONFIGURATION
local CONFIG = {
    -- Timings
    spam_interval = 0.4,
    bubble_interval = 0.4,
    loop_wait = 0.1,
    
    -- UI Dimensions
    gui_size = UDim2.new(0, 200, 0, 120),
    gui_size_minimized = UDim2.new(0, 80, 0, 30),
    gui_position = UDim2.new(0, 10, 0, 10),
    corner_radius = 8,
    
    -- Bubble detection keywords
    bubble_keywords = {"blow", "bubble"}
}

-- SERVICES & VARIABLES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
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

-- UTILITY FUNCTIONS
local function safeCall(func)
    local success, result = pcall(func)
    return success and result
end

local function addCornerRadius(element, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or CONFIG.corner_radius)
    corner.Parent = element
    return corner
end

local function createGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "BubblegumAuto"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
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
    button.TextColor3 = COLORS.text
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.Parent = parent
    
    addCornerRadius(button, CONFIG.corner_radius)
    
    -- Hover effect
    local hoverTween = TweenService:Create(
        button,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        {BackgroundTransparency = COLORS.hover_transparency}
    )
    button.MouseEnter:Connect(function() hoverTween:Play() end)
    button.MouseLeave:Connect(function() hoverTween:Reverse() end)
    
    return button
end

-- GAME FUNCTIONALITY
local function cacheRemotes()
    if State.remotesCached then return end
    
    spawn(function()
        local remotes = {}
        
        -- Search for bubble-related remotes
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                for _, keyword in pairs(CONFIG.bubble_keywords) do
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
            wait(CONFIG.bubble_interval)
        end
        State.autoBlowRunning = false
    end)
end

local function updateButtonState(button, enabled, onText, offText, onColor, offColor)
    button.Text = enabled and onText or offText
    button.BackgroundColor3 = enabled and onColor or offColor
end

-- UI CREATION
local function createInterface()
    local gui = createGui()
    if not gui then return end
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = CONFIG.gui_size
    frame.Position = CONFIG.gui_position
    frame.BackgroundColor3 = COLORS.background
    frame.BackgroundTransparency = COLORS.background_transparency
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.ZIndex = 2
    frame.Parent = gui
    addCornerRadius(frame, CONFIG.corner_radius + 2)
    
    -- Minimized button (undraggable)
    local minimizedButton = createButton(
        "Auto-Lua",
        CONFIG.gui_size_minimized,
        UDim2.new(0, 0, 0, 0),
        COLORS.minimized_button,
        gui
    )
    minimizedButton.Visible = false
    minimizedButton.Active = true
    minimizedButton.Draggable = false
    
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
        COLORS.minimize,
        controlsContainer
    )
    minimizeButton.TextSize = 16
    
    -- Close button
    local closeButton = createButton(
        "X",
        UDim2.new(0, 20, 0, 20),
        UDim2.new(1, -25, 0, 2),
        COLORS.close,
        controlsContainer
    )
    closeButton.TextSize = 12
    
    -- Feature buttons
    local rButton = createButton(
        "R Spam: OFF",
        UDim2.new(0, 180, 0, 30),
        UDim2.new(0, 10, 0, 35),
        COLORS.disabled_button,
        frame
    )
    
    local bubbleButton = createButton(
        "Bubble: OFF",
        UDim2.new(0, 180, 0, 30),
        UDim2.new(0, 10, 0, 70),
        COLORS.disabled_button,
        frame
    )
    
    -- UI FUNCTIONALITY
    local function toggleMinimize()
        State.minimized = not State.minimized
        
        if State.minimized then
            local currentFramePos = frame.Position
            frame.Visible = false
            minimizedButton.Visible = true
            minimizedButton.Position = currentFramePos
        else
            local currentMinimizedPos = minimizedButton.Position
            frame.Position = currentMinimizedPos
            frame.Visible = true
            minimizedButton.Visible = false
        end
    end
    
    -- Button events
    minimizeButton.MouseButton1Click:Connect(toggleMinimize)
    minimizedButton.MouseButton1Click:Connect(toggleMinimize)
    closeButton.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    rButton.MouseButton1Click:Connect(function()
        State.rKeyEnabled = not State.rKeyEnabled
        updateButtonState(rButton, State.rKeyEnabled, "R Auto: ON", "R Auto: OFF", COLORS.enabled_button, COLORS.disabled_button)
    end)
    
    bubbleButton.MouseButton1Click:Connect(function()
        State.autoBubbleEnabled = not State.autoBubbleEnabled
        updateButtonState(bubbleButton, State.autoBubbleEnabled, "Bubble: ON", "Bubble: OFF", COLORS.enabled_button, COLORS.disabled_button)
        
        if State.autoBubbleEnabled then
            startAutoBubble()
        end
    end) 
    return gui
end

-- MAIN EXECUTION
local function main()
    cacheRemotes()
    
    local gui = createInterface()
    if not gui then return end
    
    -- Main loop
    spawn(function()
        while gui.Parent do
            local currentTime = tick()
            
            if State.rKeyEnabled and (currentTime - State.lastRTime) >= CONFIG.spam_interval then
                pressRKey()
                State.lastRTime = currentTime
            end
            wait(CONFIG.loop_wait)
        end
    end)
end

-- Initialize
main()
