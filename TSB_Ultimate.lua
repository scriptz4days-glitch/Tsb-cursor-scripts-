--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║              TSB ULTIMATE SCRIPT  —  The Strongest Battlegrounds            ║
║                                                                              ║
║  Compatible: Delta Executor, Fluxus, Solara, Arceus X, and most others      ║
║  Author   : TSB Script Team                                                  ║
║  Version  : 2.2  (Native-style mobile controls, touch-fixed events)         ║
║                                                                              ║
║  FEATURES:                                                                   ║
║   ✦ Twisted Tech  (Instant / Humbled's variant)                             ║
║   ✦ Kyoto Combo   (One, Two & Grasp variants)                               ║
║   ✦ Grasp Tech    (Hunter's Grasp / Crushing Pull)                          ║
║   ✦ Uppercut Grasp / Humbled's Tech                                         ║
║   ✦ Lethal + Flowing Water seamless integration                             ║
║   ✦ Loop Tech     (LordHeaven-style dash pressure)                          ║
║   ✦ Auto Block    (velocity + animation-based heuristic)                    ║
║   ✦ Auto Punish after Front Dash                                            ║
║   ✦ Auto M1 after Side Dash                                                 ║
║   ✦ Lock On — Closest Player  (F10)                                         ║
║   ✦ Lock On — Closest to Cursor (F11)                                       ║
║   ✦ ESP SelectionBox + Billboard labels                                     ║
║   ✦ Draggable GUI — auto-scaled for mobile/tablet/desktop                  ║
║   ✦ Mobile Mode — native-style circular tech buttons on left side           ║
║   ✦ Kyoto/Lethal burst keys: Q / E / R / G / T                             ║
║   ✦ Right-Ctrl toggles GUI visibility                                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

  KEYBIND REFERENCE
  ─────────────────
  F1   Twisted Tech          F7   Auto Block
  F2   Kyoto Combo           F8   Auto Punish (Front Dash)
  F3   Grasp Tech            F9   Auto M1 (Side Dash)
  F4   Uppercut Grasp        F10  Lock On – Closest
  F5   Lethal + Flowing      F11  Lock On – Cursor
  F6   Loop Tech             F12  ESP
  RCtrl  Toggle GUI

  MOBILE MODE
  ───────────────────────────────────────────────────
  Enable "Mobile Mode" in the 📱 section of the GUI.
  Large circular buttons (matching TSB's native controls style) appear
  on the LEFT side of the screen — one per enabled tech.
  Tap to execute. Visual pulse confirms each tap.
]]

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 1 — SERVICES & CORE REFERENCES
-- ═════════════════════════════════════════════════════════════════════════════

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local StarterGui         = game:GetService("StarterGui")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = Workspace.CurrentCamera

-- ── Duplicate-load guard ──────────────────────────────────────────────────────
local _env = (typeof(getgenv) == "function" and getgenv()) or {}
if _env._TSB_LOADED then
    warn("[TSB] Already loaded — set _env._TSB_LOADED = false to reload.")
    return
end
_env._TSB_LOADED = true

-- ── Mobile / device detection ─────────────────────────────────────────────────
local _IsMobile     = UserInputService.TouchEnabled
local _ViewportSize = Camera.ViewportSize

-- Responsive dimension constants
local _GUI_W   = _IsMobile and 255 or 330
local _GUI_H   = _IsMobile and 410 or 500
local _TITLE_H = _IsMobile and 32  or 38
local _ROW_H   = _IsMobile and 28  or 34
local _SEC_H   = _IsMobile and 21  or 26
local _FONT_S  = _IsMobile and 11  or 13
local _HEAD_S  = _IsMobile and 10  or 11
local _BTN_W   = _IsMobile and 40  or 48
local _BTN_H   = _IsMobile and 20  or 22
local _BTN_FS  = _IsMobile and 10  or 11

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 2 — CONFIGURATION
-- ═════════════════════════════════════════════════════════════════════════════

local Config = {

    Toggles = {
        TwistedTech          = false,
        KyotoCombo           = false,
        GraspTech            = false,
        UppercutGrasp        = false,
        LethalFlowing        = false,
        LoopTech             = false,
        AutoBlock            = false,
        AutoPunishFrontDash  = false,
        AutoM1SideDash       = false,
        LockOnClosest        = false,
        LockOnCursor         = false,
        ESP                  = false,
        MobileMode           = false,
    },

    Keybinds = {
        TwistedTech          = Enum.KeyCode.F1,
        KyotoCombo           = Enum.KeyCode.F2,
        GraspTech            = Enum.KeyCode.F3,
        UppercutGrasp        = Enum.KeyCode.F4,
        LethalFlowing        = Enum.KeyCode.F5,
        LoopTech             = Enum.KeyCode.F6,
        AutoBlock            = Enum.KeyCode.F7,
        AutoPunishFrontDash  = Enum.KeyCode.F8,
        AutoM1SideDash       = Enum.KeyCode.F9,
        LockOnClosest        = Enum.KeyCode.F10,
        LockOnCursor         = Enum.KeyCode.F11,
        ESP                  = Enum.KeyCode.F12,
        ToggleGUI            = Enum.KeyCode.RightControl,
    },

    Settings = {
        AutoBlockRange     = 25,
        LockOnRange        = 200,
        PunishHitRange     = 14,
        M1Interval         = 0.35,
        DashDelay          = 0.08,
        SkillDelay         = 0.12,
        TwistedWindow      = 0.16,
        KyotoWindow        = 0.20,
        LoopDashInterval   = 0.42,
        Randomness         = 0.04,
        ESPColor           = Color3.fromRGB(255, 50, 50),
        ESPTransparency    = 0.3,
        HumbledBackForce   = 8,
    },
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 3 — UTILITY FUNCTIONS
-- ═════════════════════════════════════════════════════════════════════════════

local function Jitter(base)
    local r = Config.Settings.Randomness
    return base + (math.random() * r * 2 - r)
end

local function GetCharacter() return LocalPlayer.Character end

local function GetRoot()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function IsAlive()
    local h = GetHumanoid()
    return h ~= nil and h.Health > 0
end

local function GetPlayerRoot(player)
    local c = player and player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Distance(a, b)
    return (a - b).Magnitude
end

local function GetEnemies()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local root = GetPlayerRoot(p)
            local hum  = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                list[#list + 1] = p
            end
        end
    end
    return list
end

local function GetClosestEnemy()
    local myRoot = GetRoot()
    if not myRoot then return nil end
    local best, bestDist = nil, Config.Settings.LockOnRange
    for _, p in ipairs(GetEnemies()) do
        local r = GetPlayerRoot(p)
        if r then
            local d = Distance(myRoot.Position, r.Position)
            if d < bestDist then best, bestDist = p, d end
        end
    end
    return best
end

local function GetCursorEnemy()
    local mPos = UserInputService:GetMouseLocation()
    local best, bestDist = nil, math.huge
    for _, p in ipairs(GetEnemies()) do
        local r = GetPlayerRoot(p)
        if r then
            local sp, onScreen = Camera:WorldToViewportPoint(r.Position)
            if onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - mPos).Magnitude
                if d < bestDist then best, bestDist = p, d end
            end
        end
    end
    return best
end

local function Notify(title, text, dur)
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title    = title,
        Text     = text,
        Duration = dur or 3,
    })
end

local function IsAnimationPlaying(keyword)
    local char = GetCharacter()
    if not char then return false end
    local animator = char:FindFirstChild("Animator", true)
    if not animator then return false end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Name:lower():find(keyword:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function IsRagdolled()
    local char = GetCharacter()
    if not char then return false end
    local flag = char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsRagdoll")
    if flag and flag.Value then return true end
    local hum = GetHumanoid()
    return hum ~= nil and hum:GetState() == Enum.HumanoidStateType.FallingDown
end

local _remoteCache = {}
local function FindRemote(name)
    if _remoteCache[name] then return _remoteCache[name] end
    local found = ReplicatedStorage:FindFirstChild(name, true)
    _remoteCache[name] = found
    return found
end

local function DoAction(remoteName, ...)
    local remote = FindRemote(remoteName)
    if remote and remote:IsA("RemoteEvent") then
        pcall(remote.FireServer, remote, ...)
        return true
    end
    return false
end

local _connections = {}
local function Connect(signal, fn)
    local c = signal:Connect(fn)
    _connections[#_connections + 1] = c
    return c
end

local function DisconnectAll()
    for _, c in ipairs(_connections) do
        if c.Connected then c:Disconnect() end
    end
    _connections = {}
    _env._TSB_LOADED = false
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 4 — COMBAT STATE TRACKER
-- ═════════════════════════════════════════════════════════════════════════════

local State = {
    M1Count        = 0,
    LastM1Time     = 0,
    LastDashTime   = 0,
    DashDirection  = "None",
    IsBlocking     = false,
    IsRagdolled    = false,
    InSkill        = false,
    LastSkillUsed  = "",
    LockTarget     = nil,
}

local function ResetState()
    State.M1Count       = 0
    State.LastM1Time    = 0
    State.LastDashTime  = 0
    State.DashDirection = "None"
    State.IsBlocking    = false
    State.IsRagdolled   = false
    State.InSkill       = false
    State.LastSkillUsed = ""
    State.LockTarget    = nil
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5 — GUI SYSTEM
-- ═════════════════════════════════════════════════════════════════════════════

pcall(function()
    local old = CoreGui:FindFirstChild("TSB_GUI")
    if old then old:Destroy() end
end)

-- IgnoreGuiInset = true so our coordinates match actual screen edges on mobile
local ScreenGui               = Instance.new("ScreenGui")
ScreenGui.Name                = "TSB_GUI"
ScreenGui.ResetOnSpawn        = false
ScreenGui.ZIndexBehavior      = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.IgnoreGuiInset = true end)   -- removes top-bar offset
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- ── Main window ───────────────────────────────────────────────────────────────
local MainFrame               = Instance.new("Frame")
MainFrame.Name                = "MainFrame"
MainFrame.Size                = UDim2.new(0, _GUI_W, 0, _GUI_H)
MainFrame.Position            = UDim2.new(0, 12, 0.5, -math.floor(_GUI_H / 2))
MainFrame.BackgroundColor3    = Color3.fromRGB(14, 14, 20)
MainFrame.BorderSizePixel     = 0
MainFrame.ClipsDescendants    = true
MainFrame.ZIndex              = 5
MainFrame.Parent              = ScreenGui

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = MainFrame
end

do  -- drop shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size                  = UDim2.new(1, 24, 1, 24)
    shadow.Position              = UDim2.new(0, -12, 0, -12)
    shadow.BackgroundTransparency = 1
    shadow.Image                 = "rbxassetid://5554236805"
    shadow.ImageColor3           = Color3.new(0, 0, 0)
    shadow.ImageTransparency     = 0.55
    shadow.ScaleType             = Enum.ScaleType.Slice
    shadow.SliceCenter           = Rect.new(23, 23, 277, 277)
    shadow.ZIndex                = 4
    shadow.Parent                = MainFrame
end

-- ── Title bar ─────────────────────────────────────────────────────────────────
local TitleBar                = Instance.new("Frame")
TitleBar.Name                 = "TitleBar"
TitleBar.Size                 = UDim2.new(1, 0, 0, _TITLE_H)
TitleBar.BackgroundColor3     = Color3.fromRGB(26, 26, 40)
TitleBar.BorderSizePixel      = 0
TitleBar.ZIndex               = 6
TitleBar.Parent               = MainFrame

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = TitleBar
end

local TitleLabel              = Instance.new("TextLabel")
TitleLabel.Text               = "  ⚔  TSB ULTIMATE  v2.2"
TitleLabel.Size               = UDim2.new(1, -50, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3         = Color3.fromRGB(210, 210, 255)
TitleLabel.TextSize           = _IsMobile and 12 or 14
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
TitleLabel.ZIndex             = 7
TitleLabel.Parent             = TitleBar

local MinBtn                  = Instance.new("TextButton")
MinBtn.Text                   = "—"
MinBtn.Size                   = UDim2.new(0, 28, 0, 20)
MinBtn.Position               = UDim2.new(1, -34, 0.5, -10)
MinBtn.BackgroundColor3       = Color3.fromRGB(55, 55, 85)
MinBtn.TextColor3             = Color3.fromRGB(210, 210, 255)
MinBtn.TextSize               = _IsMobile and 12 or 14
MinBtn.Font                   = Enum.Font.GothamBold
MinBtn.BorderSizePixel        = 0
MinBtn.ZIndex                 = 7
MinBtn.AutoButtonColor        = false
MinBtn.Parent                 = TitleBar

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = MinBtn
end

-- ── Scrollable content area ───────────────────────────────────────────────────
local Scroll                  = Instance.new("ScrollingFrame")
Scroll.Name                   = "Scroll"
Scroll.Size                   = UDim2.new(1, 0, 1, -_TITLE_H)
Scroll.Position               = UDim2.new(0, 0, 0, _TITLE_H)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness     = _IsMobile and 2 or 3
Scroll.ScrollBarImageColor3   = Color3.fromRGB(90, 90, 140)
Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Scroll.ZIndex                 = 6
Scroll.Parent                 = MainFrame

do
    local layout = Instance.new("UIListLayout")
    layout.Padding   = UDim.new(0, _IsMobile and 3 or 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent    = Scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, _IsMobile and 6 or 9)
    pad.PaddingRight  = UDim.new(0, _IsMobile and 6 or 9)
    pad.PaddingTop    = UDim.new(0, _IsMobile and 6 or 9)
    pad.PaddingBottom = UDim.new(0, _IsMobile and 6 or 9)
    pad.Parent        = Scroll
end

-- ── Drag: main window — mouse + touch ────────────────────────────────────────
do
    local dragging, dragStart, frameStart

    local function IsDragInput(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end

    TitleBar.InputBegan:Connect(function(i)
        if IsDragInput(i) then
            dragging   = true
            dragStart  = i.Position
            frameStart = MainFrame.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(i)
        if IsDragInput(i) then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = i.Position - dragStart
        MainFrame.Position = UDim2.new(
            frameStart.X.Scale, frameStart.X.Offset + delta.X,
            frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
        )
    end)
end

-- ── Minimize ──────────────────────────────────────────────────────────────────
local _guiExpanded = true
-- Activated works for both mouse click and touch tap (MouseButton1Click does NOT fire on touch)
MinBtn.Activated:Connect(function()
    _guiExpanded = not _guiExpanded
    Scroll.Visible = _guiExpanded
    MainFrame.Size = _guiExpanded
        and UDim2.new(0, _GUI_W, 0, _GUI_H)
        or  UDim2.new(0, _GUI_W, 0, _TITLE_H)
    MinBtn.Text = _guiExpanded and "—" or "+"
end)

-- ── GUI builder helpers ───────────────────────────────────────────────────────

-- Forward declaration: set in Section 5.5 once the mobile panel exists
local _mobileBarRefresh = nil

local _toggleUpdaters = {}

local function MakeSection(title)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, _SEC_H)
    f.BackgroundColor3 = Color3.fromRGB(36, 36, 58)
    f.BorderSizePixel  = 0
    f.ZIndex           = 7
    f.Parent           = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Text              = "  " .. title:upper()
    lbl.Size              = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = Color3.fromRGB(140, 140, 210)
    lbl.TextSize          = _HEAD_S
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.ZIndex            = 8
    lbl.Parent            = f
end

local function MakeToggle(label, configKey, keyHint)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, _ROW_H)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    row.BorderSizePixel  = 0
    row.ZIndex           = 7
    row.Parent           = Scroll

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 7)
        c.Parent = row
    end

    local lbl = Instance.new("TextLabel")
    lbl.Text           = label
    lbl.Size           = UDim2.new(1, -(_BTN_W + 50), 1, 0)
    lbl.Position       = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3     = Color3.fromRGB(195, 195, 220)
    lbl.TextSize       = _FONT_S
    lbl.Font           = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex         = 8
    lbl.Parent         = row

    if keyHint then
        local hint = Instance.new("TextLabel")
        hint.Text           = "[" .. keyHint .. "]"
        hint.Size           = UDim2.new(0, 34, 1, 0)
        hint.Position       = UDim2.new(1, -(_BTN_W + 40), 0, 0)
        hint.BackgroundTransparency = 1
        hint.TextColor3     = Color3.fromRGB(90, 90, 130)
        hint.TextSize       = _IsMobile and 9 or 10
        hint.Font           = Enum.Font.Gotham
        hint.ZIndex         = 8
        hint.Parent         = row
    end

    -- Use TextButton so Activated fires reliably on both mouse and touch
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, _BTN_W, 0, _BTN_H)
    btn.Position         = UDim2.new(1, -(_BTN_W + 6), 0.5, -math.floor(_BTN_H / 2))
    btn.BackgroundColor3 = Color3.fromRGB(75, 75, 100)
    btn.Text             = "OFF"
    btn.TextColor3       = Color3.fromRGB(170, 170, 195)
    btn.TextSize         = _BTN_FS
    btn.Font             = Enum.Font.GothamBold
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.ZIndex           = 9
    btn.Parent           = row

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = btn
    end

    local function Refresh()
        local on = Config.Toggles[configKey]
        btn.BackgroundColor3 = on
            and Color3.fromRGB(70, 195, 115)
            or  Color3.fromRGB(75, 75, 100)
        btn.Text       = on and "ON" or "OFF"
        btn.TextColor3 = on
            and Color3.fromRGB(255, 255, 255)
            or  Color3.fromRGB(170, 170, 195)
    end

    -- Activated fires for mouse click AND touch tap — MouseButton1Click does NOT on mobile
    btn.Activated:Connect(function()
        Config.Toggles[configKey] = not Config.Toggles[configKey]
        Refresh()
        Notify("TSB Script", label .. " → " .. (Config.Toggles[configKey] and "ON" or "OFF"))
        if _mobileBarRefresh then _mobileBarRefresh(configKey) end
    end)

    _toggleUpdaters[configKey] = Refresh
end

-- ── Build layout ──────────────────────────────────────────────────────────────
MakeSection("⚔  Combat Techs")
MakeToggle("Twisted Tech",             "TwistedTech",         "F1")
MakeToggle("Kyoto Combo (Q/E/R)",      "KyotoCombo",          "F2")
MakeToggle("Grasp Tech",               "GraspTech",           "F3")
MakeToggle("Uppercut Grasp  [T]",      "UppercutGrasp",       "F4")
MakeToggle("Lethal + Flowing  [G]",    "LethalFlowing",       "F5")
MakeToggle("Loop Tech",                "LoopTech",            "F6")

MakeSection("🛡  Defense")
MakeToggle("Auto Block",               "AutoBlock",           "F7")

MakeSection("⚡  Punish")
MakeToggle("Auto Punish (Front Dash)", "AutoPunishFrontDash", "F8")
MakeToggle("Auto M1 (Side Dash)",      "AutoM1SideDash",      "F9")

MakeSection("🎯  Lock On")
MakeToggle("Closest Player",           "LockOnClosest",       "F10")
MakeToggle("Closest to Cursor",        "LockOnCursor",        "F11")

MakeSection("👁  Visual")
MakeToggle("ESP Highlights",           "ESP",                 "F12")

MakeSection("📱  Mobile")
MakeToggle("Mobile Mode",              "MobileMode",          nil)

-- ── Status bar ────────────────────────────────────────────────────────────────
local StatusRow = Instance.new("Frame")
StatusRow.Size             = UDim2.new(1, 0, 0, _IsMobile and 22 or 26)
StatusRow.BackgroundColor3 = Color3.fromRGB(26, 26, 40)
StatusRow.BorderSizePixel  = 0
StatusRow.ZIndex           = 7
StatusRow.Parent           = Scroll

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = StatusRow
end

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text           = "  Status: Idle"
StatusLabel.Size           = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3     = Color3.fromRGB(90, 180, 110)
StatusLabel.TextSize       = _IsMobile and 10 or 11
StatusLabel.Font           = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex         = 8
StatusLabel.Parent         = StatusRow

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5.5 — MOBILE TECH PANEL
-- ═════════════════════════════════════════════════════════════════════════════
--
-- Large circular buttons styled to match TSB's native mobile controls.
-- Positioned on the LEFT side of the screen (native controls own the right).
-- Each button is only visible when:
--   (a) Mobile Mode is ON, AND
--   (b) The button's corresponding tech is toggled ON.
--
-- Tap → immediate action. A scale-pulse tween confirms every tap.
--
-- Button size: 82×82 px (well above the 44pt minimum touch target).

-- Button size constant
local MBTN = 82

-- Action table — populated after tech functions are defined in Section 6.5.
-- Keyed by the button's unique `id` string.
local _mobileActions = {}

-- Button definitions
-- Each button that shares a toggle key (e.g. the three Kyoto variants) has
-- a distinct `id` so they can be mapped to different actions.
local _mobileBtnDefs = {
    --  id        toggle key              icon    label (max ~9 chars)     accent color
    { id="TW",   key="TwistedTech",       icon="⚡", label="Twisted",      clr=Color3.fromRGB(220, 60,  60)  },
    { id="KY1",  key="KyotoCombo",        icon="水", label="Kyoto 1",      clr=Color3.fromRGB(70,  120, 240) },
    { id="KY2",  key="KyotoCombo",        icon="流", label="Kyoto 2",      clr=Color3.fromRGB(50,  90,  210) },
    { id="KYG",  key="KyotoCombo",        icon="握", label="Ky. Grasp",    clr=Color3.fromRGB(40,  70,  190) },
    { id="GR",   key="GraspTech",         icon="✊", label="Grasp",        clr=Color3.fromRGB(190, 130, 40)  },
    { id="UC",   key="UppercutGrasp",     icon="↑",  label="Upcut",        clr=Color3.fromRGB(190, 70,  180) },
    { id="LF",   key="LethalFlowing",     icon="🌊", label="Lethal+Fl",    clr=Color3.fromRGB(50,  180, 150) },
    { id="LP",   key="LoopTech",          icon="🔄", label="Loop",         clr=Color3.fromRGB(220, 140, 0)   },
    { id="BK",   key="AutoBlock",         icon="🛡", label="Block",        clr=Color3.fromRGB(60,  170, 220) },
    { id="PF",   key="AutoPunishFrontDash",icon="👊",label="Punish",       clr=Color3.fromRGB(170, 60,  90)  },
    { id="SM",   key="AutoM1SideDash",    icon="↗",  label="Side M1",      clr=Color3.fromRGB(140, 80,  190) },
    { id="L1",   key="LockOnClosest",     icon="🎯", label="Lock Cls",     clr=Color3.fromRGB(70,  190, 70)  },
    { id="L2",   key="LockOnCursor",      icon="🖱", label="Lock Cur",     clr=Color3.fromRGB(100, 210, 80)  },
}

-- Scrollable container on the left side so it doesn't conflict with the
-- native right-side controls (block/punch/dash/jump buttons).
local MobilePanel = Instance.new("ScrollingFrame")
MobilePanel.Name                   = "TSB_MobilePanel"
MobilePanel.Visible                = false
MobilePanel.BackgroundTransparency = 1
-- Occupy the left strip, starting below the top Roblox chrome (~80px)
MobilePanel.Size                   = UDim2.new(0, MBTN + 16, 1, -140)
MobilePanel.Position               = UDim2.new(0, 0, 0, 80)
MobilePanel.AnchorPoint            = Vector2.new(0, 0)
MobilePanel.ClipsDescendants       = true
MobilePanel.ScrollBarThickness     = 0        -- invisible scrollbar
MobilePanel.CanvasSize             = UDim2.new(0, 0, 0, 0)
MobilePanel.AutomaticCanvasSize    = Enum.AutomaticSize.Y
MobilePanel.ZIndex                 = 20
MobilePanel.Parent                 = ScreenGui

local MPLayout = Instance.new("UIListLayout")
MPLayout.Padding              = UDim.new(0, 8)
MPLayout.FillDirection        = Enum.FillDirection.Vertical
MPLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
MPLayout.VerticalAlignment    = Enum.VerticalAlignment.Top
MPLayout.SortOrder            = Enum.SortOrder.LayoutOrder
MPLayout.Parent               = MobilePanel

local MPPad = Instance.new("UIPadding")
MPPad.PaddingTop    = UDim.new(0, 6)
MPPad.PaddingBottom = UDim.new(0, 6)
MPPad.PaddingLeft   = UDim.new(0, 8)
MPPad.PaddingRight  = UDim.new(0, 8)
MPPad.Parent        = MobilePanel

-- ── Shared tap-pulse tween ────────────────────────────────────────────────────
-- Shrinks the button briefly then springs back so the user feels their tap.
local function PulseTap(btn)
    local fullSize = UDim2.new(0, MBTN, 0, MBTN)
    local shrink   = UDim2.new(0, MBTN * 0.82, 0, MBTN * 0.82)
    local t1 = TweenService:Create(btn,
        TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = shrink })
    local t2 = TweenService:Create(btn,
        TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = fullSize })
    t1:Play()
    t1.Completed:Connect(function() t2:Play() end)
end

-- ── Build mobile buttons ──────────────────────────────────────────────────────
local _mobileBtnObjs = {}   -- [i] = ImageButton

for i, def in ipairs(_mobileBtnDefs) do

    -- Use ImageButton: Activated fires reliably on touch AND mouse
    local btn = Instance.new("ImageButton")
    btn.Name                  = "TSBMBtn_" .. def.id
    btn.Size                  = UDim2.new(0, MBTN, 0, MBTN)
    btn.BackgroundColor3      = def.clr
    btn.BackgroundTransparency = 0.28
    btn.Image                 = ""
    btn.BorderSizePixel       = 0
    btn.LayoutOrder           = i
    btn.ZIndex                = 21
    btn.Visible               = false   -- shown by RefreshMobileBar
    btn.AutoButtonColor       = false   -- disable default darkening; we do pulse instead
    btn.Parent                = MobilePanel

    -- Perfect circle
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = btn
    end

    -- Subtle white ring — matches TSB native button style
    do
        local s = Instance.new("UIStroke")
        s.Color        = Color3.fromRGB(255, 255, 255)
        s.Thickness    = 1.8
        s.Transparency = 0.55
        s.Parent       = btn
    end

    -- Large centered icon (emoji / Unicode symbol)
    local iconLbl = Instance.new("TextLabel")
    iconLbl.Text                 = def.icon
    iconLbl.Size                 = UDim2.new(1, 0, 0.54, 0)
    iconLbl.Position             = UDim2.new(0, 0, 0.06, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.TextColor3           = Color3.fromRGB(255, 255, 255)
    iconLbl.TextSize             = 28
    iconLbl.Font                 = Enum.Font.GothamBold
    iconLbl.TextStrokeTransparency = 0.25
    iconLbl.ZIndex               = 22
    iconLbl.Parent               = btn

    -- Short name below the icon
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text                 = def.label
    nameLbl.Size                 = UDim2.new(1, -8, 0.32, 0)
    nameLbl.Position             = UDim2.new(0, 4, 0.64, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3           = Color3.fromRGB(245, 245, 255)
    nameLbl.TextSize             = 11
    nameLbl.Font                 = Enum.Font.Gotham
    nameLbl.TextScaled           = true
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.ZIndex               = 22
    nameLbl.Parent               = btn

    -- Activated — the ONLY reliable cross-platform tap/click event
    btn.Activated:Connect(function()
        PulseTap(btn)
        local fn = _mobileActions[def.id]
        if fn then
            local target = State.LockTarget or GetClosestEnemy()
            task.spawn(function() pcall(fn, target) end)
        end
    end)

    _mobileBtnObjs[i] = btn
end

-- ── Refresh: show/hide buttons based on current toggle states ─────────────────
local function RefreshMobileBar(_changedKey)
    if not Config.Toggles.MobileMode then
        MobilePanel.Visible = false
        return
    end

    local anyVisible = false
    for i, def in ipairs(_mobileBtnDefs) do
        local show = Config.Toggles[def.key] == true
        _mobileBtnObjs[i].Visible = show
        if show then anyVisible = true end
    end
    MobilePanel.Visible = anyVisible
end

-- Wire refresh callback so MakeToggle can call it
_mobileBarRefresh = RefreshMobileBar

-- Override MobileMode's updater so toggling it triggers a full refresh
local _origMobileModeUpdater = _toggleUpdaters["MobileMode"]
_toggleUpdaters["MobileMode"] = function()
    if _origMobileModeUpdater then _origMobileModeUpdater() end
    RefreshMobileBar("MobileMode")
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 6 — TECH FUNCTIONS
-- ═════════════════════════════════════════════════════════════════════════════

-- ── Twisted Tech ──────────────────────────────────────────────────────────────
local _twistedBusy = false

local function PerformTwistedTech(target)
    if _twistedBusy or not Config.Toggles.TwistedTech then return end
    if not IsAlive() then return end

    _twistedBusy = true
    task.spawn(function()
        task.wait(Jitter(0.05))

        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if myRoot and tRoot then
            local backDir = (myRoot.Position - tRoot.Position).Unit
            pcall(function()
                myRoot.AssemblyLinearVelocity =
                    backDir * Config.Settings.HumbledBackForce
            end)
        end

        task.wait(Jitter(Config.Settings.TwistedWindow))

        if myRoot and tRoot then
            myRoot.CFrame = CFrame.new(
                myRoot.Position,
                Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
            )
        end

        DoAction("FrontDash")
        State.LastDashTime  = tick()
        State.DashDirection = "Front"
        State.M1Count       = 0

        task.wait(Jitter(Config.Settings.DashDelay))
        _twistedBusy = false
    end)
end

-- ── Kyoto Combo ───────────────────────────────────────────────────────────────
local _kyotoPhase = 0

local function PerformKyotoCombo(target, variant)
    if not Config.Toggles.KyotoCombo then return end
    if not IsAlive() or _kyotoPhase ~= 0 then return end

    _kyotoPhase = 1
    task.spawn(function()
        DoAction("FlowingWater")
        State.InSkill       = true
        State.LastSkillUsed = "FlowingWater"

        task.wait(Jitter(Config.Settings.KyotoWindow))

        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)

        if variant == 1 then
            DoAction("BackDash")
            State.DashDirection = "Back"
            task.wait(Jitter(0.14))
            if myRoot and tRoot then
                myRoot.CFrame = CFrame.new(
                    myRoot.Position,
                    Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
                )
            end
            DoAction("FrontDash")
            State.DashDirection = "Front"

        elseif variant == 2 then
            DoAction("SideDash")
            State.DashDirection = "Side"
            task.wait(Jitter(0.10))
            DoAction("LethalWhirlwindStream")
            State.LastSkillUsed = "LethalWhirlwindStream"
            task.wait(Jitter(0.18))
            DoAction("M1")

        elseif variant == 3 then
            DoAction("SideDash")
            State.DashDirection = "Side"
            task.wait(Jitter(0.08))
            DoAction("HuntersGrasp")
            State.LastSkillUsed = "HuntersGrasp"
        end

        task.wait(Jitter(0.22))
        State.InSkill = false
        _kyotoPhase   = 0
    end)
end

-- ── Grasp Tech ────────────────────────────────────────────────────────────────
local _graspCD = false

local function PerformGraspTech(target)
    if not Config.Toggles.GraspTech or _graspCD then return end
    if not IsAlive() or not target then return end

    local tChar = target.Character
    if not tChar then return end

    local tHum    = tChar:FindFirstChildOfClass("Humanoid")
    local ragFlag = tChar:FindFirstChild("Ragdoll") or tChar:FindFirstChild("IsRagdoll")
    local vulnerable = (ragFlag and ragFlag.Value)
        or (tHum and tHum:GetState() == Enum.HumanoidStateType.FallingDown)

    if not vulnerable then return end

    _graspCD = true
    task.spawn(function()
        task.wait(Jitter(0.06))
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if myRoot and tRoot then
            local dist = Distance(myRoot.Position, tRoot.Position)
            if dist <= 14 then
                DoAction("HuntersGrasp")
            else
                DoAction("CrushingPull")
            end
            State.LastSkillUsed = dist <= 14 and "HuntersGrasp" or "CrushingPull"
        end
        task.wait(1.6)
        _graspCD = false
    end)
end

-- ── Uppercut Grasp ────────────────────────────────────────────────────────────
local _upcutCD = false

local function PerformUppercutGrasp(target)
    if not Config.Toggles.UppercutGrasp or _upcutCD then return end
    if not IsAlive() or not target then return end

    _upcutCD = true
    task.spawn(function()
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if not myRoot or not tRoot then _upcutCD = false return end

        myRoot.CFrame = CFrame.new(
            myRoot.Position,
            Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
        )

        local hum = GetHumanoid()
        if hum then hum.Jump = true end

        task.wait(Jitter(0.09))
        DoAction("Uppercut")
        DoAction("M1")

        task.wait(Jitter(0.13))
        DoAction("HuntersGrasp")
        State.LastSkillUsed = "HuntersGrasp"

        task.wait(Jitter(1.9))
        _upcutCD = false
    end)
end

-- ── Lethal + Flowing ──────────────────────────────────────────────────────────
local _lethalFlowCD = false

local function PerformLethalFlowing()
    if not Config.Toggles.LethalFlowing or _lethalFlowCD then return end
    if not IsAlive() then return end

    _lethalFlowCD = true
    task.spawn(function()
        DoAction("LethalWhirlwindStream")
        State.LastSkillUsed = "LethalWhirlwindStream"
        State.InSkill       = true

        task.wait(Jitter(Config.Settings.SkillDelay + 0.08))
        DoAction("SideDash")
        State.DashDirection = "Side"

        task.wait(Jitter(0.11))
        DoAction("FlowingWater")
        State.LastSkillUsed = "FlowingWater"

        task.wait(Jitter(0.20))
        DoAction("SideDash")

        task.wait(Jitter(0.09))
        DoAction("M1")

        task.wait(Jitter(2.2))
        State.InSkill = false
        _lethalFlowCD = false
    end)
end

-- ── Loop Tech ─────────────────────────────────────────────────────────────────
local _loopRunning = false

local function StartLoopTech(target)
    if _loopRunning then return end
    _loopRunning = true

    task.spawn(function()
        local phase = 0
        while Config.Toggles.LoopTech and IsAlive() and _loopRunning do
            local tRoot  = GetPlayerRoot(target)
            local myRoot = GetRoot()
            if not tRoot or not myRoot then break end

            myRoot.CFrame = CFrame.new(
                myRoot.Position,
                Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
            )

            if phase % 3 == 0 then
                DoAction("SideDash")
            elseif phase % 3 == 1 then
                DoAction("FrontDash")
                task.wait(Jitter(0.04))
                DoAction("M1")
            else
                DoAction("BackDash")
            end
            phase = phase + 1

            State.LastDashTime = tick()
            task.wait(Jitter(Config.Settings.LoopDashInterval))
        end
        _loopRunning = false
    end)
end

local function StopLoopTech()
    _loopRunning = false
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 6.5 — MOBILE ACTION TABLE
-- Populated here so all tech functions above are already in scope.
-- Keys match _mobileBtnDefs[i].id (unique per button).
-- ═════════════════════════════════════════════════════════════════════════════

_mobileActions = {
    ["TW"]  = function(t) PerformTwistedTech(t) end,

    ["KY1"] = function(t) PerformKyotoCombo(t, 1) end,
    ["KY2"] = function(t) PerformKyotoCombo(t, 2) end,
    ["KYG"] = function(t) PerformKyotoCombo(t, 3) end,

    ["GR"]  = function(t) PerformGraspTech(t) end,

    ["UC"]  = function(t) PerformUppercutGrasp(t) end,

    ["LF"]  = function(_) PerformLethalFlowing() end,

    -- Loop Tech button toggles the loop
    ["LP"]  = function(t)
        if _loopRunning then
            StopLoopTech()
        else
            StartLoopTech(t or GetClosestEnemy())
        end
    end,

    -- Auto Block is passive — button just serves as a visual reminder
    ["BK"]  = function(_) end,

    -- Manual punish burst (same logic as auto but triggered on demand)
    ["PF"]  = function(t)
        if not IsAlive() or not t then return end
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(t)
        if not myRoot or not tRoot then return end
        if Distance(myRoot.Position, tRoot.Position) <= Config.Settings.PunishHitRange then
            DoAction("M1")
            task.wait(Jitter(Config.Settings.M1Interval))
            DoAction("M1")
        end
    end,

    -- Manual side-dash M1 burst
    ["SM"]  = function(t)
        if not IsAlive() or not t then return end
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(t)
        if not myRoot or not tRoot then return end
        myRoot.CFrame = CFrame.new(myRoot.Position,
            Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
        DoAction("M1")
        task.wait(Jitter(Config.Settings.M1Interval))
        DoAction("M1")
    end,

    -- Lock On buttons: snap to target immediately
    ["L1"]  = function(_)
        local e = GetClosestEnemy()
        if e then State.LockTarget = e end
    end,

    ["L2"]  = function(_)
        local e = GetCursorEnemy()
        if e then State.LockTarget = e end
    end,
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 7 — AUTO BLOCK
-- ═════════════════════════════════════════════════════════════════════════════

local _blockCD = false

local function CheckAutoBlock()
    if not Config.Toggles.AutoBlock or not IsAlive() or _blockCD then return end

    local myRoot = GetRoot()
    if not myRoot then return end

    for _, enemy in ipairs(GetEnemies()) do
        local eRoot = GetPlayerRoot(enemy)
        if not eRoot then continue end

        local dist = Distance(myRoot.Position, eRoot.Position)
        if dist > Config.Settings.AutoBlockRange then continue end

        local vel      = eRoot.AssemblyLinearVelocity
        local toMe     = (myRoot.Position - eRoot.Position).Unit
        local speed    = vel.Magnitude
        local approach = speed > 0 and vel.Unit:Dot(toMe) or 0

        local attackDetected = (approach > 0.4 and speed > 18)

        if not attackDetected then
            local eChar = enemy.Character
            local anim  = eChar and eChar:FindFirstChild("Animator", true)
            if anim then
                for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                    local n = track.Name:lower()
                    if n:find("m1") or n:find("punch") or n:find("attack") then
                        attackDetected = true
                        break
                    end
                end
            end
        end

        if attackDetected then
            _blockCD = true
            DoAction("Block", true)
            State.IsBlocking = true
            task.spawn(function()
                task.wait(Jitter(0.50))
                DoAction("Block", false)
                State.IsBlocking = false
                task.wait(0.08)
                _blockCD = false
            end)
            return
        end
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 8 — AUTO PUNISH SYSTEMS
-- ═════════════════════════════════════════════════════════════════════════════

local function AutoPunishFrontDash(target)
    if not Config.Toggles.AutoPunishFrontDash or not IsAlive() or not target then return end
    task.spawn(function()
        task.wait(Jitter(0.07))
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if myRoot and tRoot and Distance(myRoot.Position, tRoot.Position) <= Config.Settings.PunishHitRange then
            DoAction("M1")
            task.wait(Jitter(Config.Settings.M1Interval))
            DoAction("M1")
        end
    end)
end

local function AutoM1AfterSideDash(target)
    if not Config.Toggles.AutoM1SideDash or not IsAlive() or not target then return end
    task.spawn(function()
        task.wait(Jitter(0.08))
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if myRoot and tRoot and Distance(myRoot.Position, tRoot.Position) <= Config.Settings.PunishHitRange then
            myRoot.CFrame = CFrame.new(myRoot.Position,
                Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
            DoAction("M1")
            task.wait(Jitter(Config.Settings.M1Interval))
            DoAction("M1")
        end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 9 — LOCK ON SYSTEMS
-- ═════════════════════════════════════════════════════════════════════════════

local LockTarget1 = nil
local LockTarget2 = nil

local function UpdateLockOnClosest()
    if not Config.Toggles.LockOnClosest then LockTarget1 = nil return end
    LockTarget1 = GetClosestEnemy()
    if not LockTarget1 then return end
    local tRoot = GetPlayerRoot(LockTarget1)
    if not tRoot then return end
    local lookDir = (tRoot.Position - Camera.CFrame.Position).Unit
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookDir)
end

local function UpdateLockOnCursor()
    if not Config.Toggles.LockOnCursor then LockTarget2 = nil return end
    LockTarget2 = GetCursorEnemy()
    if not LockTarget2 then return end
    local tRoot = GetPlayerRoot(LockTarget2)
    if not tRoot then return end
    local lookDir = (tRoot.Position - Camera.CFrame.Position).Unit
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookDir)
end

local function GetLockTarget()
    if Config.Toggles.LockOnClosest and LockTarget1 then return LockTarget1 end
    if Config.Toggles.LockOnCursor  and LockTarget2 then return LockTarget2 end
    return GetClosestEnemy()
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 10 — ESP SYSTEM
-- ═════════════════════════════════════════════════════════════════════════════

local _espObjects = {}

local function RemoveESPFor(player)
    local objs = _espObjects[player]
    if objs then
        for _, obj in ipairs(objs) do pcall(obj.Destroy, obj) end
        _espObjects[player] = nil
    end
end

local function CreateESPFor(player)
    if _espObjects[player] then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local box               = Instance.new("SelectionBox")
    box.SurfaceTransparency = Config.Settings.ESPTransparency
    box.SurfaceColor3       = Config.Settings.ESPColor
    box.LineThickness       = 0.04
    box.Color3              = Config.Settings.ESPColor
    box.Adornee             = char
    box.Parent              = CoreGui

    local bb                = Instance.new("BillboardGui")
    bb.Adornee              = root
    bb.AlwaysOnTop          = true
    bb.Size                 = UDim2.new(0, 90, 0, 22)
    bb.StudsOffset          = Vector3.new(0, 3.2, 0)
    bb.Parent               = CoreGui

    local nlbl              = Instance.new("TextLabel")
    nlbl.Text               = player.Name
    nlbl.Size               = UDim2.new(1, 0, 1, 0)
    nlbl.BackgroundTransparency = 1
    nlbl.TextColor3         = Config.Settings.ESPColor
    nlbl.TextSize           = 13
    nlbl.Font               = Enum.Font.GothamBold
    nlbl.TextStrokeTransparency = 0.4
    nlbl.Parent             = bb

    _espObjects[player] = {box, bb}
end

local function ClearAllESP()
    for player in pairs(_espObjects) do RemoveESPFor(player) end
end

local function UpdateESP()
    if not Config.Toggles.ESP then ClearAllESP() return end
    for _, p in ipairs(GetEnemies()) do CreateESPFor(p) end
    for player in pairs(_espObjects) do
        if not GetPlayerRoot(player) then RemoveESPFor(player) end
    end
end

Connect(Players.PlayerRemoving, function(p) RemoveESPFor(p) end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 11 — INPUT / KEYBIND HANDLER
-- ═════════════════════════════════════════════════════════════════════════════

Connect(UserInputService.InputBegan, function(inp, gameProc)
    if gameProc then return end

    -- F-key feature toggles
    for name, keyCode in pairs(Config.Keybinds) do
        if inp.KeyCode == keyCode and name ~= "ToggleGUI" then
            if Config.Toggles[name] ~= nil then
                Config.Toggles[name] = not Config.Toggles[name]
                local upd = _toggleUpdaters[name]
                if upd then upd() end
                Notify("TSB Script",
                    name .. " → " .. (Config.Toggles[name] and "ON" or "OFF"))
                if _mobileBarRefresh then _mobileBarRefresh(name) end

                if name == "LoopTech" then
                    if Config.Toggles.LoopTech then
                        local t = GetLockTarget()
                        if t then StartLoopTech(t) end
                    else
                        StopLoopTech()
                    end
                end
            end
        end
    end

    if inp.KeyCode == Config.Keybinds.ToggleGUI then
        MainFrame.Visible = not MainFrame.Visible
    end

    -- Keyboard burst keys
    local target = GetLockTarget()
    if Config.Toggles.KyotoCombo then
        if inp.KeyCode == Enum.KeyCode.Q then
            PerformKyotoCombo(target, 1)
        elseif inp.KeyCode == Enum.KeyCode.E then
            PerformKyotoCombo(target, 2)
        elseif inp.KeyCode == Enum.KeyCode.R then
            PerformKyotoCombo(target, 3)
        end
    end

    if inp.KeyCode == Enum.KeyCode.G and Config.Toggles.LethalFlowing then
        PerformLethalFlowing()
    end

    if inp.KeyCode == Enum.KeyCode.T and Config.Toggles.UppercutGrasp then
        PerformUppercutGrasp(target)
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 12 — MAIN HEARTBEAT LOOP
-- ═════════════════════════════════════════════════════════════════════════════

local _hbFrame = 0

Connect(RunService.Heartbeat, function()
    _hbFrame = _hbFrame + 1

    if Config.Toggles.AutoBlock then CheckAutoBlock() end

    if _hbFrame % 2 == 0 then
        UpdateLockOnClosest()
        UpdateLockOnCursor()
        State.LockTarget = GetLockTarget()
    end

    if _hbFrame % 3 == 0 then
        if tick() - State.LastM1Time > 3.0 then State.M1Count = 0 end

        if IsAnimationPlaying("m1") or IsAnimationPlaying("punch") or
           IsAnimationPlaying("attack") then
            local now = tick()
            if now - State.LastM1Time >= 0.20 then
                State.M1Count    = (State.M1Count % 4) + 1
                State.LastM1Time = now
                local target     = State.LockTarget

                if State.M1Count == 4 and Config.Toggles.TwistedTech then
                    PerformTwistedTech(target)
                end
                if Config.Toggles.GraspTech and target then
                    PerformGraspTech(target)
                end
            end
        end
    end

    if _hbFrame % 4 == 0 then
        local now    = tick()
        local target = State.LockTarget

        if IsAnimationPlaying("frontdash") or IsAnimationPlaying("front_dash") then
            if now - State.LastDashTime > 0.3 then
                State.LastDashTime  = now
                State.DashDirection = "Front"
                AutoPunishFrontDash(target)
            end
        end

        if IsAnimationPlaying("sidedash") or IsAnimationPlaying("side_dash") then
            if now - State.LastDashTime > 0.3 then
                State.LastDashTime  = now
                State.DashDirection = "Side"
                AutoM1AfterSideDash(target)
            end
        end

        State.IsRagdolled = IsRagdolled()
    end

    if _hbFrame % 12 == 0 then UpdateESP() end

    if _hbFrame % 30 == 0 then
        local T = Config.Toggles
        local on = {}
        if T.TwistedTech         then on[#on+1] = "Twisted"  end
        if T.KyotoCombo          then on[#on+1] = "Kyoto"    end
        if T.GraspTech           then on[#on+1] = "Grasp"    end
        if T.UppercutGrasp       then on[#on+1] = "Upcut"    end
        if T.LethalFlowing       then on[#on+1] = "L+F"      end
        if T.LoopTech            then on[#on+1] = "Loop"     end
        if T.AutoBlock           then on[#on+1] = "Block"    end
        if T.AutoPunishFrontDash then on[#on+1] = "Punish"   end
        if T.AutoM1SideDash      then on[#on+1] = "SideM1"   end
        if T.LockOnClosest       then on[#on+1] = "Lock1"    end
        if T.LockOnCursor        then on[#on+1] = "Lock2"    end
        if T.ESP                 then on[#on+1] = "ESP"       end
        if T.MobileMode          then on[#on+1] = "📱"         end

        if #on == 0 then
            StatusLabel.Text       = "  Status: Idle (all off)"
            StatusLabel.TextColor3 = Color3.fromRGB(130, 130, 160)
        else
            StatusLabel.Text       = "  ▸ " .. table.concat(on, " | ")
            StatusLabel.TextColor3 = Color3.fromRGB(90, 200, 120)
        end
    end

    if Config.Toggles.LoopTech and not _loopRunning then
        local t = GetLockTarget()
        if t then StartLoopTech(t) end
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 13 — CHARACTER RESPAWN HANDLER
-- ═════════════════════════════════════════════════════════════════════════════

local function OnCharacterAdded(char)
    ResetState()
    _twistedBusy  = false
    _graspCD      = false
    _upcutCD      = false
    _lethalFlowCD = false
    _blockCD      = false
    _loopRunning  = false
    _kyotoPhase   = 0
    LockTarget1   = nil
    LockTarget2   = nil

    task.wait(1.5)
    Notify("TSB Script", "Character loaded — all systems active", 4)
end

Connect(LocalPlayer.CharacterAdded, OnCharacterAdded)
if LocalPlayer.Character then
    task.spawn(function() OnCharacterAdded(LocalPlayer.Character) end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 14 — INITIALIZATION
-- ═════════════════════════════════════════════════════════════════════════════

task.delay(2, function()
    local known = {
        "M1","FrontDash","BackDash","SideDash","Block",
        "FlowingWater","LethalWhirlwindStream","HuntersGrasp",
        "CrushingPull","Uppercut",
    }
    for _, name in ipairs(known) do FindRemote(name) end
end)

-- Sync mobile bar to initial toggle states
task.defer(function() RefreshMobileBar("init") end)

Notify(
    "TSB Ultimate v2.2 Loaded",
    "RCtrl=GUI | F1-F12=Features | Enable Mobile Mode in 📱 tab | Q/E/R/G/T=Bursts",
    8
)

print("[TSB Ultimate v2.2] Initialized — "
    .. (_IsMobile and "MOBILE" or "DESKTOP")
    .. " layout  |  IgnoreGuiInset active")
