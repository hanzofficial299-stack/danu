local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

local Config = {
    BlatantMode = false, NoAnimation = false, FlyEnabled = false, SpeedEnabled = false, NoclipEnabled = false,
    FlySpeed = 50, WalkSpeed = 50, ReelDelay = 1, FishingDelay = 0, ChargeTime = 0.3,
    MultiCast = false, CastAmount = 1, CastPower = 0.55, CastAngleMin = -0.8, CastAngleMax = 0.8
}

local Stats = { StartTime = 0, FishCaught = 0, Attempts = 0, Errors = 0, TotalSold = 0 }
local AnimationController = { OriginalAnimate = nil, IsDisabled = false, Connection = nil }
local FlyController = { BodyVelocity = nil, BodyGyro = nil, Connection = nil }
local NoclipController = { Connection = nil }
local GuiState = { IsMinimized = false, OriginalSize = UDim2.new(0, 400, 0, 500), MinimizedSize = UDim2.new(0, 200, 0, 45) }

function AnimationController:Disable()
    if self.IsDisabled then return end
    pcall(function()
        local char = Player.Character; if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
            self.Connection = humanoid.AnimationPlayed:Connect(function(animTrack) if Config.NoAnimation then animTrack:Stop() end end)
        end
        local animate = char:FindFirstChild("Animate")
        if animate then self.OriginalAnimate = animate:Clone(); animate.Enabled = false end
    end)
    self.IsDisabled = true
end

function AnimationController:Enable()
    if not self.IsDisabled then return end
    pcall(function()
        local char = Player.Character; if not char then return end
        if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
        local animate = char:FindFirstChild("Animate"); if animate then animate.Enabled = true end
    end)
    self.IsDisabled = false
end

function FlyController:Enable()
    if self.Connection then return end
    local function setupFly()
        local char = Player.Character; if not char then return end
        local humanoid, rootPart = char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        if self.BodyVelocity then self.BodyVelocity:Destroy() end; if self.BodyGyro then self.BodyGyro:Destroy() end
        self.BodyVelocity = Instance.new("BodyVelocity"); self.BodyVelocity.Velocity = Vector3.new(0,0,0)
        self.BodyVelocity.MaxForce = Vector3.new(4000,4000,4000); self.BodyVelocity.P = 1000; self.BodyVelocity.Parent = rootPart
        self.BodyGyro = Instance.new("BodyGyro"); self.BodyGyro.MaxTorque = Vector3.new(4000,4000,4000)
        self.BodyGyro.P = 1000; self.BodyGyro.D = 50; self.BodyGyro.Parent = rootPart
        self.Connection = RunService.Heartbeat:Connect(function()
            if not Config.FlyEnabled or not char or not rootPart then self:Disable(); return end
            local camera = workspace.CurrentCamera; if not camera then return end
            self.BodyGyro.CFrame = camera.CFrame
            local moveDirection, UIS = Vector3.new(0,0,0), game:GetService("UserInputService")
            if UIS:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection + Vector3.new(0,-1,0) end
            if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit * Config.FlySpeed end
            self.BodyVelocity.Velocity = moveDirection
        end)
    end
    setupFly(); Player.CharacterAdded:Connect(function() if Config.FlyEnabled then task.wait(1); setupFly() end end)
end

function FlyController:Disable()
    if self.BodyVelocity then self.BodyVelocity:Destroy(); self.BodyVelocity = nil end
    if self.BodyGyro then self.BodyGyro:Destroy(); self.BodyGyro = nil end
    if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
end

local function updateSpeed()
    local char = Player.Character; if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then humanoid.WalkSpeed = Config.SpeedEnabled and Config.WalkSpeed or 16 end
end

function NoclipController:Enable()
    if self.Connection then return end
    self.Connection = RunService.Stepped:Connect(function()
        if not Config.NoclipEnabled then self:Disable(); return end
        local char = Player.Character
        if char then for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end end
    end)
end

function NoclipController:Disable()
    if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
    local char = Player.Character
    if char then for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end end
end

local function SellAllFish()
    local success = pcall(function() return Net["RF/SellAllItems"]:InvokeServer() end)
    if success then Stats.TotalSold = Stats.TotalSold + 1 end; return success
end

Player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
local FishingActive = false

local function ExecuteSingleCast()
    local success = pcall(function()
        Net["RF/ChargeFishingRod"]:InvokeServer(); task.wait(Config.ChargeTime)
        local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
        Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock())
        task.wait(0.1 + Config.ReelDelay)
        Net["RE/FishingCompleted"]:FireServer(); task.wait(0.05); Net["RE/FishingCompleted"]:FireServer()
        Stats.FishCaught = Stats.FishCaught + 1; Stats.Attempts = Stats.Attempts + 1
    end)
    if not success then Stats.Errors = Stats.Errors + 1 end
end

local function ExecuteMultiCast()
    local success = pcall(function()
        local completed = 0
        for i = 1, Config.CastAmount do
            task.spawn(function()
                Net["RF/ChargeFishingRod"]:InvokeServer(); task.wait(Config.ChargeTime)
                local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
                Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock())
                task.wait(Config.ReelDelay)
                Net["RE/FishingCompleted"]:FireServer(); task.wait(0.03); Net["RE/FishingCompleted"]:FireServer()
                Stats.FishCaught = Stats.FishCaught + 1; Stats.Attempts = Stats.Attempts + 1; completed = completed + 1
            end)
            task.wait(0.05)
        end
        local maxWait, startWait = (Config.ChargeTime + Config.ReelDelay + 0.2) * Config.CastAmount, os.clock()
        while completed < Config.CastAmount and (os.clock() - startWait) < maxWait do task.wait(0.1) end
    end)
    if not success then Stats.Errors = Stats.Errors + 1 end
end

local function StartBlatantLoop()
    while Config.BlatantMode do
        if not FishingActive then
            FishingActive = true
            if Config.MultiCast then ExecuteMultiCast() else ExecuteSingleCast() end
            FishingActive = false; task.wait(Config.FishingDelay)
        end
        task.wait(0.05)
    end
end

-- GUI
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "DanuScript"; ScreenGui.ResetOnSpawn = false; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame"); MainFrame.Name = "MainFrame"; MainFrame.Size = GuiState.OriginalSize
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250); MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0; MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.ClipsDescendants = true; MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", MainFrame); stroke.Color = Color3.fromRGB(255, 80, 80); stroke.Thickness = 2; stroke.Transparency = 0.5

local TitleBar = Instance.new("Frame"); TitleBar.Size = UDim2.new(1, 0, 0, 45); TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
TitleBar.BorderSizePixel = 0; TitleBar.Parent = MainFrame; Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel"); Title.Size = UDim2.new(1, -100, 0, 25); Title.Position = UDim2.new(0, 12, 0, 5)
Title.BackgroundTransparency = 1; Title.Text = "TIKTOK @pemoedakinyis"; Title.TextColor3 = Color3.fromRGB(255, 100, 100)
Title.TextSize = 16; Title.Font = Enum.Font.GothamBold; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TitleBar

local Subtitle = Instance.new("TextLabel"); Subtitle.Size = UDim2.new(1, -100, 0, 14); Subtitle.Position = UDim2.new(0, 12, 0, 26)
Subtitle.BackgroundTransparency = 1; Subtitle.Text = "mampir ke tiktokku ya"; Subtitle.TextColor3 = Color3.fromRGB(140, 140, 150)
Subtitle.TextSize = 9; Subtitle.Font = Enum.Font.Gotham; Subtitle.TextXAlignment = Enum.TextXAlignment.Left; Subtitle.Parent = TitleBar

local BtnContainer = Instance.new("Frame"); BtnContainer.Size = UDim2.new(0, 75, 0, 30); BtnContainer.Position = UDim2.new(1, -85, 0, 8)
BtnContainer.BackgroundTransparency = 1; BtnContainer.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton"); MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 255); MinimizeBtn.Text = "-"; MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20; MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.Parent = BtnContainer
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(0, 38, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50); CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.Parent = BtnContainer
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local ContentFrame = Instance.new("Frame"); ContentFrame.Size = UDim2.new(1, 0, 1, -45); ContentFrame.Position = UDim2.new(0, 0, 0, 45)
ContentFrame.BackgroundTransparency = 1; ContentFrame.Parent = MainFrame

local TabContainer = Instance.new("Frame"); TabContainer.Size = UDim2.new(0, 360, 0, 35); TabContainer.Position = UDim2.new(0.5, -180, 0, 10)
TabContainer.BackgroundTransparency = 1; TabContainer.Parent = ContentFrame

local FishingTabBtn = Instance.new("TextButton"); FishingTabBtn.Size = UDim2.new(0, 175, 0, 32)
FishingTabBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); FishingTabBtn.Text = "FISHING"; FishingTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FishingTabBtn.TextSize = 13; FishingTabBtn.Font = Enum.Font.GothamBold; FishingTabBtn.Parent = TabContainer
Instance.new("UICorner", FishingTabBtn).CornerRadius = UDim.new(0, 6)

local CheatTabBtn = Instance.new("TextButton"); CheatTabBtn.Size = UDim2.new(0, 175, 0, 32); CheatTabBtn.Position = UDim2.new(1, -175, 0, 0)
CheatTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100); CheatTabBtn.Text = "CHEAT"; CheatTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CheatTabBtn.TextSize = 13; CheatTabBtn.Font = Enum.Font.GothamBold; CheatTabBtn.Parent = TabContainer
Instance.new("UICorner", CheatTabBtn).CornerRadius = UDim.new(0, 6)

local FishingFrame = Instance.new("Frame"); FishingFrame.Size = UDim2.new(0, 360, 0, 350); FishingFrame.Position = UDim2.new(0.5, -180, 0, 50)
FishingFrame.BackgroundTransparency = 1; FishingFrame.Visible = true; FishingFrame.Parent = ContentFrame

local BlatantBtn = Instance.new("TextButton"); BlatantBtn.Size = UDim2.new(1, 0, 0, 40)
BlatantBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50); BlatantBtn.Text = "START FISHING"; BlatantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BlatantBtn.TextSize = 15; BlatantBtn.Font = Enum.Font.GothamBold; BlatantBtn.Parent = FishingFrame
Instance.new("UICorner", BlatantBtn).CornerRadius = UDim.new(0, 8)

local ToggleContainer = Instance.new("Frame"); ToggleContainer.Size = UDim2.new(1, 0, 0, 40); ToggleContainer.Position = UDim2.new(0, 0, 0, 48)
ToggleContainer.BackgroundTransparency = 1; ToggleContainer.Parent = FishingFrame

local NoAnimBtn = Instance.new("TextButton"); NoAnimBtn.Size = UDim2.new(0.48, 0, 1, 0)
NoAnimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); NoAnimBtn.Text = "Anim: ON"; NoAnimBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
NoAnimBtn.TextSize = 12; NoAnimBtn.Font = Enum.Font.GothamSemibold; NoAnimBtn.Parent = ToggleContainer
Instance.new("UICorner", NoAnimBtn).CornerRadius = UDim.new(0, 6)

local MultiCastBtn = Instance.new("TextButton"); MultiCastBtn.Size = UDim2.new(0.48, 0, 1, 0); MultiCastBtn.Position = UDim2.new(0.52, 0, 0, 0)
MultiCastBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); MultiCastBtn.Text = "Single Cast"; MultiCastBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MultiCastBtn.TextSize = 12; MultiCastBtn.Font = Enum.Font.GothamSemibold; MultiCastBtn.Parent = ToggleContainer
Instance.new("UICorner", MultiCastBtn).CornerRadius = UDim.new(0, 6)

local SellFishBtn = Instance.new("TextButton"); SellFishBtn.Size = UDim2.new(1, 0, 0, 32); SellFishBtn.Position = UDim2.new(0, 0, 0, 95)
SellFishBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 255); SellFishBtn.Text = "SELL ALL FISH"; SellFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SellFishBtn.TextSize = 12; SellFishBtn.Font = Enum.Font.GothamBold; SellFishBtn.Parent = FishingFrame
Instance.new("UICorner", SellFishBtn).CornerRadius = UDim.new(0, 6)

local SettingsLabel = Instance.new("TextLabel"); SettingsLabel.Size = UDim2.new(1, 0, 0, 20); SettingsLabel.Position = UDim2.new(0, 0, 0, 135)
SettingsLabel.BackgroundTransparency = 1; SettingsLabel.Text = "SETTINGS"; SettingsLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
SettingsLabel.TextSize = 11; SettingsLabel.Font = Enum.Font.GothamBold; SettingsLabel.TextXAlignment = Enum.TextXAlignment.Left; SettingsLabel.Parent = FishingFrame

local FishingScrollFrame = Instance.new("ScrollingFrame"); FishingScrollFrame.Size = UDim2.new(1, 0, 0, 180); FishingScrollFrame.Position = UDim2.new(0, 0, 0, 158)
FishingScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32); FishingScrollFrame.ScrollBarThickness = 4
FishingScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 100); FishingScrollFrame.Parent = FishingFrame
Instance.new("UICorner", FishingScrollFrame).CornerRadius = UDim.new(0, 8)
local FishingLayout = Instance.new("UIListLayout", FishingScrollFrame); FishingLayout.Padding = UDim.new(0, 6)
local FishingPadding = Instance.new("UIPadding", FishingScrollFrame); FishingPadding.PaddingTop = UDim.new(0, 6); FishingPadding.PaddingLeft = UDim.new(0, 6); FishingPadding.PaddingRight = UDim.new(0, 6)

local function CreateSettingRow(parent, name, configKey, defaultValue, layoutOrder)
    local container = Instance.new("Frame"); container.Size = UDim2.new(1, -12, 0, 38)
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 45); container.LayoutOrder = layoutOrder; container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.6, 0, 1, 0); label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1; label.Text = name; label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextSize = 11; label.Font = Enum.Font.GothamSemibold; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container
    local input = Instance.new("TextBox"); input.Size = UDim2.new(0, 70, 0, 26); input.Position = UDim2.new(1, -80, 0.5, -13)
    input.BackgroundColor3 = Color3.fromRGB(45, 45, 55); input.Text = tostring(Config[configKey]); input.TextColor3 = Color3.fromRGB(255, 120, 120)
    input.TextSize = 11; input.Font = Enum.Font.GothamBold; input.ClearTextOnFocus = false; input.Parent = container
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
    input.FocusLost:Connect(function()
        local value = tonumber(input.Text)
        if value and value >= 0 then Config[configKey] = value; input.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(0.3); input.TextColor3 = Color3.fromRGB(255, 120, 120)
        else input.Text = tostring(Config[configKey]) end
    end)
end

CreateSettingRow(FishingScrollFrame, "Charge Time (s)", "ChargeTime", 0.3, 1)
CreateSettingRow(FishingScrollFrame, "Reel Delay (s)", "ReelDelay", 0.1, 2)
CreateSettingRow(FishingScrollFrame, "Fishing Delay (s)", "FishingDelay", 0.2, 3)
CreateSettingRow(FishingScrollFrame, "Cast Amount", "CastAmount", 3, 4)
CreateSettingRow(FishingScrollFrame, "Cast Power", "CastPower", 0.55, 5)
task.wait(); FishingScrollFrame.CanvasSize = UDim2.new(0, 0, 0, FishingLayout.AbsoluteContentSize.Y + 12)

local CheatFrame = Instance.new("Frame"); CheatFrame.Size = UDim2.new(0, 360, 0, 350); CheatFrame.Position = UDim2.new(0.5, -180, 0, 50)
CheatFrame.BackgroundTransparency = 1; CheatFrame.Visible = false; CheatFrame.Parent = ContentFrame

local CheatRow1 = Instance.new("Frame"); CheatRow1.Size = UDim2.new(1, 0, 0, 40); CheatRow1.BackgroundTransparency = 1; CheatRow1.Parent = CheatFrame
local FlyBtn = Instance.new("TextButton"); FlyBtn.Size = UDim2.new(0.48, 0, 1, 0)
FlyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); FlyBtn.Text = "Fly: OFF"; FlyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
FlyBtn.TextSize = 12; FlyBtn.Font = Enum.Font.GothamSemibold; FlyBtn.Parent = CheatRow1
Instance.new("UICorner", FlyBtn).CornerRadius = UDim.new(0, 6)

local SpeedBtn = Instance.new("TextButton"); SpeedBtn.Size = UDim2.new(0.48, 0, 1, 0); SpeedBtn.Position = UDim2.new(0.52, 0, 0, 0)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); SpeedBtn.Text = "Speed: OFF"; SpeedBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedBtn.TextSize = 12; SpeedBtn.Font = Enum.Font.GothamSemibold; SpeedBtn.Parent = CheatRow1
Instance.new("UICorner", SpeedBtn).CornerRadius = UDim.new(0, 6)

local CheatRow2 = Instance.new("Frame"); CheatRow2.Size = UDim2.new(1, 0, 0, 40); CheatRow2.Position = UDim2.new(0, 0, 0, 48)
CheatRow2.BackgroundTransparency = 1; CheatRow2.Parent = CheatFrame
local NoclipBtn = Instance.new("TextButton"); NoclipBtn.Size = UDim2.new(0.48, 0, 1, 0)
NoclipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); NoclipBtn.Text = "Noclip: OFF"; NoclipBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
NoclipBtn.TextSize = 12; NoclipBtn.Font = Enum.Font.GothamSemibold; NoclipBtn.Parent = CheatRow2
Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0, 6)

local CheatSettingsLabel = Instance.new("TextLabel"); CheatSettingsLabel.Size = UDim2.new(1, 0, 0, 20); CheatSettingsLabel.Position = UDim2.new(0, 0, 0, 100)
CheatSettingsLabel.BackgroundTransparency = 1; CheatSettingsLabel.Text = "SETTINGS"; CheatSettingsLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
CheatSettingsLabel.TextSize = 11; CheatSettingsLabel.Font = Enum.Font.GothamBold; CheatSettingsLabel.TextXAlignment = Enum.TextXAlignment.Left; CheatSettingsLabel.Parent = CheatFrame

local CheatScrollFrame = Instance.new("ScrollingFrame"); CheatScrollFrame.Size = UDim2.new(1, 0, 0, 100); CheatScrollFrame.Position = UDim2.new(0, 0, 0, 123)
CheatScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32); CheatScrollFrame.ScrollBarThickness = 4
CheatScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 100); CheatScrollFrame.Parent = CheatFrame
Instance.new("UICorner", CheatScrollFrame).CornerRadius = UDim.new(0, 8)
local CheatLayout = Instance.new("UIListLayout", CheatScrollFrame); CheatLayout.Padding = UDim.new(0, 6)
local CheatPadding = Instance.new("UIPadding", CheatScrollFrame); CheatPadding.PaddingTop = UDim.new(0, 6); CheatPadding.PaddingLeft = UDim.new(0, 6); CheatPadding.PaddingRight = UDim.new(0, 6)

CreateSettingRow(CheatScrollFrame, "Fly Speed", "FlySpeed", 50, 1)
CreateSettingRow(CheatScrollFrame, "Walk Speed", "WalkSpeed", 50, 2)
task.wait(); CheatScrollFrame.CanvasSize = UDim2.new(0, 0, 0, CheatLayout.AbsoluteContentSize.Y + 12)

local Instructions = Instance.new("TextLabel"); Instructions.Size = UDim2.new(1, 0, 0, 60); Instructions.Position = UDim2.new(0, 0, 0, 235)
Instructions.BackgroundTransparency = 1; Instructions.Text = "Controls:\nFly: WASD + Space/Shift\nSpeed: Adjust Walk Speed above"
Instructions.TextColor3 = Color3.fromRGB(150, 150, 160); Instructions.TextSize = 10; Instructions.Font = Enum.Font.Gotham
Instructions.TextXAlignment = Enum.TextXAlignment.Left; Instructions.TextYAlignment = Enum.TextYAlignment.Top; Instructions.Parent = CheatFrame

local StatsFrame = Instance.new("Frame"); StatsFrame.Size = UDim2.new(0, 360, 0, 35); StatsFrame.Position = UDim2.new(0.5, -180, 1, -45)
StatsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); StatsFrame.Parent = ContentFrame
Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 6)
local StatsText = Instance.new("TextLabel"); StatsText.Size = UDim2.new(1, -16, 1, 0); StatsText.Position = UDim2.new(0, 8, 0, 0)
StatsText.BackgroundTransparency = 1; StatsText.Text = "Fish: 0 | Sold: 0 | CPM: 0"; StatsText.TextColor3 = Color3.fromRGB(180, 180, 190)
StatsText.TextSize = 11; StatsText.Font = Enum.Font.Gotham; StatsText.TextXAlignment = Enum.TextXAlignment.Left; StatsText.Parent = StatsFrame

-- CONNECTIONS
local function ToggleMinimize()
    GuiState.IsMinimized = not GuiState.IsMinimized
    local targetSize = GuiState.IsMinimized and GuiState.MinimizedSize or GuiState.OriginalSize
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize})
    tween:Play(); ContentFrame.Visible = not GuiState.IsMinimized; MinimizeBtn.Text = GuiState.IsMinimized and "+" or "-"
    Subtitle.Text = GuiState.IsMinimized and "Click + to expand" or "mampir ke tiktokku ya"
end

MinimizeBtn.MouseButton1Click:Connect(ToggleMinimize)

CloseBtn.MouseButton1Click:Connect(function()
    Config.BlatantMode = false; FishingActive = false
    if Config.NoAnimation then AnimationController:Enable() end
    if Config.FlyEnabled then FlyController:Disable() end
    if Config.SpeedEnabled then updateSpeed() end
    if Config.NoclipEnabled then NoclipController:Disable() end
    ScreenGui:Destroy()
end)

FishingTabBtn.MouseButton1Click:Connect(function()
    FishingFrame.Visible = true; CheatFrame.Visible = false
    FishingTabBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); FishingTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CheatTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100); CheatTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

CheatTabBtn.MouseButton1Click:Connect(function()
    FishingFrame.Visible = false; CheatFrame.Visible = true
    FishingTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100); FishingTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    CheatTabBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); CheatTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

BlatantBtn.MouseButton1Click:Connect(function()
    Config.BlatantMode = not Config.BlatantMode
    if Config.BlatantMode then
        BlatantBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); BlatantBtn.Text = "STOP FISHING"
        Stats.StartTime = os.clock(); Stats.FishCaught = 0; Stats.Attempts = 0; Stats.Errors = 0
        task.spawn(StartBlatantLoop)
    else
        BlatantBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50); BlatantBtn.Text = "START FISHING"; FishingActive = false
    end
end)

NoAnimBtn.MouseButton1Click:Connect(function()
    Config.NoAnimation = not Config.NoAnimation
    if Config.NoAnimation then NoAnimBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); NoAnimBtn.Text = "Anim: OFF"; AnimationController:Disable()
    else NoAnimBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); NoAnimBtn.Text = "Anim: ON"; AnimationController:Enable() end
end)

MultiCastBtn.MouseButton1Click:Connect(function()
    Config.MultiCast = not Config.MultiCast
    if Config.MultiCast then MultiCastBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); MultiCastBtn.Text = "Multi Cast"
    else MultiCastBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); MultiCastBtn.Text = "Single Cast" end
end)

SellFishBtn.MouseButton1Click:Connect(SellAllFish)

FlyBtn.MouseButton1Click:Connect(function()
    Config.FlyEnabled = not Config.FlyEnabled
    if Config.FlyEnabled then FlyBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); FlyBtn.Text = "Fly: ON"; FlyController:Enable()
    else FlyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); FlyBtn.Text = "Fly: OFF"; FlyController:Disable() end
end)

SpeedBtn.MouseButton1Click:Connect(function()
    Config.SpeedEnabled = not Config.SpeedEnabled
    if Config.SpeedEnabled then SpeedBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); SpeedBtn.Text = "Speed: ON"
    else SpeedBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); SpeedBtn.Text = "Speed: OFF" end
    updateSpeed()
end)

NoclipBtn.MouseButton1Click:Connect(function()
    Config.NoclipEnabled = not Config.NoclipEnabled
    if Config.NoclipEnabled then NoclipBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100); NoclipBtn.Text = "Noclip: ON"; NoclipController:Enable()
    else NoclipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75); NoclipBtn.Text = "Noclip: OFF"; NoclipController:Disable() end
end)

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(0.5); local runtime = os.clock() - Stats.StartTime
        local cpm = runtime > 0 and (Stats.FishCaught / runtime) * 60 or 0
        StatsText.Text = string.format("Fish: %d | Sold: %d | CPM: %.1f", Stats.FishCaught, Stats.TotalSold, cpm)
    end
end)

task.spawn(function()
    local char = Player.Character or Player.CharacterAdded:Wait()
    char.Humanoid.Died:Connect(function() Config.BlatantMode = false; FishingActive = false end)
end)

Player.CharacterAdded:Connect(function() task.wait(1); updateSpeed() end)

ScreenGui.Parent = Player:WaitForChild("PlayerGui")
print("Danu Script Loaded - Click - to minimize, + to expand")
