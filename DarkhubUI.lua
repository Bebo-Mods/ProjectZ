--[[
    DARKHUB V2 – ARCHITECTURE UPGRADE
    - React‑style state manager (CreateState)
    - Spring animation engine (smooth toggle knob)
    - Virtualized dropdown (100–10,000 options, zero lag)
    - Object pooling (no garbage spikes)
    - All previous fixes (attributes, flag namespaces, safe destroy)
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
    State = {},                     -- actual flag values
    StateObjects = {},              -- key -> state object (with Get/Set/OnChange)
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
    Elements = {},                  -- stores UI references for cleanup
    ToggleSwitches = {},
    MultiOptions = {},
    DetachedFrames = {},
    ActiveTweens = {},
    CreatedBlur = false,
    ZIndex = 100,
    Destroyed = false,
    WaitingKeybind = nil,
    MaxNotifications = 8,
    Springs = {},                   -- list of all active springs
    _springLoopStarted = false,
    Pool = {}                       -- object pools
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

-- ==============================================
-- HELPERS
-- ==============================================
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

local function IsAlive(instance)
    return typeof(instance) == "Instance" and instance.Parent ~= nil
end

local function safeCallback(f, ...)
    local ok, err = pcall(f, ...)
    if not ok then warn("DarkHub V2 callback error:", err) end
end

-- ==============================================
-- OBJECT POOLING
-- ==============================================
function Library:Acquire(className)
    local pool = self.Pool[className]
    if not pool then pool = {}; self.Pool[className] = pool end
    if #pool > 0 then
        return table.remove(pool)
    end
    return Instance.new(className)
end

function Library:Release(obj)
    if not obj then return end
    local class = obj.ClassName
    local pool = self.Pool[class]
    if not pool then pool = {}; self.Pool[class] = pool end
    obj.Parent = nil
    table.insert(pool, obj)
end

-- ==============================================
-- SPRING SYSTEM (smooth animations)
-- ==============================================
local function createSpring(freq, damp)
    local spring = {
        pos = 0,
        vel = 0,
        target = 0,
        freq = freq or 12,
        damp = damp or 1,
        _updater = nil,   -- optional function called each frame with current pos
    }
    table.insert(Library.Springs, spring)
    return spring
end

-- Animation driver
if not Library._springLoopStarted then
    Library._springLoopStarted = true
    local stepSprings = function(dt)
        if Library.Destroyed then return end
        for _, spring in ipairs(Library.Springs) do
            local f = spring.freq * 2 * math.pi
            local g = spring.damp
            local offset = spring.pos - spring.target
            local accel = (-f * f) * offset - (2 * g * f) * spring.vel
            spring.vel = spring.vel + accel * dt
            spring.pos = spring.pos + spring.vel * dt
            if spring._updater then
                spring._updater(spring.pos)
            end
        end
    end
    RunService.RenderStepped:Connect(function(dt)
        if #Library.Springs > 0 then
            stepSprings(dt)
        end
    end)
end

-- ==============================================
-- SERIALIZATION (unchanged)
-- ==============================================
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

-- ==============================================
-- STATE MANAGER (React‑style)
-- ==============================================
function Library:CreateState(key, defaultValue)
    if self.StateObjects[key] then
        return self.StateObjects[key]  -- reuse existing state
    end

    self.State[key] = defaultValue

    local listeners = {}
    local stateObj = {
        Get = function()
            return self.State[key]
        end,
        Set = function(_, value, silent)
            if self.State[key] == value then return end
            self.State[key] = value
            if not silent then
                for _, fn in ipairs(listeners) do
                    task.spawn(fn, value)
                end
            end
        end,
        OnChange = function(_, fn)
            table.insert(listeners, fn)
        end,
        -- Cleanup
        Destroy = function()
            self.State[key] = nil
            self.StateObjects[key] = nil
        end
    }
    self.StateObjects[key] = stateObj
    return stateObj
end

-- ==============================================
-- THEME (unchanged but uses attributes)
-- ==============================================
function Library:SetTheme(accentColor)
    self.Theme.Accent = accentColor
    for _,v in ipairs(self.ThemeObjects.Accent) do
        if IsAlive(v.Object) then
            pcall(function() v.Object[v.Property] = accentColor end)
        end
    end
    -- Toggle switches
    for _, switch in ipairs(self.ToggleSwitches) do
        if IsAlive(switch) and switch:GetAttribute("State") then
            switch.BackgroundColor3 = accentColor
        end
    end
    -- Multi options
    for _, opt in ipairs(self.MultiOptions) do
        if IsAlive(opt) then
            opt.BackgroundColor3 = opt:GetAttribute("Selected") and accentColor or self.Theme.Surface2
        end
    end
    -- Tab buttons
    for _, tab in ipairs(self.Tabs) do
        if IsAlive(tab.Button) then
            tab.Button.BackgroundColor3 = tab.Button:GetAttribute("IsSelected") and accentColor or self.Theme.Surface
        end
    end
end

-- ==============================================
-- GUI SETUP
-- ==============================================
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
    Blur = Create("BlurEffect", { Name = "DarkHub_GlobalBlur", Parent = Lighting, Size = 18 })
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
    BackgroundTransparency = 1, ClipsDescendants = false
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

-- Notifications
local NotificationHolder = Create("Frame", {
    Parent = ScreenGui, AnchorPoint = Vector2.new(1,1),
    Position = UDim2.new(1,-20,1,-20), Size = UDim2.new(0,320,1,0),
    BackgroundTransparency = 1
})
Create("UIListLayout", {
    Parent = NotificationHolder, Padding = UDim.new(0,8),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom
})

function Library:Notify(title, text)
    local existing = {}
    for _, child in ipairs(NotificationHolder:GetChildren()) do
        if child:IsA("Frame") then table.insert(existing, child) end
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
        if not Frame.Parent then return end
        TweenService:Create(Frame, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(TitleLabel, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
        TweenService:Create(DescLabel, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
        for _, child in ipairs(Frame:GetChildren()) do
            if child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.2), { Transparency = 1 }):Play()
            end
        end
        task.wait(0.2)
        Frame:Destroy()
    end)
end

-- Dragging
local dragging, dragStart, startPos
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
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
local resizeDragging, resizeStart, startSize
ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizeDragging = true; resizeStart = input.Position; startSize = Main.AbsoluteSize
    end
end)
ConnectAndStore(UIS.InputChanged, function(input)
    if resizeDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - resizeStart
        Main.Size = UDim2.new(0, math.max(400, startSize.X + delta.X), 0, math.max(300, startSize.Y + delta.Y))
    end
end)
ConnectAndStore(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then resizeDragging = false end
end)

-- Minimize/Dock
Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false; Dock.Visible = true; Blur.Size = 0
end)
Dock.MouseButton1Click:Connect(function()
    Main.Visible = true; Dock.Visible = false; Blur.Size = 18
end)

-- Centralized input handling (keybinds, slider drags, colorpicker)
Library.ActiveSlider = nil
Library.ActiveColorpicker = nil

ConnectAndStore(UIS.InputBegan, function(input, gp)
    if gp then return end
    for _, bind in ipairs(Library.Keybinds) do
        if input.KeyCode == bind.Key then
            task.spawn(function() safeCallback(bind.Callback, bind.Key) end)
        end
    end
end)

ConnectAndStore(UIS.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if Library.ActiveSlider then
            local slider = Library.ActiveSlider
            local percent = math.clamp((input.Position.X - slider.Bar.AbsolutePosition.X) / slider.Bar.AbsoluteSize.X, 0, 1)
            slider.Fill.Size = UDim2.new(percent, 0, 1, 0)
            local raw = slider.Min + ((slider.Max - slider.Min) * percent)
            local factor = 10 ^ slider.Decimals
            local val = math.floor(raw * factor + 0.5) / factor
            slider.State:Set(val)
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
        Library.ActiveSlider = nil
        if Library.ActiveColorpicker then
            Library.ActiveColorpicker.DraggingPalette = false
            Library.ActiveColorpicker.DraggingHue = false
            Library.ActiveColorpicker = nil
        end
    end
end)

-- Global click outside handler
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
-- TAB SYSTEM (state‑based controls)
-- ==============================================
function Library:Tab(name)
    local TabButton = Create("TextButton", {
        Parent = Sidebar, Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0,
        Text = name, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self.Theme.Text
    })
    Corner(TabButton, 6)
    ThemeObject(TabButton, "TextColor3", "Text")
    TabButton:SetAttribute("IsSelected", false)

    local Page = Create("Frame", { Parent = Content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, ClipsDescendants = false })
    local Left = Create("ScrollingFrame", { Parent = Page, Size = UDim2.new(0.5,-8,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ClipsDescendants = false })
    local Right = Create("ScrollingFrame", { Parent = Page, Position = UDim2.new(0.5,8,0,0), Size = UDim2.new(0.5,-8,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ClipsDescendants = false })
    Create("UIListLayout", {Parent = Left, Padding = UDim.new(0,12)})
    Create("UIListLayout", {Parent = Right, Padding = UDim.new(0,12)})

    local function Select()
        for _,v in pairs(Library.Tabs) do
            v.Page.Visible = false
            v.Button:SetAttribute("IsSelected", false)
            v.Button.BackgroundColor3 = Library.Theme.Surface
        end
        Page.Visible = true
        TabButton:SetAttribute("IsSelected", true)
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
            Button.MouseButton1Click:Connect(function() task.spawn(callback) end)
        end

        -- ==============================================
        -- TOGGLE (spring‑animated knob)
        -- ==============================================
        function GroupAPI:Toggle(text, flag, default, callback)
            local state = Library:CreateState(flag, default)
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
                BackgroundColor3 = default and Library.Theme.Accent or Color3.fromRGB(55,55,55), BorderSizePixel = 0
            })
            Corner(Switch, 20)
            local Knob = Create("Frame", {
                Parent = Switch, Size = UDim2.new(0,16,0,16),
                BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
                Position = default and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
            })
            Corner(Knob, 20)
            Switch:SetAttribute("State", default)
            table.insert(Library.ToggleSwitches, Switch)

            -- Spring for knob
            local spring = createSpring(14, 1)
            spring.pos = default and 1 or 0
            spring.target = spring.pos
            spring._updater = function(pos)
                local x = 2 + (18 - 2) * pos
                Knob.Position = UDim2.new(0, x, 0.5, -8)
            end

            local function updateVisual(val)
                Switch.BackgroundColor3 = val and Library.Theme.Accent or Color3.fromRGB(55,55,55)
                spring.target = val and 1 or 0
            end

            -- Bind state changes
            state:OnChange(function(newVal)
                updateVisual(newVal)
                if callback then callback(newVal) end
            end)

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local newVal = not state:Get()
                    state:Set(newVal)
                    Switch:SetAttribute("State", newVal)
                end
            end)

            -- Initial visual
            updateVisual(state:Get())

            local control = {
                state = state,
                Destroy = function()
                    -- remove spring
                    for i, s in ipairs(Library.Springs) do
                        if s == spring then table.remove(Library.Springs, i); break end
                    end
                    -- remove switch from list
                    for i, s in ipairs(Library.ToggleSwitches) do
                        if s == Switch then table.remove(Library.ToggleSwitches, i); break end
                    end
                end
            }
            Library.Elements[flag] = control
            return state
        end

        -- ==============================================
        -- SLIDER (unchanged, uses state)
        -- ==============================================
        function GroupAPI:Slider(text, flag, min, max, default, decimals, callback)
            if type(decimals) == "function" then callback = decimals; decimals = 0 end
            decimals = decimals or 0
            local state = Library:CreateState(flag, default)
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
                Font = Enum.Font.GothamBold, Text = tostring(default), TextSize = 12, TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Right
            })
            ThemeObject(ValueLabel, "TextColor3", "Text")

            local Bar = Create("Frame", {
                Parent = Frame, Position = UDim2.new(0,12,0,34), Size = UDim2.new(1,-24,0,8),
                BackgroundColor3 = Color3.fromRGB(45,45,50), BorderSizePixel = 0
            })
            Corner(Bar, 10)

            local Fill = Create("Frame", {
                Parent = Bar, Size = UDim2.new((default - min)/(max - min),0,1,0),
                BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0
            })
            ThemeObject(Fill, "BackgroundColor3", "Accent")
            Corner(Fill, 10)

            local sliderData = {
                Bar = Bar, Fill = Fill, ValueLabel = ValueLabel,
                Min = min, Max = max, Decimals = decimals, State = state
            }

            local function updateVisual(v)
                local percent = (v - min) / (max - min)
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                ValueLabel.Text = tostring(v)
            end

            state:OnChange(function(v)
                updateVisual(v)
                if callback then callback(v) end
            end)

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Library.ActiveSlider = sliderData
                    local percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                    local raw = min + ((max - min) * percent)
                    local factor = 10 ^ decimals
                    local val = math.floor(raw * factor + 0.5) / factor
                    state:Set(val)
                end
            end)

            updateVisual(state:Get())

            local control = { state = state, Destroy = function() end }
            Library.Elements[flag] = control
            return state
        end

        -- ==============================================
        -- VIRTUALIZED DROPDOWN
        -- ==============================================
        function GroupAPI:Dropdown(text, flag, options, default, callback)
            local state = Library:CreateState(flag, default or options[1])
            local Open = false
            local ITEM_HEIGHT = 26
            local MAX_VISIBLE = 10

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
                Text = tostring(state:Get()), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text,
                ZIndex = Library.ZIndex + 1
            })
            Corner(Button, 4)
            ThemeObject(Button, "BackgroundColor3", "Background")
            ThemeObject(Button, "TextColor3", "Text")

            local List = Create("Frame", {
                Parent = ScreenGui, Visible = false, Size = UDim2.new(0, 200, 0, ITEM_HEIGHT * MAX_VISIBLE),
                BackgroundColor3 = Library.Theme.Surface, BorderSizePixel = 0, ZIndex = Library.ZIndex + 2,
                ClipsDescendants = true
            })
            Corner(List, 5)
            Stroke(List)
            table.insert(Library.DetachedFrames, List)

            local Scroll = Create("ScrollingFrame", {
                Parent = List, Size = UDim2.new(1,-4,1,-4), Position = UDim2.new(0,2,0,2),
                BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
                CanvasSize = UDim2.new(0,0,0,#options * ITEM_HEIGHT), ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = List.ZIndex + 1
            })

            local Content = Create("Frame", {
                Parent = Scroll, Size = UDim2.new(1,0,0,#options * ITEM_HEIGHT),
                BackgroundTransparency = 1, BorderSizePixel = 0
            })

            -- Connection storage for pooled buttons
            local activeButtons = {}   -- button -> connection

            local function clearPooled(btn)
                if activeButtons[btn] then
                    activeButtons[btn]:Disconnect()
                    activeButtons[btn] = nil
                end
                btn.Parent = nil
                Library:Release(btn)
            end

            local function renderVisible(startIdx)
                -- Destroy all currently visible buttons (return to pool)
                for _, child in ipairs(Content:GetChildren()) do
                    if child:IsA("TextButton") then
                        clearPooled(child)
                    end
                end
                local endIdx = math.min(startIdx + MAX_VISIBLE - 1, #options)
                for i = startIdx, endIdx do
                    local option = options[i]
                    local btn = Library:Acquire("TextButton")
                    btn.Name = "Option"
                    btn.Size = UDim2.new(1,0,0,ITEM_HEIGHT)
                    btn.Position = UDim2.new(0,0,0,(i-1)*ITEM_HEIGHT)
                    btn.BackgroundColor3 = (option == state:Get()) and Library.Theme.Accent or Library.Theme.Surface2
                    btn.BorderSizePixel = 0
                    btn.Text = option
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 12
                    btn.TextColor3 = Library.Theme.Text
                    btn.ZIndex = List.ZIndex + 2
                    btn.Parent = Content
                    Corner(btn, 4)

                    local conn = btn.MouseButton1Click:Connect(function()
                        state:Set(option)
                        -- update button text
                        Button.Text = tostring(option)
                        -- close dropdown
                        List.Visible = false
                        Open = false
                        Library.OpenDropdown = nil
                    end)
                    activeButtons[btn] = conn
                end
            end

            local function updateScroll()
                local canvasY = Scroll.CanvasPosition.Y
                local startIdx = math.floor(canvasY / ITEM_HEIGHT) + 1
                if startIdx < 1 then startIdx = 1 end
                renderVisible(startIdx)
            end

            Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScroll)

            local function OpenDropdown()
                if Library.OpenDropdown and IsAlive(Library.OpenDropdown.List) then
                    Library.OpenDropdown.List.Visible = false
                end
                local pos = Button.AbsolutePosition
                List.Position = UDim2.new(0, pos.X, 0, pos.Y + Button.AbsoluteSize.Y + 2)
                List.Size = UDim2.new(0, math.max(Button.AbsoluteSize.X, 100), 0, math.min(ITEM_HEIGHT * MAX_VISIBLE, ITEM_HEIGHT * #options))
                List.Visible = true
                Open = true
                task.wait()  -- prevent instant close from same click
                Library.OpenDropdown = { List = List, Button = Button }
                -- initial render
                updateScroll()
            end

            local function CloseDropdown()
                Open = false
                List.Visible = false
                Library.OpenDropdown = nil
            end

            Button.MouseButton1Click:Connect(function()
                if Open then CloseDropdown() else OpenDropdown() end
            end)

            state:OnChange(function(val)
                Button.Text = tostring(val)
                -- update highlighted option (if list open)
                if Open then
                    for _, child in ipairs(Content:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.BackgroundColor3 = (child.Text == val) and Library.Theme.Accent or Library.Theme.Surface2
                        end
                    end
                end
                if callback then callback(val) end
            end)

            renderVisible(1)
            local control = {
                state = state,
                Destroy = function()
                    CloseDropdown()
                    for _, child in ipairs(Content:GetChildren()) do
                        if child:IsA("TextButton") then
                            clearPooled(child)
                        end
                    end
                    List:Destroy()
                end
            }
            Library.Elements[flag] = control
            return state
        end

        -- ==============================================
        -- MULTIDROPDOWN (virtual not implemented, keep old but state)
        -- ==============================================
        function GroupAPI:MultiDropdown(text, flag, options, default, callback)
            local state = Library:CreateState(flag, default or {})
            local Selected = {}
            for _, v in pairs(default or {}) do Selected[v] = true end
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

            local Layout = Create("UIListLayout", { Parent = List, Padding = UDim.new(0,2) })
            Create("UIPadding", { Parent = List, PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,2) })

            local optionButtons = {}
            local function Refresh()
                local Names = {}
                for k,v in pairs(Selected) do if v then table.insert(Names, k) end end
                local full = table.concat(Names, ", ")
                Button.Text = #Names > 0 and (#full > 20 and full:sub(1,17).."..." or full) or "None"
                local out = {}
                for _,v in ipairs(options) do if Selected[v] then table.insert(out, v) end end
                state:Set(out, true)  -- silent update
                if callback then callback(out) end
            end

            local function CloseDropdown()
                Open = false; List.Visible = false
                if Library.OpenDropdown and Library.OpenDropdown.List == List then
                    Library.OpenDropdown = nil
                end
            end

            local function OpenDropdown()
                if Library.OpenDropdown and IsAlive(Library.OpenDropdown.List) then
                    Library.OpenDropdown.List.Visible = false
                end
                local Pos = Button.AbsolutePosition
                List.Position = UDim2.new(0, Pos.X, 0, Pos.Y + Button.AbsoluteSize.Y + 2)
                List.Size = UDim2.new(0, math.max(Button.AbsoluteSize.X, 100), 0, (#options * 26) + 4)
                List.Visible = true; Open = true
                task.wait()
                Library.OpenDropdown = { List = List, Button = Button }
            end

            for _,option in ipairs(options) do
                local Opt = Create("TextButton", {
                    Parent = List, Size = UDim2.new(1,-4,0,24),
                    BackgroundColor3 = Selected[option] and Library.Theme.Accent or Library.Theme.Surface2,
                    BorderSizePixel = 0, Text = option, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text
                })
                Corner(Opt, 4)
                ThemeObject(Opt, "TextColor3", "Text")
                Opt:SetAttribute("Selected", Selected[option] or false)
                table.insert(Library.MultiOptions, Opt)
                optionButtons[option] = Opt

                Opt.MouseButton1Click:Connect(function()
                    Selected[option] = not Selected[option]
                    Opt:SetAttribute("Selected", Selected[option])
                    Opt.BackgroundColor3 = Selected[option] and Library.Theme.Accent or Library.Theme.Surface2
                    Refresh()
                end)
            end

            Button.MouseButton1Click:Connect(function()
                if Open then CloseDropdown() else OpenDropdown() end
            end)

            Refresh()
            local control = {
                state = state,
                Destroy = function()
                    CloseDropdown()
                    for _, opt in pairs(optionButtons) do
                        for i, o in ipairs(Library.MultiOptions) do
                            if o == opt then table.remove(Library.MultiOptions, i); break end
                        end
                    end
                    List:Destroy()
                end
            }
            Library.Elements[flag] = control
            return state
        end

        -- ==============================================
        -- KEYBIND (unchanged, state)
        -- ==============================================
        function GroupAPI:Keybind(text, flag, default, onPress, onChanged)
            onChanged = onChanged or function() end
            local state = Library:CreateState(flag, default)
            local Key = default or Enum.KeyCode.E
            local Waiting = false; local destroyed = false

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
                Waiting = true; Button.Text = "..."
                if Library.WaitingKeybind then
                    Library.WaitingKeybind:Disconnect()
                    Library.WaitingKeybind = nil
                end
                local conn
                conn = UIS.InputBegan:Connect(function(input, gp)
                    if gp or destroyed then return end
                    if input.KeyCode ~= Enum.KeyCode.Unknown then
                        Key = input.KeyCode
                        Button.Text = Key.Name; Waiting = false
                        state:Set(Key)
                        onChanged(Key)
                        for _, bind in ipairs(Library.Keybinds) do
                            if bind.Id == bindId then bind.Key = Key break end
                        end
                        conn:Disconnect()
                        Library.WaitingKeybind = nil
                    end
                end)
                Library.WaitingKeybind = conn
            end)

            state:OnChange(function(v)
                onChanged(v)
                for _, bind in ipairs(Library.Keybinds) do
                    if bind.Id == bindId then bind.Key = v break end
                end
            end)
            onChanged(Key)

            local control = {
                state = state,
                Destroy = function()
                    destroyed = true; Waiting = false
                    if Library.WaitingKeybind then
                        Library.WaitingKeybind:Disconnect()
                        Library.WaitingKeybind = nil
                    end
                end
            }
            Library.Elements[flag] = control
            return state
        end

        -- ==============================================
        -- TEXTBOX (unchanged, state)
        -- ==============================================
        function GroupAPI:Textbox(text, flag, default, callback)
            local state = Library:CreateState(flag, default or "")
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
                Text = state:Get(), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Library.Theme.Text
            })
            Corner(Box, 4)
            ThemeObject(Box, "BackgroundColor3", "Background")
            ThemeObject(Box, "TextColor3", "Text")

            local StrokeObj = Create("UIStroke", { Parent = Box, Color = Library.Theme.Outline, Thickness = 1 })
            ThemeObject(StrokeObj, "Color", "Outline")

            Box.Focused:Connect(function()
                TweenService:Create(StrokeObj, TweenInfo.new(0.15), { Color = Library.Theme.Accent }):Play()
            end)
            Box.FocusLost:Connect(function()
                TweenService:Create(StrokeObj, TweenInfo.new(0.15), { Color = Library.Theme.Outline }):Play()
                state:Set(Box.Text)
                if callback then callback(Box.Text) end
            end)

            state:OnChange(function(v)
                Box.Text = v
            end)

            local control = { state = state, Destroy = function() end }
            Library.Elements[flag] = control
            return state
        end

        -- ==============================================
        -- COLORPICKER (unchanged, state)
        -- ==============================================
        function GroupAPI:Colorpicker(text, flag, default, callback)
            local state = Library:CreateState(flag, default or Color3.fromRGB(255,255,255))
            local Color = state:Get()
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
                DraggingPalette = false, DraggingHue = false, Flag = flag, State = state
            }

            function cpData.UpdateColor()
                local c = Color3.fromHSV(cpData.Hue, cpData.Sat, cpData.Val)
                cpData.Preview.BackgroundColor3 = c
                cpData.Palette.BackgroundColor3 = Color3.fromHSV(cpData.Hue, 1, 1)
                state:Set(c)
                if callback then callback(c) end
            end

            Palette.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    cpData.DraggingPalette = true; cpData.DraggingHue = false
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
                    cpData.DraggingHue = true; cpData.DraggingPalette = false
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

            local control = { state = state, Destroy = function() Picker:Destroy() end }
            Library.Elements[flag] = control
            return state
        end

        return GroupAPI
    end
    return TabAPI
end

-- ==============================================
-- DESTROY
-- ==============================================
function Library:Destroy()
    self.Destroyed = true
    for _, tween in ipairs(self.ActiveTweens) do pcall(function() tween:Cancel() end) end
    table.clear(self.ActiveTweens)
    if self.WaitingKeybind then pcall(function() self.WaitingKeybind:Disconnect() end) self.WaitingKeybind = nil end
    for _, element in pairs(self.Elements) do if type(element) == "table" and element.Destroy then pcall(element.Destroy) end end
    for _, conn in ipairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(self.Connections)
    for _, frame in ipairs(self.DetachedFrames) do pcall(function() frame:Destroy() end) end
    table.clear(self.DetachedFrames)
    for _, category in pairs(self.ThemeObjects) do table.clear(category) end
    if self.CreatedBlur and Blur then pcall(function() Blur:Destroy() end) end
    pcall(function() ScreenGui:Destroy() end)
    table.clear(self.Elements)
    table.clear(self.Keybinds)
    table.clear(self.State)
    table.clear(self.StateObjects)
    table.clear(self.ToggleSwitches)
    table.clear(self.MultiOptions)
    table.clear(self.Tabs)
    table.clear(self.Springs)
end

Close.MouseButton1Click:Connect(function() Library:Destroy() end)

-- ==============================================
-- CONFIG (save/load all state)
-- ==============================================
function Library:SaveConfig(name)
    local serialized = serialize(self.State)
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
            for k, v in pairs(flags) do
                self.State[k] = v
                if self.StateObjects[k] then
                    self.StateObjects[k]:Set(v, true)   -- silent update (UI already bound)
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
