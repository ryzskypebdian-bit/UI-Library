--[[
    R28 UI Library (Self-contained)
    Dibuat berdasarkan gaya visual script R28 HUB
    API:
        local Lib = R28Lib.new({ Title = "My Hub", Logo = "rbxassetid://...", AccentColor = Color3... })
        local Tab = Lib:Tab("Main")
        Tab:Section("Visual")
        Tab:Toggle("Name", false, function(v) end)
        Tab:Slider("Name", min, max, default, isFloat, function(v) end)
        Tab:Button("Name", "LABEL", function() end)
        Tab:Cycle("Name", "Mode", function(btn, label) end)
        Tab:Divider()
        Lib:Notify("Title", "Text", 3)
]]

local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui        = game:GetService("CoreGui")
local RunService     = game:GetService("RunService")
local Players        = game:GetService("Players")
local LocalPlayer    = Players.LocalPlayer

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    AccentColor     = Color3.fromRGB(0, 255, 255),
    BackgroundColor = Color3.fromRGB(8, 12, 20),
    MainColor       = Color3.fromRGB(14, 20, 35),
    OutlineColor    = Color3.fromRGB(0, 179, 255),
    FontColor       = Color3.fromRGB(180, 239, 255),
    TextDim         = Color3.fromRGB(200, 200, 200),
    TextMuted       = Color3.fromRGB(120, 120, 130),
    DangerColor     = Color3.fromRGB(139, 0, 0),
    OnColor         = Color3.fromRGB(60, 200, 120),
    Icons = {
        Close  = "rbxassetid://10747384394",
        Minus  = "rbxassetid://10734896206",
        Lock   = "rbxassetid://10723434711",
        Unlock = "rbxassetid://10723434711",
    },
}

-- ============================================================
-- UTILS
-- ============================================================
local Utils = {}

function Utils.New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    return obj
end

function Utils.GlowStroke(parent, c1, c2)
    pcall(function()
        if parent:IsA("UIStroke") then
            parent.Color = Color3.fromRGB(255, 255, 255)
        elseif parent:IsA("GuiObject") then
            parent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, c1 or Theme.AccentColor),
        ColorSequenceKeypoint.new(1, c2 or Theme.MainColor),
    }
    g.Parent = parent
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if g.Parent then
            g.Rotation = (g.Rotation + 120 * dt) % 360
        else
            conn:Disconnect()
        end
    end)
    return g
end

function Utils.MakeDraggable(frame, handle, isLockedFn, cancelFn)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if isLockedFn and isLockedFn() then return end
        if cancelFn and cancelFn() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragStart then return end
        if isLockedFn and isLockedFn() then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false; dragStart = nil
        end
    end)
end

-- ============================================================
-- NOTIFY SYSTEM
-- ============================================================
local Notify = {}
Notify.Gui = nil
Notify.Stack = {}
Notify.W, Notify.H, Notify.Gap = 207, 47, 6
Notify.TopOffset, Notify.RightOffset, Notify.LogoSize = 60, 15, 31

local function GetNotifyGui()
    if Notify.Gui and Notify.Gui.Parent then return Notify.Gui end
    local sg = CoreGui:FindFirstChild("R28Lib_NotifyGui")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "R28Lib_NotifyGui"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local ok = pcall(function() sg.Parent = CoreGui end)
        if not ok then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end
    Notify.Gui = sg
    return sg
end

local function Reposition()
    local y = Notify.TopOffset
    for _, f in ipairs(Notify.Stack) do
        if f and f.Parent then
            f.Position = UDim2.new(1, -(Notify.W + Notify.RightOffset), 0, y)
            y = y + Notify.H + Notify.Gap
        end
    end
end

function Notify.Show(title, text, duration, logo)
    duration = duration or 2
    pcall(function()
        local sg = GetNotifyGui()
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, Notify.W, 0, Notify.H)
        frame.Position = UDim2.new(1, -(Notify.W + Notify.RightOffset), 0, Notify.TopOffset)
        frame.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Parent = sg
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Theme.AccentColor
        stroke.Thickness = 1
        stroke.Transparency = 1
        Utils.GlowStroke(stroke, Theme.AccentColor, Theme.BackgroundColor)

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(0, Notify.LogoSize, 0, Notify.LogoSize)
        img.Position = UDim2.new(0, 9, 0.5, -(Notify.LogoSize / 2))
        img.BackgroundTransparency = 1
        img.Image = logo or ""
        img.ImageColor3 = Theme.FontColor
        img.ScaleType = Enum.ScaleType.Fit
        img.ZIndex = 2
        img.ImageTransparency = 1
        img.Parent = frame

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -(Notify.LogoSize + 18), 0, 18)
        t.Position = UDim2.new(0, Notify.LogoSize + 13, 0, 4)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = Theme.AccentColor
        t.Font = Enum.Font.Code
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTransparency = 1
        t.ZIndex = 2
        t.Parent = frame

        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -(Notify.LogoSize + 18), 0, 18)
        b.Position = UDim2.new(0, Notify.LogoSize + 13, 0, 22)
        b.BackgroundTransparency = 1
        b.Text = text
        b.TextColor3 = Theme.FontColor
        b.Font = Enum.Font.Code
        b.TextSize = 11
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTransparency = 1
        b.ZIndex = 2
        b.Parent = frame

        table.insert(Notify.Stack, 1, frame)
        Reposition()

        local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(frame, info, { BackgroundTransparency = 0 }):Play()
        TweenService:Create(stroke, info, { Transparency = 0 }):Play()
        TweenService:Create(img, info, { ImageTransparency = 0 }):Play()
        TweenService:Create(t, info, { TextTransparency = 0 }):Play()
        TweenService:Create(b, info, { TextTransparency = 0 }):Play()

        task.delay(duration, function()
            if not (frame and frame.Parent) then return end
            local out = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            TweenService:Create(frame, out, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(stroke, out, { Transparency = 1 }):Play()
            TweenService:Create(img, out, { ImageTransparency = 1 }):Play()
            TweenService:Create(t, out, { TextTransparency = 1 }):Play()
            TweenService:Create(b, out, { TextTransparency = 1 }):Play()
            task.wait(0.28)
            for i, f in ipairs(Notify.Stack) do
                if f == frame then table.remove(Notify.Stack, i); break end
            end
            if frame.Parent then frame:Destroy() end
            Reposition()
        end)
    end)
end

-- ============================================================
-- WIDGETS
-- ============================================================
local Widgets = {}

function Widgets.Section(parent, text, order)
    local s = Instance.new("Frame", parent)
    s.Size = UDim2.new(1, 0, 0, 22)
    s.LayoutOrder = order
    s.BackgroundTransparency = 1
    s.ZIndex = 3
    local l = Instance.new("TextLabel", s)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Theme.OutlineColor
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 3
    local p = Instance.new("UIPadding", l)
    p.PaddingLeft = UDim.new(0, 4)
    return s
end

function Widgets.Divider(parent, order)
    local d = Instance.new("Frame", parent)
    d.Size = UDim2.new(1, 0, 0, 8)
    d.LayoutOrder = order
    d.BackgroundTransparency = 1
    d.ZIndex = 3
    local line = Instance.new("Frame", d)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Theme.OutlineColor
    line.BorderSizePixel = 0
    return d
end

function Widgets.Toggle(parent, order, label, default, callback)
    local C = Instance.new("TextButton")
    C.Size = UDim2.new(1, 0, 0, 24)
    C.BackgroundTransparency = 1
    C.Text = ""
    C.LayoutOrder = order
    C.Parent = parent
    C.ZIndex = 3

    local L = Instance.new("TextLabel", C)
    L.Size = UDim2.new(0.7, 0, 1, 0)
    L.BackgroundTransparency = 1
    L.Text = label
    L.TextColor3 = Theme.TextDim
    L.Font = Enum.Font.Code
    L.TextSize = 12
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.ZIndex = 3

    local IB = Instance.new("Frame", C)
    IB.Size = UDim2.new(0, 34, 0, 18)
    IB.Position = UDim2.new(1, -34, 0.5, -9)
    IB.BackgroundColor3 = default and Color3.fromRGB(90, 120, 210) or Color3.fromRGB(40, 40, 45)
    IB.ZIndex = 3
    Instance.new("UICorner", IB).CornerRadius = UDim.new(1, 0)

    local Ci = Instance.new("Frame", IB)
    Ci.Size = UDim2.new(0, 14, 0, 14)
    Ci.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    Ci.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ci.ZIndex = 4
    Instance.new("UICorner", Ci).CornerRadius = UDim.new(1, 0)

    local state = default
    C.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        TweenService:Create(IB, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(90, 120, 210) or Color3.fromRGB(40, 40, 45)
        }):Play()
        TweenService:Create(Ci, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        }):Play()
    end)
    return C
end

function Widgets.Slider(parent, order, label, min, max, default, isFloat, callback)
    local C = Instance.new("Frame", parent)
    C.Size = UDim2.new(1, 0, 0, 34)
    C.BackgroundTransparency = 1
    C.LayoutOrder = order
    C.ZIndex = 3

    local L = Instance.new("TextLabel", C)
    L.Size = UDim2.new(1, 0, 0, 14)
    L.Position = UDim2.new(0, 0, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = label .. ": " .. default
    L.TextColor3 = Theme.TextDim
    L.Font = Enum.Font.Code
    L.TextSize = 11
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.ZIndex = 3

    local SB = Instance.new("Frame", C)
    SB.Size = UDim2.new(1, 0, 0, 8)
    SB.Position = UDim2.new(0, 0, 0, 20)
    SB.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    SB.ZIndex = 3
    Instance.new("UICorner", SB).CornerRadius = UDim.new(1, 0)

    local ip = math.clamp((default - min) / (max - min), 0, 1)
    local SF = Instance.new("Frame", SB)
    SF.Size = UDim2.new(ip, 0, 1, 0)
    SF.BackgroundColor3 = Color3.fromRGB(90, 120, 210)
    SF.ZIndex = 4
    Instance.new("UICorner", SF).CornerRadius = UDim.new(1, 0)

    local Ci = Instance.new("Frame", SB)
    Ci.Size = UDim2.new(0, 14, 0, 14)
    Ci.AnchorPoint = Vector2.new(0.5, 0.5)
    Ci.Position = UDim2.new(ip, 0, 0.5, 0)
    Ci.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ci.ZIndex = 5
    Instance.new("UICorner", Ci).CornerRadius = UDim.new(1, 0)

    local drag = false
    local function Upd(input)
        if not SB or not SB.Parent or SB.AbsoluteSize.X <= 0 then return end
        local pc = math.clamp((input.Position.X - SB.AbsolutePosition.X) / SB.AbsoluteSize.X, 0, 1)
        local v = min + pc * (max - min)
        v = math.clamp(v, min, max)
        v = isFloat and (math.floor(v * 100 + 0.5) / 100) or math.floor(v + 0.5)
        local cp = math.clamp((v - min) / (max - min), 0, 1)
        TweenService:Create(SF, TweenInfo.new(0.08), { Size = UDim2.new(cp, 0, 1, 0) }):Play()
        TweenService:Create(Ci, TweenInfo.new(0.08), { Position = UDim2.new(cp, 0, 0.5, 0) }):Play()
        L.Text = label .. ": " .. v
        callback(v)
    end
    SB.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; Upd(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            Upd(i)
        end
    end)
    return C
end

function Widgets.Button(parent, order, label, buttonText, callback, customColor)
    local C = Instance.new("Frame", parent)
    C.Size = UDim2.new(1, 0, 0, 24)
    C.BackgroundTransparency = 1
    C.LayoutOrder = order
    C.ZIndex = 3

    local L = Instance.new("TextLabel", C)
    L.Size = UDim2.new(0.6, 0, 1, 0)
    L.BackgroundTransparency = 1
    L.Text = label
    L.TextColor3 = Theme.TextDim
    L.Font = Enum.Font.Code
    L.TextSize = 12
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.ZIndex = 3

    local ac = customColor or Color3.fromRGB(90, 120, 210)
    local B = Instance.new("TextButton", C)
    B.Size = UDim2.new(0.4, 0, 0, 18)
    B.Position = UDim2.new(0.6, 0, 0.5, -9)
    B.BackgroundTransparency = 1
    B.Text = buttonText
    B.TextColor3 = ac
    B.Font = Enum.Font.Code
    B.TextSize = 10
    B.AutoButtonColor = false
    B.ZIndex = 4
    Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
    local S = Instance.new("UIStroke", B)
    S.Color = ac; S.Thickness = 1; S.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    B.MouseButton1Click:Connect(function() callback(B) end)
    return B, L
end

function Widgets.Cycle(parent, order, label, cycleText, callback)
    local C = Instance.new("TextButton")
    C.Size = UDim2.new(1, 0, 0, 24)
    C.BackgroundTransparency = 1
    C.Text = ""
    C.LayoutOrder = order
    C.Parent = parent
    C.ZIndex = 3

    local L = Instance.new("TextLabel", C)
    L.Size = UDim2.new(0.6, 0, 1, 0)
    L.BackgroundTransparency = 1
    L.Text = label
    L.TextColor3 = Theme.TextDim
    L.Font = Enum.Font.Code
    L.TextSize = 12
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.ZIndex = 3

    local cc = Color3.fromRGB(90, 120, 210)
    local VB = Instance.new("TextButton", C)
    VB.Size = UDim2.new(0.4, 0, 0, 18)
    VB.Position = UDim2.new(0.6, 0, 0.5, -9)
    VB.BackgroundTransparency = 1
    VB.Text = cycleText
    VB.TextColor3 = cc
    VB.Font = Enum.Font.Code
    VB.TextSize = 10
    VB.AutoButtonColor = false
    VB.ZIndex = 4
    Instance.new("UICorner", VB).CornerRadius = UDim.new(1, 0)
    local S = Instance.new("UIStroke", VB)
    S.Color = cc; S.Thickness = 1; S.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    VB.MouseButton1Click:Connect(function() callback(VB, L) end)
    return VB, L
end

-- ============================================================
-- WINDOW & TAB
-- ============================================================
local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)
    config = config or {}
    self.Title       = config.Title or "R28 HUB"
    self.Logo        = config.Logo or ""
    self.BgLogo      = config.BgLogo or self.Logo
    self.Size        = config.Size or UDim2.new(0, 365, 0, 265)
    self.Position    = config.Position or UDim2.new(0.5, -182, 0.5, -132)
    self.Tabs        = {}
    self.TabButtons  = {}
    self.TabFrames   = {}
    self.ActiveTab   = nil
    self.IsLocked    = true
    self.Order       = 0
    self.WidgetOrder = 0

    self:_Build()
    return self
end

function Window:_NextOrder()
    self.Order = self.Order + 1
    return self.Order
end

function Window:_Build()
    local name = "R28Lib_Main"
    if CoreGui:FindFirstChild(name) then CoreGui[name]:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self.ScreenGui = sg

    -- Frame utama
    local MF = Instance.new("Frame", sg)
    MF.Size = self.Size
    MF.Position = self.Position
    MF.BackgroundColor3 = Theme.BackgroundColor
    MF.BorderSizePixel = 0
    MF.Active = true
    self.MainFrame = MF
    Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 8)
    local MS = Instance.new("UIStroke", MF)
    MS.Thickness = 1
    MS.Color = Theme.OutlineColor
    MS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MS.LineJoinMode = Enum.LineJoinMode.Round
    Utils.GlowStroke(MS, Theme.AccentColor, Theme.MainColor)

    -- Background logo
    if self.BgLogo ~= "" then
        local BG = Instance.new("ImageLabel", MF)
        BG.Size = UDim2.new(1, -16, 1, -84)
        BG.Position = UDim2.new(0, 8, 0, 76)
        BG.BackgroundTransparency = 1
        BG.Image = self.BgLogo
        BG.ImageColor3 = Color3.fromRGB(55, 110, 170)
        BG.ImageTransparency = 0.55
        BG.ScaleType = Enum.ScaleType.Fit
        BG.ZIndex = 1
        Instance.new("UICorner", BG).CornerRadius = UDim.new(0, 6)
    end

    -- Top bar
    local TB = Instance.new("Frame", MF)
    TB.Size = UDim2.new(1, 0, 0, 32)
    TB.BackgroundColor3 = Theme.MainColor
    TB.BorderSizePixel = 0
    TB.ZIndex = 2
    Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 8)

    local Divider = Instance.new("Frame", TB)
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 1, 0)
    Divider.BackgroundColor3 = Theme.OutlineColor
    Divider.BorderSizePixel = 0
    Divider.ZIndex = 5

    -- Title logo
    if self.Logo ~= "" then
        local TL = Instance.new("ImageLabel", TB)
        TL.Size = UDim2.new(0, 28, 0, 28)
        TL.Position = UDim2.new(0, 8, 0, 2)
        TL.BackgroundTransparency = 1
        TL.Image = self.Logo
        TL.ImageColor3 = Theme.FontColor
        TL.ScaleType = Enum.ScaleType.Fit
        TL.ZIndex = 5
    end

    local TTL = Instance.new("TextLabel", TB)
    TTL.AutomaticSize = Enum.AutomaticSize.X
    TTL.Size = UDim2.new(0, 0, 0, 19)
    TTL.Position = UDim2.new(0, 40, 0, 6)
    TTL.BackgroundTransparency = 1
    TTL.Text = self.Title
    TTL.TextColor3 = Theme.FontColor
    TTL.TextSize = 20
    TTL.Font = Enum.Font.GothamBlack
    TTL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    TTL.TextStrokeTransparency = 0.4
    TTL.ZIndex = 3

    -- Tombol Close
    local CB = Instance.new("ImageButton", TB)
    CB.Size = UDim2.new(0, 22, 0, 22)
    CB.Position = UDim2.new(1, -28, 0.5, -11)
    CB.BackgroundTransparency = 1
    CB.Image = Theme.Icons.Close
    CB.ImageColor3 = Theme.FontColor
    CB.ScaleType = Enum.ScaleType.Fit
    CB.ZIndex = 3
    local CBP = Instance.new("UIPadding", CB)
    CBP.PaddingTop = UDim.new(0, 4); CBP.PaddingBottom = UDim.new(0, 4)
    CBP.PaddingLeft = UDim.new(0, 4); CBP.PaddingRight = UDim.new(0, 4)
    Instance.new("UICorner", CB).CornerRadius = UDim.new(0, 5)
    local CBS = Instance.new("UIStroke", CB)
    CBS.Color = Color3.fromRGB(100, 100, 110); CBS.Thickness = 1
    CBS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Tombol Minimize
    local MIB = Instance.new("ImageButton", TB)
    MIB.Size = UDim2.new(0, 22, 0, 22)
    MIB.Position = UDim2.new(1, -54, 0.5, -11)
    MIB.BackgroundTransparency = 1
    MIB.Image = Theme.Icons.Minus
    MIB.ImageColor3 = Theme.FontColor
    MIB.ScaleType = Enum.ScaleType.Fit
    MIB.ZIndex = 3
    local MIBP = Instance.new("UIPadding", MIB)
    MIBP.PaddingTop = UDim.new(0, 4); MIBP.PaddingBottom = UDim.new(0, 4)
    MIBP.PaddingLeft = UDim.new(0, 4); MIBP.PaddingRight = UDim.new(0, 4)
    Instance.new("UICorner", MIB).CornerRadius = UDim.new(0, 5)
    local MIBS = Instance.new("UIStroke", MIB)
    MIBS.Color = Color3.fromRGB(100, 100, 110); MIBS.Thickness = 1
    MIBS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Tombol Lock
    local LB = Instance.new("ImageButton", TB)
    LB.Size = UDim2.new(0, 22, 0, 22)
    LB.Position = UDim2.new(1, -80, 0.5, -11)
    LB.BackgroundTransparency = 1
    LB.Image = Theme.Icons.Lock
    LB.ImageColor3 = Theme.AccentColor
    LB.ScaleType = Enum.ScaleType.Fit
    LB.ZIndex = 3
    local LBP = Instance.new("UIPadding", LB)
    LBP.PaddingTop = UDim.new(0, 4); LBP.PaddingBottom = UDim.new(0, 4)
    LBP.PaddingLeft = UDim.new(0, 4); LBP.PaddingRight = UDim.new(0, 4)
    Instance.new("UICorner", LB).CornerRadius = UDim.new(0, 5)
    local LBS = Instance.new("UIStroke", LB)
    LBS.Color = Theme.AccentColor; LBS.Thickness = 1
    LBS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Tab bar
    local TabBar = Instance.new("Frame", MF)
    TabBar.Size = UDim2.new(1, -16, 0, 34)
    TabBar.Position = UDim2.new(0, 8, 0, 36)
    TabBar.BackgroundColor3 = Theme.BackgroundColor
    TabBar.BorderSizePixel = 0
    TabBar.ZIndex = 2
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 6)
    local TL = Instance.new("UIListLayout", TabBar)
    TL.FillDirection = Enum.FillDirection.Horizontal
    TL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TL.VerticalAlignment = Enum.VerticalAlignment.Center
    TL.Padding = UDim.new(0, 3)
    local TP = Instance.new("UIPadding", TabBar)
    TP.PaddingLeft = UDim.new(0, 3); TP.PaddingRight = UDim.new(0, 3)
    TP.PaddingTop = UDim.new(0, 4); TP.PaddingBottom = UDim.new(0, 4)
    self.TabBar = TabBar

    -- Divider bawah tab bar
    local TabDiv = Instance.new("Frame", MF)
    TabDiv.Size = UDim2.new(1, -16, 0, 1)
    TabDiv.Position = UDim2.new(0, 8, 0, 72)
    TabDiv.BackgroundColor3 = Theme.OutlineColor
    TabDiv.BorderSizePixel = 0
    TabDiv.ZIndex = 5

    -- Content container
    local CC = Instance.new("Frame", MF)
    CC.Size = UDim2.new(1, -16, 1, -84)
    CC.Position = UDim2.new(0, 8, 0, 76)
    CC.BackgroundTransparency = 1
    CC.ZIndex = 2
    self.ContentContainer = CC

    -- Confirmation exit
    local CP = Instance.new("Frame", MF)
    CP.Size = UDim2.new(1, -40, 0, 110)
    CP.Position = UDim2.new(0, 20, 0.5, -55)
    CP.BackgroundColor3 = Theme.MainColor
    CP.BorderSizePixel = 0
    CP.Visible = false
    CP.ZIndex = 50
    Instance.new("UICorner", CP).CornerRadius = UDim.new(0, 8)
    local PS = Instance.new("UIStroke", CP)
    PS.Color = Color3.fromRGB(139, 0, 0); PS.Thickness = 1
    PS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    PS.LineJoinMode = Enum.LineJoinMode.Round
    Utils.GlowStroke(PS, Color3.fromRGB(255, 50, 50), Theme.MainColor)
    self.ConfirmPanel = CP

    local PT = Instance.new("TextLabel", CP)
    PT.Size = UDim2.new(1, -20, 0, 40)
    PT.Position = UDim2.new(0, 10, 0, 10)
    PT.BackgroundTransparency = 1
    PT.Text = "Are you sure you want to exit the script?"
    PT.TextColor3 = Theme.FontColor
    PT.TextSize = 12
    PT.Font = Enum.Font.Code
    PT.TextWrapped = true
    PT.ZIndex = 51

    local YB = Instance.new("TextButton", CP)
    YB.Size = UDim2.new(0.5, -15, 0, 30)
    YB.Position = UDim2.new(0, 10, 0, 70)
    YB.BackgroundColor3 = Theme.DangerColor
    YB.Text = "Yes"
    YB.TextColor3 = Theme.FontColor
    YB.Font = Enum.Font.Code
    YB.TextSize = 12
    YB.ZIndex = 51
    Instance.new("UICorner", YB).CornerRadius = UDim.new(0, 5)

    local NB = Instance.new("TextButton", CP)
    NB.Size = UDim2.new(0.5, -15, 0, 30)
    NB.Position = UDim2.new(0.5, 5, 0, 70)
    NB.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    NB.Text = "Close"
    NB.TextColor3 = Theme.FontColor
    NB.Font = Enum.Font.Code
    NB.TextSize = 12
    NB.ZIndex = 51
    Instance.new("UICorner", NB).CornerRadius = UDim.new(0, 5)

    CB.MouseButton1Click:Connect(function()
        if not CP.Visible then CP.Visible = true end
    end)
    NB.MouseButton1Click:Connect(function() CP.Visible = false end)
    YB.MouseButton1Click:Connect(function()
        if self.OnClose then pcall(self.OnClose) end
        sg:Destroy()
    end)

    LB.MouseButton1Click:Connect(function()
        self.IsLocked = not self.IsLocked
        local st = LB:FindFirstChildOfClass("UIStroke")
        if self.IsLocked then
            LB.Image = Theme.Icons.Lock
            LB.ImageColor3 = Theme.AccentColor
            if st then st.Color = Theme.AccentColor end
        else
            LB.Image = Theme.Icons.Unlock
            LB.ImageColor3 = Color3.fromRGB(120, 120, 130)
            if st then st.Color = Color3.fromRGB(100, 100, 110) end
        end
    end)

    Utils.MakeDraggable(MF, MF, function() return self.IsLocked end,
        function() return CP.Visible end)
    Utils.MakeDraggable(MF, TB, function() return self.IsLocked end,
        function() return CP.Visible end)
end

function Window:Tab(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 1, -4)
    b.LayoutOrder = self:_NextOrder()
    b.BackgroundColor3 = Theme.BackgroundColor
    b.BackgroundTransparency = 1
    b.Text = name
    b.TextColor3 = Theme.TextMuted
    b.Font = Enum.Font.Code
    b.TextSize = 10
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.ZIndex = 3
    local st = Instance.new("UIStroke", b)
    st.Color = Theme.AccentColor; st.Thickness = 1
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Transparency = 1
    b.Parent = self.TabBar

    -- Tab frame (ScrollingFrame)
    local f = Instance.new("ScrollingFrame")
    f.Name = name .. "Tab"
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 4
    f.ScrollBarImageColor3 = Theme.AccentColor
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.ScrollingDirection = Enum.ScrollingDirection.Y
    f.Visible = false
    f.Parent = self.ContentContainer
    f.ZIndex = 3
    local lay = Instance.new("UIListLayout", f)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", f)
    pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)

    self.TabButtons[name] = b
    self.TabFrames[name] = f

    local self_ = self
    b.MouseButton1Click:Connect(function()
        self_:SwitchTab(name)
    end)
    return self:_MakeTabProxy(f)
end

function Window:SwitchTab(name)
    if self.ActiveTab == name then return end
    for nm, f in pairs(self.TabFrames) do f.Visible = (nm == name) end
    for nm, b in pairs(self.TabButtons) do
        local st = b:FindFirstChildOfClass("UIStroke")
        if nm == name then
            b.TextColor3 = Theme.AccentColor
            if st then st.Transparency = 0 end
        else
            b.TextColor3 = Theme.TextMuted
            if st then st.Transparency = 1 end
        end
    end
    self.ActiveTab = name
end

function Window:_MakeTabProxy(frame)
    local proxy = {}
    proxy.__frame = frame
    proxy.__order = 0

    function proxy:_O()
        self.__order = self.__order + 1
        return self.__order
    end

    function proxy:Section(text)
        Widgets.Section(self.__frame, text, self:_O())
    end
    function proxy:Divider()
        Widgets.Divider(self.__frame, self:_O())
    end
    function proxy:Toggle(label, default, cb)
        Widgets.Toggle(self.__frame, self:_O(), label, default, cb)
    end
    function proxy:Slider(label, mn, mx, df, isF, cb)
        Widgets.Slider(self.__frame, self:_O(), label, mn, mx, df, isF, cb)
    end
    function proxy:Button(label, btnText, cb, color)
        Widgets.Button(self.__frame, self:_O(), label, btnText, cb, color)
    end
    function proxy:Cycle(label, cycleText, cb)
        Widgets.Cycle(self.__frame, self:_O(), label, cycleText, cb)
    end
    return proxy
end

function Window:Notify(title, text, duration)
    Notify.Show(title, text, duration, self.Logo)
end

function Window:SetOnClose(fn)
    self.OnClose = fn
end

-- ============================================================
-- EXPORT
-- ============================================================
local R28Lib = {}
R28Lib.Theme = Theme
R28Lib.Utils = Utils
R28Lib.Widgets = Widgets
R28Lib.Notify = Notify

function R28Lib.new(config)
    return Window.new(config)
end

return R28Lib
