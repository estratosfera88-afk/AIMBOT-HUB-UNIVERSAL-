--// ====================== ANTI-BAN / ANTI-KICK SYSTEM ======================
local AntiBanEnabled = true

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if AntiBanEnabled then
    pcall(function()
        local oldKick = LocalPlayer.Kick
        LocalPlayer.Kick = function(self, reason)
            warn("[ANTI-KICK] Tentativa bloqueada: " .. tostring(reason or "Sem motivo"))
            return nil
        end

        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if self == LocalPlayer and (method == "Kick" or method == "kick") then
                warn("[ANTI-KICK] Namecall bloqueado!")
                return nil
            end
            return oldNamecall(self, ...)
        end)

        setreadonly(mt, true)
    end)
    print("âœ… Anti-Ban / Anti-Kick carregado com sucesso")
end
--// =====================================================================

task.wait(1.8)

local Rayfield = nil
local success = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success or not Rayfield then
    task.wait(2)
    success = pcall(function()
        Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
    end)
end

if not Rayfield then
    warn("ERRO CRÃTICO: NÃ£o foi possÃ­vel carregar Rayfield.")
    return
end

--// REMOVE NOTIFICAÃ‡Ã•ES DO RAYFIELD
local OldNotify = Rayfield.Notify
Rayfield.Notify = function(self, tbl)
    if not tbl or not tbl.Title then
        return OldNotify(self, tbl)
    end
    local title = tostring(tbl.Title):lower()
    if title == "rayfield" or title == "sirius" then
        return
    end
    return OldNotify(self, tbl)
end

--// RENAME FIX
task.spawn(function()
    task.wait(2.5)
    pcall(function()
        for _, v in ipairs(game.CoreGui:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text == "Show Rayfield" or v.Text:find("Rayfield")) then
                v.Text = "Aimbot Hub"
            end
        end
    end)
end)

--// SERVICES
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

--// VARIABLES
local Aimbot = false
local AimbotFix = false
local AimbotFixEnabled = false
local LockedTarget = nil
local AimPart = "Head"

local ESP = false
local Names = false
local TeamCheck = false
local WallCheck = true
local AimSmoothness = 4
local NameESPColor = Color3.fromRGB(0,255,0)

local FOVCircle = false
local FOVRadius = 150
local FOVThickness = 4
local FOVTransparency = 0
local FOVColor = Color3.fromRGB(255,0,0)
local FOVRainbow = false

local AntiLag = false
local ShowFPS = false
local RedMode = false
local TargetFPS = 60

--// CAMERA FIX
local OriginalAutoRotate = true

local function GetTargetPart(Character)
    if AimPart == "Head" then
        return Character:FindFirstChild("Head")
    else
        return Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
    end
end

local function IsTargetValid(target)
    if not target or not target.Parent then return false end
    
    local character = target.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or humanoid.Health <= 0 then return false end
    if not root then return false end
    
    local LocalRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if LocalRoot and (root.Position - LocalRoot.Position).Magnitude > 400 then
        return false
    end
    
    return true
end

local function ApplyCameraFix()
    if not LocalPlayer.Character then return end
    local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        OriginalAutoRotate = Humanoid.AutoRotate
        Humanoid.AutoRotate = false
    end
end

local function RemoveCameraFix()
    if not LocalPlayer.Character then return end
    local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        Humanoid.AutoRotate = OriginalAutoRotate
    end
end

--// THEME
local Theme = {
    TextColor = Color3.fromRGB(255,255,255), Background = Color3.fromRGB(18,18,18),
    Topbar = Color3.fromRGB(40,0,0), Shadow = Color3.fromRGB(0,0,0),
    NotificationBackground = Color3.fromRGB(18,18,18), NotificationActionsBackground = Color3.fromRGB(45,0,0),
    TabBackground = Color3.fromRGB(22,22,22), TabStroke = Color3.fromRGB(80,0,0),
    TabBackgroundSelected = Color3.fromRGB(120,0,0), TabTextColor = Color3.fromRGB(255,255,255),
    SelectedTabTextColor = Color3.fromRGB(255,255,255), ElementBackground = Color3.fromRGB(35,0,0),
    ElementBackgroundHover = Color3.fromRGB(55,0,0), SecondaryElementBackground = Color3.fromRGB(70,0,0),
    ElementStroke = Color3.fromRGB(120,0,0), SecondaryElementStroke = Color3.fromRGB(160,0,0),
    SliderBackground = Color3.fromRGB(45,0,0), SliderProgress = Color3.fromRGB(255,0,0),
    SliderStroke = Color3.fromRGB(255,80,80), ToggleBackground = Color3.fromRGB(40,0,0),
    ToggleEnabled = Color3.fromRGB(180,0,0), ToggleDisabled = Color3.fromRGB(60,60,60),
    ToggleEnabledStroke = Color3.fromRGB(255,0,0), ToggleDisabledStroke = Color3.fromRGB(100,100,100),
    ToggleEnabledOuterStroke = Color3.fromRGB(120,0,0), ToggleDisabledOuterStroke = Color3.fromRGB(80,80,80),
    DropdownSelected = Color3.fromRGB(70,0,0), DropdownUnselected = Color3.fromRGB(40,0,0),
    InputBackground = Color3.fromRGB(35,0,0), InputStroke = Color3.fromRGB(100,0,0),
    PlaceholderColor = Color3.fromRGB(180,180,180)
}

--// WINDOW
local Window = Rayfield:CreateWindow({
    Name = "Aimbot Hub Universal",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Script Aimbot Hub Oficial",
    Theme = Theme,
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    Size = UDim2.new(0, 520, 0, 440)
})

--// TABS
local Main = Window:CreateTab("Aimbot", 4483345998)
local MobileTab = Window:CreateTab("Aimbot Fix", 4483345998)
local FOVTab = Window:CreateTab("FOV Circle", 7733920644)
local Visual = Window:CreateTab("Visuals", 6031763426)
local FPSUI = Window:CreateTab("FPS UI", 6031763426)

--// FOV CIRCLE GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FOVCircle"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Circle = Instance.new("Frame")
Circle.Parent = ScreenGui
Circle.AnchorPoint = Vector2.new(0.5, 0.5)
Circle.Position = UDim2.new(0.5, 0, 0.5, 0)
Circle.BackgroundTransparency = 1
Circle.BorderSizePixel = 0
Circle.Visible = false

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = Circle

local Stroke = Instance.new("UIStroke")
Stroke.Parent = Circle
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Stroke.LineJoinMode = Enum.LineJoinMode.Round
Stroke.Thickness = FOVThickness
Stroke.Color = FOVColor
Stroke.Transparency = FOVTransparency

--// FPS COUNTER GUI
local FPSGui = Instance.new("ScreenGui")
FPSGui.Name = "FPSCounter"
FPSGui.IgnoreGuiInset = true
FPSGui.ResetOnSpawn = false
FPSGui.Parent = game.CoreGui

local FPSFrame = Instance.new("Frame")
FPSFrame.Parent = FPSGui
FPSFrame.Size = UDim2.new(0, 98, 0, 48)
FPSFrame.Position = UDim2.new(0.03, 0, 0.22, 0)
FPSFrame.BackgroundTransparency = 0.4
FPSFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
FPSFrame.Visible = false

local FPSCorner = Instance.new("UICorner")
FPSCorner.CornerRadius = UDim.new(1, 0)
FPSCorner.Parent = FPSFrame

local FPSStroke = Instance.new("UIStroke")
FPSStroke.Parent = FPSFrame
FPSStroke.Thickness = 2
FPSStroke.Color = Color3.fromRGB(255, 0, 0)
FPSStroke.Transparency = 0.1

local FPSGlow = Instance.new("UIStroke")
FPSGlow.Parent = FPSFrame
FPSGlow.Thickness = 5
FPSGlow.Color = Color3.fromRGB(255, 0, 0)
FPSGlow.Transparency = 0.8
FPSGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

local FPSText = Instance.new("TextLabel")
FPSText.Parent = FPSFrame
FPSText.Size = UDim2.new(1, 0, 1, 0)
FPSText.BackgroundTransparency = 1
FPSText.Text = "FPS: 60"
FPSText.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSText.TextSize = 29
FPSText.Font = Enum.Font.GothamBold
FPSText.TextStrokeTransparency = 0.6
FPSText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

--// FLOATING BUTTON
local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "AimbotFixButton"
MobileGui.ResetOnSpawn = false
MobileGui.Parent = game.CoreGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = MobileGui
ToggleButton.Size = UDim2.new(0,58,0,58)
ToggleButton.Position = UDim2.new(0.82,0,0.7,0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20,20,20)
ToggleButton.Text = "OFF"
ToggleButton.TextScaled = false
ToggleButton.TextSize = 18
ToggleButton.Font = Enum.Font.GothamBlack
ToggleButton.TextColor3 = Color3.fromRGB(0,0,0)
ToggleButton.TextStrokeTransparency = 0.2
ToggleButton.TextStrokeColor3 = Color3.fromRGB(0,0,0)
ToggleButton.BorderSizePixel = 0
ToggleButton.Visible = false

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1,0)
Corner.Parent = ToggleButton

local StrokeButton = Instance.new("UIStroke")
StrokeButton.Parent = ToggleButton
StrokeButton.Thickness = 3
StrokeButton.Color = Color3.fromRGB(255,0,0)

local BlackStroke = Instance.new("UIStroke")
BlackStroke.Parent = ToggleButton
BlackStroke.Thickness = 1.2
BlackStroke.Color = Color3.fromRGB(0,0,0)
BlackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local Gradient = Instance.new("UIGradient")
Gradient.Parent = ToggleButton
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80,0,0))
}

task.spawn(function()
    while task.wait() do
        TweenService:Create(Gradient, TweenInfo.new(2, Enum.EasingStyle.Linear), {Rotation = Gradient.Rotation + 180}):Play()
        task.wait(2)
    end
end)

local function AnimateButton()
    TweenService:Create(ToggleButton, TweenInfo.new(0.08, Enum.EasingStyle.Back), {Size = UDim2.new(0,52,0,52)}):Play()
    task.wait(0.08)
    TweenService:Create(ToggleButton, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = UDim2.new(0,58,0,58)}):Play()
end

--// DRAG BUTTON
local dragging = false
local dragInput
local dragStart
local startPos

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// AIMBOT FIX FUNCTIONS
local function UpdateButtonVisibility()
    ToggleButton.Visible = AimbotFixEnabled
end

local function ToggleAimbotFix(active)
    AimbotFix = active
    if active then
        ApplyCameraFix()
        ToggleButton.Text = "ON"
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255,0,0)}):Play()
    else
        RemoveCameraFix()
        LockedTarget = nil
        ToggleButton.Text = "OFF"
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
    end
end

--// UI ELEMENTS
Main:CreateToggle({Name = "Aimbot", CurrentValue = false, Callback = function(v)
    Aimbot = v
    if not v then LockedTarget = nil end
    if v and AimbotFixEnabled then
        Rayfield:Notify({Title = "âš ï¸ AVISO", Content = "NÃ£o use Aimbot e Aimbot Fix ao mesmo tempo, Pois nÃ£o vai funcionar.", Duration = 6})
    end
end})

Main:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) WallCheck = v end})
Main:CreateDropdown({Name = "Aim Part", Options = {"Head", "Chest"}, CurrentOption = {"Head"}, Callback = function(Option) 
    AimPart = Option[1]
    LockedTarget = nil 
end})

Main:CreateSlider({Name = "Aimbot Smoothness", Range = {1,30}, Increment = 1, Suffix = "Smooth", CurrentValue = 4, Callback = function(v) AimSmoothness = v end})

MobileTab:CreateToggle({Name = "Enable Aimbot Fix", CurrentValue = false, Callback = function(v)
    AimbotFixEnabled = v
    ToggleAimbotFix(v)
    UpdateButtonVisibility()
end})

Visual:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(v) TeamCheck = v end})
Visual:CreateToggle({Name = "Player ESP", CurrentValue = false, Callback = function(v) ESP = v end})
Visual:CreateToggle({Name = "Name ESP", CurrentValue = false, Callback = function(v) Names = v end})
Visual:CreateColorPicker({Name = "Name ESP Color", Color = Color3.fromRGB(0,255,0), Callback = function(v) NameESPColor = v end})

FOVTab:CreateToggle({Name = "Enable Circle", CurrentValue = false, Callback = function(v) FOVCircle = v end})
FOVTab:CreateSlider({Name = "Circle Size", Range = {50,250}, Increment = 5, Suffix = "PX", CurrentValue = 150, Callback = function(v) FOVRadius = v end})
FOVTab:CreateSlider({Name = "Circle Thickness", Range = {1,30}, Increment = 1, Suffix = "PX", CurrentValue = 4, Callback = function(v) FOVThickness = v end})
FOVTab:CreateSlider({Name = "Circle Transparency", Range = {0,1}, Increment = 0.05, Suffix = "", CurrentValue = 0, Callback = function(v) FOVTransparency = v end})
FOVTab:CreateColorPicker({Name = "Circle Color", Color = Color3.fromRGB(255,0,0), Callback = function(v) FOVColor = v end})
FOVTab:CreateToggle({Name = "RGB", CurrentValue = false, Callback = function(v) FOVRainbow = v end})

--// FPS UI
FPSUI:CreateToggle({
    Name = "Anti Lag",
    CurrentValue = false,
    Callback = function(v)
        AntiLag = v
        pcall(function()
            if v then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 1000000
                Lighting.Brightness = 1
                Lighting.ClockTime = 12
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0
                Lighting.Technology = Enum.Technology.Compatibility
            else
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                Lighting.GlobalShadows = true
                Lighting.Technology = Enum.Technology.Future
            end
        end)
    end
})

FPSUI:CreateToggle({Name = "Show FPS", CurrentValue = false, Callback = function(v) 
    ShowFPS = v 
    FPSFrame.Visible = v 
end})

FPSUI:CreateToggle({Name = "RED Mode", CurrentValue = false, Callback = function(v) RedMode = v end})

FPSUI:CreateDropdown({Name = "FPS Limit", Options = {"30", "60", "120", "240", "Unlimited"}, CurrentOption = {"60"}, Callback = function(Option)
    TargetFPS = Option[1] == "Unlimited" and 9999 or tonumber(Option[1])
    if setfpscap then setfpscap(TargetFPS) end
end})

--// GET CLOSEST PLAYER
local function GetClosestPlayer()
    local Closest, ClosestDistance = nil, math.huge
    local Center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, v in ipairs(Players:GetPlayers()) do
        if v == LocalPlayer or (TeamCheck and v.Team == LocalPlayer.Team) then continue end
        local Char = v.Character
        if not Char then continue end
        
        local Hum = Char:FindFirstChildOfClass("Humanoid")
        if not Hum or Hum.Health <= 0 then continue end

        local TargetPart = GetTargetPart(Char)
        if not TargetPart then continue end

        local Pos, Visible = Camera:WorldToViewportPoint(TargetPart.Position)
        if not Visible or Pos.Z <= 0 then continue end

        if WallCheck then
            local Params = RaycastParams.new()
            Params.FilterType = Enum.RaycastFilterType.Blacklist
            Params.FilterDescendantsInstances = {LocalPlayer.Character}
            local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, Params)
            if Result and not Result.Instance:IsDescendantOf(Char) then continue end
        end

        local Distance = (Vector2.new(Pos.X, Pos.Y) - Center).Magnitude
        if (Aimbot or AimbotFix) and Distance > FOVRadius then continue end

        if Distance < ClosestDistance then
            ClosestDistance = Distance
            Closest = TargetPart
        end
    end
    return Closest
end

--// ESP
local Highlights = {}
local Drawings = {}

local function CreateESP(Player)
    if Player == LocalPlayer then return end
    local Highlight = Instance.new("Highlight")
    Highlight.FillTransparency = 0.5
    Highlight.OutlineTransparency = 0
    Highlight.Enabled = false
    Highlight.Parent = game.CoreGui
    Highlights[Player] = Highlight

    local Text = Drawing.new("Text")
    Text.Size = 13
    Text.Font = 2
    Text.Center = true
    Text.Outline = true
    Text.Visible = false
    Drawings[Player] = Text
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
    Circle.Position = UDim2.new(0, Camera.ViewportSize.X/2, 0, Camera.ViewportSize.Y/2)
    Circle.Size = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)
    Circle.Visible = FOVCircle
    Stroke.Thickness = FOVThickness
    Stroke.Transparency = FOVTransparency
    Stroke.Color = FOVRainbow and Color3.fromHSV(tick()%5/5, 1, 1) or FOVColor

    if Aimbot or AimbotFix then
        local Target = nil
        if AimbotFix then
            if LockedTarget and not IsTargetValid(LockedTarget) then 
                LockedTarget = nil 
            end
            if not LockedTarget then 
                LockedTarget = GetClosestPlayer() 
            end
            Target = LockedTarget
        else
            Target = GetClosestPlayer()
        end

        if Target and Target.Position then
            if AimbotFix then
                local Character = LocalPlayer.Character
                local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                if RootPart then
                    local TargetPos = Target.Position
                    
                    local NewCFrame = CFrame.lookAt(RootPart.Position, TargetPos)
                    RootPart.CFrame = CFrame.new(RootPart.Position) * NewCFrame.Rotation
                    
                    local CamCFrame = CFrame.lookAt(Camera.CFrame.Position, TargetPos)
                    Camera.CFrame = Camera.CFrame:Lerp(CamCFrame, 0.62)
                end
            else
                local Smooth = math.clamp(1 / (AimSmoothness + 1.5), 0.08, 0.65)
                local AimCFrame = CFrame.lookAt(Camera.CFrame.Position, Target.Position)
                Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, Smooth)
            end
        end
    end

    for Player, Highlight in pairs(Highlights) do
        local Char = Player.Character
        local Text = Drawings[Player]
        if not Char then 
            if Highlight then Highlight.Enabled = false end
            if Text then Text.Visible = false end
            continue 
        end

        local Hum = Char:FindFirstChildOfClass("Humanoid")
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local Head = Char:FindFirstChild("Head")

        if not Hum or Hum.Health <= 0 or not Root then
            if Highlight then Highlight.Enabled = false end
            if Text then Text.Visible = false end
            continue
        end

        local TeamColor = (Player.Team == LocalPlayer.Team) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)

        Highlight.Adornee = Char
        Highlight.FillColor = TeamColor
        Highlight.OutlineColor = TeamColor
        Highlight.Enabled = ESP

        if Names and Head and Text then
            local Pos, OnScreen = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 2.5, 0))
            if OnScreen then
                local Dist = math.floor((Camera.CFrame.Position - Root.Position).Magnitude)
                Text.Text = Player.Name .. " [" .. Dist .. "m]"
                Text.Position = Vector2.new(Pos.X, Pos.Y)
                Text.Color = NameESPColor
                Text.Visible = true
            else
                Text.Visible = false
            end
        elseif Text then
            Text.Visible = false
        end
    end
end)

--// FPS COUNTER
local lastTime = tick()
local frameCount = 0
local hue = 0

RunService.RenderStepped:Connect(function()
    if not ShowFPS then return end
    frameCount += 1
    local currentTime = tick()
    if currentTime - lastTime >= 0.1 then
        local fps = math.floor(frameCount / (currentTime - lastTime))
        FPSText.Text = "FPS: " .. tostring(fps)

        if RedMode then
            local t = tick() * 3
            local alpha = (math.sin(t) + 1) / 2
            local color = Color3.fromRGB(160, math.floor(40 * alpha), math.floor(40 * alpha))
            FPSText.TextColor3 = color
            FPSStroke.Color = color
            FPSGlow.Color = color
        else
            hue = (hue + 0.035) % 1
            local color = Color3.fromHSV(hue, 1, 1)
            FPSText.TextColor3 = color
            FPSStroke.Color = color
            FPSGlow.Color = color
        end

        frameCount = 0
        lastTime = currentTime
    end
end)

--// BUTTON CLICK
ToggleButton.MouseButton1Click:Connect(function()
    AnimateButton()
    ToggleAimbotFix(not AimbotFix)
end)

--// NOTIFICAÃ‡Ã•ES FINAIS 
task.spawn(function()
    repeat task.wait() until Window
    task.wait(2)

    Rayfield:Notify({
        Title = "Aimbot Hub Universal",
        Content = "Carregado com sucesso.",
        Duration = 6,
        Image = 4483362458
    })

    task.wait(2)

    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/rZuYzZ7zvt")
            Rayfield:Notify({
                Title = "Script Link Server Discord.",
                Content = "Link do Discord copiado",
                Duration = 6,
                Image = 6031225819
            })
        end
    end)
end)
