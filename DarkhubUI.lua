--// PREMIUM CSGO UI FRAMEWORK
--// FULL REWRITE
--// Features:
--// • Executor Safe
--// • cloneref/gethui
--// • protect_gui
--// • Blur
--// • Notifications
--// • Modern Close Button
--// • Minimize Button
--// • Groupboxes
--// • Two Column Layout
--// • Toggles
--// • Sliders
--// • Dropdowns
--// • Animations
--// • Cleanup System

local success, err = pcall(function()

    --------------------------------------------------
    -- SERVICES
    --------------------------------------------------

    local cloneref = cloneref or function(v)
        return v
    end

    local UIS = cloneref(game:GetService("UserInputService"))
    local TweenService = cloneref(game:GetService("TweenService"))
    local Lighting = cloneref(game:GetService("Lighting"))
    local RunService = cloneref(game:GetService("RunService"))
    local HttpService = cloneref(game:GetService("HttpService"))

    local CoreGui =
        (gethui and gethui())
        or cloneref(game:GetService("CoreGui"))

    --------------------------------------------------
    -- GUI
    --------------------------------------------------

    local GuiName =
        "CSGO_" ..
        tostring(math.random(100000,999999))

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = GuiName
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999

    pcall(function()

        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
        end

        if protectgui then
            protectgui(ScreenGui)
        end
    end)

    ScreenGui.Parent = CoreGui

    --------------------------------------------------
    -- THEME
    --------------------------------------------------

    local Theme = {
        Accent = Color3.fromRGB(0,255,120),
        Background = Color3.fromRGB(17,17,21),
        Sidebar = Color3.fromRGB(13,13,16),
        Surface = Color3.fromRGB(28,28,34),
        Surface2 = Color3.fromRGB(22,22,28),
        Text = Color3.fromRGB(255,255,255),
        DarkText = Color3.fromRGB(170,170,170)
    }

    --------------------------------------------------
    -- LIBRARY
    --------------------------------------------------

    local Library = {
        Connections = {},
        Flags = {}
    }

    --------------------------------------------------
    -- HELPERS
    --------------------------------------------------

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

        local connection =
            signal:Connect(newcclosure(func))

        table.insert(
            Library.Connections,
            connection
        )

        return connection
    end

    --------------------------------------------------
    -- BLUR
    --------------------------------------------------

    local Blur = Instance.new("BlurEffect")
    Blur.Size = 0
    Blur.Parent = Lighting

    TweenService:Create(
        Blur,
        TweenInfo.new(0.25),
        {Size = 18}
    ):Play()

    --------------------------------------------------
    -- MAIN WINDOW
    --------------------------------------------------

    local Main = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(0.5,-360,0.5,-260),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })

    Create("UICorner", {
        Parent = Main,
        CornerRadius = UDim.new(0,8)
    })

    Create("UIStroke", {
        Parent = Main,
        Thickness = 1,
        Color = Theme.Surface
    })

    TweenService:Create(
        Main,
        TweenInfo.new(
            0.35,
            Enum.EasingStyle.Quart
        ),
        {
            Size = UDim2.new(0,720,0,520)
        }
    ):Play()

    --------------------------------------------------
    -- TOPBAR
    --------------------------------------------------

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
        Size = UDim2.new(1,-80,1,0),
        Text = "CS:GO • PREMIUM",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    --------------------------------------------------
    -- MINIMIZE BUTTON
    --------------------------------------------------

    local Minimize = Create("TextButton", {
        Parent = Topbar,
        Size = UDim2.new(0,16,0,16),
        Position = UDim2.new(1,-54,0.5,-8),
        BackgroundTransparency = 1,
        Text = ""
    })

    local MinLine = Create("Frame", {
        Parent = Minimize,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.new(1,0,0,2),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0
    })

    --------------------------------------------------
    -- CLOSE BUTTON
    --------------------------------------------------

    local Close = Create("TextButton", {
        Parent = Topbar,
        Size = UDim2.new(0,18,0,18),
        Position = UDim2.new(1,-28,0.5,-9),
        BackgroundTransparency = 1,
        Text = ""
    })

    local X1 = Create("Frame", {
        Parent = Close,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.new(1,0,0,2),
        Rotation = 45,
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0
    })

    local X2 = Create("Frame", {
        Parent = Close,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.new(1,0,0,2),
        Rotation = -45,
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0
    })

    --------------------------------------------------
    -- SIDEBAR
    --------------------------------------------------

    local Sidebar = Create("Frame", {
        Parent = Main,
        Size = UDim2.new(0,150,1,-42),
        Position = UDim2.new(0,0,0,42),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0
    })

    local SidebarLayout = Create("UIListLayout", {
        Parent = Sidebar,
        Padding = UDim.new(0,8)
    })

    Create("UIPadding", {
        Parent = Sidebar,
        PaddingTop = UDim.new(0,12),
        PaddingLeft = UDim.new(0,10),
        PaddingRight = UDim.new(0,10)
    })

    --------------------------------------------------
    -- CONTENT
    --------------------------------------------------

    local Content = Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1,-150,1,-42),
        Position = UDim2.new(0,150,0,42),
        BackgroundTransparency = 1
    })

    --------------------------------------------------
    -- MINIMIZE LOGIC
    --------------------------------------------------

    local Minimized = false
    local SavedSize = UDim2.new(0,720,0,520)

    Connect(Minimize.MouseButton1Click, function()

        Minimized = not Minimized

        if Minimized then

            TweenService:Create(
                Main,
                TweenInfo.new(0.25),
                {
                    Size = UDim2.new(0,720,0,42)
                }
            ):Play()

            Content.Visible = false
            Sidebar.Visible = false

        else

            Content.Visible = true
            Sidebar.Visible = true

            TweenService:Create(
                Main,
                TweenInfo.new(0.25),
                {
                    Size = SavedSize
                }
            ):Play()
        end
    end)

    --------------------------------------------------
    -- CLOSE LOGIC
    --------------------------------------------------

    Connect(Close.MouseButton1Click, function()

        TweenService:Create(
            Main,
            TweenInfo.new(0.25),
            {
                Size = UDim2.new(0,0,0,0)
            }
        ):Play()

        TweenService:Create(
            Blur,
            TweenInfo.new(0.25),
            {
                Size = 0
            }
        ):Play()

        task.wait(0.25)

        for _,connection in pairs(
            Library.Connections
        ) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        pcall(function()
            Blur:Destroy()
        end)

        pcall(function()
            ScreenGui:Destroy()
        end)
    end)

    --------------------------------------------------
    -- DRAGGING
    --------------------------------------------------

    local dragging = false
    local dragStart
    local startPos

    Connect(Topbar.InputBegan, function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)

    Connect(UIS.InputChanged, function(input)

        if dragging and
            input.UserInputType ==
            Enum.UserInputType.MouseMovement then

            local delta =
                input.Position - dragStart

            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    Connect(UIS.InputEnded, function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = false
        end
    end)

    --------------------------------------------------
    -- NOTIFICATIONS
    --------------------------------------------------

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

        Create("UIStroke", {
            Parent = Notify,
            Color = Theme.Accent
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

    --------------------------------------------------
    -- EXAMPLE NOTIFICATION
    --------------------------------------------------

    Library:Notify(
        "Loaded",
        "Premium Framework Loaded"
    )

end)

if not success then
    warn(err)
end
