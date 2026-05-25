--[[
════════════════════════════════════════════════════════════════════
  MacLib  —  Safety-Hardened Edition
  Original: github.com/biggaboy212/Maclib
  Hardening:
    ✔ gethui() → cloneref(CoreGui) → CoreGui → PlayerGui (safe chain)
    ✔ cloneref() on every service reference
    ✔ pcall() wrapping on all Instance creation, property sets,
      signal connections, and callbacks
    ✔ :connect() → :Connect()  (deprecated API fixed)
    ✔ RunService.RenderStepped:connect() → :Connect()
    ✔ task.spawn() / task.wait() / task.cancel() throughout
    ✔ All service globals replaced with safe cloneref variants
    ✔ Nil-safe guards on LocalPlayer / Mouse access
════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════
--  SAFE SERVICE + GUI ROOT HELPERS
-- ═══════════════════════════════════════════
local function SafeSvc(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    if not ok or not s then return nil end
    if cloneref then
        local ok2, r = pcall(cloneref, s)
        if ok2 and r then return r end
    end
    return s
end

local function SafeGuiRoot()
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
    local Players = SafeSvc("Players")
    local lp = Players and Players.LocalPlayer
    return lp and lp:FindFirstChildOfClass("PlayerGui")
end

local function SafeConn(sig, fn)
    if not sig or not fn then return nil end
    local ok, c = pcall(function() return sig:Connect(fn) end)
    return ok and c or nil
end

local function SafeCall(fn, ...)
    if not fn then return end
    local ok, e = pcall(fn, ...)
    if not ok then
        -- Uncomment for debug: warn("[MacLib] " .. tostring(e))
    end
    return ok
end

-- ═══════════════════════════════════════════
--  SERVICES  (all via cloneref)
-- ═══════════════════════════════════════════
local TweenService       = SafeSvc("TweenService")
local RunService         = SafeSvc("RunService")
local HttpService        = SafeSvc("HttpService")
local ContentProvider    = SafeSvc("ContentProvider")
local UserInputService   = SafeSvc("UserInputService")
local Players            = SafeSvc("Players")
local Lighting           = SafeSvc("Lighting")

local isStudio           = RunService and RunService:IsStudio() or false
local LocalPlayer        = Players and Players.LocalPlayer

-- ═══════════════════════════════════════════
--  SAFE NEW INSTANCE
-- ═══════════════════════════════════════════
local function N(class, props)
    local inst
    SafeCall(function()
        inst = Instance.new(class)
        for k, v in pairs(props or {}) do
            SafeCall(function() inst[k] = v end)
        end
    end)
    return inst
end

-- ═══════════════════════════════════════════
--  TWEEN HELPER
-- ═══════════════════════════════════════════
local function Tween(instance, tweeninfo, propertytable)
    if not (instance and tweeninfo and propertytable) then return {Play=function()end,Completed={Wait=function()end}} end
    local ok, t = pcall(function()
        return TweenService:Create(instance, tweeninfo, propertytable)
    end)
    if ok and t then return t end
    return {Play=function()end,Completed={Wait=function()end}}
end

-- ═══════════════════════════════════════════
--  MACLIB TABLE
-- ═══════════════════════════════════════════
local MacLib = {}

local windowState
local acrylicBlur
local hasGlobalSetting

local tabs = {}
local currentTabInstance = nil
local tabIndex = 0

local assets = {
    interFont          = "rbxassetid://12187365364",
    userInfoBlurred    = "rbxassetid://18824089198",
    toggleBackground   = "rbxassetid://18772190202",
    togglerHead        = "rbxassetid://18772309008",
    buttonImage        = "rbxassetid://10709791437",
    searchIcon         = "rbxassetid://86737463322606",
}

-- ═══════════════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════════════
function MacLib:Window(Settings)
    local WindowFunctions = {}

    SafeCall(function()
        acrylicBlur = Settings.AcrylicBlur ~= nil and Settings.AcrylicBlur or true
    end)

    -- ── ScreenGui ──────────────────────────────────────────────
    local macLib
    SafeCall(function()
        macLib = N("ScreenGui", {
            Name            = "MacLib",
            ResetOnSpawn    = false,
            DisplayOrder    = 100,
            IgnoreGuiInset  = true,
            ScreenInsets    = Enum.ScreenInsets.None,
            ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        })
        if macLib then
            macLib.Parent = SafeGuiRoot()
        end
    end)
    if not macLib then return WindowFunctions end

    -- ── Notifications ──────────────────────────────────────────
    local notifications = N("Frame", {
        Name                 = "Notifications",
        BackgroundColor3     = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.fromScale(1,1),
        ZIndex               = 2,
    })
    SafeCall(function()
        local l = N("UIListLayout", {
            Name               = "NotificationsUIListLayout",
            Padding            = UDim.new(0,10),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder          = Enum.SortOrder.LayoutOrder,
            VerticalAlignment  = Enum.VerticalAlignment.Bottom,
        }) if l then l.Parent = notifications end
        local p = N("UIPadding", {
            Name          = "NotificationsUIPadding",
            PaddingBottom = UDim.new(0,10),
            PaddingLeft   = UDim.new(0,10),
            PaddingRight  = UDim.new(0,10),
            PaddingTop    = UDim.new(0,10),
        }) if p then p.Parent = notifications end
        notifications.Parent = macLib
    end)

    -- ── Base frame ─────────────────────────────────────────────
    local base = N("Frame", {
        Name                 = "Base",
        AnchorPoint          = Vector2.new(0.5,0.5),
        BackgroundColor3     = Color3.fromRGB(15,15,15),
        BackgroundTransparency = acrylicBlur and 0.05 or 0,
        BorderSizePixel      = 0,
        Position             = UDim2.fromScale(0.5,0.5),
        Size                 = Settings.Size or UDim2.fromOffset(868,650),
    })
    SafeCall(function()
        local sc = N("UIScale",  {Name="BaseUIScale"})       if sc then sc.Parent = base end
        local cr = N("UICorner", {Name="BaseUICorner", CornerRadius=UDim.new(0,10)}) if cr then cr.Parent = base end
        local sk = N("UIStroke", {
            Name             = "BaseUIStroke",
            ApplyStrokeMode  = Enum.ApplyStrokeMode.Border,
            Color            = Color3.fromRGB(255,255,255),
            Transparency     = 0.9,
        }) if sk then sk.Parent = base end
        base.Parent = macLib
    end)

    -- ── Sidebar ────────────────────────────────────────────────
    local sidebar = N("Frame", {
        Name                 = "Sidebar",
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.fromScale(0,0),
        Size                 = UDim2.fromScale(0.325,1),
    })
    SafeCall(function()
        -- right divider
        local div = N("Frame",{
            Name="Divider", AnchorPoint=Vector2.new(1,0),
            BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.9,
            BorderSizePixel=0, Position=UDim2.fromScale(1,0), Size=UDim2.new(0,1,1,0),
        }) if div then div.Parent = sidebar end
        sidebar.Parent = base
    end)

    -- ── Window Controls (macOS-style dots) ─────────────────────
    local windowControls = N("Frame",{
        Name="WindowControls", BackgroundTransparency=1, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,31),
    })
    local controls = N("Frame",{
        Name="Controls", BackgroundColor3=Color3.fromRGB(119,174,94),
        BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1),
    })
    SafeCall(function()
        local ul = N("UIListLayout",{
            Name="UIListLayout", Padding=UDim.new(0,5),
            FillDirection=Enum.FillDirection.Horizontal,
            SortOrder=Enum.SortOrder.LayoutOrder,
            VerticalAlignment=Enum.VerticalAlignment.Center,
        }) if ul then ul.Parent = controls end
        local up = N("UIPadding",{Name="UIPadding", PaddingLeft=UDim.new(0,11)})
        if up then up.Parent = controls end
        controls.Parent = windowControls
    end)

    local wcs = {
        sizes          = {enabled=UDim2.fromOffset(8,8), disabled=UDim2.fromOffset(7,7)},
        transparencies = {enabled=0, disabled=1},
        strokeTransparency = 0.9,
    }
    local strokeTemplate = N("UIStroke",{
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
        Color=Color3.fromRGB(255,255,255), Transparency=wcs.strokeTransparency,
    })

    local function makeControl(name, color, order)
        local btn = N("TextButton",{
            Name=name, Text="", TextColor3=Color3.fromRGB(0,0,0), TextSize=14,
            AutoButtonColor=false, BackgroundColor3=color,
            BorderSizePixel=0, LayoutOrder=order or 0,
            FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json"),
        })
        SafeCall(function()
            local cr = N("UICorner",{CornerRadius=UDim.new(1,0)}) if cr then cr.Parent = btn end
            btn.Parent = controls
        end)
        return btn
    end

    local exit     = makeControl("Exit",     Color3.fromRGB(250,93,86),  0)
    local minimize = makeControl("Minimize", Color3.fromRGB(252,190,57), 1)
    local maximize = makeControl("Maximize", Color3.fromRGB(119,174,94), 1)

    local function applyState(button, enabled)
        SafeCall(function()
            local size = enabled and wcs.sizes.enabled or wcs.sizes.disabled
            local tr   = enabled and wcs.transparencies.enabled or wcs.transparencies.disabled
            button.Size                  = size
            button.BackgroundTransparency = tr
            button.Active                = enabled
            button.Interactable          = enabled
            for _, c in ipairs(button:GetChildren()) do
                if c:IsA("UIStroke") then c.Transparency = tr end
            end
            if not enabled and strokeTemplate then
                local clone = strokeTemplate:Clone()
                if clone then clone.Parent = button end
            end
        end)
    end
    applyState(maximize, false)
    for _, btn in pairs({exit, minimize}) do
        local en = true
        if Settings.DisabledWindowControls and table.find(Settings.DisabledWindowControls, btn.Name) then en = false end
        applyState(btn, en)
    end

    SafeCall(function()
        local div1 = N("Frame",{
            Name="Divider", AnchorPoint=Vector2.new(0,1),
            BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.9,
            BorderSizePixel=0, Position=UDim2.fromScale(0,1), Size=UDim2.new(1,0,0,1),
        }) if div1 then div1.Parent = windowControls end
        windowControls.Parent = sidebar
    end)

    -- ── Information strip ──────────────────────────────────────
    local information = N("Frame",{
        Name="Information", BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.fromOffset(0,31), Size=UDim2.new(1,0,0,60),
    })
    local informationHolder = N("Frame",{
        Name="InformationHolder", BackgroundTransparency=1,
        BorderSizePixel=0, Size=UDim2.fromScale(1,1),
    })

    local globalSettingsButton
    SafeCall(function()
        local div2 = N("Frame",{
            Name="Divider", AnchorPoint=Vector2.new(0,1),
            BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.9,
            BorderSizePixel=0, Position=UDim2.fromScale(0,1), Size=UDim2.new(1,0,0,1),
        }) if div2 then div2.Parent = information end

        local ihp = N("UIPadding",{
            Name="InformationHolderUIPadding",
            PaddingBottom=UDim.new(0,10), PaddingLeft=UDim.new(0,23),
            PaddingRight=UDim.new(0,22),  PaddingTop=UDim.new(0,10),
        }) if ihp then ihp.Parent = informationHolder end

        globalSettingsButton = N("ImageButton",{
            Name="GlobalSettingsButton", Image="rbxassetid://18767849817",
            ImageTransparency=0.4, AnchorPoint=Vector2.new(1,0.5),
            BackgroundTransparency=1, BorderSizePixel=0,
            Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(15,15),
        })
        if globalSettingsButton then globalSettingsButton.Parent = informationHolder end

        local titleFrame = N("Frame",{Name="TitleFrame",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})

        local title = N("TextLabel",{
            Name="Title",
            FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
            Text=Settings.Title or "", RichText=true,
            TextColor3=Color3.fromRGB(255,255,255), TextSize=20, TextTransparency=0.2,
            TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top, AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.new(1,-20,0,0),
        })
        if title and titleFrame then title.Parent = titleFrame end

        local subtitle = N("TextLabel",{
            Name="Subtitle",
            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
            Text=Settings.Subtitle or "", RichText=true,
            TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextTransparency=0.7,
            TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top, AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=1, Size=UDim2.new(1,-20,0,0),
        })
        if subtitle and titleFrame then subtitle.Parent = titleFrame end

        local tful = N("UIListLayout",{
            Name="TitleFrameUIListLayout", Padding=UDim.new(0,3),
            SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center,
        })
        if tful and titleFrame then tful.Parent = titleFrame end
        if titleFrame then titleFrame.Parent = informationHolder end

        informationHolder.Parent = information
        information.Parent = sidebar

        -- globalSettingsButton hover
        SafeConn(globalSettingsButton and globalSettingsButton.MouseEnter, function()
            Tween(globalSettingsButton, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {ImageTransparency=0.2}):Play()
        end)
        SafeConn(globalSettingsButton and globalSettingsButton.MouseLeave, function()
            Tween(globalSettingsButton, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {ImageTransparency=0.4}):Play()
        end)
    end)

    -- ── UpdateTitle / UpdateSubtitle ───────────────────────────
    function WindowFunctions:UpdateTitle(t) SafeCall(function()
        local lbl = informationHolder and informationHolder:FindFirstChild("TitleFrame") and informationHolder.TitleFrame:FindFirstChild("Title")
        if lbl then lbl.Text = t end
    end) end
    function WindowFunctions:UpdateSubtitle(t) SafeCall(function()
        local lbl = informationHolder and informationHolder:FindFirstChild("TitleFrame") and informationHolder.TitleFrame:FindFirstChild("Subtitle")
        if lbl then lbl.Text = t end
    end) end

    -- ── Sidebar group (tabs + user info) ───────────────────────
    local sidebarGroup = N("Frame",{
        Name="SidebarGroup", BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.fromOffset(0,91), Size=UDim2.new(1,0,1,-91),
    })

    -- User info card
    local userInfo = N("Frame",{
        Name="UserInfo", AnchorPoint=Vector2.new(0,1),
        BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.fromScale(0,1), Size=UDim2.new(1,0,0,107),
    })
    local informationGroup = N("Frame",{
        Name="InformationGroup", BackgroundTransparency=1,
        BorderSizePixel=0, Size=UDim2.fromScale(1,1),
    })

    local headshotImage, isReady = "", false
    SafeCall(function()
        local uid = LocalPlayer and LocalPlayer.UserId or 0
        headshotImage, isReady = Players:GetUserThumbnailAsync(
            uid, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size48x48)
    end)

    local headshot
    SafeCall(function()
        local igp = N("UIPadding",{
            Name="InformationGroupUIPadding",
            PaddingBottom=UDim.new(0,17), PaddingLeft=UDim.new(0,25),
        })
        if igp then igp.Parent = informationGroup end
        local igul = N("UIListLayout",{
            Name="InformationGroupUIListLayout",
            FillDirection=Enum.FillDirection.Horizontal,
            SortOrder=Enum.SortOrder.LayoutOrder,
            VerticalAlignment=Enum.VerticalAlignment.Center,
        })
        if igul then igul.Parent = informationGroup end

        headshot = N("ImageLabel",{
            Name="Headshot", BackgroundTransparency=1, BorderSizePixel=0,
            Size=UDim2.fromOffset(32,32),
            Image=isReady and headshotImage or "rbxassetid://0",
        })
        SafeCall(function()
            local cr = N("UICorner",{CornerRadius=UDim.new(1,0)}) if cr then cr.Parent = headshot end
            local sk = N("UIStroke",{
                ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                Color=Color3.fromRGB(255,255,255), Transparency=0.9,
            }) if sk then sk.Parent = headshot end
            headshot.Parent = informationGroup
        end)

        local uadf = N("Frame",{
            Name="UserAndDisplayFrame", BackgroundTransparency=1,
            BorderSizePixel=0, LayoutOrder=1, Size=UDim2.new(1,-42,0,32),
        })
        local uadfp = N("UIPadding",{PaddingLeft=UDim.new(0,8), PaddingTop=UDim.new(0,3)})
        if uadfp and uadf then uadfp.Parent = uadf end
        local uadul = N("UIListLayout",{Padding=UDim.new(0,1), SortOrder=Enum.SortOrder.LayoutOrder})
        if uadul and uadf then uadul.Parent = uadf end

        local displayName = N("TextLabel",{
            Name="DisplayName",
            FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
            Text=LocalPlayer and LocalPlayer.DisplayName or "Player",
            TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.2,
            TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top, AutomaticSize=Enum.AutomaticSize.XY,
            BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,0),
        })
        if displayName and uadf then displayName.Parent = uadf end

        local username = N("TextLabel",{
            Name="Username",
            FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
            Text="@"..(LocalPlayer and LocalPlayer.Name or "Player"),
            TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextTransparency=0.8,
            TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top, AutomaticSize=Enum.AutomaticSize.XY,
            BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=1,
            Size=UDim2.fromScale(1,0),
        })
        if username and uadf then username.Parent = uadf end
        if uadf then uadf.Parent = informationGroup end
        informationGroup.Parent = userInfo

        local uip2 = N("UIPadding",{
            Name="UserInfoUIPadding", PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10),
        })
        if uip2 then uip2.Parent = userInfo end
        userInfo.Parent = sidebarGroup
    end)

    -- Tab switcher list
    local tabSwitchersScrollingFrame
    SafeCall(function()
        local sgp = N("UIPadding",{
            Name="SidebarGroupUIPadding",
            PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,31),
        })
        if sgp then sgp.Parent = sidebarGroup end

        local tabSwitchers = N("Frame",{
            Name="TabSwitchers", BackgroundTransparency=1, BorderSizePixel=0,
            Size=UDim2.new(1,0,1,-107),
        })

        tabSwitchersScrollingFrame = N("ScrollingFrame",{
            Name="TabSwitchersScrollingFrame",
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            BottomImage="", CanvasSize=UDim2.new(),
            ScrollBarImageTransparency=0.8, ScrollBarThickness=1, TopImage="",
            BackgroundTransparency=1, BorderSizePixel=0,
            Size=UDim2.fromScale(1,1),
        })
        SafeCall(function()
            local ul = N("UIListLayout",{
                Name="TabSwitchersScrollingFrameUIListLayout",
                Padding=UDim.new(0,17), SortOrder=Enum.SortOrder.LayoutOrder,
            })
            if ul then ul.Parent = tabSwitchersScrollingFrame end
            local up = N("UIPadding",{
                Name="TabSwitchersScrollingFrameUIPadding", PaddingTop=UDim.new(0,2),
            })
            if up then up.Parent = tabSwitchersScrollingFrame end
            tabSwitchersScrollingFrame.Parent = tabSwitchers
        end)
        tabSwitchers.Parent = sidebarGroup
        sidebarGroup.Parent = sidebar
    end)

    -- ── Content area ───────────────────────────────────────────
    local content = N("Frame",{
        Name="Content", AnchorPoint=Vector2.new(1,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        Position=UDim2.fromScale(1,0), Size=UDim2.fromScale(0.675,1),
    })
    local currentTabLabel
    SafeCall(function()
        local topbar = N("Frame",{
            Name="Topbar", BackgroundTransparency=1, BorderSizePixel=0,
            Size=UDim2.new(1,0,0,63),
        })
        local div4 = N("Frame",{
            Name="Divider", AnchorPoint=Vector2.new(0,1),
            BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.9,
            BorderSizePixel=0, Position=UDim2.fromScale(0,1), Size=UDim2.new(1,0,0,1),
        }) if div4 then div4.Parent = topbar end

        local elements = N("Frame",{
            Name="Elements", BackgroundTransparency=1, BorderSizePixel=0,
            Size=UDim2.fromScale(1,1),
        })
        local ep = N("UIPadding",{
            Name="UIPadding", PaddingLeft=UDim.new(0,20), PaddingRight=UDim.new(0,20),
        }) if ep then ep.Parent = elements end

        local showMoveIcon = not Settings.DragStyle or Settings.DragStyle == 1
        local moveIcon = N("ImageButton",{
            Name="MoveIcon", Image="rbxassetid://10734900011",
            ImageTransparency=0.5, AnchorPoint=Vector2.new(1,0.5),
            BackgroundTransparency=1, BorderSizePixel=0,
            Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(15,15),
        })
        SafeCall(function()
            moveIcon.Visible = showMoveIcon
            moveIcon.Parent = elements
        end)

        local interact2 = N("TextButton",{
            Name="Interact", Text="",
            TextColor3=Color3.fromRGB(0,0,0), TextSize=14,
            AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1,
            BorderSizePixel=0, Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(30,30),
            FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json"),
        })
        SafeCall(function()
            interact2.Parent = moveIcon
        end)

        SafeConn(interact2 and interact2.MouseEnter, function()
            Tween(moveIcon, TweenInfo.new(0.2,Enum.EasingStyle.Sine), {ImageTransparency=0.2}):Play()
        end)
        SafeConn(interact2 and interact2.MouseLeave, function()
            Tween(moveIcon, TweenInfo.new(0.2,Enum.EasingStyle.Sine), {ImageTransparency=0.5}):Play()
        end)

        currentTabLabel = N("TextLabel",{
            Name="CurrentTab",
            FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
            RichText=true, Text="Tab",
            TextColor3=Color3.fromRGB(255,255,255), TextSize=15, TextTransparency=0.5,
            TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top, AnchorPoint=Vector2.new(0,0.5),
            AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
            BorderSizePixel=0, Position=UDim2.fromScale(0,0.5),
            Size=UDim2.fromScale(0.9,0),
        })
        if currentTabLabel then currentTabLabel.Parent = elements end
        elements.Parent = topbar
        topbar.Parent = content
        content.Parent = base

        -- ── Drag ───────────────────────────────────────────────
        local dragging_, dragInput, dragStart, startPos = false, nil, nil, nil
        local function updateDrag(input)
            SafeCall(function()
                local delta = input.Position - dragStart
                base.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end)
        end
        local function onDragStart(input)
            SafeCall(function()
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging_ = true
                    dragStart  = input.Position
                    startPos   = base.Position
                    SafeConn(input.Changed, function()
                        if input.UserInputState == Enum.UserInputState.End then dragging_ = false end
                    end)
                end
            end)
        end
        local function onDragMove(input)
            SafeCall(function()
                if dragging_ and (input.UserInputType == Enum.UserInputType.MouseMovement or
                                  input.UserInputType == Enum.UserInputType.Touch) then
                    dragInput = input
                end
            end)
        end

        if not Settings.DragStyle or Settings.DragStyle == 1 then
            SafeConn(interact2 and interact2.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then onDragStart(input) end
            end)
            SafeConn(interact2 and interact2.InputChanged, onDragMove)
            SafeConn(UserInputService and UserInputService.InputChanged, function(input)
                if input == dragInput and dragging_ then updateDrag(input) end
            end)
            SafeConn(interact2 and interact2.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then dragging_ = false end
            end)
        elseif Settings.DragStyle == 2 then
            SafeConn(base.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then onDragStart(input) end
            end)
            SafeConn(base.InputChanged, onDragMove)
            SafeConn(UserInputService and UserInputService.InputChanged, function(input)
                if input == dragInput and dragging_ then updateDrag(input) end
            end)
            SafeConn(base.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then dragging_ = false end
            end)
        end
    end)

    -- ── Global Settings panel ──────────────────────────────────
    local globalSettings
    local globalSettingsUIScale
    SafeCall(function()
        globalSettings = N("Frame",{
            Name="GlobalSettings", AutomaticSize=Enum.AutomaticSize.XY,
            BackgroundColor3=Color3.fromRGB(15,15,15), BorderSizePixel=0,
            Position=UDim2.fromScale(0.298,0.104),
        })
        local gsk = N("UIStroke",{
            ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
            Color=Color3.fromRGB(255,255,255), Transparency=0.9,
        }) if gsk then gsk.Parent = globalSettings end
        local gcr = N("UICorner",{CornerRadius=UDim.new(0,10)}) if gcr then gcr.Parent = globalSettings end
        local gup = N("UIPadding",{PaddingBottom=UDim.new(0,10), PaddingTop=UDim.new(0,10)})
        if gup then gup.Parent = globalSettings end
        local gul = N("UIListLayout",{Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})
        if gul then gul.Parent = globalSettings end

        globalSettingsUIScale = N("UIScale",{Name="GlobalSettingsUIScale", Scale=1e-7})
        if globalSettingsUIScale then globalSettingsUIScale.Parent = globalSettings end
        globalSettings.Parent = base
    end)

    -- globalSettingsButton toggle logic
    local gsToggled = false
    local gsHovering = false
    local function gsToggle()
        SafeCall(function()
            if not gsToggled then
                local t = Tween(globalSettingsUIScale, TweenInfo.new(0.2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Scale=1})
                t:Play(); t.Completed:Wait(); gsToggled = true
            else
                local t = Tween(globalSettingsUIScale, TweenInfo.new(0.2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Scale=0})
                t:Play(); t.Completed:Wait(); gsToggled = false
            end
        end)
    end
    SafeConn(globalSettingsButton and globalSettingsButton.MouseButton1Click, function()
        if not hasGlobalSetting then return end
        task.spawn(gsToggle)
    end)
    SafeConn(globalSettings and globalSettings.MouseEnter, function() gsHovering = true end)
    SafeConn(globalSettings and globalSettings.MouseLeave, function() gsHovering = false end)
    SafeConn(UserInputService and UserInputService.InputEnded, function(inp)
        SafeCall(function()
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and gsToggled and not gsHovering then
                task.spawn(gsToggle)
            end
        end)
    end)

    -- ── Acrylic blur (3D wedge effect) ─────────────────────────
    SafeCall(function()
        local BlurTarget = base
        local camera = workspace.CurrentCamera
        local MTREL = "Glass"
        local binds = {}
        local wedgeguid = HttpService:GenerateGUID(true)

        local DepthOfField
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("DepthOfFieldEffect") and v:HasTag(".") then DepthOfField = v end
        end
        if not DepthOfField then
            DepthOfField = N("DepthOfFieldEffect",{
                FarIntensity=0, FocusDistance=51.6, InFocusRadius=50, NearIntensity=1,
            })
            SafeCall(function()
                DepthOfField.Name = HttpService:GenerateGUID(true)
                DepthOfField:AddTag(".")
                DepthOfField.Parent = Lighting
            end)
        end

        local blurFrame = N("Frame",{
            Size=UDim2.new(0.97,0,0.97,0), Position=UDim2.new(0.5,0,0.5,0),
            AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1,
            Name=HttpService:GenerateGUID(true),
        })
        if blurFrame then blurFrame.Parent = BlurTarget end

        do
            local function IsNotNaN(x) return x == x end
            local ok2 = IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x)
            while not ok2 do
                SafeCall(function() RunService.RenderStepped:Wait() end)
                ok2 = IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x)
            end
        end

        local DrawQuad; do
            local acos,max,pi,sqrt = math.acos,math.max,math.pi,math.sqrt
            local sz = 0.2
            local function DrawTriangle(v1,v2,v3,p0,p1)
                local s1=(v1-v2).magnitude; local s2=(v2-v3).magnitude; local s3=(v3-v1).magnitude
                local smax=max(s1,s2,s3); local A,B,C
                if s1==smax then A,B,C=v1,v2,v3 elseif s2==smax then A,B,C=v2,v3,v1 else A,B,C=v3,v1,v2 end
                local para=((B-A).x*(C-A).x+(B-A).y*(C-A).y+(B-A).z*(C-A).z)/(A-B).magnitude
                local perp=sqrt((C-A).magnitude^2-para*para)
                local dif_para=(A-B).magnitude-para
                local st=CFrame.new(B,A); local za=CFrame.Angles(pi/2,0,0)
                local cf0=st
                local Top_Look=(cf0*za).lookVector
                local Mid_Point=A+CFrame.new(A,B).lookVector*para
                local Needed_Look=CFrame.new(Mid_Point,C).lookVector
                local dot=Top_Look.x*Needed_Look.x+Top_Look.y*Needed_Look.y+Top_Look.z*Needed_Look.z
                local ac=CFrame.Angles(0,0,acos(dot))
                cf0=cf0*ac
                if ((cf0*za).lookVector-Needed_Look).magnitude>0.01 then cf0=cf0*CFrame.Angles(0,0,-2*acos(dot)) end
                cf0=cf0*CFrame.new(0,perp/2,-(dif_para+para/2))
                local cf1=st*ac*CFrame.Angles(0,pi,0)
                if ((cf1*za).lookVector-Needed_Look).magnitude>0.01 then cf1=cf1*CFrame.Angles(0,0,2*acos(dot)) end
                cf1=cf1*CFrame.new(0,perp/2,dif_para/2)
                if not p0 then
                    p0=Instance.new("Part"); p0.FormFactor="Custom"; p0.TopSurface=0; p0.BottomSurface=0
                    p0.Anchored=true; p0.CanCollide=false; p0.CastShadow=false; p0.Material=MTREL
                    p0.Size=Vector3.new(sz,sz,sz); p0.Name=HttpService:GenerateGUID(true)
                    local mesh=Instance.new("SpecialMesh",p0); mesh.MeshType=2; mesh.Name=wedgeguid
                end
                p0[wedgeguid].Scale=Vector3.new(0,perp/sz,para/sz); p0.CFrame=cf0
                if not p1 then p1=p0:Clone() end
                p1[wedgeguid].Scale=Vector3.new(0,perp/sz,dif_para/sz); p1.CFrame=cf1
                return p0,p1
            end
            function DrawQuad(v1,v2,v3,v4,parts)
                parts[1],parts[2]=DrawTriangle(v1,v2,v3,parts[1],parts[2])
                parts[3],parts[4]=DrawTriangle(v3,v2,v4,parts[3],parts[4])
            end
        end

        local parts = {}
        local parents = {}
        SafeCall(function()
            local function add(child)
                if child:IsA("GuiObject") then parents[#parents+1]=child; add(child.Parent) end
            end
            add(blurFrame)
        end)

        local function IsVisible(inst)
            while inst do
                if inst:IsA("GuiObject") and not inst.Visible then return false end
                if inst:IsA("ScreenGui") then if not inst.Enabled then return false end; break end
                inst = inst.Parent
            end
            return true
        end

        local function UpdateOrientation(fetchProps)
            SafeCall(function()
                if not IsVisible(blurFrame) or not acrylicBlur then
                    for _,pt in pairs(parts) do pt.Parent=nil end
                    if DepthOfField then DepthOfField.Enabled=false end
                    return
                end
                if DepthOfField then DepthOfField.Enabled=true end
                local properties = {Transparency=0.98, BrickColor=BrickColor.new("Institutional white")}
                local zIndex=1-0.05*blurFrame.ZIndex
                local tl,br=blurFrame.AbsolutePosition,blurFrame.AbsolutePosition+blurFrame.AbsoluteSize
                local tr2,bl=Vector2.new(br.x,tl.y),Vector2.new(tl.x,br.y)
                local rot=0
                for _,v in ipairs(parents) do rot=rot+v.Rotation end
                if rot~=0 and rot%180~=0 then
                    local mid=tl:lerp(br,0.5); local s,c=math.sin(math.rad(rot)),math.cos(math.rad(rot))
                    tl=Vector2.new(c*(tl.x-mid.x)-s*(tl.y-mid.y),s*(tl.x-mid.x)+c*(tl.y-mid.y))+mid
                    tr2=Vector2.new(c*(tr2.x-mid.x)-s*(tr2.y-mid.y),s*(tr2.x-mid.x)+c*(tr2.y-mid.y))+mid
                    bl=Vector2.new(c*(bl.x-mid.x)-s*(bl.y-mid.y),s*(bl.x-mid.x)+c*(bl.y-mid.y))+mid
                    br=Vector2.new(c*(br.x-mid.x)-s*(br.y-mid.y),s*(br.x-mid.x)+c*(br.y-mid.y))+mid
                end
                DrawQuad(
                    camera:ScreenPointToRay(tl.x,tl.y,zIndex).Origin,
                    camera:ScreenPointToRay(tr2.x,tr2.y,zIndex).Origin,
                    camera:ScreenPointToRay(bl.x,bl.y,zIndex).Origin,
                    camera:ScreenPointToRay(br.x,br.y,zIndex).Origin,
                    parts)
                if fetchProps then
                    for _,pt in pairs(parts) do pt.Parent=camera end
                    for k,v in pairs(properties) do
                        for _,pt in pairs(parts) do SafeCall(function() pt[k]=v end) end
                    end
                end
            end)
        end

        UpdateOrientation(true)
        SafeConn(RunService and RunService.RenderStepped, UpdateOrientation)
    end)

    -- ════════════════════════════════════════════════════════════
    --  GlobalSetting
    -- ════════════════════════════════════════════════════════════
    function WindowFunctions:GlobalSetting(Cfg)
        local GF = {}
        SafeCall(function()
            hasGlobalSetting = true
            local gsSetting = N("TextButton",{
                Name="GlobalSetting", Text="",
                TextColor3=Color3.fromRGB(0,0,0), TextSize=14,
                BackgroundTransparency=1, BorderSizePixel=0,
                Size=UDim2.fromOffset(200,30),
                FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json"),
            })
            local gsp = N("UIPadding",{PaddingLeft=UDim.new(0,15)}) if gsp then gsp.Parent=gsSetting end
            local gsul = N("UIListLayout",{
                Padding=UDim.new(0,10), FillDirection=Enum.FillDirection.Horizontal,
                SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center,
            }) if gsul then gsul.Parent=gsSetting end

            local settingName = N("TextLabel",{
                Name="SettingName",
                FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                Text=Cfg.Name or "", RichText=true,
                TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
                TextYAlignment=Enum.TextYAlignment.Top, AnchorPoint=Vector2.new(0,0.5),
                AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, BorderSizePixel=0,
                Position=UDim2.fromScale(0,0.5), Size=UDim2.new(1,-40,0,0),
            })
            if settingName then settingName.Parent=gsSetting end

            local checkmark = N("TextLabel",{
                Name="Checkmark", Text="✓",
                FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=1,
                TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=-1,
                Position=UDim2.fromScale(0,0.5), Size=UDim2.fromOffset(-10,0),
            })
            if checkmark then checkmark.Parent=gsSetting end
            if gsSetting then gsSetting.Parent=globalSettings end

            local ts = {dur=0.2, es=Enum.EasingStyle.Quint, tIn=0.2, tOut=0.5, sInc=12, sDec=-13}

            local function Toggle(state)
                SafeCall(function()
                    local ck = checkmark
                    local sn = settingName
                    local szInc = UDim2.new(ck.Size.X.Scale, state and ts.sInc or ts.sDec, ck.Size.Y.Scale, ck.Size.Y.Offset)
                    Tween(ck, TweenInfo.new(ts.dur,ts.es), {Size=szInc}):Play()
                    Tween(sn, TweenInfo.new(ts.dur,ts.es), {TextTransparency=state and ts.tIn or ts.tOut}):Play()
                    SafeConn(ck:GetPropertyChangedSignal("AbsoluteSize"), function()
                        SafeCall(function()
                            ck.TextTransparency = (state and ck.AbsoluteSize.X > 0) and 0 or 1
                        end)
                    end)
                end)
            end

            local toggled = Cfg.Default or false
            Toggle(toggled)

            SafeConn(gsSetting and gsSetting.MouseButton1Click, function()
                toggled = not toggled
                Toggle(toggled)
                task.spawn(function()
                    if Cfg.Callback then SafeCall(Cfg.Callback, toggled) end
                end)
            end)

            function GF:UpdateName(n) SafeCall(function() if settingName then settingName.Text=n end end) end
            function GF:UpdateState(state)
                toggled=state; Toggle(state)
                task.spawn(function() if Cfg.Callback then SafeCall(Cfg.Callback,state) end end)
            end
        end)
        return GF
    end

    -- ════════════════════════════════════════════════════════════
    --  TabGroup
    -- ════════════════════════════════════════════════════════════
    function WindowFunctions:TabGroup()
        local SGF = {}
        SafeCall(function()
            local tabGroup = N("Frame",{
                Name="Section", AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,0),
            })
            local div3 = N("Frame",{
                Name="Divider", AnchorPoint=Vector2.new(0.5,1),
                BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.9,
                BorderSizePixel=0, Position=UDim2.fromScale(0.5,1), Size=UDim2.new(1,-21,0,1),
            }) if div3 then div3.Parent=tabGroup end

            local sectionTabSwitchers = N("Frame",{
                Name="SectionTabSwitchers", BackgroundTransparency=1,
                BorderSizePixel=0, Size=UDim2.fromScale(1,1),
            })
            local stul = N("UIListLayout",{
                Padding=UDim.new(0,15), HorizontalAlignment=Enum.HorizontalAlignment.Center,
                SortOrder=Enum.SortOrder.LayoutOrder,
            }) if stul then stul.Parent=sectionTabSwitchers end
            local stup = N("UIPadding",{PaddingBottom=UDim.new(0,15)})
            if stup then stup.Parent=sectionTabSwitchers end
            sectionTabSwitchers.Parent=tabGroup
            tabGroup.Parent=tabSwitchersScrollingFrame

            -- ── Tab ───────────────────────────────────────────
            function SGF:Tab(Cfg)
                local TF = {}
                SafeCall(function()
                    local tabSwitcher = N("TextButton",{
                        Name="TabSwitcher", Text="",
                        TextColor3=Color3.fromRGB(0,0,0), TextSize=14, AutoButtonColor=false,
                        AnchorPoint=Vector2.new(0.5,0), BackgroundTransparency=1, BorderSizePixel=0,
                        Position=UDim2.fromScale(0.5,0), Size=UDim2.new(1,-21,0,40),
                        FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json"),
                    })
                    tabIndex = tabIndex + 1
                    SafeCall(function() tabSwitcher.LayoutOrder = tabIndex end)

                    local tscr = N("UICorner",{Name="TabSwitcherUICorner"}) if tscr then tscr.Parent=tabSwitcher end
                    local tssk = N("UIStroke",{
                        Name="TabSwitcherUIStroke", ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                        Color=Color3.fromRGB(255,255,255), Transparency=1,
                    }) if tssk then tssk.Parent=tabSwitcher end
                    local tslayout = N("UIListLayout",{
                        Padding=UDim.new(0,9), FillDirection=Enum.FillDirection.Horizontal,
                        SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center,
                    }) if tslayout then tslayout.Parent=tabSwitcher end

                    if Cfg.Image then
                        local tabImg = N("ImageLabel",{
                            Name="TabImage", Image=Cfg.Image, ImageTransparency=0.4,
                            BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromOffset(16,16),
                        }) if tabImg then tabImg.Parent=tabSwitcher end
                    end

                    local tabName = N("TextLabel",{
                        Name="TabSwitcherName",
                        FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
                        Text=Cfg.Name or "", RichText=true,
                        TextColor3=Color3.fromRGB(255,255,255), TextSize=16, TextTransparency=0.4,
                        TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
                        TextYAlignment=Enum.TextYAlignment.Top, AutomaticSize=Enum.AutomaticSize.Y,
                        BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,0),
                        LayoutOrder=1,
                    })
                    if tabName then tabName.Parent=tabSwitcher end

                    local tsup = N("UIPadding",{
                        Name="TabSwitcherUIPadding",
                        PaddingLeft=UDim.new(0,24), PaddingRight=UDim.new(0,35), PaddingTop=UDim.new(0,1),
                    }) if tsup then tsup.Parent=tabSwitcher end
                    tabSwitcher.Parent=sectionTabSwitchers

                    -- Elements frame for this tab
                    local elements1 = N("Frame",{
                        Name="Elements", BackgroundTransparency=1, BorderSizePixel=0,
                        Position=UDim2.fromOffset(0,63), Size=UDim2.new(1,0,1,-63),
                    })
                    SafeCall(function()
                        local ep = N("UIPadding",{PaddingRight=UDim.new(0,5), PaddingTop=UDim.new(0,10)})
                        if ep then ep.Parent=elements1 end

                        local elemSF = N("ScrollingFrame",{
                            Name="ElementsScrolling",
                            AutomaticCanvasSize=Enum.AutomaticSize.Y, BottomImage="",
                            CanvasSize=UDim2.new(), ScrollBarImageTransparency=0.5,
                            ScrollBarThickness=1, TopImage="",
                            BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1),
                        })
                        local esfp = N("UIPadding",{
                            PaddingBottom=UDim.new(0,15), PaddingLeft=UDim.new(0,11),
                            PaddingRight=UDim.new(0,3), PaddingTop=UDim.new(0,5),
                        }) if esfp then esfp.Parent=elemSF end
                        local esful = N("UIListLayout",{
                            Padding=UDim.new(0,15), FillDirection=Enum.FillDirection.Horizontal,
                            SortOrder=Enum.SortOrder.LayoutOrder,
                        }) if esful then esful.Parent=elemSF end

                        local function makeCol(name, order)
                            local col = N("Frame",{
                                Name=name, AutomaticSize=Enum.AutomaticSize.Y,
                                BackgroundTransparency=1, BorderSizePixel=0,
                                LayoutOrder=order, Size=UDim2.new(0.5,-10,0,0),
                            })
                            local cul = N("UIListLayout",{Padding=UDim.new(0,15), SortOrder=Enum.SortOrder.LayoutOrder})
                            if cul then cul.Parent=col end
                            if col then col.Parent=elemSF end
                            return col
                        end
                        local left  = makeCol("Left",  0)
                        local right = makeCol("Right", 1)

                        elemSF.Parent=elements1

                        -- ────────────────────────────────────────
                        --  Section
                        -- ────────────────────────────────────────
                        function TF:Section(SCfg)
                            local SecF = {}
                            SafeCall(function()
                                local side = SCfg and SCfg.Side or "Left"
                                local section = N("Frame",{
                                    Name="Section", AutomaticSize=Enum.AutomaticSize.Y,
                                    BackgroundTransparency=0.98, BorderSizePixel=0,
                                    Size=UDim2.fromScale(1,0),
                                })
                                SafeCall(function()
                                    local scr = N("UICorner") if scr then scr.Parent=section end
                                    local ssk = N("UIStroke",{
                                        ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                                        Color=Color3.fromRGB(255,255,255), Transparency=0.95,
                                    }) if ssk then ssk.Parent=section end
                                    local sul = N("UIListLayout",{Padding=UDim.new(0,10), SortOrder=Enum.SortOrder.LayoutOrder})
                                    if sul then sul.Parent=section end
                                    local sup = N("UIPadding",{
                                        PaddingBottom=UDim.new(0,20), PaddingLeft=UDim.new(0,20),
                                        PaddingRight=UDim.new(0,18), PaddingTop=UDim.new(0,22),
                                    }) if sup then sup.Parent=section end
                                    section.Parent = (side=="Left") and left or right
                                end)

                                -- ── Button ──────────────────────
                                function SecF:Button(BCfg)
                                    local BF = {}
                                    SafeCall(function()
                                        local btn = N("Frame",{
                                            Name="Button", AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38),
                                        })
                                        btn.Parent=section
                                        local bi = N("TextButton",{
                                            Name="ButtonInteract",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            RichText=true, TextColor3=Color3.fromRGB(255,255,255),
                                            TextSize=13, TextTransparency=0.5,
                                            TextTruncate=Enum.TextTruncate.AtEnd,
                                            TextXAlignment=Enum.TextXAlignment.Left,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.fromScale(1,1), Text=BCfg.Name or "",
                                        })
                                        if bi then bi.Parent=btn end
                                        local bimg = N("ImageLabel",{
                                            Name="ButtonImage", Image=assets.buttonImage,
                                            ImageTransparency=0.5, AnchorPoint=Vector2.new(1,0.5),
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(15,15),
                                        }) if bimg then bimg.Parent=btn end

                                        SafeConn(bi and bi.MouseEnter, function()
                                            Tween(bi,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{TextTransparency=0.3}):Play()
                                            if bimg then Tween(bimg,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{ImageTransparency=0.3}):Play() end
                                        end)
                                        SafeConn(bi and bi.MouseLeave, function()
                                            Tween(bi,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{TextTransparency=0.5}):Play()
                                            if bimg then Tween(bimg,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{ImageTransparency=0.5}):Play() end
                                        end)
                                        SafeConn(bi and bi.MouseButton1Click, function()
                                            task.spawn(function() if BCfg.Callback then SafeCall(BCfg.Callback) end end)
                                        end)

                                        function BF:UpdateName(n) SafeCall(function() if bi then bi.Text=n end end) end
                                        function BF:SetVisibility(s) SafeCall(function() if btn then btn.Visible=s end end) end
                                    end)
                                    return BF
                                end

                                -- ── Toggle ──────────────────────
                                function SecF:Toggle(TCfg)
                                    local TgF = {}
                                    SafeCall(function()
                                        local tog = N("Frame",{
                                            Name="Toggle", AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38),
                                        })
                                        tog.Parent=section

                                        local togName = N("TextLabel",{
                                            Name="ToggleName",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text=TCfg.Name or "", RichText=true,
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                            TextTruncate=Enum.TextTruncate.AtEnd,
                                            TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                            AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(0,0.5), Size=UDim2.new(1,-50,0,0),
                                        })
                                        if togName then togName.Parent=tog end

                                        local tog1 = N("ImageButton",{
                                            Name="Toggle", Image=assets.toggleBackground,
                                            ImageColor3=Color3.fromRGB(61,61,61), AutoButtonColor=false,
                                            AnchorPoint=Vector2.new(1,0.5), BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(41,21),
                                        })
                                        SafeCall(function()
                                            local t1up = N("UIPadding",{
                                                PaddingBottom=UDim.new(0,1), PaddingLeft=UDim.new(0,-2),
                                                PaddingRight=UDim.new(0,3), PaddingTop=UDim.new(0,1),
                                            }) if t1up then t1up.Parent=tog1 end
                                        end)

                                        local togHead = N("ImageLabel",{
                                            Name="TogglerHead", Image=assets.togglerHead,
                                            ImageColor3=Color3.fromRGB(91,91,91),
                                            AnchorPoint=Vector2.new(1,0.5), BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(15,15), ZIndex=2,
                                        })
                                        if togHead then togHead.Parent=tog1 end
                                        if tog1 then tog1.Parent=tog end

                                        local tsOn  = {tog=Color3.fromRGB(87,86,86),  head=Color3.fromRGB(255,255,255), pos=UDim2.new(1,0,0.5,0)}
                                        local tsOff = {tog=Color3.fromRGB(61,61,61),  head=Color3.fromRGB(91,91,91),   pos=UDim2.new(0.5,0,0.5,0)}
                                        local ti = TweenInfo.new(0.2,Enum.EasingStyle.Sine)

                                        local function TogState(state)
                                            SafeCall(function()
                                                local t = state and tsOn or tsOff
                                                Tween(tog1,ti,{ImageColor3=t.tog}):Play()
                                                Tween(togHead,ti,{ImageColor3=t.head}):Play()
                                                Tween(togHead,ti,{Position=t.pos}):Play()
                                                TgF.State = state
                                            end)
                                        end

                                        local togbool = TCfg.Default or false
                                        TogState(togbool)

                                        local function DoToggle()
                                            togbool = not togbool; TogState(togbool)
                                            task.spawn(function() if TCfg.Callback then SafeCall(TCfg.Callback,togbool) end end)
                                        end
                                        SafeConn(tog1 and tog1.MouseButton1Click, DoToggle)

                                        function TgF:Toggle() DoToggle() end
                                        function TgF:UpdateState(s)
                                            togbool=s; TogState(s)
                                            task.spawn(function() if TCfg.Callback then SafeCall(TCfg.Callback,s) end end)
                                        end
                                        function TgF:GetState() return togbool end
                                        function TgF:UpdateName(n) SafeCall(function() if togName then togName.Text=n end end) end
                                        function TgF:SetVisibility(s) SafeCall(function() if tog then tog.Visible=s end end) end
                                    end)
                                    return TgF
                                end

                                -- ── Slider ──────────────────────
                                function SecF:Slider(SlCfg)
                                    local SlF = {}
                                    SafeCall(function()
                                        local slider = N("Frame",{
                                            Name="Slider", AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38),
                                        })
                                        slider.Parent=section

                                        local slName = N("TextLabel",{
                                            Name="SliderName",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text=SlCfg.Name or "", RichText=true,
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                            TextTruncate=Enum.TextTruncate.AtEnd,
                                            TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                            AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.XY,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(0,0.5),
                                        })
                                        if slName then slName.Parent=slider end

                                        local slElems = N("Frame",{
                                            Name="SliderElements", AnchorPoint=Vector2.new(1,0),
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(1,0), Size=UDim2.fromScale(1,1),
                                        })

                                        local slVal = N("TextBox",{
                                            Name="SliderValue",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text="100%", TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextTransparency=0.4,
                                            TextTruncate=Enum.TextTruncate.AtEnd,
                                            BackgroundTransparency=0.95, BorderSizePixel=0,
                                            LayoutOrder=1, Position=UDim2.fromScale(-0.0789,0.171),
                                            Size=UDim2.fromOffset(41,21),
                                        })
                                        SafeCall(function()
                                            local svcr = N("UICorner",{CornerRadius=UDim.new(0,4)}) if svcr then svcr.Parent=slVal end
                                            local svsk = N("UIStroke",{
                                                ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                                                Color=Color3.fromRGB(255,255,255), Transparency=0.9,
                                            }) if svsk then svsk.Parent=slVal end
                                            local svp = N("UIPadding",{PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2)})
                                            if svp then svp.Parent=slVal end
                                            slVal.Parent=slElems
                                        end)

                                        local sleul = N("UIListLayout",{
                                            Padding=UDim.new(0,20), FillDirection=Enum.FillDirection.Horizontal,
                                            HorizontalAlignment=Enum.HorizontalAlignment.Right,
                                            SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center,
                                        }) if sleul then sleul.Parent=slElems end

                                        local slBar = N("ImageLabel",{
                                            Name="SliderBar", Image="rbxassetid://18772615246",
                                            ImageColor3=Color3.fromRGB(87,86,86),
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(0.219,0.457), Size=UDim2.fromOffset(123,3),
                                        })

                                        local slHead = N("ImageButton",{
                                            Name="SliderHead", Image="rbxassetid://18772834246",
                                            AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(12,12),
                                        })
                                        if slHead then slHead.Parent=slBar end
                                        if slBar  then slBar.Parent=slElems end

                                        local slep = N("UIPadding",{PaddingTop=UDim.new(0,3)})
                                        if slep then slep.Parent=slElems end
                                        slElems.Parent=slider

                                        local Display = {
                                            Hundredths = function(v) return string.format("%.2f",v) end,
                                            Tenths     = function(v) return string.format("%.1f",v) end,
                                            Round      = function(v) return tostring(math.round(v)) end,
                                            Degrees    = function(v) return tostring(math.round(v)).."°" end,
                                            Percent    = function(v)
                                                local p=(v-SlCfg.Minimum)/(SlCfg.Maximum-SlCfg.Minimum)*100
                                                return tostring(math.round(p)).."%" end,
                                            Value      = function(v) return tostring(v) end,
                                        }
                                        local disp = Display[SlCfg.DisplayMethod] or Display.Value
                                        local finalValue

                                        local dragging=false
                                        local function SetValue(val, ignoreCB)
                                            SafeCall(function()
                                                local posX
                                                if typeof(val)=="Instance" then
                                                    posX=math.clamp((val.Position.X-slBar.AbsolutePosition.X)/slBar.AbsoluteSize.X,0,1)
                                                else
                                                    posX=(val-SlCfg.Minimum)/(SlCfg.Maximum-SlCfg.Minimum)
                                                end
                                                slHead.Position=UDim2.new(posX,0,0.5,0)
                                                finalValue=posX*(SlCfg.Maximum-SlCfg.Minimum)+SlCfg.Minimum
                                                slVal.Text=disp(finalValue)
                                                SlF.Value=finalValue
                                                if not ignoreCB then
                                                    task.spawn(function()
                                                        if SlCfg.Callback then SafeCall(SlCfg.Callback,finalValue) end
                                                    end)
                                                end
                                            end)
                                        end

                                        SafeCall(function() SetValue(SlCfg.Default or SlCfg.Minimum or 0, true) end)

                                        SafeConn(slHead and slHead.InputBegan, function(input)
                                            SafeCall(function()
                                                if input.UserInputType==Enum.UserInputType.MouseButton1 or
                                                   input.UserInputType==Enum.UserInputType.Touch then
                                                    dragging=true; SetValue(input)
                                                end
                                            end)
                                        end)
                                        SafeConn(slHead and slHead.InputEnded, function(input)
                                            SafeCall(function()
                                                if input.UserInputType==Enum.UserInputType.MouseButton1 or
                                                   input.UserInputType==Enum.UserInputType.Touch then dragging=false end
                                            end)
                                        end)
                                        SafeConn(slVal and slVal.FocusLost, function(enter)
                                            SafeCall(function()
                                                local t=slVal.Text
                                                local v,isP=t:match("^(%-?%d+%.?%d*)(%%?)$")
                                                if v then
                                                    v=tonumber(v); isP=isP=="%"
                                                    if isP then v=SlCfg.Minimum+(v/100)*(SlCfg.Maximum-SlCfg.Minimum) end
                                                    SetValue(math.clamp(v,SlCfg.Minimum,SlCfg.Maximum))
                                                else
                                                    slVal.Text=disp(finalValue or SlCfg.Minimum or 0)
                                                end
                                            end)
                                        end)
                                        SafeConn(UserInputService and UserInputService.InputChanged, function(input)
                                            SafeCall(function()
                                                if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or
                                                                 input.UserInputType==Enum.UserInputType.Touch) then
                                                    SetValue(input)
                                                end
                                            end)
                                        end)

                                        local function updateBarSize()
                                            SafeCall(function()
                                                if not (slElems and slVal and slName and sleul) then return end
                                                local pad=sleul.Padding.Offset
                                                local svw=slVal.AbsoluteSize.X
                                                local snw=slName.AbsoluteSize.X
                                                local tw=slElems.AbsoluteSize.X
                                                local nw=tw-(pad+svw+snw+20)
                                                if slBar then slBar.Size=UDim2.new(slBar.Size.X.Scale,nw,slBar.Size.Y.Scale,slBar.Size.Y.Offset) end
                                            end)
                                        end
                                        updateBarSize()
                                        SafeConn(slName and slName:GetPropertyChangedSignal("AbsoluteSize"), updateBarSize)
                                        SafeConn(section and section:GetPropertyChangedSignal("AbsoluteSize"), updateBarSize)

                                        function SlF:UpdateName(n) SafeCall(function() if slName then slName.Text=n end end) end
                                        function SlF:SetVisibility(s) SafeCall(function() if slider then slider.Visible=s end end) end
                                        function SlF:UpdateValue(v) SafeCall(function() SetValue(v) end) end
                                        function SlF:GetValue() return finalValue end
                                    end)
                                    return SlF
                                end

                                -- ── Input ───────────────────────
                                function SecF:Input(ICfg)
                                    local IF2 = {}
                                    SafeCall(function()
                                        local inp = N("Frame",{
                                            Name="Input", AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38),
                                        })
                                        inp.Parent=section

                                        local inpName = N("TextLabel",{
                                            Name="InputName",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text=ICfg.Name or "", RichText=true,
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                            TextTruncate=Enum.TextTruncate.AtEnd,
                                            TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                            AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.XY,
                                            BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromScale(0,0.5),
                                        })
                                        if inpName then inpName.Parent=inp end

                                        local inpBox = N("TextBox",{
                                            Name="InputBox",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text=ICfg.Default or "", PlaceholderText=ICfg.Placeholder or "",
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextTransparency=0.4,
                                            AnchorPoint=Vector2.new(1,0.5), AutomaticSize=Enum.AutomaticSize.X,
                                            BackgroundTransparency=0.95, BorderSizePixel=0, ClipsDescendants=true,
                                            LayoutOrder=1, Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(21,21),
                                        })
                                        SafeCall(function()
                                            local cr = N("UICorner",{CornerRadius=UDim.new(0,4)}) if cr then cr.Parent=inpBox end
                                            local sk = N("UIStroke",{
                                                ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                                                Color=Color3.fromRGB(255,255,255), Transparency=0.9,
                                            }) if sk then sk.Parent=inpBox end
                                            local up = N("UIPadding",{PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5)})
                                            if up then up.Parent=inpBox end
                                            local sc = N("UISizeConstraint") if sc then sc.Parent=inpBox end
                                            inpBox.Parent=inp
                                        end)

                                        local CharSubs = {
                                            All       = function(v) return v end,
                                            Numeric   = function(v) return v:match("^%-?%d*$") and v or v:gsub("[^%d-]","") end,
                                            Alphabetic= function(v) return v:gsub("[^a-zA-Z ]","") end,
                                        }
                                        local Accepted = CharSubs[ICfg.AcceptedCharacters] or CharSubs.All

                                        local function checkSize()
                                            SafeCall(function()
                                                if not (inpName and inp) then return end
                                                local mw = inp.AbsoluteSize.X - inpName.AbsoluteSize.X - 20
                                                local sc = inpBox and inpBox:FindFirstChildOfClass("UISizeConstraint")
                                                if sc then sc.MaxSize = Vector2.new(mw, 9e9) end
                                            end)
                                        end
                                        checkSize()
                                        SafeConn(inpName and inpName:GetPropertyChangedSignal("AbsoluteSize"), checkSize)

                                        SafeConn(inpBox and inpBox.FocusLost, function()
                                            SafeCall(function()
                                                local filtered=Accepted(inpBox.Text)
                                                inpBox.Text=filtered
                                                task.spawn(function()
                                                    if ICfg.Callback then SafeCall(ICfg.Callback,filtered) end
                                                end)
                                            end)
                                        end)
                                        SafeConn(inpBox and inpBox:GetPropertyChangedSignal("Text"), function()
                                            SafeCall(function()
                                                inpBox.Text=Accepted(inpBox.Text)
                                                IF2.Text=inpBox.Text
                                                if ICfg.onChanged then SafeCall(ICfg.onChanged,inpBox.Text) end
                                            end)
                                        end)

                                        function IF2:UpdateName(n)   SafeCall(function() if inpName then inpName.Text=n end end) end
                                        function IF2:SetVisibility(s) SafeCall(function() if inp then inp.Visible=s end end) end
                                        function IF2:GetInput()      return inpBox and inpBox.Text or "" end
                                        function IF2:UpdatePlaceholder(p) SafeCall(function() if inpBox then inpBox.PlaceholderText=p end end) end
                                        function IF2:UpdateText(t)   SafeCall(function() if inpBox then inpBox.Text=t end end) end
                                    end)
                                    return IF2
                                end

                                -- ── Keybind ─────────────────────
                                function SecF:Keybind(KCfg)
                                    local KF = {}
                                    SafeCall(function()
                                        local kb = N("Frame",{
                                            Name="Keybind", AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38),
                                        })
                                        kb.Parent=section

                                        local kbName = N("TextLabel",{
                                            Name="KeybindName",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text=KCfg.Name or "", RichText=true,
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                            TextTruncate=Enum.TextTruncate.AtEnd,
                                            TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                            AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.XY,
                                            BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromScale(0,0.5),
                                        })
                                        if kbName then kbName.Parent=kb end

                                        local binderBox = N("TextBox",{
                                            Name="BinderBox", CursorPosition=-1, PlaceholderText="...", Text="",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextTransparency=0.4,
                                            AnchorPoint=Vector2.new(1,0.5), AutomaticSize=Enum.AutomaticSize.X,
                                            BackgroundTransparency=0.95, BorderSizePixel=0, ClipsDescendants=true,
                                            LayoutOrder=1, Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(21,21),
                                        })
                                        SafeCall(function()
                                            local cr = N("UICorner",{CornerRadius=UDim.new(0,4)}) if cr then cr.Parent=binderBox end
                                            local sk = N("UIStroke",{
                                                ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                                                Color=Color3.fromRGB(255,255,255), Transparency=0.9,
                                            }) if sk then sk.Parent=binderBox end
                                            local up = N("UIPadding",{PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5)})
                                            if up then up.Parent=binderBox end
                                            local sc = N("UISizeConstraint") if sc then sc.Parent=binderBox end
                                            binderBox.Parent=kb
                                        end)

                                        local focused=false
                                        local binded=KCfg.Default
                                        if binded then SafeCall(function() binderBox.Text=binded.Name end) end

                                        SafeConn(binderBox and binderBox.Focused,   function() focused=true end)
                                        SafeConn(binderBox and binderBox.FocusLost, function() focused=false end)
                                        SafeConn(UserInputService and UserInputService.InputEnded, function(inp)
                                            SafeCall(function()
                                                if macLib ~= nil then
                                                    if focused and inp.KeyCode.Name ~= "Unknown" then
                                                        binded=inp.KeyCode; KF.Bind=binded
                                                        binderBox.Text=inp.KeyCode.Name
                                                        SafeCall(function() binderBox:ReleaseFocus() end)
                                                        if KCfg.onBinded then task.spawn(function() SafeCall(KCfg.onBinded,binded) end) end
                                                    elseif inp.KeyCode==binded then
                                                        if KCfg.Callback then task.spawn(function() SafeCall(KCfg.Callback,binded) end) end
                                                    end
                                                end
                                            end)
                                        end)

                                        function KF:Bind(k) SafeCall(function() binded=k; KF.Bind=k; binderBox.Text=k.Name end) end
                                        function KF:Unbind() SafeCall(function() binded=nil; binderBox.Text="" end) end
                                        function KF:GetBind() return binded end
                                        function KF:UpdateName(n) SafeCall(function() if kbName then kbName.Text=n end end) end
                                        function KF:SetVisibility(s) SafeCall(function() if kb then kb.Visible=s end end) end
                                    end)
                                    return KF
                                end

                                -- ── Dropdown ────────────────────
                                function SecF:Dropdown(DCfg)
                                    local DF = {}
                                    local Selected = {}
                                    local OptionObjs = {}
                                    SafeCall(function()
                                        local dd = N("Frame",{
                                            Name="Dropdown", BackgroundTransparency=0.985, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38), ClipsDescendants=true,
                                        })
                                        dd.Parent=section
                                        local ddp = N("UIPadding",{PaddingLeft=UDim.new(0,15), PaddingRight=UDim.new(0,15)})
                                        if ddp then ddp.Parent=dd end

                                        local ddInt = N("TextButton",{
                                            Name="Interact", Text="",
                                            TextColor3=Color3.fromRGB(0,0,0), TextSize=14,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38),
                                            FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json"),
                                        })
                                        if ddInt then ddInt.Parent=dd end

                                        local ddName = N("TextLabel",{
                                            Name="DropdownName",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text=DCfg.Name or "", RichText=true,
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                            TextTruncate=Enum.TextTruncate.SplitWord,
                                            TextXAlignment=Enum.TextXAlignment.Left,
                                            AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,-20,0,38),
                                        })
                                        if ddName then ddName.Parent=dd end

                                        SafeCall(function()
                                            local dsk = N("UIStroke",{
                                                ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
                                                Color=Color3.fromRGB(255,255,255), Transparency=0.95,
                                            }) if dsk then dsk.Parent=dd end
                                            local dcr = N("UICorner",{CornerRadius=UDim.new(0,6)})
                                            if dcr then dcr.Parent=dd end
                                        end)

                                        local ddImg = N("ImageLabel",{
                                            Name="DropdownImage", Image="rbxassetid://18865373378",
                                            ImageTransparency=0.5, AnchorPoint=Vector2.new(1,0),
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.new(1,0,0,12), Size=UDim2.fromOffset(14,14),
                                        })
                                        if ddImg then ddImg.Parent=dd end

                                        local ddFrame = N("Frame",{
                                            Name="DropdownFrame", BackgroundTransparency=1, BorderSizePixel=0,
                                            ClipsDescendants=true, Size=UDim2.fromScale(1,1),
                                            Visible=false, AutomaticSize=Enum.AutomaticSize.Y,
                                        })
                                        SafeCall(function()
                                            local dfp = N("UIPadding",{PaddingTop=UDim.new(0,38), PaddingBottom=UDim.new(0,10)})
                                            if dfp then dfp.Parent=ddFrame end
                                            local dful = N("UIListLayout",{Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})
                                            if dful then dful.Parent=ddFrame end
                                        end)

                                        -- Search
                                        if DCfg.Search then SafeCall(function()
                                            local srch = N("Frame",{
                                                Name="Search", BackgroundTransparency=0.95, BorderSizePixel=0,
                                                LayoutOrder=-1, Size=UDim2.new(1,0,0,30),
                                            })
                                            local scr2 = N("UICorner") if scr2 then scr2.Parent=srch end
                                            local sicon = N("ImageLabel",{
                                                Name="SearchIcon", Image=assets.searchIcon,
                                                ImageColor3=Color3.fromRGB(180,180,180),
                                                AnchorPoint=Vector2.new(0,0.5), BackgroundTransparency=1, BorderSizePixel=0,
                                                Position=UDim2.fromScale(0,0.5), Size=UDim2.fromOffset(12,12),
                                            }) if sicon then sicon.Parent=srch end
                                            local spad = N("UIPadding",{PaddingLeft=UDim.new(0,15)}) if spad then spad.Parent=srch end
                                            local sBox = N("TextBox",{
                                                Name="SearchBox", CursorPosition=-1, PlaceholderText="Search...",
                                                PlaceholderColor3=Color3.fromRGB(150,150,150), Text="",
                                                TextColor3=Color3.fromRGB(200,200,200), TextSize=14,
                                                TextXAlignment=Enum.TextXAlignment.Left,
                                                BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1),
                                                FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            })
                                            local sbp = N("UIPadding",{PaddingLeft=UDim.new(0,23)}) if sbp and sBox then sbp.Parent=sBox end
                                            if sBox then sBox.Parent=srch end
                                            if srch then srch.Parent=ddFrame end
                                            SafeConn(sBox and sBox:GetPropertyChangedSignal("Text"), function()
                                                SafeCall(function()
                                                    local term=sBox.Text:lower()
                                                    for _,v in pairs(OptionObjs) do
                                                        v.Button.Visible=string.find(v.NameLabel.Text:lower(),term)~=nil
                                                    end
                                                end)
                                            end)
                                        end) end

                                        local ts2={dur=0.2,es=Enum.EasingStyle.Quint,tIn=0.2,tOut=0.5,sInc=12,sDec=-13}

                                        local function CalcSize()
                                            local total=0; local cnt=0
                                            for _,v in pairs(ddFrame:GetChildren()) do
                                                if not v:IsA("UIComponent") and v.Visible then total+=v.AbsoluteSize.Y; cnt+=1 end
                                            end
                                            local dfp2 = ddFrame:FindFirstChild("DropdownFrameUIListLayout") or ddFrame:FindFirstChildOfClass("UIListLayout")
                                            local pad2 = 38+10
                                            local spacing = dfp2 and dfp2.Padding.Offset*(cnt-1) or 0
                                            return total+spacing+pad2
                                        end

                                        local function Toggle2(optName, state)
                                            SafeCall(function()
                                                local opt=OptionObjs[optName]; if not opt then return end
                                                if state then
                                                    if not DCfg.Multi then
                                                        for n,o in pairs(OptionObjs) do
                                                            if n~=optName then
                                                                Tween(o.Checkmark,TweenInfo.new(ts2.dur,ts2.es),{Size=UDim2.new(o.Checkmark.Size.X.Scale,ts2.sDec,o.Checkmark.Size.Y.Scale,o.Checkmark.Size.Y.Offset)}):Play()
                                                                Tween(o.NameLabel,TweenInfo.new(ts2.dur,ts2.es),{TextTransparency=ts2.tOut}):Play()
                                                                o.Checkmark.TextTransparency=1
                                                            end
                                                        end
                                                        Selected={optName}; DF.Value=Selected[1]
                                                    else
                                                        if not table.find(Selected,optName) then table.insert(Selected,optName) end
                                                        DF.Value=Selected
                                                    end
                                                    Tween(opt.Checkmark,TweenInfo.new(ts2.dur,ts2.es),{Size=UDim2.new(opt.Checkmark.Size.X.Scale,ts2.sInc,opt.Checkmark.Size.Y.Scale,opt.Checkmark.Size.Y.Offset)}):Play()
                                                    Tween(opt.NameLabel,TweenInfo.new(ts2.dur,ts2.es),{TextTransparency=ts2.tIn}):Play()
                                                    opt.Checkmark.TextTransparency=0
                                                else
                                                    if DCfg.Multi then
                                                        local idx=table.find(Selected,optName); if idx then table.remove(Selected,idx) end
                                                    else Selected={} end
                                                    Tween(opt.Checkmark,TweenInfo.new(ts2.dur,ts2.es),{Size=UDim2.new(opt.Checkmark.Size.X.Scale,ts2.sDec,opt.Checkmark.Size.Y.Scale,opt.Checkmark.Size.Y.Offset)}):Play()
                                                    Tween(opt.NameLabel,TweenInfo.new(ts2.dur,ts2.es),{TextTransparency=ts2.tOut}):Play()
                                                    opt.Checkmark.TextTransparency=1
                                                end
                                                if DCfg.Required and #Selected==0 and not state then return end
                                                ddName.Text = #Selected>0 and DCfg.Name.." • "..table.concat(Selected,", ") or DCfg.Name
                                            end)
                                        end

                                        local dropped=false; local db=false
                                        local function ToggleDD()
                                            if db then return end; db=true
                                            local open=not dropped
                                            local tgt=open and UDim2.new(1,0,0,CalcSize()) or UDim2.new(1,0,0,38)
                                            local t=Tween(dd,TweenInfo.new(0.2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Size=tgt})
                                            t:Play()
                                            if open then ddFrame.Visible=true; SafeConn(t.Completed,function() db=false end)
                                            else SafeConn(t.Completed,function() ddFrame.Visible=false; db=false end) end
                                            dropped=open
                                        end
                                        SafeConn(ddInt and ddInt.MouseButton1Click, ToggleDD)

                                        local function addOption(i,v)
                                            SafeCall(function()
                                                local opt = N("TextButton",{
                                                    Name="Option", Text="",
                                                    TextColor3=Color3.fromRGB(0,0,0), TextSize=14,
                                                    BackgroundTransparency=1, BorderSizePixel=0,
                                                    Size=UDim2.new(1,0,0,30),
                                                    FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json"),
                                                })
                                                local op = N("UIPadding",{PaddingLeft=UDim.new(0,15)}) if op then op.Parent=opt end
                                                local oul = N("UIListLayout",{
                                                    Padding=UDim.new(0,10), FillDirection=Enum.FillDirection.Horizontal,
                                                    SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center,
                                                }) if oul then oul.Parent=opt end

                                                local oName = N("TextLabel",{
                                                    Name="OptionName",
                                                    FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                                    Text=v, RichText=true,
                                                    TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                                    TextTruncate=Enum.TextTruncate.AtEnd,
                                                    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                                    AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.XY,
                                                    BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromScale(0,0.5),
                                                }) if oName then oName.Parent=opt end

                                                local ock = N("TextLabel",{
                                                    Name="Checkmark", Text="✓",
                                                    FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                                    TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=1,
                                                    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                                    AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.Y,
                                                    BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=-1,
                                                    Position=UDim2.fromScale(0,0.5),
                                                    Size=UDim2.fromOffset(oul and -oul.Padding.Offset or -10,0),
                                                }) if ock then ock.Parent=opt end

                                                if opt then opt.Parent=ddFrame end
                                                if ddFrame then ddFrame.Parent=dd end
                                                OptionObjs[v]={Index=i, Button=opt, NameLabel=oName, Checkmark=ock}

                                                local isSel=false
                                                if DCfg.Default then
                                                    isSel=DCfg.Multi and (table.find(DCfg.Default,v)~=nil) or (DCfg.Default==i)
                                                end
                                                Toggle2(v,isSel)

                                                SafeConn(opt and opt.MouseButton1Click, function()
                                                    SafeCall(function()
                                                        local cur=table.find(Selected,v)~=nil
                                                        local newSel=not cur
                                                        if DCfg.Required and not newSel and #Selected<=1 then return end
                                                        Toggle2(v,newSel)
                                                        task.spawn(function()
                                                            if DCfg.Multi then
                                                                local ret={}; for _,o in ipairs(Selected) do ret[o]=true end
                                                                if DCfg.Callback then SafeCall(DCfg.Callback,ret) end
                                                            else
                                                                if newSel and DCfg.Callback then SafeCall(DCfg.Callback,Selected[1] or nil) end
                                                            end
                                                        end)
                                                    end)
                                                end)
                                                if dropped then SafeCall(function() dd.Size=UDim2.new(1,0,0,CalcSize()) end) end
                                            end)
                                        end

                                        for i,v in pairs(DCfg.Options or {}) do addOption(i,v) end

                                        function DF:UpdateName(n) SafeCall(function() if ddName then ddName.Text=n end end) end
                                        function DF:SetVisibility(s) SafeCall(function() if dd then dd.Visible=s end end) end
                                        function DF:UpdateSelection(ns)
                                            SafeCall(function()
                                                if type(ns)=="number" then
                                                    for o,d in pairs(OptionObjs) do Toggle2(o,d.Index==ns) end
                                                elseif type(ns)=="table" then
                                                    for o in pairs(OptionObjs) do Toggle2(o,table.find(ns,o)~=nil) end
                                                end
                                            end)
                                        end
                                        function DF:InsertOptions(no)
                                            SafeCall(function() for i,v in pairs(no) do addOption(i,v) end end)
                                        end
                                        function DF:ClearOptions()
                                            SafeCall(function()
                                                for _,o in pairs(OptionObjs) do if o.Button then o.Button:Destroy() end end
                                                OptionObjs={}; Selected={}
                                                if dropped then SafeCall(function() dd.Size=UDim2.new(1,0,0,CalcSize()) end) end
                                            end)
                                        end
                                        function DF:GetOptions()
                                            local out={}
                                            for o in pairs(OptionObjs) do out[o]=table.find(Selected,o)~=nil end
                                            return out
                                        end
                                        function DF:RemoveOptions(rem)
                                            SafeCall(function()
                                                for _,n in ipairs(rem) do
                                                    local d=OptionObjs[n]; if d then
                                                        for i=#Selected,1,-1 do if Selected[i]==n then table.remove(Selected,i) end end
                                                        if d.Button then d.Button:Destroy() end; OptionObjs[n]=nil
                                                    end
                                                end
                                                if dropped then SafeCall(function() dd.Size=UDim2.new(1,0,0,CalcSize()) end) end
                                            end)
                                        end
                                        function DF:IsOption(n) return OptionObjs[n]~=nil end
                                    end)
                                    return DF
                                end

                                -- ── Colorpicker (full HSV wheel + slider + RGB/Hex/Alpha) ──
                                function SecF:Colorpicker(CPCfg)
                                    local CPF = {}
                                    SafeCall(function()
                                        local isAlpha = CPCfg.Alpha ~= nil
                                        CPF.Color = CPCfg.Default or Color3.fromRGB(255,255,255)
                                        CPF.Alpha = isAlpha and CPCfg.Alpha or nil

                                        -- Row frame
                                        local cpFrame = N("Frame",{
                                            Name="Colorpicker", AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0,
                                            Size=UDim2.new(1,0,0,38),
                                        })
                                        cpFrame.Parent=section

                                        local cpName = N("TextLabel",{
                                            Name="ColorpickerName",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            Text=CPCfg.Name or "", TextColor3=Color3.fromRGB(255,255,255),
                                            TextSize=13, TextTransparency=0.5, RichText=true,
                                            TextTruncate=Enum.TextTruncate.AtEnd,
                                            TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                            AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.XY,
                                            BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromScale(0,0.5),
                                        })
                                        if cpName then cpName.Parent=cpFrame end

                                        -- Swatch (checkered BG + color overlay)
                                        local colorCbg = N("ImageLabel",{
                                            Name="NewColor", Image="rbxassetid://121484455191370",
                                            ScaleType=Enum.ScaleType.Tile, TileSize=UDim2.fromOffset(500,500),
                                            AnchorPoint=Vector2.new(1,0.5), BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(21,21),
                                        })
                                        local colorC = N("Frame",{
                                            Name="Color", AnchorPoint=Vector2.new(0.5,0.5),
                                            BackgroundColor3=CPF.Color, BorderSizePixel=0,
                                            Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromScale(1,1),
                                            BackgroundTransparency=CPF.Alpha or 0,
                                        })
                                        SafeCall(function()
                                            N("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=colorC
                                            N("UICorner",{CornerRadius=UDim.new(0,8)}).Parent=colorCbg
                                        end)

                                        local cpInteract = N("TextButton",{
                                            Name="Interact", Text="", TextColor3=Color3.fromRGB(0,0,0), TextSize=14,
                                            BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1),
                                            FontFace=Font.new("rbxasset://fonts/families/SourceSansPro.json"),
                                        })
                                        SafeCall(function()
                                            cpInteract.Parent=colorC
                                            colorC.Parent=colorCbg
                                            colorCbg.Parent=cpFrame
                                        end)

                                        -- ── Full picker overlay ─────────────────────────────────
                                        local colorPicker = N("Frame",{
                                            Name="ColorPicker", BackgroundTransparency=0.5,
                                            BackgroundColor3=Color3.fromRGB(0,0,0), BorderSizePixel=0,
                                            Size=UDim2.fromScale(1,1), Visible=false,
                                        })
                                        SafeCall(function()
                                            N("UICorner",{CornerRadius=UDim.new(0,10)}).Parent=colorPicker
                                        end)

                                        -- Prompt card
                                        local prompt = N("Frame",{
                                            Name="Prompt", AnchorPoint=Vector2.new(0.5,0.5),
                                            AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundColor3=Color3.fromRGB(15,15,15), BorderSizePixel=0,
                                            Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(420,0),
                                        })
                                        SafeCall(function()
                                            N("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(255,255,255),Transparency=0.9}).Parent=prompt
                                            N("UICorner",{CornerRadius=UDim.new(0,10)}).Parent=prompt
                                            N("UIListLayout",{Padding=UDim.new(0,10),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder}).Parent=prompt
                                            N("UIPadding",{PaddingBottom=UDim.new(0,20),PaddingLeft=UDim.new(0,20),PaddingRight=UDim.new(0,20),PaddingTop=UDim.new(0,20)}).Parent=prompt
                                        end)

                                        -- Title bar inside prompt
                                        SafeCall(function()
                                            local para = N("Frame",{Name="Paragraph",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,0)})
                                            N("UIListLayout",{Padding=UDim.new(0,15),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder}).Parent=para
                                            N("UIPadding",{PaddingBottom=UDim.new(0,15)}).Parent=para
                                            local ph=N("TextLabel",{
                                                Name="ParagraphHeader",
                                                FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
                                                RichText=true, Text=CPCfg.Name or "",
                                                TextColor3=Color3.fromRGB(255,255,255), TextSize=18, TextTransparency=0.4,
                                                TextWrapped=true, TextYAlignment=Enum.TextYAlignment.Top,
                                                AutomaticSize=Enum.AutomaticSize.XY, BackgroundTransparency=1, BorderSizePixel=0,
                                                Size=UDim2.fromScale(1,0),
                                            })
                                            if ph then ph.Parent=para end
                                            local ln=N("Frame",{Name="Line",BackgroundTransparency=0.9,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,LayoutOrder=1,Size=UDim2.new(1,0,0,1)})
                                            if ln then ln.Parent=para end
                                            para.Parent=prompt
                                        end)

                                        -- Color options (wheel + inputs + value slider)
                                        local colorOptions = N("Frame",{Name="ColorOptions",AutomaticSize=Enum.AutomaticSize.XY,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=1,Size=UDim2.fromScale(1,0)})
                                        SafeCall(function()
                                            N("UIListLayout",{Padding=UDim.new(0,25),SortOrder=Enum.SortOrder.LayoutOrder}).Parent=colorOptions
                                        end)

                                        -- Value slider (brightness)
                                        local valueSlider = N("TextButton",{
                                            Name="Value", Text="", TextColor3=Color3.fromRGB(0,0,0), TextSize=14,
                                            AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(255,255,255),
                                            BorderSizePixel=0, LayoutOrder=1, Size=UDim2.new(1,0,0,15),
                                        })
                                        local valueSlide = N("Frame",{
                                            Name="Slide", AnchorPoint=Vector2.new(0,0.5),
                                            BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0,
                                            Position=UDim2.fromScale(0,0.5), Size=UDim2.new(0,13,1,8),
                                        })
                                        SafeCall(function()
                                            N("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))})}).Parent=valueSlider
                                            N("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=valueSlider
                                            N("UICorner",{CornerRadius=UDim.new(1,0)}).Parent=valueSlide
                                            N("UIStroke",{Transparency=0.5}).Parent=valueSlide
                                            valueSlide.Parent=valueSlider
                                        end)

                                        -- Wheel frame
                                        local wheelFrame = N("Frame",{Name="Wheel",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,100)})
                                        SafeCall(function()
                                            N("UIPadding",{PaddingRight=UDim.new(0,5)}).Parent=wheelFrame
                                        end)

                                        local wheel1 = N("ImageButton",{
                                            Name="Wheel", Image="rbxassetid://2849458409",
                                            AutoButtonColor=false, Active=false, BackgroundTransparency=1, BorderSizePixel=0,
                                            Selectable=false, Size=UDim2.fromOffset(220,220), SizeConstraint=Enum.SizeConstraint.RelativeYY,
                                        })
                                        local ring = N("ImageLabel",{
                                            Name="Target", Image="rbxassetid://73265255323268",
                                            ImageColor3=Color3.fromRGB(0,0,0),
                                            AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, BorderSizePixel=0,
                                            Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(22,22),
                                            SizeConstraint=Enum.SizeConstraint.RelativeYY,
                                        })
                                        SafeCall(function() ring.Parent=wheel1; wheel1.Parent=wheelFrame end)

                                        -- RGB/Hex/Alpha inputs
                                        local inputs = N("Frame",{
                                            Name="Inputs", AnchorPoint=Vector2.new(1,0.5),
                                            AutomaticSize=Enum.AutomaticSize.XY, BackgroundTransparency=1, BorderSizePixel=0,
                                            LayoutOrder=1, Position=UDim2.fromScale(1,0.5),
                                        })
                                        SafeCall(function()
                                            N("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder}).Parent=inputs
                                        end)

                                        local function makeInput(label, order, default, visible)
                                            local row=N("Frame",{Name=label,AutomaticSize=Enum.AutomaticSize.XY,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=order,Size=UDim2.fromOffset(0,38)})
                                            if visible==false then row.Visible=false end
                                            N("UIListLayout",{Padding=UDim.new(0,15),FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center}).Parent=row
                                            local lbl=N("TextLabel",{
                                                FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                                Text=label, TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                                TextTruncate=Enum.TextTruncate.AtEnd, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                                                AnchorPoint=Vector2.new(0,0.5), AutomaticSize=Enum.AutomaticSize.XY,
                                                BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=2, Position=UDim2.fromScale(0,0.5),
                                            })
                                            lbl.Parent=row
                                            local box=N("TextBox",{
                                                Name="InputBox", ClearTextOnFocus=false, CursorPosition=-1,
                                                FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                                Text=tostring(default or "255"), TextColor3=Color3.fromRGB(255,255,255), TextSize=12, TextTransparency=0.4,
                                                TextXAlignment=Enum.TextXAlignment.Left,
                                                AnchorPoint=Vector2.new(1,0.5), BackgroundTransparency=0.95, BorderSizePixel=0,
                                                ClipsDescendants=true, LayoutOrder=1, Position=UDim2.fromScale(1,0.5),
                                                Size=UDim2.fromOffset(75,25),
                                            })
                                            SafeCall(function()
                                                N("UICorner",{CornerRadius=UDim.new(0,4)}).Parent=box
                                                N("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(255,255,255),Transparency=0.9}).Parent=box
                                                N("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,10)}).Parent=box
                                                box.Parent=row
                                                row.Parent=inputs
                                            end)
                                            return box
                                        end

                                        local redBox   = makeInput("Red",   1, 255)
                                        local greenBox = makeInput("Green", 2, 255)
                                        local blueBox  = makeInput("Blue",  3, 255)
                                        local alphaBox = makeInput("Alpha", 4, 0, isAlpha)
                                        local hexBox   = makeInput("Hex",   5, "#FFFFFF")

                                        SafeCall(function()
                                            inputs.Parent=wheelFrame
                                            wheelFrame.Parent=colorOptions
                                        end)

                                        -- Color wells (new / old)
                                        SafeCall(function()
                                            local cw=N("Frame",{Name="ColorWells",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=2,Size=UDim2.fromScale(1,0)})
                                            N("UIGridLayout",{CellPadding=UDim2.fromOffset(10,0),CellSize=UDim2.new(0.5,-5,0,30),SortOrder=Enum.SortOrder.LayoutOrder}).Parent=cw

                                            local function makeWell(name, order, col, alpha)
                                                local bg=N("ImageLabel",{Name=name,Image="rbxassetid://121484455191370",ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(500,500),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=order,Size=UDim2.fromOffset(100,100)})
                                                N("UICorner").Parent=bg
                                                local c2=N("Frame",{Name="Color",AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=col or Color3.fromRGB(255,255,255),BackgroundTransparency=alpha or 0,BorderSizePixel=0,Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(1,1,1,1)})
                                                N("UICorner").Parent=c2
                                                c2.Parent=bg
                                                bg.Parent=cw
                                                return c2
                                            end
                                            local newWell = makeWell("NewColor", 0, CPF.Color, CPF.Alpha or 0)
                                            local oldWell = makeWell("OldColor", 1, CPF.Color, CPF.Alpha or 0)
                                            cw.Parent=colorOptions
                                            colorOptions.Parent=prompt

                                            -- Confirm / Cancel
                                            local interactions2=N("Frame",{Name="Interactions",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=2,Size=UDim2.fromScale(1,0)})
                                            N("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder}).Parent=interactions2
                                            N("UIPadding",{PaddingTop=UDim.new(0,10)}).Parent=interactions2

                                            local function makeBtn(label, order)
                                                local b=N("TextButton",{
                                                    FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
                                                    Text=label, TextColor3=Color3.fromRGB(255,255,255), TextSize=15, TextTransparency=0.5,
                                                    TextTruncate=Enum.TextTruncate.AtEnd, AutoButtonColor=false,
                                                    AutomaticSize=Enum.AutomaticSize.Y, BackgroundColor3=Color3.fromRGB(25,25,25),
                                                    BorderSizePixel=0, LayoutOrder=order, Size=UDim2.fromScale(1,0),
                                                })
                                                N("UICorner",{CornerRadius=UDim.new(0,10)}).Parent=b
                                                N("UIPadding",{PaddingBottom=UDim.new(0,9),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,9)}).Parent=b
                                                b.Parent=interactions2
                                                return b
                                            end
                                            local confirmBtn = makeBtn("Confirm", 0)
                                            local cancelBtn  = makeBtn("Cancel",  1)
                                            interactions2.Parent=prompt
                                            prompt.Parent=colorPicker
                                            colorPicker.Parent=base

                                            -- ── HSV logic ─────────────────────────────────────
                                            local Mouse2 = LocalPlayer and LocalPlayer:GetMouse()
                                            local WheelDown, SlideDown = false, false
                                            local hue, sat, val2 = 0, 0, 1

                                            local function clampN(v,mn,mx)
                                                local n=tonumber(v); return n and math.clamp(n,mn,mx) or mn
                                            end
                                            local function hexToRGB(hex)
                                                hex=hex:gsub("#","")
                                                if #hex~=6 then return 0,0,0 end
                                                return tonumber(hex:sub(1,2),16) or 0, tonumber(hex:sub(3,4),16) or 0, tonumber(hex:sub(5,6),16) or 0
                                            end

                                            local function applyColor()
                                                SafeCall(function()
                                                    local c=Color3.fromHSV(hue,sat,val2)
                                                    if newWell then newWell.BackgroundColor3=c end
                                                    local alp=isAlpha and clampN(alphaBox.Text,0,1) or 0
                                                    if newWell then newWell.BackgroundTransparency=alp end
                                                    colorC.BackgroundColor3=c
                                                    redBox.Text=tostring(math.floor(c.R*255+0.5))
                                                    greenBox.Text=tostring(math.floor(c.G*255+0.5))
                                                    blueBox.Text=tostring(math.floor(c.B*255+0.5))
                                                    hexBox.Text=string.format("#%02X%02X%02X",math.floor(c.R*255+0.5),math.floor(c.G*255+0.5),math.floor(c.B*255+0.5))
                                                end)
                                            end

                                            local function updateSlide(mx2)
                                                SafeCall(function()
                                                    local relX=mx2-valueSlider.AbsolutePosition.X
                                                    local clampX=math.clamp(relX,0,valueSlider.AbsoluteSize.X-valueSlide.AbsoluteSize.X)
                                                    valueSlide.Position=UDim2.new(0,clampX,0.5,0)
                                                    val2=1-(clampX/(valueSlider.AbsoluteSize.X-valueSlide.AbsoluteSize.X))
                                                    applyColor()
                                                end)
                                            end

                                            local function toPolar(v) return math.atan2(v.Y,v.X),v.Magnitude end
                                            local function updateRing(mx2,my2)
                                                SafeCall(function()
                                                    local r=wheel1.AbsoluteSize.X/2
                                                    local d=Vector2.new(mx2,my2)-wheel1.AbsolutePosition-wheel1.AbsoluteSize/2
                                                    if d.Magnitude>r then d=d.Unit*r end
                                                    ring.Position=UDim2.new(0.5,d.X,0.5,d.Y)
                                                    local phi,len=toPolar(d*Vector2.new(1,-1))
                                                    hue=((phi+math.pi)/(2*math.pi)*360)/360
                                                    sat=math.clamp(len/r,0,1)
                                                    valueSlider.BackgroundColor3=Color3.fromHSV(hue,sat,1)
                                                    applyColor()
                                                end)
                                            end

                                            local function syncRingFromHSV()
                                                SafeCall(function()
                                                    local r=wheel1.AbsoluteSize.X/2
                                                    local phi=math.rad(hue*360)
                                                    local len=sat*r
                                                    ring.Position=UDim2.new(0.5,-len*math.cos(phi),0.5,len*math.sin(phi))
                                                    valueSlider.BackgroundColor3=Color3.fromHSV(hue,sat,1)
                                                end)
                                            end
                                            local function syncSlideFromVal()
                                                SafeCall(function()
                                                    local cX=(1-val2)*math.max(0,valueSlider.AbsoluteSize.X-valueSlide.AbsoluteSize.X)
                                                    valueSlide.Position=UDim2.new(0,cX,0.5,0)
                                                end)
                                            end
                                            local function syncFromRGB()
                                                SafeCall(function()
                                                    local r=clampN(redBox.Text,0,255)
                                                    local g=clampN(greenBox.Text,0,255)
                                                    local b=clampN(blueBox.Text,0,255)
                                                    hue,sat,val2=Color3.fromRGB(r,g,b):ToHSV()
                                                    syncRingFromHSV(); syncSlideFromVal(); applyColor()
                                                end)
                                            end
                                            local function syncFromHex()
                                                SafeCall(function()
                                                    local r,g,b=hexToRGB(hexBox.Text)
                                                    redBox.Text=tostring(r); greenBox.Text=tostring(g); blueBox.Text=tostring(b)
                                                    syncFromRGB()
                                                end)
                                            end
                                            local function initFromCPF()
                                                SafeCall(function()
                                                    local c=CPF.Color
                                                    local r=math.floor(c.R*255+0.5); local g=math.floor(c.G*255+0.5); local b=math.floor(c.B*255+0.5)
                                                    redBox.Text=tostring(r); greenBox.Text=tostring(g); blueBox.Text=tostring(b)
                                                    hexBox.Text=string.format("#%02X%02X%02X",r,g,b)
                                                    if isAlpha then alphaBox.Text=tostring(CPF.Alpha or 0) end
                                                    hue,sat,val2=Color3.fromRGB(r,g,b):ToHSV()
                                                    if oldWell then oldWell.BackgroundColor3=CPF.Color; oldWell.BackgroundTransparency=CPF.Alpha or 0 end
                                                    syncRingFromHSV(); syncSlideFromVal(); applyColor()
                                                end)
                                            end

                                            -- Input connections
                                            SafeConn(wheel1.InputBegan, function(inp)
                                                SafeCall(function()
                                                    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                                                        WheelDown=true; if Mouse2 then updateRing(Mouse2.X,Mouse2.Y) end
                                                    end
                                                end)
                                            end)
                                            SafeConn(wheel1.InputEnded, function(inp)
                                                SafeCall(function()
                                                    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then WheelDown=false end
                                                end)
                                            end)
                                            SafeConn(valueSlider.InputBegan, function(inp)
                                                SafeCall(function()
                                                    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                                                        SlideDown=true; if Mouse2 then updateSlide(Mouse2.X) end
                                                    end
                                                end)
                                            end)
                                            SafeConn(valueSlider.InputEnded, function(inp)
                                                SafeCall(function()
                                                    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then SlideDown=false end
                                                end)
                                            end)
                                            SafeConn(UserInputService and UserInputService.InputChanged, function(inp)
                                                SafeCall(function()
                                                    if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
                                                        if Mouse2 then
                                                            if SlideDown then updateSlide(Mouse2.X)
                                                            elseif WheelDown then updateRing(Mouse2.X,Mouse2.Y) end
                                                        end
                                                    end
                                                end)
                                            end)
                                            SafeConn(redBox.FocusLost,   syncFromRGB)
                                            SafeConn(greenBox.FocusLost, syncFromRGB)
                                            SafeConn(blueBox.FocusLost,  syncFromRGB)
                                            SafeConn(hexBox.FocusLost,   syncFromHex)
                                            SafeConn(alphaBox.FocusLost, applyColor)

                                            -- Transition helpers
                                            local function makeCanvas2()
                                                local cv=N("CanvasGroup",{Name="ColorPickerCanvas",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=5,GroupTransparency=1,Visible=false})
                                                cv.Parent=base; return cv
                                            end
                                            local function transition2(isIn)
                                                SafeCall(function()
                                                    local cv=makeCanvas2()
                                                    local tw=Tween(cv,TweenInfo.new(0.1,Enum.EasingStyle.Sine),{GroupTransparency=isIn and 0 or 1})
                                                    colorPicker.Visible=true; colorPicker.Parent=cv
                                                    cv.Visible=true; cv.GroupTransparency=isIn and 1 or 0
                                                    tw:Play(); SafeCall(function() tw.Completed:Wait() end)
                                                    if not isIn then colorPicker.Visible=false; cv.Visible=false end
                                                    colorPicker.Parent=base; SafeCall(function() cv:Destroy() end)
                                                end)
                                            end

                                            SafeConn(cpInteract and cpInteract.MouseButton1Click, function()
                                                task.spawn(function()
                                                    SafeCall(initFromCPF)
                                                    transition2(true)
                                                end)
                                            end)
                                            SafeConn(cancelBtn and cancelBtn.MouseButton1Click, function()
                                                task.spawn(function() transition2(false) end)
                                            end)
                                            SafeConn(confirmBtn and confirmBtn.MouseButton1Click, function()
                                                task.spawn(function()
                                                    transition2(false)
                                                    SafeCall(function()
                                                        local c=Color3.fromHSV(hue,sat,val2)
                                                        CPF.Color=c
                                                        if isAlpha then CPF.Alpha=clampN(alphaBox.Text,0,1) end
                                                        colorC.BackgroundColor3=c
                                                        colorC.BackgroundTransparency=CPF.Alpha or 0
                                                        if oldWell then oldWell.BackgroundColor3=c; oldWell.BackgroundTransparency=CPF.Alpha or 0 end
                                                        if CPCfg.Callback then
                                                            task.spawn(function() SafeCall(CPCfg.Callback, CPF.Color, isAlpha and CPF.Alpha or nil) end)
                                                        end
                                                    end)
                                                end)
                                            end)

                                            -- valueSlider inside colorOptions
                                            valueSlider.Parent=colorOptions
                                        end)
                                    end)
                                    end)

                                    function CPF:SetColor(c)
                                        SafeCall(function()
                                            CPF.Color=c
                                            local colorCf=cpFrame and cpFrame:FindFirstChild("NewColor") and cpFrame.NewColor:FindFirstChild("Color")
                                            if colorCf then colorCf.BackgroundColor3=c end
                                            if colorC then colorC.BackgroundColor3=c end
                                        end)
                                    end
                                    function CPF:SetAlpha(a)
                                        SafeCall(function()
                                            CPF.Alpha=a
                                            if colorC then colorC.BackgroundTransparency=a end
                                        end)
                                    end
                                    function CPF:UpdateName(n) SafeCall(function() if cpName then cpName.Text=n end end) end
                                    function CPF:SetVisibility(s) SafeCall(function() if cpFrame then cpFrame.Visible=s end end) end
                                    return CPF
                                end

                                -- ── Header / Label / SubLabel / Paragraph / Divider / Spacer ──
                                local function SimpleTextElement(name, fs, ft, tr, sz)
                                    return function(self2, Cfg2)
                                        local F2={}
                                        SafeCall(function()
                                            local fr=N("Frame",{Name=name,AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,sz or 38)})
                                            fr.Parent=section
                                            local lbl=N("TextLabel",{
                                                Name=name.."Text",
                                                FontFace=Font.new(assets.interFont,fs or Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                                RichText=true, Text=Cfg2.Text or Cfg2.Name or "",
                                                TextColor3=Color3.fromRGB(255,255,255), TextSize=ft or 13, TextTransparency=tr or 0.5,
                                                TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
                                                AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, BorderSizePixel=0,
                                                Size=UDim2.fromScale(1,1),
                                            })
                                            if lbl then lbl.Parent=fr end
                                            function F2:UpdateName(n) SafeCall(function() if lbl then lbl.Text=n end end) end
                                            function F2:SetVisibility(s) SafeCall(function() if fr then fr.Visible=s end end) end
                                        end)
                                        return F2
                                    end
                                end

                                SecF.Header   = SimpleTextElement("Header",   Enum.FontWeight.SemiBold, 16, 0.4, 0)
                                SecF.Label    = SimpleTextElement("Label",    Enum.FontWeight.Medium,   13, 0.5, 38)
                                SecF.SubLabel = SimpleTextElement("SubLabel", Enum.FontWeight.Medium,   11, 0.7, 0)

                                function SecF:Paragraph(PCfg)
                                    local PF={}
                                    SafeCall(function()
                                        local pr=N("Frame",{Name="Paragraph",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,38)})
                                        pr.Parent=section
                                        local pul=N("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder}) if pul then pul.Parent=pr end
                                        local ph=N("TextLabel",{
                                            Name="ParagraphHeader",
                                            FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                                            RichText=true, Text=PCfg.Header or "",
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=16, TextTransparency=0.4,
                                            TextWrapped=true, AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,0),
                                        }) if ph then ph.Parent=pr end
                                        local pb=N("TextLabel",{
                                            Name="ParagraphBody",
                                            FontFace=Font.new(assets.interFont),
                                            RichText=true, Text=PCfg.Body or "",
                                            TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.5,
                                            TextWrapped=true, AutomaticSize=Enum.AutomaticSize.Y,
                                            BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=1, Size=UDim2.fromScale(1,0),
                                        }) if pb then pb.Parent=pr end
                                        function PF:UpdateHeader(n) SafeCall(function() if ph then ph.Text=n end end) end
                                        function PF:UpdateBody(n)   SafeCall(function() if pb then pb.Text=n end end) end
                                        function PF:SetVisibility(s) SafeCall(function() if pr then pr.Visible=s end end) end
                                    end)
                                    return PF
                                end

                                function SecF:Divider()
                                    local DF2={}
                                    SafeCall(function()
                                        local div=N("Frame",{Name="Divider",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,1)})
                                        div.Parent=section
                                        local dul=N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder}) if dul then dul.Parent=div end
                                        local dup=N("UIPadding",{PaddingBottom=UDim.new(0,8),PaddingTop=UDim.new(0,8)}) if dup then dup.Parent=div end
                                        local line=N("Frame",{Name="Line",BackgroundTransparency=0.9,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Size=UDim2.new(1,0,0,1)})
                                        if line then line.Parent=div end
                                        function DF2:Remove() SafeCall(function() if div then div:Destroy() end end) end
                                        function DF2:SetVisibility(s) SafeCall(function() if div then div.Visible=s end end) end
                                    end)
                                    return DF2
                                end

                                function SecF:Spacer()
                                    local SF2={}
                                    SafeCall(function()
                                        local sp=N("Frame",{Name="Spacer",BackgroundTransparency=1,BorderSizePixel=0})
                                        sp.Parent=section
                                        function SF2:Remove() SafeCall(function() if sp then sp:Destroy() end end) end
                                        function SF2:SetVisibility(s) SafeCall(function() if sp then sp.Visible=s end end) end
                                    end)
                                    return SF2
                                end

                            end) -- section SafeCall
                            return SecF
                        end -- Section

                        elements1.Parent = content

                        local function SelectTab()
                            SafeCall(function()
                                local ease=0.15
                                if currentTabInstance then currentTabInstance.Parent=nil end
                                for _,v in pairs(tabSwitchersScrollingFrame:GetDescendants()) do
                                    if v.Name=="TabSwitcher" then
                                        Tween(v,TweenInfo.new(ease,Enum.EasingStyle.Sine),{BackgroundTransparency=1}):Play()
                                        local s=v:FindFirstChild("TabSwitcherUIStroke")
                                        if s then Tween(s,TweenInfo.new(ease,Enum.EasingStyle.Sine),{Transparency=1}):Play() end
                                    end
                                end
                                tabs[tabSwitcher].Parent=content
                                currentTabInstance=tabs[tabSwitcher]
                                if currentTabLabel then currentTabLabel.Text=Cfg.Name or "" end
                                Tween(tabSwitcher,TweenInfo.new(ease,Enum.EasingStyle.Sine),{BackgroundTransparency=0.98}):Play()
                                local tss=tabSwitcher:FindFirstChild("TabSwitcherUIStroke")
                                if tss then Tween(tss,TweenInfo.new(ease,Enum.EasingStyle.Sine),{Transparency=0.95}):Play() end
                            end)
                        end

                        SafeConn(tabSwitcher and tabSwitcher.MouseButton1Click, SelectTab)
                        function TF:Select() SelectTab() end
                        tabs[tabSwitcher] = elements1
                    end) -- tab SafeCall
                    return TF
                end -- Tab
            end) -- TabGroup SafeCall
            return SGF
        end -- TabGroup

    -- ════════════════════════════════════════════════════════════
    --  Notify
    -- ════════════════════════════════════════════════════════════
    function WindowFunctions:Notify(NCfg)
        local NF = {}
        SafeCall(function()
            local notif = N("Frame",{
                Name="Notification", AnchorPoint=Vector2.new(0.5,0.5),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=Color3.fromRGB(15,15,15), BorderSizePixel=0,
                Position=UDim2.fromScale(0.5,0.5), Size=UDim2.fromOffset(NCfg.SizeX or 250,0),
            })
            notif.Parent=notifications
            SafeCall(function()
                local nsk=N("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(255,255,255),Transparency=0.9}) if nsk then nsk.Parent=notif end
                local ncr=N("UICorner",{CornerRadius=UDim.new(0,10)}) if ncr then ncr.Parent=notif end
            end)
            local nsc=N("UIScale",{Name="NotificationUIScale",Scale=0}) if nsc then nsc.Parent=notif end

            local nInfo=N("Frame",{Name="NotificationInformation",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
            SafeCall(function()
                local nTitle=N("TextLabel",{
                    Name="NotificationTitle",
                    FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
                    RichText=true, Text=NCfg.Title or "",
                    TextColor3=Color3.fromRGB(255,255,255), TextSize=13, TextTransparency=0.2,
                    TextTruncate=Enum.TextTruncate.SplitWord, TextXAlignment=Enum.TextXAlignment.Left,
                    TextYAlignment=Enum.TextYAlignment.Top, AutomaticSize=Enum.AutomaticSize.XY,
                    BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.new(1,-12,0,0),
                })
                local ntp=N("UIPadding",{PaddingRight=UDim.new(0,25)}) if ntp and nTitle then ntp.Parent=nTitle end
                if nTitle then nTitle.Parent=nInfo end

                local nDesc=N("TextLabel",{
                    Name="NotificationDescription",
                    FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),
                    Text=NCfg.Description or "", RichText=true,
                    TextColor3=Color3.fromRGB(255,255,255), TextSize=11, TextTransparency=0.5,
                    TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
                    AutomaticSize=Enum.AutomaticSize.XY, BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.new(1,-12,0,0),
                })
                local ndp=N("UIPadding",{PaddingRight=UDim.new(0,25),PaddingTop=UDim.new(0,17)}) if ndp and nDesc then ndp.Parent=nDesc end
                if nDesc then nDesc.Parent=nInfo end

                local nip=N("UIPadding",{PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,10)})
                if nip then nip.Parent=nInfo end
                nInfo.Parent=notif

                function NF:UpdateTitle(t) SafeCall(function() if nTitle then nTitle.Text=t end end) end
                function NF:UpdateDescription(d) SafeCall(function() if nDesc then nDesc.Text=d end end) end
            end)

            local tweensN = {
                In  = Tween(nsc, TweenInfo.new(0.2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Scale=NCfg.Scale or 1}),
                Out = Tween(nsc, TweenInfo.new(0.2,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Scale=0}),
            }

            local styles={
                None=function(i) SafeCall(function() i:Destroy() end) end,
                Confirm=function(i) SafeCall(function() i.Text="✓" end) end,
                Cancel =function(i) SafeCall(function() i.Text="✗" end) end,
            }

            local interactable
            SafeCall(function()
                local nc=N("Frame",{Name="NotificationControls",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
                interactable=N("TextButton",{
                    Name="Interactable",
                    FontFace=Font.new(assets.interFont),
                    Text="✓", TextColor3=Color3.fromRGB(255,255,255), TextSize=17, TextTransparency=0.2,
                    AnchorPoint=Vector2.new(1,0.5), AutomaticSize=Enum.AutomaticSize.XY,
                    BackgroundTransparency=1, BorderSizePixel=0, LayoutOrder=1, Position=UDim2.fromScale(1,0.5),
                })
                if interactable then interactable.Parent=nc end
                local ncp=N("UIPadding",{PaddingBottom=UDim.new(0,6),PaddingRight=UDim.new(0,13),PaddingTop=UDim.new(0,6)}) if ncp then ncp.Parent=nc end
                nc.Parent=notif

                local styleFn = styles[NCfg.Style] or styles.None
                styleFn(interactable)

                if interactable and interactable.Parent then
                    SafeConn(interactable.MouseButton1Click, function()
                        NF:Cancel()
                        if NCfg.Callback then task.spawn(function() SafeCall(NCfg.Callback) end) end
                    end)
                end
            end)

            local animTask = task.spawn(function()
                tweensN.In:Play()
                local lifetime = NCfg.Lifetime or 3
                if lifetime ~= 0 then
                    task.wait(lifetime)
                    local out=tweensN.Out; out:Play()
                    SafeCall(function() out.Completed:Wait() end)
                    SafeCall(function() notif:Destroy() end)
                end
            end)

            function NF:Cancel()
                SafeCall(function() task.cancel(animTask) end)
                SafeCall(function()
                    local out=tweensN.Out; out:Play()
                    out.Completed:Wait()
                    notif:Destroy()
                end)
            end
            function NF:Resize(x) SafeCall(function() notif.Size=UDim2.fromOffset(x or 250,0) end) end
        end)
        return NF
    end

    -- ════════════════════════════════════════════════════════════
    --  Dialog
    -- ════════════════════════════════════════════════════════════
    function WindowFunctions:Dialog(DCfg)
        local DlgF={}
        SafeCall(function()
            local canvas=N("CanvasGroup",{Name="DialogCanvas",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),GroupTransparency=1})
            canvas.Parent=base

            local dlg=N("Frame",{Name="Dialog",BackgroundTransparency=0.5,BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
            SafeCall(function() local cr=N("UICorner",{CornerRadius=UDim.new(0,10)}) if cr then cr.Parent=dlg end end)

            local prompt=N("Frame",{Name="Prompt",AnchorPoint=Vector2.new(0.5,0.5),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(15,15,15),BorderSizePixel=0,Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(280,0)})
            SafeCall(function()
                local psk=N("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(255,255,255),Transparency=0.9}) if psk then psk.Parent=prompt end
                local pcr=N("UICorner",{CornerRadius=UDim.new(0,10)}) if pcr then pcr.Parent=prompt end
                local pup=N("UIPadding",{PaddingBottom=UDim.new(0,20),PaddingLeft=UDim.new(0,20),PaddingRight=UDim.new(0,20),PaddingTop=UDim.new(0,20)}) if pup then pup.Parent=prompt end
                local pul=N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder}) if pul then pul.Parent=prompt end
            end)

            local ph=N("TextLabel",{Name="ParagraphHeader",FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),RichText=true,Text=DCfg.Title or "",TextColor3=Color3.fromRGB(255,255,255),TextSize=18,TextTransparency=0.4,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,0)})
            if ph then ph.Parent=prompt end
            local pb=N("TextLabel",{Name="ParagraphBody",FontFace=Font.new(assets.interFont,Enum.FontWeight.Medium,Enum.FontStyle.Normal),RichText=true,Text=DCfg.Description or "",TextColor3=Color3.fromRGB(255,255,255),TextSize=14,TextTransparency=0.5,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=1,Size=UDim2.fromScale(1,0)})
            if pb then pb.Parent=prompt end

            local interactions=N("Frame",{Name="Interactions",AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=1,Size=UDim2.fromScale(1,0)})
            SafeCall(function()
                local iul=N("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder}) if iul then iul.Parent=interactions end
                local iup=N("UIPadding",{PaddingTop=UDim.new(0,20)}) if iup then iup.Parent=interactions end
                interactions.Parent=prompt
                prompt.Parent=dlg; dlg.Parent=canvas
            end)

            local cIn=Tween(canvas,TweenInfo.new(0.1,Enum.EasingStyle.Sine),{GroupTransparency=0})
            local cOut=Tween(canvas,TweenInfo.new(0.1,Enum.EasingStyle.Sine),{GroupTransparency=1})

            local function dlgIn() SafeCall(function() cIn:Play(); cIn.Completed:Wait(); dlg.Parent=base end) end
            local function dlgOut()
                SafeCall(function()
                    dlg.Parent=canvas; cOut:Play(); cOut.Completed:Wait()
                    SafeCall(function() canvas:Destroy() end)
                end)
            end

            for _,v in pairs(DCfg.Buttons or {}) do
                SafeCall(function()
                    local btn=N("TextButton",{Name="Button",
                        FontFace=Font.new(assets.interFont,Enum.FontWeight.SemiBold,Enum.FontStyle.Normal),
                        Text=v.Name or "", TextColor3=Color3.fromRGB(255,255,255), TextSize=15, TextTransparency=0.5,
                        TextTruncate=Enum.TextTruncate.AtEnd, AutoButtonColor=false, AutomaticSize=Enum.AutomaticSize.Y,
                        BackgroundColor3=Color3.fromRGB(25,25,25), BorderSizePixel=0, Size=UDim2.fromScale(1,0),
                    })
                    SafeCall(function()
                        local bup=N("UIPadding",{PaddingBottom=UDim.new(0,9),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,9)}) if bup then bup.Parent=btn end
                        local bcr=N("UICorner",{CornerRadius=UDim.new(0,10)}) if bcr then bcr.Parent=btn end
                        btn.Parent=interactions
                    end)
                    SafeConn(btn and btn.MouseEnter, function() Tween(btn,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{BackgroundTransparency=0.3,TextTransparency=0.6}):Play() end)
                    SafeConn(btn and btn.MouseLeave, function() Tween(btn,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{BackgroundTransparency=0,TextTransparency=0.5}):Play() end)
                    SafeConn(btn and btn.MouseButton1Click, function()
                        SafeCall(function()
                            if canvas.GroupTransparency~=0 then return end
                            if v.Callback then v.Callback() end
                            task.spawn(dlgOut)
                        end)
                    end)
                end)
            end

            task.spawn(dlgIn)
            function DlgF:UpdateTitle(t) SafeCall(function() if ph then ph.Text=t end end) end
            function DlgF:UpdateDescription(d) SafeCall(function() if pb then pb.Text=d end end) end
            function DlgF:Cancel() task.spawn(dlgOut) end
        end)
        return DlgF
    end

    -- ════════════════════════════════════════════════════════════
    --  Window utility methods
    -- ════════════════════════════════════════════════════════════
    function WindowFunctions:SetNotificationsState(s) SafeCall(function() notifications.Visible=s end) end
    function WindowFunctions:GetNotificationsState()  return notifications and notifications.Visible end
    function WindowFunctions:SetState(s) SafeCall(function() windowState=s; base.Visible=s end) end
    function WindowFunctions:GetState()  return windowState end
    function WindowFunctions:SetSize(s)  SafeCall(function() base.Size=s end) end
    function WindowFunctions:GetSize()   return base.Size end
    function WindowFunctions:SetScale(s) SafeCall(function()
        local sc=base:FindFirstChildOfClass("UIScale"); if sc then sc.Scale=s end
    end) end
    function WindowFunctions:GetScale() SafeCall(function()
        local sc=base:FindFirstChildOfClass("UIScale"); return sc and sc.Scale or 1
    end) end
    function WindowFunctions:SetAcrylicBlurState(s) SafeCall(function() acrylicBlur=s; base.BackgroundTransparency=s and 0.05 or 0 end) end
    function WindowFunctions:GetAcrylicBlurState() return acrylicBlur end
    function WindowFunctions:SetKeybind(k) SafeCall(function() MenuKeybind=k end) end

    local function _SetUserInfoState(state)
        SafeCall(function()
            if not (informationGroup) then return end
            local h=informationGroup:FindFirstChild("Headshot")
            local uadf=informationGroup:FindFirstChild("UserAndDisplayFrame")
            if h then h.Image = state and (isReady and headshotImage or "rbxassetid://0") or assets.userInfoBlurred end
            if uadf then
                local un=uadf:FindFirstChild("Username")
                local dn=uadf:FindFirstChild("DisplayName")
                local name=LocalPlayer and LocalPlayer.Name or "Player"
                local dname=LocalPlayer and LocalPlayer.DisplayName or "Player"
                if un then un.Text=state and "@"..name or "@"..string.rep(".",#name) end
                if dn then dn.Text=state and dname or string.rep(".",#dname) end
            end
        end)
    end

    local showUserInfo = Settings.ShowUserInfo ~= nil and Settings.ShowUserInfo or true
    _SetUserInfoState(showUserInfo)
    function WindowFunctions:SetUserInfoState(s) _SetUserInfoState(s) end
    function WindowFunctions:GetUserInfoState() return showUserInfo end

    local onUnloadCB
    function WindowFunctions:Unload()
        SafeCall(function() if onUnloadCB then onUnloadCB() end end)
        SafeCall(function() macLib:Destroy() end)
    end
    function WindowFunctions.onUnloaded(cb) onUnloadCB=cb end

    -- Menu toggle keybind
    local MenuKeybind = Settings.Keybind or Enum.KeyCode.RightControl
    local function ToggleMenu()
        SafeCall(function()
            local state = not WindowFunctions:GetState()
            WindowFunctions:SetState(state)
            WindowFunctions:Notify({
                Title       = Settings.Title or "MacLib",
                Description = (state and "Maximized " or "Minimized ").."the menu. Use "..tostring(MenuKeybind.Name).." to toggle.",
                Lifetime    = 5,
            })
        end)
    end
    SafeConn(UserInputService and UserInputService.InputEnded, function(inp, gpe)
        SafeCall(function()
            if gpe then return end
            if inp.KeyCode == MenuKeybind then ToggleMenu() end
        end)
    end)
    SafeConn(minimize and minimize.MouseButton1Click, ToggleMenu)
    SafeConn(exit and exit.MouseButton1Click, function()
        SafeCall(function() WindowFunctions:Unload() end)
    end)

    -- Preload assets then show
    SafeCall(function()
        local aList={}
        for _,id in pairs(assets) do table.insert(aList,id) end
        ContentProvider:PreloadAsync(aList)
    end)
    SafeCall(function() macLib.Enabled=true end)
    windowState=true

    return WindowFunctions
end

-- ════════════════════════════════════════════════════════════════
--  Demo
-- ════════════════════════════════════════════════════════════════
function MacLib:Demo()
    local Window = MacLib:Window({
        Title="MacLib Demo", Subtitle="Safety-Hardened Edition",
        Size=UDim2.fromOffset(868,650), DragStyle=1,
        DisabledWindowControls={}, ShowUserInfo=true,
        Keybind=Enum.KeyCode.RightControl, AcrylicBlur=true,
    })

    Window:GlobalSetting({Name="UI Blur",   Default=true, Callback=function(v) Window:SetAcrylicBlurState(v) end})
    Window:GlobalSetting({Name="Notifs",    Default=true, Callback=function(v) Window:SetNotificationsState(v) end})
    Window:GlobalSetting({Name="User Info", Default=true, Callback=function(v) Window:SetUserInfoState(v) end})

    local TG = Window:TabGroup()
    local Main = TG:Tab({Name="Demo", Image="rbxassetid://18821914323"})

    local S = Main:Section({Side="Left"})
    S:Header({Text="Controls"})
    S:Button({Name="Open Dialog", Callback=function()
        Window:Dialog({
            Title="MacLib Demo",
            Description="Lorem ipsum dolor sit amet.",
            Buttons={
                {Name="Confirm", Callback=function() print("Confirmed") end},
                {Name="Cancel"},
            }
        })
    end})
    S:Toggle({Name="Toggle", Default=false, Callback=function(v) print("Toggle:",v) end})
    S:Slider({Name="Slider", Default=50, Minimum=0, Maximum=100, DisplayMethod="Percent", Callback=function(v) print("Slider:",v) end})
    S:Input({Name="Input", Placeholder="Type here...", AcceptedCharacters="All", Callback=function(t) print("Input:",t) end})
    S:Keybind({Name="Keybind", Callback=function(k) print("Key:",k) end})
    S:Dropdown({Name="Dropdown", Multi=false, Required=true, Options={"Option 1","Option 2","Option 3"}, Default=1, Callback=function(v) print("DD:",v) end})
    S:Divider()
    S:Label({Text="Label text here."})
    S:SubLabel({Text="Sub-label text."})
    S:Paragraph({Header="Paragraph", Body="Body text for the paragraph element."})

    Main:Select()
end

return MacLib
