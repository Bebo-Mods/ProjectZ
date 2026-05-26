
-- FULL PREMIUM UI LIBRARY SOURCE
-- COMPLETE FRAMEWORK
-- Tabs
-- Groupboxes
-- Toggles
-- Buttons
-- Sliders
-- Dropdowns
-- MultiDropdowns
-- Textboxes
-- Keybinds
-- Labels
-- Paragraphs
-- Notifications
-- Smart Minimize
-- Topbar Dock Mode
-- Blur Controller
-- Executor Safe
print("updated")
local cloneref = cloneref or function(v)
    return v
end

local UIS = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local HttpService = cloneref(game:GetService("HttpService"))

local CoreGui =
    (gethui and gethui())
    or cloneref(game:GetService("CoreGui"))

local GuiName =
    "Premium_" .. tostring(math.random(100000,999999))

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GuiName
ScreenGui.Parent = CoreGui
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)

local Theme = {
    Accent = Color3.fromRGB(0,255,120),
    Background = Color3.fromRGB(17,17,21),
    Sidebar = Color3.fromRGB(13,13,16),
    Surface = Color3.fromRGB(28,28,34),
    Surface2 = Color3.fromRGB(22,22,28),
    Text = Color3.fromRGB(255,255,255),
    DarkText = Color3.fromRGB(170,170,170)
}

local Library = {
    Connections = {},
    Flags = {}
}

local function Create(class, props)

    local obj = Instance.new(class)

    for i,v in pairs(props or {}) do
        if i ~= "Parent" then
            obj[i] = v
        end
    end

    if props and props.Parent then
        obj.Parent = props.Parent
    end

    return obj
end

local function Connect(signal, func)

    local c = signal:Connect(newcclosure(func))

    table.insert(Library.Connections, c)

    return c
end

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

TweenService:Create(
    Blur,
    TweenInfo.new(0.25),
    {Size = 18}
):Play()

local Main = Create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0,720,0,520),
    Position = UDim2.new(0.5,-360,0.5,-260),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
})

Create("UICorner", {
    Parent = Main,
    CornerRadius = UDim.new(0,8)
})

local Topbar = Create("Frame", {
    Parent = Main,
    Size = UDim2.new(1,0,0,42),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0
})

Create("UICorner", {
    Parent = Topbar,
    CornerRadius = UDim.new(0,8)
})

Create("TextLabel", {
    Parent = Topbar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0,16,0,0),
    Size = UDim2.new(1,-90,1,0),
    Text = "PREMIUM UI",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
})

local Minimize = Create("TextButton", {
    Parent = Topbar,
    Size = UDim2.new(0,16,0,16),
    Position = UDim2.new(1,-54,0.5,-8),
    BackgroundTransparency = 1,
    Text = "_",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Theme.Text
})

local Close = Create("TextButton", {
    Parent = Topbar,
    Size = UDim2.new(0,18,0,18),
    Position = UDim2.new(1,-28,0.5,-9),
    BackgroundTransparency = 1,
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.Text
})

local Sidebar = Create("Frame", {
    Parent = Main,
    Size = UDim2.new(0,150,1,-42),
    Position = UDim2.new(0,0,0,42),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0
})

Create("UIPadding", {
    Parent = Sidebar,
    PaddingTop = UDim.new(0,12),
    PaddingLeft = UDim.new(0,10),
    PaddingRight = UDim.new(0,10)
})

local SidebarLayout = Create("UIListLayout", {
    Parent = Sidebar,
    Padding = UDim.new(0,8)
})

local Content = Create("Frame", {
    Parent = Main,
    Size = UDim2.new(1,-150,1,-42),
    Position = UDim2.new(0,150,0,42),
    BackgroundTransparency = 1
})

local Tabs = {}

local dragging = false
local dragStart
local startPos

Connect(Topbar.InputBegan, function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Connect(UIS.InputChanged, function(input)

    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

Connect(UIS.InputEnded, function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Connect(Close.MouseButton1Click, function()

    for _,c in pairs(Library.Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    Blur:Destroy()
    ScreenGui:Destroy()
end)

local minimized = false

local DockButton = Create("TextButton", {
    Parent = ScreenGui,
    Visible = false,
    Size = UDim2.new(0,180,0,34),
    Position = UDim2.new(0.5,-90,0,12),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    Text = "PREMIUM UI",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Theme.Text,
    ZIndex = 999
})

Create("UICorner", {
    Parent = DockButton,
    CornerRadius = UDim.new(0,6)
})

local minimized = false

Connect(Minimize.MouseButton1Click, function()

    minimized = not minimized

    if minimized then

        TweenService:Create(
            Blur,
            TweenInfo.new(0.2),
            {
                Size = 0
            }
        ):Play()

        TweenService:Create(
            Main,
            TweenInfo.new(0.25),
            {
                Size = UDim2.new(0,0,0,0),
                Position = UDim2.new(0.5,0,0,-100)
            }
        ):Play()

        task.wait(0.25)

        Main.Visible = false
        DockButton.Visible = true

    else

        Main.Visible = true
        DockButton.Visible = false

        Main.Size = UDim2.new(0,0,0,0)
        Main.Position = UDim2.new(0.5,0,0,-100)

        TweenService:Create(
            Main,
            TweenInfo.new(0.25),
            {
                Size = UDim2.new(0,720,0,520),
                Position = UDim2.new(0.5,-360,0.5,-260)
            }
        ):Play()

        TweenService:Create(
            Blur,
            TweenInfo.new(0.2),
            {
                Size = 18
            }
        ):Play()
    end
end)

Connect(DockButton.MouseButton1Click, function()

    minimized = false

    Main.Visible = true
    DockButton.Visible = false

    Main.Size = UDim2.new(0,0,0,0)
    Main.Position = UDim2.new(0.5,0,0,-100)

    TweenService:Create(
        Main,
        TweenInfo.new(0.25),
        {
            Size = UDim2.new(0,720,0,520),
            Position = UDim2.new(0.5,-360,0.5,-260)
        }
    ):Play()

    TweenService:Create(
        Blur,
        TweenInfo.new(0.2),
        {
            Size = 18
        }
    ):Play()
end)

function Library:Notify(title, text)

    local Notify = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0,260,0,70),
        Position = UDim2.new(1,300,1,-90),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0
    })

    Create("UICorner", {
        Parent = Notify,
        CornerRadius = UDim.new(0,6)
    })

    Create("TextLabel", {
        Parent = Notify,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,12,0,8),
        Size = UDim2.new(1,-20,0,20),
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Create("TextLabel", {
        Parent = Notify,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,12,0,30),
        Size = UDim2.new(1,-20,0,20),
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.DarkText,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    TweenService:Create(
        Notify,
        TweenInfo.new(0.25),
        {
            Position = UDim2.new(1,-280,1,-90)
        }
    ):Play()

    task.delay(3, function()

        TweenService:Create(
            Notify,
            TweenInfo.new(0.25),
            {
                Position = UDim2.new(1,300,1,-90)
            }
        ):Play()

        task.wait(0.25)

        Notify:Destroy()
    end)
end

function Library:Tab(name)

    local TabAPI = {}

    local Button = Create("TextButton", {
        Parent = Sidebar,
        Size = UDim2.new(1,0,0,42),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Text = "   " .. name,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.DarkText,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Create("UICorner", {
        Parent = Button,
        CornerRadius = UDim.new(0,5)
    })

    local Page = Create("Frame", {
        Parent = Content,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Visible = false
    })

    local Left = Create("ScrollingFrame", {
        Parent = Page,
        Size = UDim2.new(0.49,0,1,0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0)
    })

    local Right = Create("ScrollingFrame", {
        Parent = Page,
        Position = UDim2.new(0.51,0,0,0),
        Size = UDim2.new(0.49,0,1,0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0)
    })

    local tabData = {
        Button = Button,
        Page = Page
    }

    table.insert(Tabs, tabData)

    if #Tabs == 1 then
        Button.BackgroundColor3 = Theme.Accent
        Button.TextColor3 = Color3.new(0,0,0)
        Page.Visible = true
    end

    Connect(Button.MouseButton1Click, function()

        for _,tab in pairs(Tabs) do
            tab.Button.BackgroundColor3 = Theme.Surface
            tab.Button.TextColor3 = Theme.DarkText
            tab.Page.Visible = false
        end

        Button.BackgroundColor3 = Theme.Accent
        Button.TextColor3 = Color3.new(0,0,0)
        Page.Visible = true
    end)

    function TabAPI:Groupbox(title, side)

        local Container = side == "Right" and Right or Left

        local Groupbox = Create("Frame", {
            Parent = Container,
            Size = UDim2.new(1,-6,0,40),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0
        })

        Create("UICorner", {
            Parent = Groupbox,
            CornerRadius = UDim.new(0,6)
        })

        Create("TextLabel", {
            Parent = Groupbox,
            BackgroundTransparency = 1,
            Position = UDim2.new(0,12,0,10),
            Size = UDim2.new(1,-20,0,20),
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local Holder = Create("Frame", {
            Parent = Groupbox,
            Position = UDim2.new(0,10,0,36),
            Size = UDim2.new(1,-20,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        })

        local Layout = Create("UIListLayout", {
            Parent = Holder,
            Padding = UDim.new(0,8)
        })

        local GroupAPI = {}

        function GroupAPI:Button(text, callback)

            local Btn = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text
            })

            Create("UICorner", {
                Parent = Btn,
                CornerRadius = UDim.new(0,5)
            })

            Connect(Btn.MouseButton1Click, function()
                pcall(callback)
            end)
        end

        function GroupAPI:Label(text)

            Create("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,20),
                BackgroundTransparency = 1,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.DarkText,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end

        function GroupAPI:Paragraph(title, text)

            local Paragraph = Create("Frame", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,50),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Paragraph,
                CornerRadius = UDim.new(0,5)
            })

            Create("TextLabel", {
                Parent = Paragraph,
                BackgroundTransparency = 1,
                Position = UDim2.new(0,10,0,6),
                Size = UDim2.new(1,-20,0,18),
                Text = title,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            Create("TextLabel", {
                Parent = Paragraph,
                BackgroundTransparency = 1,
                Position = UDim2.new(0,10,0,24),
                Size = UDim2.new(1,-20,0,18),
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Theme.DarkText,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end

        function GroupAPI:Toggle(text, default, callback)

            local enabled = default or false

            local Toggle = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Text = ""
            })

            Create("UICorner", {
                Parent = Toggle,
                CornerRadius = UDim.new(0,5)
            })

            Create("TextLabel", {
                Parent = Toggle,
                BackgroundTransparency = 1,
                Position = UDim2.new(0,12,0,0),
                Size = UDim2.new(1,-70,1,0),
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Switch = Create("Frame", {
                Parent = Toggle,
                Size = UDim2.new(0,40,0,18),
                Position = UDim2.new(1,-52,0.5,-9),
                BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(50,50,55),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Switch,
                CornerRadius = UDim.new(1,0)
            })

            local Circle = Create("Frame", {
                Parent = Switch,
                Size = UDim2.new(0,14,0,14),
                Position = enabled and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Circle,
                CornerRadius = UDim.new(1,0)
            })

            Connect(Toggle.MouseButton1Click, function()

                enabled = not enabled

                TweenService:Create(
                    Circle,
                    TweenInfo.new(0.15),
                    {
                        Position = enabled and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
                    }
                ):Play()

                TweenService:Create(
                    Switch,
                    TweenInfo.new(0.15),
                    {
                        BackgroundColor3 = enabled and Theme.Accent or Color3.fromRGB(50,50,55)
                    }
                ):Play()

                pcall(function()
                    callback(enabled)
                end)
            end)
        end

        function GroupAPI:Slider(text, min, max, default, callback)

            local value = default or min

            local SliderFrame = Create("Frame", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,46),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = SliderFrame,
                CornerRadius = UDim.new(0,5)
            })

            local Label = Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0,12,0,0),
                Size = UDim2.new(1,-24,0,20),
                Text = text .. " : " .. tostring(value),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Bar = Create("Frame", {
                Parent = SliderFrame,
                Position = UDim2.new(0,12,0,28),
                Size = UDim2.new(1,-24,0,6),
                BackgroundColor3 = Color3.fromRGB(45,45,50),
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Bar,
                CornerRadius = UDim.new(1,0)
            })

            local Fill = Create("Frame", {
                Parent = Bar,
                Size = UDim2.new((value-min)/(max-min),0,1,0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Fill,
                CornerRadius = UDim.new(1,0)
            })

            local dragging = false

            Connect(Bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)

            Connect(UIS.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            Connect(UIS.InputChanged, function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + ((max - min) * percent))
                    Fill.Size = UDim2.new(percent,0,1,0)
                    Label.Text = text .. " : " .. tostring(value)
                    pcall(function()
                        callback(value)
                    end)
                end
            end)
        end

        function GroupAPI:Textbox(text, placeholder, callback)

            local Box = Create("TextBox", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                PlaceholderText = placeholder,
                Text = "",
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text
            })

            Create("UICorner", {
                Parent = Box,
                CornerRadius = UDim.new(0,5)
            })

            Connect(Box.FocusLost, function()
                pcall(function()
                    callback(Box.Text)
                end)
            end)
        end

        function GroupAPI:Dropdown(text, options, default, callback)

            local selected = default or options[1]
            local opened = false

            local DropdownHolder = Create("Frame", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            })

            local Drop = Create("TextButton", {
                Parent = DropdownHolder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Text = text .. " : " .. tostring(selected),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text
            })

            Create("UICorner", {
                Parent = Drop,
                CornerRadius = UDim.new(0,5)
            })

            local List = Create("Frame", {
                Parent = DropdownHolder,
                Visible = false,
                Position = UDim2.new(0,0,0,40),
                Size = UDim2.new(1,0,0,#options * 28),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true
            })

            Create("UICorner", {
                Parent = List,
                CornerRadius = UDim.new(0,5)
            })

            local Layout = Create("UIListLayout", {
                Parent = List,
                Padding = UDim.new(0,2)
            })

            for _,opt in pairs(options) do

                local Btn = Create("TextButton", {
                    Parent = List,
                    Size = UDim2.new(1,0,0,26),
                    BackgroundTransparency = 1,
                    Text = opt,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.Text
                })

                Connect(Btn.MouseButton1Click, function()

                    selected = opt

                    Drop.Text = text .. " : " .. opt

                    opened = false
                    List.Visible = false

                    DropdownHolder.Size = UDim2.new(1,0,0,36)

                    pcall(function()
                        callback(opt)
                    end)
                end)
            end

            Connect(Drop.MouseButton1Click, function()

                opened = not opened

                List.Visible = opened

                DropdownHolder.Size = opened
                    and UDim2.new(1,0,0,40 + (#options * 28))
                    or UDim2.new(1,0,0,36)
            end)
        end

        function GroupAPI:Keybind(text, default, callback)

            local current = default or Enum.KeyCode.E

            local Bind = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Text = text .. " : " .. current.Name,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text
            })

            Create("UICorner", {
                Parent = Bind,
                CornerRadius = UDim.new(0,5)
            })

            local waiting = false

            Connect(Bind.MouseButton1Click, function()
                waiting = true
                Bind.Text = text .. " : ..."
            end)

            Connect(UIS.InputBegan, function(input, gp)
                if waiting and not gp then
                    waiting = false
                    current = input.KeyCode
                    Bind.Text = text .. " : " .. current.Name
                    pcall(function()
                        callback(current)
                    end)
                end
            end)
        end

        function GroupAPI:MultiDropdown(text, options, default, callback)

            local selected = {}

            for _,v in pairs(default or {}) do
                selected[v] = true
            end

            local Main = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text
            })

            Create("UICorner", {
                Parent = Main,
                CornerRadius = UDim.new(0,5)
            })

            local Container = Create("Frame", {
                Parent = Holder,
                Visible = false,
                Size = UDim2.new(1,0,0,#options * 30),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Container,
                CornerRadius = UDim.new(0,5)
            })

            local Layout = Create("UIListLayout", {
                Parent = Container
            })

            for _,opt in pairs(options) do

                local Btn = Create("TextButton", {
                    Parent = Container,
                    Size = UDim2.new(1,0,0,30),
                    BackgroundTransparency = 1,
                    Text = opt,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.Text
                })

                Connect(Btn.MouseButton1Click, function()
                    selected[opt] = not selected[opt]
                    pcall(function()
                        callback(selected)
                    end)
                end)
            end

            local opened = false

            Connect(Main.MouseButton1Click, function()
                opened = not opened
                Container.Visible = opened
            end)
        end

        function GroupAPI:Colorpicker(text, default, callback)

            local current = default or Color3.fromRGB(255,255,255)

            local Picker = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text
            })

            Create("UICorner", {
                Parent = Picker,
                CornerRadius = UDim.new(0,5)
            })

            local Preview = Create("Frame", {
                Parent = Picker,
                Size = UDim2.new(0,20,0,20),
                Position = UDim2.new(1,-30,0.5,-10),
                BackgroundColor3 = current,
                BorderSizePixel = 0
            })

            Create("UICorner", {
                Parent = Preview,
                CornerRadius = UDim.new(0,4)
            })

            Connect(Picker.MouseButton1Click, function()
                current = Color3.fromHSV(math.random(),1,1)
                Preview.BackgroundColor3 = current
                pcall(function()
                    callback(current)
                end)
            end)
        end

        return GroupAPI
    end

    return TabAPI
end

return Library
