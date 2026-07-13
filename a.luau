--// Steal a Brainrot - Base Guard
--// Rejoin → Wait for GUI → Run everything

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

--// ═══════════════════════════════════════════
--// STEP 1: CHECK IF WE ALREADY REJOINED
--// ═══════════════════════════════════════════

if _G.BaseGuardLoaded then
    -- Already rejoined, skip to full script
else
    _G.BaseGuardLoaded = true

    -- Queue re-execution after teleport
    if queue_on_teleport then
        queue_on_teleport([[
            _G.BaseGuardLoaded = true
            -- Wait for PlayerGui
            local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui", 30)
            if pg then
                pg:WaitForChild("ScreenGui", 15)
            end
            -- Wait for character
            local char = game.Players.LocalPlayer:WaitForChild("Character", 15)
            if char then
                char:WaitForChild("HumanoidRootPart", 10)
            end
            -- Extra settle time
            task.wait(3)
            -- Run the full script
            loadstring(game:HttpGet("https://raw.githubusercontent.com/deebee003/laughing-giggle/refs/heads/main/a.luau", true))()
        ]])
    end

    -- Force rejoin
    print("[Base Guard] Rejoining...")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
    return
end

--// ═══════════════════════════════════════════
--// FULL SCRIPT (runs after rejoin)
--// ═══════════════════════════════════════════

--// SERVICES
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Workspace = game:GetService("Workspace")

--// RAYFIELD LOADER
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// ═══════════════════════════════════════════
--// QUEUE ON TELEPORT
--// ═══════════════════════════════════════════

if queue_on_teleport then
    queue_on_teleport([[
        _G.BaseGuardLoaded = true
        local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui", 30)
        if pg then pg:WaitForChild("ScreenGui", 15) end
        local char = game.Players.LocalPlayer:WaitForChild("Character", 15)
        if char then char:WaitForChild("HumanoidRootPart", 10) end
        task.wait(3)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/deebee003/laughing-giggle/refs/heads/main/a.luau", true))()
    ]])
end

--// ═══════════════════════════════════════════
--// ANTI-CHEAT BYPASS
--// ═══════════════════════════════════════════

local ACBypass = {}
function ACBypass.Init()
    if writefile then
        pcall(function()
            writefile("StealABrainrot_BaseGuard.luau", game:HttpGet("https://raw.githubusercontent.com/deebee003/laughing-giggle/refs/heads/main/a.luau", true))
        end)
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local name = tostring(self.Name):lower()
            local blocked = {"anticheat","ac_","report","detect","flag","speed","fly","teleport","noclip","exploit","ban","kick","cheat","hack","inject"}
            for _, p in blocked do
                if name:find(p) then return nil end
            end
        end
        if method == "Teleport" or method == "TeleportToPlaceInstance" then
            return nil
        end
        return oldNamecall(self, ...)
    end)

    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if self == game and typeof(key) == "string" then
            for _, v in {"Kick","Shutdown"} do
                if key == v then return function() end end
            end
        end
        return oldIndex(self, key)
    end))

    pcall(function()
        local TS = game:GetService("TeleportService")
        local old = TS.Teleport
        TS.Teleport = function(self, ...)
            if queue_on_teleport then
                queue_on_teleport([[
                    _G.BaseGuardLoaded = true
                    task.wait(3)
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/deebee003/laughing-giggle/refs/heads/main/a.luau", true))()
                ]])
            end
            return nil
        end
    end)

    print("[AC Bypass] Initialized")
end
ACBypass.Init()

--// ═══════════════════════════════════════════
--// FIND YOUR BASE (with dedup)
--// ═══════════════════════════════════════════

local MyBase = nil
local MyBaseCenter = nil

local function GetBaseBounds(plot)
    if not plot then return nil end
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    for _, d in plot:GetDescendants() do
        if d:IsA("BasePart") and d.Name == "structure base home" then
            local p, s = d.Position, d.Size
            minX = math.min(minX, p.X - s.X/2)
            maxX = math.max(maxX, p.X + s.X/2)
            minZ = math.min(minZ, p.Z - s.Z/2)
            maxZ = math.max(maxZ, p.Z + s.Z/2)
            minY = math.min(minY, p.Y - s.Y/2)
            maxY = math.max(maxY, p.Y + s.Y/2)
        end
    end
    if minX == math.huge then return nil end
    return { minX=minX, maxX=maxX, minZ=minZ, maxZ=maxZ, minY=minY, maxY=maxY,
             centerX=(minX+maxX)/2, centerZ=(minZ+maxZ)/2, widthX=maxX-minX, widthZ=maxZ-minZ }
end

local function FindMyBase()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in plots:GetChildren() do
        for _, d in plot:GetDescendants() do
            if d:IsA("BillboardGui") and d.Name == "YourBase" then
                return plot
            end
        end
    end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local closest, closestDist = nil, math.huge
        for _, plot in plots:GetChildren() do
            local mr = plot:FindFirstChild("MainRoot")
            if mr then
                local dist = (mr.Position - hrp.Position).Magnitude
                if dist < closestDist then closestDist = dist; closest = plot end
            end
        end
        return closest
    end
    return nil
end

local function AutoDetectBase()
    MyBase = FindMyBase()
    MyBaseCenter = GetBaseBounds(MyBase)
    if MyBaseCenter then
        print("[Base Guard] Base found: " .. MyBase.Name)
    else
        warn("[Base Guard] No base found")
    end
    return MyBaseCenter ~= nil
end

AutoDetectBase()

--// ═══════════════════════════════════════════
--// CONFIG
--// ═══════════════════════════════════════════

local Config = {
    IntruderDetection = true,
    DetectionRadius = 30,
    KickIntruders = false,
    AlertOnEntry = true,
    IntruderCooldown = 5,
    PlayerESP = false,
    ESPColor = Color3.fromRGB(255, 0, 0),
    StealAnimEnabled = false,
    StealAnimId = 94292601332790,
    StealKickSelf = false,
    StealKickDelay = 0.1,
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

local function IsInBase(pos)
    if not MyBaseCenter then return false end
    local m = 3
    return pos.X >= (MyBaseCenter.minX - m) and pos.X <= (MyBaseCenter.maxX + m)
       and pos.Z >= (MyBaseCenter.minZ - m) and pos.Z <= (MyBaseCenter.maxZ + m)
       and pos.Y >= (MyBaseCenter.minY - 5) and pos.Y <= (MyBaseCenter.maxY + 5)
end

local function KickPlayer(player)
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(0, 500, 0) end
    end
end

local function AlertIntruder(player)
    StarterGui:SetCore("SendNotification", {
        Title = "BASE ALERT",
        Text = player.Name .. " entered your base!",
        Duration = 5
    })
    local char = player.Character
    if char and not char:FindFirstChild("IntruderHighlight") then
        local h = Instance.new("Highlight")
        h.Name = "IntruderHighlight"
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.fromRGB(255, 255, 0)
        h.FillTransparency = 0.5
        h.Adornee = char
        h.Parent = char
        task.delay(10, function() if h and h.Parent then h:Destroy() end end)
    end
end

--// ═══════════════════════════════════════════
--// PLAYER ESP
--// ═══════════════════════════════════════════

local ESPObjects = {}

local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local function addESP(char)
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "PlayerESP"
        bb.Adornee = hrp
        bb.Size = UDim2.new(0, 100, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, 0, 0.5, 0)
        nl.BackgroundTransparency = 1
        nl.Text = player.Name
        nl.TextColor3 = Config.ESPColor
        nl.TextStrokeTransparency = 0.5
        nl.TextScaled = true
        nl.Font = Enum.Font.GothamBold
        nl.Parent = bb
        local dl = Instance.new("TextLabel")
        dl.Size = UDim2.new(1, 0, 0.5, 0)
        dl.Position = UDim2.new(0, 0, 0.5, 0)
        dl.BackgroundTransparency = 1
        dl.Text = "0m"
        dl.TextColor3 = Color3.fromRGB(255,255,255)
        dl.TextStrokeTransparency = 0.5
        dl.TextScaled = true
        dl.Font = Enum.Font.Gotham
        dl.Parent = bb
        bb.Parent = char
        ESPObjects[player] = bb
    end
    if player.Character then addESP(player.Character) end
    player.CharacterAdded:Connect(function(c) task.wait(1); addESP(c) end)
end

local function RemoveESP(player)
    if ESPObjects[player] then ESPObjects[player]:Destroy(); ESPObjects[player] = nil end
end

--// ═══════════════════════════════════════════
--// FLY SYSTEM
--// ═══════════════════════════════════════════

local FlyBV, FlyBG = nil, nil

local function ToggleFly(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if state then
        FlyBV = Instance.new("BodyVelocity"); FlyBV.MaxForce = Vector3.one * math.huge; FlyBV.Velocity = Vector3.zero; FlyBV.Parent = hrp
        FlyBG = Instance.new("BodyGyro"); FlyBG.MaxTorque = Vector3.one * math.huge; FlyBG.P = 9000; FlyBG.D = 500; FlyBG.Parent = hrp
        hum.PlatformStand = true
    else
        if FlyBV then FlyBV:Destroy(); FlyBV = nil end
        if FlyBG then FlyBG:Destroy(); FlyBG = nil end
        hum.PlatformStand = false
    end
end

--// ═══════════════════════════════════════════
--// STEAL ANIMATION + KICK
--// ═══════════════════════════════════════════

local StealAnimTrack, WasStealing = nil, false

local function PlayStealAnimation()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. Config.StealAnimId
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    if StealAnimTrack then pcall(function() StealAnimTrack:Stop(0) end); StealAnimTrack = nil end
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        StealAnimTrack = track; track.Looped = true; track.Priority = Enum.AnimationPriority.Action4; track:Play(0.1, 1, 1)
    end
end

local function StopStealAnimation()
    if StealAnimTrack then pcall(function() StealAnimTrack:Stop(0.2) end); StealAnimTrack = nil end
end

local function KickSelf()
    if queue_on_teleport then
        queue_on_teleport([[
            _G.BaseGuardLoaded = true
            local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui", 30)
            if pg then pg:WaitForChild("ScreenGui", 15) end
            task.wait(3)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/deebee003/laughing-giggle/refs/heads/main/a.luau", true))()
        ]])
    end
    Rayfield:Notify({ Title = "KICKED", Content = "Kicking after steal...", Duration = Config.StealKickDelay })
    task.delay(Config.StealKickDelay, function()
        pcall(function() LocalPlayer:Kick("Steal triggered kick") end)
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(0, 99999, 0) end
        end)
    end)
end

LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
    local isStealing = tostring(LocalPlayer:GetAttribute("Stealing")):lower() == "true"
    if isStealing and not WasStealing then
        WasStealing = true
        if Config.StealAnimEnabled then PlayStealAnimation() end
        if Config.StealKickSelf then KickSelf() end
    elseif not isStealing and WasStealing then
        WasStealing = false
        StopStealAnimation()
    end
end)

--// ═══════════════════════════════════════════
--// RAYFIELD GUI
--// ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "Steal a Brainrot - Base Guard",
    LoadingTitle = "Base Guard v1.0",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = { Enabled = true, FolderName = "StealABrainrot", FileName = "BaseGuard" },
    Discord = { Enabled = false },
    KeySystem = false,
})

--// BASE GUARD TAB
local BGTab = Window:CreateTab("Base Guard", 4483362458)
BGTab:CreateSection("Intruder Detection")
BGTab:CreateToggle({ Name = "Enable Intruder Detection", CurrentValue = Config.IntruderDetection, Flag = "ID", Callback = function(s) Config.IntruderDetection = s end })
BGTab:CreateToggle({ Name = "Kick Intruders Away", CurrentValue = Config.KickIntruders, Flag = "KI", Callback = function(s) Config.KickIntruders = s end })
BGTab:CreateToggle({ Name = "Alert on Entry", CurrentValue = Config.AlertOnEntry, Flag = "AE", Callback = function(s) Config.AlertOnEntry = s end })
BGTab:CreateSlider({ Name = "Detection Radius", Range = {5, 60}, Increment = 1, CurrentValue = Config.DetectionRadius, Flag = "DR", Callback = function(s) Config.DetectionRadius = s end })
BGTab:CreateButton({ Name = "Recalibrate Base", Callback = function()
    AutoDetectBase()
    if MyBaseCenter then
        Rayfield:Notify({ Title = "Recalibrated", Content = string.format("(%.0f, %.0f)", MyBaseCenter.centerX, MyBaseCenter.centerZ), Duration = 3 })
    else
        Rayfield:Notify({ Title = "Error", Content = "No base found!", Duration = 3 })
    end
end })

--// PLAYER TAB
local PTab = Window:CreateTab("Player", 4483362458)
PTab:CreateSection("Movement")
PTab:CreateToggle({ Name = "Speed Boost", CurrentValue = Config.SpeedBoost, Flag = "SB", Callback = function(s) Config.SpeedBoost = s; local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = s and Config.WalkSpeed or 16 end end })
PTab:CreateSlider({ Name = "Walk Speed", Range = {16, 100}, Increment = 1, CurrentValue = Config.WalkSpeed, Flag = "WS", Callback = function(s) Config.WalkSpeed = s; if Config.SpeedBoost then local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = s end end end })
PTab:CreateSlider({ Name = "Jump Power", Range = {50, 200}, Increment = 5, CurrentValue = Config.JumpPower, Flag = "JP", Callback = function(s) Config.JumpPower = s; local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.UseJumpPower = true; h.JumpPower = s end end })
PTab:CreateToggle({ Name = "Fly", CurrentValue = Config.FlyEnabled, Flag = "FL", Callback = function(s) Config.FlyEnabled = s; ToggleFly(s) end })
PTab:CreateSlider({ Name = "Fly Speed", Range = {10, 200}, Increment = 5, CurrentValue = Config.FlySpeed, Flag = "FS", Callback = function(s) Config.FlySpeed = s end })
PTab:CreateToggle({ Name = "NoClip", CurrentValue = Config.NoClip, Flag = "NC", Callback = function(s) Config.NoClip = s end })
PTab:CreateSection("Visuals")
PTab:CreateToggle({ Name = "Player ESP", CurrentValue = Config.PlayerESP, Flag = "PE", Callback = function(s) Config.PlayerESP = s; if s then for _,p in Players:GetPlayers() do CreateESP(p) end else for p in ESPObjects do RemoveESP(p) end end end })
PTab:CreateToggle({ Name = "Night Mode", CurrentValue = Config.NightMode, Flag = "NM", Callback = function(s) Config.NightMode = s; Workspace.ClockTime = s and 0 or 14 end })

--// STEAL MOD TAB
local STab = Window:CreateTab("Steal Mod", 4483362458)
STab:CreateSection("Animation")
STab:CreateToggle({ Name = "Play Anim When Stealing", CurrentValue = Config.StealAnimEnabled, Flag = "SA", Callback = function(s) Config.StealAnimEnabled = s; if not s then StopStealAnimation() end end })
STab:CreateInput({ Name = "Animation ID", PlaceholderText = tostring(Config.StealAnimId), RemoveTextAfterFocusLost = false, Callback = function(t) local id = tonumber(t:match("%d+")); if id then Config.StealAnimId = id; StopStealAnimation() end end })
STab:CreateSection("Self Kick")
STab:CreateToggle({ Name = "Kick Self After Steal", CurrentValue = Config.StealKickSelf, Flag = "SK", Callback = function(s) Config.StealKickSelf = s end })
STab:CreateSlider({ Name = "Kick Delay", Range = {0.1, 5}, Increment = 0.1, CurrentValue = Config.StealKickDelay, Flag = "KD", Callback = function(s) Config.StealKickDelay = s end })
STab:CreateLabel("Monitors 'Stealing' attribute. Plays anim + kicks on steal.")

--// ANTI-CHEAT TAB
local ACTab = Window:CreateTab("Anti-Cheat", 4483362458)
ACTab:CreateLabel("Namecall hook: Active")
ACTab:CreateLabel("Index hook: Active")
ACTab:CreateLabel("Remote filter: Active")
ACTab:CreateButton({ Name = "Re-Init Bypass", Callback = function() ACBypass.Init(); Rayfield:Notify({ Title = "AC", Content = "Re-initialized!", Duration = 2 }) end })

--// INFO TAB
local ITab = Window:CreateTab("Info", 4483362458)
ITab:CreateLabel("Base: " .. (MyBase and MyBase.Name:sub(1,12).."..." or "Detecting..."))
ITab:CreateLabel("Center: " .. (MyBaseCenter and string.format("(%.0f, %.0f)", MyBaseCenter.centerX, MyBaseCenter.centerZ) or "N/A"))
ITab:CreateButton({ Name = "Refresh Base", Callback = function() AutoDetectBase() end })
for _, p in Players:GetPlayers() do
    if p ~= LocalPlayer then ITab:CreateLabel(p.Name) end
end

--// ═══════════════════════════════════════════
--// MAIN LOOPS
--// ═══════════════════════════════════════════

RunService.Stepped:Connect(function()
    if Config.NoClip then
        local char = LocalPlayer.Character
        if char then for _, p in char:GetDescendants() do if p:IsA("BasePart") then p.CanCollide = false end end end
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.FlyEnabled and FlyBV and FlyBG then
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
        FlyBG.CFrame = cam.CFrame
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.IntruderDetection and MyBaseCenter then
            for _, p in Players:GetPlayers() do
                if p ~= LocalPlayer then
                    local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local inside = IsInBase(hrp.Position)
                        local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(MyBaseCenter.centerX, 0, MyBaseCenter.centerZ)).Magnitude
                        if inside or dist <= Config.DetectionRadius then
                            local now = tick()
                            if not IntruderCooldowns[p] or (now - IntruderCooldowns[p] > Config.IntruderCooldown) then
                                IntruderCooldowns[p] = now
                                ActiveIntruders[p] = true
                                if Config.AlertOnEntry then AlertIntruder(p) end
                                if Config.KickIntruders then KickPlayer(p) end
                            end
                        else
                            ActiveIntruders[p] = nil
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.PlayerESP then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for p, bb in ESPObjects do
                    if bb and bb.Parent then
                        local t = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                        if t then
                            local dl = bb:FindFirstChildOfClass("TextLabel", true)
                            if dl then dl.Text = math.floor((t.Position - hrp).Magnitude) .. "m" end
                        end
                    end
                end
            end
        end
    end
end)

--// BASE WATCHER (deduped)
task.spawn(function()
    local lastBaseName = MyBase and MyBase.Name or ""
    while true do
        task.wait(3)
        local plots = Workspace:FindFirstChild("Plots")
        if plots then
            local foundBase = nil
            for _, plot in plots:GetChildren() do
                for _, d in plot:GetDescendants() do
                    if d:IsA("BillboardGui") and d.Name == "YourBase" then
                        foundBase = plot
                        break
                    end
                end
                if foundBase then break end
            end
            if foundBase and foundBase.Name ~= lastBaseName then
                lastBaseName = foundBase.Name
                MyBase = foundBase
                MyBaseCenter = GetBaseBounds(foundBase)
                if MyBaseCenter then
                    print("[Base Guard] Base changed -> " .. foundBase.Name)
                end
            end
        end
    end
end)

--// RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(2)
    for i = 1, 10 do if AutoDetectBase() then break end; task.wait(1) end
    if Config.SpeedBoost then
        local h = char:WaitForChild("Humanoid")
        h.WalkSpeed = Config.WalkSpeed; h.UseJumpPower = true; h.JumpPower = Config.JumpPower
    end
    if Config.FlyEnabled then ToggleFly(false); task.wait(0.5); ToggleFly(true) end
end)

Players.PlayerAdded:Connect(function(p) if Config.PlayerESP then CreateESP(p) end end)
Players.PlayerRemoving:Connect(function(p) RemoveESP(p); ActiveIntruders[p] = nil; IntruderCooldowns[p] = nil end)

--// INIT
Rayfield:Notify({ Title = "Base Guard Loaded", Content = "AC Bypass Active | Base Detection Ready", Duration = 5 })
print("[Base Guard] Script loaded")
