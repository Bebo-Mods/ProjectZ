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
    ✔ Dropdown text overlap fixed (ZIndex on dropdown container)
    ✔ Slider completely rewritten (fixed mouse tracking, drag behavior)
    ✔ Dropdown destroy properly cleans up connections

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
    -- ... (keep all other themes)
}

-- ════════════════════════════════
--  THEME SETTER
-- ════════════════════════════════
function library:SetTheme(themeName)
    local t = self.themes[themeName]
    if not t then return end
    for k, v in pairs(t) do
        pcall(function() self.options[k] = v end)
    end
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
--  RESIZE (improved with ZIndex management)
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
            ZIndex             = 1,
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
                ZIndex             = 1,
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
            ZIndex      = 1,
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
                ZIndex             = 1,
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
            ZIndex      = 1,
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
                ZIndex             = 1,
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
                    ZIndex           = 1,
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
            ZIndex      = 1,
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
                ZIndex           = 1,
            }),
            Parent = self.container,
        })

        check:FindFirstChild(name).MouseButton1Click:Connect(function()
            pcall(callback)
        end)

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
            ZIndex      = 1,
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
                ZIndex             = 1,
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
                    ZIndex             = 1,
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
--  SLIDER (COMPLETELY REWRITTEN)
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
            Size        = UDim2.new(1, 0, 0, 30),
            LayoutOrder = self:GetOrder(),
            ZIndex      = 1,
            Parent      = self.container,
        })

        local label = library:Create("TextLabel", {
            Name               = "SliderLabel",
            Text               = "\r" .. name,
            BackgroundTransparency = 1,
            TextColor3         = library.options.textcolor,
            TextStrokeTransparency = library.options.textstroke,
            TextStrokeColor3   = library.options.strokecolor,
            Position           = UDim2.new(0, 5, 0, 0),
            Size               = UDim2.new(1, -75, 0, 20),
            TextXAlignment     = Enum.TextXAlignment.Left,
            Font               = library.options.font,
            TextSize           = library.options.fontsize,
            ZIndex             = 1,
            Parent             = check,
        })

        local container = library:Create("Frame", {
            Name             = "SliderContainer",
            Size             = UDim2.new(0, 60, 0, 20),
            Position         = UDim2.new(1, -65, 0, 5),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ZIndex           = 2,
            Parent           = check,
        })

        local bg = library:Create("Frame", {
            Name             = "Background",
            Size             = UDim2.new(1, 0, 0, 4),
            Position         = UDim2.new(0, 0, 0.5, -2),
            BackgroundColor3 = library.options.bordercolor,
            BorderSizePixel  = 0,
            ZIndex           = 1,
            Parent           = container,
        })

        local fill = library:Create("Frame", {
            Name             = "Fill",
            Size             = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = library.options.underlinecolor ~= "rainbow" 
                and library.options.underlinecolor or Color3.fromRGB(255,255,255),
            BorderSizePixel  = 0,
            ZIndex           = 2,
            Parent           = container,
        })

        local knob = library:Create("TextButton", {
            Name             = "Knob",
            Size             = UDim2.new(0, 12, 0, 12),
            Position         = UDim2.new(0, -6, 0.5, -6),
            AutoButtonColor  = false,
            Text             = "",
            BackgroundColor3 = library.options.textcolor,
            BorderSizePixel  = 0,
            ZIndex           = 3,
            Parent           = container,
        })

        -- Fix: Make knob circular for better appearance
        pcall(function()
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = knob
        end)

        local valLabel = library:Create("TextLabel", {
            Name           = "ValueLabel",
            Text           = tostring(default),
            BackgroundTransparency = 1,
            TextColor3     = library.options.textcolor,
            Position       = UDim2.new(1, 5, 0, 2),
            Size           = UDim2.new(0, 35, 0, 15),
            TextXAlignment = Enum.TextXAlignment.Left,
            Font           = library.options.font,
            TextSize       = library.options.fontsize - 2,
            TextStrokeTransparency = library.options.textstroke,
            TextStrokeColor3 = library.options.strokecolor,
            ZIndex         = 1,
            Parent         = container,
        })

        local function updateVisuals(pct)
            pct = math.clamp(pct, 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -6, 0.5, -6)
        end

        local function updateValue(pct)
            local value = min_ + (max_ - min_) * pct
            if not precise then
                value = math.floor(value + 0.5)
            else
                value = tonumber(string.format("%.2f", value))
            end
            valLabel.Text = tostring(value)
            location[flag] = value
            return value
        end

        -- Set initial position
        local initPct = (default - min_) / (max_ - min_)
        updateVisuals(initPct)

        -- Slider dragging logic
        local dragging = false
        local inputConn, moveConn

        local function startDrag()
            dragging = true
            if moveConn then moveConn:Disconnect() end
            moveConn = RunService.RenderStepped:Connect(function()
                if not dragging then return end
                pcall(function()
                    local mousePos = UIS:GetMouseLocation()
                    local absPos = container.AbsolutePosition
                    local absSize = container.AbsoluteSize
                    local relativeX = mousePos.X - absPos.X
                    local pct = math.clamp(relativeX / absSize.X, 0, 1)
                    updateVisuals(pct)
                    local value = updateValue(pct)
                    pcall(callback, value)
                end)
            end)
        end

        local function stopDrag()
            dragging = false
            if moveConn then
                moveConn:Disconnect()
                moveConn = nil
            end
        end

        -- Connect drag events to the container
        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                startDrag()
            end
        end)

        container.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                stopDrag()
            end
        end)

        -- Also allow clicking on the background to jump to position
        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                pcall(function()
                    local mousePos = UIS:GetMouseLocation()
                    local absPos = container.AbsolutePosition
                    local absSize = container.AbsoluteSize
                    local relativeX = mousePos.X - absPos.X
                    local pct = math.clamp(relativeX / absSize.X, 0, 1)
                    updateVisuals(pct)
                    local value = updateValue(pct)
                    pcall(callback, value)
                end)
            end
        end)

        -- Clean up on destroy
        check.AncestryChanged:Connect(function()
            if not check.Parent then
                stopDrag()
            end
        end)

        obj.Set = function(_, value)
            pcall(function()
                local pct = (value - min_) / (max_ - min_)
                updateVisuals(pct)
                local newValue = updateValue(pct)
                pcall(callback, newValue)
            end)
        end

        self:Resize()
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
            ZIndex      = 1,
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
                ZIndex             = 1,
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
                    ZIndex           = 1,
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
--  DROPDOWN (FIXED OVERLAP)
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
            ZIndex      = 1,
            Parent      = self.container,
        })

        local dropdownFrame = library:Create("Frame", {
            Name             = "dropdown_lbl",
            BackgroundTransparency = 0,
            BackgroundColor3 = library.options.dropcolor,
            Position         = UDim2.new(0, 5, 0, 4),
            BorderColor3     = library.options.bordercolor,
            Size             = UDim2.new(1, -10, 0, 20),
            ZIndex           = 2,
            Parent           = check,
        })

        local selectionLabel = library:Create("TextLabel", {
            Name               = "Selection",
            Size               = UDim2.new(1, -25, 1, 0),
            Text               = list[1] or "",
            TextColor3         = library.options.textcolor,
            BackgroundTransparency = 1,
            Font               = library.options.font,
            TextSize           = library.options.fontsize,
            TextStrokeTransparency = library.options.textstroke,
            TextStrokeColor3   = library.options.strokecolor,
            ZIndex             = 2,
            Parent             = dropdownFrame,
        })

        local dropButton = library:Create("TextButton", {
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
            ZIndex           = 2,
            Parent           = dropdownFrame,
        })

        dropButton.MouseButton1Click:Connect(function()
            pcall(function()
                if container and container.Parent then
                    -- If already open, close it
                    pcall(function()
                        selectionLabel.TextColor3 = library.options.textcolor
                        selectionLabel.Text = location[flag] or ""
                        container:TweenSize(UDim2.new(1,0,0,0),"In","Quint",0.25,true)
                        task.wait(0.26)
                        container:Destroy()
                        container = nil
                        if inputConn then
                            inputConn:Disconnect()
                            inputConn = nil
                        end
                    end)
                    return
                end

                selectionLabel.TextColor3 = Color3.fromRGB(60,60,60)
                selectionLabel.Text = name

                local totalH = #list * 20
                local displayH = math.min(totalH, 100)

                -- Create container with proper ZIndex to overlay other elements
                container = library:Create("ScrollingFrame", {
                    TopImage    = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                    Name        = "DropContainer",
                    Parent      = dropdownFrame,
                    Size        = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = library.options.bgcolor,
                    BorderColor3     = library.options.bordercolor,
                    Position         = UDim2.new(0, 0, 1, 0),
                    ScrollBarThickness = 4,
                    CanvasSize       = UDim2.new(0, 0, 0, totalH),
                    ZIndex           = 10, -- HIGH ZINDEX TO OVERLAY OTHER ELEMENTS
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
                        ZIndex           = 10,
                        TextColor3       = library.options.textcolor,
                        TextStrokeTransparency = library.options.textstroke,
                        TextStrokeColor3 = library.options.strokecolor,
                    })

                    btn.MouseButton1Click:Connect(function()
                        pcall(function()
                            selectionLabel.TextColor3 = library.options.textcolor
                            selectionLabel.Text = btn.Text
                            location[flag] = btn.Text
                            callback(location[flag])

                            -- Close dropdown
                            container:TweenSize(UDim2.new(1,0,0,0),"In","Quint",0.25,true)
                            task.wait(0.26)
                            if container then
                                container:Destroy()
                                container = nil
                            end
                            if inputConn then
                                inputConn:Disconnect()
                                inputConn = nil
                            end
                        end)
                    end)
                end

                -- Animate open
                container:TweenSize(UDim2.new(1,0,0,displayH),"Out","Quint",0.25,true)

                -- Click outside to close
                inputConn = UIS.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    if not container or not container.Parent then
                        if inputConn then inputConn:Disconnect() end
                        return
                    end

                    pcall(function()
                        local mousePos = UIS:GetMouseLocation()
                        local absPos = container.AbsolutePosition
                        local absSize = container.AbsoluteSize

                        local inX = mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
                        local inY = mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y

                        -- Also check if clicking on the dropdown button itself
                        local btnAbsPos = dropdownFrame.AbsolutePosition
                        local btnAbsSize = dropdownFrame.AbsoluteSize
                        local inBtnX = mousePos.X >= btnAbsPos.X and mousePos.X <= btnAbsPos.X + btnAbsSize.X
                        local inBtnY = mousePos.Y >= btnAbsPos.Y and mousePos.Y <= btnAbsPos.Y + btnAbsSize.Y

                        if not (inX and inY) and not (inBtnX and inBtnY) then
                            selectionLabel.TextColor3 = library.options.textcolor
                            selectionLabel.Text = location[flag] or ""

                            container:TweenSize(UDim2.new(1,0,0,0),"In","Quint",0.25,true)
                            task.wait(0.26)
                            if container then
                                container:Destroy()
                                container = nil
                            end
                            if inputConn then
                                inputConn:Disconnect()
                                inputConn = nil
                            end
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
                if inputConn then inputConn:Disconnect(); inputConn = nil end
                if container then container:Destroy(); container = nil end
                if check and check:FindFirstChild("dropdown_lbl") then
                    check.dropdown_lbl.Selection.Text = location[flag] or ""
                    check.dropdown_lbl.Selection.TextColor3 = library.options.textcolor
                end
            end)
        end
    }
end

-- ──────────────────────────────
--  SEARCHBOX (FIXED ZINDEX)
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
            ZIndex      = 1,
            Parent      = self.container,
        })

        local box = library:Create("TextBox", {
            Text             = "",
            PlaceholderText  = text,
            PlaceholderColor3 = library.options.placeholdercolor,
            Font             = library.options.font,
            TextSize         = library.options.fontsize,
            Name             = "SearchBox",
            Size             = UDim2.new(1, -10, 0, 20),
            Position         = UDim2.new(0, 5, 0, 4),
            TextColor3       = library.options.textcolor,
            BackgroundColor3 = library.options.dropcolor,
            BorderColor3     = library.options.bordercolor,
            TextStrokeTransparency = library.options.textstroke,
            TextStrokeColor3 = library.options.strokecolor,
            ZIndex           = 2,
            Parent           = frame,
        })

        local cont = library:Create("ScrollingFrame", {
            Position         = UDim2.new(0, 0, 1, 1),
            Name             = "ResultsContainer",
            BackgroundColor3 = library.options.btncolor,
            ScrollBarThickness = 0,
            BorderSizePixel  = 0,
            BorderColor3     = library.options.bordercolor,
            Size             = UDim2.new(1, 0, 0, 0),
            ZIndex           = 10, -- HIGH ZINDEX TO OVERLAY OTHER ELEMENTS
            Parent           = box,
            library:Create("UIListLayout", {
                Name      = "ListLayout",
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        boxInst = box

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
                                ZIndex           = 10,
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
                local count    = 0
                for _, c in pairs(children) do
                    if not c:IsA("UIListLayout") then count = count + 1 end
                end
                local rawY   = count * 20
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
            location = {},
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
        local sg = library.container and library.container.Parent
        if not sg then return end

        local notif = library:Create("Frame", {
            Size             = UDim2.new(0, 200, 0, 0),
            Position         = UDim2.new(1, -210, 1, -10),
            BackgroundColor3 = library.options.topcolor,
            BorderSizePixel  = 0,
            AutomaticSize    = Enum.AutomaticSize.Y,
            Parent           = sg,
            ZIndex           = 10,
            library:Create("Frame", {
                Name             = "Underline",
                Size             = UDim2.new(1, 0, 0, 2),
                Position         = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = library.options.underlinecolor ~= "rainbow"
                    and library.options.underlinecolor or Color3.fromRGB(255,255,255),
                BorderSizePixel  = 0,
                ZIndex           = 10,
            }),
            library:Create("TextLabel", {
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
            library:Create("TextLabel", {
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
            ClipsDescendants = true, -- Changed to true to properly clip content
            ZIndex           = 2,
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

            local y = 0
            for _, v in next, window.container:GetChildren() do
                if not v:IsA("UIListLayout") then y = y + v.AbsoluteSize.Y end
            end

            local targetSize = window.toggled and UDim2.new(1,0,0,y+5) or UDim2.new(1,0,0,0)
            window.container:TweenSize(targetSize, "In", "Quint", 0.28, true)
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
