--[[
    DARKHUB V2 — ULTIMATE PRODUCTION EDITION
    Final round of fixes:
    - LoadConfig preserves table identity
    - ThemeObjects cleaned of dead references
    - Notification limit (auto‑purge oldest)
    - All callbacks run in task.spawn (non‑blocking)
    - Keybind state reset on destroy
    - Tween references self‑cleaned
    - Central IsAlive() validation
    - Blur reused globally, no collisions
]]

local cloneref = cloneref or function(v) return v end
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))

local HiddenUI = gethui and gethui() or CoreGui
local ProtectGui = protectgui or function() end

local Library = {
    Flags = {},
    FlagNamespaces = {},
    ThemeObjects = {
        Accent = {},
        Text = {},
        Background = {},
        Outline = {}
    },
    Tabs = {},
    Connections = {},
    OpenDropdown = nil,
    OpenColorpicker = nil,
    Keybinds = {},
    Elements = {},
    ToggleSwitches = {},
    MultiOptions = {},
    DetachedFrames = {},
    ActiveTweens = {},
    CreatedBlur = false,
    ZIndex = 100,
    Destroyed = false,
    WaitingKeybind = nil,
    MaxNotifications = 8,
}

Library.Theme = {
    Accent = Color3.fromRGB(0,255,120),
    Background = Color3.fromRGB(13,13,18),
    Surface = Color3.fromRGB(20,20,26),
    Surface2 = Color3.fromRGB(30,30,38),
    Outline = Color3.fromRGB(40,40,50),
    Text = Color3.fromRGB(255,255,255),
    DimText = Color3.fromRGB(170,170,170)
}

-- Helpers
local function Create(class, props)
    local obj = Instance.new(class)
    for i,v in pairs(props or {}) do obj[i] = v end
    return obj
end

local function Corner(obj, radius)
    return Create("UICorner", {
        Parent = obj,
        CornerRadius = UDim.new(0, radius or 6)
    })
end

local function Stroke(obj)
    local s = Create("UIStroke", {
        Parent = obj,
        Color = Library.Theme.Outline,
        Thickness = 1
    })
    table.insert(Library.ThemeObjects.Outline, { Object = s, Property = "Color" })
    return s
end

local function ThemeObject(obj, property, category)
    category = category or "Accent"
    table.insert(Library.ThemeObjects[category], { Object = obj, Property = property })
end

local function ConnectAndStore(event, func)
    local conn = event:Connect(func)
    table.insert(Library.Connections, conn)
    return conn
end

-- Instance validation
local function IsAlive(instance)
    return typeof(instance) == "Instance" and instance.Parent ~= nil
end

-- Cleanup dead theme references
local function CleanupThemeObjects(categoryTable)
    for i = #categoryTable, 1, -1 do
        local entry = categoryTable[i]
        if not entry.Object or not IsAlive(entry.Object) then
            table.remove(categoryTable, i)
        end
    end
end

local function safeCallback(f, ...)
    local ok, err = pcall(f, ...)
    if not ok then warn("DarkHub V2 callback error:", err) end
end

local function applyZIndex(parent, baseZ)
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("GuiObject") then
            child.ZIndex = baseZ + 1
        end
    end
    parent.ZIndex = baseZ
end

-- Serialization with cycle prevention
local function serialize(value, depth, visited)
    depth = depth or 0
    visited = visited or {}
    if depth > 100 then return nil end
    local t = typeof(value)
    if t == "Color3" then
        return { __type = "Color3", r = value.R, g = value.G, b = value.B }
    elseif t == "EnumItem" then
        return { __type = "EnumItem", enum = tostring(value) }
    elseif t == "table" then
        if visited[value] then return nil end
        visited[value] = true
        local new = {}
        for k,v in pairs(value) do
            local sk = serialize(k, depth + 1, visited)
            local sv = serialize(v, depth + 1, visited)
            if sk ~= nil and sv ~= nil then
                new[sk] = sv
            end
        end
        return new
    end
    return value
end

local function deserialize(value, visited)
    visited = visited or {}
    if type(value) == "table" then
        if visited[value] then return value end
        visited[value] = true
        if value.__type == "Color3" then
            return Color3.new(value.r, value.g, value.b)
        elseif value.__type == "EnumItem" then
            local enumName = value.enum:match("Enum%.KeyCode%.(.+)")
            return enumName and Enum.KeyCode[enumName]
        else
            local new = {}
            for k,v in pairs(value) do
                local dk = deserialize(k, visited)
                local dv = deserialize(v, visited)
                new[dk] = dv
            end
            return new
        end
    end
    return value
end

-- Tween helper with self-cleaning
local function createTween(obj, info, props)
    local tween = TweenService:Create(obj, info, props)
    table.insert(Library.ActiveTweens, tween)
    local completedConnection
    completedConnection = tween.Completed:Connect(function()
        if completedConnection then
            completedConnection:Disconnect()
            completedConnection = nil
        end
        local idx = table.find(Library.ActiveTweens, tween)
        if idx then table.remove(Library.ActiveTweens, idx) end
    end)
    tween:Play()
    return tween
end

-- Flag registration with namespace protection
function Library:RegisterFlag(name, value)
    if self.Flags[name] ~= nil then
        warn("DarkHub V2: Flag '" .. name .. "' is already in use. Use a unique name.")
        return false
    end
    self.Flags[name] = value
    self.FlagNamespaces[name] = true
    return true
end

function Library:SetTheme(accentColor)
    CleanupThemeObjects(self.ThemeObjects.Accent)
    CleanupThemeObjects(self.ThemeObjects.Text)
    CleanupThemeObjects(self.ThemeObjects.Background)
    CleanupThemeObjects(self.ThemeObjects.Outline)

    self.Theme.Accent = accentColor
    for _,v in ipairs(self.ThemeObjects.Accent) do
        if IsAlive(v.Object) then
            pcall(function() v.Object[v.Property] = accentColor end)
        end
    end
    for _, switchFrame in ipairs(self.ToggleSwitches) do
        if IsAlive(switchFrame) and switchFrame.State then
            switchFrame.BackgroundColor3 = accentColor
        end
    end
    for _, optButton in ipairs(self.MultiOptions) do
        if IsAlive(optButton) and optButton.Selected then
            optButton.BackgroundColor3 = accentColor
        end
    end
    for _, tab in ipairs(self.Tabs) do
        if IsAlive(tab.Button) then
            tab.Button.BackgroundColor3 = tab.Button.IsSelected and accentColor or self.Theme.Surface
        end
    end
end

-- GUI Setup
local ScreenGui = Create("ScreenGui", {
    Name = "DarkHubV2",
    Parent = HiddenUI,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global
})
ProtectGui(ScreenGui)

-- Global blur reuse
local Blur = Lighting:FindFirstChild("DarkHub_GlobalBlur")
if not Blur then
    Blur = Create("BlurEffect", {
        Name = "DarkHub_GlobalBlur",
        Parent = Lighting,
        Size = 18
    })
    Library.CreatedBlur = true
end

-- Main window
local Main = Create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0,760,0,520),
    Position = UDim2.new(0.5,-380,0.5,-260),
    BackgroundColor3 = Library.Theme.Background,
    BorderSizePixel = 0
})
Corner(Main, 8)
Stroke(Main)
ThemeObject(Main, "BackgroundColor3", "Background")

-- Topbar
local Topbar = Create("Frame", { Parent = Main, Size = UDim2.new(1,0,0,42), BackgroundTransparency = 1 })
local Title = Create("TextLabel", {
    Parent = Topbar, Position = UDim2.new(0,14,0,0), Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "DARKHUB V2",
    TextSize = 14, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
})
ThemeObject(Title, "TextColor3", "Text")

local Minimize = Create("TextButton", {
    Parent = Topbar, Position = UDim2.new(1,-62,0,8), Size = UDim2.new(0,24,0,24),
    Text = "—", Font = Enum.Font.GothamBold, TextSize = 15, BackgroundTransparency = 1,
    TextColor3 = Library.Theme.Text
})
ThemeObject(Minimize, "TextColor3", "Text")

local Close = Create("TextButton", {
    Parent = Topbar, Position = UDim2.new(1,-32,0,8), Size = UDim2.new(0,24,0,24),
    Text = "✕", Font = Enum.Font.GothamBold, TextSize = 13, BackgroundTransparency = 1,
    TextColor3 = Library.Theme.Text
})
ThemeObject(Close, "TextColor3", "Text")

-- Sidebar
local Sidebar = Create("Frame", {
    Parent = Main, Position = UDim2.new(0,0,0,42), Size = UDim2.new(0,170,1,-42),
    BackgroundTransparency = 1
})
Create("UIPadding", { Parent = Sidebar, PaddingTop = UDim.new(0,12), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12) })
local SidebarLayout = Create("UIListLayout", { Parent = Sidebar, Padding = UDim.new(0,8) })

-- Content area
local Content = Create("Frame", {
    Parent = Main, Position = UDim2.new(0,170,0,42), Size = UDim2.new(1,-170,1,-42),
    BackgroundTransparency = 1
})

-- Dock
local Dock = Create("TextButton", {
    Parent = ScreenGui, Visible = false, Position = UDim2.new(0.5,-90,0,10),
    Size = UDim2.new(0,180,0,36), BackgroundColor3 = Library.Theme.Surface,
    BorderSizePixel = 0, Text = "DARKHUB V2", Font = Enum.Font.GothamBold,
    TextSize = 13, TextColor3 = Library.Theme.Text
})
Corner(Dock, 6)
Stroke(Dock)
ThemeObject(Dock, "BackgroundColor3", "Background")
ThemeObject(Dock, "TextColor3", "Text")

-- Watermark
local Watermark = Create("Frame", {
    Parent = ScreenGui, Position = UDim2.new(0,10,0,10), Size = UDim2.new(0,280,0,22),
    BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0
})
Corner(Watermark, 4)
Stroke(Watermark)
ThemeObject(Watermark, "BackgroundColor3", "Background")

local WatermarkText = Create("TextLabel", {
    Parent = Watermark, Size = UDim2.new(1,-8,1,0), Position = UDim2.new(0,4,0,0),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "DarkHub V2 | " .. Players.LocalPlayer.Name .. " | ... | ..."
})
ThemeObject(WatermarkText, "TextColor3", "Text")

local FPS = 0
local frames = 0
local lastFpsTime = tick()
ConnectAndStore(RunService.RenderStepped, function()
    frames = frames + 1
    if tick() - lastFpsTime >= 1 then
        FPS = frames
        frames = 0
        lastFpsTime = tick()
    end
end)

task.spawn(function()
    while not Library.Destroyed do
        local ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
        WatermarkText.Text = "DarkHub V2 | " .. Players.LocalPlayer.Name .. " | " .. FPS .. " FPS | " .. ping .. " ms"
        task.wait(0.3)
    end
end)

-- Notifications with limit
local NotificationHolder = Create("Frame", {
    Parent = ScreenGui, AnchorPoint = Vector2.new(1,1),
    Position = UDim2.new(1,-20,1,-20), Size = UDim2.new(0,320,1,0),
    BackgroundTransparency = 1
})
local NotificationLayout = Create("UIListLayout", {
    Parent = NotificationHolder, Padding = UDim.new(0,8),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom
})

function Library:Notify(title, text)
    -- Purge excess notifications
    local existing = {}
    for _, child in ipairs(NotificationHolder:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(existing, child)
        end
    end
    if #existing >= self.MaxNotifications then
        existing[1]:Destroy()
    end

    local Frame = Create("Frame", {
        Parent = NotificationHolder, Size = UDim2.new(0,300,0,70),
        BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0
    })
    Corner(Frame, 6)
    Stroke(Frame)
    ThemeObject(Frame, "BackgroundColor3", "Background")

    local Accent = Create("Frame", {
        Parent = Frame, Size = UDim2.new(0,4,1,0),
        BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0
    })
    ThemeObject(Accent, "BackgroundColor3", "Accent")

    local TitleLabel = Create("TextLabel", {
        Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,8),
        Size = UDim2.new(1,-20,0,18), Font = Enum.Font.GothamBold,
        Text = title, TextSize = 13, TextColor3 = self.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
    })
    ThemeObject(TitleLabel, "TextColor3", "Text")

    local DescLabel = Create("TextLabel", {
        Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,28),
        Size = UDim2.new(1,-20,1,-32), Font = Enum.Font.Gotham,
        Text = text, TextWrapped = true, TextSize = 12, TextColor3 = self.Theme.DimText,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top
    })
    ThemeObject(DescLabel, "TextColor3", "Text")

    task.delay(4, function()
        createTween(Frame, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
        createTween(TitleLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
        createTween(DescLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
        for _, child in ipairs(Frame:GetChildren()) do
            if child:IsA("UIStroke") then
                createTween(child, TweenInfo.new(0.2), { Transparency = 1 })
            end
        end
        task.wait(0.2)
        Frame:Destroy()
    end)
end

-- Dragging (topbar)
local dragging, dragStart, startPos
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
ConnectAndStore(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
ConnectAndStore(UIS.InputChanged, function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Resize handle
local ResizeHandle = Create("TextButton", {
    Parent = Main, Position = UDim2.new(1,-16,1,-16), Size = UDim2.new(0,16,0,16),
    BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0,
    Text = "", AutoButtonColor = false
})
Corner(ResizeHandle, 0)
ThemeObject(ResizeHandle, "BackgroundColor3", "Accent")

local resizeDragging = false
local resizeStart, startSize
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizeDragging = true
        resizeStart = input.Position
        startSize = Main.AbsoluteSize
    end
end)
ConnectAndStore(UIS.InputChanged, function(input)
    if resizeDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - resizeStart
        Main.Size = UDim2.new(0, math.max(400, startSize.X + delta.X), 0, math.max(300, startSize.Y + delta.Y))
        if Library.OpenDropdown and Library.OpenDropdown.List and Library.OpenDropdown.Button then
            Library.OpenDropdown.List.Position = UDim2.new(0, Library.OpenDropdown.Button.AbsolutePosition.X, 0, Library.OpenDropdown.Button.AbsolutePosition.Y + Library.OpenDropdown.Button.AbsoluteSize.Y + 2)
        end
        if Library.OpenColorpicker and Library.OpenColorpicker.Picker and Library.OpenColorpicker.Preview then
            local pos = Library.OpenColorpicker.Preview.AbsolutePosition
            Library.OpenColorpicker.Picker.Position = UDim2.new(0, pos.X - 140, 0, pos.Y + 26)
        end
    end
end)
ConnectAndStore(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then resizeDragging = false end
end)

-- Minimize / Dock
Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Dock.Visible = true
    Blur.Size = 0
end)
Dock.MouseButton1Click:Connect(function()
    Main.Visible = true
    Dock.Visible = false
    Blur.Size = 18
end)

-- Centralized input handling
Library.ActiveSlider = nil
Library.ActiveColorpicker = nil

ConnectAndStore(UIS.InputBegan, function(input, gp)
    if gp then return end
    for _, bind in ipairs(Library.Keybinds) do
        if input.KeyCode == bind.Key then
            task.spawn(function()
                safeCallback(bind.Callback, bind.Key)
            end)
        end
    end
end)

ConnectAndStore(UIS.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if Library.ActiveSlider then
            local slider = Library.ActiveSlider
            local Percent = math.clamp((input.Position.X - slider.Bar.AbsolutePosition.X) / slider.Bar.AbsoluteSize.X, 0, 1)
            slider.Fill.Size = UDim2.new(Percent, 0, 1, 0)
            local raw = slider.Min + ((slider.Max - slider.Min) * Percent)
            local factor = 10 ^ slider.Decimals
            slider.Value = math.floor(raw * factor + 0.5) / factor
            slider.ValueLabel.Text = tostring(slider.Value)
            Library.Flags[slider.Flag] = slider.Value
            task.spawn(function() safeCallback(slider.Callback, slider.Value) end)
        elseif Library.ActiveColorpicker then
            local cp = Library.ActiveColorpicker
            if cp.DraggingPalette then
                local x = math.clamp(input.Position.X - cp.Palette.AbsolutePosition.X, 0, cp.Palette.AbsoluteSize.X)
                local y = math.clamp(input.Position.Y - cp.Palette.AbsolutePosition.Y, 0, cp.Palette.AbsoluteSize.Y)
                cp.Sat = x / cp.Palette.AbsoluteSize.X
                cp.Val = 1 - (y / cp.Palette.AbsoluteSize.Y)
                cp.Selector.Position = UDim2.new(cp.Sat, 0, 1 - cp.Val, 0)
                cp.UpdateColor()
            elseif cp.DraggingHue then
                local y = math.clamp(input.Position.Y - cp.HueBar.AbsolutePosition.Y, 0, cp.HueBar.AbsoluteSize.Y)
                cp.Hue = math.clamp(y / cp.HueBar.AbsoluteSize.Y, 0, 0.999)
                cp.HueSelector.Position = UDim2.new(0, 0, cp.Hue, 0)
                cp.UpdateColor()
            end
        end
    end
end)

ConnectAndStore(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if Library.ActiveSlider then Library.ActiveSlider = nil end
        if Library.ActiveColorpicker then
            Library.ActiveColorpicker.DraggingPalette = false
            Library.ActiveColorpicker.DraggingHue = false
            Library.ActiveColorpicker = nil
        end
    end
end)

-- Global click outside handler (null‑safe)
ConnectAndStore(UIS.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UIS:GetMouseLocation()
        if Library.OpenDropdown and IsAlive(Library.OpenDropdown.List) then
            local list = Library.OpenDropdown.List
            local button = Library.OpenDropdown.Button
            local function inside(f) return IsAlive(f) and mousePos.X >= f.AbsolutePosition.X and mousePos.X <= f.AbsolutePosition.X + f.AbsoluteSize.X and mousePos.Y >= f.AbsolutePosition.Y and mousePos.Y <= f.AbsolutePosition.Y + f.AbsoluteSize.Y end
            if not inside(list) and not inside(button) then
                list.Visible = false
                Library.OpenDropdown = nil
            end
        end
        if Library.OpenColorpicker and IsAlive(Library.OpenColorpicker.Picker) then
            local picker = Library.OpenColorpicker.Picker
            local preview = Library.OpenColorpicker.Preview
            local function inside(f) return IsAlive(f) and mousePos.X >= f.AbsolutePosition.X and mousePos.X <= f.AbsolutePosition.X + f.AbsoluteSize.X and mousePos.Y >= f.AbsolutePosition.Y and mousePos.Y <= f.AbsolutePosition.Y + f.AbsoluteSize.Y end
            if not inside(picker) and not inside(preview) then
                picker.Visible = false
                Library.OpenColorpicker = nil
            end
        end
    end
end)

-- ==============================================
-- TAB SYSTEM
-- ==============================================
function Library:Tab(name)
    local TabButton = Create("TextButton", {
        Parent = Sidebar, Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0,
        Text = name, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self.Theme.Text
    })
    Corner(TabButton, 6)
    ThemeObject(TabButton, "TextColor3", "Text")
    TabButton.IsSelected = false

    local Page = Create("Frame", { Parent = Content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false })
    local Left = Create("ScrollingFrame", { Parent = Page, Size = UDim2.new(0.5,-8,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() })
    local Right = Create("ScrollingFrame", { Parent = Page, Position = UDim2.new(0.5,8,0,0), Size = UDim2.new(0.5,-8,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() })
    Create("UIListLayout", {Parent = Left, Padding = UDim.new(0,12)})
    Create("UIListLayout", {Parent = Right, Padding = UDim.new(0,12)})

    local function Select()
        for _,v in pairs(Library.Tabs) do
            v.Page.Visible = false
            v.Button.IsSelected = false
            v.Button.BackgroundColor3 = Library.Theme.Surface
        end
        Page.Visible = true
        TabButton.IsSelected = true
        TabButton.BackgroundColor3 = Library.Theme.Accent
    end
    TabButton.MouseButton1Click:Connect(Select)
    if #Library.Tabs == 0 then Select() end
    table.insert(Library.Tabs, {Button = TabButton, Page = Page})

    local TabAPI = {}
    function TabAPI:Groupbox(title, side)
        local Parent = side == "Right" and Right or Left
        local Group = Create("Frame", {
            Parent = Parent, Size = UDim2.new(1,0,0,40), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0
        })
        Corner(Group, 6)
        Stroke(Group)
        ThemeObject(Group, "BackgroundColor3", "Background")

        local TitleLabel = Create("TextLabel", {
            Parent = Group, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(1,0,0,34),
            Font = Enum.Font.GothamBold, Text = title, TextSize = 13, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
        })
        ThemeObject(TitleLabel, "TextColor3", "Text")

        local Holder = Create("Frame", {
            Parent = Group, Position = UDim2.new(0,10,0,36), Size = UDim2.new(1,-20,0,0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1
        })
        Create("UIListLayout", {Parent = Holder, Padding = UDim.new(0,8)})
        Create("UIPadding", {Parent = Holder, PaddingBottom = UDim.new(0,10)})

        local GroupAPI = {}

        function GroupAPI:Label(text)
            local lbl = Create("TextLabel", {
                Parent = Holder, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1,
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.DimText, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(lbl, "TextColor3", "Text")
        end

        function GroupAPI:Separator()
            local Line = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,1),
                BackgroundColor3 = Library.Theme.Outline, BorderSizePixel = 0
            })
            ThemeObject(Line, "BackgroundColor3", "Outline")
            return Line
        end

        function GroupAPI:Button(text, callback)
            local Button = Create("TextButton", {
                Parent = Holder, Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0,
                Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text
            })
            Corner(Button, 5)
            ThemeObject(Button, "BackgroundColor3", "Background")
            ThemeObject(Button, "TextColor3", "Text")
            Button.MouseButton1Click:Connect(function()
                task.spawn(function() safeCallback(callback) end)
            end)
        end

        -- Toggle
        function GroupAPI:Toggle(text, default, callback)
            if not Library:RegisterFlag(text, default) then return end
            local State = default
            local Frame = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0
            })
            Corner(Frame, 5)
            ThemeObject(Frame, "BackgroundColor3", "Background")

            local Label = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(1,0,1,0),
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(Label, "TextColor3", "Text")

            local Switch = Create("Frame", {
                Parent = Frame, Position = UDim2.new(1,-52,0.5,-10), Size = UDim2.new(0,40,0,20),
                BackgroundColor3 = State and Library.Theme.Accent or Color3.fromRGB(55,55,55), BorderSizePixel = 0
            })
            Corner(Switch, 20)
            local Knob = Create("Frame", {
                Parent = Switch, Position = State and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
                Size = UDim2.new(0,16,0,16), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0
            })
            Corner(Knob, 20)
            Switch.State = State
            table.insert(Library.ToggleSwitches, Switch)

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    State = not State
                    Library.Flags[text] = State
                    Switch.State = State
                    Switch.BackgroundColor3 = State and Library.Theme.Accent or Color3.fromRGB(55,55,55)
                    createTween(Knob, TweenInfo.new(0.15), {
                        Position = State and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
                    })
                    task.spawn(function() safeCallback(callback, State) end)
                end
            end)

            local control = {
                Set = function(_, v, silent)
                    State = v
                    Library.Flags[text] = v
                    Switch.State = v
                    Switch.BackgroundColor3 = State and Library.Theme.Accent or Color3.fromRGB(55,55,55)
                    Knob.Position = State and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
                    if not silent then
                        task.spawn(function() safeCallback(callback, State) end)
                    end
                end,
                Get = function() return State end,
                Destroy = function() Switch.State = false end
            }
            Library.Elements[text] = control
            return control
        end

        -- Slider
        function GroupAPI:Slider(text, min, max, default, decimals, callback)
            if type(decimals) == "function" then callback = decimals; decimals = 0 end
            decimals = decimals or 0
            if not Library:RegisterFlag(text, default) then return end
            local Value = default
            local Frame = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,54),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0
            })
            Corner(Frame, 5)
            ThemeObject(Frame, "BackgroundColor3", "Background")

            local Label = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(1,-60,0,24),
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(Label, "TextColor3", "Text")

            local ValueLabel = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(1,-50,0,0), Size = UDim2.new(0,40,0,24),
                Font = Enum.Font.GothamBold, Text = tostring(Value), TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Right
            })
            ThemeObject(ValueLabel, "TextColor3", "Text")

            local Bar = Create("Frame", {
                Parent = Frame, Position = UDim2.new(0,12,0,34), Size = UDim2.new(1,-24,0,8),
                BackgroundColor3 = Color3.fromRGB(45,45,50), BorderSizePixel = 0
            })
            Corner(Bar, 10)

            local Fill = Create("Frame", {
                Parent = Bar, Size = UDim2.new((Value - min)/(max - min),0,1,0),
                BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0
            })
            ThemeObject(Fill, "BackgroundColor3", "Accent")
            Corner(Fill, 10)

            local sliderData = {
                Bar = Bar, Fill = Fill, ValueLabel = ValueLabel,
                Min = min, Max = max, Decimals = decimals, Value = Value, Flag = text, Callback = callback
            }

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Library.ActiveSlider = sliderData
                    local Percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                    Fill.Size = UDim2.new(Percent, 0, 1, 0)
                    local raw = min + ((max - min) * Percent)
                    local factor = 10 ^ decimals
                    Value = math.floor(raw * factor + 0.5) / factor
                    ValueLabel.Text = tostring(Value)
                    Library.Flags[text] = Value
                    task.spawn(function() safeCallback(callback, Value) end)
                end
            end)

            task.spawn(function() safeCallback(callback, Value) end)
            local control = {
                Set = function(_, v, silent)
                    v = math.clamp(v, min, max)
                    Value = v
                    Library.Flags[text] = v
                    local Percent = (Value - min)/(max - min)
                    Fill.Size = UDim2.new(Percent,0,1,0)
                    ValueLabel.Text = tostring(Value)
                    if not silent then
                        task.spawn(function() safeCallback(callback, Value) end)
                    end
                end,
                Get = function() return Value end,
                Destroy = function() end
            }
            Library.Elements[text] = control
            return control
        end

        -- Dropdown
        function GroupAPI:Dropdown(text, options, default, callback)
            if not Library:RegisterFlag(text, default) then return end
            local Value = default or options[1]
            local Open = false
            local Frame = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,40),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0, ClipsDescendants = false
            })
            Corner(Frame, 5)
            ThemeObject(Frame, "BackgroundColor3", "Background")

            local Label = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(0.4,0,1,0),
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(Label, "TextColor3", "Text")

            local Button = Create("TextButton", {
                Parent = Frame, Position = UDim2.new(0.45,0,0.5,-12), Size = UDim2.new(0.5,-6,0,24),
                BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0,
                Text = tostring(Value), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text
            })
            Corner(Button, 4)
            ThemeObject(Button, "BackgroundColor3", "Background")
            ThemeObject(Button, "TextColor3", "Text")

            local List = Create("Frame", {
                Parent = ScreenGui, Visible = false, Size = UDim2.new(0, 200, 0, (#options * 26) + 4),
                BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0, ZIndex = Library.ZIndex + 1
            })
            Corner(List, 5)
            Stroke(List)
            table.insert(Library.DetachedFrames, List)
            applyZIndex(List, Library.ZIndex + 1)

            Create("UIListLayout", { Parent = List, Padding = UDim.new(0,2) })
            Create("UIPadding", { Parent = List, PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,2) })

            local function CloseDropdown()
                Open = false
                List.Visible = false
                if Library.OpenDropdown and Library.OpenDropdown.List == List then
                    Library.OpenDropdown = nil
                end
            end

            local function OpenDropdown()
                if Library.OpenDropdown and Library.OpenDropdown.List then
                    Library.OpenDropdown.List.Visible = false
                end
                local Pos = Button.AbsolutePosition
                List.Position = UDim2.new(0, Pos.X, 0, Pos.Y + Button.AbsoluteSize.Y + 2)
                List.Size = UDim2.new(0, math.max(Button.AbsoluteSize.X, 100), 0, (#options * 26) + 4)
                List.Visible = true
                Open = true
                Library.OpenDropdown = { List = List, Button = Button }
            end

            for _,option in ipairs(options) do
                local Opt = Create("TextButton", {
                    Parent = List, Size = UDim2.new(1,-4,0,24),
                    BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0,
                    Text = option, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text,
                    ZIndex = Library.ZIndex + 2
                })
                Corner(Opt, 4)
                ThemeObject(Opt, "BackgroundColor3", "Background")
                ThemeObject(Opt, "TextColor3", "Text")
                Opt.MouseButton1Click:Connect(function()
                    Value = option
                    Button.Text = option
                    Library.Flags[text] = Value
                    CloseDropdown()
                    task.spawn(function() safeCallback(callback, Value) end)
                end)
            end

            Button.MouseButton1Click:Connect(function()
                if Open then CloseDropdown() else OpenDropdown() end
            end)

            task.spawn(function() safeCallback(callback, Value) end)
            local control = {
                Set = function(_, v, silent)
                    Value = v
                    Button.Text = tostring(v)
                    Library.Flags[text] = v
                    if not silent then
                        task.spawn(function() safeCallback(callback, v) end)
                    end
                end,
                Get = function() return Value end,
                Destroy = function() end
            }
            Library.Elements[text] = control
            return control
        end

        -- MultiDropdown
        function GroupAPI:MultiDropdown(text, options, default, callback)
            if not Library:RegisterFlag(text, default or {}) then return end
            local Selected = {}
            for _,v in pairs(default or {}) do Selected[v] = true end
            local Open = false
            local Frame = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,40),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0
            })
            Corner(Frame, 5)
            ThemeObject(Frame, "BackgroundColor3", "Background")

            local Label = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(0.4,0,1,0),
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(Label, "TextColor3", "Text")

            local Button = Create("TextButton", {
                Parent = Frame, Position = UDim2.new(0.45,0,0.5,-12), Size = UDim2.new(0.5,-6,0,24),
                BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0,
                Text = "...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text
            })
            Corner(Button, 4)
            ThemeObject(Button, "BackgroundColor3", "Background")
            ThemeObject(Button, "TextColor3", "Text")

            local List = Create("Frame", {
                Parent = ScreenGui, Visible = false, Size = UDim2.new(0, 200, 0, (#options * 26) + 4),
                BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0, ZIndex = Library.ZIndex + 1
            })
            Corner(List, 5)
            Stroke(List)
            table.insert(Library.DetachedFrames, List)
            applyZIndex(List, Library.ZIndex + 1)

            Create("UIListLayout", { Parent = List, Padding = UDim.new(0,2) })
            Create("UIPadding", { Parent = List, PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,2) })

            local function Refresh()
                local Names = {}
                for k,v in pairs(Selected) do if v then table.insert(Names, k) end end
                local full = table.concat(Names, ", ")
                Button.Text = #Names > 0 and (#full > 20 and full:sub(1,17).."..." or full) or "None"
                local out = {}
                for _,v in ipairs(options) do if Selected[v] then table.insert(out, v) end end
                Library.Flags[text] = out
                task.spawn(function() safeCallback(callback, out) end)
            end

            local function CloseDropdown()
                Open = false
                List.Visible = false
                if Library.OpenDropdown and Library.OpenDropdown.List == List then
                    Library.OpenDropdown = nil
                end
            end

            local function OpenDropdown()
                if Library.OpenDropdown and Library.OpenDropdown.List then
                    Library.OpenDropdown.List.Visible = false
                end
                local Pos = Button.AbsolutePosition
                List.Position = UDim2.new(0, Pos.X, 0, Pos.Y + Button.AbsoluteSize.Y + 2)
                List.Size = UDim2.new(0, math.max(Button.AbsoluteSize.X, 100), 0, (#options * 26) + 4)
                List.Visible = true
                Open = true
                Library.OpenDropdown = { List = List, Button = Button }
            end

            local optionButtons = {}
            for _,option in ipairs(options) do
                local Opt = Create("TextButton", {
                    Parent = List, Size = UDim2.new(1,-4,0,24),
                    BackgroundColor3 = Selected[option] and Library.Theme.Accent or Library.Theme.Surface2,
                    BorderSizePixel = 0, Text = option, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text,
                    ZIndex = Library.ZIndex + 2
                })
                Corner(Opt, 4)
                ThemeObject(Opt, "BackgroundColor3", "Background")
                ThemeObject(Opt, "TextColor3", "Text")
                optionButtons[option] = Opt
                Opt.Selected = Selected[option] or false
                table.insert(Library.MultiOptions, Opt)

                Opt.MouseButton1Click:Connect(function()
                    Selected[option] = not Selected[option]
                    Opt.Selected = Selected[option]
                    Opt.BackgroundColor3 = Selected[option] and Library.Theme.Accent or Library.Theme.Surface2
                    Refresh()
                end)
            end

            Button.MouseButton1Click:Connect(function()
                if Open then CloseDropdown() else OpenDropdown() end
            end)

            Refresh()
            local control = {
                Set = function(_, selections, silent)
                    for k in pairs(Selected) do Selected[k] = false end
                    for _,v in ipairs(selections) do
                        Selected[v] = true
                        if optionButtons[v] then
                            optionButtons[v].Selected = true
                            optionButtons[v].BackgroundColor3 = Library.Theme.Accent
                        end
                    end
                    for _,v in ipairs(options) do
                        if not Selected[v] and optionButtons[v] then
                            optionButtons[v].Selected = false
                            optionButtons[v].BackgroundColor3 = Library.Theme.Surface2
                        end
                    end
                    if not silent then Refresh() end
                end,
                Get = function()
                    local out = {}
                    for _,v in ipairs(options) do if Selected[v] then table.insert(out, v) end end
                    return out
                end,
                Destroy = function() end
            }
            Library.Elements[text] = control
            return control
        end

        -- Keybind
        function GroupAPI:Keybind(text, default, onPress, onChanged)
            onChanged = onChanged or function() end
            if not Library:RegisterFlag(text, default) then return end
            local Key = default or Enum.KeyCode.E
            local Waiting = false
            local destroyed = false

            local bindId = HttpService:GenerateGUID(false)
            table.insert(Library.Keybinds, { Id = bindId, Key = Key, Callback = onPress })

            local Frame = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,40),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0
            })
            Corner(Frame, 5)
            ThemeObject(Frame, "BackgroundColor3", "Background")

            local Label = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(0.5,0,1,0),
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(Label, "TextColor3", "Text")

            local Button = Create("TextButton", {
                Parent = Frame, Position = UDim2.new(1,-90,0.5,-12), Size = UDim2.new(0,78,0,24),
                BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0,
                Text = Key.Name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text
            })
            Corner(Button, 4)
            ThemeObject(Button, "BackgroundColor3", "Background")
            ThemeObject(Button, "TextColor3", "Text")

            Button.MouseButton1Click:Connect(function()
                if Waiting or destroyed then return end
                Waiting = true
                Button.Text = "..."
                if Library.WaitingKeybind then
                    Library.WaitingKeybind:Disconnect()
                    Library.WaitingKeybind = nil
                end
                local conn
                conn = UIS.InputBegan:Connect(function(input, gp)
                    if gp or destroyed then return end
                    if input.KeyCode ~= Enum.KeyCode.Unknown then
                        Key = input.KeyCode
                        Button.Text = Key.Name
                        Waiting = false
                        Library.Flags[text] = Key
                        task.spawn(function() safeCallback(onChanged, Key) end)
                        for _, bind in ipairs(Library.Keybinds) do
                            if bind.Id == bindId then bind.Key = Key break end
                        end
                        conn:Disconnect()
                        Library.WaitingKeybind = nil
                    end
                end)
                Library.WaitingKeybind = conn
            end)

            task.spawn(function() safeCallback(onChanged, Key) end)
            local control = {
                Set = function(_, v, silent)
                    Key = v
                    Button.Text = v.Name
                    Library.Flags[text] = v
                    if not silent then
                        task.spawn(function() safeCallback(onChanged, v) end)
                    end
                    for _, bind in ipairs(Library.Keybinds) do
                        if bind.Id == bindId then bind.Key = v break end
                    end
                end,
                Get = function() return Key end,
                Destroy = function()
                    destroyed = true
                    Waiting = false
                    if Library.WaitingKeybind then
                        Library.WaitingKeybind:Disconnect()
                        Library.WaitingKeybind = nil
                    end
                end
            }
            Library.Elements[text] = control
            return control
        end

        -- Textbox
        function GroupAPI:Textbox(text, default, callback)
            if not Library:RegisterFlag(text, default or "") then return end
            local Value = default or ""
            local Frame = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,40),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0
            })
            Corner(Frame, 5)
            ThemeObject(Frame, "BackgroundColor3", "Background")

            local Label = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(0.4,0,1,0),
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(Label, "TextColor3", "Text")

            local Box = Create("TextBox", {
                Parent = Frame, Position = UDim2.new(0.45,0,0.5,-12), Size = UDim2.new(0.5,-6,0,24),
                BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0,
                ClearTextOnFocus = false, PlaceholderText = "Enter text...",
                Text = Value, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text
            })
            Corner(Box, 4)
            ThemeObject(Box, "BackgroundColor3", "Background")
            ThemeObject(Box, "TextColor3", "Text")

            local StrokeObj = Create("UIStroke", { Parent = Box, Color = Library.Theme.Outline, Thickness = 1 })
            ThemeObject(StrokeObj, "Color", "Outline")

            Box.Focused:Connect(function()
                createTween(StrokeObj, TweenInfo.new(0.15), { Color = Library.Theme.Accent })
            end)
            Box.FocusLost:Connect(function()
                createTween(StrokeObj, TweenInfo.new(0.15), { Color = Library.Theme.Outline })
                Value = Box.Text
                Library.Flags[text] = Value
                task.spawn(function() safeCallback(callback, Value) end)
            end)

            task.spawn(function() safeCallback(callback, Value) end)
            local control = {
                Set = function(_, v, silent)
                    v = tostring(v)
                    Value = v
                    Box.Text = v
                    Library.Flags[text] = v
                    if not silent then
                        task.spawn(function() safeCallback(callback, v) end)
                    end
                end,
                Get = function() return Value end,
                Destroy = function() end
            }
            Library.Elements[text] = control
            return control
        end

        -- Colorpicker
        function GroupAPI:Colorpicker(text, default, callback)
            if not Library:RegisterFlag(text, default) then return end
            local Color = default or Color3.fromRGB(255,255,255)
            local Open = false
            local Hue, Sat, Val = Color:ToHSV()

            local Frame = Create("Frame", {
                Parent = Holder, Size = UDim2.new(1,0,0,40),
                BackgroundColor3 = Library.Theme.Surface2, BorderSizePixel = 0, ClipsDescendants = false
            })
            Corner(Frame, 5)
            ThemeObject(Frame, "BackgroundColor3", "Background")

            local Label = Create("TextLabel", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0,12,0,0), Size = UDim2.new(0.5,0,1,0),
                Font = Enum.Font.Gotham, Text = text, TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            })
            ThemeObject(Label, "TextColor3", "Text")

            local Preview = Create("TextButton", {
                Parent = Frame, Position = UDim2.new(1,-42,0.5,-10), Size = UDim2.new(0,20,0,20),
                BackgroundColor3 = Color, BorderSizePixel = 0, Text = ""
            })
            Corner(Preview, 4)

            local Picker = Create("Frame", {
                Parent = ScreenGui, Visible = false, Size = UDim2.new(0,180,0,150),
                BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0, ZIndex = Library.ZIndex + 1
            })
            Corner(Picker, 6)
            Stroke(Picker)
            table.insert(Library.DetachedFrames, Picker)
            applyZIndex(Picker, Library.ZIndex + 1)

            local Palette = Create("ImageLabel", {
                Parent = Picker, Position = UDim2.new(0,10,0,10), Size = UDim2.new(0,120,0,120),
                BackgroundColor3 = Color3.fromHSV(Hue,1,1), BorderSizePixel = 0,
                Image = "rbxassetid://4155801252", ScaleType = Enum.ScaleType.Stretch, ZIndex = Library.ZIndex + 2
            })
            Corner(Palette, 4)

            local Selector = Create("Frame", {
                Parent = Palette, Size = UDim2.new(0,4,0,4), AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new(Sat,0,1-Val,0),
                BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = Library.ZIndex + 3
            })
            Corner(Selector, 10)

            local HueBar = Create("ImageLabel", {
                Parent = Picker, Position = UDim2.new(0,140,0,10), Size = UDim2.new(0,20,0,120),
                BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
                Image = "rbxassetid://3641079629", ScaleType = Enum.ScaleType.Stretch, ZIndex = Library.ZIndex + 2
            })
            Corner(HueBar, 4)

            local HueSelector = Create("Frame", {
                Parent = HueBar, Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,Hue,0),
                BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = Library.ZIndex + 3
            })

            local cpData = {
                Palette = Palette, HueBar = HueBar, Selector = Selector, HueSelector = HueSelector,
                Preview = Preview, Picker = Picker, Hue = Hue, Sat = Sat, Val = Val,
                DraggingPalette = false, DraggingHue = false, Flag = text, Callback = callback,
            }

            function cpData.UpdateColor()
                Color = Color3.fromHSV(cpData.Hue, cpData.Sat, cpData.Val)
                cpData.Preview.BackgroundColor3 = Color
                cpData.Palette.BackgroundColor3 = Color3.fromHSV(cpData.Hue, 1, 1)
                Library.Flags[cpData.Flag] = Color
                task.spawn(function() safeCallback(cpData.Callback, Color) end)
            end

            Palette.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    cpData.DraggingPalette = true
                    cpData.DraggingHue = false
                    Library.ActiveColorpicker = cpData
                    local x = math.clamp(input.Position.X - Palette.AbsolutePosition.X, 0, Palette.AbsoluteSize.X)
                    local y = math.clamp(input.Position.Y - Palette.AbsolutePosition.Y, 0, Palette.AbsoluteSize.Y)
                    cpData.Sat = x / Palette.AbsoluteSize.X
                    cpData.Val = 1 - (y / Palette.AbsoluteSize.Y)
                    cpData.Selector.Position = UDim2.new(cpData.Sat, 0, 1 - cpData.Val, 0)
                    cpData.UpdateColor()
                end
            end)
            HueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    cpData.DraggingHue = true
                    cpData.DraggingPalette = false
                    Library.ActiveColorpicker = cpData
                    local y = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
                    cpData.Hue = math.clamp(y / HueBar.AbsoluteSize.Y, 0, 0.999)
                    cpData.HueSelector.Position = UDim2.new(0, 0, cpData.Hue, 0)
                    cpData.UpdateColor()
                end
            end)

            Preview.MouseButton1Click:Connect(function()
                Open = not Open
                if Open then
                    local Pos = Preview.AbsolutePosition
                    Picker.Position = UDim2.new(0, Pos.X - 140, 0, Pos.Y + 26)
                    Library.OpenColorpicker = { Picker = Picker, Preview = Preview }
                else
                    Library.OpenColorpicker = nil
                end
                Picker.Visible = Open
            end)

            task.spawn(function() safeCallback(callback, Color) end)
            local control = {
                Set = function(_, v, silent)
                    Color = v
                    cpData.Preview.BackgroundColor3 = v
                    cpData.Hue, cpData.Sat, cpData.Val = v:ToHSV()
                    cpData.Selector.Position = UDim2.new(cpData.Sat, 0, 1 - cpData.Val, 0)
                    cpData.HueSelector.Position = UDim2.new(0, 0, cpData.Hue, 0)
                    cpData.Palette.BackgroundColor3 = Color3.fromHSV(cpData.Hue, 1, 1)
                    Library.Flags[text] = v
                    if not silent then
                        task.spawn(function() safeCallback(callback, v) end)
                    end
                end,
                Get = function() return Color end,
                Destroy = function() end
            }
            Library.Elements[text] = control
            return control
        end

        return GroupAPI
    end
    return TabAPI
end

-- ==============================================
-- DESTROY (fully clean)
-- ==============================================
function Library:Destroy()
    self.Destroyed = true

    -- Cancel active tweens
    for _, tween in ipairs(self.ActiveTweens) do
        pcall(function() tween:Cancel() end)
    end
    table.clear(self.ActiveTweens)

    -- Cancel waiting keybind connection
    if self.WaitingKeybind then
        pcall(function() self.WaitingKeybind:Disconnect() end)
        self.WaitingKeybind = nil
    end

    -- Call Destroy on all elements (keybinds etc.)
    for _, element in pairs(self.Elements) do
        if type(element) == "table" and element.Destroy then
            pcall(element.Destroy)
        end
    end

    -- Disconnect all stored connections
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(self.Connections)

    -- Destroy detached frames
    for _, frame in ipairs(self.DetachedFrames) do
        pcall(function() frame:Destroy() end)
    end
    table.clear(self.DetachedFrames)

    -- Clear theme object references
    for _, category in pairs(self.ThemeObjects) do
        table.clear(category)
    end

    if self.CreatedBlur and Blur then
        pcall(function() Blur:Destroy() end)
    end

    pcall(function() ScreenGui:Destroy() end)

    table.clear(self.Elements)
    table.clear(self.Keybinds)
    table.clear(self.Flags)
    table.clear(self.FlagNamespaces)
    table.clear(self.ToggleSwitches)
    table.clear(self.MultiOptions)
    table.clear(self.Tabs)
end

Close.MouseButton1Click:Connect(function()
    Library:Destroy()
end)

-- ==============================================
-- CONFIG SYSTEM
-- ==============================================
function Library:SaveConfig(name)
    local serialized = serialize(self.Flags)
    writefile("DarkHubV2_" .. name .. ".json", HttpService:JSONEncode(serialized))
    self:Notify("Config", "Saved " .. name)
end

function Library:LoadConfig(name)
    local file = "DarkHubV2_" .. name .. ".json"
    if isfile(file) then
        local data = readfile(file)
        local success, raw = pcall(HttpService.JSONDecode, HttpService, data)
        if success and raw then
            local flags = deserialize(raw)
            -- Update existing table instead of replacing
            for k,v in pairs(flags) do
                self.Flags[k] = v
            end
            for flagName, value in pairs(flags) do
                if self.Elements[flagName] then
                    pcall(function()
                        self.Elements[flagName].Set(nil, value, true) -- silent
                    end)
                end
            end
            self:Notify("Config", "Loaded " .. name)
        else
            self:Notify("Config", "Failed to parse " .. name)
        end
    else
        self:Notify("Config", "Config not found: " .. name)
    end
end

return Library
