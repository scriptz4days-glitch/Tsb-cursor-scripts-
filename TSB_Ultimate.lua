--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║              TSB ULTIMATE SCRIPT  —  The Strongest Battlegrounds            ║
║                                                                              ║
║  Compatible: Delta Executor, Fluxus, Solara, Arceus X, and most others      ║
║  Author   : TSB Script Team                                                  ║
║  Version  : 2.1  (Mobile Mode + responsive GUI)                             ║
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
║   ✦ Mobile Mode — floating draggable on-screen tech buttons                 ║
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

  COMBO BURST KEYS (active while their toggle is ON)
  ───────────────────────────────────────────────────
  Q    Kyoto One   (Flowing Water → back-dash cancel → re-engage)
  E    Kyoto Two   (Flowing Water → side-dash cancel → Lethal)
  R    Kyoto Grasp (Flowing Water → side-dash cancel → Hunter's Grasp)
  G    Lethal + Flowing burst sequence
  T    Uppercut Grasp

  MOBILE MODE
  ───────────────────────────────────────────────────
  Enable "Mobile Mode" in the 📱 section of the GUI.
  A draggable button bar will appear showing a tap button for every
  tech that is currently toggled ON. Buttons respect touch and mouse.
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

-- ── Duplicate-load guard (executor-safe) ──────────────────────────────────────
local _env = (typeof(getgenv) == "function" and getgenv()) or {}
if _env._TSB_LOADED then
    warn("[TSB] Script already loaded — run _env._TSB_LOADED = false to reload.")
    return
end
_env._TSB_LOADED = true

-- ── Mobile / device detection ─────────────────────────────────────────────────
-- TouchEnabled is true on phones and tablets; we use it to auto-scale the GUI.
local _IsMobile     = UserInputService.TouchEnabled
local _ViewportSize = Camera.ViewportSize

-- Responsive dimension constants — all GUI pixel sizes reference these.
local _GUI_W   = _IsMobile and 255 or 330   -- window width
local _GUI_H   = _IsMobile and 410 or 500   -- window expanded height
local _TITLE_H = _IsMobile and 32  or 38    -- title bar height
local _ROW_H   = _IsMobile and 28  or 34    -- toggle row height
local _SEC_H   = _IsMobile and 21  or 26    -- section header height
local _FONT_S  = _IsMobile and 11  or 13    -- toggle label font size
local _HEAD_S  = _IsMobile and 10  or 11    -- section header font size
local _BTN_W   = _IsMobile and 40  or 48    -- pill button width
local _BTN_H   = _IsMobile and 20  or 22    -- pill button height
local _BTN_FS  = _IsMobile and 10  or 11    -- pill button font size

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 2 — CONFIGURATION
-- ═════════════════════════════════════════════════════════════════════════════

local Config = {

    -- Toggle states (all start OFF for safety)
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
        MobileMode           = false,  -- enables the floating on-screen button bar
    },

    -- F-key keybinds for toggling each feature
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
        -- MobileMode has no keybind — use the GUI toggle
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

local ScreenGui         = Instance.new("ScreenGui")
ScreenGui.Name          = "TSB_GUI"
ScreenGui.ResetOnSpawn  = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- ── Main window ───────────────────────────────────────────────────────────────
local MainFrame                = Instance.new("Frame")
MainFrame.Name                 = "MainFrame"
MainFrame.Size                 = UDim2.new(0, _GUI_W, 0, _GUI_H)
MainFrame.Position             = UDim2.new(0, 12, 0.5, -math.floor(_GUI_H / 2))
MainFrame.BackgroundColor3     = Color3.fromRGB(14, 14, 20)
MainFrame.BorderSizePixel      = 0
MainFrame.ClipsDescendants     = true
MainFrame.Parent               = ScreenGui

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
    shadow.ZIndex                = -1
    shadow.Parent                = MainFrame
end

-- ── Title bar ─────────────────────────────────────────────────────────────────
local TitleBar             = Instance.new("Frame")
TitleBar.Name              = "TitleBar"
TitleBar.Size              = UDim2.new(1, 0, 0, _TITLE_H)
TitleBar.BackgroundColor3  = Color3.fromRGB(26, 26, 40)
TitleBar.BorderSizePixel   = 0
TitleBar.Parent            = MainFrame

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = TitleBar
end

local TitleLabel               = Instance.new("TextLabel")
TitleLabel.Text                = "  ⚔  TSB ULTIMATE  v2.1"
TitleLabel.Size                = UDim2.new(1, -50, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3          = Color3.fromRGB(210, 210, 255)
TitleLabel.TextSize            = _IsMobile and 12 or 14
TitleLabel.Font                = Enum.Font.GothamBold
TitleLabel.TextXAlignment      = Enum.TextXAlignment.Left
TitleLabel.Parent              = TitleBar

local MinBtn                   = Instance.new("TextButton")
MinBtn.Text                    = "—"
MinBtn.Size                    = UDim2.new(0, 28, 0, 20)
MinBtn.Position                = UDim2.new(1, -34, 0.5, -10)
MinBtn.BackgroundColor3        = Color3.fromRGB(55, 55, 85)
MinBtn.TextColor3              = Color3.fromRGB(210, 210, 255)
MinBtn.TextSize                = _IsMobile and 12 or 14
MinBtn.Font                    = Enum.Font.GothamBold
MinBtn.BorderSizePixel         = 0
MinBtn.Parent                  = TitleBar

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = MinBtn
end

-- ── Scrollable content area ───────────────────────────────────────────────────
local Scroll                   = Instance.new("ScrollingFrame")
Scroll.Name                    = "Scroll"
Scroll.Size                    = UDim2.new(1, 0, 1, -_TITLE_H)
Scroll.Position                = UDim2.new(0, 0, 0, _TITLE_H)
Scroll.BackgroundTransparency  = 1
Scroll.ScrollBarThickness      = _IsMobile and 2 or 3
Scroll.ScrollBarImageColor3    = Color3.fromRGB(90, 90, 140)
Scroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
Scroll.Parent                  = MainFrame

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

-- ── Draggable title bar — supports both mouse and touch ───────────────────────
do
    local dragging, dragStart, frameStart

    local function IsDragInput(inp)
        return inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch
    end
    local function IsMovInput(inp)
        return inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch
    end

    TitleBar.InputBegan:Connect(function(inp)
        if IsDragInput(inp) then
            dragging   = true
            dragStart  = inp.Position
            frameStart = MainFrame.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if IsDragInput(inp) then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and IsMovInput(inp) then
            local delta = inp.Position - dragStart
            MainFrame.Position = UDim2.new(
                frameStart.X.Scale, frameStart.X.Offset + delta.X,
                frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
            )
        end
    end)
end

-- ── Minimize toggle ───────────────────────────────────────────────────────────
local _guiExpanded = true
MinBtn.MouseButton1Click:Connect(function()
    _guiExpanded = not _guiExpanded
    Scroll.Visible = _guiExpanded
    MainFrame.Size = _guiExpanded
        and UDim2.new(0, _GUI_W, 0, _GUI_H)
        or  UDim2.new(0, _GUI_W, 0, _TITLE_H)
    MinBtn.Text = _guiExpanded and "—" or "+"
end)

-- ── GUI builder helpers ───────────────────────────────────────────────────────

-- Forward declaration: mobile bar refresh callback, set in Section 5.5
local _mobileBarRefresh = nil  -- function(changedKey) — called after each toggle

local _toggleUpdaters = {}   -- [configKey] → function() to refresh visual

local function MakeSection(title)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, _SEC_H)
    f.BackgroundColor3 = Color3.fromRGB(36, 36, 58)
    f.BorderSizePixel  = 0
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
    lbl.Parent            = f
end

local function MakeToggle(label, configKey, keyHint)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, _ROW_H)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    row.BorderSizePixel  = 0
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
        hint.Parent         = row
    end

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, _BTN_W, 0, _BTN_H)
    btn.Position         = UDim2.new(1, -(_BTN_W + 6), 0.5, -math.floor(_BTN_H / 2))
    btn.BackgroundColor3 = Color3.fromRGB(75, 75, 100)
    btn.Text             = "OFF"
    btn.TextColor3       = Color3.fromRGB(170, 170, 195)
    btn.TextSize         = _BTN_FS
    btn.Font             = Enum.Font.GothamBold
    btn.BorderSizePixel  = 0
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

    btn.MouseButton1Click:Connect(function()
        Config.Toggles[configKey] = not Config.Toggles[configKey]
        Refresh()
        Notify("TSB Script", label .. " → " .. (Config.Toggles[configKey] and "ON" or "OFF"))
        -- Notify mobile bar so it can show/hide the corresponding button
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
StatusLabel.Parent         = StatusRow

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 5.5 — MOBILE BAR (on-screen floating tech buttons)
-- ═════════════════════════════════════════════════════════════════════════════
--
-- When Mobile Mode is ON, a draggable button panel appears with one circular
-- button per tech that is currently toggled ON in the main GUI.
-- Tapping a button executes that tech's action once (burst / trigger).
--
-- Layout: 3-column grid, 64×64 buttons, 6 px gaps.
-- The bar is positioned at the bottom-center of the screen by default.

-- Action table — populated AFTER tech functions are defined (Section 6).
-- Keys match Config.Toggles keys. Values are called with (target) on tap.
local _mobileActions = {}   -- [configKey] = function(target)

-- Visual metadata for each button
local _mobileButtonDefs = {
    { key = "TwistedTech",         label = "TW",   shortName = "Twisted",     color = Color3.fromRGB(230, 70,  70)  },
    { key = "KyotoCombo",          label = "KY1",  shortName = "Kyoto 1",     color = Color3.fromRGB(90,  140, 255) },
    { key = "KyotoCombo",          label = "KY2",  shortName = "Kyoto 2",     color = Color3.fromRGB(70,  110, 230) },
    { key = "KyotoCombo",          label = "KYG",  shortName = "Kyoto Grsp",  color = Color3.fromRGB(50,  80,  200) },
    { key = "GraspTech",           label = "GR",   shortName = "Grasp",       color = Color3.fromRGB(200, 140, 50)  },
    { key = "UppercutGrasp",       label = "UC",   shortName = "Upcut Grsp",  color = Color3.fromRGB(210, 90,  190) },
    { key = "LethalFlowing",       label = "L+F",  shortName = "Lethal+Flow", color = Color3.fromRGB(80,  200, 160) },
    { key = "LoopTech",            label = "LP",   shortName = "Loop",        color = Color3.fromRGB(255, 165, 0)   },
    { key = "AutoBlock",           label = "BK",   shortName = "Block",       color = Color3.fromRGB(60,  170, 220) },
    { key = "AutoPunishFrontDash", label = "PF",   shortName = "Punish F",    color = Color3.fromRGB(180, 80,  110) },
    { key = "AutoM1SideDash",      label = "SM",   shortName = "Side M1",     color = Color3.fromRGB(160, 100, 200) },
    { key = "LockOnClosest",       label = "L1",   shortName = "Lock Cls",    color = Color3.fromRGB(100, 220, 80)  },
    { key = "LockOnCursor",        label = "L2",   shortName = "Lock Cur",    color = Color3.fromRGB(140, 240, 100) },
}

-- The button objects, indexed by _mobileButtonDefs position
local _mobileButtonObjs = {}   -- [defIndex] = TextButton

local MBTN_SIZE = 64   -- px per button (touch-friendly)
local MBTN_GAP  = 6    -- px gap between buttons
local MCOLS     = 3    -- buttons per row

-- ── Container frame ──────────────────────────────────────────────────────────
local MobileBar = Instance.new("Frame")
MobileBar.Name             = "TSB_MobileBar"
MobileBar.Visible          = false
MobileBar.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
MobileBar.BackgroundTransparency = 0.15
MobileBar.BorderSizePixel  = 0
MobileBar.Size             = UDim2.new(0, 10, 0, 10)   -- auto-resized later
MobileBar.Position         = UDim2.new(0.5, -120, 1, -200)
MobileBar.AnchorPoint      = Vector2.new(0, 0)
MobileBar.Parent           = ScreenGui
MobileBar.ZIndex           = 10

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = MobileBar
end

do  -- faint border
    local stroke = Instance.new("UIStroke")
    stroke.Color       = Color3.fromRGB(70, 70, 110)
    stroke.Thickness   = 1
    stroke.Transparency = 0.5
    stroke.Parent      = MobileBar
end

-- Drag title handle at top of mobile bar
local MobileBarHandle = Instance.new("TextButton")
MobileBarHandle.Size             = UDim2.new(1, 0, 0, 22)
MobileBarHandle.BackgroundColor3 = Color3.fromRGB(28, 28, 46)
MobileBarHandle.Text             = "  ⚔ TSB Controls  ··· drag"
MobileBarHandle.TextColor3       = Color3.fromRGB(160, 160, 200)
MobileBarHandle.TextSize         = 10
MobileBarHandle.Font             = Enum.Font.GothamBold
MobileBarHandle.TextXAlignment   = Enum.TextXAlignment.Left
MobileBarHandle.BorderSizePixel  = 0
MobileBarHandle.ZIndex           = 11
MobileBarHandle.Parent           = MobileBar

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = MobileBarHandle
end

-- Grid frame that holds the actual tech buttons
local MobileGrid = Instance.new("Frame")
MobileGrid.Name                 = "Grid"
MobileGrid.BackgroundTransparency = 1
MobileGrid.Size                 = UDim2.new(1, 0, 1, -22)
MobileGrid.Position             = UDim2.new(0, 0, 0, 22)
MobileGrid.ZIndex               = 11
MobileGrid.Parent               = MobileBar

local MobileGridLayout = Instance.new("UIGridLayout")
MobileGridLayout.CellSize        = UDim2.new(0, MBTN_SIZE, 0, MBTN_SIZE)
MobileGridLayout.CellPaddingH    = UDim.new(0, MBTN_GAP)    -- Roblox 2026+ property name
MobileGridLayout.CellPaddingV    = UDim.new(0, MBTN_GAP)
-- Fallback if those properties don't exist in older API:
pcall(function()
    MobileGridLayout.CellPaddingH = UDim.new(0, MBTN_GAP)
    MobileGridLayout.CellPaddingV = UDim.new(0, MBTN_GAP)
end)
MobileGridLayout.FillDirection   = Enum.FillDirection.Horizontal
MobileGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
MobileGridLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
MobileGridLayout.SortOrder       = Enum.SortOrder.LayoutOrder
MobileGridLayout.Parent          = MobileGrid

local MobileGridPad = Instance.new("UIPadding")
MobileGridPad.PaddingLeft   = UDim.new(0, 6)
MobileGridPad.PaddingRight  = UDim.new(0, 6)
MobileGridPad.PaddingTop    = UDim.new(0, 6)
MobileGridPad.PaddingBottom = UDim.new(0, 6)
MobileGridPad.Parent        = MobileGrid

-- ── Draggable mobile bar (mouse + touch) ─────────────────────────────────────
do
    local drag, dStart, bStart

    local function IsDragInp(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end

    MobileBarHandle.InputBegan:Connect(function(i)
        if IsDragInp(i) then
            drag   = true
            dStart = i.Position
            bStart = MobileBar.Position
        end
    end)
    MobileBarHandle.InputEnded:Connect(function(i)
        if IsDragInp(i) then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - dStart
            MobileBar.Position = UDim2.new(
                bStart.X.Scale, bStart.X.Offset + delta.X,
                bStart.Y.Scale, bStart.Y.Offset + delta.Y
            )
        end
    end)
end

-- ── Create all mobile buttons (hidden by default) ─────────────────────────────
local function _MakeMobileButton(def, index)
    local btn = Instance.new("TextButton")
    btn.Name             = "MBtn_" .. def.label
    btn.Size             = UDim2.new(0, MBTN_SIZE, 0, MBTN_SIZE)
    btn.BackgroundColor3 = def.color
    btn.BackgroundTransparency = 0.1
    btn.Text             = ""
    btn.BorderSizePixel  = 0
    btn.LayoutOrder      = index
    btn.ZIndex           = 12
    btn.Visible          = false   -- shown only when tech is ON + Mobile Mode is ON
    btn.Parent           = MobileGrid

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 12)
        c.Parent = btn
    end

    -- Short label (e.g. "TW")
    local shortLbl = Instance.new("TextLabel")
    shortLbl.Text                 = def.label
    shortLbl.Size                 = UDim2.new(1, 0, 0.55, 0)
    shortLbl.Position             = UDim2.new(0, 0, 0.08, 0)
    shortLbl.BackgroundTransparency = 1
    shortLbl.TextColor3           = Color3.fromRGB(255, 255, 255)
    shortLbl.TextSize             = 18
    shortLbl.Font                 = Enum.Font.GothamBold
    shortLbl.ZIndex               = 13
    shortLbl.Parent               = btn

    -- Full name sub-label (e.g. "Twisted")
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text                  = def.shortName
    nameLbl.Size                  = UDim2.new(1, -4, 0.32, 0)
    nameLbl.Position              = UDim2.new(0, 2, 0.64, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3            = Color3.fromRGB(240, 240, 255)
    nameLbl.TextSize              = 9
    nameLbl.Font                  = Enum.Font.Gotham
    nameLbl.TextScaled            = true
    nameLbl.ZIndex                = 13
    nameLbl.Parent                = btn

    -- Tap / click: fire the action from _mobileActions
    btn.MouseButton1Click:Connect(function()
        -- Map the button back to its unique action key
        -- Kyoto buttons share the "KyotoCombo" toggle key but have different actions
        local actionKey = def.label   -- unique per button (e.g. "KY1", "KY2", "KYG")
        local fn = _mobileActions[actionKey]
        if fn then
            local target = State.LockTarget or GetClosestEnemy()
            pcall(fn, target)
        end
    end)

    return btn
end

-- Build all buttons
for i, def in ipairs(_mobileButtonDefs) do
    _mobileButtonObjs[i] = _MakeMobileButton(def, i)
end

-- ── Resize MobileBar to fit exactly its visible buttons ──────────────────────
local function _ResizeMobileBar()
    local visCount = 0
    for _, btn in ipairs(_mobileButtonObjs) do
        if btn.Visible then visCount = visCount + 1 end
    end
    if visCount == 0 then
        MobileBar.Visible = false
        return
    end
    MobileBar.Visible = Config.Toggles.MobileMode

    local rows = math.ceil(visCount / MCOLS)
    local cols = math.min(visCount, MCOLS)
    local pad  = 6
    local w = cols * MBTN_SIZE + (cols - 1) * MBTN_GAP + pad * 2
    local h = rows * MBTN_SIZE + (rows - 1) * MBTN_GAP + pad * 2 + 22   -- +22 for handle
    MobileBar.Size = UDim2.new(0, w, 0, h)
end

-- ── Master refresh: update button visibility + resize bar ─────────────────────
-- Called when any toggle changes (changedKey = the Config.Toggles key that changed).
local function RefreshMobileBar(changedKey)
    if not Config.Toggles.MobileMode then
        MobileBar.Visible = false
        return
    end

    for i, def in ipairs(_mobileButtonDefs) do
        _mobileButtonObjs[i].Visible = Config.Toggles[def.key]
    end
    _ResizeMobileBar()
end

-- Expose as the forward-declared callback so MakeToggle can call it
_mobileBarRefresh = RefreshMobileBar

-- Special case: when MobileMode itself is toggled, refresh everything
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

-- ── Lethal + Flowing Integration ──────────────────────────────────────────────
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
-- Populated here so all tech functions are already defined above.
-- Keys match _mobileButtonDefs[i].label (unique per button).
-- ═════════════════════════════════════════════════════════════════════════════

_mobileActions = {
    -- Twisted Tech
    ["TW"]  = function(t) PerformTwistedTech(t) end,

    -- Three Kyoto variants — each has a distinct label key
    ["KY1"] = function(t) PerformKyotoCombo(t, 1) end,
    ["KY2"] = function(t) PerformKyotoCombo(t, 2) end,
    ["KYG"] = function(t) PerformKyotoCombo(t, 3) end,

    -- Grasp Tech (only fires if target is ragdolled — shows "GraspTech" toggle is ON)
    ["GR"]  = function(t) PerformGraspTech(t) end,

    -- Uppercut Grasp
    ["UC"]  = function(t) PerformUppercutGrasp(t) end,

    -- Lethal + Flowing burst
    ["L+F"] = function(_) PerformLethalFlowing() end,

    -- Loop Tech: toggle the loop on/off via the mobile button
    ["LP"]  = function(t)
        if _loopRunning then
            StopLoopTech()
        else
            StartLoopTech(t or GetClosestEnemy())
        end
    end,

    -- Auto Block: re-trigger the block check immediately
    ["BK"]  = function(_) end,   -- Auto Block is passive; button is informational

    -- Auto Punish: manually trigger a punish burst
    ["PF"]  = function(t)
        if not IsAlive() or not t then return end
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(t)
        if myRoot and tRoot and Distance(myRoot.Position, tRoot.Position) <= 14 then
            DoAction("M1")
            task.wait(Jitter(Config.Settings.M1Interval))
            DoAction("M1")
        end
    end,

    -- Auto M1 side-dash: manually trigger side-dash M1 extension
    ["SM"]  = function(t)
        if not IsAlive() or not t then return end
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(t)
        if myRoot and tRoot then
            myRoot.CFrame = CFrame.new(myRoot.Position,
                Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
            DoAction("M1")
            task.wait(Jitter(Config.Settings.M1Interval))
            DoAction("M1")
        end
    end,

    -- Lock On 1: snap to closest enemy now
    ["L1"]  = function(_)
        local e = GetClosestEnemy()
        if e then State.LockTarget = e end
    end,

    -- Lock On 2: snap to cursor-nearest enemy now
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
            myRoot.CFrame = CFrame.new(
                myRoot.Position,
                Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
            )
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
    if not Config.Toggles.LockOnClosest then
        LockTarget1 = nil
        return
    end
    LockTarget1 = GetClosestEnemy()
    if not LockTarget1 then return end
    local tRoot = GetPlayerRoot(LockTarget1)
    if not tRoot then return end
    local lookDir = (tRoot.Position - Camera.CFrame.Position).Unit
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookDir)
end

local function UpdateLockOnCursor()
    if not Config.Toggles.LockOnCursor then
        LockTarget2 = nil
        return
    end
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

    local box                   = Instance.new("SelectionBox")
    box.SurfaceTransparency     = Config.Settings.ESPTransparency
    box.SurfaceColor3           = Config.Settings.ESPColor
    box.LineThickness           = 0.04
    box.Color3                  = Config.Settings.ESPColor
    box.Adornee                 = char
    box.Parent                  = CoreGui

    local bb                    = Instance.new("BillboardGui")
    bb.Adornee                  = root
    bb.AlwaysOnTop              = true
    bb.Size                     = UDim2.new(0, 90, 0, 22)
    bb.StudsOffset              = Vector3.new(0, 3.2, 0)
    bb.Parent                   = CoreGui

    local name_lbl              = Instance.new("TextLabel")
    name_lbl.Text               = player.Name
    name_lbl.Size               = UDim2.new(1, 0, 1, 0)
    name_lbl.BackgroundTransparency = 1
    name_lbl.TextColor3         = Config.Settings.ESPColor
    name_lbl.TextSize           = 13
    name_lbl.Font               = Enum.Font.GothamBold
    name_lbl.TextStrokeTransparency = 0.4
    name_lbl.Parent             = bb

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

    -- GUI visibility
    if inp.KeyCode == Config.Keybinds.ToggleGUI then
        MainFrame.Visible = not MainFrame.Visible
    end

    -- Kyoto burst keys
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

    -- Every frame: Auto Block
    if Config.Toggles.AutoBlock then CheckAutoBlock() end

    -- Every 2 frames: Lock On
    if _hbFrame % 2 == 0 then
        UpdateLockOnClosest()
        UpdateLockOnCursor()
        State.LockTarget = GetLockTarget()
    end

    -- Every 3 frames: M1 combo state machine
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

    -- Every 4 frames: Dash detection
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

    -- Every 12 frames: ESP
    if _hbFrame % 12 == 0 then UpdateESP() end

    -- Every 30 frames: status bar + Loop Tech keep-alive
    if _hbFrame % 30 == 0 then
        local T = Config.Toggles
        local on = {}
        if T.TwistedTech        then on[#on+1] = "Twisted"  end
        if T.KyotoCombo         then on[#on+1] = "Kyoto"    end
        if T.GraspTech          then on[#on+1] = "Grasp"    end
        if T.UppercutGrasp      then on[#on+1] = "Upcut"    end
        if T.LethalFlowing      then on[#on+1] = "L+F"      end
        if T.LoopTech           then on[#on+1] = "Loop"     end
        if T.AutoBlock          then on[#on+1] = "Block"    end
        if T.AutoPunishFrontDash then on[#on+1] = "Punish"  end
        if T.AutoM1SideDash     then on[#on+1] = "SideM1"  end
        if T.LockOnClosest      then on[#on+1] = "Lock1"   end
        if T.LockOnCursor       then on[#on+1] = "Lock2"   end
        if T.ESP                then on[#on+1] = "ESP"      end
        if T.MobileMode         then on[#on+1] = "📱"        end

        if #on == 0 then
            StatusLabel.Text       = "  Status: Idle (all off)"
            StatusLabel.TextColor3 = Color3.fromRGB(130, 130, 160)
        else
            StatusLabel.Text       = "  ▸ " .. table.concat(on, " | ")
            StatusLabel.TextColor3 = Color3.fromRGB(90, 200, 120)
        end
    end

    -- Loop Tech auto-restart
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

-- Perform an initial mobile bar state sync in case toggles were pre-set
task.defer(function() RefreshMobileBar("init") end)

Notify(
    "TSB Ultimate v2.1 Loaded",
    "RCtrl=GUI | F1–F12=Features | 📱=Mobile Mode | Q/E/R/G/T=Bursts",
    8
)

print("[TSB Ultimate v2.1] Initialized — " .. (_IsMobile and "MOBILE" or "DESKTOP") .. " layout active.")
