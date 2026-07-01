--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║              TSB ULTIMATE SCRIPT  —  The Strongest Battlegrounds            ║
║                                                                              ║
║  Compatible: Delta Executor, Fluxus, Solara, Arceus X, and most others      ║
║  Author   : TSB Script Team                                                  ║
║  Version  : 2.0                                                              ║
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
║   ✦ Draggable dark GUI, F1–F12 keybinds                                     ║
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
-- getgenv() is available in most executors; fall back to an empty table if not.
local _env = (typeof(getgenv) == "function" and getgenv()) or {}
if _env._TSB_LOADED then
    warn("[TSB] Script already loaded — run _env._TSB_LOADED = false to reload.")
    return
end
_env._TSB_LOADED = true

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
    },

    Settings = {
        -- Ranges (studs)
        AutoBlockRange     = 25,
        LockOnRange        = 200,
        PunishHitRange     = 14,

        -- Base timing windows (seconds)
        M1Interval         = 0.35,  -- time between M1 hits
        DashDelay          = 0.08,  -- post-dash input window
        SkillDelay         = 0.12,  -- skill-to-action delay
        TwistedWindow      = 0.16,  -- Twisted Tech execution window
        KyotoWindow        = 0.20,  -- Kyoto combo input window
        LoopDashInterval   = 0.42,  -- Loop Tech dash cadence

        -- ±variance added to every delay for human-like behaviour
        Randomness         = 0.04,

        -- ESP appearance
        ESPColor           = Color3.fromRGB(255, 50, 50),
        ESPTransparency    = 0.3,

        -- Twist: how much to nudge backward (Humbled's anti-knockback)
        HumbledBackForce   = 8,
    },
}

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 3 — UTILITY FUNCTIONS
-- ═════════════════════════════════════════════════════════════════════════════

-- Add slight random variance to any timing value so actions feel human.
local function Jitter(base)
    local r = Config.Settings.Randomness
    return base + (math.random() * r * 2 - r)
end

-- Safe character accessors
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

-- Safe root for any Player object
local function GetPlayerRoot(player)
    local c = player and player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function Distance(a, b)
    return (a - b).Magnitude
end

-- Returns a list of alive enemy Player objects
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

-- Closest alive enemy to our HRP
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

-- Enemy whose screen position is closest to the current mouse cursor
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

-- StarterGui notification (safe pcall because it fails pre-load sometimes)
local function Notify(title, text, dur)
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title    = title,
        Text     = text,
        Duration = dur or 3,
    })
end

-- Check if a named animation track is currently playing on our character
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

-- TSB marks ragdolled characters with a BoolValue or via humanoid state
local function IsRagdolled()
    local char = GetCharacter()
    if not char then return false end
    local flag = char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsRagdoll")
    if flag and flag.Value then return true end
    local hum = GetHumanoid()
    return hum ~= nil and hum:GetState() == Enum.HumanoidStateType.FallingDown
end

-- ── Remote discovery ──────────────────────────────────────────────────────────
-- TSB stores combat remotes under ReplicatedStorage; names vary by version.
-- We search recursively so the script adapts even if paths shift between updates.

local _remoteCache = {}

local function FindRemote(name)
    if _remoteCache[name] then return _remoteCache[name] end
    local found = ReplicatedStorage:FindFirstChild(name, true)
    _remoteCache[name] = found
    return found
end

-- Attempt to fire a RemoteEvent by logical name, silent-fail on error
local function DoAction(remoteName, ...)
    local remote = FindRemote(remoteName)
    if remote and remote:IsA("RemoteEvent") then
        pcall(remote.FireServer, remote, ...)
        return true
    end
    return false
end

-- ── Connection management (prevents memory leaks on reload) ───────────────────
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
    M1Count        = 0,       -- which hit of the 4-hit chain we're on
    LastM1Time     = 0,
    LastDashTime   = 0,
    DashDirection  = "None",  -- "Front" | "Back" | "Side"
    IsBlocking     = false,
    IsRagdolled    = false,
    InSkill        = false,
    LastSkillUsed  = "",
    LockTarget     = nil,     -- active lock-on Player object
}

-- Reset all mutable state flags (called on respawn)
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

-- Destroy any previous instance so re-running the script is clean
pcall(function()
    local old = CoreGui:FindFirstChild("TSB_GUI")
    if old then old:Destroy() end
end)

-- Root ScreenGui — parent to CoreGui when possible (prevents it being wiped
-- by character resets), fall back to PlayerGui.
local ScreenGui         = Instance.new("ScreenGui")
ScreenGui.Name          = "TSB_GUI"
ScreenGui.ResetOnSpawn  = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- ── Main window ───────────────────────────────────────────────────────────────
local MainFrame                = Instance.new("Frame")
MainFrame.Name                 = "MainFrame"
MainFrame.Size                 = UDim2.new(0, 330, 0, 500)
MainFrame.Position             = UDim2.new(0, 24, 0.5, -250)
MainFrame.BackgroundColor3     = Color3.fromRGB(14, 14, 20)
MainFrame.BorderSizePixel      = 0
MainFrame.ClipsDescendants     = true
MainFrame.Parent               = ScreenGui

do  -- rounded corners
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = MainFrame
end

do  -- subtle drop shadow
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
TitleBar.Size              = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3  = Color3.fromRGB(26, 26, 40)
TitleBar.BorderSizePixel   = 0
TitleBar.Parent            = MainFrame

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = TitleBar
end

local TitleLabel               = Instance.new("TextLabel")
TitleLabel.Text                = "  ⚔  TSB ULTIMATE  v2.0"
TitleLabel.Size                = UDim2.new(1, -50, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3          = Color3.fromRGB(210, 210, 255)
TitleLabel.TextSize            = 14
TitleLabel.Font                = Enum.Font.GothamBold
TitleLabel.TextXAlignment      = Enum.TextXAlignment.Left
TitleLabel.Parent              = TitleBar

local MinBtn                   = Instance.new("TextButton")
MinBtn.Text                    = "—"
MinBtn.Size                    = UDim2.new(0, 30, 0, 22)
MinBtn.Position                = UDim2.new(1, -38, 0.5, -11)
MinBtn.BackgroundColor3        = Color3.fromRGB(55, 55, 85)
MinBtn.TextColor3              = Color3.fromRGB(210, 210, 255)
MinBtn.TextSize                = 14
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
Scroll.Size                    = UDim2.new(1, 0, 1, -38)
Scroll.Position                = UDim2.new(0, 0, 0, 38)
Scroll.BackgroundTransparency  = 1
Scroll.ScrollBarThickness      = 3
Scroll.ScrollBarImageColor3    = Color3.fromRGB(90, 90, 140)
Scroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
Scroll.Parent                  = MainFrame

do
    local layout = Instance.new("UIListLayout")
    layout.Padding    = UDim.new(0, 5)
    layout.SortOrder  = Enum.SortOrder.LayoutOrder
    layout.Parent     = Scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 9)
    pad.PaddingRight  = UDim.new(0, 9)
    pad.PaddingTop    = UDim.new(0, 9)
    pad.PaddingBottom = UDim.new(0, 9)
    pad.Parent        = Scroll
end

-- ── Draggable title bar logic ─────────────────────────────────────────────────
do
    local dragging, dragStart, frameStart
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            frameStart = MainFrame.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
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
    Scroll.Visible    = _guiExpanded
    MainFrame.Size    = _guiExpanded
        and UDim2.new(0, 330, 0, 500)
        or  UDim2.new(0, 330, 0, 38)
    MinBtn.Text = _guiExpanded and "—" or "+"
end)

-- ── GUI builder helpers ───────────────────────────────────────────────────────
local _toggleUpdaters = {}   -- [configKey] = function() to refresh visual

-- Section header label
local function MakeSection(title)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 26)
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
    lbl.TextSize          = 11
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = f
end

-- Toggle row with pill button + optional key hint
local function MakeToggle(label, configKey, keyHint)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 34)
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
    lbl.Size           = UDim2.new(1, -100, 1, 0)
    lbl.Position       = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3     = Color3.fromRGB(195, 195, 220)
    lbl.TextSize       = 13
    lbl.Font           = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent         = row

    if keyHint then
        local hint = Instance.new("TextLabel")
        hint.Text           = "[" .. keyHint .. "]"
        hint.Size           = UDim2.new(0, 38, 1, 0)
        hint.Position       = UDim2.new(1, -98, 0, 0)
        hint.BackgroundTransparency = 1
        hint.TextColor3     = Color3.fromRGB(90, 90, 130)
        hint.TextSize       = 10
        hint.Font           = Enum.Font.Gotham
        hint.Parent         = row
    end

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 48, 0, 22)
    btn.Position         = UDim2.new(1, -58, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(75, 75, 100)
    btn.Text             = "OFF"
    btn.TextColor3       = Color3.fromRGB(170, 170, 195)
    btn.TextSize         = 11
    btn.Font             = Enum.Font.GothamBold
    btn.BorderSizePixel  = 0
    btn.Parent           = row

    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)  -- fully rounded pill
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
    end)

    _toggleUpdaters[configKey] = Refresh
end

-- ── Build layout ──────────────────────────────────────────────────────────────
MakeSection("⚔  Combat Techs")
MakeToggle("Twisted Tech",            "TwistedTech",         "F1")
MakeToggle("Kyoto Combo (Q/E/R)",     "KyotoCombo",          "F2")
MakeToggle("Grasp Tech",              "GraspTech",           "F3")
MakeToggle("Uppercut Grasp  [T]",     "UppercutGrasp",       "F4")
MakeToggle("Lethal + Flowing  [G]",   "LethalFlowing",       "F5")
MakeToggle("Loop Tech",               "LoopTech",            "F6")

MakeSection("🛡  Defense")
MakeToggle("Auto Block",              "AutoBlock",           "F7")

MakeSection("⚡  Punish")
MakeToggle("Auto Punish (Front Dash)","AutoPunishFrontDash", "F8")
MakeToggle("Auto M1 (Side Dash)",     "AutoM1SideDash",      "F9")

MakeSection("🎯  Lock On")
MakeToggle("Closest Player",          "LockOnClosest",       "F10")
MakeToggle("Closest to Cursor",       "LockOnCursor",        "F11")

MakeSection("👁  Visual")
MakeToggle("ESP Highlights",          "ESP",                 "F12")

-- Status bar at the bottom of the scroll area
local StatusRow = Instance.new("Frame")
StatusRow.Size             = UDim2.new(1, 0, 0, 26)
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
StatusLabel.TextSize       = 11
StatusLabel.Font           = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent         = StatusRow

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 6 — TECH FUNCTIONS
-- ═════════════════════════════════════════════════════════════════════════════

-- ── Twisted Tech ──────────────────────────────────────────────────────────────
--
-- Fires on the 4th M1 of the combo chain.
-- Classic Twisted: front-dash as soon as the 4th hit commits.
-- Humbled's variant: tiny backward velocity nudge first, reducing the
-- opponent's knockback so they stay close enough for a follow-up.

local _twistedBusy = false

local function PerformTwistedTech(target)
    if _twistedBusy or not Config.Toggles.TwistedTech then return end
    if not IsAlive() then return end

    _twistedBusy = true
    task.spawn(function()
        -- Let the 4th M1 animation commit briefly before dashing
        task.wait(Jitter(0.05))

        -- Humbled's micro back-nudge: keeps the opponent in combo range
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

        -- Face the target so the front-dash travels toward them
        if myRoot and tRoot then
            local dir = (tRoot.Position - myRoot.Position)
            myRoot.CFrame = CFrame.new(
                myRoot.Position,
                Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
            )
        end

        DoAction("FrontDash")
        State.LastDashTime  = tick()
        State.DashDirection = "Front"
        State.M1Count       = 0   -- reset combo counter after dash

        task.wait(Jitter(Config.Settings.DashDelay))
        _twistedBusy = false
    end)
end

-- ── Kyoto Combo ───────────────────────────────────────────────────────────────
--
-- Three variants triggered by Q / E / R while KyotoCombo is ON:
--   variant 1 (Q) — Kyoto One:   Flowing Water → back-dash cancel → front-dash re-engage
--   variant 2 (E) — Kyoto Two:   Flowing Water → side-dash cancel → Lethal → M1
--   variant 3 (R) — Kyoto Grasp: Flowing Water → side-dash cancel → Hunter's Grasp
--
-- These are high-reward, high-timing-requirement combos; small delays are
-- included to respect server-side animation locks.

local _kyotoPhase = 0   -- 0 = idle, 1 = mid-sequence

local function PerformKyotoCombo(target, variant)
    if not Config.Toggles.KyotoCombo then return end
    if not IsAlive() or _kyotoPhase ~= 0 then return end

    _kyotoPhase = 1
    task.spawn(function()
        -- Step 1: Flowing Water
        DoAction("FlowingWater")
        State.InSkill     = true
        State.LastSkillUsed = "FlowingWater"

        task.wait(Jitter(Config.Settings.KyotoWindow))

        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)

        if variant == 1 then
            -- Kyoto One: back-dash cancel → turn → front-dash re-engage
            DoAction("BackDash")
            State.DashDirection = "Back"

            task.wait(Jitter(0.14))

            -- Rotate toward target so front-dash is aimed correctly
            if myRoot and tRoot then
                myRoot.CFrame = CFrame.new(
                    myRoot.Position,
                    Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
                )
            end
            DoAction("FrontDash")
            State.DashDirection = "Front"

        elseif variant == 2 then
            -- Kyoto Two: side-dash cancel → Lethal Whirlwind Stream → M1
            DoAction("SideDash")
            State.DashDirection = "Side"

            task.wait(Jitter(0.10))

            DoAction("LethalWhirlwindStream")
            State.LastSkillUsed = "LethalWhirlwindStream"

            task.wait(Jitter(0.18))
            DoAction("M1")

        elseif variant == 3 then
            -- Kyoto Grasp: side-dash cancel → Hunter's Grasp on stunned target
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
--
-- Detects when the target is ragdolled (knocked down) and immediately fires
-- Hunter's Grasp (close range) or Crushing Pull (medium range) to chain
-- damage before they recover.

local _graspCD = false

local function PerformGraspTech(target)
    if not Config.Toggles.GraspTech or _graspCD then return end
    if not IsAlive() or not target then return end

    local tChar = target.Character
    if not tChar then return end

    local tHum     = tChar:FindFirstChildOfClass("Humanoid")
    local ragFlag  = tChar:FindFirstChild("Ragdoll") or tChar:FindFirstChild("IsRagdoll")
    local vulnerable = (ragFlag and ragFlag.Value)
        or (tHum and tHum:GetState() == Enum.HumanoidStateType.FallingDown)

    if not vulnerable then return end

    _graspCD = true
    task.spawn(function()
        task.wait(Jitter(0.06))  -- align with ragdoll animation window

        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if myRoot and tRoot then
            local dist = Distance(myRoot.Position, tRoot.Position)
            if dist <= 14 then
                DoAction("HuntersGrasp")
            else
                -- Crushing Pull draws the target closer before damage
                DoAction("CrushingPull")
            end
            State.LastSkillUsed = dist <= 14 and "HuntersGrasp" or "CrushingPull"
        end

        task.wait(1.6)   -- respect grasp cooldown
        _graspCD = false
    end)
end

-- ── Uppercut Grasp / Humbled's Tech ───────────────────────────────────────────
--
-- Jump → aim at target's head → uppercut M1 → immediately Hunter's Grasp.
-- The head-level hit triggers a special launch state that sets up the grasp.

local _upcutCD = false

local function PerformUppercutGrasp(target)
    if not Config.Toggles.UppercutGrasp or _upcutCD then return end
    if not IsAlive() or not target then return end

    _upcutCD = true
    task.spawn(function()
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if not myRoot or not tRoot then _upcutCD = false return end

        -- Face the target
        myRoot.CFrame = CFrame.new(
            myRoot.Position,
            Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
        )

        -- Jump to gain the upward trajectory
        local hum = GetHumanoid()
        if hum then hum.Jump = true end

        task.wait(Jitter(0.09))

        -- Uppercut / rising M1 (TSB fires this as "Uppercut" remote or "M1" while airborne)
        DoAction("Uppercut")
        -- Fallback: generic M1 while jumping still triggers the rising hit
        DoAction("M1")

        task.wait(Jitter(0.13))

        -- Hunter's Grasp immediately after the uppercut hit
        DoAction("HuntersGrasp")
        State.LastSkillUsed = "HuntersGrasp"

        task.wait(Jitter(1.9))
        _upcutCD = false
    end)
end

-- ── Lethal + Flowing Integration ───────────────────────────────────────────────
--
-- Chains Lethal Whirlwind Stream into Flowing Water with an intermediate
-- side-dash cancel to create extended, high-damage combo pressure.
-- Triggered by G while LethalFlowing is ON.

local _lethalFlowCD = false

local function PerformLethalFlowing()
    if not Config.Toggles.LethalFlowing or _lethalFlowCD then return end
    if not IsAlive() then return end

    _lethalFlowCD = true
    task.spawn(function()
        -- Phase 1: Lethal Whirlwind Stream
        DoAction("LethalWhirlwindStream")
        State.LastSkillUsed = "LethalWhirlwindStream"
        State.InSkill = true

        task.wait(Jitter(Config.Settings.SkillDelay + 0.08))

        -- Dash cancel mid-stream — side dash keeps us close but resets hitstun
        DoAction("SideDash")
        State.DashDirection = "Side"

        task.wait(Jitter(0.11))

        -- Phase 2: Flowing Water
        DoAction("FlowingWater")
        State.LastSkillUsed = "FlowingWater"

        task.wait(Jitter(0.20))

        -- Second side-dash cancel for extended pressure
        DoAction("SideDash")

        task.wait(Jitter(0.09))

        -- Close out with M1
        DoAction("M1")

        task.wait(Jitter(2.2))
        State.InSkill = false
        _lethalFlowCD = false
    end)
end

-- ── Loop Tech (LordHeaven / Loop Dash style) ──────────────────────────────────
--
-- Continuously orbits the target by alternating front / side / back dashes,
-- mixing in M1s to maintain combo pressure. Stops when LoopTech is toggled
-- off or the target dies/leaves.

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

            -- Always keep facing the target between dashes
            myRoot.CFrame = CFrame.new(
                myRoot.Position,
                Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z)
            )

            -- Rotate through: side dash → front dash + M1 → back dash → repeat
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
-- SECTION 7 — AUTO BLOCK
-- ═════════════════════════════════════════════════════════════════════════════

-- Heuristic 1: an enemy's HRP is moving fast in our direction → likely attacking.
-- Heuristic 2: an enemy's Animator has an M1/punch track currently playing.
-- When triggered: fires Block remote ON, waits, then fires Block OFF.

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

        -- Velocity dot test
        local vel      = eRoot.AssemblyLinearVelocity
        local toMe     = (myRoot.Position - eRoot.Position).Unit
        local speed    = vel.Magnitude
        local approach = vel.Magnitude > 0 and vel.Unit:Dot(toMe) or 0

        local attackDetected = (approach > 0.4 and speed > 18)

        -- Animation check (slower but more accurate)
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
                -- Hold block for the duration of the incoming hit window
                task.wait(Jitter(0.50))
                DoAction("Block", false)
                State.IsBlocking = false
                task.wait(0.08)
                _blockCD = false
            end)
            return  -- only need to block once per frame check
        end
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 8 — AUTO PUNISH SYSTEMS
-- ═════════════════════════════════════════════════════════════════════════════

-- Auto-punish fires 1–2 M1s immediately after the player lands a front dash
-- on an opponent who is now in recovery frames.
local function AutoPunishFrontDash(target)
    if not Config.Toggles.AutoPunishFrontDash or not IsAlive() or not target then return end

    task.spawn(function()
        task.wait(Jitter(0.07))  -- let dash land
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if not myRoot or not tRoot then return end
        if Distance(myRoot.Position, tRoot.Position) <= Config.Settings.PunishHitRange then
            DoAction("M1")
            task.wait(Jitter(Config.Settings.M1Interval))
            DoAction("M1")
        end
    end)
end

-- After a side dash reposition, re-face the target and fire M1s to extend combo.
local function AutoM1AfterSideDash(target)
    if not Config.Toggles.AutoM1SideDash or not IsAlive() or not target then return end

    task.spawn(function()
        task.wait(Jitter(0.08))
        local myRoot = GetRoot()
        local tRoot  = GetPlayerRoot(target)
        if not myRoot or not tRoot then return end
        if Distance(myRoot.Position, tRoot.Position) <= Config.Settings.PunishHitRange then
            -- Re-face after the side dash rotation
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

local LockTarget1 = nil   -- Closest to LocalPlayer
local LockTarget2 = nil   -- Closest to cursor

-- Lock-On 1: keep camera rotated toward the nearest alive enemy.
local function UpdateLockOnClosest()
    if not Config.Toggles.LockOnClosest then
        LockTarget1 = nil
        return
    end
    LockTarget1 = GetClosestEnemy()
    if not LockTarget1 then return end
    local tRoot = GetPlayerRoot(LockTarget1)
    if not tRoot then return end
    -- Smoothly aim the camera
    local lookDir = (tRoot.Position - Camera.CFrame.Position).Unit
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookDir)
end

-- Lock-On 2: keep camera rotated toward the enemy whose screen position
-- is nearest to the mouse pointer.
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

-- Returns whichever lock-on target is currently active,
-- falling back to the closest enemy for tech functions.
local function GetLockTarget()
    if Config.Toggles.LockOnClosest and LockTarget1 then return LockTarget1 end
    if Config.Toggles.LockOnCursor  and LockTarget2 then return LockTarget2 end
    return GetClosestEnemy()
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 10 — ESP SYSTEM
-- ═════════════════════════════════════════════════════════════════════════════

-- Each enemy gets a SelectionBox (outline) and a BillboardGui (name label).
-- Both are parented to CoreGui so they persist through death/respawn.

local _espObjects = {}   -- [Player] = {SelectionBox, BillboardGui}

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

    -- Selection box around the full character
    local box                   = Instance.new("SelectionBox")
    box.SurfaceTransparency     = Config.Settings.ESPTransparency
    box.SurfaceColor3           = Config.Settings.ESPColor
    box.LineThickness           = 0.04
    box.Color3                  = Config.Settings.ESPColor
    box.Adornee                 = char
    box.Parent                  = CoreGui

    -- Billboard name tag above the head
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
    if not Config.Toggles.ESP then
        ClearAllESP()
        return
    end
    -- Add/refresh for current enemies
    for _, p in ipairs(GetEnemies()) do CreateESPFor(p) end
    -- Prune stale entries
    for player in pairs(_espObjects) do
        local root = GetPlayerRoot(player)
        if not root then RemoveESPFor(player) end
    end
end

-- Clean up immediately when a player leaves
Connect(Players.PlayerRemoving, function(p) RemoveESPFor(p) end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 11 — INPUT / KEYBIND HANDLER
-- ═════════════════════════════════════════════════════════════════════════════

Connect(UserInputService.InputBegan, function(inp, gameProc)
    if gameProc then return end

    -- ── F-key feature toggles ──────────────────────────────────────────────
    for name, keyCode in pairs(Config.Keybinds) do
        if inp.KeyCode == keyCode and name ~= "ToggleGUI" then
            if Config.Toggles[name] ~= nil then
                Config.Toggles[name] = not Config.Toggles[name]
                local upd = _toggleUpdaters[name]
                if upd then upd() end
                Notify("TSB Script",
                    name .. " → " .. (Config.Toggles[name] and "ON" or "OFF"))

                -- Loop Tech: start/stop on toggle
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

    -- ── GUI visibility ─────────────────────────────────────────────────────
    if inp.KeyCode == Config.Keybinds.ToggleGUI then
        MainFrame.Visible = not MainFrame.Visible
    end

    -- ── Kyoto burst keys (active only while KyotoCombo is toggled ON) ──────
    local target = GetLockTarget()
    if Config.Toggles.KyotoCombo then
        if inp.KeyCode == Enum.KeyCode.Q then
            PerformKyotoCombo(target, 1)   -- Kyoto One
        elseif inp.KeyCode == Enum.KeyCode.E then
            PerformKyotoCombo(target, 2)   -- Kyoto Two
        elseif inp.KeyCode == Enum.KeyCode.R then
            PerformKyotoCombo(target, 3)   -- Kyoto Grasp
        end
    end

    -- ── Lethal+Flowing burst (G) ────────────────────────────────────────────
    if inp.KeyCode == Enum.KeyCode.G and Config.Toggles.LethalFlowing then
        PerformLethalFlowing()
    end

    -- ── Uppercut Grasp (T) ─────────────────────────────────────────────────
    if inp.KeyCode == Enum.KeyCode.T and Config.Toggles.UppercutGrasp then
        PerformUppercutGrasp(target)
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 12 — MAIN LOOPS / CONNECTIONS
-- ═════════════════════════════════════════════════════════════════════════════

-- Single Heartbeat loop — subdivided by frame modulus to avoid per-frame
-- overhead for expensive operations while keeping critical checks fast.
local _hbFrame = 0

Connect(RunService.Heartbeat, function()
    _hbFrame = _hbFrame + 1

    -- ── Every frame: Auto Block (needs fastest possible reaction) ─────────
    if Config.Toggles.AutoBlock then
        CheckAutoBlock()
    end

    -- ── Every 2 frames: Lock On (smooth, not every-frame expensive) ───────
    if _hbFrame % 2 == 0 then
        UpdateLockOnClosest()
        UpdateLockOnCursor()
        State.LockTarget = GetLockTarget()
    end

    -- ── Every 3 frames: M1 combo state machine ────────────────────────────
    if _hbFrame % 3 == 0 then
        -- Expire combo window after 3 seconds of no M1
        if tick() - State.LastM1Time > 3.0 then
            State.M1Count = 0
        end

        -- Detect M1 animation to track combo count
        if IsAnimationPlaying("m1") or IsAnimationPlaying("punch") or
           IsAnimationPlaying("attack") then
            local now = tick()
            -- Guard: only count once per ~200 ms to avoid multiple ticks per animation
            if now - State.LastM1Time >= 0.20 then
                State.M1Count     = (State.M1Count % 4) + 1
                State.LastM1Time  = now

                local target = State.LockTarget

                -- Twisted Tech fires on the 4th M1 hit
                if State.M1Count == 4 and Config.Toggles.TwistedTech then
                    PerformTwistedTech(target)
                end

                -- Opportunistic Grasp Tech: fire if target ragdolled mid-combo
                if Config.Toggles.GraspTech and target then
                    PerformGraspTech(target)
                end
            end
        end
    end

    -- ── Every 4 frames: Dash detection → auto punish/extend ──────────────
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

        -- Ragdoll state
        State.IsRagdolled = IsRagdolled()
    end

    -- ── Every 12 frames: ESP (SelectionBox is expensive) ─────────────────
    if _hbFrame % 12 == 0 then
        UpdateESP()
    end

    -- ── Every 30 frames: Status bar refresh ───────────────────────────────
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

        if #on == 0 then
            StatusLabel.Text       = "  Status: Idle (all off)"
            StatusLabel.TextColor3 = Color3.fromRGB(130, 130, 160)
        else
            StatusLabel.Text       = "  ▸ " .. table.concat(on, " | ")
            StatusLabel.TextColor3 = Color3.fromRGB(90, 200, 120)
        end
    end

    -- ── Loop Tech: auto-restart if target changed and loop stopped ────────
    if Config.Toggles.LoopTech and not _loopRunning then
        local t = GetLockTarget()
        if t then StartLoopTech(t) end
    end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 13 — CHARACTER RESPAWN HANDLER
-- ═════════════════════════════════════════════════════════════════════════════

local function OnCharacterAdded(char)
    -- Reset all mutable state so the script works cleanly after respawn
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

    -- Wait for character to finish loading before notifying
    task.wait(1.5)
    Notify("TSB Script", "Character loaded — all systems active", 4)
end

Connect(LocalPlayer.CharacterAdded, OnCharacterAdded)

-- Handle the case where the character already exists when the script runs
if LocalPlayer.Character then
    task.spawn(function() OnCharacterAdded(LocalPlayer.Character) end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 14 — INITIALIZATION
-- ═════════════════════════════════════════════════════════════════════════════

-- Pre-warm remote cache in background (2-second delay to let the game load)
task.delay(2, function()
    local knownRemotes = {
        "M1", "FrontDash", "BackDash", "SideDash", "Block",
        "FlowingWater", "LethalWhirlwindStream", "HuntersGrasp",
        "CrushingPull", "Uppercut",
    }
    for _, name in ipairs(knownRemotes) do
        FindRemote(name)   -- populates _remoteCache
    end
end)

-- Boot notification
Notify(
    "TSB Ultimate Loaded",
    "GUI: RCtrl  |  Techs: F1–F6  |  Defense: F7  |  Punish: F8–F9  |  Lock: F10–F11  |  ESP: F12",
    8
)

print("[TSB Ultimate v2.0] Script initialized — all systems ready.")
