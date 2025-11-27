local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

local Config = {
    BlatantMode = false, NoAnimation = false, FlyEnabled = false, SpeedEnabled = false, NoclipEnabled = false,
    FlySpeed = 50, WalkSpeed = 50, ReelDelay = 0.1, FishingDelay = 0.2, ChargeTime = 0.3,
    MultiCast = false, CastAmount = 3, CastPower = 0.55, CastAngleMin = -0.8, CastAngleMax = 0.8,
    InstantFish = false, AutoSell = false, AutoSellThreshold = 50,
    AutoBuyEventEnabled = false, SelectedEvent = "Wind", AutoBuyCheckInterval = 5,
    AntiAFKEnabled = true, AutoRejoinEnabled = false, AutoRejoinDelay = 5, AntiLagEnabled = false
}

local EventList = { "Wind", "Cloudy", "Snow", "Storm", "Radiant", "Shark Hunt" }
local Stats = { StartTime = 0, FishCaught = 0, TotalSold = 0 }
local FishingActive = false

local AnimationController = { IsDisabled = false, Connection = nil }
local FlyController = { BodyVelocity = nil, BodyGyro = nil, Connection = nil }
local NoclipController = { Connection = nil }
local AutoBuyEventController = { Connection = nil, LastBuyTime = 0 }
local AntiAFKController = { Connection = nil, IdleConnection = nil }
local AutoRejoinController = { Connection = nil }
local AntiLagController = { Enabled = false, OriginalSettings = {} }

function AntiLagController:Enable()
    if self.Enabled then return end
    self.OriginalSettings = { GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd }
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = 1
        if Terrain then Terrain.Decoration = false end
        for _, v in pairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false
                elseif v:IsA("MeshPart") or v:IsA("Part") then v.Material = Enum.Material.Plastic v.CastShadow = false end
            end)
        end
    end)
    self.Enabled = true
end

function AntiLagController:Disable()
    if not self.Enabled then return end
    pcall(function()
        Lighting.GlobalShadows = self.OriginalSettings.GlobalShadows
        Lighting.FogEnd = self.OriginalSettings.FogEnd
        settings().Rendering.QualityLevel = 10
    end)
    self.Enabled = false
end

function AnimationController:Disable()
    if self.IsDisabled then return end
    pcall(function()
        local char = Player.Character if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if hum then for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
            self.Connection = hum.AnimationPlayed:Connect(function(t) if Config.NoAnimation then t:Stop() end end) end
        local anim = char:FindFirstChild("Animate") if anim then anim.Enabled = false end
    end)
    self.IsDisabled = true
end

function AnimationController:Enable()
    if not self.IsDisabled then return end
    pcall(function()
        local char = Player.Character if not char then return end
        if self.Connection then self.Connection:Disconnect() self.Connection = nil end
        local anim = char:FindFirstChild("Animate") if anim then anim.Enabled = true end
    end)
    self.IsDisabled = false
end

function FlyController:Enable()
    if self.Connection then return end
    local function setup()
        local char = Player.Character if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") if not root then return end
        if self.BodyVelocity then self.BodyVelocity:Destroy() end
        if self.BodyGyro then self.BodyGyro:Destroy() end
        self.BodyVelocity = Instance.new("BodyVelocity") self.BodyVelocity.Velocity = Vector3.zero self.BodyVelocity.MaxForce = Vector3.new(4e4,4e4,4e4) self.BodyVelocity.P = 1000 self.BodyVelocity.Parent = root
        self.BodyGyro = Instance.new("BodyGyro") self.BodyGyro.MaxTorque = Vector3.new(4e4,4e4,4e4) self.BodyGyro.P = 1000 self.BodyGyro.D = 50 self.BodyGyro.Parent = root
        self.Connection = RunService.Heartbeat:Connect(function()
            if not Config.FlyEnabled or not root then self:Disable() return end
            local cam = workspace.CurrentCamera if not cam then return end
            self.BodyGyro.CFrame = cam.CFrame
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            self.BodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
        end)
    end
    setup()
    Player.CharacterAdded:Connect(function() if Config.FlyEnabled then task.wait(1) setup() end end)
end

function FlyController:Disable()
    if self.BodyVelocity then self.BodyVelocity:Destroy() self.BodyVelocity = nil end
    if self.BodyGyro then self.BodyGyro:Destroy() self.BodyGyro = nil end
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
end

local function updateSpeed()
    local char = Player.Character if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = Config.SpeedEnabled and Config.WalkSpeed or 16 end
end

function NoclipController:Enable()
    if self.Connection then return end
    self.Connection = RunService.Stepped:Connect(function()
        if not Config.NoclipEnabled then self:Disable() return end
        local char = Player.Character if char then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end)
end

function NoclipController:Disable()
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
    local char = Player.Character if char then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
end

local function SellAllFish() local s = pcall(function() Net["RF/SellAllItems"]:InvokeServer() end) if s then Stats.TotalSold = Stats.TotalSold + 1 end return s end

function AutoBuyEventController:PurchaseEvent(e)
    local s, r = pcall(function() return Net["RF/PurchaseWeatherEvent"]:InvokeServer(e) end)
    return s, r
end

function AutoBuyEventController:Enable()
    if self.Connection then return end
    self.Connection = task.spawn(function()
        while Config.AutoBuyEventEnabled do
            if os.clock() - self.LastBuyTime >= Config.AutoBuyCheckInterval then self:PurchaseEvent(Config.SelectedEvent) self.LastBuyTime = os.clock() end
            task.wait(1)
        end
    end)
end

function AutoBuyEventController:Disable() if self.Connection then task.cancel(self.Connection) self.Connection = nil end end

function AntiAFKController:Enable()
    if self.IdleConnection then return end
    self.IdleConnection = Player.Idled:Connect(function() if Config.AntiAFKEnabled then VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.zero) end end)
    self.Connection = task.spawn(function() while Config.AntiAFKEnabled do pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.zero) end) task.wait(60) end end)
end

function AntiAFKController:Disable()
    if self.IdleConnection then self.IdleConnection:Disconnect() self.IdleConnection = nil end
    if self.Connection then task.cancel(self.Connection) self.Connection = nil end
end

function AutoRejoinController:Enable()
    if self.Connection then return end
    pcall(function() self.Connection = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function() if Config.AutoRejoinEnabled then task.wait(Config.AutoRejoinDelay) TeleportService:Teleport(game.PlaceId, Player) end end) end)
end

function AutoRejoinController:Disable() if self.Connection then self.Connection:Disconnect() self.Connection = nil end end

if Config.AntiAFKEnabled then AntiAFKController:Enable() end

local function ExecuteFishing()
    pcall(function()
        if Config.MultiCast then
            for i = 1, Config.CastAmount do
                task.spawn(function()
                    pcall(function() Net["RF/ChargeFishingRod"]:InvokeServer() end)
                    if Config.ChargeTime > 0 then task.wait(Config.ChargeTime) end
                    local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
                    pcall(function() Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) end)
                    if Config.ReelDelay > 0 then task.wait(Config.ReelDelay) end
                    pcall(function() Net["RE/ShakeFish"]:FireServer() Net["RE/ShakeFish"]:FireServer() end)
                    pcall(function() Net["RE/FishingCompleted"]:FireServer() Net["RE/FishingCompleted"]:FireServer() end)
                    Stats.FishCaught = Stats.FishCaught + 1
                end)
            end
            task.wait(Config.ChargeTime + Config.ReelDelay + 0.05)
        elseif Config.InstantFish then
            pcall(function() Net["RF/ChargeFishingRod"]:InvokeServer() end)
            local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
            pcall(function() Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) end)
            for i = 1, 3 do pcall(function() Net["RE/FishingCompleted"]:FireServer() Net["RE/ShakeFish"]:FireServer() end) end
            Stats.FishCaught = Stats.FishCaught + 1
        else
            pcall(function() Net["RF/ChargeFishingRod"]:InvokeServer() end)
            if Config.ChargeTime > 0 then task.wait(Config.ChargeTime) end
            local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
            pcall(function() Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) end)
            if Config.ReelDelay > 0 then task.wait(Config.ReelDelay) end
            pcall(function() Net["RE/ShakeFish"]:FireServer() Net["RE/ShakeFish"]:FireServer() end)
            pcall(function() Net["RE/FishingCompleted"]:FireServer() Net["RE/FishingCompleted"]:FireServer() end)
            Stats.FishCaught = Stats.FishCaught + 1
        end
    end)
end

local function StartBlatantLoop()
    while Config.BlatantMode do
        if not FishingActive then
            FishingActive = true
            ExecuteFishing()
            if Config.AutoSell and Stats.FishCaught > 0 and Stats.FishCaught % Config.AutoSellThreshold == 0 then SellAllFish() end
            FishingActive = false
            task.wait(Config.FishingDelay)
        end
        task.wait(0.01)
    end
end
local ScreenGui = Instance.new("ScreenGui") ScreenGui.Name = "DanuScript" ScreenGui.ResetOnSpawn = false ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local MIN_W, MIN_H, MAX_W, MAX_H, DEF_W, DEF_H = 300, 450, 550, 750, 380, 620

local MainFrame = Instance.new("Frame") MainFrame.Size = UDim2.new(0, DEF_W, 0, DEF_H) MainFrame.Position = UDim2.new(0.5, -DEF_W/2, 0.5, -DEF_H/2) MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24) MainFrame.BorderSizePixel = 0 MainFrame.Active = true MainFrame.Draggable = true MainFrame.ClipsDescendants = true MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", MainFrame) stroke.Color = Color3.fromRGB(255, 80, 80) stroke.Thickness = 2 stroke.Transparency = 0.5

local ResizeHandle = Instance.new("TextButton", MainFrame) ResizeHandle.Size = UDim2.new(0, 20, 0, 20) ResizeHandle.Position = UDim2.new(1, -20, 1, -20) ResizeHandle.BackgroundColor3 = Color3.fromRGB(255, 80, 80) ResizeHandle.Text = "+" ResizeHandle.TextColor3 = Color3.fromRGB(255,255,255) ResizeHandle.TextSize = 14 ResizeHandle.Font = Enum.Font.GothamBold ResizeHandle.ZIndex = 10 Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 6)

local isResizing, resizeStartPos, resizeStartSize = false, nil, nil
ResizeHandle.MouseButton1Down:Connect(function() isResizing = true resizeStartPos = UserInputService:GetMouseLocation() resizeStartSize = MainFrame.Size end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isResizing = false end end)
UserInputService.InputChanged:Connect(function(i) if isResizing and i.UserInputType == Enum.UserInputType.MouseMovement then local d = UserInputService:GetMouseLocation() - resizeStartPos MainFrame.Size = UDim2.new(0, math.clamp(resizeStartSize.X.Offset + d.X, MIN_W, MAX_W), 0, math.clamp(resizeStartSize.Y.Offset + d.Y, MIN_H, MAX_H)) end end)

local Title = Instance.new("TextLabel", MainFrame) Title.Size = UDim2.new(1, 0, 0, 40) Title.BackgroundTransparency = 1 Title.Text = "DANU SCRIPT" Title.TextColor3 = Color3.fromRGB(255, 100, 100) Title.TextSize = 20 Title.Font = Enum.Font.GothamBold
local Subtitle = Instance.new("TextLabel", MainFrame) Subtitle.Size = UDim2.new(1, -120, 0, 18) Subtitle.Position = UDim2.new(0, 10, 0, 38) Subtitle.BackgroundTransparency = 1 Subtitle.Text = "[Fish It Auto Farm]" Subtitle.TextColor3 = Color3.fromRGB(140, 140, 150) Subtitle.TextSize = 10 Subtitle.Font = Enum.Font.Gotham Subtitle.TextXAlignment = Enum.TextXAlignment.Left

local TabContainer = Instance.new("Frame", MainFrame) TabContainer.Size = UDim2.new(1, -40, 0, 35) TabContainer.Position = UDim2.new(0, 20, 0, 60) TabContainer.BackgroundTransparency = 1

local function MakeTab(txt, pos, active)
    local b = Instance.new("TextButton", TabContainer) b.Size = UDim2.new(0.24, 0, 0, 32) b.Position = pos b.BackgroundColor3 = active and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(60, 60, 80) b.Text = txt b.TextColor3 = Color3.fromRGB(255,255,255) b.TextSize = 10 b.Font = Enum.Font.GothamBold Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6) return b
end

local FishingTabBtn = MakeTab("FISHING", UDim2.new(0, 0, 0, 0), true)
local CheatTabBtn = MakeTab("CHEAT", UDim2.new(0.25, 0, 0, 0), false)
local EventTabBtn = MakeTab("EVENT", UDim2.new(0.50, 0, 0, 0), false)
local HelpTabBtn = MakeTab("HELP", UDim2.new(0.75, 0, 0, 0), false)

local function MakeFrame() local f = Instance.new("ScrollingFrame", MainFrame) f.Size = UDim2.new(1, -40, 0, 450) f.Position = UDim2.new(0, 20, 0, 100) f.BackgroundColor3 = Color3.fromRGB(22, 22, 28) f.ScrollBarThickness = 6 f.Visible = false f.CanvasSize = UDim2.new(0, 0, 0, 800) Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8) local l = Instance.new("UIListLayout", f) l.Padding = UDim.new(0, 6) l.HorizontalAlignment = Enum.HorizontalAlignment.Center return f end

local FishingFrame = MakeFrame() FishingFrame.Visible = true
local CheatFrame = MakeFrame()
local EventFrame = MakeFrame()
local HelpFrame = MakeFrame()

local function MakeButton(parent, txt, order, color)
    local b = Instance.new("TextButton", parent) b.Size = UDim2.new(1, -16, 0, 38) b.BackgroundColor3 = color or Color3.fromRGB(220, 50, 50) b.Text = txt b.TextColor3 = Color3.fromRGB(255,255,255) b.TextSize = 12 b.Font = Enum.Font.GothamBold b.LayoutOrder = order Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8) return b
end

local function MakeLabel(parent, txt, order)
    local l = Instance.new("TextLabel", parent) l.Size = UDim2.new(1, -16, 0, 22) l.BackgroundTransparency = 1 l.Text = txt l.TextColor3 = Color3.fromRGB(200, 200, 210) l.TextSize = 11 l.Font = Enum.Font.GothamBold l.TextXAlignment = Enum.TextXAlignment.Left l.LayoutOrder = order return l
end

local function MakeSetting(parent, name, configKey, order)
    local c = Instance.new("Frame", parent) c.Size = UDim2.new(1, -16, 0, 36) c.BackgroundColor3 = Color3.fromRGB(35, 35, 42) c.LayoutOrder = order Instance.new("UICorner", c).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel", c) l.Size = UDim2.new(0.65, 0, 1, 0) l.Position = UDim2.new(0, 10, 0, 0) l.BackgroundTransparency = 1 l.Text = name l.TextColor3 = Color3.fromRGB(200, 200, 210) l.TextSize = 10 l.Font = Enum.Font.GothamSemibold l.TextXAlignment = Enum.TextXAlignment.Left
    local inp = Instance.new("TextBox", c) inp.Size = UDim2.new(0, 60, 0, 26) inp.Position = UDim2.new(1, -70, 0.5, -13) inp.BackgroundColor3 = Color3.fromRGB(45, 45, 55) inp.Text = tostring(Config[configKey]) inp.TextColor3 = Color3.fromRGB(255, 120, 120) inp.TextSize = 11 inp.Font = Enum.Font.GothamBold inp.ClearTextOnFocus = false Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 6)
    inp.FocusLost:Connect(function() local v = tonumber(inp.Text) if v and v >= 0 then Config[configKey] = v else inp.Text = tostring(Config[configKey]) end end)
end

local BlatantBtn = MakeButton(FishingFrame, "[START FISHING]", 1, Color3.fromRGB(220, 50, 50))
BlatantBtn.MouseButton1Click:Connect(function()
    Config.BlatantMode = not Config.BlatantMode
    if Config.BlatantMode then BlatantBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 100) BlatantBtn.Text = "[STOP FISHING]" Stats.StartTime = os.clock() Stats.FishCaught, Stats.TotalSold = 0, 0 task.spawn(StartBlatantLoop)
    else BlatantBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50) BlatantBtn.Text = "[START FISHING]" FishingActive = false end
end)

MakeLabel(FishingFrame, "-- FISHING MODE --", 2)

local InstantFishBtn = MakeButton(FishingFrame, "Instant Fish: OFF", 3, Color3.fromRGB(220, 50, 50))
InstantFishBtn.MouseButton1Click:Connect(function() Config.InstantFish = not Config.InstantFish InstantFishBtn.BackgroundColor3 = Config.InstantFish and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) InstantFishBtn.Text = Config.InstantFish and "Instant Fish: ON" or "Instant Fish: OFF" end)

local MultiCastBtn = MakeButton(FishingFrame, "Multi Cast: OFF", 4, Color3.fromRGB(220, 50, 50))
MultiCastBtn.MouseButton1Click:Connect(function() Config.MultiCast = not Config.MultiCast MultiCastBtn.BackgroundColor3 = Config.MultiCast and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) MultiCastBtn.Text = Config.MultiCast and "Multi Cast: ON (x"..Config.CastAmount..")" or "Multi Cast: OFF" end)

MakeLabel(FishingFrame, "-- OPTIONS --", 5)

local AutoSellBtn = MakeButton(FishingFrame, "Auto Sell: OFF", 6, Color3.fromRGB(220, 50, 50))
AutoSellBtn.MouseButton1Click:Connect(function() Config.AutoSell = not Config.AutoSell AutoSellBtn.BackgroundColor3 = Config.AutoSell and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) AutoSellBtn.Text = Config.AutoSell and "Auto Sell: ON" or "Auto Sell: OFF" end)

local NoAnimBtn = MakeButton(FishingFrame, "No Animation: OFF", 7, Color3.fromRGB(220, 50, 50))
NoAnimBtn.MouseButton1Click:Connect(function() Config.NoAnimation = not Config.NoAnimation NoAnimBtn.BackgroundColor3 = Config.NoAnimation and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) NoAnimBtn.Text = Config.NoAnimation and "No Animation: ON" or "No Animation: OFF" if Config.NoAnimation then AnimationController:Disable() else AnimationController:Enable() end end)

local SellFishBtn = MakeButton(FishingFrame, "[SELL ALL FISH NOW]", 8, Color3.fromRGB(80, 150, 255))
SellFishBtn.MouseButton1Click:Connect(SellAllFish)

MakeLabel(FishingFrame, "-- SETTINGS --", 9)
MakeSetting(FishingFrame, "Charge Time (detik)", "ChargeTime", 10)
MakeSetting(FishingFrame, "Reel Delay (detik)", "ReelDelay", 11)
MakeSetting(FishingFrame, "Fish Delay (detik)", "FishingDelay", 12)
MakeSetting(FishingFrame, "Cast Amount (multi)", "CastAmount", 13)
MakeSetting(FishingFrame, "Auto Sell Every (ikan)", "AutoSellThreshold", 14)
MakeSetting(FishingFrame, "Cast Power (0-1)", "CastPower", 15)
MakeLabel(CheatFrame, "-- MOVEMENT --", 1)

local FlyBtn = MakeButton(CheatFrame, "Fly: OFF", 2, Color3.fromRGB(220, 50, 50))
FlyBtn.MouseButton1Click:Connect(function() Config.FlyEnabled = not Config.FlyEnabled FlyBtn.BackgroundColor3 = Config.FlyEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) FlyBtn.Text = Config.FlyEnabled and "Fly: ON" or "Fly: OFF" if Config.FlyEnabled then FlyController:Enable() else FlyController:Disable() end end)

local SpeedBtn = MakeButton(CheatFrame, "Speed Hack: OFF", 3, Color3.fromRGB(220, 50, 50))
SpeedBtn.MouseButton1Click:Connect(function() Config.SpeedEnabled = not Config.SpeedEnabled SpeedBtn.BackgroundColor3 = Config.SpeedEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) SpeedBtn.Text = Config.SpeedEnabled and "Speed Hack: ON" or "Speed Hack: OFF" updateSpeed() end)

local NoclipBtn = MakeButton(CheatFrame, "Noclip: OFF", 4, Color3.fromRGB(220, 50, 50))
NoclipBtn.MouseButton1Click:Connect(function() Config.NoclipEnabled = not Config.NoclipEnabled NoclipBtn.BackgroundColor3 = Config.NoclipEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) NoclipBtn.Text = Config.NoclipEnabled and "Noclip: ON" or "Noclip: OFF" if Config.NoclipEnabled then NoclipController:Enable() else NoclipController:Disable() end end)

MakeLabel(CheatFrame, "-- PERFORMANCE --", 5)

local AntiLagBtn = MakeButton(CheatFrame, "Anti Lag: OFF", 6, Color3.fromRGB(220, 50, 50))
AntiLagBtn.MouseButton1Click:Connect(function() Config.AntiLagEnabled = not Config.AntiLagEnabled AntiLagBtn.BackgroundColor3 = Config.AntiLagEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) AntiLagBtn.Text = Config.AntiLagEnabled and "Anti Lag: ON" or "Anti Lag: OFF" if Config.AntiLagEnabled then AntiLagController:Enable() else AntiLagController:Disable() end end)

MakeLabel(CheatFrame, "-- SETTINGS --", 7)
MakeSetting(CheatFrame, "Fly Speed", "FlySpeed", 8)
MakeSetting(CheatFrame, "Walk Speed", "WalkSpeed", 9)

MakeLabel(EventFrame, "-- AUTO BUY EVENT --", 1)

local AutoBuyEventBtn = MakeButton(EventFrame, "Auto Buy Event: OFF", 2, Color3.fromRGB(220, 50, 50))
AutoBuyEventBtn.MouseButton1Click:Connect(function() Config.AutoBuyEventEnabled = not Config.AutoBuyEventEnabled AutoBuyEventBtn.BackgroundColor3 = Config.AutoBuyEventEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) AutoBuyEventBtn.Text = Config.AutoBuyEventEnabled and ("Auto Buy: " .. Config.SelectedEvent) or "Auto Buy Event: OFF" if Config.AutoBuyEventEnabled then AutoBuyEventController:Enable() else AutoBuyEventController:Disable() end end)

MakeLabel(EventFrame, "-- SELECT EVENT --", 3)

local eventButtons = {}
local ManualBuyBtn

for i, en in ipairs(EventList) do
    local eb = MakeButton(EventFrame, en, 3 + i, Config.SelectedEvent == en and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(60, 60, 80))
    eb.Size = UDim2.new(1, -16, 0, 32)
    eventButtons[en] = eb
    eb.MouseButton1Click:Connect(function()
        Config.SelectedEvent = en
        for n, b in pairs(eventButtons) do b.BackgroundColor3 = n == en and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(60, 60, 80) end
        if Config.AutoBuyEventEnabled then AutoBuyEventBtn.Text = "Auto Buy: " .. en end
        if ManualBuyBtn then ManualBuyBtn.Text = "[BUY " .. en .. " NOW]" end
    end)
end

ManualBuyBtn = MakeButton(EventFrame, "[BUY " .. Config.SelectedEvent .. " NOW]", 10, Color3.fromRGB(80, 150, 255))
ManualBuyBtn.MouseButton1Click:Connect(function() ManualBuyBtn.Text = "Buying..." local s = AutoBuyEventController:PurchaseEvent(Config.SelectedEvent) ManualBuyBtn.Text = s and "Success!" or "Failed!" task.wait(1) ManualBuyBtn.Text = "[BUY " .. Config.SelectedEvent .. " NOW]" end)

MakeLabel(EventFrame, "-- UTILITY --", 11)

local AntiAFKBtn = MakeButton(EventFrame, Config.AntiAFKEnabled and "Anti AFK: ON" or "Anti AFK: OFF", 12, Config.AntiAFKEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50))
AntiAFKBtn.MouseButton1Click:Connect(function() Config.AntiAFKEnabled = not Config.AntiAFKEnabled AntiAFKBtn.BackgroundColor3 = Config.AntiAFKEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) AntiAFKBtn.Text = Config.AntiAFKEnabled and "Anti AFK: ON" or "Anti AFK: OFF" if Config.AntiAFKEnabled then AntiAFKController:Enable() else AntiAFKController:Disable() end end)

local AutoRejoinBtn = MakeButton(EventFrame, "Auto Rejoin: OFF", 13, Color3.fromRGB(220, 50, 50))
AutoRejoinBtn.MouseButton1Click:Connect(function() Config.AutoRejoinEnabled = not Config.AutoRejoinEnabled AutoRejoinBtn.BackgroundColor3 = Config.AutoRejoinEnabled and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50) AutoRejoinBtn.Text = Config.AutoRejoinEnabled and "Auto Rejoin: ON" or "Auto Rejoin: OFF" if Config.AutoRejoinEnabled then AutoRejoinController:Enable() else AutoRejoinController:Disable() end end)

MakeSetting(EventFrame, "Auto Buy Interval (detik)", "AutoBuyCheckInterval", 14)
local function MakeHelpSection(parent, title, content, order)
    local c = Instance.new("Frame", parent) c.Size = UDim2.new(1, -16, 0, 0) c.BackgroundColor3 = Color3.fromRGB(30, 30, 40) c.LayoutOrder = order c.AutomaticSize = Enum.AutomaticSize.Y Instance.new("UICorner", c).CornerRadius = UDim.new(0, 8)
    local pad = Instance.new("UIPadding", c) pad.PaddingTop = UDim.new(0, 8) pad.PaddingBottom = UDim.new(0, 8) pad.PaddingLeft = UDim.new(0, 10) pad.PaddingRight = UDim.new(0, 10)
    local t = Instance.new("TextLabel", c) t.Size = UDim2.new(1, 0, 0, 18) t.BackgroundTransparency = 1 t.Text = title t.TextColor3 = Color3.fromRGB(255, 150, 150) t.TextSize = 12 t.Font = Enum.Font.GothamBold t.TextXAlignment = Enum.TextXAlignment.Left
    local d = Instance.new("TextLabel", c) d.Size = UDim2.new(1, 0, 0, 0) d.Position = UDim2.new(0, 0, 0, 22) d.BackgroundTransparency = 1 d.Text = content d.TextColor3 = Color3.fromRGB(180, 180, 190) d.TextSize = 10 d.Font = Enum.Font.Gotham d.TextXAlignment = Enum.TextXAlignment.Left d.TextYAlignment = Enum.TextYAlignment.Top d.TextWrapped = true d.AutomaticSize = Enum.AutomaticSize.Y
end

MakeHelpSection(HelpFrame, "[PANDUAN PEMULA]", "Selamat datang di Danu Script!\n\n1. Klik [START FISHING] untuk mulai\n2. Script akan otomatis cast, shake, dan reel\n3. Ikan akan tercatch otomatis\n4. Gunakan Auto Sell agar inventory tidak penuh", 1)

MakeHelpSection(HelpFrame, "[INSTANT FISH]", "Mode tercepat untuk farming!\n\nCara pakai:\n- Nyalakan Instant Fish: ON\n- Klik [START FISHING]\n\nPenjelasan:\n- Skip animasi cast dan reel\n- Langsung complete fishing\n- Cocok untuk farming cepat\n\nRekomendasi Setting:\n- Charge Time: 0\n- Reel Delay: 0\n- Fish Delay: 0.01", 2)

MakeHelpSection(HelpFrame, "[MULTI CAST]", "Lempar banyak pancing sekaligus!\n\nCara pakai:\n- Nyalakan Multi Cast: ON\n- Set Cast Amount (misal 3-5)\n- Klik [START FISHING]\n\nPenjelasan:\n- Lempar beberapa pancing bersamaan\n- Dapat lebih banyak ikan per cycle\n- Bisa digabung dengan mode lain\n\nRekomendasi Setting:\n- Cast Amount: 3-5\n- Charge Time: 0.1\n- Fish Delay: 0.1", 3)

MakeHelpSection(HelpFrame, "[MODE AMAN / SAFE]", "Untuk menghindari deteksi/ban!\n\nCara pakai:\n- Matikan Instant Fish\n- Matikan Multi Cast\n- Set delay lebih tinggi\n\nRekomendasi Setting:\n- Charge Time: 0.4-0.5\n- Reel Delay: 0.2-0.3\n- Fish Delay: 0.3-0.5\n\nTips:\n- Lebih lambat tapi lebih aman\n- Cocok untuk AFK lama", 4)

MakeHelpSection(HelpFrame, "[MODE CEPAT / FAST]", "Keseimbangan speed dan safety!\n\nRekomendasi Setting:\n- Charge Time: 0.1-0.2\n- Reel Delay: 0.05-0.1\n- Fish Delay: 0.1-0.15\n\nTips:\n- Cukup cepat tapi tidak terlalu mencurigakan\n- Cocok untuk farming harian", 5)

MakeHelpSection(HelpFrame, "[FITUR CHEAT]", "Fly: Terbang dengan WASD + Space/Shift\n- Space = naik, Shift = turun\n- Atur Fly Speed sesuai kebutuhan\n\nSpeed Hack: Jalan lebih cepat\n- Atur Walk Speed (default 50)\n\nNoclip: Tembus tembok/objek\n- Berguna untuk akses area tertentu\n\nAnti Lag: Boost FPS\n- Matikan efek visual\n- Cocok untuk HP kentang", 6)

MakeHelpSection(HelpFrame, "[FITUR EVENT]", "Auto Buy Event: Beli event otomatis\n- Pilih event yang diinginkan\n- Nyalakan Auto Buy Event\n- Script akan beli setiap interval\n\nEvent tersedia:\n- Wind, Cloudy, Snow\n- Storm, Radiant, Shark Hunt\n\nAnti AFK: Mencegah kick karena idle\n- Otomatis aktif saat script jalan\n\nAuto Rejoin: Reconnect otomatis\n- Jika disconnect, akan rejoin", 7)

MakeHelpSection(HelpFrame, "[REKOMENDASI SETTING]", "PEMULA (Aman):\n- Instant Fish: OFF\n- Multi Cast: OFF\n- Charge: 0.3, Reel: 0.2, Delay: 0.3\n\nMENENGAH (Balanced):\n- Instant Fish: OFF\n- Multi Cast: ON (3x)\n- Charge: 0.15, Reel: 0.1, Delay: 0.15\n\nPRO (Maximum Speed):\n- Instant Fish: ON\n- Multi Cast: ON (5x)\n- Charge: 0, Reel: 0, Delay: 0.01", 8)
local function SwitchTab(activeTab)
    FishingFrame.Visible = activeTab == "fishing"
    CheatFrame.Visible = activeTab == "cheat"
    EventFrame.Visible = activeTab == "event"
    HelpFrame.Visible = activeTab == "help"
    FishingTabBtn.BackgroundColor3 = activeTab == "fishing" and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(60, 60, 80)
    CheatTabBtn.BackgroundColor3 = activeTab == "cheat" and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(60, 60, 80)
    EventTabBtn.BackgroundColor3 = activeTab == "event" and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(60, 60, 80)
    HelpTabBtn.BackgroundColor3 = activeTab == "help" and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(60, 60, 80)
end

FishingTabBtn.MouseButton1Click:Connect(function() SwitchTab("fishing") end)
CheatTabBtn.MouseButton1Click:Connect(function() SwitchTab("cheat") end)
EventTabBtn.MouseButton1Click:Connect(function() SwitchTab("event") end)
HelpTabBtn.MouseButton1Click:Connect(function() SwitchTab("help") end)

local StatsFrame = Instance.new("Frame", MainFrame) StatsFrame.Size = UDim2.new(1, -40, 0, 45) StatsFrame.Position = UDim2.new(0, 20, 1, -55) StatsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) StatsFrame.BorderSizePixel = 0 Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 8)
local StatsText = Instance.new("TextLabel", StatsFrame) StatsText.Size = UDim2.new(1, -16, 1, -8) StatsText.Position = UDim2.new(0, 8, 0, 4) StatsText.BackgroundTransparency = 1 StatsText.Text = "Fish: 0 | Sold: 0 | 0/min" StatsText.TextColor3 = Color3.fromRGB(180, 180, 190) StatsText.TextSize = 11 StatsText.Font = Enum.Font.Gotham StatsText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", MainFrame) CloseBtn.Size = UDim2.new(0, 30, 0, 30) CloseBtn.Position = UDim2.new(1, -36, 0, 8) CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50) CloseBtn.Text = "X" CloseBtn.TextColor3 = Color3.fromRGB(255,255,255) CloseBtn.TextSize = 14 CloseBtn.Font = Enum.Font.GothamBold Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local MinimizeBtn = Instance.new("TextButton", MainFrame) MinimizeBtn.Size = UDim2.new(0, 30, 0, 30) MinimizeBtn.Position = UDim2.new(1, -70, 0, 8) MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 50) MinimizeBtn.Text = "-" MinimizeBtn.TextColor3 = Color3.fromRGB(255,255,255) MinimizeBtn.TextSize = 18 MinimizeBtn.Font = Enum.Font.GothamBold Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local SizeBtn = Instance.new("TextButton", MainFrame) SizeBtn.Size = UDim2.new(0, 30, 0, 30) SizeBtn.Position = UDim2.new(1, -104, 0, 8) SizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255) SizeBtn.Text = "S" SizeBtn.TextColor3 = Color3.fromRGB(255,255,255) SizeBtn.TextSize = 12 SizeBtn.Font = Enum.Font.GothamBold Instance.new("UICorner", SizeBtn).CornerRadius = UDim.new(0, 6)

local SizePresets = { Small = {300, 500}, Medium = {380, 620}, Large = {450, 700} }
local currentPreset = "Medium"
SizeBtn.MouseButton1Click:Connect(function() currentPreset = currentPreset == "Medium" and "Small" or (currentPreset == "Small" and "Large" or "Medium") SizeBtn.Text = currentPreset:sub(1,1) local p = SizePresets[currentPreset] MainFrame.Size = UDim2.new(0, p[1], 0, p[2]) end)

local isMinimized, savedSize = false, nil
MinimizeBtn.MouseButton1Click:Connect(function() isMinimized = not isMinimized if isMinimized then savedSize = MainFrame.Size MainFrame.Size = UDim2.new(0, MainFrame.Size.X.Offset, 0, 50) MinimizeBtn.Text = "+" TabContainer.Visible, FishingFrame.Visible, CheatFrame.Visible, EventFrame.Visible, HelpFrame.Visible, StatsFrame.Visible, ResizeHandle.Visible = false, false, false, false, false, false, false else MainFrame.Size = savedSize or UDim2.new(0, DEF_W, 0, DEF_H) MinimizeBtn.Text = "-" TabContainer.Visible, StatsFrame.Visible, ResizeHandle.Visible = true, true, true SwitchTab("fishing") end end)

CloseBtn.MouseButton1Click:Connect(function() Config.BlatantMode = false FishingActive = false if Config.NoAnimation then AnimationController:Enable() end if Config.FlyEnabled then FlyController:Disable() end if Config.SpeedEnabled then Config.SpeedEnabled = false updateSpeed() end if Config.NoclipEnabled then NoclipController:Disable() end if Config.AutoBuyEventEnabled then AutoBuyEventController:Disable() end if Config.AntiAFKEnabled then AntiAFKController:Disable() end if Config.AutoRejoinEnabled then AutoRejoinController:Disable() end if Config.AntiLagEnabled then AntiLagController:Disable() end ScreenGui:Destroy() end)

task.spawn(function() while ScreenGui.Parent do task.wait(0.5) local rt = os.clock() - Stats.StartTime local cpm = rt > 0 and (Stats.FishCaught / rt) * 60 or 0 StatsText.Text = string.format("Fish: %d | Sold: %d | %.1f/min", Stats.FishCaught, Stats.TotalSold, cpm) end end)
task.spawn(function() local char = Player.Character or Player.CharacterAdded:Wait() if char:FindFirstChild("Humanoid") then char.Humanoid.Died:Connect(function() Config.BlatantMode = false FishingActive = false end) end end)
Player.CharacterAdded:Connect(function() task.wait(1) updateSpeed() end)

ScreenGui.Parent = Player:WaitForChild("PlayerGui")
