local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local autofarmEnabled = false
local lastTeleport = 0
local teleportCooldown = 0.3
local coinLimit = 40
local farmDepth = -50
local voidY = -5000
local targetNames = { "Coin", "EventOrb", "Candy", "Orb" }

-- Очистка старого GUI
if CoreGui:FindFirstChild("MM2FarmUI") then
    CoreGui.MM2FarmUI:Destroy()
end

-- Создание GUI
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "MM2FarmUI"

local button = Instance.new("TextButton", gui)
button.Size = UDim2.new(0, 180, 0, 40)
button.Position = UDim2.new(0, 10, 0, 10)
button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.Text = "Включить автофарм"

button.MouseButton1Click:Connect(function()
    autofarmEnabled = not autofarmEnabled
    button.Text = autofarmEnabled and "Выключить автофарм" or "Включить автофарм"
end)

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

local function moveTo(pos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = CFrame.new(pos.X, pos.Y + farmDepth, pos.Z)
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

local function findMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p:FindFirstChild("Role") and p.Role.Value == "Murderer" then
            return p
        end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    if not autofarmEnabled then return end
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then return end
    if not LocalPlayer:FindFirstChild("leaderstats") then return end

    makeInvisible()

    if hasMaxCoins() then
        local murderer = findMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = murderer.Character.HumanoidRootPart
            if hrp.Position.Y > -4000 then
                hrp.CFrame = CFrame.new(0, voidY, 0)
            end
        end
    end

    local targets = findTargets()
    table.sort(targets, function(a, b)
        local h = LocalPlayer.Character.HumanoidRootPart.Position
        return (a.Position - h).Magnitude < (b.Position - h).Magnitude
    end)

    local now = tick()
    if #targets > 0 and (now - lastTeleport) > teleportCooldown then
        lastTeleport = now
        moveTo(targets[1].Position)
    end
end)