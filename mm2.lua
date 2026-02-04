--[[
    SHEILT MM2 GUI ahhaaha
    Authored by: sheilt
    
    Version: betav1
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local KeyPassed = false

local function CreateKeySystem()
    local Screen = Instance.new("ScreenGui")
    Screen.Name = "SheiltKeySystem"
    Screen.Parent = CoreGui
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 320, 0, 160)
    Frame.Position = UDim2.new(0.5, -160, 0.5, -80)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.Parent = Screen
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(200, 0, 0)
    Stroke.Thickness = 2
    Stroke.Parent = Frame
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    
    local Title = Instance.new("TextLabel")
    Title.Text = "SHEILT KEY SYSTEM BETA"
    Title.Size = UDim2.new(1, 0, 0, 45)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(200, 0, 0)
    Title.Font = Enum.Font.GothamBlack
    Title.TextSize = 18
    Title.Parent = Frame
    
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0.8, 0, 0, 35)
    Box.Position = UDim2.new(0.1, 0, 0.35, 0)
    Box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Box.TextColor3 = Color3.new(1,1,1)
    Box.Text = ""
    Box.PlaceholderText = "Key"
    Box.Font = Enum.Font.GothamBold
    Box.TextSize = 14
    Box.Parent = Frame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.5, 0, 0, 35)
    Btn.Position = UDim2.new(0.25, 0, 0.7, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    Btn.Text = "LOGIN"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBlack
    Btn.TextSize = 14
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    Btn.MouseButton1Click:Connect(function()
        if Box.Text == "github" or Box.Text == "sheilt" then
            Screen:Destroy()
            KeyPassed = true
        else
            Box.Text = "WRONG KEY!"
            task.wait(1)
            Box.Text = ""
        end
    end)
    
    return Screen
end

if not game:IsLoaded() then game.Loaded:Wait() end
local KeyUI = CreateKeySystem()

repeat task.wait(0.1) until KeyPassed


local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

getgenv().OldPos = nil
getgenv().FPDH = Workspace.FallenPartsDestroyHeight

local ESP_Cache = {} 
local GunESP_Instance = nil
local GunESP_Highlight = nil
local GunESP_Billboard = nil

local SafetyActive = false 
local SafeZonePart = nil
local ReturnPos = nil

local LastDeathPosition = nil
local IsDead = false

local SheriffDeathMarker = nil
local LastSheriffPos = nil

local ChinaHatPart = nil
local HatConnection = nil

local Colors = {
    Bg = Color3.fromRGB(18, 18, 18),
    Side = Color3.fromRGB(25, 25, 25),
    Elem = Color3.fromRGB(35, 35, 35),
    Main = Color3.fromRGB(220, 20, 20),
    Sec = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(240, 240, 240),
    
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 100),
    GunDrop = Color3.fromRGB(255, 255, 0)
}

-- default settings
local Settings = {
    -- combat
    AimbotEnabled = false,
    AimbotActive = true,
    AimbotKey = Enum.KeyCode.LeftAlt,
    AimbotPart = "HumanoidRootPart", 
    AimbotFOV = 50,
    MaxDistance = 3000,
    ShowFOV = false,
    WallCheck = true,
    AutoFire = false,
    SmartAim = true,
    Prediction = true,
    PredictionStrength = 1.0,
    
    SilentAim = false,
    SilentAimHitChance = 100,
    
    HitboxExpander = false,
    HitboxSize = 5,
    
    -- antiaim
    AntiAim = "None",
    AntiAimToggled = true,
    
    -- visuals
    ESPEnabled = false,
    ESPChams = false,
    ShowName = false,
    ShowDist = false,
    GunESP = true, 
    
    ChinaHat = false,
    ChinaHatHeight = 0.80, -- lowered
    
    CamFOV = 70,
    
    -- local
    LocalGhost = false,
    LocalColor = {R=255, G=0, B=0},
    LocalTrans = 0.5,
    
    -- movement
    Speedhack = false,
    SpeedVal = 16,
    Bhop = false,
    
    -- safety
    AntiMurderer = false,
    AM_Distance = 69,
    
    -- others
    LogsEnabled = true,
    AutoDeathTP = false,
    
    -- fling
    FlingActive = false,
    SelectedTargets = {}
}


local function GetPing()
    local pingStr = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    local ping = tonumber(string.match(pingStr, "%d+"))
    return ping or 50
end

local function GetPlayerRole(plr)
    if not plr or not plr.Character then return "Innocent" end
    
    local hasKnife = false
    local hasGun = false
    
    local function check(loc)
        for _, item in pairs(loc:GetChildren()) do
            if item:IsA("Tool") then
                local n = string.lower(item.Name)
                if string.find(n, "knife") then hasKnife = true end
                if string.find(n, "gun") or string.find(n, "revolver") then hasGun = true end
            end
        end
    end
    
    if plr.Backpack then check(plr.Backpack) end
    if plr.Character then check(plr.Character) end
    
    if hasKnife then return "Murderer" end
    if hasGun then return "Sheriff" end
    return "Innocent"
end


local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "SheiltLogs"
NotifyGui.ResetOnSpawn = false
if CoreGui:FindFirstChild("SheiltLogs") then
    CoreGui.SheiltLogs:Destroy()
end
NotifyGui.Parent = CoreGui

local LogContainer = Instance.new("Frame")
LogContainer.Size = UDim2.new(0, 350, 0, 600)
LogContainer.Position = UDim2.new(1, -360, 0, 10)
LogContainer.BackgroundTransparency = 1
LogContainer.Parent = NotifyGui

local LogList = Instance.new("UIListLayout")
LogList.Parent = LogContainer
LogList.SortOrder = Enum.SortOrder.LayoutOrder
LogList.Padding = UDim.new(0, 5)
LogList.VerticalAlignment = Enum.VerticalAlignment.Top
LogList.HorizontalAlignment = Enum.HorizontalAlignment.Right

local function SendLog(text, type)
    if not Settings.LogsEnabled then return end
    
    local accent = Colors.Main
    if type == "Warn" then accent = Color3.fromRGB(255, 200, 0) end
    if type == "Error" then accent = Colors.Murderer end
    if type == "Kill" then accent = Color3.fromRGB(50, 255, 50) end
    if type == "Info" then accent = Colors.Sheriff end
    if type == "System" then accent = Color3.fromRGB(200, 200, 200) end

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Frame.BackgroundTransparency = 0.2
    Frame.BorderSizePixel = 0
    Frame.Parent = LogContainer
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = accent
    Stroke.Thickness = 1
    Stroke.Parent = Frame
    
    local Grad = Instance.new("UIGradient")
    Grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25,25,30)),
        ColorSequenceKeypoint.new(1, accent)
    }
    Grad.Transparency = NumberSequence.new(0.3)
    Grad.Rotation = 180
    Grad.Parent = Frame

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -10, 1, 0)
    Lbl.Position = UDim2.new(0, 5, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Colors.Text
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Frame
    
    Debris:AddItem(Frame, 6)
end


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SheiltMM2_GUI"
ScreenGui.ResetOnSpawn = false
if CoreGui:FindFirstChild("SheiltMM2_GUI") then
    CoreGui.SheiltMM2_GUI:Destroy()
end
ScreenGui.Parent = CoreGui

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Colors.Main
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = Settings.AimbotFOV
FOVCircle.Visible = false

local MobBtn = Instance.new("TextButton")
MobBtn.Name = "MobToggle"
MobBtn.Size = UDim2.new(0, 55, 0, 55)
MobBtn.Position = UDim2.new(0, 30, 0.75, 0)
MobBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MobBtn.Text = ""
MobBtn.Parent = ScreenGui
Instance.new("UICorner", MobBtn).CornerRadius = UDim.new(0, 16)

local MobStroke = Instance.new("UIStroke")
MobStroke.Color = Colors.Main
MobStroke.Thickness = 2
MobStroke.Parent = MobBtn

local MobLabel = Instance.new("TextLabel")
MobLabel.Size = UDim2.new(1,0,1,0)
MobLabel.BackgroundTransparency = 1
MobLabel.Text = "S"
MobLabel.TextColor3 = Colors.Main
MobLabel.Font = Enum.Font.GothamBlack
MobLabel.TextSize = 28
MobLabel.Parent = MobBtn

local MobGrad = Instance.new("UIGradient")
MobGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Colors.Main),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 0))
}
MobGrad.Rotation = 45
MobGrad.Parent = MobBtn

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 600, 0, 450)
Main.Position = UDim2.new(0.5, -300, 0.5, -225)
Main.BackgroundColor3 = Colors.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local Stroke = Instance.new("UIStroke")
Stroke.Color = Colors.Main
Stroke.Thickness = 2
Stroke.Parent = Main
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Side = Instance.new("Frame")
Side.Size = UDim2.new(0, 150, 1, 0)
Side.BackgroundColor3 = Colors.Side
Side.BorderSizePixel = 0
Side.Parent = Main
Instance.new("UICorner", Side).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.BackgroundTransparency = 1
Title.Text = "SHEILT\nMM2 GUI\nbetav1"
Title.TextColor3 = Colors.Main
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20
Title.Parent = Side

local PageHold = Instance.new("Frame")
PageHold.Position = UDim2.new(0, 150, 0, 0)
PageHold.Size = UDim2.new(1, -150, 1, 0)
PageHold.BackgroundTransparency = 1
PageHold.Parent = Main

local Tabs = {}
local function CreateTab(name, parent)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, -20, 1, -20)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.ScrollBarThickness = 6
    frame.BorderSizePixel = 0
    frame.Parent = parent
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Tabs[name] = frame
    return frame
end

local Tab_Fling = CreateTab("Fling", PageHold)
local Tab_Combat = CreateTab("Combat", PageHold)
local Tab_Visuals = CreateTab("Visuals", PageHold)
local Tab_Move = CreateTab("Move", PageHold)
local Tab_Safety = CreateTab("Safety", PageHold)
local Tab_Others = CreateTab("Others", PageHold)

Tab_Combat.Visible = true

local function MakeTabBtn(name, txt, y, tabToOpen)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 35) -- Slightly smaller to fit more
    Btn.Position = UDim2.new(0, 10, 0, y)
    Btn.BackgroundColor3 = (name == "Combat") and Colors.Main or Colors.Elem
    Btn.Text = txt
    Btn.TextColor3 = Colors.Text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = Side
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    Btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Visible = false end
        tabToOpen.Visible = true
        for _, c in pairs(Side:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3 = Colors.Elem
                c.TextColor3 = Colors.Text
            end
        end
        Btn.BackgroundColor3 = Colors.Main
    end)
end

MakeTabBtn("Fling", "Fling / TP", 70, Tab_Fling)
MakeTabBtn("Combat", "Combat", 110, Tab_Combat)
MakeTabBtn("Visuals", "Visuals", 150, Tab_Visuals)
MakeTabBtn("Move", "Movement", 190, Tab_Move)
MakeTabBtn("Safety", "Anti-Murderer", 230, Tab_Safety)
MakeTabBtn("Others", "Others", 270, Tab_Others)

local function AddToggle(parent, text, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = Colors.Elem
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.7, 0, 1, 0)
    l.Position = UDim2.new(0.05, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Colors.Text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 24, 0, 24)
    b.Position = UDim2.new(0.9, -24, 0.5, -12)
    b.BackgroundColor3 = default and Colors.Main or Color3.fromRGB(80, 80, 80)
    b.Text = ""
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    
    local on = default
    b.MouseButton1Click:Connect(function()
        on = not on
        b.BackgroundColor3 = on and Colors.Main or Color3.fromRGB(80, 80, 80)
        callback(on)
    end)
    
    if parent:IsA("ScrollingFrame") then
        if not parent:FindFirstChild("UIListLayout") then
            local ll = Instance.new("UIListLayout")
            ll.Padding = UDim.new(0, 8)
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent = parent
        end
        parent.CanvasSize = UDim2.new(0, 0, 0, (#parent:GetChildren() * 50))
    end
end

local function AddButton(parent, text, color, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 40)
    b.BackgroundColor3 = color or Colors.Elem
    b.Text = text
    b.TextColor3 = Colors.Text
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 14
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    
    b.MouseButton1Click:Connect(callback)
    
    if parent:IsA("ScrollingFrame") then
         parent.CanvasSize = UDim2.new(0, 0, 0, (#parent:GetChildren() * 50))
    end
end

local function AddSlider(parent, text, min, max, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 50)
    f.BackgroundColor3 = Colors.Elem
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, 20)
    l.Position = UDim2.new(0, 10, 0, 5)
    l.BackgroundTransparency = 1
    l.Text = text .. ": " .. default
    l.TextColor3 = Colors.Text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0.9, 0, 0, 6)
    bar.Position = UDim2.new(0.05, 0, 0.7, 0)
    bar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    bar.BorderSizePixel = 0
    bar.Parent = f
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Main
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = bar

    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end 
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local pos = UserInputService:GetMouseLocation().X
            local rel = math.clamp((pos - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max-min)*rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            l.Text = text .. ": " .. val
            callback(val)
        end
    end)
    if parent:IsA("ScrollingFrame") then
        parent.CanvasSize = UDim2.new(0, 0, 0, (#parent:GetChildren() * 60))
    end
end

local function AddColorPicker(parent, text, defaultRGB, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 110)
    f.BackgroundColor3 = Colors.Elem
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -60, 0, 20)
    l.Position = UDim2.new(0, 10, 0, 5)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Colors.Text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 40, 0, 20)
    preview.Position = UDim2.new(1, -50, 0, 5)
    preview.BackgroundColor3 = Color3.fromRGB(defaultRGB.R, defaultRGB.G, defaultRGB.B)
    preview.Parent = f
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)
    
    local rgb = {R=defaultRGB.R, G=defaultRGB.G, B=defaultRGB.B}
    
    local function makeSubSlider(name, y, col, key)
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0.9, 0, 0, 6)
        bar.Position = UDim2.new(0.05, 0, 0, y)
        bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(rgb[key]/255, 0, 1, 0)
        fill.BackgroundColor3 = col
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,1,0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = bar
        
        local drag = false
        btn.MouseButton1Down:Connect(function() drag = true end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
        
        RunService.RenderStepped:Connect(function()
            if drag then
                local pos = UserInputService:GetMouseLocation().X
                local rel = math.clamp((pos - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                rgb[key] = math.floor(rel * 255)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                preview.BackgroundColor3 = Color3.fromRGB(rgb.R, rgb.G, rgb.B)
                callback(Color3.fromRGB(rgb.R, rgb.G, rgb.B))
            end
        end)
    end
    
    makeSubSlider("R", 35, Color3.new(1,0,0), "R")
    makeSubSlider("G", 60, Color3.new(0,1,0), "G")
    makeSubSlider("B", 85, Color3.new(0,0,1), "B")
    
    if parent:IsA("ScrollingFrame") then
        parent.CanvasSize = UDim2.new(0, 0, 0, (#parent:GetChildren() * 120))
    end
end

local function AddDropdown(parent, text, options, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = Colors.Elem
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text .. ": " .. options[1]
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = f
    
    local idx = 1
    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        btn.Text = text .. ": " .. options[idx]
        callback(options[idx])
    end)
    if parent:IsA("ScrollingFrame") then
        parent.CanvasSize = UDim2.new(0, 0, 0, (#parent:GetChildren() * 50))
    end
end


local function ResetHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                head.Size = Vector3.new(1, 1, 1) -- Standard Head Size
                head.Transparency = 0
                head.CanCollide = true
            end
        end
    end
end

local function ApplyHitbox(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        head.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
        head.CanCollide = false 
        head.Transparency = 0.6
    end
end

local function ExpandHitboxesLoop()
    if not Settings.HitboxExpander then return end
    for _, p in pairs(Players:GetPlayers()) do
        ApplyHitbox(p)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if Settings.HitboxExpander then
            char:WaitForChild("Head", 5)
            ApplyHitbox(plr)
        end
    end)
end)

local function CreateDeathMarker(position)
    if SheriffDeathMarker then SheriffDeathMarker:Destroy() end
    
    local p = Instance.new("Part")
    p.Name = "SheriffDeathMarker"
    p.Size = Vector3.new(4, 0.2, 4)
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 0.5
    p.Color = Color3.fromRGB(0, 255, 100)
    p.Material = Enum.Material.Neon
    p.Position = position - Vector3.new(0, 2.5, 0) -- Floor level
    p.Parent = Workspace
    
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 100, 0, 40)
    bg.AlwaysOnTop = true
    bg.Adornee = p
    bg.Parent = p
    
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,0,1,0)
    t.BackgroundTransparency = 1
    t.Text = "SHERIFF DIED HERE"
    t.TextColor3 = Color3.fromRGB(0, 255, 100)
    t.Font = Enum.Font.GothamBlack
    t.TextStrokeTransparency = 0
    t.Parent = bg
    
    SheriffDeathMarker = p
    LastSheriffPos = position
end

local function UpdateGunESP()
    if not Settings.GunESP then
        if GunESP_Highlight then GunESP_Highlight:Destroy() GunESP_Highlight = nil end
        if GunESP_Billboard then GunESP_Billboard:Destroy() GunESP_Billboard = nil end
        return
    end

    local foundGun = nil
    
    if GunESP_Instance and GunESP_Instance.Parent then
        foundGun = GunESP_Instance
    else
        if Workspace:FindFirstChild("GunDrop") then
            foundGun = Workspace.GunDrop
        else
            for _, v in pairs(Workspace:GetChildren()) do
                if v.Name == "GunDrop" then
                    foundGun = v
                    break
                end
            end
        end
    end
    
    if foundGun then
        GunESP_Instance = foundGun
        
        if not GunESP_Highlight or GunESP_Highlight.Parent ~= CoreGui then
            if GunESP_Highlight then GunESP_Highlight:Destroy() end
            
            local h = Instance.new("Highlight")
            h.Adornee = foundGun
            h.FillColor = Colors.GunDrop
            h.OutlineColor = Colors.GunDrop
            h.FillTransparency = 0.2
            h.OutlineTransparency = 0
            h.Parent = CoreGui
            GunESP_Highlight = h
        end
        
        if not GunESP_Billboard or GunESP_Billboard.Parent ~= CoreGui then
            if GunESP_Billboard then GunESP_Billboard:Destroy() end
            
            local bg = Instance.new("BillboardGui")
            bg.Size = UDim2.new(0, 100, 0, 30)
            bg.AlwaysOnTop = true
            bg.Adornee = foundGun
            bg.Parent = CoreGui
            
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1,0,1,0)
            t.BackgroundTransparency = 1
            t.Text = "GUN HERE"
            t.TextColor3 = Colors.GunDrop
            t.Font = Enum.Font.GothamBlack
            t.TextStrokeTransparency = 0
            t.Parent = bg
            
            GunESP_Billboard = bg
        end
        
        if GunESP_Highlight.Adornee ~= foundGun then GunESP_Highlight.Adornee = foundGun end
        if GunESP_Billboard.Adornee ~= foundGun then GunESP_Billboard.Adornee = foundGun end
        
    else
        if GunESP_Highlight then GunESP_Highlight:Destroy() GunESP_Highlight = nil end
        if GunESP_Billboard then GunESP_Billboard:Destroy() GunESP_Billboard = nil end
        GunESP_Instance = nil
    end
    
    if SheriffDeathMarker and LastSheriffPos then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local role = GetPlayerRole(p)
                local dist = (p.Character.HumanoidRootPart.Position - LastSheriffPos).Magnitude
                
                if role == "Sheriff" or (role == "Innocent" and dist < 5) then
                     if role == "Sheriff" then
                         SheriffDeathMarker:Destroy()
                         SheriffDeathMarker = nil
                         LastSheriffPos = nil
                         SendLog("Gun Picked Up!", "Info")
                         break
                     end
                end
            end
        end
    end
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GunDrop" and Settings.GunESP then
        SendLog("Gun Dropped!", "Warn")
        UpdateGunESP()
    end
end)

local function UpdateChinaHat()
    if Settings.ChinaHat and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        if not ChinaHatPart then
            ChinaHatPart = Instance.new("Part")
            ChinaHatPart.Name = "SheiltHat"
            ChinaHatPart.Size = Vector3.new(2, 0.5, 2)
            ChinaHatPart.CanCollide = false
            ChinaHatPart.Transparency = 0
            ChinaHatPart.Material = Enum.Material.Neon
            ChinaHatPart.Parent = Workspace
            
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = "http://www.roblox.com/asset/?id=1033714"
            mesh.Scale = Vector3.new(1.5, 1.5, 1.5) 
            mesh.Parent = ChinaHatPart
        end
        
        local hue = tick() % 5 / 5
        ChinaHatPart.Color = Color3.fromHSV(hue, 1, 1)
        
        local head = LocalPlayer.Character.Head
        local camPos = Camera.CFrame.Position
        local dist = (camPos - head.Position).Magnitude
        
        if dist < 1.5 then
            ChinaHatPart.Transparency = 1 -- Hide in FP
        else
            ChinaHatPart.Transparency = 0
        end
        
        ChinaHatPart.CFrame = head.CFrame * CFrame.new(0, Settings.ChinaHatHeight, 0)
    else
        if ChinaHatPart then
            ChinaHatPart:Destroy()
            ChinaHatPart = nil
        end
    end
end

local function OnCharacterAdded(char)
    if IsDead and Settings.AutoDeathTP and LastDeathPosition then
        SendLog("Respawned! Attempting to TP to death...", "Info")
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            for i = 1, 5 do
                task.wait(0.5)
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = LastDeathPosition + Vector3.new(0, 2, 0)
                end
            end
            SendLog("Teleported to death location.", "Info")
        end
    end
    IsDead = false
    
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(function()
            if char:FindFirstChild("HumanoidRootPart") then
                LastDeathPosition = char.HumanoidRootPart.CFrame
                IsDead = true
                SendLog("You died! Position saved.", "Error")
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        local h = c:WaitForChild("Humanoid", 10)
        if h then
            h.Died:Connect(function()
                if GetPlayerRole(p) == "Sheriff" and c:FindFirstChild("HumanoidRootPart") then
                    CreateDeathMarker(c.HumanoidRootPart.Position)
                    SendLog("Sheriff Died! Marked Location.", "Info")
                end
            end)
        end
    end)
end)

for _, p in pairs(Players:GetPlayers()) do
    if p.Character then
        local h = p.Character:FindFirstChild("Humanoid")
        if h then
            h.Died:Connect(function()
                if GetPlayerRole(p) == "Sheriff" and p.Character:FindFirstChild("HumanoidRootPart") then
                    CreateDeathMarker(p.Character.HumanoidRootPart.Position)
                end
            end)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
if LocalPlayer.Character then OnCharacterAdded(LocalPlayer.Character) end


AddToggle(Tab_Combat, "Aimbot Enabled", false, function(v) 
    Settings.AimbotEnabled = v 
    SendLog("Aimbot "..(v and "Enabled" or "Disabled"), "Info")
end)
AddToggle(Tab_Combat, "Silent Aim", false, function(v)
    Settings.SilentAim = v
    SendLog("Silent Aim: " .. tostring(v), "Warn")
end)
AddToggle(Tab_Combat, "Smart Role Logic", true, function(v) 
    Settings.SmartAim = v 
    SendLog("Smart Aim: " .. tostring(v), "Info")
end)
AddToggle(Tab_Combat, "Prediction (Fix Lag)", true, function(v) Settings.Prediction = v end)
AddToggle(Tab_Combat, "Show FOV Circle", false, function(v) Settings.ShowFOV = v end)
AddSlider(Tab_Combat, "Aimbot Range (Dist)", 50, 3000, 2000, function(v) 
    Settings.MaxDistance = v 
end)
AddSlider(Tab_Combat, "FOV Radius", 10, 500, 100, function(v) 
    Settings.AimbotFOV = v 
    FOVCircle.Radius = v
end)
AddToggle(Tab_Combat, "Auto Fire", false, function(v) Settings.AutoFire = v end)
AddToggle(Tab_Combat, "Wall Check", true, function(v) Settings.WallCheck = v end)

AddDropdown(Tab_Combat, "Aim Part", {"HumanoidRootPart", "Head", "Torso"}, function(v)
    Settings.AimbotPart = v
end)

AddToggle(Tab_Combat, "Hitbox Expander", false, function(v) 
    Settings.HitboxExpander = v
    if v then
        ExpandHitboxesLoop()
        SendLog("Hitboxes Expanded!", "Warn")
    else
        ResetHitboxes()
        SendLog("Hitboxes Reset to Normal", "Info")
    end
end)
AddSlider(Tab_Combat, "Hitbox Size", 2, 10, 5, function(v) Settings.HitboxSize = v end)

AddDropdown(Tab_Combat, "Anti-Aim", {"None", "Spin", "Jitter"}, function(v) 
    Settings.AntiAim = v 
end)

AddToggle(Tab_Visuals, "ESP Enabled", false, function(v) Settings.ESPEnabled = v end)
AddToggle(Tab_Visuals, "Gun ESP or Marker", true, function(v) Settings.GunESP = v end)
AddToggle(Tab_Visuals, "Chams", false, function(v) Settings.ESPChams = v end)
AddToggle(Tab_Visuals, "Show Names", false, function(v) Settings.ShowName = v end)
AddToggle(Tab_Visuals, "Show Distance", false, function(v) Settings.ShowDist = v end)

AddToggle(Tab_Visuals, "China Hat :)", false, function(v) 
    Settings.ChinaHat = v 
    if not v and ChinaHatPart then ChinaHatPart:Destroy() ChinaHatPart = nil end
end)
AddSlider(Tab_Visuals, "Hat Height", 0, 30, 6, function(v)
    Settings.ChinaHatHeight = v / 10 -- 0.6 default roughly
end)

AddToggle(Tab_Visuals, "Ghost Mode", false, function(v) Settings.LocalGhost = v end)
AddColorPicker(Tab_Visuals, "Ghost Color", {R=255,G=0,B=0}, function(c) Settings.LocalColor = c end)
AddSlider(Tab_Visuals, "Ghost Transparency", 0, 10, 5, function(v) Settings.LocalTrans = v/10 end)
AddSlider(Tab_Visuals, "Camera FOV", 70, 120, 70, function(v) Settings.CamFOV = v end)

AddToggle(Tab_Move, "Speedhack", false, function(v) Settings.Speedhack = v end)
AddSlider(Tab_Move, "Speed Value", 16, 100, 24, function(v) Settings.SpeedVal = v end)
AddToggle(Tab_Move, "Bhop", false, function(v) Settings.Bhop = v end)

AddToggle(Tab_Safety, "Anti-Murderer", false, function(v) 
    Settings.AntiMurderer = v 
    if not v and SafetyActive then
        if ReturnPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = ReturnPos
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
        end
        SafetyActive = false
        if SafeZonePart then SafeZonePart:Destroy() SafeZonePart = nil end
    end
end)
AddSlider(Tab_Safety, "Protection Distance", 10, 100, 30, function(v) Settings.AM_Distance = v end)

AddToggle(Tab_Others, "Show Logs", true, function(v) Settings.LogsEnabled = v end)
AddToggle(Tab_Others, "Auto TP to Death", false, function(v) 
    Settings.AutoDeathTP = v 
    if v then SendLog("Death TP Enabled", "Info") end
end)

local function FakeServerCrash()
    SendLog("INITIATING SERVER ATTACK...", "Error")
    task.wait(0.5)
    SendLog("Bypassing Anti-Cheat (Byfron)...", "Warn")
    task.wait(0.8)
    SendLog("Injecting Malicious Packets...", "Error")
    task.wait(0.5)
    SendLog("Brute-forcing Admin Panel...", "Warn")
    task.wait(0.3)
    SendLog("Packet Flood: 10000req/s", "Info")
    
    local originalSky = Lighting:FindFirstChildOfClass("Sky")
    local fakeSky = Instance.new("Sky")
    fakeSky.Name = "ErrorSky"
    fakeSky.SkyboxBk = "http://www.roblox.com/asset/?id=0"
    fakeSky.SkyboxDn = "http://www.roblox.com/asset/?id=0"
    fakeSky.SkyboxFt = "http://www.roblox.com/asset/?id=0"
    fakeSky.SkyboxLf = "http://www.roblox.com/asset/?id=0"
    fakeSky.SkyboxRt = "http://www.roblox.com/asset/?id=0"
    fakeSky.SkyboxUp = "http://www.roblox.com/asset/?id=0"
    fakeSky.Parent = Lighting
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/uuhhh.mp3"
    sound.Volume = 10
    sound.Looped = true
    sound.Parent = Workspace
    sound:Play()
    
    local crashGui = Instance.new("ScreenGui")
    crashGui.IgnoreGuiInset = true
    crashGui.Parent = CoreGui
    
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.5
    overlay.Parent = crashGui
    
    local errText = Instance.new("TextLabel")
    errText.Size = UDim2.new(1,0,1,0)
    errText.BackgroundTransparency = 1
    errText.Text = "FATAL ERROR\nSERVER NOT RESPONDING\nDDOS ATTACK IN PROGRESS BY SHEILT"
    errText.TextColor3 = Color3.new(1,0,0)
    errText.TextSize = 40
    errText.Font = Enum.Font.Code
    errText.Parent = overlay
    
    task.spawn(function()
        local start = tick()
        while tick() - start < 5 do
            local x = math.random(-5, 5)
            local y = math.random(-5, 5)
            Camera.CFrame = Camera.CFrame * CFrame.new(x/10, y/10, 0)
            if math.random(1, 5) == 1 then
                overlay.BackgroundColor3 = Color3.new(math.random(), 0, 0)
                errText.TextTransparency = math.random()
            end
            
            if math.random(1, 10) == 1 then
                 SendLog("CRITICAL ERROR: 0xDEADBEEF", "Error")
            end
            task.wait()
        end
        
        crashGui:Destroy()
        sound:Destroy()
        fakeSky:Destroy()
        SendLog("JUST A JOKE >:D", "Info")
    end)
end

AddButton(Tab_Others, "haahah joke server xddd", Colors.Murderer, function()
    FakeServerCrash()
end)

local FlingStatus = Instance.new("TextLabel")
FlingStatus.Size = UDim2.new(1, 0, 0, 25)
FlingStatus.BackgroundTransparency = 1
FlingStatus.Text = "STATUS: IDLE"
FlingStatus.TextColor3 = Colors.Text
FlingStatus.Font = Enum.Font.GothamBold
FlingStatus.TextSize = 14
FlingStatus.Parent = Tab_Fling

local FlingList = Instance.new("ScrollingFrame")
FlingList.Size = UDim2.new(1, 0, 1, -85)
FlingList.Position = UDim2.new(0, 0, 0, 25)
FlingList.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
FlingList.BorderSizePixel = 0
FlingList.ScrollBarThickness = 4
FlingList.Parent = Tab_Fling
Instance.new("UICorner", FlingList).CornerRadius = UDim.new(0, 6)

local ActionContainer = Instance.new("Frame")
ActionContainer.Size = UDim2.new(1, 0, 0, 55)
ActionContainer.Position = UDim2.new(0, 0, 1, -55)
ActionContainer.BackgroundTransparency = 1
ActionContainer.Parent = Tab_Fling

local function CreateActionBtn(txt, col, pos, sz, func)
    local b = Instance.new("TextButton")
    b.Size = sz
    b.Position = pos
    b.BackgroundColor3 = col
    b.Text = txt
    b.TextColor3 = Colors.Text
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 12
    b.Parent = ActionContainer
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(func)
    return b
end

local Checks = {}
local function RefreshPlayerList()
    for _, v in pairs(FlingList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    Checks = {}
    local all = Players:GetPlayers()
    table.sort(all, function(a,b) return a.Name < b.Name end)
    local y = 0
    for _, p in ipairs(all) do
        if p ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -10, 0, 40)
            row.Position = UDim2.new(0, 0, 0, y)
            row.BackgroundColor3 = Colors.Elem
            row.Parent = FlingList
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
            
            local nm = Instance.new("TextLabel")
            nm.Text = p.DisplayName .. " (@" .. p.Name .. ")"
            nm.Size = UDim2.new(0.5, 0, 1, 0)
            nm.Position = UDim2.new(0.05, 0, 0, 0)
            nm.BackgroundTransparency = 1
            nm.TextColor3 = Colors.Text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = row
            
            local tp = Instance.new("TextButton")
            tp.Text = "TP"
            tp.Size = UDim2.new(0, 30, 0, 24)
            tp.Position = UDim2.new(0.7, 0, 0.5, -12)
            tp.BackgroundColor3 = Colors.Main
            tp.TextColor3 = Colors.Text
            tp.Font = Enum.Font.GothamBold
            tp.TextSize = 12
            tp.Parent = row
            Instance.new("UICorner", tp).CornerRadius = UDim.new(0, 4)
            
            tp.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
            end)
            
            local sel = Instance.new("TextButton")
            sel.Text = ""
            sel.Size = UDim2.new(0, 24, 0, 24)
            sel.Position = UDim2.new(0.88, 0, 0.5, -12)
            sel.BackgroundColor3 = Settings.SelectedTargets[p.Name] and Colors.Main or Color3.fromRGB(80, 80, 80)
            sel.Parent = row
            Instance.new("UICorner", sel).CornerRadius = UDim.new(0, 4)
            
            sel.MouseButton1Click:Connect(function()
                if Settings.SelectedTargets[p.Name] then
                    Settings.SelectedTargets[p.Name] = nil
                    sel.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                else
                    Settings.SelectedTargets[p.Name] = p
                    sel.BackgroundColor3 = Colors.Main
                end
            end)
            
            Checks[p.Name] = sel
            y = y + 45
        end
    end
    FlingList.CanvasSize = UDim2.new(0, 0, 0, y)
end

Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)

local function KillTarget(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    
    if not TCharacter then return end
    
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if Character and Humanoid and RootPart then
        if not getgenv().OldPos then
             getgenv().OldPos = RootPart.CFrame
        end
        
        if THead then
            Workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then
             Workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid then
             Workspace.CurrentCamera.CameraSubject = THumanoid
        end
        
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
        
        local FPos = function(BasePart, Pos, Ang)
            if not Settings.FlingActive then return end
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not Settings.FlingActive 
        end
        
        Workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart then SFBasePart(TRootPart)
        elseif THead then SFBasePart(THead)
        elseif Handle then SFBasePart(Handle)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        Workspace.CurrentCamera.CameraSubject = Humanoid
        
        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
                
                Humanoid:ChangeState("GettingUp")
                
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity = Vector3.new(0,0,0)
                        part.RotVelocity = Vector3.new(0,0,0)
                    end
                end
                task.wait()
                
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            
            Workspace.FallenPartsDestroyHeight = getgenv().FPDH
            getgenv().OldPos = nil
        end
    end
end

CreateActionBtn("START", Colors.Main, UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 0, 30), function()
    if Settings.FlingActive then return end
    Settings.FlingActive = true
    FlingStatus.Text = "FLING ACTIVE!"
    FlingStatus.TextColor3 = Colors.Main
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        getgenv().OldPos = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
    
    task.spawn(function()
        while Settings.FlingActive do
            local found = false
            for n, p in pairs(Settings.SelectedTargets) do
                if p and p.Parent and p ~= LocalPlayer then
                    found = true
                    KillTarget(p)
                    task.wait(0.1)
                else
                    Settings.SelectedTargets[n] = nil
                end
            end
            if not found then FlingStatus.Text = "NO TARGETS" end
            task.wait(0.5)
        end
        FlingStatus.Text = "IDLE"
        FlingStatus.TextColor3 = Colors.Text
    end)
end)

CreateActionBtn("STOP", Colors.Murderer, UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 0, 30), function()
    Settings.FlingActive = false
    FlingStatus.Text = "STOPPED"
    FlingStatus.TextColor3 = Colors.Murderer
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
        LocalPlayer.Character.HumanoidRootPart.RotVelocity = Vector3.zero
        Workspace.FallenPartsDestroyHeight = getgenv().FPDH 
    end
end)

CreateActionBtn("ALL", Colors.Elem, UDim2.new(0, 0, 0, 35), UDim2.new(0.23, 0, 0, 20), function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            Settings.SelectedTargets[p.Name] = p
            if Checks[p.Name] then Checks[p.Name].BackgroundColor3 = Colors.Main end
        end
    end
end)

CreateActionBtn("CLEAR", Colors.Elem, UDim2.new(0.25, 0, 0, 35), UDim2.new(0.23, 0, 0, 20), function()
    Settings.SelectedTargets = {}
    for _, b in pairs(Checks) do b.BackgroundColor3 = Color3.fromRGB(80, 80, 80) end
end)



local function IsVisible(targetPart, ignoreList)
    if not Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = ignoreList
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetPredictedPosition(targetPart)
    if not Settings.Prediction then return targetPart.Position end
    
    local ping = GetPing()
    local pingSec = ping / 1000
    local velocity = targetPart.Velocity
    
    local predicted = targetPart.Position + (velocity * (pingSec * Settings.PredictionStrength))
    return predicted
end

local function GetClosestTarget()
    local closest = nil
    local shortestDist = Settings.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    local MyRole = GetPlayerRole(LocalPlayer)
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            
            local TargetRole = GetPlayerRole(plr)
            local AllowTarget = true
            
            if Settings.SmartAim then
                if MyRole == "Innocent" then
                    AllowTarget = false
                elseif MyRole == "Sheriff" then
                    if TargetRole ~= "Murderer" then AllowTarget = false end
                elseif MyRole == "Murderer" then
                    AllowTarget = true
                end
            end

            if not AllowTarget then continue end

            local targetPart = nil
            if plr.Character:FindFirstChild(Settings.AimbotPart) then
                targetPart = plr.Character[Settings.AimbotPart]
            else
                targetPart = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
            end
            
            if targetPart then
                local distToPlayer = (LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude
                if distToPlayer > Settings.MaxDistance then continue end

                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < shortestDist then
                        if IsVisible(targetPart, {LocalPlayer.Character, plr.Character}) then
                            closest = plr
                            shortestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

if getgenv().hookmetamethod then
    local oldIndex = nil
    local oldNamecall = nil
    
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if Settings.SilentAim and self == Mouse and (key == "Hit" or key == "Target") then
            local target = GetClosestTarget()
            if target and target.Character then
                local part = target.Character:FindFirstChild(Settings.AimbotPart) or target.Character:FindFirstChild("Head")
                if part then
                    if key == "Hit" then
                        local predPos = GetPredictedPosition(part)
                        return CFrame.new(predPos)
                    end
                    if key == "Target" then
                        return part
                    end
                end
            end
        end
        return oldIndex(self, key)
    end)
    
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if Settings.SilentAim and self == Mouse and method == "Hit" then
            local target = GetClosestTarget()
            if target and target.Character then
                local part = target.Character:FindFirstChild(Settings.AimbotPart) or target.Character:FindFirstChild("Head")
                if part then
                    local predPos = GetPredictedPosition(part)
                    return CFrame.new(predPos)
                end
            end
        end
        return oldNamecall(self, ...)
    end)
else
    SendLog("HOOK (for silentaim) NOT SUPPORTED", "Error")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Settings.AimbotKey then
            Settings.AimbotActive = not Settings.AimbotActive
            SendLog("Aimbot Active: " .. tostring(Settings.AimbotActive), Settings.AimbotActive and "Info" or "Warn")
        end
        if input.KeyCode == Enum.KeyCode.Z then
            Settings.AntiAimToggled = not Settings.AntiAimToggled
            SendLog("Anti-Aim Toggled: " .. (Settings.AntiAimToggled and "ON" or "OFF"), "System")
        end
        if input.KeyCode == Enum.KeyCode.Quote then
            Main.Visible = not Main.Visible
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.ShowFOV then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Settings.AimbotFOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if Settings.AimbotEnabled and Settings.AimbotActive and not Settings.SilentAim then
        local target = GetClosestTarget()
        if target then
            local part = nil
            if target.Character:FindFirstChild(Settings.AimbotPart) then
                part = target.Character[Settings.AimbotPart]
            else
                part = target.Character:FindFirstChild("HumanoidRootPart")
            end
            
            if part then
                local finalPos = GetPredictedPosition(part)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, finalPos)
            end
        end
    end
    
    if Settings.AutoFire then
        local target = GetClosestTarget()
        if target then
             mouse1click()
        end
    end
    
    if Settings.HitboxExpander then
        ExpandHitboxesLoop()
    end
    
    UpdateGunESP()
    UpdateChinaHat()
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hum = LocalPlayer.Character.Humanoid
        local hrp = LocalPlayer.Character.HumanoidRootPart
        
        if Settings.Speedhack then
            hum.WalkSpeed = Settings.SpeedVal
        else
            if hum.WalkSpeed ~= 16 and not Settings.Speedhack then
                 hum.WalkSpeed = 16
            end
        end
        
        if Settings.Bhop and hum.MoveDirection.Magnitude > 0 then
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum.Jump = true
            end
            
            if hum.FloorMaterial == Enum.Material.Air then
                local moveDir = hum.MoveDirection
                local desiredVel = moveDir * Settings.SpeedVal 
                hrp.Velocity = Vector3.new(desiredVel.X, hrp.Velocity.Y, desiredVel.Z)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Settings.AntiAim ~= "None" and Settings.AntiAimToggled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = false end
        
        local currentPos = hrp.Position
        local newRot = hrp.CFrame.Rotation
        
        if Settings.AntiAim == "Spin" then
            newRot = CFrame.Angles(0, math.rad(tick() * 500 % 360), 0)
        elseif Settings.AntiAim == "Jitter" then
            newRot = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
        end
        hrp.CFrame = CFrame.new(currentPos) * newRot
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
end)

-- antimurderer is bug sorry. mne len' fiksit'
RunService.Heartbeat:Connect(function()
    if not Settings.AntiMurderer then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local murd = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetPlayerRole(p) == "Murderer" then murd = p break end
    end
    
    local myRoot = LocalPlayer.Character.HumanoidRootPart
    
    if murd and murd.Character and murd.Character:FindFirstChild("HumanoidRootPart") then
        local dist = (myRoot.Position - murd.Character.HumanoidRootPart.Position).Magnitude
        
        if dist <= Settings.AM_Distance then
            if not SafetyActive then
                SafetyActive = true
                ReturnPos = myRoot.CFrame
                SendLog("MURDERER NEAR! Teleporting to safety...", "Warn")
                
                if not SafeZonePart then
                    SafeZonePart = Instance.new("Part")
                    SafeZonePart.Size = Vector3.new(50, 2, 50)
                    SafeZonePart.Position = Vector3.new(0, 1000, 0) 
                    SafeZonePart.Anchored = true
                    SafeZonePart.Transparency = 0.5
                    SafeZonePart.Color = Colors.Innocent
                    SafeZonePart.Parent = Workspace
                end
                
                myRoot.CFrame = SafeZonePart.CFrame + Vector3.new(0, 5, 0)
            end
        else
            if SafetyActive then
                SafetyActive = false
                SendLog("Murderer left radius. Returning.", "Info")
                if ReturnPos then
                    myRoot.CFrame = ReturnPos
                    myRoot.Velocity = Vector3.zero 
                end
                if SafeZonePart then
                    SafeZonePart:Destroy()
                    SafeZonePart = nil
                end
            end
        end
    end
end)

local function HookChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    
    task.spawn(function()
        while char.Parent do
            task.wait()
            if Settings.LocalGhost then
                 for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                         part.Color = Settings.LocalColor
                         part.Transparency = Settings.LocalTrans
                         part.Material = Enum.Material.Neon
                    end
                 end
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(HookChar)
if LocalPlayer.Character then HookChar(LocalPlayer.Character) end

local ESPFolder = Instance.new("Folder", game.CoreGui)
ESPFolder.Name = "ESP_Folder"

local function ClearESP(plr)
    if ESP_Cache[plr] then
        if ESP_Cache[plr].Highlight then ESP_Cache[plr].Highlight:Destroy() end
        if ESP_Cache[plr].BillBoard then ESP_Cache[plr].BillBoard:Destroy() end
        ESP_Cache[plr] = nil
    end
end

RunService.RenderStepped:Connect(function()
    Camera.FieldOfView = Settings.CamFOV

    if not Settings.ESPEnabled then 
        for plr, _ in pairs(ESP_Cache) do ClearESP(plr) end
        return 
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            
            if not ESP_Cache[plr] then
                local hl = Instance.new("Highlight")
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = ESPFolder
                
                local bg = Instance.new("BillboardGui")
                bg.Size = UDim2.new(0, 200, 0, 50)
                bg.StudsOffset = Vector3.new(0, 3, 0)
                bg.AlwaysOnTop = true
                bg.Parent = ESPFolder
                
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1,0,1,0)
                txt.BackgroundTransparency = 1
                txt.Font = Enum.Font.GothamBold
                txt.TextSize = 14
                txt.TextStrokeTransparency = 0
                txt.Parent = bg
                
                ESP_Cache[plr] = { Highlight = hl, BillBoard = bg, TextLabel = txt }
            end
            
            local cache = ESP_Cache[plr]
            local role = GetPlayerRole(plr)
            local col = Colors.Innocent
            
            if role == "Murderer" then col = Colors.Murderer
            elseif role == "Sheriff" then col = Colors.Sheriff
            end
            
            cache.Highlight.Adornee = plr.Character
            cache.Highlight.FillColor = col
            cache.Highlight.Enabled = Settings.ESPChams
            
            if Settings.ShowName then
                local dist = ""
                if Settings.ShowDist and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local mag = (LocalPlayer.Character.HumanoidRootPart.Position - plr.Character.Head.Position).Magnitude
                    dist = string.format(" [%.0f]", mag)
                end
                
                cache.BillBoard.Adornee = plr.Character.Head
                cache.TextLabel.Text = plr.Name .. dist .. "\n["..role.."]"
                cache.TextLabel.TextColor3 = col
                cache.BillBoard.Enabled = true
            else
                cache.BillBoard.Enabled = false
            end
        else
            ClearESP(plr)
        end
    end
end)

Players.PlayerRemoving:Connect(ClearESP)
MobBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

RefreshPlayerList()
SendLog("sheilt mm2 gui LOADED!", "Info")
SendLog("visit site rfrfrftrf.github.io", "Info")