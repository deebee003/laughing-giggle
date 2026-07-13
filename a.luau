--// Steal a Brainrot - Base Guard Script
--// Rayfield GUI | Anti-Cheat Bypass | Base Intruder Detection
--// Uses queue_on_teleport to survive anticheat teleports

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--// ═══════════════════════════════════════════
--// QUEUE ON TELEPORT - Re-execute after anticheat kicks
--// ═══════════════════════════════════════════

local ScriptSource = game:HttpGet("https://raw.githubusercontent.com/StealABrainrot/BaseGuard/main/StealABrainrot_BaseGuard.luau", true)

-- Queue the script to re-run after any teleport (anticheat dodge)
if queue_on_teleport then
    queue_on_teleport([[
        -- Re-inject after anticheat teleport
        wait(2)
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/StealABrainrot/BaseGuard/main/StealABrainrot_BaseGuard.luau", true))()
        end)
        if not success then
            warn("[Base Guard] Re-inject failed: " .. tostring(err))
        end
    ]])
    print("[Base Guard] Queued re-injection on teleport")
end

-- Also queue it with the local source as fallback
local function QueueSelfReinject()
    if queue_on_teleport then
        queue_on_teleport(string.format([[
            wait(2)
            pcall(function()
                -- Fallback: attempt to re-execute from saved source
                local src = readfile and readfile("StealABrainrot_BaseGuard.luau")
                if src then
                    loadstring(src)()
                end
            end)
        ]]))
    end
end

QueueSelfReinject()

--// RAYFIELD LOADER
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// ═══════════════════════════════════════════
--// ANTI-CHEAT BYPASS
--// ═══════════════════════════════════════════

local ACBypass = {}

function ACBypass.Init()
    -- Save script locally for re-injection fallback
    if writefile then
        pcall(function()
            local src = game:HttpGet("https://raw.githubusercontent.com/StealABrainrot/BaseGuard/main/StealABrainrot_BaseGuard.luau", true)
            writefile("StealABrainrot_BaseGuard.luau", src)
        end)
    end

    -- Hook __namecall to suppress detection remotes AND block teleport-to-lobby
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Block common anticheat report/check remotes
        if method == "FireServer" or method == "InvokeServer" then
            local remoteName = tostring(self.Name):lower()
            local blockedPatterns = {
                "anticheat", "ac_", "report", "detect", "flag",
                "speed", "fly", "teleport", "noclip", "exploit",
                "ban", "kick", "cheat", "hack", "inject"
            }

            for _, pattern in blockedPatterns do
                if remoteName:find(pattern) then
                    return nil
                end
            end
        end

        -- Block server-initiated TeleportService calls (anticheat kicks)
        if method == "Teleport" or method == "TeleportToPlaceInstance" then
            warn("[AC Bypass] Blocked server teleport attempt!")
            return nil
        end

        return oldNamecall(self, ...)
    end)

    -- Hook __index to hide exploit globals from detection
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if self == game and typeof(key) == "string" then
            local blocked = {"Kick", "Shutdown"}
            for _, v in blocked do
                if key == v then
                    return function() end
                end
            end
        end
        return oldIndex(self, key)
    end))

    -- Spoof character state to avoid velocity checks
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                -- Allow normal speed changes
            end)
        end
    end

    -- Block velocity/tp detection from ReplicatedFirst
    for _, v in ReplicatedFirst:GetDescendants() do
        if v:IsA("LocalScript") then
            local success, _ = pcall(function()
                -- Monitor for detection scripts
            end)
        end
    end

    -- Hook TeleportService to block server-forced teleports
    pcall(function()
        local TeleportService = game:GetService("TeleportService")
        local oldTeleport = TeleportService.Teleport
        TeleportService.Teleport = function(self, ...)
            warn("[AC Bypass] Blocked TeleportService:Teleport()")
            -- Queue re-injection in case it goes through
            if queue_on_teleport then
                queue_on_teleport([[
                    wait(3)
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/StealABrainrot/BaseGuard/main/StealABrainrot_BaseGuard.luau", true))()
                    end)
                ]])
            end
            return nil
        end

        -- Also hook teleport attempt events
        TeleportService.TeleportInitiated:Connect(function()
            if queue_on_teleport then
                queue_on_teleport([[
                    wait(3)
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/StealABrainrot/BaseGuard/main/StealABrainrot_BaseGuard.luau", true))()
                    end)
                ]])
            end
        end)
    end)

    print("[AC Bypass] Initialized")
end

ACBypass.Init()

--// ═══════════════════════════════════════════
--// FIND YOUR BASE
--// ═══════════════════════════════════════════

local MyBase = nil
local MyBaseCenter = nil

local function FindMyBase()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end

    -- Method 1: "YourBase" billboard (most reliable)
    for _, plot in plots:GetChildren() do
        for _, d in plot:GetDescendants() do
            if d:IsA("BillboardGui") and d.Name == "YourBase" then
                return plot
            end
        end
    end

    -- Method 2: Wait for billboard to appear (server assigns it shortly after spawn)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Find the plot the player is standing in
        local closest, closestDist = nil, math.huge
        for _, plot in plots:GetChildren() do
            local mainRoot = plot:FindFirstChild("MainRoot")
            if mainRoot then
                local dist = (mainRoot.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = plot
                end
            end
        end
        return closest
    end

    return nil
end

local function GetBaseBounds(plot)
    if not plot then return nil end

    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    for _, d in plot:GetDescendants() do
        if d:IsA("BasePart") and d.Name == "structure base home" then
            local pos = d.Position
            local size = d.Size
            local hx, hz = size.X / 2, size.Z / 2
            minX = math.min(minX, pos.X - hx)
            maxX = math.max(maxX, pos.X + hx)
            minZ = math.min(minZ, pos.Z - hz)
            maxZ = math.max(maxZ, pos.Z + hz)
            minY = math.min(minY, pos.Y - size.Y / 2)
            maxY = math.max(maxY, pos.Y + size.Y / 2)
        end
    end

    if minX == math.huge then return nil end

    return {
        minX = minX, maxX = maxX,
        minZ = minZ, maxZ = maxZ,
        minY = minY, maxY = maxY,
        centerX = (minX + maxX) / 2,
        centerZ = (minZ + maxZ) / 2,
        widthX = maxX - minX,
        widthZ = maxZ - minZ
    }
end

local function AutoDetectBase()
    MyBase = FindMyBase()
    MyBaseCenter = GetBaseBounds(MyBase)
    if MyBaseCenter then
        print("[Base Guard] Base found: " .. MyBase.Name)
        print("[Base Guard] Center: (" .. MyBaseCenter.centerX .. ", " .. MyBaseCenter.centerZ .. ")")
    else
        warn("[Base Guard] No base found, retrying in 3s...")
    end
    return MyBaseCenter ~= nil
end

AutoDetectBase()

--// ═══════════════════════════════════════════
--// CONFIG
--// ═══════════════════════════════════════════

local Config = {
    -- Base Guard
    IntruderDetection = true,
    DetectionRadius = 30,
    KickIntruders = false,  -- Teleport intruders away
    AlertOnEntry = true,
    IntruderCooldown = 5,

    -- ESP
    PlayerESP = false,
    ESPColor = Color3.fromRGB(255, 0, 0),

    -- Steal Mod
    StealAnimEnabled = false,
    StealAnimId = 94292601332790,
    StealKickSelf = false,
    StealKickDelay = 0.1,
    StealAutoDisconnect = false,

    -- Misc
    InfiniteStamina = false,
    AutoCollect = false,
    AutoSteal = false,
    SpeedBoost = false,
    WalkSpeed = 16,
    JumpPower = 50,
    FlyEnabled = false,
    FlySpeed = 50,
    NoClip = false,
    NightMode = false,
}

--// ═══════════════════════════════════════════
--// INTRUDER DETECTION
--// ═══════════════════════════════════════════

local IntruderCooldowns = {}
local ActiveIntruders = {}

local function IsInBase(position)
    if not MyBaseCenter then return false end

    local margin = 3
    return position.X >= (MyBaseCenter.minX - margin)
        and position.X <= (MyBaseCenter.maxX + margin)
        and position.Z >= (MyBaseCenter.minZ - margin)
        and position.Z <= (MyBaseCenter.maxZ + margin)
        and position.Y >= (MyBaseCenter.minY - 5)
        and position.Y <= (MyBaseCenter.maxY + 5)
end

local function KickPlayer(player)
    -- We can't actually kick from client, so teleport them far away
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(0, 500, 0)
        end
    end

    -- Also try to fire any kick-related remotes (won't work server-side but worth trying)
    pcall(function()
        for _, remote in ReplicatedStorage:GetDescendants() do
            if remote:IsA("RemoteEvent") and remote.Name:lower():find("kick") then
                remote:FireServer(player)
            end
        end
    end)
end

local function AlertIntruder(player)
    StarterGui:SetCore("SendNotification", {
        Title = "BASE ALERT",
        Text = player.Name .. " entered your base!",
        Duration = 5
    })

    -- Highlight the intruder
    local char = player.Character
    if char then
        local existing = char:FindFirstChild("IntruderHighlight")
        if not existing then
            local highlight = Instance.new("Highlight")
            highlight.Name = "IntruderHighlight"
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
            highlight.FillTransparency = 0.5
            highlight.Adornee = char
            highlight.Parent = char

            task.delay(10, function()
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end)
        end
    end
end

--// ═══════════════════════════════════════════
--// PLAYER ESP
--// ═══════════════════════════════════════════

local ESPObjects = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    local function addESP(char)
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "PlayerESP"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Config.ESPColor
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboard

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distLabel.TextStrokeTransparency = 0.5
        distLabel.TextScaled = true
        distLabel.Font = Enum.Font.Gotham
        distLabel.Parent = billboard

        billboard.Parent = char
        ESPObjects[player] = billboard
    end

    if player.Character then
        addESP(player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        addESP(char)
    end)
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function UpdateESPDistances()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for player, billboard in ESPObjects do
        if billboard and billboard.Parent then
            local targetChar = player.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local dist = (targetHRP.Position - hrp.Position).Magnitude
                local distLabel = billboard:FindFirstChildOfClass("TextLabel", true)
                if distLabel then
                    distLabel.Text = math.floor(dist) .. "m"
                end
            end
        end
    end
end

--// ═══════════════════════════════════════════
--// FLY SYSTEM
--// ═══════════════════════════════════════════

local FlyBodyVelocity = nil
local FlyBodyGyro = nil

local function ToggleFly(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    if state then
        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.Parent = hrp

        FlyBodyGyro = Instance.new("BodyGyro")
        FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        FlyBodyGyro.P = 9000
        FlyBodyGyro.D = 500
        FlyBodyGyro.Parent = hrp

        humanoid.PlatformStand = true
    else
        if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
        if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
        humanoid.PlatformStand = false
    end
end

--// ═══════════════════════════════════════════
--// NOCLIP SYSTEM
--// ═══════════════════════════════════════════

local function ToggleNoClip(state)
    Config.NoClip = state
end

--// ═══════════════════════════════════════════
--// STEAL ANIMATION + KICK ON STEAL
--// ═══════════════════════════════════════════

local StealAnimTrack = nil
local WasStealing = false

local function PlayStealAnimation()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    -- Stop existing steal anim if any
    if StealAnimTrack then
        pcall(function() StealAnimTrack:Stop(0) end)
        StealAnimTrack = nil
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. Config.StealAnimId

    local success, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)

    if success and track then
        StealAnimTrack = track
        track.Looped = true
        track.Priority = Enum.AnimationPriority.Action4
        track:Play(0.1, 1, 1)
        print("[Steal Mod] Animation playing (ID: " .. Config.StealAnimId .. ")")
    else
        warn("[Steal Mod] Failed to load animation: " .. tostring(track))
    end
end

local function StopStealAnimation()
    if StealAnimTrack then
        pcall(function()
            StealAnimTrack:Stop(0.2)
        end)
        StealAnimTrack = nil
        print("[Steal Mod] Animation stopped")
    end
end

local function KickSelf()
    -- Queue re-injection BEFORE the kick so we survive the teleport
    if queue_on_teleport then
        queue_on_teleport([[
            wait(3)
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/StealABrainrot/BaseGuard/main/StealABrainrot_BaseGuard.luau", true))()
            end)
        ]])
        print("[Steal Mod] Queued re-injection after kick")
    end

    Rayfield:Notify({
        Title = "KICKED",
        Content = "Kicking self after steal (delay: " .. Config.StealKickDelay .. "s)",
        Duration = Config.StealKickDelay
    })
    task.delay(Config.StealKickDelay, function()
        -- Primary: Kick (will trigger teleport, queue handles re-inject)
        pcall(function() LocalPlayer:Kick("Steal triggered kick") end)
        -- Fallback: teleport way up
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(0, 99999, 0)
            end
        end)
    end)
end

-- Monitor Stealing attribute
local function MonitorStealing()
    local player = LocalPlayer

    local function onStealingChanged()
        local isStealing = player:GetAttribute("Stealing") == true
            or tostring(player:GetAttribute("Stealing")):lower() == "true"

        if isStealing and not WasStealing then
            WasStealing = true
            print("[Steal Mod] Stealing started")

            if Config.StealAnimEnabled then
                PlayStealAnimation()
            end

            if Config.StealKickSelf then
                KickSelf()
            end

        elseif not isStealing and WasStealing then
            WasStealing = false
            print("[Steal Mod] Stealing stopped")
            StopStealAnimation()
        end
    end

    player:GetAttributeChangedSignal("Stealing"):Connect(onStealingChanged)
    onStealingChanged()
end

MonitorStealing()

--// ═══════════════════════════════════════════
--// RAYFIELD GUI
--// ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Steal a Brainrot - Base Guard",
    LoadingTitle = "Base Guard v1.0",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "StealABrainrot",
        FileName = "BaseGuard"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false,
})

--// ─── TAB: Base Guard ──────────────────────

local BaseGuardTab = Window:CreateTab("Base Guard", 4483362458)

BaseGuardTab:CreateSection("Intruder Detection")

BaseGuardTab:CreateToggle({
    Name = "Enable Intruder Detection",
    CurrentValue = Config.IntruderDetection,
    Flag = "IntruderDetection",
    Callback = function(state)
        Config.IntruderDetection = state
    end,
})

BaseGuardTab:CreateToggle({
    Name = "Kick/Teleport Intruders Away",
    CurrentValue = Config.KickIntruders,
    Flag = "KickIntruders",
    Callback = function(state)
        Config.KickIntruders = state
    end,
})

BaseGuardTab:CreateToggle({
    Name = "Alert on Base Entry",
    CurrentValue = Config.AlertOnEntry,
    Flag = "AlertOnEntry",
    Callback = function(state)
        Config.AlertOnEntry = state
    end,
})

BaseGuardTab:CreateSlider({
    Name = "Detection Radius",
    Range = {5, 60},
    Increment = 1,
    CurrentValue = Config.DetectionRadius,
    Flag = "DetectionRadius",
    Callback = function(state)
        Config.DetectionRadius = state
    end,
})

BaseGuardTab:CreateButton({
    Name = "Recalibrate Base",
    Callback = function()
        AutoDetectBase()
        if MyBaseCenter then
            Rayfield:Notify({
                Title = "Base Recalibrated",
                Content = string.format("Center: (%.0f, %.0f) | Size: %.0f x %.0f",
                    MyBaseCenter.centerX, MyBaseCenter.centerZ,
                    MyBaseCenter.widthX, MyBaseCenter.widthZ),
                Duration = 5
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Could not find your base! Try respawning.",
                Duration = 3
            })
        end
    end,
})

BaseGuardTab:CreateSection("Intruder Log")
BaseGuardTab:CreateLabel("No intruders detected yet")

--// ─── TAB: Player ──────────────────────────

local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = Config.SpeedBoost,
    Flag = "SpeedBoost",
    Callback = function(state)
        Config.SpeedBoost = state
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = state and Config.WalkSpeed or 16
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = Config.WalkSpeed,
    Flag = "WalkSpeed",
    Callback = function(state)
        Config.WalkSpeed = state
        if Config.SpeedBoost then
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = state
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 5,
    CurrentValue = Config.JumpPower,
    Flag = "JumpPower",
    Callback = function(state)
        Config.JumpPower = state
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = state
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = Config.FlyEnabled,
    Flag = "FlyEnabled",
    Callback = function(state)
        Config.FlyEnabled = state
        ToggleFly(state)
    end,
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = Config.FlySpeed,
    Flag = "FlySpeed",
    Callback = function(state)
        Config.FlySpeed = state
    end,
})

PlayerTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = Config.NoClip,
    Flag = "NoClip",
    Callback = function(state)
        ToggleNoClip(state)
    end,
})

PlayerTab:CreateSection("Visuals")

PlayerTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = Config.PlayerESP,
    Flag = "PlayerESP",
    Callback = function(state)
        Config.PlayerESP = state
        if state then
            for _, player in Players:GetPlayers() do
                CreateESP(player)
            end
        else
            for player, _ in ESPObjects do
                RemoveESP(player)
            end
        end
    end,
})

PlayerTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Config.ESPColor,
    Flag = "ESPColor",
    Callback = function(value)
        Config.ESPColor = value
        for _, billboard in ESPObjects do
            local label = billboard and billboard:FindFirstChildOfClass("TextLabel")
            if label then
                label.TextColor3 = value
            end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Night Mode",
    CurrentValue = Config.NightMode,
    Flag = "NightMode",
    Callback = function(state)
        Config.NightMode = state
        if state then
            Workspace.ClockTime = 0
        else
            Workspace.ClockTime = 14
        end
    end,
})

--// ─── TAB: Steal Mod ───────────────────────

local StealTab = Window:CreateTab("Steal Mod", 4483362458)

StealTab:CreateSection("Steal Animation")

StealTab:CreateToggle({
    Name = "Play Animation When Stealing",
    CurrentValue = Config.StealAnimEnabled,
    Flag = "StealAnimEnabled",
    Callback = function(state)
        Config.StealAnimEnabled = state
        if not state then
            StopStealAnimation()
        end
    end,
})

StealTab:CreateInput({
    Name = "Animation ID",
    PlaceholderText = tostring(Config.StealAnimId),
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local id = tonumber(text:match("%d+"))
        if id then
            Config.StealAnimId = id
            StopStealAnimation()
            Rayfield:Notify({
                Title = "Animation Updated",
                Content = "New ID: " .. id,
                Duration = 3
            })
        end
    end,
})

StealTab:CreateSection("Self Kick on Steal")

StealTab:CreateToggle({
    Name = "Kick Self After Stealing",
    CurrentValue = Config.StealKickSelf,
    Flag = "StealKickSelf",
    Callback = function(state)
        Config.StealKickSelf = state
    end,
})

StealTab:CreateSlider({
    Name = "Kick Delay (seconds)",
    Range = {0.1, 5},
    Increment = 0.1,
    CurrentValue = Config.StealKickDelay,
    Flag = "StealKickDelay",
    Callback = function(state)
        Config.StealKickDelay = state
    end,
})

StealTab:CreateSection("How it works")
StealTab:CreateLabel("Monitors the 'Stealing' attribute on your character.")
StealTab:CreateLabel("When stealing starts: plays animation + optionally kicks you.")
StealTab:CreateLabel("When stealing stops: animation stops automatically.")
StealTab:CreateLabel("Base auto-detects via 'YourBase' billboard on respawn.")

--// ─── TAB: Anti-Cheat ──────────────────────

local ACTab = Window:CreateTab("Anti-Cheat", 4483362458)

ACTab:CreateSection("Bypass Status")
ACTab:CreateLabel("Namecall hook: Active")
ACTab:CreateLabel("Index hook: Active")
ACTab:CreateLabel("Remote filter: Active")

ACTab:CreateButton({
    Name = "Re-Initialize Bypass",
    Callback = function()
        ACBypass.Init()
        Rayfield:Notify({
            Title = "Anti-Cheat",
            Content = "Bypass re-initialized!",
            Duration = 3
        })
    end,
})

ACTab:CreateSection("Remote Spy")
ACTab:CreateButton({
    Name = "Log Active Remotes",
    Callback = function()
        local remotes = {}
        for _, v in ReplicatedStorage:GetDescendants() do
            if v:IsA("RemoteEvent") then
                table.insert(remotes, v.Name)
            end
        end
        Rayfield:Notify({
            Title = "Remotes Found",
            Content = #remotes .. " RemoteEvents in ReplicatedStorage",
            Duration = 5
        })
    end,
})

--// ─── TAB: Info ────────────────────────────

local InfoTab = Window:CreateTab("Info", 4483362458)

InfoTab:CreateSection("Base Info")
InfoTab:CreateLabel("Base: " .. (MyBase and MyBase.Name:sub(1, 12) .. "..." or "Detecting..."))
InfoTab:CreateLabel("Center: " .. (MyBaseCenter and string.format("(%.0f, %.0f)", MyBaseCenter.centerX, MyBaseCenter.centerZ) or "N/A"))
InfoTab:CreateButton({
    Name = "Refresh Base Info",
    Callback = function()
        AutoDetectBase()
        if MyBase then
            Rayfield:Notify({
                Title = "Base Refreshed",
                Content = MyBase.Name:sub(1, 12) .. "...",
                Duration = 3
            })
        end
    end,
})

InfoTab:CreateSection("Players in Server")
for _, player in Players:GetPlayers() do
    if player ~= LocalPlayer then
        InfoTab:CreateLabel(player.Name .. " (ID: " .. player.UserId .. ")")
    end
end

--// ═══════════════════════════════════════════
--// MAIN LOOPS
--// ═══════════════════════════════════════════

-- NoClip loop
RunService.Stepped:Connect(function()
    if Config.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, part in char:GetDescendants() do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Fly loop
RunService.Heartbeat:Connect(function()
    if Config.FlyEnabled and FlyBodyVelocity and FlyBodyGyro then
        local cam = Workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * Config.FlySpeed
        end

        FlyBodyVelocity.Velocity = moveDir
        FlyBodyGyro.CFrame = cam.CFrame
    end
end)

-- Intruder detection loop
task.spawn(function()
    while true do
        task.wait(0.5)

        if Config.IntruderDetection and MyBaseCenter then
            for _, player in Players:GetPlayers() do
                if player ~= LocalPlayer then
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                    if hrp then
                        local isInside = IsInBase(hrp.Position)
                        local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) -
                            Vector3.new(MyBaseCenter.centerX, 0, MyBaseCenter.centerZ)).Magnitude

                        if isInside or dist <= Config.DetectionRadius then
                            local now = tick()
                            if not IntruderCooldowns[player] or (now - IntruderCooldowns[player] > Config.IntruderCooldown) then
                                IntruderCooldowns[player] = now
                                ActiveIntruders[player] = true

                                if Config.AlertOnEntry then
                                    AlertIntruder(player)
                                end

                                if Config.KickIntruders then
                                    KickPlayer(player)
                                end
                            end
                        else
                            if ActiveIntruders[player] then
                                ActiveIntruders[player] = nil
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ESP distance update loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.PlayerESP then
            UpdateESPDistances()
        end
    end
end)

-- Respawn handler - re-detect base on every respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(2)

    -- Re-detect base (it changes each time)
    local found = false
    for attempt = 1, 10 do
        if AutoDetectBase() then
            found = true
            break
        end
        task.wait(1)
    end

    if not found then
        warn("[Base Guard] Could not find base after 10 attempts")
    end

    if Config.SpeedBoost then
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.WalkSpeed = Config.WalkSpeed
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Config.JumpPower
    end
    if Config.FlyEnabled then
        ToggleFly(false)
        task.wait(0.5)
        ToggleFly(true)
    end
end)

-- Billboard watcher: detect when "YourBase" moves to a different plot
task.spawn(function()
    local lastBaseName = MyBase and MyBase.Name or ""
    while true do
        task.wait(2)
        local plots = Workspace:FindFirstChild("Plots")
        if plots then
            for _, plot in plots:GetChildren() do
                for _, d in plot:GetDescendants() do
                    if d:IsA("BillboardGui") and d.Name == "YourBase" then
                        if plot.Name ~= lastBaseName then
                            lastBaseName = plot.Name
                            MyBase = plot
                            MyBaseCenter = GetBaseBounds(plot)
                            if MyBaseCenter then
                                Rayfield:Notify({
                                    Title = "Base Changed!",
                                    Content = "New base detected: " .. plot.Name:sub(1, 8) .. "...",
                                    Duration = 5
                                })
                                print("[Base Guard] Base reassigned -> " .. plot.Name)
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end)

-- Player join/leave
Players.PlayerAdded:Connect(function(player)
    if Config.PlayerESP then
        CreateESP(player)
    end
    Rayfield:Notify({
        Title = "Player Joined",
        Content = player.Name .. " joined the server",
        Duration = 3
    })
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    ActiveIntruders[player] = nil
    IntruderCooldowns[player] = nil
end)

--// ═══════════════════════════════════════════
--// INIT
--// ═══════════════════════════════════════════

Rayfield:Notify({
    Title = "Base Guard Loaded",
    Content = "Anti-Cheat Bypass Active | Base Detection Ready",
    Duration = 5
})

print("[Base Guard] Script loaded successfully")
print("[Base Guard] Base Center: " .. (MyBaseCenter and string.format("(%.0f, %.0f)", MyBaseCenter.centerX, MyBaseCenter.centerZ) or "N/A"))
