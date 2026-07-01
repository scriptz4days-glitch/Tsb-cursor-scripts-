--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║              TSB ULTIMATE SCRIPT  —  The Strongest Battlegrounds            ║
║  Version : 3.0  (Lock-On + Mobile UI — no automation)                      ║
║  Compat  : Delta, Fluxus, Solara, Arceus X, and most executors             ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  FEATURES                                                                    ║
║   ✦ Lock-On button — targeting-reticle style circle on screen               ║
║       · Tap to lock / unlock the nearest enemy                               ║
║       · Draggable                                                            ║
║   ✦ Target diamond indicator — dual rotating diamond outline appears         ║
║       around the locked target (inspired by image 2, not copied)             ║
║   ✦ Mobile Mode — shows decorative tech buttons on screen                   ║
║       (buttons are visual only; no actions fire)                            ║
║   ✦ Minimal GUI — just the Mobile Mode toggle                               ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  USAGE                                                                       ║
║   Tap the LOCK button (left side) to lock onto nearest enemy.               ║
║   Enable Mobile Mode in the small GUI to show decorative buttons.           ║
║   Right-Ctrl  → toggle GUI visibility                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 1 — SERVICES
-- ═════════════════════════════════════════════════════════════════════════════

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local StarterGui         = game:GetService("StarterGui")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ── Duplicate-load guard ──────────────────────────────────────────────────────
local _env = (typeof(getgenv) == "function" and getgenv()) or {}
if _env._TSB_LOADED then
    warn("[TSB] Already loaded. Set _env._TSB_LOADED = false to reload.")
    return
end
_env._TSB_LOADED = true

-- ── Device detection ──────────────────────────────────────────────────────────
local _IsMobile = UserInputService.TouchEnabled

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 2 — CONFIGURATION
-- ═════════════════════════════════════════════════════════════════════════════

local Config = {
    Toggles = {
        LockOn     = false,   -- controlled by the on-screen lock button
        MobileMode = false,   -- shows the decorative mobile buttons
    },
    Settings = {
        LockOnRange        = 200,   -- max studs to acquire a lock
        IndicatorSize      = 170,   -- diamond indicator screen size (px)
        IndicatorStudsOffs = 1.5,   -- vertical offset (studs above HRP center)
    },
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 3 — UTILITIES
-- ═════════════════════════════════════════════════════════════════════════════

local function GetCharacter() return LocalPlayer.Character end

local function GetRoot()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function IsAlive()
    local c = GetCharacter()
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

local function GetPlayerRoot(p)
    local c = p and p.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Distance(a, b) return (a - b).Magnitude end

local function GetEnemies()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local r = GetPlayerRoot(p)
            local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then list[#list + 1] = p end
        end
    end
    return list
end

local function GetClosestEnemy()
    local myRoot = GetRoot()
    if not myRoot then return nil end
    local best, bestD = nil, Config.Settings.LockOnRange
    for _, p in ipairs(GetEnemies()) do
        local r = GetPlayerRoot(p)
        if r then
            local d = Distance(myRoot.Position, r.Position)
            if d < bestD then best, bestD = p, d end
        end
    end
    return best
end

local function Notify(title, text, dur)
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title = title, Text = text, Duration = dur or 3,
    })
end

-- Connection table for leak-free cleanup
local _conns = {}
local function Connect(sig, fn)
    local c = sig:Connect(fn)
    _conns[#_conns + 1] = c
    return c
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 4 — STATE
-- ═════════════════════════════════════════════════════════════════════════════

local State = {
    LockTarget    = nil,    -- Player currently locked onto
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5 — MINIMAL MAIN GUI  (Mobile Mode toggle + title)
-- ═════════════════════════════════════════════════════════════════════════════

pcall(function()
    local old = CoreGui:FindFirstChild("TSB_GUI")
    if old then old:Destroy() end
end)

local ScreenGui              = Instance.new("ScreenGui")
ScreenGui.Name               = "TSB_GUI"
ScreenGui.ResetOnSpawn       = false
ScreenGui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.IgnoreGuiInset = true end)
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- ── Main window ───────────────────────────────────────────────────────────────
local GW = _IsMobile and 200 or 240   -- compact — just Mobile Mode toggle
local GH = _IsMobile and 86  or 92

local MainFrame              = Instance.new("Frame")
MainFrame.Name               = "MainFrame"
MainFrame.Size               = UDim2.new(0, GW, 0, GH)
MainFrame.Position           = UDim2.new(1, -(GW + 14), 0, 46)  -- top-right, below Roblox bar
MainFrame.BackgroundColor3   = Color3.fromRGB(14, 14, 20)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel    = 0
MainFrame.ClipsDescendants   = true
MainFrame.ZIndex             = 5
MainFrame.Parent             = ScreenGui

do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = MainFrame end

-- Title bar
local TitleBar               = Instance.new("Frame")
TitleBar.Size                = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3    = Color3.fromRGB(26, 26, 40)
TitleBar.BorderSizePixel     = 0
TitleBar.ZIndex              = 6
TitleBar.Parent              = MainFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = TitleBar end

local TitleLbl               = Instance.new("TextLabel")
TitleLbl.Text                = "  ⚔  TSB v3.0"
TitleLbl.Size                = UDim2.new(1, -40, 1, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.TextColor3          = Color3.fromRGB(210, 210, 255)
TitleLbl.TextSize            = _IsMobile and 11 or 12
TitleLbl.Font                = Enum.Font.GothamBold
TitleLbl.TextXAlignment      = Enum.TextXAlignment.Left
TitleLbl.ZIndex              = 7
TitleLbl.Parent              = TitleBar

local MinBtn                 = Instance.new("TextButton")
MinBtn.Text                  = "—"
MinBtn.Size                  = UDim2.new(0, 26, 0, 18)
MinBtn.Position              = UDim2.new(1, -32, 0.5, -9)
MinBtn.BackgroundColor3      = Color3.fromRGB(55, 55, 85)
MinBtn.TextColor3            = Color3.fromRGB(210, 210, 255)
MinBtn.TextSize              = 12
MinBtn.Font                  = Enum.Font.GothamBold
MinBtn.BorderSizePixel       = 0
MinBtn.AutoButtonColor       = false
MinBtn.ZIndex                = 7
MinBtn.Parent                = TitleBar
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = MinBtn end

-- Content area
local Content                = Instance.new("Frame")
Content.Size                 = UDim2.new(1, 0, 1, -32)
Content.Position             = UDim2.new(0, 0, 0, 32)
Content.BackgroundTransparency = 1
Content.ZIndex               = 6
Content.Parent               = MainFrame

-- Mobile Mode row
local MobileRow              = Instance.new("Frame")
MobileRow.Size               = UDim2.new(1, -16, 0, _IsMobile and 28 or 34)
MobileRow.Position           = UDim2.new(0, 8, 0, 8)
MobileRow.BackgroundColor3   = Color3.fromRGB(22, 22, 32)
MobileRow.BorderSizePixel    = 0
MobileRow.ZIndex             = 7
MobileRow.Parent             = Content
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = MobileRow end

local MobileLbl              = Instance.new("TextLabel")
MobileLbl.Text               = "  📱  Mobile Mode"
MobileLbl.Size               = UDim2.new(1, -60, 1, 0)
MobileLbl.BackgroundTransparency = 1
MobileLbl.TextColor3         = Color3.fromRGB(195, 195, 220)
MobileLbl.TextSize           = _IsMobile and 11 or 12
MobileLbl.Font               = Enum.Font.Gotham
MobileLbl.TextXAlignment     = Enum.TextXAlignment.Left
MobileLbl.ZIndex             = 8
MobileLbl.Parent             = MobileRow

local MobileToggleBtn        = Instance.new("TextButton")
MobileToggleBtn.Size         = UDim2.new(0, 44, 0, 20)
MobileToggleBtn.Position     = UDim2.new(1, -50, 0.5, -10)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(75, 75, 100)
MobileToggleBtn.Text         = "OFF"
MobileToggleBtn.TextColor3   = Color3.fromRGB(170, 170, 195)
MobileToggleBtn.TextSize     = 10
MobileToggleBtn.Font         = Enum.Font.GothamBold
MobileToggleBtn.BorderSizePixel = 0
MobileToggleBtn.AutoButtonColor = false
MobileToggleBtn.ZIndex       = 9
MobileToggleBtn.Parent       = MobileRow
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = MobileToggleBtn end

-- Forward declarations (set in later sections)
local _refreshMobilePanel = nil

local function RefreshMobileToggle()
    local on = Config.Toggles.MobileMode
    MobileToggleBtn.BackgroundColor3 = on
        and Color3.fromRGB(70, 195, 115) or Color3.fromRGB(75, 75, 100)
    MobileToggleBtn.Text       = on and "ON" or "OFF"
    MobileToggleBtn.TextColor3 = on
        and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 195)
    if _refreshMobilePanel then _refreshMobilePanel() end
end

MobileToggleBtn.Activated:Connect(function()
    Config.Toggles.MobileMode = not Config.Toggles.MobileMode
    RefreshMobileToggle()
    Notify("TSB", "Mobile Mode " .. (Config.Toggles.MobileMode and "ON" or "OFF"))
end)

-- Drag main GUI
do
    local drag, ds, fs
    local function isDrag(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end
    TitleBar.InputBegan:Connect(function(i)
        if isDrag(i) then drag=true; ds=i.Position; fs=MainFrame.Position end
    end)
    TitleBar.InputEnded:Connect(function(i) if isDrag(i) then drag=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = i.Position - ds
        MainFrame.Position = UDim2.new(fs.X.Scale, fs.X.Offset+d.X, fs.Y.Scale, fs.Y.Offset+d.Y)
    end)
end

-- Minimize
local _expanded = true
MinBtn.Activated:Connect(function()
    _expanded = not _expanded
    Content.Visible  = _expanded
    MainFrame.Size   = _expanded and UDim2.new(0,GW,0,GH) or UDim2.new(0,GW,0,32)
    MinBtn.Text      = _expanded and "—" or "+"
end)

-- Right-Ctrl hides/shows the whole GUI
Connect(UserInputService.InputBegan, function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5.5 — LOCK-ON BUTTON
-- ═════════════════════════════════════════════════════════════════════════════
--
-- Circular on-screen button inspired by (but not copying) image 1.
-- Design: dark circle shell + teal outer ring + four inward tick marks
-- (like a targeting reticle / weapon sight) + center aiming dot.
-- Tap to toggle lock-on. Draggable. Glows when actively locked.

local LOCK_BTN_SIZE = _IsMobile and 86 or 80

-- Container (draggable, positions whole button)
local LockBtnFrame           = Instance.new("Frame")
LockBtnFrame.Name            = "TSB_LockBtnFrame"
LockBtnFrame.Size            = UDim2.new(0, LOCK_BTN_SIZE + 4, 0, LOCK_BTN_SIZE + 24)
LockBtnFrame.Position        = UDim2.new(0, 18, 0.52, 0)   -- left side, mid-screen
LockBtnFrame.BackgroundTransparency = 1
LockBtnFrame.ZIndex          = 30
LockBtnFrame.Parent          = ScreenGui

-- Outer shell (dark circle — the "body" of the button)
local LockBtn                = Instance.new("ImageButton")
LockBtn.Name                 = "LockBtn"
LockBtn.Size                 = UDim2.new(0, LOCK_BTN_SIZE, 0, LOCK_BTN_SIZE)
LockBtn.Position             = UDim2.new(0, 2, 0, 0)
LockBtn.BackgroundColor3     = Color3.fromRGB(20, 22, 28)
LockBtn.BackgroundTransparency = 0.08
LockBtn.Image                = ""
LockBtn.BorderSizePixel      = 0
LockBtn.AutoButtonColor      = false
LockBtn.ZIndex               = 31
LockBtn.Parent               = LockBtnFrame

do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = LockBtn end

-- Outer teal ring (UIStroke on the shell)
local LockRingOuter          = Instance.new("UIStroke")
LockRingOuter.Color          = Color3.fromRGB(0, 195, 210)
LockRingOuter.Thickness      = 2.5
LockRingOuter.Transparency   = 0.45
LockRingOuter.Parent         = LockBtn

-- Inset mid-ring (decorative inner circle, similar to camera-lens depth rings)
local MidRing                = Instance.new("Frame")
MidRing.Size                 = UDim2.new(0, LOCK_BTN_SIZE - 18, 0, LOCK_BTN_SIZE - 18)
MidRing.Position             = UDim2.new(0.5, -(LOCK_BTN_SIZE-18)/2, 0.5, -(LOCK_BTN_SIZE-18)/2)
MidRing.BackgroundTransparency = 1
MidRing.BorderSizePixel      = 0
MidRing.ZIndex               = 32
MidRing.Parent               = LockBtn

do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = MidRing
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 145, 160); s.Thickness = 1; s.Transparency = 0.5; s.Parent = MidRing
end

-- Four inward tick marks (N / E / S / W) — targeting reticle style
-- Each is a thin rectangle pointing from the ring edge toward the center,
-- leaving a gap so the center stays open (not a full crosshair)
local TICK_COLOR = Color3.fromRGB(0, 200, 215)
local S = LOCK_BTN_SIZE
local tickDefs = {
    { sz=UDim2.new(0,2,0,10),  pos=UDim2.new(0.5,-1, 0,  7 ) },   -- top
    { sz=UDim2.new(0,2,0,10),  pos=UDim2.new(0.5,-1, 1, -17) },   -- bottom
    { sz=UDim2.new(0,10,0,2),  pos=UDim2.new(0,  7 , 0.5,-1) },   -- left
    { sz=UDim2.new(0,10,0,2),  pos=UDim2.new(1,-17 , 0.5,-1) },   -- right
}
local LockTicks = {}
for _, d in ipairs(tickDefs) do
    local f = Instance.new("Frame")
    f.Size             = d.sz
    f.Position         = d.pos
    f.BackgroundColor3 = TICK_COLOR
    f.BackgroundTransparency = 0.3
    f.BorderSizePixel  = 0
    f.ZIndex           = 33
    f.Parent           = LockBtn
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,1); c.Parent = f end
    LockTicks[#LockTicks+1] = f
end

-- Center aiming dot
local CenterDot              = Instance.new("Frame")
CenterDot.Size               = UDim2.new(0, 10, 0, 10)
CenterDot.Position           = UDim2.new(0.5, -5, 0.5, -5)
CenterDot.BackgroundColor3   = Color3.fromRGB(0, 200, 215)
CenterDot.BackgroundTransparency = 0.15
CenterDot.BorderSizePixel    = 0
CenterDot.ZIndex             = 33
CenterDot.Parent             = LockBtn
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = CenterDot end

-- Small "LOCK" / "LOCKED" label below the button
local LockLabel              = Instance.new("TextLabel")
LockLabel.Text               = "LOCK"
LockLabel.Size               = UDim2.new(1, 0, 0, 18)
LockLabel.Position           = UDim2.new(0, 0, 1, -20)
LockLabel.BackgroundTransparency = 1
LockLabel.TextColor3         = Color3.fromRGB(0, 180, 200)
LockLabel.TextSize           = 10
LockLabel.Font               = Enum.Font.GothamBold
LockLabel.ZIndex             = 31
LockLabel.Parent             = LockBtnFrame

-- ── Visual state updater ──────────────────────────────────────────────────────
local function UpdateLockBtnVisual()
    local on  = Config.Toggles.LockOn
    local clr = on and Color3.fromRGB(0, 230, 245) or Color3.fromRGB(0, 200, 215)

    -- Shell background
    LockBtn.BackgroundColor3   = on
        and Color3.fromRGB(12, 48, 58)
        or  Color3.fromRGB(20, 22, 28)

    -- Outer ring brightness
    LockRingOuter.Color        = on and Color3.fromRGB(0, 230, 245) or Color3.fromRGB(0, 195, 210)
    LockRingOuter.Thickness    = on and 3.5 or 2.5
    LockRingOuter.Transparency = on and 0   or 0.45

    -- Ticks + center dot
    for _, t in ipairs(LockTicks) do
        t.BackgroundColor3        = clr
        t.BackgroundTransparency  = on and 0 or 0.3
    end
    CenterDot.BackgroundColor3    = clr
    CenterDot.BackgroundTransparency = on and 0 or 0.15

    -- Label
    LockLabel.Text       = on and ("LOCKED  ●") or "LOCK"
    LockLabel.TextColor3 = on and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(0, 180, 200)
end

UpdateLockBtnVisual()   -- apply initial state

-- ── Drag the lock button (touch + mouse) ─────────────────────────────────────
do
    local drag, ds, fs
    local function isDrag(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end
    LockBtn.InputBegan:Connect(function(i)
        if isDrag(i) then drag=true; ds=i.Position; fs=LockBtnFrame.Position end
    end)
    LockBtn.InputEnded:Connect(function(i) if isDrag(i) then drag=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = i.Position - ds
        LockBtnFrame.Position = UDim2.new(
            fs.X.Scale, fs.X.Offset + d.X,
            fs.Y.Scale, fs.Y.Offset + d.Y
        )
    end)
end

-- ── Tap: toggle lock-on ───────────────────────────────────────────────────────
local function SetLockOn(on)
    Config.Toggles.LockOn = on
    UpdateLockBtnVisual()
    if not on then
        State.LockTarget = nil
    end
end

LockBtn.Activated:Connect(function()
    -- Scale pulse on tap
    local full = UDim2.new(0, LOCK_BTN_SIZE, 0, LOCK_BTN_SIZE)
    local shrunk = UDim2.new(0, LOCK_BTN_SIZE*0.88, 0, LOCK_BTN_SIZE*0.88)
    local t1 = TweenService:Create(LockBtn,
        TweenInfo.new(0.07, Enum.EasingStyle.Quad), {Size = shrunk,
        Position = UDim2.new(0, 2 + LOCK_BTN_SIZE*0.06, 0, LOCK_BTN_SIZE*0.06)})
    local t2 = TweenService:Create(LockBtn,
        TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = full, Position = UDim2.new(0, 2, 0, 0)})
    t1:Play(); t1.Completed:Connect(function() t2:Play() end)

    SetLockOn(not Config.Toggles.LockOn)
    Notify("TSB", Config.Toggles.LockOn and "🎯 Lock-On ACTIVE" or "Lock-On OFF", 2)
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5.6 — TARGET DIAMOND INDICATOR
-- ═════════════════════════════════════════════════════════════════════════════
--
-- A dual diamond outline appears around the locked target.
-- Inspired by (not copied from) image 2:
--   · Outer diamond:  thick darker teal border, rounded corners
--   · Inner diamond:  thin lighter teal border, rounded corners
--   · Outer rotates clockwise, inner counter-clockwise for a dynamic look
--   · Fades in when locking, fades out when unlocking
-- Implemented as a BillboardGui so it always faces the camera in 3D space.

local _indicator = nil   -- the live BillboardGui, or nil

local function DestroyIndicator()
    if _indicator then
        -- Fade out then destroy
        local bb = _indicator
        _indicator = nil
        task.spawn(function()
            for i = 1, 8 do
                pcall(function()
                    local c = bb:GetChildren()
                    for _, f in ipairs(c) do
                        if f:IsA("Frame") then
                            local s = f:FindFirstChildOfClass("UIStroke")
                            if s then s.Transparency = math.min(1, s.Transparency + 0.12) end
                        end
                    end
                end)
                task.wait(0.04)
            end
            pcall(bb.Destroy, bb)
        end)
    end
end

local function CreateIndicator(target)
    DestroyIndicator()

    local tChar = target and target.Character
    local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end

    local IND = Config.Settings.IndicatorSize
    local YOff = Config.Settings.IndicatorStudsOffs

    local bb                   = Instance.new("BillboardGui")
    bb.Name                    = "TSB_TargetIndicator"
    bb.Adornee                 = tRoot
    bb.AlwaysOnTop             = true
    bb.Size                    = UDim2.new(0, IND, 0, IND)
    bb.StudsOffset             = Vector3.new(0, YOff, 0)
    bb.ZIndexBehavior          = Enum.ZIndexBehavior.Sibling
    bb.Parent                  = CoreGui
    _indicator = bb

    -- Helper: make a rotated diamond frame
    local function MakeDiamond(sz, strokeClr, strokeThk, cornerR, startRot)
        local f = Instance.new("Frame")
        f.Size                 = UDim2.new(0, sz, 0, sz)
        f.Position             = UDim2.new(0.5, -sz/2, 0.5, -sz/2)
        f.BackgroundTransparency = 1
        f.BorderSizePixel      = 0
        f.Rotation             = startRot
        f.Parent               = bb

        local s = Instance.new("UIStroke")
        s.Color                = strokeClr
        s.Thickness            = strokeThk
        s.Transparency         = 0
        s.LineJoinMode         = Enum.LineJoinMode.Round
        s.Parent               = f

        local c = Instance.new("UICorner")
        c.CornerRadius         = UDim.new(0, cornerR)
        c.Parent               = f

        return f, s
    end

    -- Outer diamond — darker teal, thick
    local outerFrame, outerStroke = MakeDiamond(
        IND - 10,
        Color3.fromRGB(0, 148, 165),   -- darker teal (outer edge)
        13,
        22,
        45
    )

    -- Inner diamond — brighter teal, thin
    local innerFrame, innerStroke = MakeDiamond(
        IND - 46,
        Color3.fromRGB(90, 225, 230),  -- lighter teal (inner edge)
        4,
        15,
        45
    )

    -- Fade in both diamonds
    outerStroke.Transparency = 1
    innerStroke.Transparency = 1
    TweenService:Create(outerStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
    TweenService:Create(innerStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()

    -- Counter-rotating spin + pulse loop
    task.spawn(function()
        local angle    = 45
        local pulse    = 0
        local pulseDir = 1
        while bb.Parent and _indicator == bb do
            angle = angle + 0.35     -- outer: slow clockwise
            outerFrame.Rotation = angle
            innerFrame.Rotation = -(angle * 1.5)  -- inner: faster counter-clockwise

            -- Gentle outer-stroke transparency pulse
            pulse = pulse + 0.04 * pulseDir
            if pulse >= 1 then pulseDir = -1
            elseif pulse <= 0 then pulseDir = 1 end
            outerStroke.Transparency = pulse * 0.38   -- 0 → 0.38 → 0

            task.wait(0.016)
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5.7 — MOBILE TECH PANEL  (decorative — buttons do nothing)
-- ═════════════════════════════════════════════════════════════════════════════
--
-- When Mobile Mode is ON, circular tech buttons appear on the right-hand side
-- of the left edge (just to the right of the lock button column).
-- They look like TSB's native circular controls but have NO functional actions.
-- Tap → scale-pulse visual feedback only.

local MBTN = _IsMobile and 68 or 62

-- Definitions — visual only
local _mbDefs = {
    { label="TW",  name="Twisted",    clr=Color3.fromRGB(220, 60,  60)  },
    { label="KY1", name="Kyoto 1",    clr=Color3.fromRGB(70,  120, 240) },
    { label="KY2", name="Kyoto 2",    clr=Color3.fromRGB(50,  90,  210) },
    { label="KYG", name="Ky.Grasp",   clr=Color3.fromRGB(40,  70,  190) },
    { label="GR",  name="Grasp",      clr=Color3.fromRGB(190, 130, 40)  },
    { label="UC",  name="Upcut",      clr=Color3.fromRGB(190, 70,  180) },
    { label="LF",  name="Lethal+Fl",  clr=Color3.fromRGB(50,  180, 150) },
    { label="LP",  name="Loop",       clr=Color3.fromRGB(220, 140, 0)   },
    { label="PF",  name="Punish",     clr=Color3.fromRGB(170, 60,  90)  },
    { label="SM",  name="Side M1",    clr=Color3.fromRGB(140, 80,  190) },
}

-- Scrollable column — positioned just to the right of the lock button
local MobilePanel            = Instance.new("ScrollingFrame")
MobilePanel.Name             = "TSB_MobilePanel"
MobilePanel.Visible          = false
MobilePanel.BackgroundTransparency = 1
MobilePanel.Size             = UDim2.new(0, MBTN + 14, 1, -140)
MobilePanel.Position         = UDim2.new(0, 18 + LOCK_BTN_SIZE + 12, 0, 80)
MobilePanel.ClipsDescendants = true
MobilePanel.ScrollBarThickness = 0
MobilePanel.CanvasSize       = UDim2.new(0, 0, 0, 0)
MobilePanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
MobilePanel.ZIndex           = 20
MobilePanel.Parent           = ScreenGui

do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 8)
    l.FillDirection = Enum.FillDirection.Vertical
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = MobilePanel

    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 6); p.PaddingBottom = UDim.new(0, 6)
    p.PaddingLeft = UDim.new(0, 7); p.PaddingRight = UDim.new(0, 7)
    p.Parent = MobilePanel
end

local function PulseTap(btn)
    local full = UDim2.new(0, MBTN, 0, MBTN)
    local sm   = UDim2.new(0, MBTN * 0.84, 0, MBTN * 0.84)
    local t1 = TweenService:Create(btn, TweenInfo.new(0.07, Enum.EasingStyle.Quad), {Size=sm})
    local t2 = TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=full})
    t1:Play(); t1.Completed:Connect(function() t2:Play() end)
end

for i, def in ipairs(_mbDefs) do
    local btn                = Instance.new("ImageButton")
    btn.Size                 = UDim2.new(0, MBTN, 0, MBTN)
    btn.BackgroundColor3     = def.clr
    btn.BackgroundTransparency = 0.28
    btn.Image                = ""
    btn.BorderSizePixel      = 0
    btn.LayoutOrder          = i
    btn.ZIndex               = 21
    btn.AutoButtonColor      = false
    btn.Parent               = MobilePanel

    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = btn
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(255,255,255); s.Thickness = 1.6; s.Transparency = 0.55; s.Parent = btn
    end

    local ico = Instance.new("TextLabel")
    ico.Text   = def.label; ico.Size = UDim2.new(1,0,0.54,0); ico.Position = UDim2.new(0,0,0.06,0)
    ico.BackgroundTransparency = 1; ico.TextColor3 = Color3.fromRGB(255,255,255)
    ico.TextSize = _IsMobile and 20 or 18; ico.Font = Enum.Font.GothamBold
    ico.TextStrokeTransparency = 0.2; ico.ZIndex = 22; ico.Parent = btn

    local nm = Instance.new("TextLabel")
    nm.Text  = def.name; nm.Size = UDim2.new(1,-6,0.32,0); nm.Position = UDim2.new(0,3,0.64,0)
    nm.BackgroundTransparency = 1; nm.TextColor3 = Color3.fromRGB(240,240,255)
    nm.TextSize = 10; nm.Font = Enum.Font.Gotham; nm.TextScaled = true
    nm.TextStrokeTransparency = 0.45; nm.ZIndex = 22; nm.Parent = btn

    -- Visual-only tap: pulse animation, no action
    btn.Activated:Connect(function() PulseTap(btn) end)
end

-- Wire the refresh callback so MobileToggleBtn can show/hide the panel
_refreshMobilePanel = function()
    MobilePanel.Visible = Config.Toggles.MobileMode
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 6 — LOCK-ON LOGIC
-- ═════════════════════════════════════════════════════════════════════════════

-- Update which player we're locked onto, rotate camera toward them,
-- and manage the diamond indicator lifecycle.

local function UpdateLockOn()
    if not Config.Toggles.LockOn then
        if State.LockTarget then
            State.LockTarget = nil
            DestroyIndicator()
        end
        return
    end

    -- Try to keep existing target if still alive
    if State.LockTarget then
        local tHum = State.LockTarget.Character
            and State.LockTarget.Character:FindFirstChildOfClass("Humanoid")
        if not tHum or tHum.Health <= 0 or not GetPlayerRoot(State.LockTarget) then
            -- Target died / left — re-acquire
            State.LockTarget = nil
            DestroyIndicator()
        end
    end

    -- Acquire new target if needed
    if not State.LockTarget then
        local e = GetClosestEnemy()
        if e then
            State.LockTarget = e
            CreateIndicator(e)
        else
            -- No enemies found — keep lock toggle on but wait
            return
        end
    end

    -- Camera rotation toward target
    local tRoot = GetPlayerRoot(State.LockTarget)
    if tRoot then
        local lookDir = (tRoot.Position - Camera.CFrame.Position).Unit
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookDir)
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 7 — MAIN HEARTBEAT LOOP
-- ═════════════════════════════════════════════════════════════════════════════

local _hbFrame = 0
Connect(RunService.Heartbeat, function()
    _hbFrame = _hbFrame + 1

    -- Every 2 frames: update lock-on
    if _hbFrame % 2 == 0 then
        UpdateLockOn()

        -- Keep lock-button visual in sync with actual lock state
        -- (e.g. if target died and we auto-deactivated)
        local hasTarget = Config.Toggles.LockOn and State.LockTarget ~= nil
        if not hasTarget and Config.Toggles.LockOn and not GetClosestEnemy() then
            -- No one to lock onto; reflect in label but keep toggle on
            LockLabel.Text       = "SCANNING…"
            LockLabel.TextColor3 = Color3.fromRGB(200, 200, 60)
        elseif Config.Toggles.LockOn and State.LockTarget then
            LockLabel.Text       = "LOCKED  ●"
            LockLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
        elseif not Config.Toggles.LockOn then
            LockLabel.Text       = "LOCK"
            LockLabel.TextColor3 = Color3.fromRGB(0, 180, 200)
        end
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 8 — CHARACTER RESPAWN HANDLER
-- ═════════════════════════════════════════════════════════════════════════════

local function OnCharacterAdded()
    State.LockTarget = nil
    DestroyIndicator()
    -- Keep user's lock-on toggle preference; it'll re-acquire on next loop
end

Connect(LocalPlayer.CharacterAdded, OnCharacterAdded)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 9 — INITIALIZATION
-- ═════════════════════════════════════════════════════════════════════════════

-- Sync initial state
_refreshMobilePanel()
UpdateLockBtnVisual()

Notify("TSB v3.0 Loaded",
    "Tap LOCK button (left side) to lock onto nearest enemy. Enable Mobile Mode in GUI for decorative buttons.",
    7)

print("[TSB v3.0] Ready — lock-on button active | Mobile Mode: "
    .. tostring(Config.Toggles.MobileMode))
