--[[
════════════════════════════════════════════════════════════════
  wally2  —  fixed + hardened + themed
  Original fork by SharKK | SharKK#1954
  Fixes & additions:
    ✔ pcall on every operation that can throw
    ✔ gethui() → cloneref(CoreGui) → CoreGui → PlayerGui (safe chain)
    ✔ cloneref() on every service reference
    ✔ :connect() → :Connect() (Roblox deprecation fix)
    ✔ :disconnect() → :Disconnect()
    ✔ wait() → task.wait()
    ✔ spawn() → task.spawn()
    ✔ RenderStepped slider (was broken on menu-close) — now uses
      UserInputService mouse tracking, properly disconnected
    ✔ Dropdown container leak fixed (Debris replaced with proper destroy)
    ✔ SearchBox ZIndex layering fixed
    ✔ Slider default-position bug fixed (was off-by-one on 100%)
    ✔ Box number clamp now works correctly on focus
    ✔ Rainbow loop uses task.wait() and won't error if object destroyed
    ✔ RightControl hide-toggle preserves original positions correctly
    ✔ Bind system uses InputBegan properly (gpe respected)

  NEW FEATURES:
    ✔ library.themes  — 6 prebuilt themes
    ✔ library:SetTheme(name)  — switch theme at any time
    ✔ window:ColorSettings()  — in-window theme/color picker section
    ✔ library:Notify(title, text, duration)  — toast notification
    ✔ window:Label(text)  — simple text label element
    ✔ Configurable accent color per-window via options.underlinecolor
════════════════════════════════════════════════════════════════
]]

-- ════════════════════════════════
--  SAFE SERVICE GETTER
-- ════════════════════════════════
local function Svc(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    if not ok then return nil end
    if cloneref then
        local ok2, r = pcall(cloneref, s)
        if ok2 then return r end
    end
    return s
end

local Players    = Svc("Players")
local UIS        = Svc("UserInputService")
local RunService = Svc("RunService")
local TweenSvc   = Svc("TweenService")
local Debris     = Svc("Debris")

-- ════════════════════════════════
--  SAFE GUI PARENT
-- ════════════════════════════════
local function GuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    if cloneref then
        local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if ok and cg then return cg end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    local lp = Players and Players.LocalPlayer
    return lp and lp:FindFirstChildOfClass("PlayerGui")
end

-- ════════════════════════════════
--  LIBRARY TABLE
-- ════════════════════════════════
local library = {
    count        = 0,
    queue        = {},
    callbacks    = {},
    rainbowtable = {},
    toggled      = true,
    binds        = {},
    binding      = false,
    _windows     = {},
}

-- ════════════════════════════════
--  PREBUILT THEMES
-- ════════════════════════════════
library.themes = {
    ["Default"] = {
        topcolor         = Color3.fromRGB(30,  30,  30),
        underlinecolor   = Color3.fromRGB(0,   255, 140),
        bgcolor          = Color3.fromRGB(35,  35,  35),
        boxcolor         = Color3.fromRGB(35,  35,  35),
        btncolor         = Color3.fromRGB(25,  25,  25),
        dropcolor        = Color3.fromRGB(25,  25,  25),
        sectncolor       = Color3.fromRGB(25,  25,  25),
        bordercolor      = Color3.fromRGB(60,  60,  60),
        textcolor        = Color3.fromRGB(255, 255, 255),
        titletextcolor   = Color3.fromRGB(255, 255, 255),
        placeholdercolor = Color3.fromRGB(120, 120, 120),
        strokecolor      = Color3.fromRGB(0,   0,   0),
        titlestrokecolor = Color3.fromRGB(0,   0,   0),
        font             = Enum.Font.SourceSans,
        titlefont        = Enum.Font.Code,
        fontsize         = 17,
        titlesize        = 18,
        textstroke       = 1,
        titlestroke      = 1,
    },
    ["Midnight"] = {
        topcolor         = Color3.fromRGB(15,  15,  25),
        underlinecolor   = Color3.fromRGB(100, 80,  255),
        bgcolor          = Color3.fromRGB(20,  20,  32),
        boxcolor         = Color3.fromRGB(20,  20,  32),
        btncolor         = Color3.fromRGB(12,  12,  22),
        dropcolor        = Color3.fromRGB(12,  12,  22),
        sectncolor       = Color3.fromRGB(12,  12,  22),
        bordercolor      = Color3.fromRGB(55,  50,  90),
        textcolor        = Color3.fromRGB(210, 205, 235),
        titletextcolor   = Color3.fromRGB(255, 255, 255),
        placeholdercolor = Color3.fromRGB(90,  85,  120),
        strokecolor      = Color3.fromRGB(0,   0,   0),
        titlestrokecolor = Color3.fromRGB(0,   0,   0),
        font             = Enum.Font.Gotham,
        titlefont        = Enum.Font.GothamBold,
        fontsize         = 14,
        titlesize        = 15,
        textstroke       = 1,
        titlestroke      = 1,
    },
    ["Crimson"] = {
        topcolor         = Color3.fromRGB(25,  10,  10),
        underlinecolor   = Color3.fromRGB(220, 40,  60),
        bgcolor          = Color3.fromRGB(30,  14,  14),
        boxcolor         = Color3.fromRGB(30,  14,  14),
        btncolor         = Color3.fromRGB(20,  8,   8),
        dropcolor        = Color3.fromRGB(20,  8,   8),
        sectncolor       = Color3.fromRGB(20,  8,   8),
        bordercolor      = Color3.fromRGB(80,  30,  30),
        textcolor        = Color3.fromRGB(255, 220, 220),
        titletextcolor   = Color3.fromRGB(255, 200, 200),
        placeholdercolor = Color3.fromRGB(120, 80,  80),
        strokecolor      = Color3.fromRGB(0,   0,   0),
        titlestrokecolor = Color3.fromRGB(0,   0,   0),
        font             = Enum.Font.SourceSans,
        titlefont        = Enum.Font.SourceSansBold,
        fontsize         = 17,
        titlesize        = 18,
        textstroke       = 1,
        titlestroke      = 1,
    },
    ["Arctic"] = {
        topcolor         = Color3.fromRGB(235, 240, 250),
        underlinecolor   = Color3.fromRGB(30,  130, 220),
        bgcolor          = Color3.fromRGB(245, 247, 252),
        boxcolor         = Color3.fromRGB(225, 230, 240),
        btncolor         = Color3.fromRGB(215, 220, 235),
        dropcolor        = Color3.fromRGB(220, 225, 238),
        sectncolor       = Color3.fromRGB(200, 208, 225),
        bordercolor      = Color3.fromRGB(180, 188, 210),
        textcolor        = Color3.fromRGB(30,  35,  60),
        titletextcolor   = Color3.fromRGB(20,  25,  50),
        placeholdercolor = Color3.fromRGB(140, 148, 170),
        strokecolor      = Color3.fromRGB(200, 205, 220),
        titlestrokecolor = Color3.fromRGB(200, 205, 220),
        font             = Enum.Font.Gotham,
        titlefont        = Enum.Font.GothamBold,
        fontsize         = 14,
        titlesize        = 15,
        textstroke       = 1,
        titlestroke      = 1,
    },
    ["Gold"] = {
        topcolor         = Color3.fromRGB(22,  18,  8),
        underlinecolor   = Color3.fromRGB(220, 175, 30),
        bgcolor          = Color3.fromRGB(28,  23,  10),
        boxcolor         = Color3.fromRGB(28,  23,  10),
        btncolor         = Color3.fromRGB(18,  14,  5),
        dropcolor        = Color3.fromRGB(18,  14,  5),
        sectncolor       = Color3.fromRGB(18,  14,  5),
        bordercolor      = Color3.fromRGB(90,  72,  20),
        textcolor        = Color3.fromRGB(240, 210, 140),
        titletextcolor   = Color3.fromRGB(255, 230, 160),
        placeholdercolor = Color3.fromRGB(120, 95,  40),
        strokecolor      = Color3.fromRGB(0,   0,   0),
        titlestrokecolor = Color3.fromRGB(0,   0,   0),
        font             = Enum.Font.SourceSans,
        titlefont        = Enum.Font.SourceSansBold,
        fontsize         = 17,
        titlesize        = 18,
        textstroke       = 1,
        titlestroke      = 1,
    },
    ["Neon"] = {
        topcolor         = Color3.fromRGB(5,   5,   5),
        underlinecolor   = "rainbow", -- special: animated
        bgcolor          = Color3.fromRGB(8,   8,   8),
        boxcolor         = Color3.fromRGB(8,   8,   8),
        btncolor         = Color3.fromRGB(4,   4,   4),
        dropcolor        = Color3.fromRGB(4,   4,   4),
        sectncolor       = Color3.fromRGB(4,   4,   4),
        bordercolor      = Color3.fromRGB(50,  50,  50),
        textcolor        = Color3.fromRGB(255, 255, 255),
        titletextcolor   = Color3.fromRGB(255, 255, 255),
        placeholdercolor = Color3.fromRGB(80,  80,  80),
        strokecolor      = Color3.fromRGB(0,   0,   0),
        titlestrokecolor = Color3.fromRGB(0,   0,   0),
        font             = Enum.Font.Code,
        titlefont        = Enum.Font.Code,
        fontsize         = 16,
        titlesize        = 17,
        textstroke       = 1,
        titlestroke      = 0,
    },
}

-- ════════════════════════════════
--  THEME SETTER
-- ════════════════════════════════
function library:SetTheme(themeName)
    local t = self.themes[themeName]
    if not t then return end
    -- merge into options (keeps any user overrides)
    for k, v in pairs(t) do
        pcall(function() self.options[k] = v end)
    end
    -- recolor existing windows
    for _, wdata in pairs(self._windows) do
        pcall(function()
            wdata.object.BackgroundColor3 = self.options.topcolor
            local cont = wdata.object:FindFirstChild("container")
            if cont then cont.BackgroundColor3 = self.options.bgcolor end
            local ul = wdata.object:FindFirstChild("Underline")
            if ul and self.options.underlinecolor ~= "rainbow" then
                ul.BackgroundColor3 = self.options.underlinecolor
            end
        end)
    end
end

-- ════════════════════════════════
--  CREATE HELPER
-- ════════════════════════════════
function library:Create(class, data)
    local obj
    pcall(function()
        obj = Instance.new(class)
        for i, v in next, data do
            if i ~= "Parent" then
                pcall(function()
                    if typeof(v) == "Instance" then
                        v.Parent = obj
                    else
                        obj[i] = v
                    end
                end)
            end
        end
        obj.Parent = data.Parent
    end)
    return obj
end

-- ════════════════════════════════
--  DEFAULT OPTIONS
-- ════════════════════════════════
local default = {
    topcolor         = Color3.fromRGB(30,  30,  30),
    titlecolor       = Color3.fromRGB(255, 255, 255),
    underlinecolor   = Color3.fromRGB(0,   255, 140),
    bgcolor          = Color3.fromRGB(35,  35,  35),
    boxcolor         = Color3.fromRGB(35,  35,  35),
    btncolor         = Color3.fromRGB(25,  25,  25),
    dropcolor        = Color3.fromRGB(25,  25,  25),
    sectncolor       = Color3.fromRGB(25,  25,  25),
    bordercolor      = Color3.fromRGB(60,  60,  60),
    font             = Enum.Font.SourceSans,
    titlefont        = Enum.Font.Code,
    fontsize         = 17,
    titlesize        = 18,
    textstroke       = 1,
    titlestroke      = 1,
    strokecolor      = Color3.fromRGB(0,   0,   0),
    textcolor        = Color3.fromRGB(255, 255, 255),
    titletextcolor   = Color3.fromRGB(255, 255, 255),
    placeholdercolor = Color3.fromRGB(120, 120, 120),
    titlestrokecolor = Color3.fromRGB(0,   0,   0),
}
library.options = setmetatable({}, {__index = default})

-- ════════════════════════════════
--  GLOBAL TOGGLE (RightControl)
-- ════════════════════════════════
pcall(function()
    UIS.InputBegan:Connect(function(key, gpe)
        if gpe then return end
        pcall(function()
            if key.KeyCode == Enum.KeyCode.RightControl then
                library.toggled = not library.toggled
                for _, data in next, library.queue do
                    pcall(function()
                        local pos = library.toggled and data.p or UDim2.new(-1, 0, -0.5, 0)
                        data.w:TweenPosition(pos,
                            library.toggled and "Out" or "In",
                            "Quad", 0.15, true)
                    end)
                    task.wait()
                end
            end
        end)
    end)
end)

-- ════════════════════════════════
--  BIND PRESS CHECKER
-- ════════════════════════════════
local function isreallypressed(bind, inp)
    local ok = pcall(function()
        local key = bind
        if typeof(key) == "Instance" then
            if key.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key.KeyCode then
                return true
            elseif tostring(key.UserInputType):find("MouseButton") and inp.UserInputType == key.UserInputType then
                return true
            end
        end
        if tostring(key):find("MouseButton1") then
            return key == inp.UserInputType
        else
            return key == inp.KeyCode
        end
    end)
    if not ok then return false end
    -- redo with return value
    local bind2 = bind
    if typeof(bind2) == "Instance" then
        if bind2.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == bind2.KeyCode then return true end
        if tostring(bind2.UserInputType):find("MouseButton") and inp.UserInputType == bind2.UserInputType then return true end
        return false
    end
    if tostring(bind2):find("MouseButton1") then return bind2 == inp.UserInputType end
    return bind2 == inp.KeyCode
end

pcall(function()
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if library.binding then return end
        pcall(function()
            for idx, binds in next, library.binds do
                pcall(function()
                    local real_binding = binds.location[idx]
                    if real_binding and isreallypressed(real_binding, input) then
                        binds.callback()
                    end
                end)
            end
        end)
    end)
end)

-- ════════════════════════════════
--  RAINBOW LOOP
-- ════════════════════════════════
task.spawn(function()
    while true do
        for i = 0, 1, 1/300 do
            for _, obj in next, library.rainbowtable do
                pcall(function()
                    if obj and obj.Parent then
                        obj.BackgroundColor3 = Color3.fromHSV(i, 1, 1)
                    end
                end)
            end
            task.wait()
        end
    end
end)

-- ════════════════════════════════
--  DRAGGER
-- ════════════════════════════════
local function makeDraggable(frame)
    pcall(function()
        local mouse = Players.LocalPlayer:GetMouse()
        local dragging, dragStart, startPos = false, nil, nil

        frame.Active = true
        frame.InputBegan:Connect(function(input)
            pcall(function()
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging  = true
                    dragStart = input.Position
                    startPos  = frame.Position
                end
            end)
        end)
        frame.InputEnded:Connect(function(input)
            pcall(function()
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
        end)
        UIS.InputChanged:Connect(function(input)
            pcall(function()
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Position - dragStart
                    frame:TweenPosition(
                        UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y),
                        "Out", "Linear", 0.05, true)
                end
            end)
        end)
    end)
end

-- ════════════════════════════════
--  TYPES METATABLE
-- ════════════════════════════════
local types = {}
types.__index = types

-- ──────────────────────────────
--  RESIZE
-- ──────────────────────────────
function types:Resize()
    pcall(function()
        local y = 0
        for _, v in next, self.container:GetChildren() do
            if not v:IsA("UIListLayout") then
                y = y + v.AbsoluteSize.Y
            end
        end
        self.container.Size = UDim2.new(1, 0, 0, y + 5)
    end)
end

function types:GetOrder()
    local c = 0
    pcall(function()
        for _, v in next, self.container:GetChildren() do
            if not v:IsA("UIListLayout") then c = c + 1 end
        end
    end)
    return c
end

-- ──────────────────────────────
--  SECTION
-- ──────────────────────────────
function types:Section(name)
    pcall(function()
        local order = self:GetOrder()
        local sz    = order == 0 and UDim2.new(1,0,0,21) or UDim2.new(1,0,0,25)
        local pos   = order == 0 and UDim2.new(0,0,0,-1) or UDim2.new(0,0,0,4)
        local lsz   = order == 0 and UDim2.new(1,0,1,0)  or UDim2.new(1,0,0,20)

        library:Create("Frame", {
            Name               = "Section",
            BackgroundTransparency = 1,
            Size               = sz,
            BackgroundColor3   = library.options.sectncolor,
            BorderSizePixel    = 0,
            LayoutOrder        = order,
            library:Create("TextLabel", {
                Name               = "section_lbl",
                Text               = name,
                BackgroundTransparency = 0,
                BorderSizePixel    = 0,
                BackgroundColor3   = library.options.sectncolor,
                TextColor3         = library.options.textcolor,
                Position           = pos,
                Size               = lsz,
                Font               = library.options.font,
                TextSize           = library.options.fontsize,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3   = library.options.strokecolor,
            }),
            Parent = self.container,
        })
        self:Resize()
    end)
end

-- ──────────────────────────────
--  LABEL  (new)
-- ──────────────────────────────
function types:Label(text)
    pcall(function()
        library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 22),
            LayoutOrder = self:GetOrder(),
            library:Create("TextLabel", {
                Text               = text or "",
                BackgroundTransparency = 1,
                TextColor3         = library.options.textcolor,
                Position           = UDim2.new(0, 5, 0, 0),
                Size               = UDim2.new(1, -5, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
                Font               = library.options.font,
                TextSize           = library.options.fontsize - 2,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3   = library.options.strokecolor,
            }),
            Parent = self.container,
        })
        self:Resize()
    end)
end

-- ──────────────────────────────
--  TOGGLE
-- ──────────────────────────────
function types:Toggle(name, options, callback)
    options  = options  or {}
    callback = callback or function() end
    local default  = options.default  or false
    local location = options.location or self.flags
    local flag     = options.flag     or ""
    location[flag] = default

    local obj = {}
    pcall(function()
        local check = library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 25),
            LayoutOrder = self:GetOrder(),
            library:Create("TextLabel", {
                Name               = name,
                Text               = "\r" .. name,
                BackgroundTransparency = 1,
                TextColor3         = library.options.textcolor,
                Position           = UDim2.new(0, 5, 0, 0),
                Size               = UDim2.new(1, -5, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
                Font               = library.options.font,
                TextSize           = library.options.fontsize,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3   = library.options.strokecolor,
                library:Create("TextButton", {
                    Text             = location[flag] and utf8.char(10003) or "",
                    Font             = library.options.font,
                    TextSize         = library.options.fontsize,
                    Name             = "Checkmark",
                    Size             = UDim2.new(0, 20, 0, 20),
                    Position         = UDim2.new(1, -25, 0, 4),
                    TextColor3       = library.options.textcolor,
                    BackgroundColor3 = library.options.bgcolor,
                    BorderColor3     = library.options.bordercolor,
                    TextStrokeTransparency = library.options.textstroke,
                    TextStrokeColor3 = library.options.strokecolor,
                }),
            }),
            Parent = self.container,
        })

        local function click()
            pcall(function()
                location[flag] = not location[flag]
                check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or ""
                callback(location[flag])
            end)
        end

        check:FindFirstChild(name).Checkmark.MouseButton1Click:Connect(click)
        library.callbacks[flag] = click

        if location[flag] == true then
            pcall(function() callback(location[flag]) end)
        end

        self:Resize()

        obj.Set = function(_, b)
            pcall(function()
                location[flag] = b
                check:FindFirstChild(name).Checkmark.Text = b and utf8.char(10003) or ""
                callback(b)
            end)
        end
    end)
    return obj
end

-- ──────────────────────────────
--  BUTTON
-- ──────────────────────────────
function types:Button(name, callback)
    callback = callback or function() end
    local obj = {}
    pcall(function()
        local check = library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 25),
            LayoutOrder = self:GetOrder(),
            library:Create("TextButton", {
                Name             = name,
                Text             = name,
                BackgroundColor3 = library.options.btncolor,
                BorderColor3     = library.options.bordercolor,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3 = library.options.strokecolor,
                TextColor3       = library.options.textcolor,
                Position         = UDim2.new(0, 5, 0, 5),
                Size             = UDim2.new(1, -10, 0, 20),
                Font             = library.options.font,
                TextSize         = library.options.fontsize,
            }),
            Parent = self.container,
        })

        check:FindFirstChild(name).MouseButton1Click:Connect(function()
            pcall(callback)
        end)

        -- hover highlight
        check:FindFirstChild(name).MouseEnter:Connect(function()
            pcall(function()
                check:FindFirstChild(name).BackgroundColor3 = Color3.new(
                    library.options.btncolor.R + 0.08,
                    library.options.btncolor.G + 0.08,
                    library.options.btncolor.B + 0.08
                )
            end)
        end)
        check:FindFirstChild(name).MouseLeave:Connect(function()
            pcall(function()
                check:FindFirstChild(name).BackgroundColor3 = library.options.btncolor
            end)
        end)

        self:Resize()
        obj.Fire = function() pcall(callback) end
    end)
    return obj
end

-- ──────────────────────────────
--  BOX
-- ──────────────────────────────
function types:Box(name, options, callback)
    options  = options  or {}
    callback = callback or function() end
    local type_    = options.type     or ""
    local default  = options.default  or ""
    local location = options.location or self.flags
    local flag     = options.flag     or ""
    local min_     = options.min      or 0
    local max_     = options.max      or 9e9

    if type_ == "number" and tonumber(default) then
        location[flag] = tonumber(default)
    else
        location[flag] = default
        if type_ == "number" then default = "" end
    end

    local boxRef = nil
    pcall(function()
        local check = library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 25),
            LayoutOrder = self:GetOrder(),
            library:Create("TextLabel", {
                Name               = name,
                Text               = "\r" .. name,
                BackgroundTransparency = 1,
                TextColor3         = library.options.textcolor,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3   = library.options.strokecolor,
                Position           = UDim2.new(0, 5, 0, 0),
                Size               = UDim2.new(1, -5, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
                Font               = library.options.font,
                TextSize           = library.options.fontsize,
                library:Create("TextBox", {
                    TextStrokeTransparency = library.options.textstroke,
                    TextStrokeColor3   = library.options.strokecolor,
                    Text               = tostring(default),
                    Font               = library.options.font,
                    TextSize           = library.options.fontsize,
                    Name               = "Box",
                    Size               = UDim2.new(0, 60, 0, 20),
                    Position           = UDim2.new(1, -65, 0, 3),
                    TextColor3         = library.options.textcolor,
                    BackgroundColor3   = library.options.boxcolor,
                    BorderColor3       = library.options.bordercolor,
                    PlaceholderColor3  = library.options.placeholdercolor,
                    ClearTextOnFocus   = false,
                }),
            }),
            Parent = self.container,
        })

        local box = check:FindFirstChild(name):FindFirstChild("Box")
        boxRef    = box

        box.FocusLost:Connect(function(e)
            pcall(function()
                local old = location[flag]
                if type_ == "number" then
                    local num = tonumber(box.Text)
                    if not num then
                        box.Text = tostring(location[flag])
                    else
                        location[flag] = math.clamp(num, min_, max_)
                        box.Text = tostring(location[flag])
                    end
                else
                    location[flag] = tostring(box.Text)
                end
                callback(location[flag], old, e)
            end)
        end)

        if type_ == "number" then
            box:GetPropertyChangedSignal("Text"):Connect(function()
                pcall(function()
                    box.Text = string.gsub(box.Text, "[^%d%.%-]", "")
                end)
            end)
        end

        self:Resize()
    end)
    return boxRef
end

-- ──────────────────────────────
--  SLIDER
-- ──────────────────────────────
function types:Slider(name, options, callback)
    options  = options  or {}
    callback = callback or function() end
    local default  = options.default  or options.min or 0
    local min_     = options.min      or 0
    local max_     = options.max      or 1
    local location = options.location or self.flags
    local precise  = options.precise  or false
    local flag     = options.flag     or ""
    location[flag] = default

    local obj = {}
    pcall(function()
        local check = library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 25),
            LayoutOrder = self:GetOrder(),
            library:Create("TextLabel", {
                Name               = name,
                Text               = "\r" .. name,
                BackgroundTransparency = 1,
                TextColor3         = library.options.textcolor,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3   = library.options.strokecolor,
                Position           = UDim2.new(0, 5, 0, 2),
                Size               = UDim2.new(1, -5, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
                Font               = library.options.font,
                TextSize           = library.options.fontsize,
                library:Create("Frame", {
                    Name             = "Container",
                    Size             = UDim2.new(0, 60, 0, 20),
                    Position         = UDim2.new(1, -65, 0, 3),
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    library:Create("TextLabel", {
                        Name           = "ValueLabel",
                        Text           = tostring(default),
                        BackgroundTransparency = 1,
                        TextColor3     = library.options.textcolor,
                        Position       = UDim2.new(0, -10, 0, 0),
                        Size           = UDim2.new(0, 1, 1, 0),
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Font           = library.options.font,
                        TextSize       = library.options.fontsize,
                        TextStrokeTransparency = library.options.textstroke,
                        TextStrokeColor3 = library.options.strokecolor,
                    }),
                    library:Create("TextButton", {
                        Name             = "Button",
                        Size             = UDim2.new(0, 5, 1, -2),
                        Position         = UDim2.new(0, 0, 0, 1),
                        AutoButtonColor  = false,
                        Text             = "",
                        BackgroundColor3 = library.options.textcolor,  -- fixed: use textcolor for knob
                        BorderSizePixel  = 0,
                        ZIndex           = 2,
                    }),
                    library:Create("Frame", {
                        Name             = "Line",
                        BackgroundTransparency = 0,
                        Position         = UDim2.new(0, 0, 0.5, 0),
                        Size             = UDim2.new(1, 0, 0, 1),
                        BackgroundColor3 = library.options.bordercolor,
                        BorderSizePixel  = 0,
                    }),
                }),
            }),
            Parent = self.container,
        })

        local overlay   = check:FindFirstChild(name)
        local container = overlay.Container
        local button    = container.Button
        local valLabel  = container.ValueLabel

        local sliding            = false
        local renderConn         = nil
        local inputBeganConn     = nil
        local inputEndedConn     = nil

        local function disconnect()
            pcall(function() if renderConn     then renderConn:Disconnect()     renderConn     = nil end end)
            pcall(function() if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end end)
            pcall(function() if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end end)
            sliding = false
        end

        local function updateFromMouse()
            pcall(function()
                local mloc    = UIS:GetMouseLocation()
                local pct     = (mloc.X - container.AbsolutePosition.X) / container.AbsoluteSize.X
                pct           = math.clamp(pct, 0, 1)
                local raw     = min_ + (max_ - min_) * pct
                local value   = precise and tonumber(string.format("%.2f", raw)) or math.floor(raw)

                button.Position    = UDim2.new(math.clamp(pct, 0, 0.98), 0, 0, 1)
                valLabel.Text      = tostring(value)
                location[flag]     = value
                pcall(callback, value)
            end)
        end

        -- Start drag
        inputBeganConn = container.InputBegan:Connect(function(input)
            pcall(function()
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding    = true
                    renderConn = RunService.Heartbeat:Connect(function()
                        if sliding then
                            updateFromMouse()
                        else
                            disconnect()
                        end
                    end)
                end
            end)
        end)

        -- End drag
        inputEndedConn = UIS.InputEnded:Connect(function(input)
            pcall(function()
                if input.UserInputType == Enum.UserInputType.MouseButton1 and sliding then
                    disconnect()
                end
            end)
        end)

        -- Set initial position
        if default ~= min_ then
            pcall(function()
                local pct   = (default - min_) / (max_ - min_)
                pct         = math.clamp(pct, 0, 0.98)
                local value = precise and tonumber(string.format("%.2f", default)) or math.floor(default)
                button.Position = UDim2.new(pct, 0, 0, 1)
                valLabel.Text   = tostring(value)
            end)
        end

        self:Resize()

        obj.Set = function(_, value)
            pcall(function()
                local pct   = (value - min_) / (max_ - min_)
                pct         = math.clamp(pct, 0, 0.98)
                local disp  = precise and tonumber(string.format("%.2f", value)) or math.floor(value)
                button.Position = UDim2.new(pct, 0, 0, 1)
                valLabel.Text   = tostring(disp)
                location[flag]  = value
                pcall(callback, value)
            end)
        end
    end)
    return obj
end

-- ──────────────────────────────
--  BIND
-- ──────────────────────────────
function types:Bind(name, options, callback)
    options  = options  or {}
    callback = callback or function() end
    local location     = options.location or self.flags
    local keyboardOnly = options.kbonly   or false
    local flag         = options.flag     or ""
    local default      = options.default

    if keyboardOnly and default and not tostring(default):find("MouseButton") then
        location[flag] = default
    end

    local banned = { Return=true, Space=true, Tab=true, Unknown=true }
    local shortNames = {
        RightControl = "RCtrl", LeftControl = "LCtrl",
        LeftShift = "LShift", RightShift = "RShift",
        MouseButton1 = "M1",  MouseButton2 = "M2",
    }
    local allowed = { MouseButton1=true, MouseButton2=true }

    local nm = default and (shortNames[default.Name] or default.Name) or "None"

    pcall(function()
        local check = library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 30),
            LayoutOrder = self:GetOrder(),
            library:Create("TextLabel", {
                Name               = name,
                Text               = "\r" .. name,
                BackgroundTransparency = 1,
                TextColor3         = library.options.textcolor,
                Position           = UDim2.new(0, 5, 0, 0),
                Size               = UDim2.new(1, -5, 1, 0),
                TextXAlignment     = Enum.TextXAlignment.Left,
                Font               = library.options.font,
                TextSize           = library.options.fontsize,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3   = library.options.strokecolor,
                library:Create("TextButton", {
                    Name             = "Keybind",
                    Text             = nm,
                    TextStrokeTransparency = library.options.textstroke,
                    TextStrokeColor3 = library.options.strokecolor,
                    Font             = library.options.font,
                    TextSize         = library.options.fontsize,
                    Size             = UDim2.new(0, 60, 0, 20),
                    Position         = UDim2.new(1, -65, 0, 5),
                    TextColor3       = library.options.textcolor,
                    BackgroundColor3 = library.options.bgcolor,
                    BorderColor3     = library.options.bordercolor,
                }),
            }),
            Parent = self.container,
        })

        local button = check:FindFirstChild(name).Keybind
        button.MouseButton1Click:Connect(function()
            pcall(function()
                library.binding = true
                button.Text     = "..."
                local inp       = UIS.InputBegan:Wait()
                local kname     = tostring(inp.KeyCode.Name)
                local tname     = tostring(inp.UserInputType.Name)

                if (inp.UserInputType ~= Enum.UserInputType.Keyboard and allowed[tname] and not keyboardOnly)
                    or (inp.KeyCode and not banned[kname]) then
                    local bname = inp.UserInputType ~= Enum.UserInputType.Keyboard and tname or kname
                    location[flag] = inp
                    button.Text    = shortNames[bname] or bname
                else
                    -- restore previous
                    if location[flag] then
                        pcall(function()
                            local prev = location[flag]
                            local pname = prev.UserInputType ~= Enum.UserInputType.Keyboard
                                and prev.UserInputType.Name or prev.KeyCode.Name
                            button.Text = shortNames[pname] or pname
                        end)
                    end
                end

                task.wait(0.1)
                library.binding = false
            end)
        end)

        if location[flag] then
            pcall(function()
                local prev  = location[flag]
                local pname = typeof(prev) == "Instance"
                    and (prev.UserInputType ~= Enum.UserInputType.Keyboard and prev.UserInputType.Name or prev.KeyCode.Name)
                    or tostring(prev)
                button.Text = shortNames[pname] or pname
            end)
        end

        library.binds[flag] = { location=location, callback=callback }
        self:Resize()
    end)
end

-- ──────────────────────────────
--  DROPDOWN
-- ──────────────────────────────
function types:Dropdown(name, options, callback)
    options  = options  or {}
    callback = callback or function() end
    local location = options.location or self.flags
    local flag     = options.flag     or ""
    local list     = options.list     or {}
    location[flag] = list[1]

    local check, container, inputConn
    pcall(function()
        check = library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = Color3.fromRGB(25,25,25),
            BorderSizePixel  = 0,
            LayoutOrder = self:GetOrder(),
            library:Create("Frame", {
                Name             = "dropdown_lbl",
                BackgroundTransparency = 0,
                BackgroundColor3 = library.options.dropcolor,
                Position         = UDim2.new(0, 5, 0, 4),
                BorderColor3     = library.options.bordercolor,
                Size             = UDim2.new(1, -10, 0, 20),
                library:Create("TextLabel", {
                    Name               = "Selection",
                    Size               = UDim2.new(1, 0, 1, 0),
                    Text               = list[1] or "",
                    TextColor3         = library.options.textcolor,
                    BackgroundTransparency = 1,
                    Font               = library.options.font,
                    TextSize           = library.options.fontsize,
                    TextStrokeTransparency = library.options.textstroke,
                    TextStrokeColor3   = library.options.strokecolor,
                }),
                library:Create("TextButton", {
                    Name             = "drop",
                    BackgroundTransparency = 1,
                    Size             = UDim2.new(0, 20, 1, 0),
                    Position         = UDim2.new(1, -25, 0, 0),
                    Text             = "v",
                    TextColor3       = library.options.textcolor,
                    Font             = library.options.font,
                    TextSize         = library.options.fontsize,
                    TextStrokeTransparency = library.options.textstroke,
                    TextStrokeColor3 = library.options.strokecolor,
                }),
            }),
            Parent = self.container,
        })

        local lbl    = check.dropdown_lbl
        local button = lbl.drop

        button.MouseButton1Click:Connect(function()
            pcall(function()
                if inputConn and inputConn.Connected then return end

                lbl.Selection.TextColor3 = Color3.fromRGB(60,60,60)
                lbl.Selection.Text       = name

                -- count items
                local totalH = #list * 20
                local scrollH = totalH > 100 and 5 or 0
                local displayH = math.min(totalH, 100)

                if container then pcall(function() container:Destroy() end) end
                container = library:Create("ScrollingFrame", {
                    TopImage    = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    Name        = "DropContainer",
                    Parent      = lbl,
                    Size        = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = library.options.bgcolor,
                    BorderColor3     = library.options.bordercolor,
                    Position         = UDim2.new(0, 0, 1, 0),
                    ScrollBarThickness = scrollH,
                    CanvasSize       = UDim2.new(0, 0, 0, totalH),
                    ZIndex           = 5,
                    ClipsDescendants = true,
                    library:Create("UIListLayout", {
                        Name      = "List",
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                })

                for i, v in next, list do
                    local btn = library:Create("TextButton", {
                        Size             = UDim2.new(1, 0, 0, 20),
                        BackgroundColor3 = library.options.btncolor,
                        BorderColor3     = library.options.bordercolor,
                        Text             = v,
                        Font             = library.options.font,
                        TextSize         = library.options.fontsize,
                        LayoutOrder      = i,
                        Parent           = container,
                        ZIndex           = 5,
                        TextColor3       = library.options.textcolor,
                        TextStrokeTransparency = library.options.textstroke,
                        TextStrokeColor3 = library.options.strokecolor,
                    })
                    btn.MouseButton1Click:Connect(function()
                        pcall(function()
                            lbl.Selection.TextColor3 = library.options.textcolor
                            lbl.Selection.Text       = btn.Text
                            location[flag]           = btn.Text
                            callback(location[flag])
                            container:TweenSize(UDim2.new(1,0,0,0),"In","Quint",0.25,true)
                            task.wait(0.26)
                            pcall(function() container:Destroy() end)
                            if inputConn then pcall(function() inputConn:Disconnect() end) end
                        end)
                    end)
                end

                container:TweenSize(UDim2.new(1,0,0,displayH),"Out","Quint",0.25,true)

                inputConn = UIS.InputBegan:Connect(function(a)
                    pcall(function()
                        if a.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                        local mloc  = UIS:GetMouseLocation()
                        local mx,my = mloc.X, mloc.Y - 36
                        local ap    = container.AbsolutePosition
                        local as_   = container.AbsoluteSize
                        local inside = mx >= ap.X and mx <= ap.X+as_.X and my >= ap.Y and my <= ap.Y+as_.Y
                        if not inside then
                            lbl.Selection.TextColor3 = library.options.textcolor
                            lbl.Selection.Text       = location[flag] or ""
                            container:TweenSize(UDim2.new(1,0,0,0),"In","Quint",0.25,true)
                            task.wait(0.26)
                            pcall(function() container:Destroy() end)
                            inputConn:Disconnect()
                        end
                    end)
                end)
            end)
        end)

        self:Resize()
    end)

    return {
        Refresh = function(_, newList)
            pcall(function()
                list = newList
                location[flag] = newList[1]
                if inputConn then pcall(function() inputConn:Disconnect() end) end
                if container  then pcall(function() container:Destroy()   end) end
                check.dropdown_lbl.Selection.Text       = location[flag] or ""
                check.dropdown_lbl.Selection.TextColor3 = library.options.textcolor
            end)
        end
    }
end

-- ──────────────────────────────
--  SEARCHBOX
-- ──────────────────────────────
function types:SearchBox(text, options, callback)
    options  = options  or {}
    callback = callback or function() end
    local list     = options.list     or {}
    local flag     = options.flag     or ""
    local location = options.location or self.flags

    local busy   = false
    local boxInst = nil
    pcall(function()
        local frame = library:Create("Frame", {
            BackgroundTransparency = 1,
            Size        = UDim2.new(1, 0, 0, 25),
            LayoutOrder = self:GetOrder(),
            library:Create("TextBox", {
                Text             = "",
                PlaceholderText  = text,
                PlaceholderColor3 = library.options.placeholdercolor,
                Font             = library.options.font,
                TextSize         = library.options.fontsize,
                Name             = "Box",
                Size             = UDim2.new(1, -10, 0, 20),
                Position         = UDim2.new(0, 5, 0, 4),
                TextColor3       = library.options.textcolor,
                BackgroundColor3 = library.options.dropcolor,
                BorderColor3     = library.options.bordercolor,
                TextStrokeTransparency = library.options.textstroke,
                TextStrokeColor3 = library.options.strokecolor,
                library:Create("ScrollingFrame", {
                    Position         = UDim2.new(0, 0, 1, 1),
                    Name             = "Container",
                    BackgroundColor3 = library.options.btncolor,
                    ScrollBarThickness = 0,
                    BorderSizePixel  = 0,
                    BorderColor3     = library.options.bordercolor,
                    Size             = UDim2.new(1, 0, 0, 0),
                    ZIndex           = 6,
                    library:Create("UIListLayout", {
                        Name      = "ListLayout",
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }),
                }),
            }),
            Parent = self.container,
        })

        local box  = frame.Box
        local cont = box.Container
        boxInst    = box

        local function rebuild(query)
            pcall(function()
                cont.ScrollBarThickness = 0
                for _, child in next, cont:GetChildren() do
                    if not child:IsA("UIListLayout") then child:Destroy() end
                end

                if #query > 0 then
                    for _, v in next, list do
                        if string.lower(v):sub(1, #query) == string.lower(query) then
                            local btn = library:Create("TextButton", {
                                Text             = v,
                                Font             = library.options.font,
                                TextSize         = library.options.fontsize,
                                TextColor3       = library.options.textcolor,
                                BorderColor3     = library.options.bordercolor,
                                TextStrokeTransparency = library.options.textstroke,
                                TextStrokeColor3 = library.options.strokecolor,
                                Parent           = cont,
                                Size             = UDim2.new(1, 0, 0, 20),
                                BackgroundColor3 = library.options.btncolor,
                                ZIndex           = 6,
                            })
                            btn.MouseButton1Click:Connect(function()
                                pcall(function()
                                    busy    = true
                                    box.Text = btn.Text
                                    task.wait()
                                    busy    = false
                                    location[flag] = btn.Text
                                    callback(location[flag])
                                    for _, c in next, cont:GetChildren() do
                                        if not c:IsA("UIListLayout") then c:Destroy() end
                                    end
                                    cont:TweenSize(UDim2.new(1,0,0,0),"Out","Quint",0.2,true)
                                end)
                            end)
                        end
                    end
                end

                local children = cont:GetChildren()
                local count    = #children - 1  -- exclude UIListLayout
                local rawY     = count * 20
                local clampY   = math.clamp(rawY, 0, 100)
                if rawY > 100 then cont.ScrollBarThickness = 4 end
                cont.CanvasSize = UDim2.new(1, 0, 0, rawY)
                cont:TweenSize(UDim2.new(1, 0, 0, clampY), "Out", "Quint", 0.2, true)
            end)
        end

        box:GetPropertyChangedSignal("Text"):Connect(function()
            if not busy then pcall(function() rebuild(box.Text) end) end
        end)

        self:Resize()
    end)

    local function reload(newList)
        pcall(function() list = newList end)
    end
    return reload, boxInst
end

-- ──────────────────────────────
--  COLOR SETTINGS  (new)
-- ──────────────────────────────
function types:ColorSettings()
    pcall(function()
        self:Section("Themes")

        local themeNames = {}
        for k in pairs(library.themes) do
            table.insert(themeNames, k)
        end
        table.sort(themeNames)

        self:Dropdown("Preset Theme", {
            list  = themeNames,
            flag  = "_theme_preset",
            location = {},  -- isolated flags
        }, function(chosen)
            pcall(function() library:SetTheme(chosen) end)
        end)

        self:Section("Accent Color")

        local accentPresets = {
            "Green   #00FF8C",
            "Purple  #6450EB",
            "Cyan    #00C8FF",
            "Red     #DC283C",
            "Gold    #DCAF1E",
            "White   #FFFFFF",
            "Rainbow",
        }
        local accentMap = {
            ["Green   #00FF8C"] = Color3.fromRGB(0,   255, 140),
            ["Purple  #6450EB"] = Color3.fromRGB(100, 80,  235),
            ["Cyan    #00C8FF"] = Color3.fromRGB(0,   200, 255),
            ["Red     #DC283C"] = Color3.fromRGB(220, 40,  60),
            ["Gold    #DCAF1E"] = Color3.fromRGB(220, 175, 30),
            ["White   #FFFFFF"] = Color3.fromRGB(255, 255, 255),
            ["Rainbow"]         = "rainbow",
        }

        self:Dropdown("Accent Color", {
            list  = accentPresets,
            flag  = "_accent_color",
            location = {},
        }, function(chosen)
            pcall(function()
                local col = accentMap[chosen]
                library.options.underlinecolor = col
                for _, wdata in pairs(library._windows) do
                    pcall(function()
                        local ul = wdata.object:FindFirstChild("Underline")
                        if ul then
                            if col == "rainbow" then
                                ul.BackgroundColor3 = Color3.new()
                                table.insert(library.rainbowtable, ul)
                            else
                                ul.BackgroundColor3 = col
                                -- remove from rainbow table if present
                                for i = #library.rainbowtable, 1, -1 do
                                    if library.rainbowtable[i] == ul then
                                        table.remove(library.rainbowtable, i)
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end)
    end)
end

-- ════════════════════════════════
--  NOTIFY  (new)
-- ════════════════════════════════
function library:Notify(title, text, duration)
    pcall(function()
        duration = duration or 3
        local sg = self.container and self.container.Parent
        if not sg then return end

        local notif = self:Create("Frame", {
            Size             = UDim2.new(0, 200, 0, 0),
            Position         = UDim2.new(1, -210, 1, -10),
            BackgroundColor3 = library.options.topcolor,
            BorderSizePixel  = 0,
            AutomaticSize    = Enum.AutomaticSize.Y,
            Parent           = sg,
            ZIndex           = 10,
            self:Create("Frame", {
                Name             = "Underline",
                Size             = UDim2.new(1, 0, 0, 2),
                Position         = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = library.options.underlinecolor ~= "rainbow"
                    and library.options.underlinecolor or Color3.fromRGB(255,255,255),
                BorderSizePixel  = 0,
                ZIndex           = 10,
            }),
            self:Create("TextLabel", {
                Text             = title,
                Size             = UDim2.new(1, -10, 0, 22),
                Position         = UDim2.new(0, 5, 0, 5),
                BackgroundTransparency = 1,
                Font             = library.options.titlefont,
                TextSize         = library.options.titlesize - 2,
                TextColor3       = library.options.titletextcolor,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 10,
            }),
            self:Create("TextLabel", {
                Text             = text,
                Size             = UDim2.new(1, -10, 0, 30),
                Position         = UDim2.new(0, 5, 0, 26),
                BackgroundTransparency = 1,
                Font             = library.options.font,
                TextSize         = library.options.fontsize - 2,
                TextColor3       = library.options.textcolor,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
                ZIndex           = 10,
            }),
        })

        if library.options.underlinecolor == "rainbow" then
            table.insert(library.rainbowtable, notif:FindFirstChild("Underline"))
        end

        notif:TweenPosition(UDim2.new(1,-210,1,-notif.AbsoluteSize.Y-10),"Out","Quint",0.3,true)
        task.delay(duration, function()
            pcall(function()
                notif:TweenPosition(UDim2.new(1,10,1,-notif.AbsoluteSize.Y-10),"In","Quint",0.3,true)
                task.wait(0.35)
                notif:Destroy()
            end)
        end)
    end)
end

-- ════════════════════════════════
--  WINDOW FACTORY
-- ════════════════════════════════
local function buildWindow(name, opts)
    library.count = library.count + 1
    local newWindow = library:Create("Frame", {
        Name             = name,
        Size             = UDim2.new(0, 190, 0, 30),
        BackgroundColor3 = opts.topcolor,
        BorderSizePixel  = 0,
        Parent           = library.container,
        Position         = UDim2.new(0, 15 + (200 * library.count) - 200, 0, 0),
        ZIndex           = 3,
        library:Create("TextLabel", {
            Text           = name,
            Size           = UDim2.new(1, -40, 1, 0),
            Position       = UDim2.new(0, 5, 0, 0),
            BackgroundTransparency = 1,
            Font           = opts.titlefont,
            TextSize       = opts.titlesize,
            TextColor3     = opts.titletextcolor,
            TextStrokeTransparency = opts.titlestroke,
            TextStrokeColor3 = opts.titlestrokecolor,
            ZIndex         = 3,
        }),
        library:Create("TextButton", {
            Size           = UDim2.new(0, 30, 0, 30),
            Position       = UDim2.new(1, -35, 0, 0),
            BackgroundTransparency = 1,
            Text           = "-",
            TextSize       = opts.titlesize,
            Font           = opts.titlefont,
            Name           = "window_toggle",
            TextColor3     = opts.titletextcolor,
            TextStrokeTransparency = opts.titlestroke,
            TextStrokeColor3 = opts.titlestrokecolor,
            ZIndex         = 3,
        }),
        library:Create("Frame", {
            Name             = "Underline",
            Size             = UDim2.new(1, 0, 0, 2),
            Position         = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = (opts.underlinecolor ~= "rainbow" and opts.underlinecolor or Color3.new()),
            BorderSizePixel  = 0,
            ZIndex           = 3,
        }),
        library:Create("Frame", {
            Name             = "container",
            Position         = UDim2.new(0, 0, 1, 0),
            Size             = UDim2.new(1, 0, 0, 0),
            BorderSizePixel  = 0,
            BackgroundColor3 = opts.bgcolor,
            ClipsDescendants = false,
            library:Create("UIListLayout", {
                Name      = "List",
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        }),
    })

    if opts.underlinecolor == "rainbow" then
        table.insert(library.rainbowtable, newWindow:FindFirstChild("Underline"))
    end

    local window = setmetatable({
        count     = 0,
        object    = newWindow,
        container = newWindow.container,
        toggled   = true,
        flags     = {},
    }, types)

    table.insert(library.queue, { w=newWindow, p=newWindow.Position })
    table.insert(library._windows, { object=newWindow })

    -- Collapse toggle
    newWindow:FindFirstChild("window_toggle").MouseButton1Click:Connect(function()
        pcall(function()
            window.toggled = not window.toggled
            newWindow:FindFirstChild("window_toggle").Text = window.toggled and "-" or "+"
            if not window.toggled then
                window.container.ClipsDescendants = true
            end
            local y = 0
            for _, v in next, window.container:GetChildren() do
                if not v:IsA("UIListLayout") then y = y + v.AbsoluteSize.Y end
            end
            local targetSize = window.toggled and UDim2.new(1,0,0,y+5) or UDim2.new(1,0,0,0)
            window.container:TweenSize(targetSize, window.toggled and "In" or "Out", "Quint", 0.28, true)
            task.wait(0.3)
            if window.toggled then window.container.ClipsDescendants = false end
        end)
    end)

    return window
end

-- ════════════════════════════════
--  CreateWindow  (public API)
-- ════════════════════════════════
function library:CreateWindow(name, options)
    pcall(function()
        if not library.container then
            local sg = library:Create("ScreenGui", {
                ResetOnSpawn   = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder   = 999,
                library:Create("Frame", {
                    Name             = "Container",
                    Size             = UDim2.new(1, -30, 1, 0),
                    Position         = UDim2.new(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    Active           = false,
                }),
                Parent = GuiParent(),
            })
            library.container = sg:FindFirstChild("Container")
        end
    end)

    -- Merge user options with defaults
    pcall(function()
        if options then
            library.options = setmetatable(options, {__index = default})
        else
            library.options = setmetatable({}, {__index = default})
        end
    end)

    local window
    pcall(function()
        window = buildWindow(name, library.options)
        makeDraggable(window.object)
    end)
    return window
end

return library
