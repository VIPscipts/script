local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local farmDepth = -50         
local targetNames = { "Coin", "EventOrb", "Candy", "Orb" }
local coinLimit = 40          
local voidY = -5000           
local teleportCooldown = 0.3  
local lastTeleport = 0

local function makeInvisible()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
            part.CanCollide = false
        end
    end
end

local function findTargets()
    local found = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and table.find(targetNames, obj.Name) then
            table.insert(found, obj)
        end
    end
    return found
end

local function smoothMoveTo(targetPos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dir = (targetPos - hrp.Position)
    if dir.Magnitude < 5 then
        hrp.CFrame = CFrame.new(targetPos.X, targetPos.Y + farmDepth, targetPos.Z)
    else
        local step = dir.Unit * 5
        local nextPos = hrp.Position + step
        hrp.CFrame = CFrame.new(nextPos.X, nextPos.Y + farmDepth, nextPos.Z)
    end
end

local function findMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p:FindFirstChild("Role") and p.Role.Value == "Murderer" then
            return p
        end
    end
    return nil
end

local function yeetMurderer()
    local m = findMurderer()
    if m and m.Character and m.Character:FindFirstChild("HumanoidRootPart") then
        m.Character.HumanoidRootPart.CFrame = CFrame.new(0, voidY, 0)
    end
end

local function hasMaxCoins()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if not stats then return false end
    for _, v in pairs(stats:GetChildren()) do
        if v:IsA("IntValue") and (v.Name == "Coins" or v.Name == "Points") and v.Value >= coinLimit then
            return true
        end
    end
    return false
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Freefall then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 10, 0)
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then return end

    -- Остановка, если нет leaderstats (античит может наблюдать)
    if not LocalPlayer:FindFirstChild("leaderstats") then
        warn("⚠️ Скрипт отключён: leaderstats не найдены (возможный патруль).")
        return
    end

    makeInvisible()

    if hasMaxCoins() then
        yeetMurderer()
    end

    local targets = findTargets()
    table.sort(targets, function(a, b)
        local h = LocalPlayer.Character.HumanoidRootPart.Position
        return (a.Position - h).Magnitude < (b.Position - h).Magnitude
    end)

    local now = tick()
    if #targets > 0 and (now - lastTeleport) > teleportCooldown then
        lastTeleport = now
        smoothMoveTo(targets[1].Position)
    end
end)

print("✅ Safe Collector Script активирован. Античит-защита включена.")
