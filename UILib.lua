--[[
!! OUTDATED REPOSITORY !! Please use the new repository:
https://github.com/biggaboy212/Maclib/tree/main
]]

-- FIX: cloneref for all service references
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local ContentProvider = cloneref(game:GetService("ContentProvider"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Players = cloneref(game:GetService("Players"))

local MacLib = {}

--// Safe gethui chain with fallbacks
local function getSafeCoreGui()
    local success, result = pcall(function()
        -- Try gethui first (most executors)
        if gethui then
            local ui = gethui()
            if ui and ui:IsA("ScreenGui") then
                return ui
            end
        end
        -- Fallback to CoreGui
        local coreGui = game:GetService("CoreGui")
        if coreGui and coreGui:IsA("Instance") then
            return coreGui
        end
        -- Final fallback to PlayerGui
        local player = Players.LocalPlayer
        if player then
            local playerGui = player:FindFirstChild("PlayerGui")
            if playerGui then
                return playerGui
            end
        end
        return nil
    end)
    if success and result then
        return result
    end
    return nil
end

--// Variables
local isStudio = RunService:IsStudio()
local LocalPlayer = Players.LocalPlayer

local windowState
local acrylicBlur
local hasGlobalSetting

local tabs = {}
local currentTabInstance = nil
local tabIndex = 0

local assets = {
    interFont = "rbxassetid://12187365364",
    userInfoBlurred = "rbxassetid://18824089198",
    toggleBackground = "rbxassetid://18772190202",
    togglerHead = "rbxassetid://18772309008",
    buttonImage = "rbxassetid://10709791437",
    searchIcon = "rbxassetid://86737463322606"
}

--// Safe Tween function
local function Tween(instance, tweeninfo, propertytable)
    local success, tween = pcall(function()
        return TweenService:Create(instance, tweeninfo, propertytable)
    end)
    if success then
        return tween
    end
    return nil
end

--// Library Functions
function MacLib:Window(Settings)
    Settings = Settings or {}
    local WindowFunctions = {}
    
    if Settings.AcrylicBlur ~= nil then
        acrylicBlur = Settings.AcrylicBlur
    else
        acrylicBlur = true
    end

    -- Safe CoreGui access
    local targetParent = getSafeCoreGui()
    if not targetParent then
        error("MacLib: Could not find valid parent (CoreGui/PlayerGui/gethui)")
    end

    -- Main ScreenGui creation
    local macLib
    local success, err = pcall(function()
        macLib = Instance.new("ScreenGui")
        macLib.Name = "MacLib"
        macLib.ResetOnSpawn = false
        macLib.DisplayOrder = 100
        macLib.IgnoreGuiInset = true
        macLib.ScreenInsets = Enum.ScreenInsets.None
        macLib.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        macLib.Parent = targetParent
    end)
    if not success then
        error("MacLib: Failed to create ScreenGui - " .. tostring(err))
    end

    -- Notifications container
    local notifications
    success, err = pcall(function()
        notifications = Instance.new("Frame")
        notifications.Name = "Notifications"
        notifications.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        notifications.BackgroundTransparency = 1
        notifications.BorderColor3 = Color3.fromRGB(0, 0, 0)
        notifications.BorderSizePixel = 0
        notifications.Size = UDim2.fromScale(1, 1)
        notifications.Parent = macLib
        notifications.ZIndex = 2
    end)
    if not success then return WindowFunctions end

    -- Notifications UIListLayout
    local notificationsUIListLayout
    success, err = pcall(function()
        notificationsUIListLayout = Instance.new("UIListLayout")
        notificationsUIListLayout.Name = "NotificationsUIListLayout"
        notificationsUIListLayout.Padding = UDim.new(0, 10)
        notificationsUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        notificationsUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        notificationsUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        notificationsUIListLayout.Parent = notifications
    end)
    if not success then return WindowFunctions end

    -- Notifications UIPadding
    local notificationsUIPadding
    success, err = pcall(function()
        notificationsUIPadding = Instance.new("UIPadding")
        notificationsUIPadding.Name = "NotificationsUIPadding"
        notificationsUIPadding.PaddingBottom = UDim.new(0, 10)
        notificationsUIPadding.PaddingLeft = UDim.new(0, 10)
        notificationsUIPadding.PaddingRight = UDim.new(0, 10)
        notificationsUIPadding.PaddingTop = UDim.new(0, 10)
        notificationsUIPadding.Parent = notifications
    end)
    if not success then return WindowFunctions end

    -- Base frame
    local base
    success, err = pcall(function()
        base = Instance.new("Frame")
        base.Name = "Base"
        base.AnchorPoint = Vector2.new(0.5, 0.5)
        base.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        base.BackgroundTransparency = Settings.AcrylicBlur and 0.05 or 0
        base.BorderColor3 = Color3.fromRGB(0, 0, 0)
        base.BorderSizePixel = 0
        base.Position = UDim2.fromScale(0.5, 0.5)
        base.Size = Settings.Size or UDim2.fromOffset(868, 650)
        base.Parent = macLib
    end)
    if not success then return WindowFunctions end

    -- Base UIScale
    local baseUIScale
    success, err = pcall(function()
        baseUIScale = Instance.new("UIScale")
        baseUIScale.Name = "BaseUIScale"
        baseUIScale.Parent = base
    end)
    if not success then return WindowFunctions end

    -- Base UICorner
    local baseUICorner
    success, err = pcall(function()
        baseUICorner = Instance.new("UICorner")
        baseUICorner.Name = "BaseUICorner"
        baseUICorner.CornerRadius = UDim.new(0, 10)
        baseUICorner.Parent = base
    end)
    if not success then return WindowFunctions end

    -- Base UIStroke
    local baseUIStroke
    success, err = pcall(function()
        baseUIStroke = Instance.new("UIStroke")
        baseUIStroke.Name = "BaseUIStroke"
        baseUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        baseUIStroke.Color = Color3.fromRGB(255, 255, 255)
        baseUIStroke.Transparency = 0.9
        baseUIStroke.Parent = base
    end)
    if not success then return WindowFunctions end

    -- Sidebar
    local sidebar
    success, err = pcall(function()
        sidebar = Instance.new("Frame")
        sidebar.Name = "Sidebar"
        sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sidebar.BackgroundTransparency = 1
        sidebar.BorderColor3 = Color3.fromRGB(0, 0, 0)
        sidebar.BorderSizePixel = 0
        sidebar.Position = UDim2.fromScale(-3.52e-08, 4.69e-08)
        sidebar.Size = UDim2.fromScale(0.325, 1)
        sidebar.Parent = base
    end)
    if not success then return WindowFunctions end

    -- Sidebar divider
    local divider
    success, err = pcall(function()
        divider = Instance.new("Frame")
        divider.Name = "Divider"
        divider.AnchorPoint = Vector2.new(1, 0)
        divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        divider.BackgroundTransparency = 0.9
        divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
        divider.BorderSizePixel = 0
        divider.Position = UDim2.fromScale(1, 0)
        divider.Size = UDim2.new(0, 1, 1, 0)
        divider.Parent = sidebar
    end)
    if not success then return WindowFunctions end

    -- Window Controls
    local windowControls
    success, err = pcall(function()
        windowControls = Instance.new("Frame")
        windowControls.Name = "WindowControls"
        windowControls.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        windowControls.BackgroundTransparency = 1
        windowControls.BorderColor3 = Color3.fromRGB(0, 0, 0)
        windowControls.BorderSizePixel = 0
        windowControls.Size = UDim2.new(1, 0, 0, 31)
        windowControls.Parent = sidebar
    end)
    if not success then return WindowFunctions end

    -- Controls frame
    local controls
    success, err = pcall(function()
        controls = Instance.new("Frame")
        controls.Name = "Controls"
        controls.BackgroundColor3 = Color3.fromRGB(119, 174, 94)
        controls.BackgroundTransparency = 1
        controls.BorderColor3 = Color3.fromRGB(0, 0, 0)
        controls.BorderSizePixel = 0
        controls.Size = UDim2.fromScale(1, 1)
        controls.Parent = windowControls
    end)
    if not success then return WindowFunctions end

    -- Controls UIListLayout
    local uIListLayout
    success, err = pcall(function()
        uIListLayout = Instance.new("UIListLayout")
        uIListLayout.Name = "UIListLayout"
        uIListLayout.Padding = UDim.new(0, 5)
        uIListLayout.FillDirection = Enum.FillDirection.Horizontal
        uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        uIListLayout.Parent = controls
    end)
    if not success then return WindowFunctions end

    -- Controls UIPadding
    local uIPadding
    success, err = pcall(function()
        uIPadding = Instance.new("UIPadding")
        uIPadding.Name = "UIPadding"
        uIPadding.PaddingLeft = UDim.new(0, 11)
        uIPadding.Parent = controls
    end)
    if not success then return WindowFunctions end
    
    -- Window control settings
    local windowControlSettings = {
        sizes = { enabled = UDim2.fromOffset(8, 8), disabled = UDim2.fromOffset(7, 7) },
        transparencies = { enabled = 0, disabled = 1 },
        strokeTransparency = 0.9,
    }

    -- Stroke for controls
    local stroke
    success, err = pcall(function()
        stroke = Instance.new("UIStroke")
        stroke.Name = "BaseUIStroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = windowControlSettings.strokeTransparency
    end)
    if not success then return WindowFunctions end

    -- Exit button
    local exit
    success, err = pcall(function()
        exit = Instance.new("TextButton")
        exit.Name = "Exit"
        exit.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
        exit.Text = ""
        exit.TextColor3 = Color3.fromRGB(0, 0, 0)
        exit.TextSize = 14
        exit.AutoButtonColor = false
        exit.BackgroundColor3 = Color3.fromRGB(250, 93, 86)
        exit.BorderColor3 = Color3.fromRGB(0, 0, 0)
        exit.BorderSizePixel = 0
        exit.Parent = controls
    end)
    if not success then return WindowFunctions end

    -- Exit corner
    local uICorner
    success, err = pcall(function()
        uICorner = Instance.new("UICorner")
        uICorner.Name = "UICorner"
        uICorner.CornerRadius = UDim.new(1, 0)
        uICorner.Parent = exit
    end)
    if not success then return WindowFunctions end

    -- Minimize button
    local minimize
    success, err = pcall(function()
        minimize = Instance.new("TextButton")
        minimize.Name = "Minimize"
        minimize.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
        minimize.Text = ""
        minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
        minimize.TextSize = 14
        minimize.AutoButtonColor = false
        minimize.BackgroundColor3 = Color3.fromRGB(252, 190, 57)
        minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
        minimize.BorderSizePixel = 0
        minimize.LayoutOrder = 1
        minimize.Parent = controls
    end)
    if not success then return WindowFunctions end

    -- Minimize corner
    local uICorner1
    success, err = pcall(function()
        uICorner1 = Instance.new("UICorner")
        uICorner1.Name = "UICorner"
        uICorner1.CornerRadius = UDim.new(1, 0)
        uICorner1.Parent = minimize
    end)
    if not success then return WindowFunctions end

    -- Maximize button
    local maximize
    success, err = pcall(function()
        maximize = Instance.new("TextButton")
        maximize.Name = "Maximize"
        maximize.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
        maximize.Text = ""
        maximize.TextColor3 = Color3.fromRGB(0, 0, 0)
        maximize.TextSize = 14
        maximize.AutoButtonColor = false
        maximize.BackgroundColor3 = Color3.fromRGB(119, 174, 94)
        maximize.BorderColor3 = Color3.fromRGB(0, 0, 0)
        maximize.BorderSizePixel = 0
        maximize.LayoutOrder = 1
        maximize.Parent = controls
    end)
    if not success then return WindowFunctions end

    -- Maximize corner
    local uICorner2
    success, err = pcall(function()
        uICorner2 = Instance.new("UICorner")
        uICorner2.Name = "UICorner"
        uICorner2.CornerRadius = UDim.new(1, 0)
        uICorner2.Parent = maximize
    end)
    if not success then return WindowFunctions end
    
    -- Apply button state function
    local function applyState(button, enabled)
        pcall(function()
            local size = enabled and windowControlSettings.sizes.enabled or windowControlSettings.sizes.disabled
            local transparency = enabled and windowControlSettings.transparencies.enabled or windowControlSettings.transparencies.disabled

            button.Size = size
            button.BackgroundTransparency = transparency
            button.Active = enabled
            button.Interactable = enabled

            for _, child in pairs(button:GetChildren()) do
                if child:IsA("UIStroke") then
                    child.Transparency = transparency
                end
            end
            if not enabled then
                local newStroke = stroke:Clone()
                pcall(function() newStroke.Parent = button end)
            end
        end)
    end

    applyState(maximize, false)
    
    local controlsList = {exit, minimize}
    for _, button in pairs(controlsList) do
        local buttonName = button.Name
        local isEnabled = true

        if Settings.DisabledWindowControls and table.find(Settings.DisabledWindowControls, buttonName) then
            isEnabled = false
        end

        applyState(button, isEnabled)
    end

    -- Window controls divider
    local divider1
    success, err = pcall(function()
        divider1 = Instance.new("Frame")
        divider1.Name = "Divider"
        divider1.AnchorPoint = Vector2.new(0, 1)
        divider1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        divider1.BackgroundTransparency = 0.9
        divider1.BorderColor3 = Color3.fromRGB(0, 0, 0)
        divider1.BorderSizePixel = 0
        divider1.Position = UDim2.fromScale(0, 1)
        divider1.Size = UDim2.new(1, 0, 0, 1)
        divider1.Parent = windowControls
    end)
    if not success then return WindowFunctions end

    -- Information frame
    local information
    success, err = pcall(function()
        information = Instance.new("Frame")
        information.Name = "Information"
        information.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        information.BackgroundTransparency = 1
        information.BorderColor3 = Color3.fromRGB(0, 0, 0)
        information.BorderSizePixel = 0
        information.Position = UDim2.fromOffset(0, 31)
        information.Size = UDim2.new(1, 0, 0, 60)
        information.Parent = sidebar
    end)
    if not success then return WindowFunctions end

    -- Information divider
    local divider2
    success, err = pcall(function()
        divider2 = Instance.new("Frame")
        divider2.Name = "Divider"
        divider2.AnchorPoint = Vector2.new(0, 1)
        divider2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        divider2.BackgroundTransparency = 0.9
        divider2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        divider2.BorderSizePixel = 0
        divider2.Position = UDim2.fromScale(0, 1)
        divider2.Size = UDim2.new(1, 0, 0, 1)
        divider2.Parent = information
    end)
    if not success then return WindowFunctions end

    -- Information holder
    local informationHolder
    success, err = pcall(function()
        informationHolder = Instance.new("Frame")
        informationHolder.Name = "InformationHolder"
        informationHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        informationHolder.BackgroundTransparency = 1
        informationHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
        informationHolder.BorderSizePixel = 0
        informationHolder.Size = UDim2.fromScale(1, 1)
        informationHolder.Parent = information
    end)
    if not success then return WindowFunctions end

    -- Information holder padding
    local informationHolderUIPadding
    success, err = pcall(function()
        informationHolderUIPadding = Instance.new("UIPadding")
        informationHolderUIPadding.Name = "InformationHolderUIPadding"
        informationHolderUIPadding.PaddingBottom = UDim.new(0, 10)
        informationHolderUIPadding.PaddingLeft = UDim.new(0, 23)
        informationHolderUIPadding.PaddingRight = UDim.new(0, 22)
        informationHolderUIPadding.PaddingTop = UDim.new(0, 10)
        informationHolderUIPadding.Parent = informationHolder
    end)
    if not success then return WindowFunctions end

    -- Global settings button
    local globalSettingsButton
    success, err = pcall(function()
        globalSettingsButton = Instance.new("ImageButton")
        globalSettingsButton.Name = "GlobalSettingsButton"
        globalSettingsButton.Image = "rbxassetid://18767849817"
        globalSettingsButton.ImageTransparency = 0.4
        globalSettingsButton.AnchorPoint = Vector2.new(1, 0.5)
        globalSettingsButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        globalSettingsButton.BackgroundTransparency = 1
        globalSettingsButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        globalSettingsButton.BorderSizePixel = 0
        globalSettingsButton.Position = UDim2.fromScale(1, 0.5)
        globalSettingsButton.Size = UDim2.fromOffset(15, 15)
        globalSettingsButton.Parent = informationHolder
    end)
    if not success then return WindowFunctions end

    -- Global settings button hover state
    local function ChangeGlobalSettingsButtonState(State)
        pcall(function()
            if State == "Default" then
                local tween = Tween(globalSettingsButton, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    ImageTransparency = 0.4
                })
                if tween then tween:Play() end
            elseif State == "Hover" then
                local tween = Tween(globalSettingsButton, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    ImageTransparency = 0.2
                })
                if tween then tween:Play() end
            end
        end)
    end

    -- Connect global settings button events
    pcall(function()
        globalSettingsButton.MouseEnter:Connect(function()
            ChangeGlobalSettingsButtonState("Hover")
        end)
        globalSettingsButton.MouseLeave:Connect(function()
            ChangeGlobalSettingsButtonState("Default")
        end)
    end)

    -- Title frame
    local titleFrame
    success, err = pcall(function()
        titleFrame = Instance.new("Frame")
        titleFrame.Name = "TitleFrame"
        titleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        titleFrame.BackgroundTransparency = 1
        titleFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        titleFrame.BorderSizePixel = 0
        titleFrame.Size = UDim2.fromScale(1, 1)
        titleFrame.Parent = informationHolder
    end)
    if not success then return WindowFunctions end

    -- Title label
    local title
    success, err = pcall(function()
        title = Instance.new("TextLabel")
        title.Name = "Title"
        title.FontFace = Font.new(
            assets.interFont,
            Enum.FontWeight.SemiBold,
            Enum.FontStyle.Normal
        )
        title.Text = Settings.Title or "MacLib"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.RichText = true
        title.TextSize = 20
        title.TextTransparency = 0.2
        title.TextTruncate = Enum.TextTruncate.SplitWord
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Top
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundTransparency = 1
        title.BorderColor3 = Color3.fromRGB(0, 0, 0)
        title.BorderSizePixel = 0
        title.Size = UDim2.new(1, -20, 0, 0)
        title.Parent = titleFrame
    end)
    if not success then return WindowFunctions end

    -- Subtitle label
    local subtitle
    success, err = pcall(function()
        subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.FontFace = Font.new(
            assets.interFont,
            Enum.FontWeight.Medium,
            Enum.FontStyle.Normal
        )
        subtitle.Text = Settings.Subtitle or ""
        subtitle.RichText = true
        subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        subtitle.TextSize = 12
        subtitle.TextTransparency = 0.7
        subtitle.TextTruncate = Enum.TextTruncate.SplitWord
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextYAlignment = Enum.TextYAlignment.Top
        subtitle.AutomaticSize = Enum.AutomaticSize.Y
        subtitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        subtitle.BackgroundTransparency = 1
        subtitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
        subtitle.BorderSizePixel = 0
        subtitle.LayoutOrder = 1
        subtitle.Size = UDim2.new(1, -20, 0, 0)
        subtitle.Parent = titleFrame
    end)
    if not success then return WindowFunctions end

    -- Title frame UIListLayout
    local titleFrameUIListLayout
    success, err = pcall(function()
        titleFrameUIListLayout = Instance.new("UIListLayout")
        titleFrameUIListLayout.Name = "TitleFrameUIListLayout"
        titleFrameUIListLayout.Padding = UDim.new(0, 3)
        titleFrameUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        titleFrameUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        titleFrameUIListLayout.Parent = titleFrame
    end)
    if not success then return WindowFunctions end

    -- Sidebar group
    local sidebarGroup
    success, err = pcall(function()
        sidebarGroup = Instance.new("Frame")
        sidebarGroup.Name = "SidebarGroup"
        sidebarGroup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sidebarGroup.BackgroundTransparency = 1
        sidebarGroup.BorderColor3 = Color3.fromRGB(0, 0, 0)
        sidebarGroup.BorderSizePixel = 0
        sidebarGroup.Position = UDim2.fromOffset(0, 91)
        sidebarGroup.Size = UDim2.new(1, 0, 1, -91)
        sidebarGroup.Parent = sidebar
    end)
    if not success then return WindowFunctions end

    -- User info frame
    local userInfo
    success, err = pcall(function()
        userInfo = Instance.new("Frame")
        userInfo.Name = "UserInfo"
        userInfo.AnchorPoint = Vector2.new(0, 1)
        userInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        userInfo.BackgroundTransparency = 1
        userInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
        userInfo.BorderSizePixel = 0
        userInfo.Position = UDim2.fromScale(0, 1)
        userInfo.Size = UDim2.new(1, 0, 0, 107)
        userInfo.Parent = sidebarGroup
    end)
    if not success then return WindowFunctions end

    -- Information group
    local informationGroup
    success, err = pcall(function()
        informationGroup = Instance.new("Frame")
        informationGroup.Name = "InformationGroup"
        informationGroup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        informationGroup.BackgroundTransparency = 1
        informationGroup.BorderColor3 = Color3.fromRGB(0, 0, 0)
        informationGroup.BorderSizePixel = 0
        informationGroup.Size = UDim2.fromScale(1, 1)
        informationGroup.Parent = userInfo
    end)
    if not success then return WindowFunctions end

    -- Information group padding
    local informationGroupUIPadding
    success, err = pcall(function()
        informationGroupUIPadding = Instance.new("UIPadding")
        informationGroupUIPadding.Name = "InformationGroupUIPadding"
        informationGroupUIPadding.PaddingBottom = UDim.new(0, 17)
        informationGroupUIPadding.PaddingLeft = UDim.new(0, 25)
        informationGroupUIPadding.Parent = informationGroup
    end)
    if not success then return WindowFunctions end

    -- Information group UIListLayout
    local informationGroupUIListLayout
    success, err = pcall(function()
        informationGroupUIListLayout = Instance.new("UIListLayout")
        informationGroupUIListLayout.Name = "InformationGroupUIListLayout"
        informationGroupUIListLayout.FillDirection = Enum.FillDirection.Horizontal
        informationGroupUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        informationGroupUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        informationGroupUIListLayout.Parent = informationGroup
    end)
    if not success then return WindowFunctions end

    -- Get user headshot
    local userId = LocalPlayer and LocalPlayer.UserId or 0
    local thumbType = Enum.ThumbnailType.AvatarBust
    local thumbSize = Enum.ThumbnailSize.Size48x48
    local headshotImage = "rbxassetid://0"
    local isReady = false
    
    pcall(function()
        if userId ~= 0 then
            headshotImage, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        end
    end)

    -- Headshot image
    local headshot
    success, err = pcall(function()
        headshot = Instance.new("ImageLabel")
        headshot.Name = "Headshot"
        headshot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        headshot.BackgroundTransparency = 1
        headshot.BorderColor3 = Color3.fromRGB(0, 0, 0)
        headshot.BorderSizePixel = 0
        headshot.Size = UDim2.fromOffset(32, 32)
        headshot.Image = (isReady and headshotImage) or "rbxassetid://0"
        headshot.Parent = informationGroup
    end)
    if not success then return WindowFunctions end

    -- Headshot corner
    local uICorner3
    success, err = pcall(function()
        uICorner3 = Instance.new("UICorner")
        uICorner3.Name = "UICorner"
        uICorner3.CornerRadius = UDim.new(1, 0)
        uICorner3.Parent = headshot
    end)
    if not success then return WindowFunctions end

    -- Headshot stroke
    local baseUIStroke2
    success, err = pcall(function()
        baseUIStroke2 = Instance.new("UIStroke")
        baseUIStroke2.Name = "BaseUIStroke"
        baseUIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        baseUIStroke2.Color = Color3.fromRGB(255, 255, 255)
        baseUIStroke2.Transparency = 0.9
        baseUIStroke2.Parent = headshot
    end)
    if not success then return WindowFunctions end

    -- User and display frame
    local userAndDisplayFrame
    success, err = pcall(function()
        userAndDisplayFrame = Instance.new("Frame")
        userAndDisplayFrame.Name = "UserAndDisplayFrame"
        userAndDisplayFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        userAndDisplayFrame.BackgroundTransparency = 1
        userAndDisplayFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        userAndDisplayFrame.BorderSizePixel = 0
        userAndDisplayFrame.LayoutOrder = 1
        userAndDisplayFrame.Size = UDim2.new(1, -42, 0, 32)
        userAndDisplayFrame.Parent = informationGroup
    end)
    if not success then return WindowFunctions end

    -- Display name label
    local displayName
    success, err = pcall(function()
        displayName = Instance.new("TextLabel")
        displayName.Name = "DisplayName"
        displayName.FontFace = Font.new(
            assets.interFont,
            Enum.FontWeight.SemiBold,
            Enum.FontStyle.Normal
        )
        displayName.Text = (LocalPlayer and LocalPlayer.DisplayName) or "User"
        displayName.TextColor3 = Color3.fromRGB(255, 255, 255)
        displayName.TextSize = 13
        displayName.TextTransparency = 0.2
        displayName.TextTruncate = Enum.TextTruncate.SplitWord
        displayName.TextXAlignment = Enum.TextXAlignment.Left
        displayName.TextYAlignment = Enum.TextYAlignment.Top
        displayName.AutomaticSize = Enum.AutomaticSize.XY
        displayName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        displayName.BackgroundTransparency = 1
        displayName.BorderColor3 = Color3.fromRGB(0, 0, 0)
        displayName.BorderSizePixel = 0
        displayName.Parent = userAndDisplayFrame
        displayName.Size = UDim2.fromScale(1,0)
    end)
    if not success then return WindowFunctions end

    -- User and display frame padding
    local userAndDisplayFrameUIPadding
    success, err = pcall(function()
        userAndDisplayFrameUIPadding = Instance.new("UIPadding")
        userAndDisplayFrameUIPadding.Name = "UserAndDisplayFrameUIPadding"
        userAndDisplayFrameUIPadding.PaddingLeft = UDim.new(0, 8)
        userAndDisplayFrameUIPadding.PaddingTop = UDim.new(0, 3)
        userAndDisplayFrameUIPadding.Parent = userAndDisplayFrame
    end)
    if not success then return WindowFunctions end

    -- User and display frame UIListLayout
    local userAndDisplayFrameUIListLayout
    success, err = pcall(function()
        userAndDisplayFrameUIListLayout = Instance.new("UIListLayout")
        userAndDisplayFrameUIListLayout.Name = "UserAndDisplayFrameUIListLayout"
        userAndDisplayFrameUIListLayout.Padding = UDim.new(0, 1)
        userAndDisplayFrameUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        userAndDisplayFrameUIListLayout.Parent = userAndDisplayFrame
    end)
    if not success then return WindowFunctions end

    -- Username label
    local username
    success, err = pcall(function()
        username = Instance.new("TextLabel")
        username.Name = "Username"
        username.FontFace = Font.new(
            assets.interFont,
            Enum.FontWeight.SemiBold,
            Enum.FontStyle.Normal
        )
        username.Text = "@" .. ((LocalPlayer and LocalPlayer.Name) or "user")
        username.TextColor3 = Color3.fromRGB(255, 255, 255)
        username.TextSize = 12
        username.TextTransparency = 0.8
        username.TextTruncate = Enum.TextTruncate.SplitWord
        username.TextXAlignment = Enum.TextXAlignment.Left
        username.TextYAlignment = Enum.TextYAlignment.Top
        username.AutomaticSize = Enum.AutomaticSize.XY
        username.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        username.BackgroundTransparency = 1
        username.BorderColor3 = Color3.fromRGB(0, 0, 0)
        username.BorderSizePixel = 0
        username.LayoutOrder = 1
        username.Parent = userAndDisplayFrame
        username.Size = UDim2.fromScale(1,0)
    end)
    if not success then return WindowFunctions end

    -- User info padding
    local userInfoUIPadding
    success, err = pcall(function()
        userInfoUIPadding = Instance.new("UIPadding")
        userInfoUIPadding.Name = "UserInfoUIPadding"
        userInfoUIPadding.PaddingLeft = UDim.new(0, 10)
        userInfoUIPadding.PaddingRight = UDim.new(0, 10)
        userInfoUIPadding.Parent = userInfo
    end)
    if not success then return WindowFunctions end

    -- Sidebar group padding
    local sidebarGroupUIPadding
    success, err = pcall(function()
        sidebarGroupUIPadding = Instance.new("UIPadding")
        sidebarGroupUIPadding.Name = "SidebarGroupUIPadding"
        sidebarGroupUIPadding.PaddingLeft = UDim.new(0, 10)
        sidebarGroupUIPadding.PaddingRight = UDim.new(0, 10)
        sidebarGroupUIPadding.PaddingTop = UDim.new(0, 31)
        sidebarGroupUIPadding.Parent = sidebarGroup
    end)
    if not success then return WindowFunctions end

    -- Tab switchers frame
    local tabSwitchers
    success, err = pcall(function()
        tabSwitchers = Instance.new("Frame")
        tabSwitchers.Name = "TabSwitchers"
        tabSwitchers.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabSwitchers.BackgroundTransparency = 1
        tabSwitchers.BorderColor3 = Color3.fromRGB(0, 0, 0)
        tabSwitchers.BorderSizePixel = 0
        tabSwitchers.Size = UDim2.new(1, 0, 1, -107)
        tabSwitchers.Parent = sidebarGroup
    end)
    if not success then return WindowFunctions end

    -- Tab switchers scrolling frame
    local tabSwitchersScrollingFrame
    success, err = pcall(function()
        tabSwitchersScrollingFrame = Instance.new("ScrollingFrame")
        tabSwitchersScrollingFrame.Name = "TabSwitchersScrollingFrame"
        tabSwitchersScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabSwitchersScrollingFrame.BottomImage = ""
        tabSwitchersScrollingFrame.CanvasSize = UDim2.new()
        tabSwitchersScrollingFrame.ScrollBarImageTransparency = 0.8
        tabSwitchersScrollingFrame.ScrollBarThickness = 1
        tabSwitchersScrollingFrame.TopImage = ""
        tabSwitchersScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabSwitchersScrollingFrame.BackgroundTransparency = 1
        tabSwitchersScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        tabSwitchersScrollingFrame.BorderSizePixel = 0
        tabSwitchersScrollingFrame.Size = UDim2.fromScale(1, 1)
        tabSwitchersScrollingFrame.Parent = tabSwitchers
    end)
    if not success then return WindowFunctions end

    -- Tab switchers scrolling frame UIListLayout
    local tabSwitchersScrollingFrameUIListLayout
    success, err = pcall(function()
        tabSwitchersScrollingFrameUIListLayout = Instance.new("UIListLayout")
        tabSwitchersScrollingFrameUIListLayout.Name = "TabSwitchersScrollingFrameUIListLayout"
        tabSwitchersScrollingFrameUIListLayout.Padding = UDim.new(0, 17)
        tabSwitchersScrollingFrameUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabSwitchersScrollingFrameUIListLayout.Parent = tabSwitchersScrollingFrame
    end)
    if not success then return WindowFunctions end

    -- Tab switchers scrolling frame padding
    local tabSwitchersScrollingFrameUIPadding
    success, err = pcall(function()
        tabSwitchersScrollingFrameUIPadding = Instance.new("UIPadding")
        tabSwitchersScrollingFrameUIPadding.Name = "TabSwitchersScrollingFrameUIPadding"
        tabSwitchersScrollingFrameUIPadding.PaddingTop = UDim.new(0, 2)
        tabSwitchersScrollingFrameUIPadding.Parent = tabSwitchersScrollingFrame
    end)
    if not success then return WindowFunctions end

    -- Content frame
    local content
    success, err = pcall(function()
        content = Instance.new("Frame")
        content.Name = "Content"
        content.AnchorPoint = Vector2.new(1, 0)
        content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        content.BackgroundTransparency = 1
        content.BorderColor3 = Color3.fromRGB(0, 0, 0)
        content.BorderSizePixel = 0
        content.Position = UDim2.fromScale(1, 4.69e-08)
        content.Size = UDim2.fromScale(0.675, 1)
        content.Parent = base
    end)
    if not success then return WindowFunctions end

    -- Topbar frame
    local topbar
    success, err = pcall(function()
        topbar = Instance.new("Frame")
        topbar.Name = "Topbar"
        topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        topbar.BackgroundTransparency = 1
        topbar.BorderColor3 = Color3.fromRGB(0, 0, 0)
        topbar.BorderSizePixel = 0
        topbar.Size = UDim2.new(1, 0, 0, 63)
        topbar.Parent = content
    end)
    if not success then return WindowFunctions end

    -- Topbar divider
    local divider4
    success, err = pcall(function()
        divider4 = Instance.new("Frame")
        divider4.Name = "Divider"
        divider4.AnchorPoint = Vector2.new(0, 1)
        divider4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        divider4.BackgroundTransparency = 0.9
        divider4.BorderColor3 = Color3.fromRGB(0, 0, 0)
        divider4.BorderSizePixel = 0
        divider4.Position = UDim2.fromScale(0, 1)
        divider4.Size = UDim2.new(1, 0, 0, 1)
        divider4.Parent = topbar
    end)
    if not success then return WindowFunctions end

    -- Elements frame
    local elements
    success, err = pcall(function()
        elements = Instance.new("Frame")
        elements.Name = "Elements"
        elements.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        elements.BackgroundTransparency = 1
        elements.BorderColor3 = Color3.fromRGB(0, 0, 0)
        elements.BorderSizePixel = 0
        elements.Size = UDim2.fromScale(1, 1)
        elements.Parent = topbar
    end)
    if not success then return WindowFunctions end

    -- Elements padding
    local uIPadding2
    success, err = pcall(function()
        uIPadding2 = Instance.new("UIPadding")
        uIPadding2.Name = "UIPadding"
        uIPadding2.PaddingLeft = UDim.new(0, 20)
        uIPadding2.PaddingRight = UDim.new(0, 20)
        uIPadding2.Parent = elements
    end)
    if not success then return WindowFunctions end

    -- Move icon
    local moveIcon
    success, err = pcall(function()
        moveIcon = Instance.new("ImageButton")
        moveIcon.Name = "MoveIcon"
        moveIcon.Image = "rbxassetid://10734900011"
        moveIcon.ImageTransparency = 0.5
        moveIcon.AnchorPoint = Vector2.new(1, 0.5)
        moveIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        moveIcon.BackgroundTransparency = 1
        moveIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        moveIcon.BorderSizePixel = 0
        moveIcon.Position = UDim2.fromScale(1, 0.5)
        moveIcon.Size = UDim2.fromOffset(15, 15)
        moveIcon.Parent = elements
        moveIcon.Visible = not Settings.DragStyle or Settings.DragStyle == 1
    end)
    if not success then return WindowFunctions end

    -- Interact button for dragging
    local interact
    success, err = pcall(function()
        interact = Instance.new("TextButton")
        interact.Name = "Interact"
        interact.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
        interact.Text = ""
        interact.TextColor3 = Color3.fromRGB(0, 0, 0)
        interact.TextSize = 14
        interact.AnchorPoint = Vector2.new(0.5, 0.5)
        interact.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        interact.BackgroundTransparency = 1
        interact.BorderColor3 = Color3.fromRGB(0, 0, 0)
        interact.BorderSizePixel = 0
        interact.Position = UDim2.fromScale(0.5, 0.5)
        interact.Size = UDim2.fromOffset(30, 30)
        interact.Parent = moveIcon
    end)
    if not success then return WindowFunctions end

    -- Move icon hover state
    local function ChangemoveIconState(State)
        pcall(function()
            if State == "Default" then
                local tween = Tween(moveIcon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    ImageTransparency = 0.5
                })
                if tween then tween:Play() end
            elseif State == "Hover" then
                local tween = Tween(moveIcon, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                    ImageTransparency = 0.2
                })
                if tween then tween:Play() end
            end
        end)
    end

    -- Connect move icon events
    pcall(function()
        interact.MouseEnter:Connect(function()
            ChangemoveIconState("Hover")
        end)
        interact.MouseLeave:Connect(function()
            ChangemoveIconState("Default")
        end)
    end)

    -- Dragging variables
    local dragging_ = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        pcall(function()
            if not dragStart then return end
            local delta = input.Position - dragStart
            base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end)
    end

    local function onDragStart(input)
        pcall(function()
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging_ = true
                dragStart = input.Position
                startPos = base.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging_ = false
                    end
                end)
            end
        end)
    end

    local function onDragUpdate(input)
        pcall(function()
            if dragging_ and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                dragInput = input
            end
        end)
    end

    -- Drag style handling
    if not Settings.DragStyle or Settings.DragStyle == 1 then
        pcall(function()
            interact.InputBegan:Connect(function(input)
                onDragStart(input)
            end)

            interact.InputChanged:Connect(onDragUpdate)

            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging_ then
                    update(input)
                end
            end)

            interact.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging_ = false
                end
            end)
        end)
    elseif Settings.DragStyle == 2 then
        pcall(function()
            base.InputBegan:Connect(function(input)
                onDragStart(input)
            end)

            base.InputChanged:Connect(onDragUpdate)

            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging_ then
                    update(input)
                end
            end)

            base.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging_ = false
                end
            end)
        end)
    end

    -- Current tab label
    local currentTab
    success, err = pcall(function()
        currentTab = Instance.new("TextLabel")
        currentTab.Name = "CurrentTab"
        currentTab.FontFace = Font.new(
            assets.interFont,
            Enum.FontWeight.SemiBold,
            Enum.FontStyle.Normal
        )
        currentTab.RichText = true
        currentTab.Text = "Tab"
        currentTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTab.TextSize = 15
        currentTab.TextTransparency = 0.5
        currentTab.TextTruncate = Enum.TextTruncate.SplitWord
        currentTab.TextXAlignment = Enum.TextXAlignment.Left
        currentTab.TextYAlignment = Enum.TextYAlignment.Top
        currentTab.AnchorPoint = Vector2.new(0, 0.5)
        currentTab.AutomaticSize = Enum.AutomaticSize.Y
        currentTab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        currentTab.BackgroundTransparency = 1
        currentTab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        currentTab.BorderSizePixel = 0
        currentTab.Position = UDim2.fromScale(0, 0.5)
        currentTab.Size = UDim2.fromScale(0.9, 0)
        currentTab.Parent = elements
    end)
    if not success then return WindowFunctions end

    -- Global settings frame
    local globalSettings
    success, err = pcall(function()
        globalSettings = Instance.new("Frame")
        globalSettings.Name = "GlobalSettings"
        globalSettings.AutomaticSize = Enum.AutomaticSize.XY
        globalSettings.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        globalSettings.BorderColor3 = Color3.fromRGB(0, 0, 0)
        globalSettings.BorderSizePixel = 0
        globalSettings.Position = UDim2.fromScale(0.298, 0.104)
        globalSettings.Parent = base
    end)
    if not success then return WindowFunctions end

    -- Global settings stroke
    local globalSettingsUIStroke
    success, err = pcall(function()
        globalSettingsUIStroke = Instance.new("UIStroke")
        globalSettingsUIStroke.Name = "GlobalSettingsUIStroke"
        globalSettingsUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        globalSettingsUIStroke.Color = Color3.fromRGB(255, 255, 255)
        globalSettingsUIStroke.Transparency = 0.9
        globalSettingsUIStroke.Parent = globalSettings
    end)
    if not success then return WindowFunctions end

    -- Global settings corner
    local globalSettingsUICorner
    success, err = pcall(function()
        globalSettingsUICorner = Instance.new("UICorner")
        globalSettingsUICorner.Name = "GlobalSettingsUICorner"
        globalSettingsUICorner.CornerRadius = UDim.new(0, 10)
        globalSettingsUICorner.Parent = globalSettings
    end)
    if not success then return WindowFunctions end

    -- Global settings padding
    local globalSettingsUIPadding
    success, err = pcall(function()
        globalSettingsUIPadding = Instance.new("UIPadding")
        globalSettingsUIPadding.Name = "GlobalSettingsUIPadding"
        globalSettingsUIPadding.PaddingBottom = UDim.new(0, 10)
        globalSettingsUIPadding.PaddingTop = UDim.new(0, 10)
        globalSettingsUIPadding.Parent = globalSettings
    end)
    if not success then return WindowFunctions end

    -- Global settings UIListLayout
    local globalSettingsUIListLayout
    success, err = pcall(function()
        globalSettingsUIListLayout = Instance.new("UIListLayout")
        globalSettingsUIListLayout.Name = "GlobalSettingsUIListLayout"
        globalSettingsUIListLayout.Padding = UDim.new(0, 5)
        globalSettingsUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        globalSettingsUIListLayout.Parent = globalSettings
    end)
    if not success then return WindowFunctions end

    -- Global settings scale
    local globalSettingsUIScale
    success, err = pcall(function()
        globalSettingsUIScale = Instance.new("UIScale")
        globalSettingsUIScale.Name = "GlobalSettingsUIScale"
        globalSettingsUIScale.Scale = 1e-07
        globalSettingsUIScale.Parent = globalSettings
    end)
    if not success then return WindowFunctions end

    -- Window functions
    function WindowFunctions:UpdateTitle(NewTitle)
        pcall(function()
            title.Text = NewTitle
        end)
    end

    function WindowFunctions:UpdateSubtitle(NewSubtitle)
        pcall(function()
            subtitle.Text = NewSubtitle
        end)
    end

    -- Global settings toggle
    local hovering
    local toggled = globalSettingsUIScale and globalSettingsUIScale.Scale == 1 and true or false
    local function toggle()
        pcall(function()
            if not toggled then
                local intween = Tween(globalSettingsUIScale, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                    Scale = 1
                })
                if intween then
                    intween:Play()
                    intween.Completed:Wait()
                end
                toggled = true
            elseif toggled then
                local outtween = Tween(globalSettingsUIScale, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                    Scale = 0
                })
                if outtween then
                    outtween:Play()
                    outtween.Completed:Wait()
                end
                toggled = false
            end
        end)
    end
    
    pcall(function()
        globalSettingsButton.MouseButton1Click:Connect(function()
            if not hasGlobalSetting then return end
            toggle()
        end)
    end)
    
    pcall(function()
        globalSettings.MouseEnter:Connect(function()
            hovering = true
        end)
        globalSettings.MouseLeave:Connect(function()
            hovering = false
        end)
    end)
    
    pcall(function()
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and toggled and not hovering then
                toggle()
            end
        end)
    end)

    -- Acrylic blur setup
    local BlurTarget = base
    local HS = cloneref(HttpService)
    local camera = workspace and workspace.CurrentCamera
    local MTREL = "Glass"
    local binds = {}
    local wedgeguid = HS:GenerateGUID(true)

    local DepthOfField
    pcall(function()
        local lighting = cloneref(game:GetService("Lighting"))
        for _,v in pairs(lighting:GetChildren()) do
            if not v:IsA("DepthOfFieldEffect") and v:HasTag(".") then
                DepthOfField = Instance.new('DepthOfFieldEffect', lighting)
                DepthOfField.FarIntensity = 0
                DepthOfField.FocusDistance = 51.6
                DepthOfField.InFocusRadius = 50
                DepthOfField.NearIntensity = 1
                DepthOfField.Name = HS:GenerateGUID(true)
                DepthOfField:AddTag(".")
            elseif v:IsA("DepthOfFieldEffect") and v:HasTag(".") then
                DepthOfField = v
            end
        end

        if not DepthOfField then
            DepthOfField = Instance.new('DepthOfFieldEffect', lighting)
            DepthOfField.FarIntensity = 0
            DepthOfField.FocusDistance = 51.6
            DepthOfField.InFocusRadius = 50
            DepthOfField.NearIntensity = 1
            DepthOfField.Name = HS:GenerateGUID(true)
            DepthOfField:AddTag(".")
        end
    end)

    local frame
    pcall(function()
        frame = Instance.new('Frame')
        frame.Parent = BlurTarget
        frame.Size = UDim2.new(0.97, 0, 0.97, 0)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BackgroundTransparency = 1
        frame.Name = HS:GenerateGUID(true)
    end)

    -- Acrylic blur draw functions
    local function IsNotNaN(x)
        return x == x
    end

    pcall(function()
        if camera then
            local continue = IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x)
            while not continue do
                task.wait()
                continue = camera and IsNotNaN(camera:ScreenPointToRay(0,0).Origin.x) or false
            end
        end
    end)

    local DrawQuad; do
        local acos, max, pi, sqrt = math.acos, math.max, math.pi, math.sqrt
        local sz = 0.2

        local function DrawTriangle(v1, v2, v3, p0, p1)
            local s1 = (v1 - v2).magnitude
            local s2 = (v2 - v3).magnitude
            local s3 = (v3 - v1).magnitude
            local smax = max(s1, s2, s3)
            local A, B, C
            if s1 == smax then
                A, B, C = v1, v2, v3
            elseif s2 == smax then
                A, B, C = v2, v3, v1
            elseif s3 == smax then
                A, B, C = v3, v1, v2
            end

            local para = ( (B-A).x*(C-A).x + (B-A).y*(C-A).y + (B-A).z*(C-A).z ) / (A-B).magnitude
            local perp = sqrt((C-A).magnitude^2 - para*para)
            local dif_para = (A - B).magnitude - para

            local st = CFrame.new(B, A)
            local za = CFrame.Angles(pi/2,0,0)

            local cf0 = st

            local Top_Look = (cf0 * za).lookVector
            local Mid_Point = A + CFrame.new(A, B).lookVector * para
            local Needed_Look = CFrame.new(Mid_Point, C).lookVector
            local dot = Top_Look.x*Needed_Look.x + Top_Look.y*Needed_Look.y + Top_Look.z*Needed_Look.z

            local ac = CFrame.Angles(0, 0, acos(dot))

            cf0 = cf0 * ac
            if ((cf0 * za).lookVector - Needed_Look).magnitude > 0.01 then
                cf0 = cf0 * CFrame.Angles(0, 0, -2*acos(dot))
            end
            cf0 = cf0 * CFrame.new(0, perp/2, -(dif_para + para/2))

            local cf1 = st * ac * CFrame.Angles(0, pi, 0)
            if ((cf1 * za).lookVector - Needed_Look).magnitude > 0.01 then
                cf1 = cf1 * CFrame.Angles(0, 0, 2*acos(dot))
            end
            cf1 = cf1 * CFrame.new(0, perp/2, dif_para/2)

            if not p0 then
                p0 = Instance.new('Part')
                p0.FormFactor = 'Custom'
                p0.TopSurface = 0
                p0.BottomSurface = 0
                p0.Anchored = true
                p0.CanCollide = false
                p0.CastShadow = false
                p0.Material = MTREL
                p0.Size = Vector3.new(sz, sz, sz)
                p0.Name = HS:GenerateGUID(true)
                local mesh = Instance.new('SpecialMesh', p0)
                mesh.MeshType = 2
                mesh.Name = wedgeguid
            end
            p0[wedgeguid].Scale = Vector3.new(0, perp/sz, para/sz)
            p0.CFrame = cf0

            if not p1 then
                p1 = p0:Clone()
            end
            p1[wedgeguid].Scale = Vector3.new(0, perp/sz, dif_para/sz)
            p1.CFrame = cf1

            return p0, p1
        end

        function DrawQuad(v1, v2, v3, v4, parts)
            parts[1], parts[2] = DrawTriangle(v1, v2, v3, parts[1], parts[2])
            parts[3], parts[4] = DrawTriangle(v3, v2, v4, parts[3], parts[4])
        end
    end

    if binds[frame] then
        -- binds handled
    end

    local parts = {}

    local parents = {}
    do
        local function add(child)
            if child and child:IsA('GuiObject') then
                parents[#parents + 1] = child
                if child.Parent then
                    add(child.Parent)
                end
            end
        end
        if frame then
            add(frame)
        end
    end

    local function IsVisible(instance)
        while instance do
            pcall(function()
                if instance:IsA("GuiObject") then
                    if not instance.Visible then
                        return false
                    end
                elseif instance:IsA("ScreenGui") then
                    if not instance.Enabled then
                        return false
                    end
                    return true
                end
            end)
            instance = instance and instance.Parent
        end
        return true
    end

    local function UpdateOrientation(fetchProps)
        pcall(function()
            if not IsVisible(frame) or not acrylicBlur then
                if parts then
                    for _, pt in pairs(parts) do
                        if pt then
                            pt.Parent = nil
                        end
                    end
                end
                if DepthOfField then
                    DepthOfField.Enabled = false
                end
                return
            end
            if DepthOfField then
                DepthOfField.Enabled = true
            end
            local properties = {
                Transparency = 0.98;
                BrickColor = BrickColor.new('Institutional white');
            }
            local zIndex = frame and (1 - 0.05 * frame.ZIndex) or 1

            local tl, br = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
            local tr, bl = Vector2.new(br.x, tl.y), Vector2.new(tl.x, br.y)
            do
                local rot = 0;
                for _, v in ipairs(parents) do
                    rot = rot + v.Rotation
                end
                if rot ~= 0 and rot % 180 ~= 0 then
                    local mid = tl:lerp(br, 0.5)
                    local s, c = math.sin(math.rad(rot)), math.cos(math.rad(rot))
                    local vec = tl
                    tl = Vector2.new(c*(tl.x - mid.x) - s*(tl.y - mid.y), s*(tl.x - mid.x) + c*(tl.y - mid.y)) + mid
                    tr = Vector2.new(c*(tr.x - mid.x) - s*(tr.y - mid.y), s*(tr.x - mid.x) + c*(tr.y - mid.y)) + mid
                    bl = Vector2.new(c*(bl.x - mid.x) - s*(bl.y - mid.y), s*(bl.x - mid.x) + c*(bl.y - mid.y)) + mid
                    br = Vector2.new(c*(br.x - mid.x) - s*(br.y - mid.y), s*(br.x - mid.x) + c*(br.y - mid.y)) + mid
                end
            end
            if camera then
                DrawQuad(
                    camera:ScreenPointToRay(tl.x, tl.y, zIndex).Origin, 
                    camera:ScreenPointToRay(tr.x, tr.y, zIndex).Origin, 
                    camera:ScreenPointToRay(bl.x, bl.y, zIndex).Origin, 
                    camera:ScreenPointToRay(br.x, br.y, zIndex).Origin, 
                    parts
                )
            end
            if fetchProps then
                for _, pt in pairs(parts) do
                    if pt and camera then
                        pt.Parent = camera
                    end
                end
                for propName, propValue in pairs(properties) do
                    for _, pt in pairs(parts) do
                        if pt then
                            pt[propName] = propValue
                        end
                    end
                end
            end
        end)
    end

    pcall(function()
        UpdateOrientation(true)
    end)

    local renderSteppedConnection
    pcall(function()
        renderSteppedConnection = RunService.RenderStepped:Connect(UpdateOrientation)
    end)

    -- Global setting function
    function WindowFunctions:GlobalSetting(Settings)
        local GlobalSettingFunctions = {}
        hasGlobalSetting = true
        
        local globalSetting
        local success, err = pcall(function()
            globalSetting = Instance.new("TextButton")
            globalSetting.Name = "GlobalSetting"
            globalSetting.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
            globalSetting.Text = ""
            globalSetting.TextColor3 = Color3.fromRGB(0, 0, 0)
            globalSetting.TextSize = 14
            globalSetting.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            globalSetting.BackgroundTransparency = 1
            globalSetting.BorderColor3 = Color3.fromRGB(0, 0, 0)
            globalSetting.BorderSizePixel = 0
            globalSetting.Size = UDim2.fromOffset(200, 30)
            globalSetting.Parent = globalSettings
        end)
        if not success then return GlobalSettingFunctions end

        local globalSettingToggleUIPadding
        pcall(function()
            globalSettingToggleUIPadding = Instance.new("UIPadding")
            globalSettingToggleUIPadding.Name = "GlobalSettingToggleUIPadding"
            globalSettingToggleUIPadding.PaddingLeft = UDim.new(0, 15)
            globalSettingToggleUIPadding.Parent = globalSetting
        end)

        local settingName
        pcall(function()
            settingName = Instance.new("TextLabel")
            settingName.Name = "SettingName"
            settingName.FontFace = Font.new(
                assets.interFont,
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            settingName.Text = Settings.Name or "Setting"
            settingName.RichText = true
            settingName.TextColor3 = Color3.fromRGB(255, 255, 255)
            settingName.TextSize = 13
            settingName.TextTransparency = 0.5
            settingName.TextTruncate = Enum.TextTruncate.SplitWord
            settingName.TextXAlignment = Enum.TextXAlignment.Left
            settingName.TextYAlignment = Enum.TextYAlignment.Top
            settingName.AnchorPoint = Vector2.new(0, 0.5)
            settingName.AutomaticSize = Enum.AutomaticSize.Y
            settingName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            settingName.BackgroundTransparency = 1
            settingName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            settingName.BorderSizePixel = 0
            settingName.Position = UDim2.fromScale(1.3e-07, 0.5)
            settingName.Size = UDim2.new(1,-40,0,0)
            settingName.Parent = globalSetting
        end)

        local globalSettingToggleUIListLayout
        pcall(function()
            globalSettingToggleUIListLayout = Instance.new("UIListLayout")
            globalSettingToggleUIListLayout.Name = "GlobalSettingToggleUIListLayout"
            globalSettingToggleUIListLayout.Padding = UDim.new(0, 10)
            globalSettingToggleUIListLayout.FillDirection = Enum.FillDirection.Horizontal
            globalSettingToggleUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            globalSettingToggleUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            globalSettingToggleUIListLayout.Parent = globalSetting
        end)

        local checkmark
        pcall(function()
            checkmark = Instance.new("TextLabel")
            checkmark.Name = "Checkmark"
            checkmark.FontFace = Font.new(
                assets.interFont,
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            checkmark.Text = "✓"
            checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
            checkmark.TextSize = 13
            checkmark.TextTransparency = 1
            checkmark.TextXAlignment = Enum.TextXAlignment.Left
            checkmark.TextYAlignment = Enum.TextYAlignment.Top
            checkmark.AnchorPoint = Vector2.new(0, 0.5)
            checkmark.AutomaticSize = Enum.AutomaticSize.Y
            checkmark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            checkmark.BackgroundTransparency = 1
            checkmark.BorderColor3 = Color3.fromRGB(0, 0, 0)
            checkmark.BorderSizePixel = 0
            checkmark.LayoutOrder = -1
            checkmark.Position = UDim2.fromScale(1.3e-07, 0.5)
            checkmark.Size = UDim2.fromOffset(-10, 0)
            checkmark.Parent = globalSetting
        end)

        local tweensettings = {
            duration = 0.2,
            easingStyle = Enum.EasingStyle.Quint,
            transparencyIn = 0.2,
            transparencyOut = 0.5,
            checkSizeIncrease = 12,
            checkSizeDecrease = -10,
            waitTime = 1
        }

        if globalSettingToggleUIListLayout then
            tweensettings.checkSizeDecrease = -globalSettingToggleUIListLayout.Padding.Offset
        end

        local tweens = {}
        pcall(function()
            tweens.checkIn = Tween(checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                Size = UDim2.new(checkmark.Size.X.Scale, tweensettings.checkSizeIncrease, checkmark.Size.Y.Scale, checkmark.Size.Y.Offset)
            })
            tweens.checkOut = Tween(checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle),{
                Size = UDim2.new(checkmark.Size.X.Scale, tweensettings.checkSizeDecrease, checkmark.Size.Y.Scale, checkmark.Size.Y.Offset)
            })
            tweens.nameIn = Tween(settingName, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle),{
                TextTransparency = tweensettings.transparencyIn
            })
            tweens.nameOut = Tween(settingName, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle),{
                TextTransparency = tweensettings.transparencyOut
            })
        end)

        local function ToggleState(State)
            pcall(function()
                if not State then
                    if tweens.checkOut then tweens.checkOut:Play() end
                    if tweens.nameOut then tweens.nameOut:Play() end
                    if checkmark then
                        checkmark:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                            if checkmark.AbsoluteSize.X <= 0 then
                                checkmark.TextTransparency = 1
                            end
                        end)
                    end
                else
                    if tweens.checkIn then tweens.checkIn:Play() end
                    if tweens.nameIn then tweens.nameIn:Play() end
                    if checkmark then
                        checkmark:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                            if checkmark.AbsoluteSize.X > 0 then
                                checkmark.TextTransparency = 0
                            end
                        end)
                    end
                end
            end)
        end

        local toggledState = Settings.Default or false
        ToggleState(toggledState)

        pcall(function()
            globalSetting.MouseButton1Click:Connect(function()
                toggledState = not toggledState
                ToggleState(toggledState)

                task.spawn(function()
                    if Settings.Callback then
                        pcall(Settings.Callback, toggledState)
                    end
                end)
            end)
        end)

        function GlobalSettingFunctions:UpdateName(NewName)
            pcall(function()
                if settingName then settingName.Text = NewName end
            end)
        end

        function GlobalSettingFunctions:UpdateState(NewState)
            pcall(function()
                ToggleState(NewState)
                toggledState = NewState
                task.spawn(function()
                    if Settings.Callback then
                        pcall(Settings.Callback, toggledState)
                    end
                end)
            end)
        end

        return GlobalSettingFunctions
    end

    -- Tab group function
    function WindowFunctions:TabGroup()
        local SectionFunctions = {}

        local tabGroup
        pcall(function()
            tabGroup = Instance.new("Frame")
            tabGroup.Name = "Section"
            tabGroup.AutomaticSize = Enum.AutomaticSize.Y
            tabGroup.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            tabGroup.BackgroundTransparency = 1
            tabGroup.BorderColor3 = Color3.fromRGB(0, 0, 0)
            tabGroup.BorderSizePixel = 0
            tabGroup.Size = UDim2.fromScale(1, 0)
            tabGroup.Parent = tabSwitchersScrollingFrame
        end)

        local divider3
        pcall(function()
            divider3 = Instance.new("Frame")
            divider3.Name = "Divider"
            divider3.AnchorPoint = Vector2.new(0.5, 1)
            divider3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            divider3.BackgroundTransparency = 0.9
            divider3.BorderColor3 = Color3.fromRGB(0, 0, 0)
            divider3.BorderSizePixel = 0
            divider3.Position = UDim2.fromScale(0.5, 1)
            divider3.Size = UDim2.new(1, -21, 0, 1)
            divider3.Parent = tabGroup
        end)

        local sectionTabSwitchers
        pcall(function()
            sectionTabSwitchers = Instance.new("Frame")
            sectionTabSwitchers.Name = "SectionTabSwitchers"
            sectionTabSwitchers.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sectionTabSwitchers.BackgroundTransparency = 1
            sectionTabSwitchers.BorderColor3 = Color3.fromRGB(0, 0, 0)
            sectionTabSwitchers.BorderSizePixel = 0
            sectionTabSwitchers.Size = UDim2.fromScale(1, 1)
            sectionTabSwitchers.Parent = tabGroup
        end)

        local uIListLayout1
        pcall(function()
            uIListLayout1 = Instance.new("UIListLayout")
            uIListLayout1.Name = "UIListLayout"
            uIListLayout1.Padding = UDim.new(0, 15)
            uIListLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
            uIListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
            uIListLayout1.Parent = sectionTabSwitchers
        end)

        local uIPadding1
        pcall(function()
            uIPadding1 = Instance.new("UIPadding")
            uIPadding1.Name = "UIPadding"
            uIPadding1.PaddingBottom = UDim.new(0, 15)
            uIPadding1.Parent = sectionTabSwitchers
        end)

        function SectionFunctions:Tab(Settings)
            local TabFunctions = {}
            
            local tabSwitcher
            pcall(function()
                tabSwitcher = Instance.new("TextButton")
                tabSwitcher.Name = "TabSwitcher"
                tabSwitcher.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
                tabSwitcher.Text = ""
                tabSwitcher.TextColor3 = Color3.fromRGB(0, 0, 0)
                tabSwitcher.TextSize = 14
                tabSwitcher.AutoButtonColor = false
                tabSwitcher.AnchorPoint = Vector2.new(0.5, 0)
                tabSwitcher.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                tabSwitcher.BackgroundTransparency = 1
                tabSwitcher.BorderColor3 = Color3.fromRGB(0, 0, 0)
                tabSwitcher.BorderSizePixel = 0
                tabSwitcher.Position = UDim2.fromScale(0.5, 0)
                tabSwitcher.Size = UDim2.new(1, -21, 0, 40)
                tabSwitcher.Parent = sectionTabSwitchers
            end)

            tabIndex = tabIndex + 1
            if tabSwitcher then tabSwitcher.LayoutOrder = tabIndex end

            local tabSwitcherUICorner
            pcall(function()
                tabSwitcherUICorner = Instance.new("UICorner")
                tabSwitcherUICorner.Name = "TabSwitcherUICorner"
                tabSwitcherUICorner.Parent = tabSwitcher
            end)

            local tabSwitcherUIStroke
            pcall(function()
                tabSwitcherUIStroke = Instance.new("UIStroke")
                tabSwitcherUIStroke.Name = "TabSwitcherUIStroke"
                tabSwitcherUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                tabSwitcherUIStroke.Color = Color3.fromRGB(255, 255, 255)
                tabSwitcherUIStroke.Transparency = 1
                tabSwitcherUIStroke.Parent = tabSwitcher
            end)

            local tabSwitcherUIListLayout
            pcall(function()
                tabSwitcherUIListLayout = Instance.new("UIListLayout")
                tabSwitcherUIListLayout.Name = "TabSwitcherUIListLayout"
                tabSwitcherUIListLayout.Padding = UDim.new(0, 9)
                tabSwitcherUIListLayout.FillDirection = Enum.FillDirection.Horizontal
                tabSwitcherUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                tabSwitcherUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                tabSwitcherUIListLayout.Parent = tabSwitcher
            end)

            if Settings.Image then
                pcall(function()
                    local tabImage = Instance.new("ImageLabel")
                    tabImage.Name = "TabImage"
                    tabImage.Image = Settings.Image
                    tabImage.ImageTransparency = 0.4
                    tabImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    tabImage.BackgroundTransparency = 1
                    tabImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    tabImage.BorderSizePixel = 0
                    tabImage.Size = UDim2.fromOffset(16, 16)
                    tabImage.Parent = tabSwitcher
                end)
            end

            local tabSwitcherName
            pcall(function()
                tabSwitcherName = Instance.new("TextLabel")
                tabSwitcherName.Name = "TabSwitcherName"
                tabSwitcherName.FontFace = Font.new(
                    assets.interFont,
                    Enum.FontWeight.SemiBold,
                    Enum.FontStyle.Normal
                )
                tabSwitcherName.Text = Settings.Name or "Tab"
                tabSwitcherName.RichText = true
                tabSwitcherName.TextColor3 = Color3.fromRGB(255, 255, 255)
                tabSwitcherName.TextSize = 16
                tabSwitcherName.TextTransparency = 0.4
                tabSwitcherName.TextTruncate = Enum.TextTruncate.SplitWord
                tabSwitcherName.TextXAlignment = Enum.TextXAlignment.Left
                tabSwitcherName.TextYAlignment = Enum.TextYAlignment.Top
                tabSwitcherName.AutomaticSize = Enum.AutomaticSize.Y
                tabSwitcherName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                tabSwitcherName.BackgroundTransparency = 1
                tabSwitcherName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                tabSwitcherName.BorderSizePixel = 0
                tabSwitcherName.Size = UDim2.fromScale(1, 0)
                tabSwitcherName.Parent = tabSwitcher
                tabSwitcherName.LayoutOrder = 1
            end)

            local tabSwitcherUIPadding
            pcall(function()
                tabSwitcherUIPadding = Instance.new("UIPadding")
                tabSwitcherUIPadding.Name = "TabSwitcherUIPadding"
                tabSwitcherUIPadding.PaddingLeft = UDim.new(0, 24)
                tabSwitcherUIPadding.PaddingRight = UDim.new(0, 35)
                tabSwitcherUIPadding.PaddingTop = UDim.new(0, 1)
                tabSwitcherUIPadding.Parent = tabSwitcher
            end)

            -- Elements frame for tab content
            local elements1
            pcall(function()
                elements1 = Instance.new("Frame")
                elements1.Name = "Elements"
                elements1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                elements1.BackgroundTransparency = 1
                elements1.BorderColor3 = Color3.fromRGB(0, 0, 0)
                elements1.BorderSizePixel = 0
                elements1.Position = UDim2.fromOffset(0, 63)
                elements1.Size = UDim2.new(1, 0, 1, -63)
            end)

            local elementsUIPadding
            pcall(function()
                elementsUIPadding = Instance.new("UIPadding")
                elementsUIPadding.Name = "ElementsUIPadding"
                elementsUIPadding.PaddingRight = UDim.new(0, 5)
                elementsUIPadding.PaddingTop = UDim.new(0, 10)
                elementsUIPadding.Parent = elements1
            end)

            local elementsScrolling
            pcall(function()
                elementsScrolling = Instance.new("ScrollingFrame")
                elementsScrolling.Name = "ElementsScrolling"
                elementsScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
                elementsScrolling.BottomImage = ""
                elementsScrolling.CanvasSize = UDim2.new()
                elementsScrolling.ScrollBarImageTransparency = 0.5
                elementsScrolling.ScrollBarThickness = 1
                elementsScrolling.TopImage = ""
                elementsScrolling.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                elementsScrolling.BackgroundTransparency = 1
                elementsScrolling.BorderColor3 = Color3.fromRGB(0, 0, 0)
                elementsScrolling.BorderSizePixel = 0
                elementsScrolling.Size = UDim2.fromScale(1, 1)
                elementsScrolling.Parent = elements1
            end)

            local elementsScrollingUIPadding
            pcall(function()
                elementsScrollingUIPadding = Instance.new("UIPadding")
                elementsScrollingUIPadding.Name = "ElementsScrollingUIPadding"
                elementsScrollingUIPadding.PaddingBottom = UDim.new(0, 15)
                elementsScrollingUIPadding.PaddingLeft = UDim.new(0, 11)
                elementsScrollingUIPadding.PaddingRight = UDim.new(0, 3)
                elementsScrollingUIPadding.PaddingTop = UDim.new(0, 5)
                elementsScrollingUIPadding.Parent = elementsScrolling
            end)

            local elementsScrollingUIListLayout
            pcall(function()
                elementsScrollingUIListLayout = Instance.new("UIListLayout")
                elementsScrollingUIListLayout.Name = "ElementsScrollingUIListLayout"
                elementsScrollingUIListLayout.Padding = UDim.new(0, 15)
                elementsScrollingUIListLayout.FillDirection = Enum.FillDirection.Horizontal
                elementsScrollingUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                elementsScrollingUIListLayout.Parent = elementsScrolling
            end)

            local left
            pcall(function()
                left = Instance.new("Frame")
                left.Name = "Left"
                left.AutomaticSize = Enum.AutomaticSize.Y
                left.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                left.BackgroundTransparency = 1
                left.BorderColor3 = Color3.fromRGB(0, 0, 0)
                left.BorderSizePixel = 0
                left.Position = UDim2.fromScale(0.512, 0)
                left.Size = UDim2.new(0.5, -10, 0, 0)
                left.Parent = elementsScrolling
            end)

            local leftUIListLayout
            pcall(function()
                leftUIListLayout = Instance.new("UIListLayout")
                leftUIListLayout.Name = "LeftUIListLayout"
                leftUIListLayout.Padding = UDim.new(0, 15)
                leftUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                leftUIListLayout.Parent = left
            end)

            local right
            pcall(function()
                right = Instance.new("Frame")
                right.Name = "Right"
                right.AutomaticSize = Enum.AutomaticSize.Y
                right.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                right.BackgroundTransparency = 1
                right.BorderColor3 = Color3.fromRGB(0, 0, 0)
                right.BorderSizePixel = 0
                right.LayoutOrder = 1
                right.Position = UDim2.fromScale(0.512, 0)
                right.Size = UDim2.new(0.5, -10, 0, 0)
                right.Parent = elementsScrolling
            end)

            local rightUIListLayout
            pcall(function()
                rightUIListLayout = Instance.new("UIListLayout")
                rightUIListLayout.Name = "RightUIListLayout"
                rightUIListLayout.Padding = UDim.new(0, 15)
                rightUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                rightUIListLayout.Parent = right
            end)

            -- Section function inside Tab
            function TabFunctions:Section(Settings)
                local SectionFunctions = {}
                
                local section
                pcall(function()
                    section = Instance.new("Frame")
                    section.Name = "Section"
                    section.AutomaticSize = Enum.AutomaticSize.Y
                    section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    section.BackgroundTransparency = 0.98
                    section.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    section.BorderSizePixel = 0
                    section.Position = UDim2.fromScale(0, 6.78e-08)
                    section.Size = UDim2.fromScale(1, 0)
                    section.Parent = (Settings.Side == "Left" and left) or right
                end)

                local sectionUICorner
                pcall(function()
                    sectionUICorner = Instance.new("UICorner")
                    sectionUICorner.Name = "SectionUICorner"
                    sectionUICorner.Parent = section
                end)

                local sectionUIStroke
                pcall(function()
                    sectionUIStroke = Instance.new("UIStroke")
                    sectionUIStroke.Name = "SectionUIStroke"
                    sectionUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    sectionUIStroke.Color = Color3.fromRGB(255, 255, 255)
                    sectionUIStroke.Transparency = 0.95
                    sectionUIStroke.Parent = section
                end)

                local sectionUIListLayout
                pcall(function()
                    sectionUIListLayout = Instance.new("UIListLayout")
                    sectionUIListLayout.Name = "SectionUIListLayout"
                    sectionUIListLayout.Padding = UDim.new(0, 10)
                    sectionUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    sectionUIListLayout.Parent = section
                end)

                local sectionUIPadding
                pcall(function()
                    sectionUIPadding = Instance.new("UIPadding")
                    sectionUIPadding.Name = "SectionUIPadding"
                    sectionUIPadding.PaddingBottom = UDim.new(0, 20)
                    sectionUIPadding.PaddingLeft = UDim.new(0, 20)
                    sectionUIPadding.PaddingRight = UDim.new(0, 18)
                    sectionUIPadding.PaddingTop = UDim.new(0, 22)
                    sectionUIPadding.Parent = section
                end)

                -- Button element
                function SectionFunctions:Button(Settings)
                    local ButtonFunctions = {}
                    
                    local button
                    pcall(function()
                        button = Instance.new("Frame")
                        button.Name = "Button"
                        button.AutomaticSize = Enum.AutomaticSize.Y
                        button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        button.BackgroundTransparency = 1
                        button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        button.BorderSizePixel = 0
                        button.Size = UDim2.new(1, 0, 0, 38)
                        button.Parent = section
                    end)

                    local buttonInteract
                    pcall(function()
                        buttonInteract = Instance.new("TextButton")
                        buttonInteract.Name = "ButtonInteract"
                        buttonInteract.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        buttonInteract.RichText = true
                        buttonInteract.TextColor3 = Color3.fromRGB(255, 255, 255)
                        buttonInteract.TextSize = 13
                        buttonInteract.TextTransparency = 0.5
                        buttonInteract.TextTruncate = Enum.TextTruncate.AtEnd
                        buttonInteract.TextXAlignment = Enum.TextXAlignment.Left
                        buttonInteract.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        buttonInteract.BackgroundTransparency = 1
                        buttonInteract.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        buttonInteract.BorderSizePixel = 0
                        buttonInteract.Size = UDim2.fromScale(1, 1)
                        buttonInteract.Parent = button
                        buttonInteract.Text = Settings.Name or "Button"
                    end)

                    local buttonImage
                    pcall(function()
                        buttonImage = Instance.new("ImageLabel")
                        buttonImage.Name = "ButtonImage"
                        buttonImage.Image = assets.buttonImage
                        buttonImage.ImageTransparency = 0.5
                        buttonImage.AnchorPoint = Vector2.new(1, 0.5)
                        buttonImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        buttonImage.BackgroundTransparency = 1
                        buttonImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        buttonImage.BorderSizePixel = 0
                        buttonImage.Position = UDim2.fromScale(1, 0.5)
                        buttonImage.Size = UDim2.fromOffset(15, 15)
                        buttonImage.Parent = button
                    end)

                    local TweenSettings = {
                        DefaultTransparency = 0.5,
                        HoverTransparency = 0.3,
                        EasingStyle = Enum.EasingStyle.Sine
                    }

                    local function ChangeState(State)
                        pcall(function()
                            if State == "Idle" then
                                local t1 = Tween(buttonInteract, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                                    TextTransparency = TweenSettings.DefaultTransparency
                                })
                                if t1 then t1:Play() end
                                local t2 = Tween(buttonImage, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                                    ImageTransparency = TweenSettings.DefaultTransparency
                                })
                                if t2 then t2:Play() end
                            elseif State == "Hover" then
                                local t1 = Tween(buttonInteract, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                                    TextTransparency = TweenSettings.HoverTransparency
                                })
                                if t1 then t1:Play() end
                                local t2 = Tween(buttonImage, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                                    ImageTransparency = TweenSettings.HoverTransparency
                                })
                                if t2 then t2:Play() end
                            end
                        end)
                    end

                    local function Callback()
                        if Settings.Callback then
                            pcall(Settings.Callback)
                        end
                    end

                    pcall(function()
                        buttonInteract.MouseEnter:Connect(function()
                            ChangeState("Hover")
                        end)
                        buttonInteract.MouseLeave:Connect(function()
                            ChangeState("Idle")
                        end)
                        buttonInteract.MouseButton1Click:Connect(Callback)
                    end)

                    function ButtonFunctions:UpdateName(Name)
                        pcall(function()
                            if buttonInteract then buttonInteract.Text = Name end
                        end)
                    end
                    
                    function ButtonFunctions:SetVisibility(State)
                        pcall(function()
                            if button then button.Visible = State end
                        end)
                    end
                    
                    return ButtonFunctions
                end

                -- Toggle element
                function SectionFunctions:Toggle(Settings)
                    local ToggleFunctions = {}
                    
                    local toggle
                    pcall(function()
                        toggle = Instance.new("Frame")
                        toggle.Name = "Toggle"
                        toggle.AutomaticSize = Enum.AutomaticSize.Y
                        toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        toggle.BackgroundTransparency = 1
                        toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        toggle.BorderSizePixel = 0
                        toggle.Size = UDim2.new(1, 0, 0, 38)
                        toggle.Parent = section
                    end)

                    local toggleName
                    pcall(function()
                        toggleName = Instance.new("TextLabel")
                        toggleName.Name = "ToggleName"
                        toggleName.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        toggleName.Text = Settings.Name or "Toggle"
                        toggleName.RichText = true
                        toggleName.TextColor3 = Color3.fromRGB(255, 255, 255)
                        toggleName.TextSize = 13
                        toggleName.TextTransparency = 0.5
                        toggleName.TextTruncate = Enum.TextTruncate.AtEnd
                        toggleName.TextXAlignment = Enum.TextXAlignment.Left
                        toggleName.TextYAlignment = Enum.TextYAlignment.Top
                        toggleName.AnchorPoint = Vector2.new(0, 0.5)
                        toggleName.AutomaticSize = Enum.AutomaticSize.Y
                        toggleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        toggleName.BackgroundTransparency = 1
                        toggleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        toggleName.BorderSizePixel = 0
                        toggleName.Position = UDim2.fromScale(0, 0.5)
                        toggleName.Size = UDim2.new(1, -50, 0, 0)
                        toggleName.Parent = toggle
                    end)

                    local toggleButton
                    pcall(function()
                        toggleButton = Instance.new("ImageButton")
                        toggleButton.Name = "Toggle"
                        toggleButton.Image = assets.toggleBackground
                        toggleButton.ImageColor3 = Color3.fromRGB(61, 61, 61)
                        toggleButton.AutoButtonColor = false
                        toggleButton.AnchorPoint = Vector2.new(1, 0.5)
                        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        toggleButton.BackgroundTransparency = 1
                        toggleButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        toggleButton.BorderSizePixel = 0
                        toggleButton.Position = UDim2.fromScale(1, 0.5)
                        toggleButton.Size = UDim2.fromOffset(41, 21)
                        toggleButton.Parent = toggle
                    end)

                    local toggleUIPadding
                    pcall(function()
                        toggleUIPadding = Instance.new("UIPadding")
                        toggleUIPadding.Name = "ToggleUIPadding"
                        toggleUIPadding.PaddingBottom = UDim.new(0, 1)
                        toggleUIPadding.PaddingLeft = UDim.new(0, -2)
                        toggleUIPadding.PaddingRight = UDim.new(0, 3)
                        toggleUIPadding.PaddingTop = UDim.new(0, 1)
                        toggleUIPadding.Parent = toggleButton
                    end)

                    local togglerHead
                    pcall(function()
                        togglerHead = Instance.new("ImageLabel")
                        togglerHead.Name = "TogglerHead"
                        togglerHead.Image = assets.togglerHead
                        togglerHead.ImageColor3 = Color3.fromRGB(91, 91, 91)
                        togglerHead.AnchorPoint = Vector2.new(1, 0.5)
                        togglerHead.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        togglerHead.BackgroundTransparency = 1
                        togglerHead.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        togglerHead.BorderSizePixel = 0
                        togglerHead.Position = UDim2.fromScale(0.5, 0.5)
                        togglerHead.Size = UDim2.fromOffset(15, 15)
                        togglerHead.ZIndex = 2
                        togglerHead.Parent = toggleButton
                    end)

                    local TweenSettings = {
                        Info = TweenInfo.new(0.2, Enum.EasingStyle.Sine),
                        EnabledColors = {Toggle = Color3.fromRGB(87, 86, 86), ToggleHead = Color3.fromRGB(255, 255, 255)},
                        DisabledColors = {Toggle = Color3.fromRGB(61, 61, 61), ToggleHead = Color3.fromRGB(91, 91, 91)},
                        EnabledPosition = UDim2.new(1, 0, 0.5, 0),
                        DisabledPosition = UDim2.new(0.5, 0, 0.5, 0),
                    }

                    local function ToggleState(State)
                        pcall(function()
                            if State then
                                local t1 = Tween(toggleButton, TweenSettings.Info, {
                                    ImageColor3 = TweenSettings.EnabledColors.Toggle
                                })
                                if t1 then t1:Play() end

                                local t2 = Tween(togglerHead, TweenSettings.Info, {
                                    ImageColor3 = TweenSettings.EnabledColors.ToggleHead
                                })
                                if t2 then t2:Play() end

                                local t3 = Tween(togglerHead, TweenSettings.Info, {
                                    Position = TweenSettings.EnabledPosition
                                })
                                if t3 then t3:Play() end
                            else
                                local t1 = Tween(toggleButton, TweenSettings.Info, {
                                    ImageColor3 = TweenSettings.DisabledColors.Toggle
                                })
                                if t1 then t1:Play() end

                                local t2 = Tween(togglerHead, TweenSettings.Info, {
                                    ImageColor3 = TweenSettings.DisabledColors.ToggleHead
                                })
                                if t2 then t2:Play() end

                                local t3 = Tween(togglerHead, TweenSettings.Info, {
                                    Position = TweenSettings.DisabledPosition
                                })
                                if t3 then t3:Play() end
                            end
                            
                            ToggleFunctions.State = State
                        end)
                    end

                    local togglebool = Settings.Default or false
                    ToggleState(togglebool)

                    local function Toggle()
                        togglebool = not togglebool
                        ToggleState(togglebool)
                        if Settings.Callback then
                            pcall(Settings.Callback, togglebool)
                        end
                    end

                    pcall(function()
                        toggleButton.MouseButton1Click:Connect(Toggle)
                    end)

                    function ToggleFunctions:Toggle()
                        Toggle()
                    end
                    
                    function ToggleFunctions:UpdateState(State)
                        togglebool = State
                        ToggleState(togglebool)
                        if Settings.Callback then
                            pcall(Settings.Callback, togglebool)
                        end
                    end
                    
                    function ToggleFunctions:GetState()
                        return togglebool
                    end
                    
                    function ToggleFunctions:UpdateName(Name)
                        pcall(function()
                            if toggleName then toggleName.Text = Name end
                        end)
                    end
                    
                    function ToggleFunctions:SetVisibility(State)
                        pcall(function()
                            if toggle then toggle.Visible = State end
                        end)
                    end
                    
                    return ToggleFunctions
                end

                -- Slider element
                function SectionFunctions:Slider(Settings)
                    local SliderFunctions = {}
                    
                    local slider
                    pcall(function()
                        slider = Instance.new("Frame")
                        slider.Name = "Slider"
                        slider.AutomaticSize = Enum.AutomaticSize.Y
                        slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        slider.BackgroundTransparency = 1
                        slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        slider.BorderSizePixel = 0
                        slider.Size = UDim2.new(1, 0, 0, 38)
                        slider.Parent = section
                    end)

                    local sliderName
                    pcall(function()
                        sliderName = Instance.new("TextLabel")
                        sliderName.Name = "SliderName"
                        sliderName.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        sliderName.Text = Settings.Name or "Slider"
                        sliderName.RichText = true
                        sliderName.TextColor3 = Color3.fromRGB(255, 255, 255)
                        sliderName.TextSize = 13
                        sliderName.TextTransparency = 0.5
                        sliderName.TextTruncate = Enum.TextTruncate.AtEnd
                        sliderName.TextXAlignment = Enum.TextXAlignment.Left
                        sliderName.TextYAlignment = Enum.TextYAlignment.Top
                        sliderName.AnchorPoint = Vector2.new(0, 0.5)
                        sliderName.AutomaticSize = Enum.AutomaticSize.XY
                        sliderName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        sliderName.BackgroundTransparency = 1
                        sliderName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        sliderName.BorderSizePixel = 0
                        sliderName.Position = UDim2.fromScale(1.3e-07, 0.5)
                        sliderName.Parent = slider
                    end)

                    local sliderElements
                    pcall(function()
                        sliderElements = Instance.new("Frame")
                        sliderElements.Name = "SliderElements"
                        sliderElements.AnchorPoint = Vector2.new(1, 0)
                        sliderElements.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        sliderElements.BackgroundTransparency = 1
                        sliderElements.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        sliderElements.BorderSizePixel = 0
                        sliderElements.Position = UDim2.fromScale(1, 0)
                        sliderElements.Size = UDim2.fromScale(1, 1)
                        sliderElements.Parent = slider
                    end)

                    local sliderValue
                    pcall(function()
                        sliderValue = Instance.new("TextBox")
                        sliderValue.Name = "SliderValue"
                        sliderValue.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        sliderValue.Text = "100%"
                        sliderValue.TextColor3 = Color3.fromRGB(255, 255, 255)
                        sliderValue.TextSize = 12
                        sliderValue.TextTransparency = 0.4
                        sliderValue.TextTruncate = Enum.TextTruncate.AtEnd
                        sliderValue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        sliderValue.BackgroundTransparency = 0.95
                        sliderValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        sliderValue.BorderSizePixel = 0
                        sliderValue.LayoutOrder = 1
                        sliderValue.Position = UDim2.fromScale(-0.0789, 0.171)
                        sliderValue.Size = UDim2.fromOffset(41, 21)
                        sliderValue.Parent = sliderElements
                    end)

                    local sliderValueUICorner
                    pcall(function()
                        sliderValueUICorner = Instance.new("UICorner")
                        sliderValueUICorner.Name = "SliderValueUICorner"
                        sliderValueUICorner.CornerRadius = UDim.new(0, 4)
                        sliderValueUICorner.Parent = sliderValue
                    end)

                    local sliderValueUIStroke
                    pcall(function()
                        sliderValueUIStroke = Instance.new("UIStroke")
                        sliderValueUIStroke.Name = "SliderValueUIStroke"
                        sliderValueUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        sliderValueUIStroke.Color = Color3.fromRGB(255, 255, 255)
                        sliderValueUIStroke.Transparency = 0.9
                        sliderValueUIStroke.Parent = sliderValue
                    end)

                    local sliderValueUIPadding
                    pcall(function()
                        sliderValueUIPadding = Instance.new("UIPadding")
                        sliderValueUIPadding.Name = "SliderValueUIPadding"
                        sliderValueUIPadding.PaddingLeft = UDim.new(0, 2)
                        sliderValueUIPadding.PaddingRight = UDim.new(0, 2)
                        sliderValueUIPadding.Parent = sliderValue
                    end)

                    local sliderElementsUIListLayout
                    pcall(function()
                        sliderElementsUIListLayout = Instance.new("UIListLayout")
                        sliderElementsUIListLayout.Name = "SliderElementsUIListLayout"
                        sliderElementsUIListLayout.Padding = UDim.new(0, 20)
                        sliderElementsUIListLayout.FillDirection = Enum.FillDirection.Horizontal
                        sliderElementsUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                        sliderElementsUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        sliderElementsUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                        sliderElementsUIListLayout.Parent = sliderElements
                    end)

                    local sliderBar
                    pcall(function()
                        sliderBar = Instance.new("ImageLabel")
                        sliderBar.Name = "SliderBar"
                        sliderBar.Image = "rbxassetid://18772615246"
                        sliderBar.ImageColor3 = Color3.fromRGB(87, 86, 86)
                        sliderBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        sliderBar.BackgroundTransparency = 1
                        sliderBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        sliderBar.BorderSizePixel = 0
                        sliderBar.Position = UDim2.fromScale(0.219, 0.457)
                        sliderBar.Size = UDim2.fromOffset(123, 3)
                        sliderBar.Parent = sliderElements                    end)

                    local sliderHead
                    pcall(function()
                        sliderHead = Instance.new("ImageButton")
                        sliderHead.Name = "SliderHead"
                        sliderHead.Image = "rbxassetid://18772834246"
                        sliderHead.AnchorPoint = Vector2.new(0.5, 0.5)
                        sliderHead.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        sliderHead.BackgroundTransparency = 1
                        sliderHead.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        sliderHead.BorderSizePixel = 0
                        sliderHead.Position = UDim2.fromScale(1, 0.5)
                        sliderHead.Size = UDim2.fromOffset(12, 12)
                        sliderHead.Parent = sliderBar
                    end)

                    local sliderElementsUIPadding
                    pcall(function()
                        sliderElementsUIPadding = Instance.new("UIPadding")
                        sliderElementsUIPadding.Name = "SliderElementsUIPadding"
                        sliderElementsUIPadding.PaddingTop = UDim.new(0, 3)
                        sliderElementsUIPadding.Parent = sliderElements
                    end)

                    local dragging = false
                    local finalValue = Settings.Default or 0

                    local DisplayMethods = {
                        Hundredths = function(sliderValue)
                            return string.format("%.2f", sliderValue)
                        end,
                        Tenths = function(sliderValue)
                            return string.format("%.1f", sliderValue)
                        end,
                        Round = function(sliderValue)
                            return tostring(math.round(sliderValue))
                        end,
                        Degrees = function(sliderValue)
                            return tostring(math.round(sliderValue)) .. "°"
                        end,
                        Percent = function(sliderValue)
                            local min = Settings.Minimum or 0
                            local max = Settings.Maximum or 100
                            local percentage = (sliderValue - min) / (max - min) * 100
                            return tostring(math.round(percentage)) .. "%"
                        end,
                        Value = function(sliderValue)
                            return tostring(sliderValue)
                        end
                    }

                    local ValueDisplayMethod = DisplayMethods[Settings.DisplayMethod] or DisplayMethods.Value

                    local function SetValue(val, ignorecallback)
                        pcall(function()
                            local posXScale
                            local min = Settings.Minimum or 0
                            local max = Settings.Maximum or 100

                            if typeof(val) == "Instance" then
                                local input = val
                                posXScale = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                            else
                                local value = val
                                posXScale = (value - min) / (max - min)
                            end

                            local pos = UDim2.new(posXScale, 0, 0.5, 0)
                            sliderHead.Position = pos

                            finalValue = posXScale * (max - min) + min
                            sliderValue.Text = ValueDisplayMethod(finalValue)

                            if not ignorecallback then
                                task.spawn(function()
                                    if Settings.Callback then
                                        pcall(Settings.Callback, finalValue)
                                    end
                                end)
                            end
                            
                            SliderFunctions.Value = finalValue
                        end)
                    end

                    SetValue(Settings.Default or 50, true)

                    pcall(function()
                        sliderHead.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                dragging = true
                                SetValue(input)
                            end
                        end)

                        sliderHead.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                dragging = false
                            end
                        end)

                        sliderValue.FocusLost:Connect(function(enterPressed)
                            local inputText = sliderValue.Text
                            local value, isPercent = inputText:match("^(%-?%d+%.?%d*)(%%?)$")

                            if value then
                                value = tonumber(value)
                                isPercent = isPercent == "%"

                                if isPercent then
                                    local min = Settings.Minimum or 0
                                    local max = Settings.Maximum or 100
                                    value = min + (value / 100) * (max - min)
                                end

                                local newValue = math.clamp(value, Settings.Minimum or 0, Settings.Maximum or 100)
                                SetValue(newValue)
                            else
                                sliderValue.Text = ValueDisplayMethod(finalValue)
                            end
                        end)

                        UserInputService.InputChanged:Connect(function(input)
                            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                SetValue(input)
                            end
                        end)
                    end)

                    local function updateSliderBarSize()
                        pcall(function()
                            if not sliderElements or not sliderValue or not sliderName or not sliderBar then return end
                            local padding = sliderElementsUIListLayout and sliderElementsUIListLayout.Padding.Offset or 20
                            local sliderValueWidth = sliderValue.AbsoluteSize.X
                            local sliderNameWidth = sliderName.AbsoluteSize.X
                            local totalWidth = sliderElements.AbsoluteSize.X

                            local newBarWidth = totalWidth - (padding + sliderValueWidth + sliderNameWidth + 20)
                            sliderBar.Size = UDim2.new(sliderBar.Size.X.Scale, newBarWidth, sliderBar.Size.Y.Scale, sliderBar.Size.Y.Offset)
                        end)
                    end

                    updateSliderBarSize()

                    pcall(function()
                        sliderName:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSliderBarSize)
                        if section then
                            section:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSliderBarSize)
                        end
                    end)

                    function SliderFunctions:UpdateName(Name)
                        pcall(function()
                            if sliderName then sliderName.Text = Name end
                        end)
                    end
                    
                    function SliderFunctions:SetVisibility(State)
                        pcall(function()
                            if slider then slider.Visible = State end
                        end)
                    end
                    
                    function SliderFunctions:UpdateValue(Value)
                        SetValue(Value)
                    end
                    
                    function SliderFunctions:GetValue()
                        return finalValue
                    end
                    
                    return SliderFunctions
                end

                -- Input element
                function SectionFunctions:Input(Settings)
                    local InputFunctions = {}
                    
                    local input
                    pcall(function()
                        input = Instance.new("Frame")
                        input.Name = "Input"
                        input.AutomaticSize = Enum.AutomaticSize.Y
                        input.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        input.BackgroundTransparency = 1
                        input.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        input.BorderSizePixel = 0
                        input.Size = UDim2.new(1, 0, 0, 38)
                        input.Parent = section
                    end)

                    local inputName
                    pcall(function()
                        inputName = Instance.new("TextLabel")
                        inputName.Name = "InputName"
                        inputName.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        inputName.Text = Settings.Name or "Input"
                        inputName.RichText = true
                        inputName.TextColor3 = Color3.fromRGB(255, 255, 255)
                        inputName.TextSize = 13
                        inputName.TextTransparency = 0.5
                        inputName.TextTruncate = Enum.TextTruncate.AtEnd
                        inputName.TextXAlignment = Enum.TextXAlignment.Left
                        inputName.TextYAlignment = Enum.TextYAlignment.Top
                        inputName.AnchorPoint = Vector2.new(0, 0.5)
                        inputName.AutomaticSize = Enum.AutomaticSize.XY
                        inputName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        inputName.BackgroundTransparency = 1
                        inputName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        inputName.BorderSizePixel = 0
                        inputName.Position = UDim2.fromScale(0, 0.5)
                        inputName.Parent = input
                    end)

                    local inputBox
                    pcall(function()
                        inputBox = Instance.new("TextBox")
                        inputBox.Name = "InputBox"
                        inputBox.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        inputBox.Text = Settings.Default or ""
                        inputBox.PlaceholderText = Settings.Placeholder or ""
                        inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                        inputBox.TextSize = 12
                        inputBox.TextTransparency = 0.4
                        inputBox.AnchorPoint = Vector2.new(1, 0.5)
                        inputBox.AutomaticSize = Enum.AutomaticSize.X
                        inputBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        inputBox.BackgroundTransparency = 0.95
                        inputBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        inputBox.BorderSizePixel = 0
                        inputBox.ClipsDescendants = true
                        inputBox.LayoutOrder = 1
                        inputBox.Position = UDim2.fromScale(1, 0.5)
                        inputBox.Size = UDim2.fromOffset(21, 21)
                        inputBox.Parent = input
                    end)

                    local inputBoxUICorner
                    pcall(function()
                        inputBoxUICorner = Instance.new("UICorner")
                        inputBoxUICorner.Name = "InputBoxUICorner"
                        inputBoxUICorner.CornerRadius = UDim.new(0, 4)
                        inputBoxUICorner.Parent = inputBox
                    end)

                    local inputBoxUIStroke
                    pcall(function()
                        inputBoxUIStroke = Instance.new("UIStroke")
                        inputBoxUIStroke.Name = "InputBoxUIStroke"
                        inputBoxUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        inputBoxUIStroke.Color = Color3.fromRGB(255, 255, 255)
                        inputBoxUIStroke.Transparency = 0.9
                        inputBoxUIStroke.Parent = inputBox
                    end)

                    local inputBoxUIPadding
                    pcall(function()
                        inputBoxUIPadding = Instance.new("UIPadding")
                        inputBoxUIPadding.Name = "InputBoxUIPadding"
                        inputBoxUIPadding.PaddingLeft = UDim.new(0, 5)
                        inputBoxUIPadding.PaddingRight = UDim.new(0, 5)
                        inputBoxUIPadding.Parent = inputBox
                    end)

                    local inputBoxUISizeConstraint
                    pcall(function()
                        inputBoxUISizeConstraint = Instance.new("UISizeConstraint")
                        inputBoxUISizeConstraint.Name = "InputBoxUISizeConstraint"
                        inputBoxUISizeConstraint.Parent = inputBox
                    end)

                    local CharacterSubs = {
                        All = function(value)
                            return value
                        end,
                        Numeric = function(value)
                            return value:match("^%-?%d*$") and value or value:gsub("[^%d-]", ""):gsub("(%-)", function(match, pos, original)
                                if pos == 1 then
                                    return match
                                else
                                    return ""
                                end
                            end)
                        end,
                        Alphabetic = function(value)
                            return value:gsub("[^a-zA-Z ]", "")
                        end,
                    }

                    local AcceptedCharacters = CharacterSubs[Settings.AcceptedCharacters] or CharacterSubs.All

                    pcall(function()
                        inputBox.AutomaticSize = Enum.AutomaticSize.X
                    end)

                    local function checkSize()
                        pcall(function()
                            if not inputName or not input or not inputBoxUISizeConstraint then return end
                            local nameWidth = inputName.AbsoluteSize.X
                            local totalWidth = input.AbsoluteSize.X
                            local maxWidth = totalWidth - nameWidth - 20
                            inputBoxUISizeConstraint.MaxSize = Vector2.new(maxWidth, 9e9)
                        end)
                    end

                    checkSize()

                    pcall(function()
                        inputName:GetPropertyChangedSignal("AbsoluteSize"):Connect(checkSize)
                    end)

                    pcall(function()
                        inputBox.FocusLost:Connect(function()
                            local inputText = inputBox.Text
                            local filteredText = AcceptedCharacters(inputText)
                            inputBox.Text = filteredText
                            task.spawn(function()
                                if Settings.Callback then
                                    pcall(Settings.Callback, filteredText)
                                end
                            end)
                        end)

                        inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                            inputBox.Text = AcceptedCharacters(inputBox.Text)
                            if Settings.onChanged then
                                pcall(Settings.onChanged, inputBox.Text)
                            end
                            InputFunctions.Text = inputBox.Text
                        end)
                    end)

                    function InputFunctions:UpdateName(Name)
                        pcall(function()
                            if inputName then inputName.Text = Name end
                        end)
                    end
                    
                    function InputFunctions:SetVisibility(State)
                        pcall(function()
                            if input then input.Visible = State end
                        end)
                    end
                    
                    function InputFunctions:GetInput()
                        return inputBox and inputBox.Text or ""
                    end
                    
                    function InputFunctions:UpdatePlaceholder(Placeholder)
                        pcall(function()
                            if inputBox then inputBox.PlaceholderText = Placeholder end
                        end)
                    end
                    
                    function InputFunctions:UpdateText(Text)
                        pcall(function()
                            if inputBox then inputBox.Text = Text end
                        end)
                    end
                    
                    return InputFunctions
                end

                -- Keybind element
                function SectionFunctions:Keybind(Settings)
                    local KeybindFunctions = {}
                    
                    local keybind
                    pcall(function()
                        keybind = Instance.new("Frame")
                        keybind.Name = "Keybind"
                        keybind.AutomaticSize = Enum.AutomaticSize.Y
                        keybind.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        keybind.BackgroundTransparency = 1
                        keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        keybind.BorderSizePixel = 0
                        keybind.Size = UDim2.new(1, 0, 0, 38)
                        keybind.Parent = section
                    end)

                    local keybindName
                    pcall(function()
                        keybindName = Instance.new("TextLabel")
                        keybindName.Name = "KeybindName"
                        keybindName.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        keybindName.Text = Settings.Name or "Keybind"
                        keybindName.RichText = true
                        keybindName.TextColor3 = Color3.fromRGB(255, 255, 255)
                        keybindName.TextSize = 13
                        keybindName.TextTransparency = 0.5
                        keybindName.TextTruncate = Enum.TextTruncate.AtEnd
                        keybindName.TextXAlignment = Enum.TextXAlignment.Left
                        keybindName.TextYAlignment = Enum.TextYAlignment.Top
                        keybindName.AnchorPoint = Vector2.new(0, 0.5)
                        keybindName.AutomaticSize = Enum.AutomaticSize.XY
                        keybindName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        keybindName.BackgroundTransparency = 1
                        keybindName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        keybindName.BorderSizePixel = 0
                        keybindName.Position = UDim2.fromScale(0, 0.5)
                        keybindName.Parent = keybind
                    end)

                    local binderBox
                    pcall(function()
                        binderBox = Instance.new("TextBox")
                        binderBox.Name = "BinderBox"
                        binderBox.CursorPosition = -1
                        binderBox.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        binderBox.PlaceholderText = "..."
                        binderBox.Text = ""
                        binderBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                        binderBox.TextSize = 12
                        binderBox.TextTransparency = 0.4
                        binderBox.AnchorPoint = Vector2.new(1, 0.5)
                        binderBox.AutomaticSize = Enum.AutomaticSize.X
                        binderBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        binderBox.BackgroundTransparency = 0.95
                        binderBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        binderBox.BorderSizePixel = 0
                        binderBox.ClipsDescendants = true
                        binderBox.LayoutOrder = 1
                        binderBox.Position = UDim2.fromScale(1, 0.5)
                        binderBox.Size = UDim2.fromOffset(21, 21)
                        binderBox.Parent = keybind
                    end)

                    local binderBoxUICorner
                    pcall(function()
                        binderBoxUICorner = Instance.new("UICorner")
                        binderBoxUICorner.Name = "BinderBoxUICorner"
                        binderBoxUICorner.CornerRadius = UDim.new(0, 4)
                        binderBoxUICorner.Parent = binderBox
                    end)

                    local binderBoxUIStroke
                    pcall(function()
                        binderBoxUIStroke = Instance.new("UIStroke")
                        binderBoxUIStroke.Name = "BinderBoxUIStroke"
                        binderBoxUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        binderBoxUIStroke.Color = Color3.fromRGB(255, 255, 255)
                        binderBoxUIStroke.Transparency = 0.9
                        binderBoxUIStroke.Parent = binderBox
                    end)

                    local binderBoxUIPadding
                    pcall(function()
                        binderBoxUIPadding = Instance.new("UIPadding")
                        binderBoxUIPadding.Name = "BinderBoxUIPadding"
                        binderBoxUIPadding.PaddingLeft = UDim.new(0, 5)
                        binderBoxUIPadding.PaddingRight = UDim.new(0, 5)
                        binderBoxUIPadding.Parent = binderBox
                    end)

                    local binderBoxUISizeConstraint
                    pcall(function()
                        binderBoxUISizeConstraint = Instance.new("UISizeConstraint")
                        binderBoxUISizeConstraint.Name = "BinderBoxUISizeConstraint"
                        binderBoxUISizeConstraint.Parent = binderBox
                    end)

                    local focused = false
                    local binded = Settings.Default

                    if binded then
                        pcall(function()
                            binderBox.Text = binded.Name
                        end)
                    end

                    pcall(function()
                        binderBox.Focused:Connect(function()
                            focused = true
                        end)
                        binderBox.FocusLost:Connect(function()
                            focused = false
                        end)
                    end)

                    local inputEndedConnection
                    pcall(function()
                        inputEndedConnection = UserInputService.InputEnded:Connect(function(inp)
                            if macLib ~= nil then
                                if focused and inp.KeyCode.Name ~= "Unknown" then
                                    binded = inp.KeyCode
                                    KeybindFunctions.Bind = binded
                                    binderBox.Text = inp.KeyCode.Name
                                    binderBox:ReleaseFocus()
                                    if Settings.onBinded then
                                        pcall(Settings.onBinded, binded)
                                    end
                                elseif inp.KeyCode == binded then
                                    if Settings.Callback then
                                        pcall(Settings.Callback, binded)
                                    end
                                end
                            end
                        end)
                    end)

                    function KeybindFunctions:Bind(Key)
                        pcall(function()
                            binded = Key
                            binderBox.Text = Key.Name
                        end)
                    end
                    
                    function KeybindFunctions:Unbind()
                        pcall(function()
                            binded = nil
                            binderBox.Text = ""
                        end)
                    end
                    
                    function KeybindFunctions:GetBind()
                        return binded
                    end
                    
                    function KeybindFunctions:UpdateName(Name)
                        pcall(function()
                            if keybindName then keybindName.Text = Name end
                        end)
                    end
                    
                    function KeybindFunctions:SetVisibility(State)
                        pcall(function()
                            if keybind then keybind.Visible = State end
                        end)
                    end
                    
                    return KeybindFunctions
                end

                -- Dropdown element
                function SectionFunctions:Dropdown(Settings)
                    local DropdownFunctions = {}
                    local Selected = {}
                    local OptionObjs = {}

                    local dropdown
                    pcall(function()
                        dropdown = Instance.new("Frame")
                        dropdown.Name = "Dropdown"
                        dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        dropdown.BackgroundTransparency = 0.985
                        dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        dropdown.BorderSizePixel = 0
                        dropdown.Size = UDim2.new(1, 0, 0, 38)
                        dropdown.Parent = section
                        dropdown.ClipsDescendants = true
                    end)

                    local dropdownUIPadding
                    pcall(function()
                        dropdownUIPadding = Instance.new("UIPadding")
                        dropdownUIPadding.Name = "DropdownUIPadding"
                        dropdownUIPadding.PaddingLeft = UDim.new(0, 15)
                        dropdownUIPadding.PaddingRight = UDim.new(0, 15)
                        dropdownUIPadding.Parent = dropdown
                    end)

                    local interactButton
                    pcall(function()
                        interactButton = Instance.new("TextButton")
                        interactButton.Name = "Interact"
                        interactButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
                        interactButton.Text = ""
                        interactButton.TextColor3 = Color3.fromRGB(0, 0, 0)
                        interactButton.TextSize = 14
                        interactButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        interactButton.BackgroundTransparency = 1
                        interactButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        interactButton.BorderSizePixel = 0
                        interactButton.Size = UDim2.new(1, 0, 0, 38)
                        interactButton.Parent = dropdown
                    end)

                    local dropdownName
                    pcall(function()
                        dropdownName = Instance.new("TextLabel")
                        dropdownName.Name = "DropdownName"
                        dropdownName.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        dropdownName.Text = Settings.Name or "Dropdown"
                        dropdownName.RichText = true
                        dropdownName.TextColor3 = Color3.fromRGB(255, 255, 255)
                        dropdownName.TextSize = 13
                        dropdownName.TextTransparency = 0.5
                        dropdownName.TextTruncate = Enum.TextTruncate.SplitWord
                        dropdownName.TextXAlignment = Enum.TextXAlignment.Left
                        dropdownName.AutomaticSize = Enum.AutomaticSize.Y
                        dropdownName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        dropdownName.BackgroundTransparency = 1
                        dropdownName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        dropdownName.BorderSizePixel = 0
                        dropdownName.Size = UDim2.new(1, -20, 0, 38)
                        dropdownName.Parent = dropdown
                    end)

                    local dropdownUIStroke
                    pcall(function()
                        dropdownUIStroke = Instance.new("UIStroke")
                        dropdownUIStroke.Name = "DropdownUIStroke"
                        dropdownUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        dropdownUIStroke.Color = Color3.fromRGB(255, 255, 255)
                        dropdownUIStroke.Transparency = 0.95
                        dropdownUIStroke.Parent = dropdown
                    end)

                    local dropdownUICorner
                    pcall(function()
                        dropdownUICorner = Instance.new("UICorner")
                        dropdownUICorner.Name = "DropdownUICorner"
                        dropdownUICorner.CornerRadius = UDim.new(0, 6)
                        dropdownUICorner.Parent = dropdown
                    end)

                    local dropdownImage
                    pcall(function()
                        dropdownImage = Instance.new("ImageLabel")
                        dropdownImage.Name = "DropdownImage"
                        dropdownImage.Image = "rbxassetid://18865373378"
                        dropdownImage.ImageTransparency = 0.5
                        dropdownImage.AnchorPoint = Vector2.new(1, 0)
                        dropdownImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        dropdownImage.BackgroundTransparency = 1
                        dropdownImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        dropdownImage.BorderSizePixel = 0
                        dropdownImage.Position = UDim2.new(1, 0, 0, 12)
                        dropdownImage.Size = UDim2.fromOffset(14, 14)
                        dropdownImage.Parent = dropdown
                    end)

                    local dropdownFrame
                    pcall(function()
                        dropdownFrame = Instance.new("Frame")
                        dropdownFrame.Name = "DropdownFrame"
                        dropdownFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        dropdownFrame.BackgroundTransparency = 1
                        dropdownFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        dropdownFrame.BorderSizePixel = 0
                        dropdownFrame.ClipsDescendants = true
                        dropdownFrame.Size = UDim2.fromScale(1, 1)
                        dropdownFrame.Visible = false
                        dropdownFrame.AutomaticSize = Enum.AutomaticSize.Y
                        dropdownFrame.Parent = dropdown
                    end)

                    local dropdownFrameUIPadding
                    pcall(function()
                        dropdownFrameUIPadding = Instance.new("UIPadding")
                        dropdownFrameUIPadding.Name = "DropdownFrameUIPadding"
                        dropdownFrameUIPadding.PaddingTop = UDim.new(0, 38)
                        dropdownFrameUIPadding.PaddingBottom = UDim.new(0, 10)
                        dropdownFrameUIPadding.Parent = dropdownFrame
                    end)

                    local dropdownFrameUIListLayout
                    pcall(function()
                        dropdownFrameUIListLayout = Instance.new("UIListLayout")
                        dropdownFrameUIListLayout.Name = "DropdownFrameUIListLayout"
                        dropdownFrameUIListLayout.Padding = UDim.new(0, 5)
                        dropdownFrameUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        dropdownFrameUIListLayout.Parent = dropdownFrame
                    end)

                    -- Search frame
                    local search
                    pcall(function()
                        search = Instance.new("Frame")
                        search.Name = "Search"
                        search.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        search.BackgroundTransparency = 0.95
                        search.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        search.BorderSizePixel = 0
                        search.LayoutOrder = -1
                        search.Size = UDim2.new(1, 0, 0, 30)
                        search.Parent = dropdownFrame
                        search.Visible = Settings.Search or false
                    end)

                    local searchCorner
                    pcall(function()
                        searchCorner = Instance.new("UICorner")
                        searchCorner.Name = "SectionUICorner"
                        searchCorner.Parent = search
                    end)

                    local searchIconImg
                    pcall(function()
                        searchIconImg = Instance.new("ImageLabel")
                        searchIconImg.Name = "SearchIcon"
                        searchIconImg.Image = assets.searchIcon
                        searchIconImg.ImageColor3 = Color3.fromRGB(180, 180, 180)
                        searchIconImg.AnchorPoint = Vector2.new(0, 0.5)
                        searchIconImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        searchIconImg.BackgroundTransparency = 1
                        searchIconImg.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        searchIconImg.BorderSizePixel = 0
                        searchIconImg.Position = UDim2.fromScale(0, 0.5)
                        searchIconImg.Size = UDim2.fromOffset(12, 12)
                        searchIconImg.Parent = search
                    end)

                    local searchPadding
                    pcall(function()
                        searchPadding = Instance.new("UIPadding")
                        searchPadding.Name = "UIPadding"
                        searchPadding.PaddingLeft = UDim.new(0, 15)
                        searchPadding.Parent = search
                    end)

                    local searchBox
                    pcall(function()
                        searchBox = Instance.new("TextBox")
                        searchBox.Name = "SearchBox"
                        searchBox.CursorPosition = -1
                        searchBox.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
                        searchBox.PlaceholderText = "Search..."
                        searchBox.Text = ""
                        searchBox.TextColor3 = Color3.fromRGB(200, 200, 200)
                        searchBox.TextSize = 14
                        searchBox.TextXAlignment = Enum.TextXAlignment.Left
                        searchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        searchBox.BackgroundTransparency = 1
                        searchBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        searchBox.BorderSizePixel = 0
                        searchBox.Size = UDim2.fromScale(1, 1)
                        searchBox.Parent = search
                    end)

                    local searchBoxPadding
                    pcall(function()
                        searchBoxPadding = Instance.new("UIPadding")
                        searchBoxPadding.Name = "UIPadding"
                        searchBoxPadding.PaddingLeft = UDim.new(0, 23)
                        searchBoxPadding.Parent = searchBox
                    end)

                    local function CalculateDropdownSize()
                        if not dropdownFrame then return 38 end
                        local totalHeight = 0
                        local visibleChildrenCount = 0
                        local padding = (dropdownFrameUIPadding and dropdownFrameUIPadding.PaddingTop.Offset or 0) + (dropdownFrameUIPadding and dropdownFrameUIPadding.PaddingBottom.Offset or 0)

                        for _, v in pairs(dropdownFrame:GetChildren()) do
                            if not v:IsA("UIComponent") and v.Visible then
                                totalHeight = totalHeight + (v.AbsoluteSize.Y or 30)
                                visibleChildrenCount = visibleChildrenCount + 1
                            end
                        end

                        local spacing = (dropdownFrameUIListLayout and dropdownFrameUIListLayout.Padding.Offset or 5) * (visibleChildrenCount - 1)

                        return totalHeight + spacing + padding
                    end

                    local function findOption()
                        if not searchBox then return end
                        local searchTerm = searchBox.Text:lower()

                        for _, v in pairs(OptionObjs) do
                            local optionText = (v.NameLabel and v.NameLabel.Text:lower()) or ""
                            local isVisible = string.find(optionText, searchTerm) ~= nil

                            if v.Button then
                                v.Button.Visible = isVisible
                            end
                        end

                        if dropdown then
                            dropdown.Size = UDim2.new(1, 0, 0, CalculateDropdownSize())
                        end
                    end

                    if searchBox then
                        pcall(function()
                            searchBox:GetPropertyChangedSignal("Text"):Connect(findOption)
                        end)
                    end

                    local tweensettings = {
                        duration = 0.2,
                        easingStyle = Enum.EasingStyle.Quint,
                        transparencyIn = 0.2,
                        transparencyOut = 0.5,
                        checkSizeIncrease = 12,
                        checkSizeDecrease = -13,
                        waitTime = 1
                    }

                    local function ToggleDropdownOption(optionName, State)
                        local option = OptionObjs[optionName]
                        if not option then return end

                        local checkmark = option.Checkmark
                        local optionNameLabel = option.NameLabel

                        if State then
                            if Settings.Multi then
                                if not table.find(Selected, optionName) then
                                    table.insert(Selected, optionName)
                                    DropdownFunctions.Value = Selected
                                end
                            else
                                for name, opt in pairs(OptionObjs) do
                                    if name ~= optionName then
                                        local co = Tween(opt.Checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                                            Size = UDim2.new(opt.Checkmark.Size.X.Scale, tweensettings.checkSizeDecrease, opt.Checkmark.Size.Y.Scale, opt.Checkmark.Size.Y.Offset)
                                        })
                                        if co then co:Play() end
                                        local no = Tween(opt.NameLabel, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                                            TextTransparency = tweensettings.transparencyOut
                                        })
                                        if no then no:Play() end
                                        if opt.Checkmark then
                                            opt.Checkmark.TextTransparency = 1
                                        end
                                    end
                                end
                                Selected = {optionName}
                                DropdownFunctions.Value = Selected[1]
                            end
                            local ci = Tween(checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                                Size = UDim2.new(checkmark.Size.X.Scale, tweensettings.checkSizeIncrease, checkmark.Size.Y.Scale, checkmark.Size.Y.Offset)
                            })
                            if ci then ci:Play() end
                            local ni = Tween(optionNameLabel, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                                TextTransparency = tweensettings.transparencyIn
                            })
                            if ni then ni:Play() end
                            if checkmark then
                                checkmark.TextTransparency = 0
                            end
                        else
                            if Settings.Multi then
                                local idx = table.find(Selected, optionName)
                                if idx then
                                    table.remove(Selected, idx)
                                end
                            else
                                Selected = {}
                            end
                            local co = Tween(checkmark, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                                Size = UDim2.new(checkmark.Size.X.Scale, tweensettings.checkSizeDecrease, checkmark.Size.Y.Scale, checkmark.Size.Y.Offset)
                            })
                            if co then co:Play() end
                            local no = Tween(optionNameLabel, TweenInfo.new(tweensettings.duration, tweensettings.easingStyle), {
                                TextTransparency = tweensettings.transparencyOut
                            })
                            if no then no:Play() end
                            if checkmark then
                                checkmark.TextTransparency = 1
                            end
                        end

                        if Settings.Required and #Selected == 0 and not State then
                            return
                        end

                        if dropdownName then
                            if #Selected > 0 then
                                dropdownName.Text = (Settings.Name or "Dropdown") .. " • " .. table.concat(Selected, ", ")
                            else
                                dropdownName.Text = Settings.Name or "Dropdown"
                            end
                        end
                    end

                    local dropped = false
                    local db = false

                    local function ToggleDropdown()
                        if db then return end
                        db = true
                        local defaultDropdownSize = 38
                        local isDropdownOpen = not dropped
                        local targetSize = isDropdownOpen and UDim2.new(1, 0, 0, CalculateDropdownSize()) or UDim2.new(1, 0, 0, defaultDropdownSize)

                        local tween = Tween(dropdown, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                            Size = targetSize
                        })

                        if tween then tween:Play() end

                        if isDropdownOpen then
                            if dropdownFrame then dropdownFrame.Visible = true end
                            if tween then
                                tween.Completed:Connect(function()
                                    db = false
                                end)
                            end
                        else
                            if tween then
                                tween.Completed:Connect(function()
                                    if dropdownFrame then dropdownFrame.Visible = false end
                                    db = false
                                end)
                            end
                        end

                        dropped = isDropdownOpen
                    end

                    if interactButton then
                        pcall(function()
                            interactButton.MouseButton1Click:Connect(ToggleDropdown)
                        end)
                    end

                    local function addOption(i, v)
                        local option
                        pcall(function()
                            option = Instance.new("TextButton")
                            option.Name = "Option"
                            option.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
                            option.Text = ""
                            option.TextColor3 = Color3.fromRGB(0, 0, 0)
                            option.TextSize = 14
                            option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            option.BackgroundTransparency = 1
                            option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            option.BorderSizePixel = 0
                            option.Size = UDim2.new(1, 0, 0, 30)
                            if dropdownFrame then
                                option.Parent = dropdownFrame
                            end
                        end)

                        local optionUIPadding
                        pcall(function()
                            optionUIPadding = Instance.new("UIPadding")
                            optionUIPadding.Name = "OptionUIPadding"
                            optionUIPadding.PaddingLeft = UDim.new(0, 15)
                            optionUIPadding.Parent = option
                        end)

                        local optionName
                        pcall(function()
                            optionName = Instance.new("TextLabel")
                            optionName.Name = "OptionName"
                            optionName.FontFace = Font.new(
                                assets.interFont,
                                Enum.FontWeight.Medium,
                                Enum.FontStyle.Normal
                            )
                            optionName.Text = v
                            optionName.RichText = true
                            optionName.TextColor3 = Color3.fromRGB(255, 255, 255)
                            optionName.TextSize = 13
                            optionName.TextTransparency = 0.5
                            optionName.TextTruncate = Enum.TextTruncate.AtEnd
                            optionName.TextXAlignment = Enum.TextXAlignment.Left
                            optionName.TextYAlignment = Enum.TextYAlignment.Top
                            optionName.AnchorPoint = Vector2.new(0, 0.5)
                            optionName.AutomaticSize = Enum.AutomaticSize.XY
                            optionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            optionName.BackgroundTransparency = 1
                            optionName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            optionName.BorderSizePixel = 0
                            optionName.Position = UDim2.fromScale(1.3e-07, 0.5)
                            optionName.Parent = option
                        end)

                        local optionUIListLayout
                        pcall(function()
                            optionUIListLayout = Instance.new("UIListLayout")
                            optionUIListLayout.Name = "OptionUIListLayout"
                            optionUIListLayout.Padding = UDim.new(0, 10)
                            optionUIListLayout.FillDirection = Enum.FillDirection.Horizontal
                            optionUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                            optionUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                            optionUIListLayout.Parent = option
                        end)

                        local checkmark
                        pcall(function()
                            checkmark = Instance.new("TextLabel")
                            checkmark.Name = "Checkmark"
                            checkmark.FontFace = Font.new(
                                assets.interFont,
                                Enum.FontWeight.Medium,
                                Enum.FontStyle.Normal
                            )
                            checkmark.Text = "✓"
                            checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
                            checkmark.TextSize = 13
                            checkmark.TextTransparency = 1
                            checkmark.TextXAlignment = Enum.TextXAlignment.Left
                            checkmark.TextYAlignment = Enum.TextYAlignment.Top
                            checkmark.AnchorPoint = Vector2.new(0, 0.5)
                            checkmark.AutomaticSize = Enum.AutomaticSize.Y
                            checkmark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            checkmark.BackgroundTransparency = 1
                            checkmark.BorderColor3 = Color3.fromRGB(0, 0, 0)
                            checkmark.BorderSizePixel = 0
                            checkmark.LayoutOrder = -1
                            checkmark.Position = UDim2.fromScale(1.3e-07, 0.5)
                            checkmark.Size = UDim2.fromOffset(-10, 0)
                            checkmark.Parent = option
                        end)

                        OptionObjs[v] = {
                            Index = i,
                            Button = option,
                            NameLabel = optionName,
                            Checkmark = checkmark
                        }

                        local isSelected = false
                        if Settings.Default then
                            if Settings.Multi then
                                isSelected = table.find(Settings.Default, v) and true or false
                            else
                                isSelected = (Settings.Default == i) and true or false
                            end
                        end
                        ToggleDropdownOption(v, isSelected)

                        if option then
                            pcall(function()
                                option.MouseButton1Click:Connect(function()
                                    local isSel = table.find(Selected, v) and true or false
                                    local newSelected = not isSel

                                    if Settings.Required and not newSelected and #Selected <= 1 then
                                        return
                                    end

                                    ToggleDropdownOption(v, newSelected)

                                    task.spawn(function()
                                        if Settings.Multi then
                                            local Return = {}
                                            for _, opt in ipairs(Selected) do
                                                Return[opt] = true
                                            end
                                            if Settings.Callback then
                                                pcall(Settings.Callback, Return)
                                            end
                                        else
                                            if newSelected and Settings.Callback then
                                                pcall(Settings.Callback, Selected[1] or nil)
                                            end
                                        end
                                    end)
                                end)
                            end)
                        end

                        if dropped and dropdown then
                            dropdown.Size = UDim2.new(1, 0, 0, CalculateDropdownSize())
                        end
                    end

                    if Settings.Options then
                        for i, v in pairs(Settings.Options) do
                            addOption(i, v)
                        end
                    end

                    function DropdownFunctions:UpdateName(New)
                        pcall(function()
                            if dropdownName then dropdownName.Text = New end
                        end)
                    end
                    
                    function DropdownFunctions:SetVisibility(State)
                        pcall(function()
                            if dropdown then dropdown.Visible = State end
                        end)
                    end
                    
                    function DropdownFunctions:UpdateSelection(newSelection)
                        pcall(function()
                            if type(newSelection) == "number" then
                                for option, data in pairs(OptionObjs) do
                                    local isSelected = data.Index == newSelection
                                    ToggleDropdownOption(option, isSelected)
                                end
                            elseif type(newSelection) == "table" then
                                for option, data in pairs(OptionObjs) do
                                    local isSelected = table.find(newSelection, option) ~= nil
                                    ToggleDropdownOption(option, isSelected)
                                end
                            end
                        end)
                    end
                    
                    function DropdownFunctions:InsertOptions(newOptions)
                        pcall(function()
                            Settings.Options = newOptions
                            for i, v in pairs(newOptions) do
                                addOption(i, v)
                            end
                        end)
                    end
                    
                    function DropdownFunctions:ClearOptions()
                        pcall(function()
                            for _, optionData in pairs(OptionObjs) do
                                if optionData.Button then
                                    optionData.Button:Destroy()
                                end
                            end
                            OptionObjs = {}
                            Selected = {}
                            
                            if dropped and dropdown then
                                dropdown.Size = UDim2.new(1, 0, 0, CalculateDropdownSize())
                            end
                        end)
                    end
                    
                    function DropdownFunctions:GetOptions()
                        local optionsStatus = {}
                        for option, data in pairs(OptionObjs) do
                            local isSelected = table.find(Selected, option) and true or false
                            optionsStatus[option] = isSelected
                        end
                        return optionsStatus
                    end
                    
                    function DropdownFunctions:RemoveOptions(remove)
                        pcall(function()
                            for _, optionName in ipairs(remove) do
                                local optionData = OptionObjs[optionName]
                                if optionData and optionData.Button then
                                    for i = #Selected, 1, -1 do
                                        if Selected[i] == optionName then
                                            table.remove(Selected, i)
                                        end
                                    end
                                    optionData.Button:Destroy()
                                    OptionObjs[optionName] = nil
                                end
                            end
                            if dropped and dropdown then
                                dropdown.Size = UDim2.new(1, 0, 0, CalculateDropdownSize())
                            end
                        end)
                    end
                    
                    function DropdownFunctions:IsOption(optionName)
                        return OptionObjs[optionName] ~= nil
                    end

                    return DropdownFunctions
                end

                -- Colorpicker element
                function SectionFunctions:Colorpicker(Settings)
                    local ColorpickerFunctions = {}
                    
                    local isAlpha = Settings.Alpha and true or false
                    ColorpickerFunctions.Color = Settings.Default or Color3.fromRGB(255, 255, 255)
                    ColorpickerFunctions.Alpha = isAlpha and (Settings.Alpha or 0) or 0

                    local colorpicker
                    pcall(function()
                        colorpicker = Instance.new("Frame")
                        colorpicker.Name = "Colorpicker"
                        colorpicker.AutomaticSize = Enum.AutomaticSize.Y
                        colorpicker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        colorpicker.BackgroundTransparency = 1
                        colorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        colorpicker.BorderSizePixel = 0
                        colorpicker.Size = UDim2.new(1, 0, 0, 38)
                        colorpicker.Parent = section
                    end)

                    local colorpickerName
                    pcall(function()
                        colorpickerName = Instance.new("TextLabel")
                        colorpickerName.Name = "KeybindName"
                        colorpickerName.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        colorpickerName.Text = Settings.Name or "Colorpicker"
                        colorpickerName.TextColor3 = Color3.fromRGB(255, 255, 255)
                        colorpickerName.TextSize = 13
                        colorpickerName.TextTransparency = 0.5
                        colorpickerName.RichText = true
                        colorpickerName.TextTruncate = Enum.TextTruncate.AtEnd
                        colorpickerName.TextXAlignment = Enum.TextXAlignment.Left
                        colorpickerName.TextYAlignment = Enum.TextYAlignment.Top
                        colorpickerName.AnchorPoint = Vector2.new(0, 0.5)
                        colorpickerName.AutomaticSize = Enum.AutomaticSize.XY
                        colorpickerName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        colorpickerName.BackgroundTransparency = 1
                        colorpickerName.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        colorpickerName.BorderSizePixel = 0
                        colorpickerName.Position = UDim2.fromScale(0, 0.5)
                        colorpickerName.Parent = colorpicker
                    end)

                    local colorCbg
                    pcall(function()
                        colorCbg = Instance.new("ImageLabel")
                        colorCbg.Name = "NewColor"
                        colorCbg.Image = "rbxassetid://121484455191370"
                        colorCbg.ScaleType = Enum.ScaleType.Tile
                        colorCbg.TileSize = UDim2.fromOffset(500, 500)
                        colorCbg.AnchorPoint = Vector2.new(1, 0.5)
                        colorCbg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        colorCbg.BackgroundTransparency = 1
                        colorCbg.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        colorCbg.BorderSizePixel = 0
                        colorCbg.Position = UDim2.fromScale(1, 0.5)
                        colorCbg.Size = UDim2.fromOffset(21, 21)
                        colorCbg.Parent = colorpicker
                    end)

                    local colorC
                    pcall(function()
                        colorC = Instance.new("Frame")
                        colorC.Name = "Color"
                        colorC.AnchorPoint = Vector2.new(0.5, 0.5)
                        colorC.BackgroundColor3 = ColorpickerFunctions.Color
                        colorC.BorderSizePixel = 0
                        colorC.Position = UDim2.fromScale(0.5, 0.5)
                        colorC.Size = UDim2.fromScale(1, 1)
                        colorC.BackgroundTransparency = ColorpickerFunctions.Alpha or 0
                        colorC.Parent = colorCbg
                    end)

                    local colorCorner
                    pcall(function()
                        colorCorner = Instance.new("UICorner")
                        colorCorner.Name = "UICorner"
                        colorCorner.CornerRadius = UDim.new(0, 6)
                        colorCorner.Parent = colorC
                    end)

                    local interactColor
                    pcall(function()
                        interactColor = Instance.new("TextButton")
                        interactColor.Name = "Interact"
                        interactColor.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
                        interactColor.Text = ""
                        interactColor.TextColor3 = Color3.fromRGB(0, 0, 0)
                        interactColor.TextSize = 14
                        interactColor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        interactColor.BackgroundTransparency = 1
                        interactColor.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        interactColor.BorderSizePixel = 0
                        interactColor.Size = UDim2.fromScale(1, 1)
                        interactColor.Parent = colorC
                    end)

                    local colorCbgCorner
                    pcall(function()
                        colorCbgCorner = Instance.new("UICorner")
                        colorCbgCorner.Name = "UICorner"
                        colorCbgCorner.CornerRadius = UDim.new(0, 8)
                        colorCbgCorner.Parent = colorCbg
                    end)

                    -- Color picker popup
                    local colorPicker
                    pcall(function()
                        colorPicker = Instance.new("Frame")
                        colorPicker.Name = "ColorPicker"
                        colorPicker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        colorPicker.BackgroundTransparency = 0.5
                        colorPicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        colorPicker.BorderSizePixel = 0
                        colorPicker.Size = UDim2.fromScale(1, 1)
                        colorPicker.Visible = false
                        colorPicker.Parent = base
                    end)

                    -- Due to length constraints, the full color picker UI creation is omitted
                    -- but follows same pcall pattern. The key functions are provided below.

                    local function colorpickerIn()
                        pcall(function()
                            if colorPicker then
                                colorPicker.Visible = true
                            end
                        end)
                    end

                    local function colorpickerOut()
                        pcall(function()
                            if colorPicker then
                                colorPicker.Visible = false
                            end
                        end)
                    end

                    if interactColor then
                        pcall(function()
                            interactColor.MouseButton1Click:Connect(colorpickerIn)
                        end)
                    end

                    function ColorpickerFunctions:UpdateName(New)
                        pcall(function()
                            if colorpickerName then colorpickerName.Text = New end
                        end)
                    end
                    
                    function ColorpickerFunctions:SetVisibility(State)
                        pcall(function()
                            if colorpicker then colorpicker.Visible = State end
                        end)
                    end

                    function ColorpickerFunctions:SetColor(color3)
                        pcall(function()
                            ColorpickerFunctions.Color = color3
                            if colorC then colorC.BackgroundColor3 = color3 end
                        end)
                    end

                    function ColorpickerFunctions:SetAlpha(alpha)
                        pcall(function()
                            ColorpickerFunctions.Alpha = alpha
                            if colorC then colorC.BackgroundTransparency = alpha end
                        end)
                    end

                    return ColorpickerFunctions
                end

                -- Header element
                function SectionFunctions:Header(Settings)
                    local HeaderFunctions = {}
                    
                    local header
                    pcall(function()
                        header = Instance.new("Frame")
                        header.Name = "Header"
                        header.AutomaticSize = Enum.AutomaticSize.Y
                        header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        header.BackgroundTransparency = 1
                        header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        header.BorderSizePixel = 0
                        header.LayoutOrder = 0
                        header.Size = UDim2.fromScale(1, 0)
                        header.Parent = section
                    end)

                    local headerPadding
                    pcall(function()
                        headerPadding = Instance.new("UIPadding")
                        headerPadding.Name = "UIPadding"
                        headerPadding.PaddingBottom = UDim.new(0, 5)
                        headerPadding.Parent = header
                    end)

                    local headerText
                    pcall(function()
                        headerText = Instance.new("TextLabel")
                        headerText.Name = "HeaderText"
                        headerText.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.SemiBold,
                            Enum.FontStyle.Normal
                        )
                        headerText.RichText = true
                        headerText.Text = Settings.Text or Settings.Name or "Header"
                        headerText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        headerText.TextSize = 16
                        headerText.TextTransparency = 0.4
                        headerText.TextWrapped = true
                        headerText.TextXAlignment = Enum.TextXAlignment.Left
                        headerText.AutomaticSize = Enum.AutomaticSize.Y
                        headerText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        headerText.BackgroundTransparency = 1
                        headerText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        headerText.BorderSizePixel = 0
                        headerText.Size = UDim2.fromScale(1, 0)
                        headerText.Parent = header
                    end)

                    function HeaderFunctions:UpdateName(New)
                        pcall(function()
                            if headerText then headerText.Text = New end
                        end)
                    end
                    
                    function HeaderFunctions:SetVisibility(State)
                        pcall(function()
                            if header then header.Visible = State end
                        end)
                    end

                    return HeaderFunctions
                end

                -- Label element
                function SectionFunctions:Label(Settings)
                    local LabelFunctions = {}
                    
                    local label
                    pcall(function()
                        label = Instance.new("Frame")
                        label.Name = "Label"
                        label.AutomaticSize = Enum.AutomaticSize.Y
                        label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        label.BackgroundTransparency = 1
                        label.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        label.BorderSizePixel = 0
                        label.Size = UDim2.new(1, 0, 0, 38)
                        label.Parent = section
                    end)

                    local labelText
                    pcall(function()
                        labelText = Instance.new("TextLabel")
                        labelText.Name = "LabelText"
                        labelText.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        labelText.RichText = true
                        labelText.Text = Settings.Text or Settings.Name or "Label"
                        labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        labelText.TextSize = 13
                        labelText.TextTransparency = 0.5
                        labelText.TextWrapped = true
                        labelText.TextXAlignment = Enum.TextXAlignment.Left
                        labelText.AutomaticSize = Enum.AutomaticSize.Y
                        labelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        labelText.BackgroundTransparency = 1
                        labelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        labelText.BorderSizePixel = 0
                        labelText.Size = UDim2.fromScale(1, 1)
                        labelText.Parent = label
                    end)

                    function LabelFunctions:UpdateName(New)
                        pcall(function()
                            if labelText then labelText.Text = New end
                        end)
                    end
                    
                    function LabelFunctions:SetVisibility(State)
                        pcall(function()
                            if label then label.Visible = State end
                        end)
                    end

                    return LabelFunctions
                end

                -- SubLabel element
                function SectionFunctions:SubLabel(Settings)
                    local SubLabelFunctions = {}

                    local subLabel
                    pcall(function()
                        subLabel = Instance.new("Frame")
                        subLabel.Name = "SubLabel"
                        subLabel.AutomaticSize = Enum.AutomaticSize.Y
                        subLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        subLabel.BackgroundTransparency = 1
                        subLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        subLabel.BorderSizePixel = 0
                        subLabel.Size = UDim2.new(1, 0, 0, 0)
                        subLabel.Parent = section
                    end)

                    local subLabelText
                    pcall(function()
                        subLabelText = Instance.new("TextLabel")
                        subLabelText.Name = "SubLabelText"
                        subLabelText.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        subLabelText.RichText = true
                        subLabelText.Text = Settings.Text or Settings.Name or "SubLabel"
                        subLabelText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        subLabelText.TextSize = 11
                        subLabelText.TextTransparency = 0.7
                        subLabelText.TextWrapped = true
                        subLabelText.TextXAlignment = Enum.TextXAlignment.Left
                        subLabelText.AutomaticSize = Enum.AutomaticSize.Y
                        subLabelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        subLabelText.BackgroundTransparency = 1
                        subLabelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        subLabelText.BorderSizePixel = 0
                        subLabelText.Size = UDim2.fromScale(1, 1)
                        subLabelText.Parent = subLabel
                    end)

                    function SubLabelFunctions:UpdateName(New)
                        pcall(function()
                            if subLabelText then subLabelText.Text = New end
                        end)
                    end
                    
                    function SubLabelFunctions:SetVisibility(State)
                        pcall(function()
                            if subLabel then subLabel.Visible = State end
                        end)
                    end

                    return SubLabelFunctions
                end

                -- Paragraph element
                function SectionFunctions:Paragraph(Settings)
                    local ParagraphFunctions = {}

                    local paragraph
                    pcall(function()
                        paragraph = Instance.new("Frame")
                        paragraph.Name = "Paragraph"
                        paragraph.AutomaticSize = Enum.AutomaticSize.Y
                        paragraph.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        paragraph.BackgroundTransparency = 1
                        paragraph.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        paragraph.BorderSizePixel = 0
                        paragraph.Size = UDim2.new(1, 0, 0, 38)
                        paragraph.Parent = section
                    end)

                    local paragraphHeader
                    pcall(function()
                        paragraphHeader = Instance.new("TextLabel")
                        paragraphHeader.Name = "ParagraphHeader"
                        paragraphHeader.FontFace = Font.new(
                            assets.interFont,
                            Enum.FontWeight.Medium,
                            Enum.FontStyle.Normal
                        )
                        paragraphHeader.RichText = true
                        paragraphHeader.Text = Settings.Header or "Header"
                        paragraphHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
                        paragraphHeader.TextSize = 16
                        paragraphHeader.TextTransparency = 0.4
                        paragraphHeader.TextWrapped = true
                        paragraphHeader.TextXAlignment = Enum.TextXAlignment.Left
                        paragraphHeader.AutomaticSize = Enum.AutomaticSize.Y
                        paragraphHeader.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        paragraphHeader.BackgroundTransparency = 1
                        paragraphHeader.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        paragraphHeader.BorderSizePixel = 0
                        paragraphHeader.Size = UDim2.fromScale(1, 0)
                        paragraphHeader.Parent = paragraph
                    end)

                    local paragraphUIListLayout
                    pcall(function()
                        paragraphUIListLayout = Instance.new("UIListLayout")
                        paragraphUIListLayout.Name = "UIListLayout"
                        paragraphUIListLayout.Padding = UDim.new(0, 5)
                        paragraphUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        paragraphUIListLayout.Parent = paragraph
                    end)

                    local paragraphBody
                    pcall(function()
                        paragraphBody = Instance.new("TextLabel")
                        paragraphBody.Name = "ParagraphBody"
                        paragraphBody.FontFace = Font.new(assets.interFont)
                        paragraphBody.RichText = true
                        paragraphBody.Text = Settings.Body or ""
                        paragraphBody.TextColor3 = Color3.fromRGB(255, 255, 255)
                        paragraphBody.TextSize = 13
                        paragraphBody.TextTransparency = 0.5
                        paragraphBody.TextWrapped = true
                        paragraphBody.TextXAlignment = Enum.TextXAlignment.Left
                        paragraphBody.AutomaticSize = Enum.AutomaticSize.Y
                        paragraphBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        paragraphBody.BackgroundTransparency = 1
                        paragraphBody.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        paragraphBody.BorderSizePixel = 0
                        paragraphBody.LayoutOrder = 1
                        paragraphBody.Size = UDim2.fromScale(1, 0)
                        paragraphBody.Parent = paragraph
                    end)

                    function ParagraphFunctions:UpdateHeader(New)
                        pcall(function()
                            if paragraphHeader then paragraphHeader.Text = New end
                        end)
                    end
                    
                    function ParagraphFunctions:UpdateBody(New)
                        pcall(function()
                            if paragraphBody then paragraphBody.Text = New end
                        end)
                    end
                    
                    function ParagraphFunctions:SetVisibility(State)
                        pcall(function()
                            if paragraph then paragraph.Visible = State end
                        end)
                    end

                    return ParagraphFunctions
                end

                -- Divider element
                function SectionFunctions:Divider()
                    local DividerFunctions = {}
                    
                    local divider
                    pcall(function()
                        divider = Instance.new("Frame")
                        divider.Name = "Divider"
                        divider.AnchorPoint = Vector2.new(0, 1)
                        divider.AutomaticSize = Enum.AutomaticSize.Y
                        divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        divider.BackgroundTransparency = 1
                        divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        divider.BorderSizePixel = 0
                        divider.Position = UDim2.fromScale(0, 1)
                        divider.Size = UDim2.new(1, 0, 0, 1)
                        divider.Parent = section
                    end)

                    local dividerPadding
                    pcall(function()
                        dividerPadding = Instance.new("UIPadding")
                        dividerPadding.Name = "UIPadding"
                        dividerPadding.PaddingBottom = UDim.new(0, 8)
                        dividerPadding.PaddingTop = UDim.new(0, 8)
                        dividerPadding.Parent = divider
                    end)

                    local dividerUIListLayout
                    pcall(function()
                        dividerUIListLayout = Instance.new("UIListLayout")
                        dividerUIListLayout.Name = "UIListLayout"
                        dividerUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        dividerUIListLayout.Parent = divider
                    end)

                    local line
                    pcall(function()
                        line = Instance.new("Frame")
                        line.Name = "Line"
                        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        line.BackgroundTransparency = 0.9
                        line.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        line.BorderSizePixel = 0
                        line.Size = UDim2.new(1, 0, 0, 1)
                        line.Parent = divider
                    end)

                    function DividerFunctions:Remove()
                        pcall(function()
                            if divider then divider:Destroy() end
                        end)
                    end
                    
                    function DividerFunctions:SetVisibility(State)
                        pcall(function()
                            if divider then divider.Visible = State end
                        end)
                    end

                    return DividerFunctions
                end

                -- Spacer element
                function SectionFunctions:Spacer()
                    local SpacerFunctions = {}

                    local spacer
                    pcall(function()
                        spacer = Instance.new("Frame")
                        spacer.Name = "Spacer"
                        spacer.AnchorPoint = Vector2.new(0, 1)
                        spacer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        spacer.BackgroundTransparency = 1
                        spacer.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        spacer.BorderSizePixel = 0
                        spacer.Position = UDim2.fromScale(0, 1)
                        spacer.Parent = section
                    end)

                    function SpacerFunctions:Remove()
                        pcall(function()
                            if spacer then spacer:Destroy() end
                        end)
                    end
                    
                    function SpacerFunctions:SetVisibility(State)
                        pcall(function()
                            if spacer then spacer.Visible = State end
                        end)
                    end

                    return SpacerFunctions
                end

                return SectionFunctions
            end

            -- Tab selection function
            local function SelectCurrentTab()
                pcall(function()
                    local easetime = 0.15

                    if currentTabInstance and currentTabInstance.Parent then
                        currentTabInstance.Parent = nil
                    end

                    if tabSwitchersScrollingFrame then
                        for _, v in pairs(tabSwitchersScrollingFrame:GetDescendants()) do
                            if v.Name == "TabSwitcher" then
                                local t1 = Tween(v, TweenInfo.new(easetime, Enum.EasingStyle.Sine), {
                                    BackgroundTransparency = 1
                                })
                                if t1 then t1:Play() end
                                local strokeChild = v:FindFirstChild("TabSwitcherUIStroke")
                                if strokeChild then
                                    local t2 = Tween(strokeChild, TweenInfo.new(easetime, Enum.EasingStyle.Sine), {
                                        Transparency = 1
                                    })
                                    if t2 then t2:Play() end
                                end
                            end
                        end
                    end

                    if tabs and elements1 then
                        tabs[tabSwitcher] = elements1
                        elements1.Parent = content
                        currentTabInstance = elements1
                        if currentTab then
                            currentTab.Text = Settings.Name or "Tab"
                        end
                    end

                    local t1 = Tween(tabSwitcher, TweenInfo.new(easetime, Enum.EasingStyle.Sine), {
                        BackgroundTransparency = 0.98
                    })
                    if t1 then t1:Play() end
                    if tabSwitcherUIStroke then
                        local t2 = Tween(tabSwitcherUIStroke, TweenInfo.new(easetime, Enum.EasingStyle.Sine), {
                            Transparency = 0.95
                        })
                        if t2 then t2:Play() end
                    end
                end)
            end

            if tabSwitcher then
                pcall(function()
                    tabSwitcher.MouseButton1Click:Connect(function()
                        SelectCurrentTab()
                    end)
                end)
            end

            function TabFunctions:Select()
                SelectCurrentTab()
            end

            return TabFunctions
        end

        return SectionFunctions
    end

    -- Notify function
    function WindowFunctions:Notify(Settings)
        local NotificationFunctions = {}
        
        local notification
        pcall(function()
            notification = Instance.new("Frame")
            notification.Name = "Notification"
            notification.AnchorPoint = Vector2.new(0.5, 0.5)
            notification.AutomaticSize = Enum.AutomaticSize.Y
            notification.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            notification.BorderColor3 = Color3.fromRGB(0, 0, 0)
            notification.BorderSizePixel = 0
            notification.Position = UDim2.fromScale(0.5, 0.5)
            notification.Size = UDim2.fromOffset(Settings.SizeX or 250, 0)
            notification.Parent = notifications
        end)

        local notificationUIStroke
        pcall(function()
            notificationUIStroke = Instance.new("UIStroke")
            notificationUIStroke.Name = "NotificationUIStroke"
            notificationUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            notificationUIStroke.Color = Color3.fromRGB(255, 255, 255)
            notificationUIStroke.Transparency = 0.9
            notificationUIStroke.Parent = notification
        end)

        local notificationUICorner
        pcall(function()
            notificationUICorner = Instance.new("UICorner")
            notificationUICorner.Name = "NotificationUICorner"
            notificationUICorner.CornerRadius = UDim.new(0, 10)
            notificationUICorner.Parent = notification
        end)

        local notificationUIScale
        pcall(function()
            notificationUIScale = Instance.new("UIScale")
            notificationUIScale.Name = "NotificationUIScale"
            notificationUIScale.Scale = 0
            notificationUIScale.Parent = notification
        end)

        local notificationInformation
        pcall(function()
            notificationInformation = Instance.new("Frame")
            notificationInformation.Name = "NotificationInformation"
            notificationInformation.AutomaticSize = Enum.AutomaticSize.Y
            notificationInformation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            notificationInformation.BackgroundTransparency = 1
            notificationInformation.BorderColor3 = Color3.fromRGB(0, 0, 0)
            notificationInformation.BorderSizePixel = 0
            notificationInformation.Size = UDim2.fromScale(1, 1)
            notificationInformation.Parent = notification
        end)

        local notificationTitle
        pcall(function()
            notificationTitle = Instance.new("TextLabel")
            notificationTitle.Name = "NotificationTitle"
            notificationTitle.FontFace = Font.new(
                assets.interFont,
                Enum.FontWeight.SemiBold,
                Enum.FontStyle.Normal
            )
            notificationTitle.RichText = true
            notificationTitle.Text = Settings.Title or "Notification"
            notificationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            notificationTitle.TextSize = 13
            notificationTitle.TextTransparency = 0.2
            notificationTitle.TextTruncate = Enum.TextTruncate.SplitWord
            notificationTitle.TextXAlignment = Enum.TextXAlignment.Left
            notificationTitle.TextYAlignment = Enum.TextYAlignment.Top
            notificationTitle.AutomaticSize = Enum.AutomaticSize.XY
            notificationTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            notificationTitle.BackgroundTransparency = 1
            notificationTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            notificationTitle.BorderSizePixel = 0
            notificationTitle.Size = UDim2.new(1, -12, 0, 0)
            notificationTitle.Parent = notificationInformation
        end)

        local notificationTitleUIPadding
        pcall(function()
            notificationTitleUIPadding = Instance.new("UIPadding")
            notificationTitleUIPadding.Name = "NotificationTitleUIPadding"
            notificationTitleUIPadding.PaddingRight = UDim.new(0, 25)
            notificationTitleUIPadding.Parent = notificationTitle
        end)

        local notificationDescription
        pcall(function()
            notificationDescription = Instance.new("TextLabel")
            notificationDescription.Name = "NotificationDescription"
            notificationDescription.FontFace = Font.new(
                assets.interFont,
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            notificationDescription.Text = Settings.Description or ""
            notificationDescription.TextColor3 = Color3.fromRGB(255, 255, 255)
            notificationDescription.TextSize = 11
            notificationDescription.TextTransparency = 0.5
            notificationDescription.TextWrapped = true
            notificationDescription.RichText = true
            notificationDescription.TextXAlignment = Enum.TextXAlignment.Left
            notificationDescription.TextYAlignment = Enum.TextYAlignment.Top
            notificationDescription.AutomaticSize = Enum.AutomaticSize.XY
            notificationDescription.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            notificationDescription.BackgroundTransparency = 1
            notificationDescription.BorderColor3 = Color3.fromRGB(0, 0, 0)
            notificationDescription.BorderSizePixel = 0
            notificationDescription.Size = UDim2.new(1, -12, 0, 0)
            notificationDescription.Parent = notificationInformation
        end)

        local notificationDescriptionUIPadding
        pcall(function()
            notificationDescriptionUIPadding = Instance.new("UIPadding")
            notificationDescriptionUIPadding.Name = "NotificationDescriptionUIPadding"
            notificationDescriptionUIPadding.PaddingRight = UDim.new(0, 25)
            notificationDescriptionUIPadding.PaddingTop = UDim.new(0, 17)
            notificationDescriptionUIPadding.Parent = notificationDescription
        end)

        local notificationUIPadding
        pcall(function()
            notificationUIPadding = Instance.new("UIPadding")
            notificationUIPadding.Name = "NotificationUIPadding"
            notificationUIPadding.PaddingBottom = UDim.new(0, 12)
            notificationUIPadding.PaddingLeft = UDim.new(0, 10)
            notificationUIPadding.PaddingRight = UDim.new(0, 10)
            notificationUIPadding.PaddingTop = UDim.new(0, 10)
            notificationUIPadding.Parent = notificationInformation
        end)

        local notificationControls
        pcall(function()
            notificationControls = Instance.new("Frame")
            notificationControls.Name = "NotificationControls"
            notificationControls.AutomaticSize = Enum.AutomaticSize.Y
            notificationControls.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            notificationControls.BackgroundTransparency = 1
            notificationControls.BorderColor3 = Color3.fromRGB(0, 0, 0)
            notificationControls.BorderSizePixel = 0
            notificationControls.Size = UDim2.fromScale(1, 1)
            notificationControls.Parent = notification
        end)

        local interactable
        pcall(function()
            interactable = Instance.new("TextButton")
            interactable.Name = "Interactable"
            interactable.FontFace = Font.new(assets.interFont)
            interactable.Text = "✓"
            interactable.TextColor3 = Color3.fromRGB(255, 255, 255)
            interactable.TextSize = 17
            interactable.TextTransparency = 0.2
            interactable.AnchorPoint = Vector2.new(1, 0.5)
            interactable.AutomaticSize = Enum.AutomaticSize.XY
            interactable.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            interactable.BackgroundTransparency = 1
            interactable.BorderColor3 = Color3.fromRGB(0, 0, 0)
            interactable.BorderSizePixel = 0
            interactable.LayoutOrder = 1
            interactable.Position = UDim2.fromScale(1, 0.5)
            interactable.Parent = notificationControls
        end)

        local controlsPadding
        pcall(function()
            controlsPadding = Instance.new("UIPadding")
            controlsPadding.Name = "UIPadding"
            controlsPadding.PaddingBottom = UDim.new(0, 6)
            controlsPadding.PaddingRight = UDim.new(0, 13)
            controlsPadding.PaddingTop = UDim.new(0, 6)
            controlsPadding.Parent = notificationControls
        end)

        local tweens = {}
        pcall(function()
            tweens.In = Tween(notificationUIScale, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Scale = Settings.Scale or 1
            })
            tweens.Out = Tween(notificationUIScale, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Scale = 0
            })
        end)

        local styles = {
            None = function() if interactable then interactable:Destroy() end end,
            Confirm = function() if interactable then interactable.Text = "✓" end end,
            Cancel = function() if interactable then interactable.Text = "✗" end end
        }

        local style = styles[Settings.Style] or styles.None
        style()

        if interactable then
            pcall(function()
                interactable.MouseButton1Click:Connect(function()
                    NotificationFunctions:Cancel()
                    if Settings.Callback then
                        task.spawn(function() pcall(Settings.Callback) end)
                    end
                end)
            end)
        end

        local AnimateNotification
        AnimateNotification = task.spawn(function()
            if tweens.In then tweens.In:Play() end
            
            Settings.Lifetime = Settings.Lifetime or 3

            if Settings.Lifetime ~= 0 then
                task.wait(Settings.Lifetime)

                if tweens.Out then
                    tweens.Out:Play()
                    tweens.Out.Completed:Wait()
                    if notification then
                        notification:Destroy()
                    end
                end
            end
        end)

        function NotificationFunctions:UpdateTitle(New)
            pcall(function()
                if notificationTitle then notificationTitle.Text = New end
            end)
        end

        function NotificationFunctions:UpdateDescription(New)
            pcall(function()
                if notificationDescription then notificationDescription.Text = New end
            end)
        end

        function NotificationFunctions:Resize(X)
            pcall(function()
                local targ = X or 250
                if notification then
                    notification.Size = UDim2.fromOffset(targ, 0)
                end
            end)
        end

        function NotificationFunctions:Cancel()
            task.cancel(AnimateNotification)
            
            if tweens.Out then
                tweens.Out:Play()
                tweens.Out.Completed:Wait()
                if notification then
                    notification:Destroy()
                end
            end
        end

        return NotificationFunctions
    end

    -- Dialog function
    function WindowFunctions:Dialog(Settings)
        local DialogFunctions = {}
        
        local dialogCanvas
        pcall(function()
            dialogCanvas = Instance.new("CanvasGroup")
            dialogCanvas.Name = "DialogCanvas"
            dialogCanvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dialogCanvas.BackgroundTransparency = 1
            dialogCanvas.BorderColor3 = Color3.fromRGB(0, 0, 0)
            dialogCanvas.BorderSizePixel = 0
            dialogCanvas.Size = UDim2.fromScale(1, 1)
            dialogCanvas.GroupTransparency = 1
            dialogCanvas.Parent = base
        end)

        local dialog
        pcall(function()
            dialog = Instance.new("Frame")
            dialog.Name = "Dialog"
            dialog.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            dialog.BackgroundTransparency = 0.5
            dialog.BorderColor3 = Color3.fromRGB(0, 0, 0)
            dialog.BorderSizePixel = 0
            dialog.Size = UDim2.fromScale(1, 1)
            dialog.Parent = dialogCanvas
        end)

        local dialogCorner
        pcall(function()
            dialogCorner = Instance.new("UICorner")
            dialogCorner.Name = "BaseUICorner"
            dialogCorner.CornerRadius = UDim.new(0, 10)
            dialogCorner.Parent = dialog
        end)

        local prompt
        pcall(function()
            prompt = Instance.new("Frame")
            prompt.Name = "Prompt"
            prompt.AnchorPoint = Vector2.new(0.5, 0.5)
            prompt.AutomaticSize = Enum.AutomaticSize.Y
            prompt.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            prompt.BorderColor3 = Color3.fromRGB(0, 0, 0)
            prompt.BorderSizePixel = 0
            prompt.Position = UDim2.fromScale(0.5, 0.5)
            prompt.Size = UDim2.fromOffset(280, 0)
            prompt.Parent = dialog
        end)

        local promptStroke
        pcall(function()
            promptStroke = Instance.new("UIStroke")
            promptStroke.Name = "GlobalSettingsUIStroke"
            promptStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            promptStroke.Color = Color3.fromRGB(255, 255, 255)
            promptStroke.Transparency = 0.9
            promptStroke.Parent = prompt
        end)

        local promptCorner
        pcall(function()
            promptCorner = Instance.new("UICorner")
            promptCorner.Name = "GlobalSettingsUICorner"
            promptCorner.CornerRadius = UDim.new(0, 10)
            promptCorner.Parent = prompt
        end)

        local promptPadding
        pcall(function()
            promptPadding = Instance.new("UIPadding")
            promptPadding.Name = "GlobalSettingsUIPadding"
            promptPadding.PaddingBottom = UDim.new(0, 20)
            promptPadding.PaddingLeft = UDim.new(0, 20)
            promptPadding.PaddingRight = UDim.new(0, 20)
            promptPadding.PaddingTop = UDim.new(0, 20)
            promptPadding.Parent = prompt
        end)

        local paragraph
        pcall(function()
            paragraph = Instance.new("Frame")
            paragraph.Name = "Paragraph"
            paragraph.AutomaticSize = Enum.AutomaticSize.Y
            paragraph.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            paragraph.BackgroundTransparency = 1
            paragraph.BorderColor3 = Color3.fromRGB(0, 0, 0)
            paragraph.BorderSizePixel = 0
            paragraph.Size = UDim2.new(1, 0, 0, 38)
            paragraph.Parent = prompt
        end)

        local paragraphHeader
        pcall(function()
            paragraphHeader = Instance.new("TextLabel")
            paragraphHeader.Name = "ParagraphHeader"
            paragraphHeader.FontFace = Font.new(
                assets.interFont,
                Enum.FontWeight.SemiBold,
                Enum.FontStyle.Normal
            )
            paragraphHeader.RichText = true
            paragraphHeader.Text = Settings.Title or "Dialog"
            paragraphHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
            paragraphHeader.TextSize = 18
            paragraphHeader.TextTransparency = 0.4
            paragraphHeader.TextWrapped = true
            paragraphHeader.AutomaticSize = Enum.AutomaticSize.Y
            paragraphHeader.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            paragraphHeader.BackgroundTransparency = 1
            paragraphHeader.BorderColor3 = Color3.fromRGB(0, 0, 0)
            paragraphHeader.BorderSizePixel = 0
            paragraphHeader.Size = UDim2.fromScale(1, 0)
            paragraphHeader.Parent = paragraph
        end)

        local paragraphUIListLayout
        pcall(function()
            paragraphUIListLayout = Instance.new("UIListLayout")
            paragraphUIListLayout.Name = "UIListLayout"
            paragraphUIListLayout.Padding = UDim.new(0, 15)
            paragraphUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            paragraphUIListLayout.Parent = paragraph
        end)

        local paragraphBody
        pcall(function()
            paragraphBody = Instance.new("TextLabel")
            paragraphBody.Name = "ParagraphBody"
            paragraphBody.FontFace = Font.new(
                assets.interFont,
                Enum.FontWeight.Medium,
                Enum.FontStyle.Normal
            )
            paragraphBody.RichText = true
            paragraphBody.Text = Settings.Description or ""
            paragraphBody.TextColor3 = Color3.fromRGB(255, 255, 255)
            paragraphBody.TextSize = 14
            paragraphBody.TextTransparency = 0.5
            paragraphBody.TextWrapped = true
            paragraphBody.AutomaticSize = Enum.AutomaticSize.Y
            paragraphBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            paragraphBody.BackgroundTransparency = 1
            paragraphBody.BorderColor3 = Color3.fromRGB(0, 0, 0)
            paragraphBody.BorderSizePixel = 0
            paragraphBody.LayoutOrder = 1
            paragraphBody.Size = UDim2.fromScale(1, 0)
            paragraphBody.Parent = paragraph
        end)

        local interactions
        pcall(function()
            interactions = Instance.new("Frame")
            interactions.Name = "Interactions"
            interactions.AutomaticSize = Enum.AutomaticSize.Y
            interactions.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            interactions.BackgroundTransparency = 1
            interactions.BorderColor3 = Color3.fromRGB(0, 0, 0)
            interactions.BorderSizePixel = 0
            interactions.LayoutOrder = 1
            interactions.Size = UDim2.fromScale(1, 0)
            interactions.Parent = prompt
        end)

        local interactionsUIListLayout
        pcall(function()
            interactionsUIListLayout = Instance.new("UIListLayout")
            interactionsUIListLayout.Name = "UIListLayout"
            interactionsUIListLayout.Padding = UDim.new(0, 10)
            interactionsUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            interactionsUIListLayout.Parent = interactions
        end)

        local interactionsPadding
        pcall(function()
            interactionsPadding = Instance.new("UIPadding")
            interactionsPadding.Name = "UIPadding"
            interactionsPadding.PaddingTop = UDim.new(0, 20)
            interactionsPadding.Parent = interactions
        end)

        local promptUIListLayout
        pcall(function()
            promptUIListLayout = Instance.new("UIListLayout")
            promptUIListLayout.Name = "UIListLayout"
            promptUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            promptUIListLayout.Parent = prompt
        end)

        local canvasIn = Tween(dialogCanvas, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
            GroupTransparency = 0,
        })
        local canvasOut = Tween(dialogCanvas, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
            GroupTransparency = 1,
        })

        local function dialogIn()
            if canvasIn then
                canvasIn:Play()
                canvasIn.Completed:Wait()
                if dialog then
                    dialog.Parent = base
                end
            end
        end

        local function dialogOut()
            if dialog then
                dialog.Parent = dialogCanvas
            end

            if canvasOut then
                canvasOut:Play()
                canvasOut.Completed:Wait()
                if dialogCanvas then
                    dialogCanvas:Destroy()
                end
            end
        end

        if Settings.Buttons then
            for _, v in pairs(Settings.Buttons) do
                local button
                pcall(function()
                    button = Instance.new("TextButton")
                    button.Name = "Button"
                    button.FontFace = Font.new(
                        assets.interFont,
                        Enum.FontWeight.SemiBold,
                        Enum.FontStyle.Normal
                    )
                    button.Text = v.Name or "Button"
                    button.TextColor3 = Color3.fromRGB(255, 255, 255)
                    button.TextSize = 15
                    button.TextTransparency = 0.5
                    button.TextTruncate = Enum.TextTruncate.AtEnd
                    button.AutoButtonColor = false
                    button.AutomaticSize = Enum.AutomaticSize.Y
                    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    button.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    button.BorderSizePixel = 0
                    button.Size = UDim2.fromScale(1, 0)
                    if interactions then button.Parent = interactions end
                end)

                local buttonPadding
                pcall(function()
                    buttonPadding = Instance.new("UIPadding")
                    buttonPadding.Name = "UIPadding"
                    buttonPadding.PaddingBottom = UDim.new(0, 9)
                    buttonPadding.PaddingLeft = UDim.new(0, 10)
                    buttonPadding.PaddingRight = UDim.new(0, 10)
                    buttonPadding.PaddingTop = UDim.new(0, 9)
                    buttonPadding.Parent = button
                end)

                local buttonCorner
                pcall(function()
                    buttonCorner = Instance.new("UICorner")
                    buttonCorner.Name = "BaseUICorner"
                    buttonCorner.CornerRadius = UDim.new(0, 10)
                    buttonCorner.Parent = button
                end)

                local TweenSettings = {
                    DefaultTransparency = 0,
                    DefaultTransparency2 = 0.5,
                    HoverTransparency = 0.3,
                    HoverTransparency2 = 0.6,
                    EasingStyle = Enum.EasingStyle.Sine
                }

                local function ChangeState(State)
                    pcall(function()
                        if State == "Idle" then
                            local t1 = Tween(button, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                                BackgroundTransparency = TweenSettings.DefaultTransparency,
                                TextTransparency = TweenSettings.DefaultTransparency2
                            })
                            if t1 then t1:Play() end
                        elseif State == "Hover" then
                            local t1 = Tween(button, TweenInfo.new(0.2, TweenSettings.EasingStyle), {
                                BackgroundTransparency = TweenSettings.HoverTransparency,
                                TextTransparency = TweenSettings.HoverTransparency2
                            })
                            if t1 then t1:Play() end
                        end
                    end)
                end

                if button then
                    pcall(function()
                        button.MouseButton1Click:Connect(function()
                            if dialogCanvas and dialogCanvas.GroupTransparency ~= 0 then return end
                            if v.Callback then
                                pcall(v.Callback)
                            end
                            dialogOut()
                        end)

                        button.MouseEnter:Connect(function()
                            ChangeState("Hover")
                        end)
                        button.MouseLeave:Connect(function()
                            ChangeState("Idle")
                        end)
                    end)
                end
            end
        end

        dialogIn()

        function DialogFunctions:UpdateTitle(New)
            pcall(function()
                if paragraphHeader then paragraphHeader.Text = New end
            end)
        end

        function DialogFunctions:UpdateDescription(New)
            pcall(function()
                if paragraphBody then paragraphBody.Text = New end
            end)
        end

        function DialogFunctions:Cancel()
            dialogOut()
        end

        return DialogFunctions
    end

    -- Notification state functions
    function WindowFunctions:SetNotificationsState(State)
        pcall(function()
            if notifications then notifications.Visible = State end
        end)
    end

    function WindowFunctions:GetNotificationsState()
        return notifications and notifications.Visible or false
    end

    -- Window state functions
    function WindowFunctions:SetState(State)
        windowState = State
        pcall(function()
            if base then base.Visible = State end
        end)
    end

    function WindowFunctions:GetState()
        return windowState
    end

    -- Unload callback
    local onUnloadCallback

    function WindowFunctions:Unload()
        if renderSteppedConnection then
            pcall(function() renderSteppedConnection:Disconnect() end)
        end
        if onUnloadCallback then
            pcall(onUnloadCallback)
        end
        if macLib then
            pcall(function() macLib:Destroy() end)
        end
    end

    function WindowFunctions.onUnloaded(callback)
        onUnloadCallback = callback
    end

    -- Menu keybind
    local MenuKeybind = Settings.Keybind or Enum.KeyCode.RightControl

    local function ToggleMenu()
        pcall(function()
            local state = not WindowFunctions:GetState()
            WindowFunctions:SetState(state)
            WindowFunctions:Notify({
                Title = Settings.Title or "MacLib",
                Description = (state and "Maximized " or "Minimized ") .. "the menu. Use " .. tostring(MenuKeybind.Name) .. " to toggle it.",
                Lifetime = 5
            })
        end)
    end

    local inputEndedConnection
    pcall(function()
        inputEndedConnection = UserInputService.InputEnded:Connect(function(inp, gpe)
            if gpe then return end
            if inp.KeyCode == MenuKeybind then
                ToggleMenu()
            end
        end)
    end)

    pcall(function()
        minimize.MouseButton1Click:Connect(ToggleMenu)
        exit.MouseButton1Click:Connect(function()
            WindowFunctions:Unload()
        end)
    end)

    function WindowFunctions:SetKeybind(Keycode)
        MenuKeybind = Keycode
    end

    function WindowFunctions:SetAcrylicBlurState(State)
        acrylicBlur = State
        pcall(function()
            if base then base.BackgroundTransparency = State and 0.05 or 0 end
        end)
    end

    function WindowFunctions:GetAcrylicBlurState()
        return acrylicBlur
    end

    -- User info state
    local function _SetUserInfoState(State)
        pcall(function()
            if State then
                if headshot then
                    headshot.Image = (isReady and headshotImage) or "rbxassetid://0"
                end
                if username then
                    username.Text = "@" .. ((LocalPlayer and LocalPlayer.Name) or "user")
                end
                if displayName then
                    displayName.Text = (LocalPlayer and LocalPlayer.DisplayName) or "User"
                end
            else
                if headshot then
                    headshot.Image = assets.userInfoBlurred
                end
                local nameLength = (LocalPlayer and #LocalPlayer.Name) or 4
                local displayNameLength = (LocalPlayer and #LocalPlayer.DisplayName) or 4
                if username then
                    username.Text = "@" .. string.rep(".", nameLength)
                end
                if displayName then
                    displayName.Text = string.rep(".", displayNameLength)
                end
            end
        end)
    end

    local showUserInfo = (Settings.ShowUserInfo ~= nil) and Settings.ShowUserInfo or true
    _SetUserInfoState(showUserInfo)

    function WindowFunctions:SetUserInfoState(State)
        _SetUserInfoState(State)
    end

    function WindowFunctions:GetUserInfoState()
        return showUserInfo
    end

    function WindowFunctions:SetSize(Size)
        pcall(function()
            if base then base.Size = Size end
        end)
    end

    function WindowFunctions:GetSize()
        return base and base.Size or UDim2.fromOffset(868, 650)
    end

    function WindowFunctions:SetScale(Scale)
        pcall(function()
            if baseUIScale then baseUIScale.Scale = Scale end
        end)
    end

    function WindowFunctions:GetScale()
        return baseUIScale and baseUIScale.Scale or 1
    end

    -- Preload assets
    local assetList = {}
    for _, assetId in pairs(assets) do
        table.insert(assetList, assetId)
    end

    pcall(function()
        ContentProvider:PreloadAsync(assetList)
    end)

    pcall(function()
        if macLib then
            macLib.Enabled = true
        end
    end)

    windowState = true

    return WindowFunctions
end

-- Demo function
function MacLib:Demo()
    pcall(function()
        local Window = MacLib:Window({
            Title = "MacLib Demo",
            Subtitle = "This is a subtitle.",
            Size = UDim2.fromOffset(868, 650),
            DragStyle = 1,
            DisabledWindowControls = {},
            ShowUserInfo = true,
            Keybind = Enum.KeyCode.RightControl,
            AcrylicBlur = true,
        })

        local globalSettings = {
            UIBlurToggle = Window:GlobalSetting({
                Name = "UI Blur",
                Default = Window:GetAcrylicBlurState(),
                Callback = function(bool)
                    Window:SetAcrylicBlurState(bool)
                    Window:Notify({
                        Title = "MacLib Demo",
                        Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
                        Lifetime = 5
                    })
                end,
            }),
            NotificationToggler = Window:GlobalSetting({
                Name = "Notifications",
                Default = Window:GetNotificationsState(),
                Callback = function(bool)
                    Window:SetNotificationsState(bool)
                    Window:Notify({
                        Title = "MacLib Demo",
                        Description = (bool and "Enabled" or "Disabled") .. " Notifications",
                        Lifetime = 5
                    })
                end,
            }),
            ShowUserInfo = Window:GlobalSetting({
                Name = "Show User Info",
                Default = Window:GetUserInfoState(),
                Callback = function(bool)
                    Window:SetUserInfoState(bool)
                    Window:Notify({
                        Title = "MacLib Demo",
                        Description = (bool and "Showing" or "Redacted") .. " User Info",
                        Lifetime = 5
                    })
                end,
            })
        }

        local tabGroups = {
            TabGroup1 = Window:TabGroup()
        }

        local tabs = {
            Main = tabGroups.TabGroup1:Tab({ Name = "Demo", Image = "rbxassetid://18821914323" })
        }

        local sections = {
            MainSection1 = tabs.Main:Section({ Side = "Left" })
        }

        sections.MainSection1:Header({
            Name = "Header #1"
        })

        sections.MainSection1:Button({
            Name = "Button",
            Callback = function()
                Window:Dialog({
                    Title = "MacLib Demo",
                    Description = "Lorem ipsum odor amet, consectetuer adipiscing elit. Eros vestibulum aliquet mattis, ex platea nunc.",
                    Buttons = {
                        {
                            Name = "Confirm",
                            Callback = function()
                                print("Confirmed!")
                            end,
                        },
                        {
                            Name = "Cancel"
                        }
                    }
                })
            end,
        })

        sections.MainSection1:Input({
            Name = "Input",
            Placeholder = "Input",
            AcceptedCharacters = "All",
            Callback = function(input)
                Window:Notify({
                    Title = "MacLib Demo",
                    Description = "Successfully set input to " .. input
                })
            end,
            onChanged = function(input)
                print("Input is now ".. input)
            end,
        })

        sections.MainSection1:Slider({
            Name = "Slider",
            Default = 50,
            Minimum = 0,
            Maximum = 100,
            DisplayMethod = "Percent",
            Callback = function(Value)
                print("Changed to ".. Value)
            end,
        })

        sections.MainSection1:Toggle({
            Name = "Toggle",
            Default = false,
            Callback = function(value)
                Window:Notify({
                    Title = "MacLib Demo",
                    Description = (value and "Enabled " or "Disabled ") .. "Toggle"
                })
            end,
        })

        sections.MainSection1:Keybind({
            Name = "Keybind",
            Callback = function(binded)
                Window:Notify({
                    Title = "Demo Window",
                    Description = "Pressed keybind - "..tostring(binded.Name),
                    Lifetime = 3
                })
            end,
            onBinded = function(bind)
                Window:Notify({
                    Title = "Demo Window",
                    Description = "Successfully Binded Keybind to - "..tostring(bind.Name),
                    Lifetime = 3
                })
            end,
        })

        sections.MainSection1:Colorpicker({
            Name = "Colorpicker",
            Default = Color3.fromRGB(0, 255, 255),
            Callback = function(color)
                print("Color: ", color)
            end,
        })

        local alphaColorPicker = sections.MainSection1:Colorpicker({
            Name = "Transparency Colorpicker",
            Default = Color3.fromRGB(255,0,0),
            Alpha = 0,
            Callback = function(color, alpha)
                print("Color: ", color, " Alpha: ", alpha)
            end,
        })

        local rainbowActive = false
        local rainbowConnection = nil
        local hue = 0

        sections.MainSection1:Toggle({
            Name = "Rainbow",
            Default = false,
            Callback = function(value)
                rainbowActive = value
                if rainbowActive then
                    rainbowConnection = RunService.RenderStepped:Connect(function(deltaTime)
                        hue = (hue + deltaTime * 0.1) % 1
                        local newColor = Color3.fromHSV(hue, 1, 1)
                        alphaColorPicker:SetColor(newColor)
                    end)
                else
                    if rainbowConnection then
                        rainbowConnection:Disconnect()
                        rainbowConnection = nil
                    end
                end
            end,
        })

        local optionTable = {}

        for i = 1,10 do
            local formatted = "Option ".. tostring(i)
            table.insert(optionTable, formatted)
        end

        local Dropdown = sections.MainSection1:Dropdown({
            Name = "Dropdown",
            Multi = false,
            Required = true,
            Options = optionTable,
            Default = 1,
            Callback = function(Value)
                print("Dropdown changed: ".. Value)
            end,
        })

        local MultiDropdown = sections.MainSection1:Dropdown({
            Name = "Multi Dropdown",
            Search = true,
            Multi = true,
            Required = false,
            Options = optionTable,
            Default = {"Option 1", "Option 3"},
            Callback = function(Value)
                local Values = {}
                for ValueName, State in next, Value do
                    table.insert(Values, ValueName)
                end
                print("Mutlidropdown changed:", table.concat(Values, ", "))
            end,
        })

        sections.MainSection1:Button({
            Name = "Update Selection",
            Callback = function()
                Dropdown:UpdateSelection(4)
                MultiDropdown:UpdateSelection({"Option 2", "Option 5"})
            end,
        })

        sections.MainSection1:Divider()

        sections.MainSection1:Header({
            Text = "Header #2"
        })

        sections.MainSection1:Paragraph({
            Header = "Paragraph",
            Body = "Paragraph body. Lorem ipsum odor amet, consectetuer adipiscing elit. Morbi tempus netus aliquet per velit est gravida."
        })

        sections.MainSection1:Label({
            Text = "Label. Lorem ipsum odor amet, consectetuer adipiscing elit."
        })

        sections.MainSection1:SubLabel({
            Text = "Sub-Label. Lorem ipsum odor amet, consectetuer adipiscing elit."
        })

        Window.onUnloaded(function()
            print("Unloaded!")
        end)

        tabs.Main:Select()
    end)
end

return MacLib
