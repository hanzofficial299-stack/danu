local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- Network Setup
local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

-- Configuration
local Config = {
    BlatantMode = false,
    NoAnimation = false,
    
    -- FITUR BARU: Fly, Speed, Noclip
    FlyEnabled = false,
    SpeedEnabled = false,
    NoclipEnabled = false,
    FlySpeed = 50,
    WalkSpeed = 50,
    
    -- Delay Settings
    ReelDelay = 0.1,
    FishingDelay = 0.2,
    ChargeTime = 0.3,
    
    -- Multi-Cast Settings
    MultiCast = false,
    CastAmount = 3,
    
    -- Cast Settings 
    CastPower = 0.55,
    CastAngleMin = -0.8,
    CastAngleMax = 0.8
}

-- Stats Tracking
local Stats = {
    StartTime = 0,
    FishCaught = 0,
    Attempts = 0,
    Errors = 0,
    TotalSold = 0
}

-- Animation Controller
local AnimationController = {
    OriginalAnimate = nil,
    IsDisabled = false,
    Connection = nil
}

-- FITUR BARU: Fly Controller
local FlyController = {
    BodyVelocity = nil,
    BodyGyro = nil,
    Connection = nil
}

-- FITUR BARU: Noclip Controller
local NoclipController = {
    Connection = nil
}

function AnimationController:Disable()
    if self.IsDisabled then return end
    
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:Stop()
            end
            
            self.Connection = humanoid.AnimationPlayed:Connect(function(animTrack)
                if Config.NoAnimation then
                    animTrack:Stop()
                end
            end)
        end
        
        local animate = char:FindFirstChild("Animate")
        if animate then
            self.OriginalAnimate = animate:Clone()
            animate.Enabled = false
        end
    end)
    
    self.IsDisabled = true
    print("🚫 Animations disabled")
end

function AnimationController:Enable()
    if not self.IsDisabled then return end
    
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        
        local animate = char:FindFirstChild("Animate")
        if animate then
            animate.Enabled = true
        end
    end)
    
    self.IsDisabled = false
    print("✅ Animations enabled")
end

-- FITUR BARU: Fly Functions
function FlyController:Enable()
    if self.Connection then return end
    
    local function setupFly()
        local char = Player.Character
        if not char then return end
        
        local humanoid = char:FindFirstChild("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not rootPart then return end
        
        -- Hapus yang lama
        if self.BodyVelocity then self.BodyVelocity:Destroy() end
        if self.BodyGyro then self.BodyGyro:Destroy() end
        
        -- Buat BodyVelocity untuk movement
        self.BodyVelocity = Instance.new("BodyVelocity")
        self.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
        self.BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        self.BodyVelocity.P = 1000
        self.BodyVelocity.Parent = rootPart
        
        -- Buat BodyGyro untuk stabilisasi
        self.BodyGyro = Instance.new("BodyGyro")
        self.BodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
        self.BodyGyro.P = 1000
        self.BodyGyro.D = 50
        self.BodyGyro.Parent = rootPart
        
        -- Setup fly loop
        self.Connection = RunService.Heartbeat:Connect(function()
            if not Config.FlyEnabled or not char or not rootPart then
                self:Disable()
                return
            end
            
            local camera = workspace.CurrentCamera
            if not camera then return end
            
            -- Update gyro untuk menghadap ke arah kamera
            self.BodyGyro.CFrame = camera.CFrame
            
            -- Calculate movement direction
            local moveDirection = Vector3.new(0, 0, 0)
            
            -- Forward/Backward (W/S)
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + camera.CFrame.LookVector
            end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - camera.CFrame.LookVector
            end
            
            -- Left/Right (A/D)
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - camera.CFrame.RightVector
            end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + camera.CFrame.RightVector
            end
            
            -- Up/Down (Space/Shift)
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection + Vector3.new(0, -1, 0)
            end
            
            -- Normalize dan apply speed
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * Config.FlySpeed
            end
            
            self.BodyVelocity.Velocity = moveDirection
        end)
    end
    
    -- Setup initial fly
    setupFly()
    
    -- Reconnect jika character respawn
    Player.CharacterAdded:Connect(function()
        if Config.FlyEnabled then
            task.wait(1)
            setupFly()
        end
    end)
    
    print("🕊️ Fly enabled - Use WASD, Space/Shift to fly")
end

function FlyController:Disable()
    if self.BodyVelocity then
        self.BodyVelocity:Destroy()
        self.BodyVelocity = nil
    end
    if self.BodyGyro then
        self.BodyGyro:Destroy()
        self.BodyGyro = nil
    end
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    print("🕊️ Fly disabled")
end

-- FITUR BARU: Speed Function
local function updateSpeed()
    local char = Player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        if Config.SpeedEnabled then
            humanoid.WalkSpeed = Config.WalkSpeed
        else
            humanoid.WalkSpeed = 16 -- Default speed
        end
    end
end

-- FITUR BARU: Noclip Functions
function NoclipController:Enable()
    if self.Connection then return end
    
    self.Connection = RunService.Stepped:Connect(function()
        if not Config.NoclipEnabled then
            self:Disable()
            return
        end
        
        local char = Player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    print("👻 Noclip enabled - You can walk through walls")
end

function NoclipController:Disable()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    
    -- Restore collision
    local char = Player.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    print("👻 Noclip disabled")
end

-- FITUR BARU: Sell Fish Function
local function SellAllFish()
    local success, result = pcall(function()
        return Net["RF/SellAllItems"]:InvokeServer()
    end)
    
    if success then
        Stats.TotalSold = Stats.TotalSold + 1
        print("💰 Successfully sold all fish!")
        return true
    else
        warn("❌ Failed to sell fish: " .. tostring(result))
        return false
    end
end

-- Anti-AFK System
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- FISHING FUNCTIONS

local FishingActive = false

-- Function single cast
local function ExecuteSingleCast()
    local success, errorMsg = pcall(function()
        -- Step 1: Charge Rod
        Net["RF/ChargeFishingRod"]:InvokeServer()
        task.wait(Config.ChargeTime)
        
        -- Step 2: Cast Rod
        local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
        local castTime = os.clock()
        
        Net["RF/RequestFishingMinigameStarted"]:InvokeServer(
            angle,
            Config.CastPower,
            castTime
        )
        
        -- Step 3: Tunggu bentar
        task.wait(0.1)
        
        -- Step 4: Complete fishing
        task.wait(Config.ReelDelay)
        Net["RE/FishingCompleted"]:FireServer()
        
        -- Step 5: Double complete
        task.wait(0.05)
        Net["RE/FishingCompleted"]:FireServer()
        
        Stats.FishCaught = Stats.FishCaught + 1
        Stats.Attempts = Stats.Attempts + 1
        
        print(string.format("✅ Fish caught! Total: %d", Stats.FishCaught))
    end)
    
    if not success then
        Stats.Errors = Stats.Errors + 1
        warn(string.format("❌ Error: %s", tostring(errorMsg)))
    end
end

-- FUNCTION MULTI-CAST
local function ExecuteMultiCast()
    local success, errorMsg = pcall(function()
        local completed = 0
        
        for i = 1, Config.CastAmount do
            task.spawn(function()
                -- Charge rod
                Net["RF/ChargeFishingRod"]:InvokeServer()
                task.wait(Config.ChargeTime)
                
                -- Cast dengan angle berbeda
                local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
                local castTime = os.clock()
                
                Net["RF/RequestFishingMinigameStarted"]:InvokeServer(
                    angle,
                    Config.CastPower,
                    castTime
                )
                
                -- Completion sequence
                task.wait(Config.ReelDelay)
                Net["RE/FishingCompleted"]:FireServer()
                task.wait(0.03)
                Net["RE/FishingCompleted"]:FireServer()
                
                Stats.FishCaught = Stats.FishCaught + 1
                Stats.Attempts = Stats.Attempts + 1
                completed = completed + 1
            end)
            
            task.wait(0.05)
        end
        
        local maxWaitTime = (Config.ChargeTime + Config.ReelDelay + 0.2) * Config.CastAmount
        local startWait = os.clock()
        
        while completed < Config.CastAmount and (os.clock() - startWait) < maxWaitTime do
            task.wait(0.1)
        end
        
        if completed == Config.CastAmount then
            print(string.format("🎯 Multi-cast completed! Total: %d fish", Config.CastAmount))
        else
            print(string.format("⚠️ Multi-cast partial: %d/%d completed", completed, Config.CastAmount))
        end
    end)
    
    if not success then
        Stats.Errors = Stats.Errors + 1
        warn(string.format("❌ Multi-cast Error: %s", tostring(errorMsg)))
    end
end

-- Main fishing loop
local function StartBlatantLoop()
    while Config.BlatantMode do
        if not FishingActive then
            FishingActive = true
            
            if Config.MultiCast then
                ExecuteMultiCast()
            else
                ExecuteSingleCast()
            end
            
            FishingActive = false
            task.wait(Config.FishingDelay)
        end
        task.wait(0.05)
    end
end

-- CREATE GUI DENGAN TAB SYSTEM

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DanuScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 80, 80)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5
UIStroke.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🎣 DANU SCRIPT"
Title.TextColor3 = Color3.fromRGB(255, 100, 100)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, 0, 0, 18)
Subtitle.Position = UDim2.new(0, 0, 0, 38)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Fishing Bot & Cheat Menu"
Subtitle.TextColor3 = Color3.fromRGB(140, 140, 150)
Subtitle.TextSize = 9
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = MainFrame

-- Tab Buttons
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 360, 0, 40)
TabContainer.Position = UDim2.new(0.5, -180, 0, 60)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local FishingTabBtn = Instance.new("TextButton")
FishingTabBtn.Size = UDim2.new(0, 175, 0, 35)
FishingTabBtn.Position = UDim2.new(0, 0, 0, 0)
FishingTabBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
FishingTabBtn.Text = "🎣 FISHING"
FishingTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FishingTabBtn.TextSize = 14
FishingTabBtn.Font = Enum.Font.GothamBold
FishingTabBtn.Parent = TabContainer

local FishingTabCorner = Instance.new("UICorner")
FishingTabCorner.CornerRadius = UDim.new(0, 6)
FishingTabCorner.Parent = FishingTabBtn

local CheatTabBtn = Instance.new("TextButton")
CheatTabBtn.Size = UDim2.new(0, 175, 0, 35)
CheatTabBtn.Position = UDim2.new(1, -175, 0, 0)
CheatTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
CheatTabBtn.Text = "⚡ CHEAT MODE"
CheatTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CheatTabBtn.TextSize = 14
CheatTabBtn.Font = Enum.Font.GothamBold
CheatTabBtn.Parent = TabContainer

local CheatTabCorner = Instance.new("UICorner")
CheatTabCorner.CornerRadius = UDim.new(0, 6)
CheatTabCorner.Parent = CheatTabBtn

-- Content Frames
local FishingFrame = Instance.new("Frame")
FishingFrame.Size = UDim2.new(0, 360, 0, 350)
FishingFrame.Position = UDim2.new(0.5, -180, 0, 110)
FishingFrame.BackgroundTransparency = 1
FishingFrame.Visible = true
FishingFrame.Parent = MainFrame

local CheatFrame = Instance.new("Frame")
CheatFrame.Size = UDim2.new(0, 360, 0, 350)
CheatFrame.Position = UDim2.new(0.5, -180, 0, 110)
CheatFrame.BackgroundTransparency = 1
CheatFrame.Visible = false
CheatFrame.Parent = MainFrame

-- FISHING FRAME CONTENT

-- Blatant Mode Button
local BlatantBtn = Instance.new("TextButton")
BlatantBtn.Size = UDim2.new(0, 360, 0, 45)
BlatantBtn.Position = UDim2.new(0, 0, 0, 0)
BlatantBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
BlatantBtn.Text = "🚀 START BLATANT MODE"
BlatantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BlatantBtn.TextSize = 16
BlatantBtn.Font = Enum.Font.GothamBold
BlatantBtn.Parent = FishingFrame

local BlatantCorner = Instance.new("UICorner")
BlatantCorner.CornerRadius = UDim.new(0, 8)
BlatantCorner.Parent = BlatantBtn

BlatantBtn.MouseButton1Click:Connect(function()
    Config.BlatantMode = not Config.BlatantMode
    
    if Config.BlatantMode then
        BlatantBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        BlatantBtn.Text = "⏸ STOP BLATANT MODE"
        
        Stats.StartTime = os.clock()
        Stats.FishCaught = 0
        Stats.Attempts = 0
        Stats.Errors = 0
        
        print("\n" .. string.rep("=", 50))
        print("🚀 BLATANT FISHING STARTED")
        print("Mode: " .. (Config.MultiCast and "MULTI-CAST" or "SINGLE CAST"))
        print(string.rep("=", 50))
        
        task.spawn(StartBlatantLoop)
    else
        BlatantBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        BlatantBtn.Text = "🚀 START BLATANT MODE"
        
        print("\n" .. string.rep("=", 50))
        print("🛑 BLATANT FISHING STOPPED")
        print(string.format("📊 Caught: %d fish", Stats.FishCaught))
        print(string.rep("=", 50))
        
        FishingActive = false
    end
end)

-- Fishing Toggle Container
local FishingToggleContainer = Instance.new("Frame")
FishingToggleContainer.Size = UDim2.new(0, 360, 0, 45)
FishingToggleContainer.Position = UDim2.new(0, 0, 0, 55)
FishingToggleContainer.BackgroundTransparency = 1
FishingToggleContainer.Parent = FishingFrame

-- No Animation Toggle
local NoAnimBtn = Instance.new("TextButton")
NoAnimBtn.Size = UDim2.new(0, 175, 0, 45)
NoAnimBtn.Position = UDim2.new(0, 0, 0, 0)
NoAnimBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
NoAnimBtn.Text = "🚫 Anim: OFF"
NoAnimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoAnimBtn.TextSize = 14
NoAnimBtn.Font = Enum.Font.GothamBold
NoAnimBtn.Parent = FishingToggleContainer

local NoAnimCorner = Instance.new("UICorner")
NoAnimCorner.CornerRadius = UDim.new(0, 8)
NoAnimCorner.Parent = NoAnimBtn

NoAnimBtn.MouseButton1Click:Connect(function()
    Config.NoAnimation = not Config.NoAnimation
    if Config.NoAnimation then
        NoAnimBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        NoAnimBtn.Text = "🚫 Anim: ON"
        AnimationController:Disable()
    else
        NoAnimBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        NoAnimBtn.Text = "🚫 Anim: OFF"
        AnimationController:Enable()
    end
end)

-- Multi-Cast Toggle
local MultiCastBtn = Instance.new("TextButton")
MultiCastBtn.Size = UDim2.new(0, 175, 0, 45)
MultiCastBtn.Position = UDim2.new(1, -175, 0, 0)
MultiCastBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
MultiCastBtn.Text = "🎯 Single Cast"
MultiCastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MultiCastBtn.TextSize = 14
MultiCastBtn.Font = Enum.Font.GothamBold
MultiCastBtn.Parent = FishingToggleContainer

local MultiCastCorner = Instance.new("UICorner")
MultiCastCorner.CornerRadius = UDim.new(0, 8)
MultiCastCorner.Parent = MultiCastBtn

MultiCastBtn.MouseButton1Click:Connect(function()
    Config.MultiCast = not Config.MultiCast
    if Config.MultiCast then
        MultiCastBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        MultiCastBtn.Text = "🎯 Multi-Cast"
        print("✅ Multi-Cast mode enabled")
    else
        MultiCastBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        MultiCastBtn.Text = "🎯 Single Cast"
        print("✅ Single Cast mode enabled")
    end
end)

-- Sell Fish Button
local SellFishBtn = Instance.new("TextButton")
SellFishBtn.Size = UDim2.new(0, 360, 0, 35)
SellFishBtn.Position = UDim2.new(0, 0, 0, 110)
SellFishBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
SellFishBtn.Text = "💸 SELL ALL FISH"
SellFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SellFishBtn.TextSize = 14
SellFishBtn.Font = Enum.Font.GothamBold
SellFishBtn.Parent = FishingFrame

local SellFishCorner = Instance.new("UICorner")
SellFishCorner.CornerRadius = UDim.new(0, 6)
SellFishCorner.Parent = SellFishBtn

SellFishBtn.MouseButton1Click:Connect(function()
    print("🔄 Selling all fish...")
    SellAllFish()
end)

-- Fishing Settings Label
local FishingSettingsLabel = Instance.new("TextLabel")
FishingSettingsLabel.Size = UDim2.new(1, -40, 0, 25)
FishingSettingsLabel.Position = UDim2.new(0, 20, 0, 155)
FishingSettingsLabel.BackgroundTransparency = 1
FishingSettingsLabel.Text = "⚙️ FISHING SETTINGS"
FishingSettingsLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
FishingSettingsLabel.TextSize = 13
FishingSettingsLabel.Font = Enum.Font.GothamBold
FishingSettingsLabel.TextXAlignment = Enum.TextXAlignment.Left
FishingSettingsLabel.Parent = FishingFrame

-- Fishing Settings Container
local FishingScrollFrame = Instance.new("ScrollingFrame")
FishingScrollFrame.Size = UDim2.new(0, 360, 0, 150)
FishingScrollFrame.Position = UDim2.new(0, 0, 0, 185)
FishingScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
FishingScrollFrame.ScrollBarThickness = 6
FishingScrollFrame.Parent = FishingFrame

local FishingScrollCorner = Instance.new("UICorner")
FishingScrollCorner.CornerRadius = UDim.new(0, 8)
FishingScrollCorner.Parent = FishingScrollFrame

local FishingLayout = Instance.new("UIListLayout")
FishingLayout.Padding = UDim.new(0, 8)
FishingLayout.Parent = FishingScrollFrame

-- Function untuk bikin fishing setting
local function CreateFishingSetting(name, configKey, defaultValue, description, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    container.LayoutOrder = layoutOrder
    container.Parent = FishingScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 12
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0, 180, 0, 16)
    desc.Position = UDim2.new(0, 10, 0, 28)
    desc.BackgroundTransparency = 1
    desc.Text = description
    desc.TextColor3 = Color3.fromRGB(140, 140, 150)
    desc.TextSize = 9
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = container
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 80, 0, 32)
    input.Position = UDim2.new(1, -95, 0.5, -16)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    input.PlaceholderText = tostring(defaultValue)
    input.Text = tostring(Config[configKey])
    input.TextColor3 = Color3.fromRGB(255, 100, 100)
    input.TextSize = 12
    input.Font = Enum.Font.GothamBold
    input.ClearTextOnFocus = false
    input.Parent = container
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = input
    
    input.FocusLost:Connect(function()
        local value = tonumber(input.Text)
        if value and value >= 0 then
            Config[configKey] = value
            input.TextColor3 = Color3.fromRGB(50, 255, 100)
            print("✅ " .. name .. ": " .. value)
            task.wait(0.3)
            input.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            input.Text = tostring(Config[configKey])
            input.TextColor3 = Color3.fromRGB(255, 50, 50)
            warn("❌ Invalid " .. name)
            task.wait(0.5)
            input.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

-- Create fishing settings
CreateFishingSetting("⏱️ Charge Time", "ChargeTime", 0.3, "Waktu charge rod (detik)", 1)
CreateFishingSetting("⏱️ Reel Delay", "ReelDelay", 0.1, "Delay setelah cast (detik)", 2)
CreateFishingSetting("⏱️ Fishing Delay", "FishingDelay", 0.2, "Delay antar siklus (detik)", 3)
CreateFishingSetting("🎯 Cast Amount", "CastAmount", 3, "Jumlah multi-cast (1-5)", 4)
CreateFishingSetting("💪 Cast Power", "CastPower", 0.55, "Kekuatan lempar (0-1)", 5)

-- Update canvas size
task.wait()
FishingScrollFrame.CanvasSize = UDim2.new(0, 0, 0, FishingLayout.AbsoluteContentSize.Y)

-- CHEAT FRAME CONTENT

-- Cheat Toggles Container
local CheatToggleContainer1 = Instance.new("Frame")
CheatToggleContainer1.Size = UDim2.new(0, 360, 0, 45)
CheatToggleContainer1.Position = UDim2.new(0, 0, 0, 0)
CheatToggleContainer1.BackgroundTransparency = 1
CheatToggleContainer1.Parent = CheatFrame

local CheatToggleContainer2 = Instance.new("Frame")
CheatToggleContainer2.Size = UDim2.new(0, 360, 0, 45)
CheatToggleContainer2.Position = UDim2.new(0, 0, 0, 55)
CheatToggleContainer2.BackgroundTransparency = 1
CheatToggleContainer2.Parent = CheatFrame

-- Fly Toggle
local FlyBtn = Instance.new("TextButton")
FlyBtn.Size = UDim2.new(0, 175, 0, 45)
FlyBtn.Position = UDim2.new(0, 0, 0, 0)
FlyBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
FlyBtn.Text = "🕊️ Fly: OFF"
FlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyBtn.TextSize = 14
FlyBtn.Font = Enum.Font.GothamBold
FlyBtn.Parent = CheatToggleContainer1

local FlyCorner = Instance.new("UICorner")
FlyCorner.CornerRadius = UDim.new(0, 8)
FlyCorner.Parent = FlyBtn

FlyBtn.MouseButton1Click:Connect(function()
    Config.FlyEnabled = not Config.FlyEnabled
    if Config.FlyEnabled then
        FlyBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        FlyBtn.Text = "🕊️ Fly: ON"
        FlyController:Enable()
    else
        FlyBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        FlyBtn.Text = "🕊️ Fly: OFF"
        FlyController:Disable()
    end
end)

-- Speed Toggle
local SpeedBtn = Instance.new("TextButton")
SpeedBtn.Size = UDim2.new(0, 175, 0, 45)
SpeedBtn.Position = UDim2.new(1, -175, 0, 0)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
SpeedBtn.Text = "💨 Speed: OFF"
SpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBtn.TextSize = 14
SpeedBtn.Font = Enum.Font.GothamBold
SpeedBtn.Parent = CheatToggleContainer1

local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 8)
SpeedCorner.Parent = SpeedBtn

SpeedBtn.MouseButton1Click:Connect(function()
    Config.SpeedEnabled = not Config.SpeedEnabled
    if Config.SpeedEnabled then
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        SpeedBtn.Text = "💨 Speed: ON"
        updateSpeed()
    else
        SpeedBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        SpeedBtn.Text = "💨 Speed: OFF"
        updateSpeed()
    end
end)

-- Noclip Toggle
local NoclipBtn = Instance.new("TextButton")
NoclipBtn.Size = UDim2.new(0, 175, 0, 45)
NoclipBtn.Position = UDim2.new(0, 0, 0, 0)
NoclipBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
NoclipBtn.Text = "👻 Noclip: OFF"
NoclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoclipBtn.TextSize = 14
NoclipBtn.Font = Enum.Font.GothamBold
NoclipBtn.Parent = CheatToggleContainer2

local NoclipCorner = Instance.new("UICorner")
NoclipCorner.CornerRadius = UDim.new(0, 8)
NoclipCorner.Parent = NoclipBtn

NoclipBtn.MouseButton1Click:Connect(function()
    Config.NoclipEnabled = not Config.NoclipEnabled
    if Config.NoclipEnabled then
        NoclipBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
        NoclipBtn.Text = "👻 Noclip: ON"
        NoclipController:Enable()
    else
        NoclipBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        NoclipBtn.Text = "👻 Noclip: OFF"
        NoclipController:Disable()
    end
end)

-- Cheat Settings Label
local CheatSettingsLabel = Instance.new("TextLabel")
CheatSettingsLabel.Size = UDim2.new(1, -40, 0, 25)
CheatSettingsLabel.Position = UDim2.new(0, 20, 0, 110)
CheatSettingsLabel.BackgroundTransparency = 1
CheatSettingsLabel.Text = "⚡ CHEAT SETTINGS"
CheatSettingsLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
CheatSettingsLabel.TextSize = 13
CheatSettingsLabel.Font = Enum.Font.GothamBold
CheatSettingsLabel.TextXAlignment = Enum.TextXAlignment.Left
CheatSettingsLabel.Parent = CheatFrame

-- Cheat Settings Container
local CheatScrollFrame = Instance.new("ScrollingFrame")
CheatScrollFrame.Size = UDim2.new(0, 360, 0, 100)
CheatScrollFrame.Position = UDim2.new(0, 0, 0, 140)
CheatScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
CheatScrollFrame.ScrollBarThickness = 6
CheatScrollFrame.Parent = CheatFrame

local CheatScrollCorner = Instance.new("UICorner")
CheatScrollCorner.CornerRadius = UDim.new(0, 8)
CheatScrollCorner.Parent = CheatScrollFrame

local CheatLayout = Instance.new("UIListLayout")
CheatLayout.Padding = UDim.new(0, 8)
CheatLayout.Parent = CheatScrollFrame

-- Function untuk bikin cheat setting
local function CreateCheatSetting(name, configKey, defaultValue, description, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    container.LayoutOrder = layoutOrder
    container.Parent = CheatScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 12
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(0, 180, 0, 16)
    desc.Position = UDim2.new(0, 10, 0, 28)
    desc.BackgroundTransparency = 1
    desc.Text = description
    desc.TextColor3 = Color3.fromRGB(140, 140, 150)
    desc.TextSize = 9
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = container
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 80, 0, 32)
    input.Position = UDim2.new(1, -95, 0.5, -16)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    input.PlaceholderText = tostring(defaultValue)
    input.Text = tostring(Config[configKey])
    input.TextColor3 = Color3.fromRGB(255, 100, 100)
    input.TextSize = 12
    input.Font = Enum.Font.GothamBold
    input.ClearTextOnFocus = false
    input.Parent = container
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = input
    
    input.FocusLost:Connect(function()
        local value = tonumber(input.Text)
        if value and value >= 0 then
            Config[configKey] = value
            input.TextColor3 = Color3.fromRGB(50, 255, 100)
            print("✅ " .. name .. ": " .. value)
            
            -- Update speed langsung jika speed enabled
            if configKey == "WalkSpeed" and Config.SpeedEnabled then
                updateSpeed()
            end
            
            task.wait(0.3)
            input.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            input.Text = tostring(Config[configKey])
            input.TextColor3 = Color3.fromRGB(255, 50, 50)
            warn("❌ Invalid " .. name)
            task.wait(0.5)
            input.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

-- Create cheat settings
CreateCheatSetting("🕊️ Fly Speed", "FlySpeed", 50, "Kecepatan terbang (1-100)", 1)
CreateCheatSetting("💨 Walk Speed", "WalkSpeed", 50, "Kecepatan jalan (1-100)", 2)

-- Update canvas size
task.wait()
CheatScrollFrame.CanvasSize = UDim2.new(0, 0, 0, CheatLayout.AbsoluteContentSize.Y)

-- Cheat Instructions
local CheatInstructions = Instance.new("TextLabel")
CheatInstructions.Size = UDim2.new(1, -20, 0, 80)
CheatInstructions.Position = UDim2.new(0, 10, 0, 250)
CheatInstructions.BackgroundTransparency = 1
CheatInstructions.Text = "💡 Instructions:\n• Fly: WASD + Space/Shift\n• Speed: Atur di Walk Speed\n• Noclip: Bisa tembus tembok"
CheatInstructions.TextColor3 = Color3.fromRGB(180, 180, 190)
CheatInstructions.TextSize = 11
CheatInstructions.Font = Enum.Font.Gotham
CheatInstructions.TextXAlignment = Enum.TextXAlignment.Left
CheatInstructions.TextYAlignment = Enum.TextYAlignment.Top
CheatInstructions.Parent = CheatFrame

-- Tab Switching Logic
FishingTabBtn.MouseButton1Click:Connect(function()
    FishingFrame.Visible = true
    CheatFrame.Visible = false
    FishingTabBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
    CheatTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
end)

CheatTabBtn.MouseButton1Click:Connect(function()
    FishingFrame.Visible = false
    CheatFrame.Visible = true
    FishingTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    CheatTabBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
end)

-- Stats Display
local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(0, 360, 0, 50)
StatsFrame.Position = UDim2.new(0.5, -180, 0, 470)
StatsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
StatsFrame.BorderSizePixel = 0
StatsFrame.Parent = MainFrame

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 8)
StatsCorner.Parent = StatsFrame

local StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, -20, 1, -10)
StatsText.Position = UDim2.new(0, 10, 0, 5)
StatsText.BackgroundTransparency = 1
StatsText.Text = "🐟 Fish: 0 | Sold: 0 | CPM: 0"
StatsText.TextColor3 = Color3.fromRGB(180, 180, 190)
StatsText.TextSize = 12
StatsText.Font = Enum.Font.Gotham
StatsText.TextXAlignment = Enum.TextXAlignment.Left
StatsText.Parent = StatsFrame

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    Config.BlatantMode = false
    FishingActive = false
    
    if Config.NoAnimation then
        AnimationController:Enable()
    end
    
    if Config.FlyEnabled then
        FlyController:Disable()
    end
    
    if Config.SpeedEnabled then
        updateSpeed() -- Reset ke default
    end
    
    if Config.NoclipEnabled then
        NoclipController:Disable()
    end
    
    ScreenGui:Destroy()
    print("🎣 Danu Script closed")
end)

-- Update Stats Loop
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(0.5)
        local runtime = os.clock() - Stats.StartTime
        local cpm = runtime > 0 and (Stats.FishCaught / runtime) * 60 or 0
        
        StatsText.Text = string.format("🐟 Fish: %d | Sold: %d | CPM: %.1f", 
            Stats.FishCaught,
            Stats.TotalSold,
            cpm)
    end
end)

-- Character death handler
task.spawn(function()
    local char = Player.Character or Player.CharacterAdded:Wait()
    char.Humanoid.Died:Connect(function()
        Config.BlatantMode = false
        FishingActive = false
        warn("💀 Character died - fishing stopped")
    end)
end)

-- Character added handler untuk speed
Player.CharacterAdded:Connect(function()
    task.wait(1)
    updateSpeed()
end)

-- Add to PlayerGui
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

print("\n" .. string.rep("=", 60))
print("🎣 DANU SCRIPT - FISHING BOT & CHEAT MENU")
print(string.rep("=", 60))
print("👤 Player: " .. Player.Name)
print("✨ Features:")
print("  🎣 Advanced Fishing Bot")
print("  🕊️ Fly Mode (WASD + Space/Shift)")
print("  💨 Speed Boost")
print("  👻 Noclip Mode")
print("  🚫 Animation Control")
print("  💸 Manual Fish Selling")
print("")
print("⚙️ Current Settings:")
print("  • Charge Time: " .. Config.ChargeTime .. "s")
print("  • Reel Delay: " .. Config.ReelDelay .. "s") 
print("  • Fishing Delay: " .. Config.FishingDelay .. "s")
print("  • Multi-Cast: " .. (Config.MultiCast and "ON" or "OFF"))
print("  • Animations: " .. (Config.NoAnimation and "OFF" or "ON"))
print("  • Fly: " .. (Config.FlyEnabled and "ON" or "OFF"))
print("  • Speed: " .. (Config.SpeedEnabled and "ON" or "OFF"))
print("  • Noclip: " .. (Config.NoclipEnabled and "ON" or "OFF"))
print("")
print("💡 Tips:")
print("  • Gunakan tab Fishing untuk bot settings")
print("  • Gunakan tab Cheat untuk movement hacks")
print("  • Jual ikan manual dengan tombol SELL ALL FISH")
print(string.rep("=", 60) .. "\n")
