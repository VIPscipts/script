local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local farmDepth = -50         
local targetNames = { "Coin", "EventOrb", "Candy", "Orb" }
local coinLimit = 40          
local voidY = -5000           
local teleportCooldown = 0.3  
local lastTeleport = 0
local autofarmEnabled = false

-- UI уже создан?
if game.CoreGui:FindFirstChild("MM2FarmUI") then
    game.CoreGui.MM2FarmUI:Destroy()
end

-- Создание GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "MM2FarmUI"
ScreenGui.ResetOnSpawn = false

-- Кнопка открытия меню
local openButton = Instance.new("TextButton", ScreenGui)
openButton.Size = UDim2.new(0, 120, 0, 30)
openButton.Position = UDim2.new(0, 10, 0, 10)
openButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Text = "Открыть меню"
openButton.Font = Enum.Font.SourceSansBold
openButton.TextSize = 16

-- Основное окно меню
local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Visible = false

-- Заголовок
local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "MM2 Farm Menu"
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 18

-- Кнопка включения/выключения фарма
local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(1, -20, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Text = "Включить авто-сбор"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 16

-- Лейбл статуса
local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 80)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.Text = "Статус: Выключено"

-- Кнопка выброса мардера
local yeetButton = Instance.new("TextButton", mainFrame)
yeetButton.Size = UDim2.new(1, -20, 0, 30)
yeetButton.Position = UDim2.new(0, 10, 0, 115)
yeetButton.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
yeetButton.TextColor3 = Color3.new(1, 1, 1)
yeetButton.Font = Enum.Font.SourceSansBold
yeetButton.TextSize = 14
yeetButton.Text = "Принудительно завершить раунд"

-- Обработчики кнопок
openButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

toggleButton.MouseButton1Click:Connect(function()
    autofarmEnabled = not autofarmEnabled
    toggleButton.Text = autofarmEnabled and "Выключить авто-сбор" or "Включить авто-сбор"
    statusLabel.Text = "Статус: " .. (autofarmEnabled and "Включено" or "Выключено")
end)

yeetButton.MouseButton1Click:Connect(function()
    local function findMurderer()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p:FindFirstChild("Role") and p.Role.Value == "Murderer" then
                return p
            end
        end
        return nil
    end
    local m = findMurderer()
    if m and m.Character and m.Character:FindFirstChild("HumanoidRootPart") then
        m.Character.HumanoidRootPart.CFrame = CFrame.new(0, -5000, 0)
    end
end)

-- Фарм логика
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

RunService.Heartbeat:Connect(function()
    if not autofarmEnabled then return end
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then return end
    if not LocalPlayer:FindFirstChild("leaderstats") then return end

    makeInvisible()

    if hasMaxCoins() then
        yeetButton:MouseButton1Click()
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

print("✅ MM2 GUI Farm загружен.")