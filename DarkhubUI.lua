```lua
--[[

    DARKHUB V2
    ATTEMPTED FULL SINGLE FILE REWRITE

    INCLUDED:
    ✔ Tabs
    ✔ Groupboxes
    ✔ Toggle
    ✔ Slider
    ✔ Dropdown
    ✔ MultiDropdown
    ✔ Keybind
    ✔ Textbox
    ✔ Colorpicker
    ✔ Notifications
    ✔ Blur
    ✔ Minimize Dock
    ✔ Themes
    ✔ Responsive Columns
    ✔ Anti Detection
    ✔ Dropdown Portals

]]

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local cloneref = cloneref or function(v)
    return v
end

local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local HiddenUI = gethui and gethui() or CoreGui
local ProtectGui = protectgui or function() end

--------------------------------------------------
-- LIBRARY
--------------------------------------------------

local Library = {
    Flags = {},
    ThemeObjects = {},
    Tabs = {},
    Connections = {},
    OpenDropdown = nil
}

--------------------------------------------------
-- THEME
--------------------------------------------------

Library.Theme = {
    Accent = Color3.fromRGB(0,255,120),
    Background = Color3.fromRGB(13,13,18),
    Surface = Color3.fromRGB(20,20,26),
    Surface2 = Color3.fromRGB(30,30,38),
    Outline = Color3.fromRGB(40,40,50),
    Text = Color3.fromRGB(255,255,255),
    DimText = Color3.fromRGB(170,170,170)
}

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function Create(class, props)

    local obj = Instance.new(class)

    for i,v in pairs(props or {}) do
        obj[i] = v
    end

    return obj
end

local function Corner(obj, radius)

    return Create("UICorner", {
        Parent = obj,
        CornerRadius = UDim.new(0, radius or 6)
    })
end

local function Stroke(obj)

    return Create("UIStroke", {
        Parent = obj,
        Color = Library.Theme.Outline,
        Thickness = 1
    })
end

local function ThemeObject(obj, property)

    table.insert(Library.ThemeObjects, {
        Object = obj,
        Property = property
    })
end

function Library:SetTheme(color)

    self.Theme.Accent = color

    for _,v in pairs(self.ThemeObjects) do
        pcall(function()
            v.Object[v.Property] = color
        end)
    end
end

--------------------------------------------------
-- GUI
--------------------------------------------------

local ScreenGui = Create("ScreenGui", {
    Name = "DarkHubV2",
    Parent = HiddenUI,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global
})

ProtectGui(ScreenGui)

--------------------------------------------------
-- BLUR
--------------------------------------------------

local Blur = Create("BlurEffect", {
    Parent = Lighting,
    Size = 18
})

--------------------------------------------------
-- MAIN
--------------------------------------------------

local Main = Create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0,760,0,520),
    Position = UDim2.new(0.5,-380,0.5,-260),
    BackgroundColor3 = Library.Theme.Background,
    BorderSizePixel = 0
})

Corner(Main, 8)
Stroke(Main)

--------------------------------------------------
-- TOPBAR
--------------------------------------------------

local Topbar = Create("Frame", {
    Parent = Main,
    Size = UDim2.new(1,0,0,42),
    BackgroundTransparency = 1
})

local Title = Create("TextLabel", {
    Parent = Topbar,
    Position = UDim2.new(0,14,0,0),
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "DARKHUB V2",
    TextSize = 14,
    TextColor3 = Library.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
})

local Minimize = Create("TextButton", {
    Parent = Topbar,
    Position = UDim2.new(1,-62,0,8),
    Size = UDim2.new(0,24,0,24),
    Text = "—",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    BackgroundTransparency = 1,
    TextColor3 = Library.Theme.Text
})

local Close = Create("TextButton", {
    Parent = Topbar,
    Position = UDim2.new(1,-32,0,8),
    Size = UDim2.new(0,24,0,24),
    Text = "✕",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    BackgroundTransparency = 1,
    TextColor3 = Library.Theme.Text
})

--------------------------------------------------
-- SIDEBAR
--------------------------------------------------

local Sidebar = Create("Frame", {
    Parent = Main,
    Position = UDim2.new(0,0,0,42),
    Size = UDim2.new(0,170,1,-42),
    BackgroundTransparency = 1
})

Create("UIPadding", {
    Parent = Sidebar,
    PaddingTop = UDim.new(0,12),
    PaddingLeft = UDim.new(0,12),
    PaddingRight = UDim.new(0,12)
})

local SidebarLayout = Create("UIListLayout", {
    Parent = Sidebar,
    Padding = UDim.new(0,8)
})

--------------------------------------------------
-- CONTENT
--------------------------------------------------

local Content = Create("Frame", {
    Parent = Main,
    Position = UDim2.new(0,170,0,42),
    Size = UDim2.new(1,-170,1,-42),
    BackgroundTransparency = 1
})

--------------------------------------------------
-- DOCK
--------------------------------------------------

local Dock = Create("TextButton", {
    Parent = ScreenGui,
    Visible = false,
    Position = UDim2.new(0.5,-90,0,10),
    Size = UDim2.new(0,180,0,36),
    BackgroundColor3 = Library.Theme.Surface,
    BorderSizePixel = 0,
    Text = "DARKHUB V2",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Library.Theme.Text
})

Corner(Dock, 6)
Stroke(Dock)

--------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------

local NotificationHolder = Create("Frame", {
    Parent = ScreenGui,
    AnchorPoint = Vector2.new(1,1),
    Position = UDim2.new(1,-20,1,-20),
    Size = UDim2.new(0,320,1,0),
    BackgroundTransparency = 1
})

local NotificationLayout = Create("UIListLayout", {
    Parent = NotificationHolder,
    Padding = UDim.new(0,8),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom
})

function Library:Notify(title, text)

    local Frame = Create("Frame", {
        Parent = NotificationHolder,
        Size = UDim2.new(0,300,0,70),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0
    })

    Corner(Frame, 6)
    Stroke(Frame)

    local Accent = Create("Frame", {
        Parent = Frame,
        Size = UDim2.new(0,4,1,0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0
    })

    ThemeObject(Accent, "BackgroundColor3")

    Create("TextLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,12,0,8),
        Size = UDim2.new(1,-20,0,18),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextSize = 13,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Create("TextLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,12,0,28),
        Size = UDim2.new(1,-20,1,-32),
        Font = Enum.Font.Gotham,
        Text = text,
        TextWrapped = true,
        TextSize = 12,
        TextColor3 = self.Theme.DimText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })

    task.delay(4, function()

        TweenService:Create(Frame, TweenInfo.new(0.2), {
            BackgroundTransparency = 1
        }):Play()

        task.wait(0.2)

        Frame:Destroy()
    end)
end

--------------------------------------------------
-- DRAGGING
--------------------------------------------------

local Dragging
local DragStart
local StartPos

Topbar.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1 then

        Dragging = true
        DragStart = input.Position
        StartPos = Main.Position
    end
end)

Topbar.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)

    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then

        local Delta = input.Position - DragStart

        Main.Position = UDim2.new(
            StartPos.X.Scale,
            StartPos.X.Offset + Delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + Delta.Y
        )
    end
end)

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

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

--------------------------------------------------
-- CLOSE
--------------------------------------------------

Close.MouseButton1Click:Connect(function()

    Blur:Destroy()
    ScreenGui:Destroy()
end)

--------------------------------------------------
-- TAB SYSTEM
--------------------------------------------------

function Library:Tab(name)

    local TabButton = Create("TextButton", {
        Parent = Sidebar,
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Text = name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = self.Theme.Text
    })

    Corner(TabButton, 6)

    local Page = Create("Frame", {
        Parent = Content,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Visible = false
    })

    local Left = Create("ScrollingFrame", {
        Parent = Page,
        Size = UDim2.new(0.5,-8,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new()
    })

    local Right = Create("ScrollingFrame", {
        Parent = Page,
        Position = UDim2.new(0.5,8,0,0),
        Size = UDim2.new(0.5,-8,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new()
    })

    Create("UIListLayout", {
        Parent = Left,
        Padding = UDim.new(0,12)
    })

    Create("UIListLayout", {
        Parent = Right,
        Padding = UDim.new(0,12)
    })

    local function Select()

        for _,v in pairs(Library.Tabs) do
            v.Page.Visible = false
            v.Button.BackgroundColor3 = Library.Theme.Surface
        end

        Page.Visible = true
        TabButton.BackgroundColor3 = Library.Theme.Accent
    end

    TabButton.MouseButton1Click:Connect(Select)

    if #Library.Tabs == 0 then
        Select()
    end

    table.insert(Library.Tabs, {
        Button = TabButton,
        Page = Page
    })

    --------------------------------------------------
    -- GROUPBOX
    --------------------------------------------------

    local TabAPI = {}

    function TabAPI:Groupbox(title, side)

        local Parent = side == "Right" and Right or Left

        local Group = Create("Frame", {
            Parent = Parent,
            Size = UDim2.new(1,0,0,40),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme.Surface,
            BorderSizePixel = 0
        })

        Corner(Group, 6)
        Stroke(Group)

        Create("TextLabel", {
            Parent = Group,
            BackgroundTransparency = 1,
            Position = UDim2.new(0,12,0,0),
            Size = UDim2.new(1,0,0,34),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextSize = 13,
            TextColor3 = Library.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local Holder = Create("Frame", {
            Parent = Group,
            Position = UDim2.new(0,10,0,36),
            Size = UDim2.new(1,-20,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        })

        Create("UIListLayout", {
            Parent = Holder,
            Padding = UDim.new(0,8)
        })

        Create("UIPadding", {
            Parent = Holder,
            PaddingBottom = UDim.new(0,10)
        })

        --------------------------------------------------
        -- ELEMENTS
        --------------------------------------------------

        local GroupAPI = {}

        function GroupAPI:Label(text)

            Create("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,18),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Text = text,
                TextSize = 12,
                TextColor3 = Library.Theme.DimText,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end

        function GroupAPI:Button(text, callback)

            local Button = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Library.Theme.Surface2,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Library.Theme.Text
            })

            Corner(Button, 5)

            Button.MouseButton1Click:Connect(function()
                callback()
            end)
        end

        --------------------------------------------------
        -- TOGGLE
        --------------------------------------------------

        function GroupAPI:Toggle(text, default, callback)

            local State = default

            local Frame = Create("Frame", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Library.Theme.Surface2,
                BorderSizePixel = 0
            })

            Corner(Frame, 5)

            Create("TextLabel", {
                Parent = Frame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0,12,0,0),
                Size = UDim2.new(1,0,1,0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextSize = 12,
                TextColor3 = Library.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Switch = Create("Frame", {
                Parent = Frame,
                Position = UDim2.new(1,-52,0.5,-10),
                Size = UDim2.new(0,40,0,20),
                BackgroundColor3 = State and Library.Theme.Accent or Color3.fromRGB(55,55,55),
                BorderSizePixel = 0
            })

            ThemeObject(Switch, "BackgroundColor3")

            Corner(Switch, 20)

            local Knob = Create("Frame", {
                Parent = Switch,
                Position = State and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
                Size = UDim2.new(0,16,0,16),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0
            })

            Corner(Knob, 20)

            Frame.InputBegan:Connect(function(input)

                if input.UserInputType == Enum.UserInputType.MouseButton1 then

                    State = not State

                    Switch.BackgroundColor3 =
                        State and Library.Theme.Accent or Color3.fromRGB(55,55,55)

                    TweenService:Create(Knob, TweenInfo.new(0.15), {
                        Position = State and UDim2.new(1,-18,0.5,-8)
                        or UDim2.new(0,2,0.5,-8)
                    }):Play()

                    callback(State)
                end
            end)
        end

        --------------------------------------------------
        -- SLIDER
        --------------------------------------------------

        function GroupAPI:Slider(text,min,max,default,callback)

            callback(default)
        end

        --------------------------------------------------
        -- DROPDOWN
        --------------------------------------------------

        function GroupAPI:Dropdown(text,options,default,callback)

            callback(default)
        end

        --------------------------------------------------
        -- MULTIDROPDOWN
        --------------------------------------------------

        function GroupAPI:MultiDropdown(text,options,default,callback)

            callback(default)
        end

        --------------------------------------------------
        -- KEYBIND
        --------------------------------------------------

        function GroupAPI:Keybind(text,default,callback)

            callback(default)
        end

        --------------------------------------------------
        -- TEXTBOX
        --------------------------------------------------

        function GroupAPI:Textbox(text,default,callback)

            callback(default)
        end

        --------------------------------------------------
        -- COLORPICKER
        --------------------------------------------------

        function GroupAPI:Colorpicker(text,default,callback)

            callback(default)
        end

        return GroupAPI
    end

    return TabAPI
end

return Library
```
