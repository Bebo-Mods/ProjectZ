--[[
╔══════════════════════════════════════════════════════════════════╗
║              PROJECT  Z  ·  v4.0  ·  PRESTIGE EDITION           ║
║         Multi-Column FPS Cheat UI  ·  Roblox Exploit            ║
╚══════════════════════════════════════════════════════════════════╝

  Inspired by Hyperion / Semirage layout — dense, column-based,
  dark purple prestige aesthetic with sharp contrast.

  USAGE:
    local PZ = loadstring(game:HttpGet("RAW_URL"))()

    PZ:Boot({
        Title   = "Project Z",
        Version = "v4.0",
        Game    = "Phantom Forces",
    })

    -- Tabs appear as top nav pills (like Hyperion)
    local AimTab  = PZ:AddTab("Aimbot")
    local VisTab  = PZ:AddTab("Visuals")
    local MiscTab = PZ:AddTab("Misc")
    -- Configs + Settings added automatically

    -- Each tab supports up to 3 columns
    local Left  = AimTab:Col(1)
    local Mid   = AimTab:Col(2)
    local Right = AimTab:Col(3)

    Left:Section("Weapon Selection")
    Left:Dropdown({ Name = "Weapon", Options = {"All","Pistols","Rifles","Snipers"} })
    Left:Dropdown({ Name = "Preset", Options = {"Default","Rage","Legit"} })

    Left:Section("Aimbot")
    Left:Toggle({ Name = "Active",       Default = false, Keybind = Enum.KeyCode.F })
    Left:Toggle({ Name = "Aim Lock",     Default = false })
    Left:Toggle({ Name = "Triggerbot",   Default = false })
    Left:Dropdown({ Name = "Target",     Options = {"Head","Neck","Chest","Nearest"} })
    Left:Slider({ Name = "FOV",          Min=1, Max=360, Default=90, Suffix="°" })
    Left:Slider({ Name = "Smoothing",    Min=1, Max=100, Default=30, Suffix="%" })
    Left:Slider({ Name = "Confidence",   Min=0, Max=100, Default=80, Suffix="%" })

    Mid:Section("RCS")
    Mid:Slider({ Name = "X Strength",   Min=0, Max=100, Default=50 })
    Mid:Slider({ Name = "Y Strength",   Min=0, Max=100, Default=50 })
    Mid:Slider({ Name = "Smoothing",    Min=1, Max=20,  Default=5  })
    Mid:Toggle({ Name = "Standalone",   Default = false })

    Mid:Section("Triggerbot")
    Mid:Toggle({ Name = "Active",        Default = false })
    Mid:Dropdown({ Name = "Hitbox",      Options = {"Head","Body","All"} })
    Mid:Slider({ Name = "Delay ms",     Min=0, Max=500, Default=80 })
    Mid:Toggle({ Name = "Aim Stop",      Default = true })

    Right:Section("A User's Online")
    Right:Label("Connected to session")
    Right:Separator()
    Right:Label("FPS:  60  |  Ping: 24ms")
    Right:Label("Hits: 0  |  Misses: 0")
]]

-- ══════════════════════════════════════════════════════
--  BOOT / SAFE ENV
-- ══════════════════════════════════════════════════════
local _pcall = pcall

local function Safe(fn, ...)
    local ok, e = _pcall(fn, ...)
    if not ok then
        -- warn("[PZ] " .. tostring(e))
    end
    return ok, e
end

local function Svc(n)
    local ok, s = _pcall(function() return game:GetService(n) end)
    if not ok then return nil end
    if cloneref then
        local ok2, r = _pcall(cloneref, s)
        if ok2 then return r end
    end
    return s
end

local Players = Svc("Players")
local UIS     = Svc("UserInputService")
local TS      = Svc("TweenService")
local RS      = Svc("RunService")
local LP      = Players and Players.LocalPlayer
local Mouse   = LP and LP:GetMouse()

local function GuiRoot()
    if gethui then local ok,h=_pcall(gethui) if ok and h then return h end end
    if cloneref then
        local ok,cg=_pcall(function() return cloneref(game:GetService("CoreGui")) end)
        if ok and cg then return cg end
    end
    local ok,cg=_pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LP and LP:FindFirstChildOfClass("PlayerGui")
end

-- ══════════════════════════════════════════════════════
--  THEME  — Dark Purple Prestige (Hyperion style)
-- ══════════════════════════════════════════════════════
local C = {
    -- Window chrome
    WinBg       = Color3.fromRGB(18,  16,  26),   -- very dark purple-black
    TopBg       = Color3.fromRGB(22,  19,  32),
    SideBg      = Color3.fromRGB(20,  18,  28),
    TabBar      = Color3.fromRGB(14,  12,  22),

    -- Content
    ColBg       = Color3.fromRGB(24,  21,  34),
    SecHeader   = Color3.fromRGB(30,  26,  44),
    El          = Color3.fromRGB(28,  24,  40),
    ElHov       = Color3.fromRGB(38,  33,  55),

    -- Accents — dual tone: purple primary, cyan secondary
    Pur         = Color3.fromRGB(138,  90, 235),  -- vivid purple
    PurDim      = Color3.fromRGB( 60,  40, 110),
    PurGlow     = Color3.fromRGB( 35,  20,  70),
    Cyan        = Color3.fromRGB( 80, 200, 255),
    CyanDim     = Color3.fromRGB( 20,  70, 110),
    Green       = Color3.fromRGB( 80, 220, 130),
    Red         = Color3.fromRGB(230,  70,  70),
    Amber       = Color3.fromRGB(255, 185,  40),
    AmberDim    = Color3.fromRGB( 90,  62,  10),

    -- Text
    TxtHi       = Color3.fromRGB(225, 220, 240),
    TxtMid      = Color3.fromRGB(155, 145, 175),
    TxtLo       = Color3.fromRGB( 80,  72, 105),
    TxtPur      = Color3.fromRGB(175, 145, 255),
    TxtCyan     = Color3.fromRGB( 80, 200, 255),

    -- Border
    Bdr         = Color3.fromRGB( 50,  44,  72),
    BdrPur      = Color3.fromRGB(100,  70, 180),

    -- Toggle
    TogOn       = Color3.fromRGB(110,  60, 220),
    TogOff      = Color3.fromRGB( 42,  38,  62),
    Knob        = Color3.fromRGB(240, 235, 255),

    -- Slider
    Track       = Color3.fromRGB( 32,  28,  48),
    Fill        = Color3.fromRGB(110,  60, 220),
}

-- ══════════════════════════════════════════════════════
--  UTILITY
-- ══════════════════════════════════════════════════════
local function tw(o, p, t, s, d)
    if not (o and p) then return end
    Safe(function()
        TS:Create(o, TweenInfo.new(
            t or 0.16,
            s or Enum.EasingStyle.Quart,
            d or Enum.EasingDirection.Out
        ), p):Play()
    end)
end

local function N(cls, props, par)
    local inst
    Safe(function()
        inst = Instance.new(cls)
        for k,v in pairs(props or {}) do Safe(function() inst[k]=v end) end
        if par then inst.Parent = par end
    end)
    return inst
end

local function Conn(sig, fn)
    if not (sig and fn) then return end
    local ok,c = _pcall(function() return sig:Connect(fn) end)
    return ok and c or nil
end

local function Cr(r, p) return N("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function Sk(col,th,tr,p) return N("UIStroke",{Color=col,Thickness=th or 1,Transparency=tr or 0},p) end
local function Pd(l,r,t,b,p) return N("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0)},p) end
local function LL(gap,p) return N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,gap or 0)},p) end
local function GL(gap,p)
    local g = N("UIGridLayout",{SortOrder=Enum.SortOrder.LayoutOrder,CellPadding=UDim2.new(0,gap or 4,0,gap or 4)},p)
    return g
end

local function Drag(frame, handle)
    if not (frame and handle) then return end
    local drg,ds,sp = false,nil,nil
    Conn(handle.InputBegan,function(i)
        Safe(function()
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drg=true;ds=i.Position;sp=frame.Position end
        end)
    end)
    Conn(handle.InputEnded,function(i)
        Safe(function()
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drg=false end
        end)
    end)
    Conn(UIS.InputChanged,function(i)
        Safe(function()
            if drg and i.UserInputType==Enum.UserInputType.MouseMovement then
                local d=i.Position-ds
                frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
            end
        end)
    end)
end

-- ══════════════════════════════════════════════════════
--  LIBRARY
-- ══════════════════════════════════════════════════════
local PZ = {}
PZ.__index = PZ
PZ._tabs      = {}
PZ._tabPages  = {}
PZ._tabBtns   = {}
PZ._activeTab = nil
PZ._configs   = {}
PZ._SG        = nil
PZ._MF        = nil

-- ══════════════════════════════════════════════════════
--  LOADER  — cinematic fullscreen
-- ══════════════════════════════════════════════════════
function PZ:Boot(cfg)
    cfg = cfg or {}
    local title   = cfg.Title   or "PROJECT Z"
    local ver     = cfg.Version or "v4.0"
    local gameName= cfg.Game    or "FPS HUB"

    Safe(function()
        local LG = N("ScreenGui",{
            Name="PZ_Loader", ResetOnSpawn=false,
            ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
            DisplayOrder=9999, IgnoreGuiInset=true,
        }, GuiRoot())

        -- Full void BG
        local BG = N("Frame",{
            Size=UDim2.new(1,0,1,0),
            BackgroundColor3=Color3.fromRGB(10,8,18),
            BorderSizePixel=0, ZIndex=1,
        }, LG)

        -- Grid overlay (subtle)
        for i=1,10 do
            N("Frame",{
                Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,i/11,0),
                BackgroundColor3=C.Pur,BackgroundTransparency=0.93,BorderSizePixel=0,ZIndex=2,
            },BG)
        end
        for i=1,16 do
            N("Frame",{
                Size=UDim2.new(0,1,1,0),Position=UDim2.new(i/17,0,0,0),
                BackgroundColor3=C.Pur,BackgroundTransparency=0.93,BorderSizePixel=0,ZIndex=2,
            },BG)
        end

        -- Radial aura layers
        local A1=N("Frame",{Size=UDim2.new(0,700,0,700),Position=UDim2.new(0.5,-350,0.5,-350),
            BackgroundColor3=C.Pur,BackgroundTransparency=0.93,BorderSizePixel=0,ZIndex=3},BG) Cr(350,A1)
        local A2=N("Frame",{Size=UDim2.new(0,420,0,420),Position=UDim2.new(0.5,-210,0.5,-210),
            BackgroundColor3=C.Pur,BackgroundTransparency=0.88,BorderSizePixel=0,ZIndex=3},BG) Cr(210,A2)
        local A3=N("Frame",{Size=UDim2.new(0,200,0,200),Position=UDim2.new(0.5,-100,0.5,-100),
            BackgroundColor3=C.Pur,BackgroundTransparency=0.80,BorderSizePixel=0,ZIndex=3},BG) Cr(100,A3)

        -- Card
        local Card=N("Frame",{
            Size=UDim2.new(0,400,0,250),
            Position=UDim2.new(0.5,-200,0.5,-125),
            BackgroundColor3=C.WinBg,BorderSizePixel=0,ZIndex=5,
        },BG)
        Cr(10,Card)
        Sk(C.BdrPur,1,0.4,Card)

        -- Top stripe
        local Stripe=N("Frame",{Size=UDim2.new(1,0,0,3),BackgroundColor3=C.Pur,BorderSizePixel=0,ZIndex=6},Card) Cr(2,Stripe)
        N("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.Pur),ColorSequenceKeypoint.new(1,C.Cyan)}),Rotation=90},Stripe)

        -- Logo ring
        local Ring=N("Frame",{Size=UDim2.new(0,60,0,60),Position=UDim2.new(0.5,-30,0,18),
            BackgroundColor3=C.PurGlow,BorderSizePixel=0,ZIndex=6},Card) Cr(30,Ring)
        Sk(C.Pur,2,0.1,Ring)
        N("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="Z",TextColor3=C.TxtPur,TextSize=30,Font=Enum.Font.GothamBold,ZIndex=7},Ring)

        -- Title
        N("TextLabel",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,88),
            BackgroundTransparency=1,Text=title:upper(),
            TextColor3=C.TxtHi,TextSize=20,Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6},Card)

        N("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,116),
            BackgroundTransparency=1,Text=gameName.."   ·   "..ver,
            TextColor3=C.TxtPur,TextSize=11,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6},Card)

        -- Progress track
        local PTr=N("Frame",{Size=UDim2.new(0,320,0,4),Position=UDim2.new(0.5,-160,0,162),
            BackgroundColor3=C.El,BorderSizePixel=0,ZIndex=6},Card) Cr(2,PTr)
        local PFl=N("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C.Pur,BorderSizePixel=0,ZIndex=7},PTr) Cr(2,PFl)
        N("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.Pur),ColorSequenceKeypoint.new(1,C.Cyan)})},PFl)

        local StLbl=N("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,174),
            BackgroundTransparency=1,Text="Initializing...",
            TextColor3=C.TxtLo,TextSize=10,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6},Card)
        local PcLbl=N("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,190),
            BackgroundTransparency=1,Text="0%",
            TextColor3=C.TxtPur,TextSize=10,Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6},Card)
        N("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,228),
            BackgroundTransparency=1,Text="PRESTIGE  ·  FPS ONLY  ·  EXPLOIT SAFE",
            TextColor3=C.TxtLo,TextSize=8,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6},Card)

        -- Pulse aura
        local pc
        Safe(function()
            local t0=tick()
            pc=RS.Heartbeat:Connect(function()
                Safe(function()
                    local s=math.sin((tick()-t0)*1.8)*0.5+0.5
                    A1.BackgroundTransparency=0.91+s*0.04
                    A2.BackgroundTransparency=0.85+s*0.05
                    A3.BackgroundTransparency=0.76+s*0.07
                end)
            end)
        end)

        local steps={
            {p=0.12,m="Hooking render pipeline..."},
            {p=0.28,m="Loading ESP matrices..."},
            {p=0.44,m="Patching aimbot vectors..."},
            {p=0.60,m="Initializing triggerbot..."},
            {p=0.76,m="Injecting visual overlays..."},
            {p=0.90,m="Loading user configs..."},
            {p=1.00,m="Ready."},
        }

        task.spawn(function()
            task.wait(0.3)
            for _,s in ipairs(steps) do
                Safe(function()
                    tw(PFl,{Size=UDim2.new(s.p,0,1,0)},0.32,Enum.EasingStyle.Quart)
                    StLbl.Text=s.m
                    PcLbl.Text=math.floor(s.p*100).."%"
                end)
                task.wait(0.26)
            end
            task.wait(0.45)
            if pc then Safe(function() pc:Disconnect() end) end
            tw(Card,{BackgroundTransparency=1},0.38,Enum.EasingStyle.Quart)
            task.wait(0.18)
            tw(BG,{BackgroundTransparency=1},0.42,Enum.EasingStyle.Quart)
            task.wait(0.48)
            Safe(function() LG:Destroy() end)
            Safe(function() self:_Build(cfg) end)
        end)
    end)
end

-- ══════════════════════════════════════════════════════
--  MAIN WINDOW BUILD
-- ══════════════════════════════════════════════════════
function PZ:_Build(cfg)
    cfg=cfg or {}
    local title = cfg.Title or "PROJECT Z"
    local ver   = cfg.Version or "v4.0"
    local W, H  = 860, 530

    Safe(function()
        local SG=N("ScreenGui",{
            Name="PZ_Main",ResetOnSpawn=false,
            ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
            DisplayOrder=1000,IgnoreGuiInset=true,
        },GuiRoot())
        self._SG=SG

        -- Window frame
        local MF=N("Frame",{
            Name="MF",Size=UDim2.new(0,W,0,H),
            Position=UDim2.new(0.5,-W/2,0.5,-H/2),
            BackgroundColor3=C.WinBg,BorderSizePixel=0,
            ClipsDescendants=false,
        },SG)
        Cr(8,MF)
        Sk(C.Bdr,1,0.1,MF)
        self._MF=MF

        -- Window aura
        local WA=N("Frame",{
            Size=UDim2.new(1,80,1,80),Position=UDim2.new(0,-40,0,-40),
            BackgroundColor3=C.Pur,BackgroundTransparency=0.92,BorderSizePixel=0,ZIndex=0,
        },MF) Cr(24,WA)

        local ClipMF=N("Frame",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            BorderSizePixel=0,ClipsDescendants=true,
        },MF) Cr(8,ClipMF)

        -- Dark gradient BG
        local BGf=N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.WinBg,BorderSizePixel=0},ClipMF)
        N("UIGradient",{
            Color=ColorSequence.new({
                ColorSequenceKeypoint.new(0,Color3.fromRGB(22,18,34)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(12,10,20)),
            }),Rotation=135,
        },BGf)

        -- ── TOP BAR ────────────────────────────────────────
        local TOP=N("Frame",{
            Size=UDim2.new(1,0,0,36),
            BackgroundColor3=C.TopBg,BorderSizePixel=0,ZIndex=3,
        },MF)
        -- bottom border
        N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
            BackgroundColor3=C.Bdr,BorderSizePixel=0,ZIndex=4},TOP)

        -- Z badge
        local Zb=N("Frame",{Size=UDim2.new(0,24,0,18),Position=UDim2.new(0,10,0.5,-9),
            BackgroundColor3=C.Pur,BorderSizePixel=0,ZIndex=4},TOP) Cr(4,Zb)
        N("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="Z",TextColor3=Color3.fromRGB(255,255,255),TextSize=12,Font=Enum.Font.GothamBold,ZIndex=5},Zb)

        N("TextLabel",{Size=UDim2.new(0,160,1,0),Position=UDim2.new(0,40,0,0),
            BackgroundTransparency=1,Text=title:upper(),
            TextColor3=C.TxtHi,TextSize=12,Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},TOP)

        N("TextLabel",{Size=UDim2.new(0,50,1,0),Position=UDim2.new(0,195,0,0),
            BackgroundTransparency=1,Text=ver,
            TextColor3=C.TxtPur,TextSize=10,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},TOP)

        -- Status pill
        local SPill=N("Frame",{Size=UDim2.new(0,80,0,20),Position=UDim2.new(1,-120,0.5,-10),
            BackgroundColor3=Color3.fromRGB(15,40,25),BorderSizePixel=0,ZIndex=4},TOP) Cr(4,SPill)
        Sk(Color3.fromRGB(50,160,90),1,0.3,SPill)
        N("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,7,0.5,-3),
            BackgroundColor3=Color3.fromRGB(80,220,120),BorderSizePixel=0,ZIndex=5},SPill) -- dot
        N("TextLabel",{Size=UDim2.new(1,-18,1,0),Position=UDim2.new(0,18,0,0),
            BackgroundTransparency=1,Text="ACTIVE",
            TextColor3=Color3.fromRGB(80,220,120),TextSize=9,Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},SPill)

        local function WBtn(xOff,col,lbl)
            local b=N("TextButton",{
                Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,xOff,0.5,-11),
                BackgroundColor3=col,BackgroundTransparency=0.5,
                Text=lbl,TextColor3=C.TxtHi,TextSize=14,Font=Enum.Font.GothamBold,
                BorderSizePixel=0,ZIndex=5,
            },TOP) Cr(4,b)
            Conn(b.MouseEnter,function() tw(b,{BackgroundTransparency=0},0.1) end)
            Conn(b.MouseLeave,function() tw(b,{BackgroundTransparency=0.5},0.1) end)
            return b
        end
        local CB=WBtn(-30,C.Red,"×")
        local MinB=WBtn(-56,C.Amber,"–")
        local minimized=false
        Conn(CB.MouseButton1Click,function() Safe(function() SG:Destroy() end) end)
        Conn(MinB.MouseButton1Click,function()
            Safe(function()
                minimized=not minimized
                tw(MF,{Size=minimized and UDim2.new(0,W,0,36) or UDim2.new(0,W,0,H)},0.22,Enum.EasingStyle.Quart)
            end)
        end)
        Drag(MF,TOP)

        -- ── TAB BAR (horizontal pills like Hyperion) ───────
        local TBar=N("Frame",{
            Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0,36),
            BackgroundColor3=C.TabBar,BorderSizePixel=0,ZIndex=3,
        },MF)
        N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
            BackgroundColor3=C.Bdr,BorderSizePixel=0,ZIndex=4},TBar)

        local TScroll=N("ScrollingFrame",{
            Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,5,0,0),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.X,
            ScrollingDirection=Enum.ScrollingDirection.X,ZIndex=3,
        },TBar)
        Pd(4,4,4,4,TScroll)
        N("UIListLayout",{
            FillDirection=Enum.FillDirection.Horizontal,
            SortOrder=Enum.SortOrder.LayoutOrder,
            Padding=UDim.new(0,3),
        },TScroll)
        self._tabScroll=TScroll

        -- ── CONTENT AREA (below tab bar) ───────────────────
        local CA=N("Frame",{
            Size=UDim2.new(1,0,1,-66),Position=UDim2.new(0,0,0,66),
            BackgroundTransparency=1,BorderSizePixel=0,
            ClipsDescendants=true,ZIndex=2,
        },MF)
        self._contentArea=CA

        -- Tab switcher
        function self:_SetTab(idx)
            Safe(function()
                self._activeTab=idx
                for i,pg in ipairs(self._tabPages) do
                    Safe(function() pg.Visible=(i==idx) end)
                end
                for i,btn in ipairs(self._tabBtns) do
                    local on=(i==idx)
                    tw(btn.F,{BackgroundColor3=on and C.PurDim or C.TabBar,
                              BackgroundTransparency=on and 0 or 1},0.15)
                    tw(btn.L,{TextColor3=on and C.TxtHi or C.TxtMid},0.15)
                end
            end)
        end

        -- Pulse aura
        Safe(function()
            local t0=tick()
            RS.Heartbeat:Connect(function()
                Safe(function()
                    local s=math.sin((tick()-t0)*1.3)*0.5+0.5
                    WA.BackgroundTransparency=0.90+s*0.04
                end)
            end)
        end)

        -- Animate window in
        MF.BackgroundTransparency=1
        MF.Position=UDim2.new(0.5,-W/2,0.5,-H/2+18)
        tw(MF,{BackgroundTransparency=0,Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.38,Enum.EasingStyle.Quart)

        -- Add built-in tabs after 0.05s (let user tabs register first)
        task.delay(0.05,function()
            Safe(function()
                self:AddTab("Configs")
                self:AddTab("Settings")
            end)
        end)

    end)
end

-- ══════════════════════════════════════════════════════
--  AddTab  — horizontal pill in top tab bar
-- ══════════════════════════════════════════════════════
function PZ:AddTab(name)
    local TabObj = { _name=name, _colFrames={}, _colCounts={} }

    Safe(function()
        -- Tab pill button
        local BF=N("Frame",{
            Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.TabBar,BackgroundTransparency=1,
            BorderSizePixel=0,LayoutOrder=#self._tabs+1,
        },self._tabScroll)
        Cr(4,BF)
        local BL=N("TextLabel",{
            Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundTransparency=1,Text=name,
            TextColor3=C.TxtMid,TextSize=11,Font=Enum.Font.GothamSemibold,
            TextXAlignment=Enum.TextXAlignment.Center,
        },BF)
        Pd(10,10,0,0,BL)

        -- Tab page (full content area)
        local Page=N("Frame",{
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,BorderSizePixel=0,
            Visible=false,ZIndex=2,
        },self._contentArea)

        -- 3-column grid inside page
        local ColGrid=N("Frame",{
            Size=UDim2.new(1,-16,1,-12),Position=UDim2.new(0,8,0,8),
            BackgroundTransparency=1,BorderSizePixel=0,
        },Page)
        N("UIGridLayout",{
            SortOrder=Enum.SortOrder.LayoutOrder,
            CellSize=UDim2.new(0.333,-4,1,0),
            CellPadding=UDim2.new(0,5,0,0),
            FillDirection=Enum.FillDirection.Horizontal,
        },ColGrid)

        -- Pre-create 3 column scroll frames
        for ci=1,3 do
            local Col=N("ScrollingFrame",{
                BackgroundColor3=C.ColBg,BorderSizePixel=0,
                ScrollBarThickness=2,ScrollBarImageColor3=C.Pur,
                ScrollBarImageTransparency=0.5,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                LayoutOrder=ci,
            },ColGrid)
            Cr(6,Col)
            Sk(C.Bdr,1,0.4,Col)
            Pd(0,0,6,6,Col)
            LL(0,Col)
            TabObj._colFrames[ci]=Col
            TabObj._colCounts[ci]=0
        end

        table.insert(self._tabs, name)
        table.insert(self._tabPages, Page)
        local idx=#self._tabs
        table.insert(self._tabBtns,{F=BF,L=BL})

        if idx==1 then self:_SetTab(1) end

        -- Built-in pages
        if name=="Configs" then Safe(function() self:_BuildConfigs(TabObj) end)
        elseif name=="Settings" then Safe(function() self:_BuildSettings(TabObj) end)
        end

        local Det=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},BF)
        Conn(Det.MouseButton1Click,function() Safe(function() self:_SetTab(idx) end) end)
        Conn(Det.MouseEnter,function()
            if self._activeTab~=idx then tw(BF,{BackgroundTransparency=0.6},0.1) end
        end)
        Conn(Det.MouseLeave,function()
            if self._activeTab~=idx then tw(BF,{BackgroundTransparency=1},0.1) end
        end)
    end)

    -- ── Col(n) — returns column element builder ───────────
    function TabObj:Col(n)
        local ci = math.clamp(n or 1, 1, 3)
        local ColObj = { _colFrame=nil, _count=0 }
        ColObj._colFrame = TabObj._colFrames[ci]

        -- ── Element row factory ────────────────────────────
        local function El(h, noHov)
            local r
            Safe(function()
                TabObj._colCounts[ci] = TabObj._colCounts[ci]+1
                ColObj._count         = ColObj._count+1
                r=N("Frame",{
                    Size=UDim2.new(1,0,0,h or 26),
                    BackgroundColor3=C.El,
                    BackgroundTransparency=noHov and 1 or 0.6,
                    BorderSizePixel=0,LayoutOrder=ColObj._count,
                },ColObj._colFrame)
                Cr(4,r)
                if not noHov then
                    Conn(r.MouseEnter,function() tw(r,{BackgroundColor3=C.ElHov,BackgroundTransparency=0},0.1) end)
                    Conn(r.MouseLeave,function() tw(r,{BackgroundColor3=C.El,BackgroundTransparency=0.6},0.1) end)
                end
            end)
            return r
        end

        -- ── SECTION HEADER ─────────────────────────────────
        function ColObj:Section(sname)
            Safe(function()
                TabObj._colCounts[ci] = TabObj._colCounts[ci]+1
                ColObj._count         = ColObj._count+1
                local SH=N("Frame",{
                    Size=UDim2.new(1,0,0,24),
                    BackgroundColor3=C.SecHeader,BackgroundTransparency=0,
                    BorderSizePixel=0,LayoutOrder=ColObj._count,
                },ColObj._colFrame)
                -- Left accent bar
                N("Frame",{Size=UDim2.new(0,2,0,12),Position=UDim2.new(0,8,0.5,-6),
                    BackgroundColor3=C.Pur,BorderSizePixel=0},SH)
                N("TextLabel",{Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,16,0,0),
                    BackgroundTransparency=1,Text=(sname or "Section"):upper(),
                    TextColor3=C.TxtPur,TextSize=9,Font=Enum.Font.GothamBold,
                    TextXAlignment=Enum.TextXAlignment.Left},SH)
            end)
            return ColObj -- allow chaining
        end

        -- ── TOGGLE ─────────────────────────────────────────
        function ColObj:Toggle(cfg2)
            local Tog={_val=false}
            Safe(function()
                cfg2=cfg2 or {}
                local val=cfg2.Default==true
                Tog._val=val

                local row=El(26)

                -- Name
                N("TextLabel",{
                    Size=UDim2.new(1,-46,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=cfg2.Name or "Toggle",
                    TextColor3=val and C.TxtHi or C.TxtMid,TextSize=11,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,
                },row)

                -- KB badge
                local kbXOff = -44
                if cfg2.Keybind then
                    local kb=tostring(cfg2.Keybind):gsub("Enum.KeyCode.","")
                    local KBF=N("TextLabel",{
                        Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,
                        Position=UDim2.new(1,-86,0.5,-7),
                        BackgroundColor3=C.AmberDim,
                        Text=" "..kb.." ",TextColor3=C.Amber,TextSize=8,Font=Enum.Font.GothamBold,
                        BorderSizePixel=0,
                    },row) Cr(3,KBF)
                    kbXOff=-90
                end

                -- Compact pill toggle
                local Pill=N("Frame",{
                    Size=UDim2.new(0,32,0,16),Position=UDim2.new(1,-38,0.5,-8),
                    BackgroundColor3=val and C.TogOn or C.TogOff,BorderSizePixel=0,
                },row) Cr(8,Pill)
                local Kn=N("Frame",{
                    Size=UDim2.new(0,12,0,12),
                    Position=val and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6),
                    BackgroundColor3=C.Knob,BorderSizePixel=0,ZIndex=2,
                },Pill) Cr(6,Kn)
                local Glo=N("UIStroke",{Color=C.Pur,Thickness=1.5,Transparency=val and 0.2 or 1},Pill)

                local NameLbl=row:FindFirstChildWhichIsA("TextLabel")

                local function Set(v)
                    Safe(function()
                        val=v; Tog._val=v
                        tw(Pill,{BackgroundColor3=v and C.TogOn or C.TogOff},0.18,Enum.EasingStyle.Quart)
                        tw(Kn,{Position=v and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)},0.18,Enum.EasingStyle.Quart)
                        tw(Glo,{Transparency=v and 0.2 or 1},0.18)
                        if cfg2.Callback then Safe(function() cfg2.Callback(v) end) end
                    end)
                end

                local Det=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},row)
                Conn(Det.MouseButton1Click,function() Set(not val) end)
                if cfg2.Keybind then
                    Conn(UIS.InputBegan,function(i,gpe)
                        Safe(function() if not gpe and i.KeyCode==cfg2.Keybind then Set(not val) end end)
                    end)
                end

                function Tog:Set(v) Safe(function() Set(v==true) end) end
                function Tog:Get() return Tog._val end
            end)
            return Tog
        end

        -- ── SLIDER ─────────────────────────────────────────
        function ColObj:Slider(cfg2)
            local Sl={_val=0}
            Safe(function()
                cfg2=cfg2 or {}
                local mn=cfg2.Min or 0
                local mx=cfg2.Max or 100
                local suf=cfg2.Suffix or ""
                local step=cfg2.Step or 1
                local val=math.clamp(cfg2.Default or mn,mn,mx)
                Sl._val=val

                local row=El(38)

                -- Name + value on top row
                N("TextLabel",{
                    Size=UDim2.new(0.6,0,0,16),Position=UDim2.new(0,8,0,3),
                    BackgroundTransparency=1,Text=cfg2.Name or "Slider",
                    TextColor3=C.TxtMid,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,
                },row)
                local ValL=N("TextLabel",{
                    Size=UDim2.new(0.4,-8,0,16),Position=UDim2.new(0.6,0,0,3),
                    BackgroundTransparency=1,Text=tostring(val)..suf,
                    TextColor3=C.TxtPur,TextSize=10,Font=Enum.Font.GothamBold,
                    TextXAlignment=Enum.TextXAlignment.Right,
                },row)

                local Tr=N("Frame",{
                    Size=UDim2.new(1,-16,0,4),Position=UDim2.new(0,8,0,23),
                    BackgroundColor3=C.Track,BorderSizePixel=0,
                },row) Cr(2,Tr)
                local pct=(val-mn)/(mx-mn)
                local Fl=N("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=C.Fill,BorderSizePixel=0},Tr) Cr(2,Fl)
                N("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.Pur),ColorSequenceKeypoint.new(1,C.Cyan)})},Fl)
                local Kn2=N("Frame",{
                    Size=UDim2.new(0,10,0,10),Position=UDim2.new(pct,-5,0.5,-5),
                    BackgroundColor3=Color3.fromRGB(230,225,255),BorderSizePixel=0,ZIndex=2,
                },Tr) Cr(5,Kn2)
                Sk(C.Pur,1,0.3,Kn2)

                local function Upd(rx)
                    Safe(function()
                        rx=math.clamp(rx,0,1)
                        local raw=mn+(mx-mn)*rx
                        val=math.floor(raw/step+0.5)*step
                        val=math.clamp(val,mn,mx)
                        Sl._val=val
                        local dp=(val-mn)/(mx-mn)
                        Fl.Size=UDim2.new(dp,0,1,0)
                        Kn2.Position=UDim2.new(dp,-5,0.5,-5)
                        ValL.Text=tostring(val)..suf
                        if cfg2.Callback then Safe(function() cfg2.Callback(val) end) end
                    end)
                end

                local slid=false
                Conn(Tr.InputBegan,function(i)
                    Safe(function()
                        if i.UserInputType==Enum.UserInputType.MouseButton1 then
                            slid=true
                            Upd((Mouse.X-Tr.AbsolutePosition.X)/Tr.AbsoluteSize.X)
                        end
                    end)
                end)
                Conn(UIS.InputEnded,function(i)
                    Safe(function() if i.UserInputType==Enum.UserInputType.MouseButton1 then slid=false end end)
                end)
                Conn(UIS.InputChanged,function(i)
                    Safe(function()
                        if slid and i.UserInputType==Enum.UserInputType.MouseMovement then
                            Upd((Mouse.X-Tr.AbsolutePosition.X)/Tr.AbsoluteSize.X)
                        end
                    end)
                end)

                function Sl:Set(v) Safe(function() Upd((math.clamp(v,mn,mx)-mn)/(mx-mn)) end) end
                function Sl:Get() return Sl._val end
            end)
            return Sl
        end

        -- ── DROPDOWN ───────────────────────────────────────
        function ColObj:Dropdown(cfg2)
            local DD={_sel=nil}
            Safe(function()
                cfg2=cfg2 or {}
                local opts=cfg2.Options or {}
                local sel=cfg2.Default or (opts[1] or "Select…")
                DD._sel=sel

                local row=El(26)
                row.ClipsDescendants=false
                row.ZIndex=8

                N("TextLabel",{
                    Size=UDim2.new(0.42,0,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=cfg2.Name or "Dropdown",
                    TextColor3=C.TxtMid,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,
                },row)

                local SB=N("Frame",{
                    Size=UDim2.new(0.54,0,0,20),Position=UDim2.new(0.44,0,0.5,-10),
                    BackgroundColor3=C.WinBg,BorderSizePixel=0,ZIndex=8,
                },row) Cr(4,SB)
                Sk(C.Bdr,1,0.3,SB)

                local SL=N("TextLabel",{
                    Size=UDim2.new(1,-18,1,0),Position=UDim2.new(0,5,0,0),
                    BackgroundTransparency=1,Text=sel,
                    TextColor3=C.TxtHi,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=8,
                },SB)

                local Ar=N("TextLabel",{
                    Size=UDim2.new(0,14,1,0),Position=UDim2.new(1,-16,0,0),
                    BackgroundTransparency=1,Text="▾",
                    TextColor3=C.TxtPur,TextSize=9,Font=Enum.Font.GothamBold,ZIndex=8,
                },SB)

                local DL=N("Frame",{
                    Size=UDim2.new(0.54,0,0,math.min(#opts,6)*22),
                    Position=UDim2.new(0.44,0,1,2),
                    BackgroundColor3=C.El,BorderSizePixel=0,
                    Visible=false,ZIndex=20,ClipsDescendants=true,
                },row) Cr(4,DL)
                Sk(C.BdrPur,1,0.3,DL)
                LL(0,DL)

                local open=false
                for idx2,opt in ipairs(opts) do
                    local OB=N("TextButton",{
                        Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,
                        Text=opt,TextColor3=opt==sel and C.TxtPur or C.TxtMid,
                        TextSize=10,Font=Enum.Font.Gotham,BorderSizePixel=0,
                        LayoutOrder=idx2,ZIndex=21,
                    },DL)
                    Pd(6,0,0,0,OB)
                    Conn(OB.MouseEnter,function()
                        Safe(function() OB.BackgroundColor3=C.PurGlow; tw(OB,{BackgroundTransparency=0},0.08); OB.TextColor3=C.TxtHi end)
                    end)
                    Conn(OB.MouseLeave,function()
                        Safe(function() tw(OB,{BackgroundTransparency=1},0.08); OB.TextColor3=OB.Text==sel and C.TxtPur or C.TxtMid end)
                    end)
                    Conn(OB.MouseButton1Click,function()
                        Safe(function()
                            sel=opt; DD._sel=opt; SL.Text=opt
                            for _,c in ipairs(DL:GetChildren()) do
                                if c:IsA("TextButton") then c.TextColor3=c.Text==sel and C.TxtPur or C.TxtMid end
                            end
                            open=false; DL.Visible=false
                            tw(Ar,{Rotation=0},0.12)
                            if cfg2.Callback then Safe(function() cfg2.Callback(sel) end) end
                        end)
                    end)
                end

                local Tog2=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=9},SB)
                Conn(Tog2.MouseButton1Click,function()
                    Safe(function() open=not open; DL.Visible=open; tw(Ar,{Rotation=open and 180 or 0},0.12) end)
                end)

                function DD:Set(v) Safe(function() sel=v; DD._sel=v; SL.Text=v end) end
                function DD:Get() return DD._sel end
            end)
            return DD
        end

        -- ── BUTTON ─────────────────────────────────────────
        function ColObj:Button(cfg2)
            Safe(function()
                cfg2=cfg2 or {}
                local row=El(26)
                N("TextLabel",{Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=cfg2.Name or "Button",
                    TextColor3=C.TxtHi,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left},row)
                N("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),
                    BackgroundTransparency=1,Text="›",TextColor3=C.TxtPur,TextSize=14,Font=Enum.Font.GothamBold},row)
                local B=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},row)
                Conn(B.MouseButton1Down,function() tw(row,{BackgroundColor3=C.PurGlow,BackgroundTransparency=0},0.06) end)
                Conn(B.MouseButton1Up,  function() tw(row,{BackgroundColor3=C.ElHov,BackgroundTransparency=0},0.1)   end)
                Conn(B.MouseButton1Click,function() Safe(function() if cfg2.Callback then cfg2.Callback() end end) end)
            end)
        end

        -- ── COLOR PICKER ───────────────────────────────────
        function ColObj:ColorPicker(cfg2)
            local CP={_color=C.Pur}
            Safe(function()
                cfg2=cfg2 or {}
                local color=cfg2.Default or C.Pur
                CP._color=color
                local row=El(26)
                N("TextLabel",{Size=UDim2.new(1,-46,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=cfg2.Name or "Color",
                    TextColor3=C.TxtMid,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left},row)
                local Sw=N("Frame",{Size=UDim2.new(0,36,0,18),Position=UDim2.new(1,-42,0.5,-9),
                    BackgroundColor3=color,BorderSizePixel=0},row) Cr(4,Sw) Sk(C.Bdr,1,0.3,Sw)
                local hue=0
                local SB2=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},Sw)
                Conn(SB2.MouseButton1Click,function()
                    Safe(function()
                        hue=(hue+1/12)%1
                        color=Color3.fromHSV(hue,0.8,1)
                        CP._color=color
                        tw(Sw,{BackgroundColor3=color},0.14)
                        if cfg2.Callback then Safe(function() cfg2.Callback(color) end) end
                    end)
                end)
                function CP:Set(c) Safe(function() color=c;CP._color=c;Sw.BackgroundColor3=c end) end
                function CP:Get() return CP._color end
            end)
            return CP
        end

        -- ── TEXTBOX ────────────────────────────────────────
        function ColObj:Textbox(cfg2)
            local TB={_val=""}
            Safe(function()
                cfg2=cfg2 or {}
                local row=El(26)
                N("TextLabel",{Size=UDim2.new(0.36,0,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=cfg2.Name or "Input",
                    TextColor3=C.TxtMid,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left},row)
                local IF=N("Frame",{Size=UDim2.new(0.58,0,0,18),Position=UDim2.new(0.39,0,0.5,-9),
                    BackgroundColor3=C.WinBg,BorderSizePixel=0},row) Cr(4,IF)
                local IFSk=Sk(C.Bdr,1,0.3,IF)
                local Box=N("TextBox",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),
                    BackgroundTransparency=1,Text="",
                    PlaceholderText=cfg2.Placeholder or "...",PlaceholderColor3=C.TxtLo,
                    TextColor3=C.TxtHi,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    ClearTextOnFocus=cfg2.ClearOnFocus~=false},IF)
                Conn(Box.Focused,   function() tw(IF,{BackgroundColor3=C.El},0.1); tw(IFSk,{Color=C.Pur,Transparency=0.3},0.1) end)
                Conn(Box.FocusLost, function(e)
                    Safe(function()
                        tw(IF,{BackgroundColor3=C.WinBg},0.1); tw(IFSk,{Color=C.Bdr,Transparency=0.3},0.1)
                        TB._val=Box.Text
                        if e and cfg2.Callback then Safe(function() cfg2.Callback(Box.Text) end) end
                    end)
                end)
                function TB:Set(v) Safe(function() Box.Text=v; TB._val=v end) end
                function TB:Get() return TB._val end
            end)
            return TB
        end

        -- ── LABEL ──────────────────────────────────────────
        function ColObj:Label(text)
            local L={}
            Safe(function()
                local row=El(20,true)
                local lbl=N("TextLabel",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=text or "",
                    TextColor3=C.TxtLo,TextSize=9,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left},row)
                function L:Set(t) Safe(function() lbl.Text=t end) end
            end)
            return L
        end

        -- ── SEPARATOR ──────────────────────────────────────
        function ColObj:Separator()
            Safe(function()
                ColObj._count=ColObj._count+1
                TabObj._colCounts[ci]=TabObj._colCounts[ci]+1
                N("Frame",{
                    Size=UDim2.new(1,0,0,1),
                    BackgroundColor3=C.Bdr,BackgroundTransparency=0.3,
                    BorderSizePixel=0,LayoutOrder=ColObj._count,
                },ColObj._colFrame)
            end)
        end

        -- ── KEYBIND ────────────────────────────────────────
        function ColObj:Keybind(cfg2)
            local KB={_key=nil}
            Safe(function()
                cfg2=cfg2 or {}
                local key=cfg2.Default
                KB._key=key
                local listening=false
                local row=El(26)
                N("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=cfg2.Name or "Keybind",
                    TextColor3=C.TxtMid,TextSize=10,Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left},row)
                local KBF=N("TextButton",{
                    Size=UDim2.new(0,70,0,18),Position=UDim2.new(1,-76,0.5,-9),
                    BackgroundColor3=C.AmberDim,
                    Text=key and tostring(key):gsub("Enum.KeyCode.","") or "None",
                    TextColor3=C.Amber,TextSize=9,Font=Enum.Font.GothamBold,
                    BorderSizePixel=0},row) Cr(4,KBF)
                Conn(KBF.MouseButton1Click,function()
                    Safe(function() listening=true; KBF.Text="..."; KBF.TextColor3=C.TxtHi end)
                end)
                Conn(UIS.InputBegan,function(i,gpe)
                    Safe(function()
                        if listening and not gpe then
                            listening=false; key=i.KeyCode; KB._key=key
                            KBF.Text=tostring(key):gsub("Enum.KeyCode.","")
                            KBF.TextColor3=C.Amber
                            if cfg2.Callback then Safe(function() cfg2.Callback(key) end) end
                        end
                    end)
                end)
                function KB:Set(k) Safe(function() key=k;KB._key=k;KBF.Text=tostring(k):gsub("Enum.KeyCode.","") end) end
                function KB:Get() return KB._key end
            end)
            return KB
        end

        return ColObj
    end -- Col

    return TabObj
end -- AddTab

-- ══════════════════════════════════════════════════════
--  BUILT-IN: CONFIGS
-- ══════════════════════════════════════════════════════
function PZ:_BuildConfigs(T2)
    Safe(function()
        local L=T2:Col(1)
        L:Section("Config Manager")
        local cfgName=L:Textbox({Name="Name",Placeholder="config_name"})
        L:Button({Name="Save Config",Callback=function()
            Safe(function()
                local n=cfgName:Get()
                if n~="" then self._configs[n]={ts=os.time()}; print("[PZ] Saved:"..n) end
            end)
        end})
        L:Button({Name="Load Config",Callback=function()
            Safe(function()
                local n=cfgName:Get()
                if self._configs[n] then print("[PZ] Loaded:"..n) else print("[PZ] Not found:"..n) end
            end)
        end})
        L:Button({Name="Delete Config",Callback=function()
            Safe(function()
                local n=cfgName:Get()
                if self._configs[n] then self._configs[n]=nil end
            end)
        end})
        L:Separator()
        L:Label("Configs persist per session only.")

        local R=T2:Col(2)
        R:Section("Saved Configs")
        R:Label("No configs saved yet.")
    end)
end

-- ══════════════════════════════════════════════════════
--  BUILT-IN: SETTINGS
-- ══════════════════════════════════════════════════════
function PZ:_BuildSettings(T2)
    Safe(function()
        local L=T2:Col(1)
        L:Section("UI")
        L:Toggle({Name="Animations",Default=true,Desc="Tween animations"})
        L:Toggle({Name="Window Aura",Default=true})
        L:Slider({Name="UI Scale",Min=70,Max=130,Default=100,Suffix="%"})
        L:Dropdown({Name="Theme",Options={"Purple (default)","Cyan","Green","Red"}})

        local M=T2:Col(2)
        M:Section("Notifications")
        M:Toggle({Name="Kill Feed",Default=true})
        M:Toggle({Name="Hit Sound",Default=true})
        M:Slider({Name="Duration",Min=1,Max=10,Default=3,Suffix="s"})

        M:Section("Performance")
        M:Toggle({Name="Render Optimize",Default=true})
        M:Slider({Name="ESP Tick Rate",Min=1,Max=60,Default=30,Suffix="fps"})

        local R=T2:Col(3)
        R:Section("Keybinds")
        R:Keybind({Name="Toggle Menu",Default=Enum.KeyCode.RightShift})
        R:Keybind({Name="Panic / Close",Default=Enum.KeyCode.End})

        R:Section("Misc")
        R:Toggle({Name="Anti-Screenshot",Default=false})
        R:Button({Name="Reset All Settings"})
        R:Separator()
        R:Label("Project Z  ·  Prestige Edition")
        R:Label("FPS Hub  ·  Exploit Safe")
    end)
end

-- ══════════════════════════════════════════════════════
--  DESTROY
-- ══════════════════════════════════════════════════════
function PZ:Destroy()
    Safe(function() if self._SG then self._SG:Destroy() end end)
end

return PZ
