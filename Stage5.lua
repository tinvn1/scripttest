local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

print("[💀 STAGE 5] Thực hiện cất vũ khí và bắt đầu nạp mạng...")

-- BƯỚC 1: Cất vũ khí đúng 1 lần duy nhất bằng cách ép State nhân vật
local char = localPlayer.Character
local humanoid = char and char:FindFirstChildOfClass("Humanoid")

if humanoid then
    humanoid:ChangeState(Enum.HumanoidStateType.None)
    task.wait(0.2)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    print("[🎒] Đã thả vũ khí (cất đồ) một lần duy nhất.")
end

-- BƯỚC 2: Tìm quái và nạp mạng như các bản trước
local targetMobNames = {["crawler"]=true, ["phaser"]=true, ["runner"]=true, ["zombie"]=true}

local function getNearestMob(rootPosition)
    local nearestMobPart = nil
    local minDistance = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and targetMobNames[string.lower(obj.Name)] then
            local mobRoot = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            local mobHumanoid = obj:FindFirstChildOfClass("Humanoid")
            if mobRoot and mobHumanoid and mobHumanoid.Health > 0 then
                local dist = (rootPosition - mobRoot.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    nearestMobPart = mobRoot
                end
            end
        end
    end
    return nearestMobPart
end

local gameOverVisible = false
task.spawn(function()
    while not gameOverVisible do
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local targetMob = getNearestMob(root.Position)
            if targetMob then
                root.CFrame = targetMob.CFrame * CFrame.new(0, 0, 0.5)
            else
                local randomPos = root.Position + Vector3.new(math.random(-20,20), 0, math.random(-20,20))
                root.CFrame = CFrame.new(randomPos.X, root.Position.Y, randomPos.Z)
            end
        end
        task.wait(0.2)
    end
end)

-- Chờ bảng Play Again
while not gameOverVisible do
    for _, gui in pairs(localPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
        if gui:IsA("TextButton") and (string.find(string.lower(gui.Text), "play again")) then
            if gui.Visible then gameOverVisible = true end
        end
    end
    task.wait(0.5)
end

_G.CurrentStage = 6
return true
