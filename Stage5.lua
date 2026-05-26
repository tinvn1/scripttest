local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = Players.LocalPlayer

task.wait(10) -- Nghỉ 10s để đảm bảo Stage 4 đã xong
print("[💀 STAGE 5] Kích hoạt nạp mạng thông minh...")

_G.AllowAutoEquip = false 

-- Cất vũ khí duy nhất 1 lần
local char = localPlayer.Character
local humanoid = char and char:FindFirstChildOfClass("Humanoid")
if humanoid then
    humanoid:ChangeState(Enum.HumanoidStateType.None)
    task.wait(0.2)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

-- Hàm tìm đường thông minh
local function walkToTarget(targetPos)
    local path = PathfindingService:CreatePath({AgentRadius=3, AgentHeight=5})
    local success = pcall(function() path:ComputeAsync(char.HumanoidRootPart.Position, targetPos) end)
    if success and path.Status == Enum.PathStatus.Success then
        for _, waypoint in pairs(path:GetWaypoints()) do
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        end
    end
end

local targetMobNames = {["crawler"]=true, ["phaser"]=true, ["runner"]=true, ["zombie"]=true}
local gameOverVisible = false

task.spawn(function()
    while not gameOverVisible do
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local nearest = nil
            local dist = math.huge
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and targetMobNames[string.lower(obj.Name)] then
                    local mobRoot = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                    if mobRoot then
                        local d = (root.Position - mobRoot.Position).Magnitude
                        if d < dist then dist = d; nearest = mobRoot end
                    end
                end
            end
            if nearest then walkToTarget(nearest.Position)
            else walkToTarget(root.Position + Vector3.new(math.random(-50,50),0,math.random(-50,50))) end
        end
        task.wait(0.5)
    end
end)

-- Chờ Play Again
while not gameOverVisible do
    for _, gui in pairs(localPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
        if gui:IsA("TextButton") and string.find(string.lower(gui.Text), "play again") and gui.Visible then
            gameOverVisible = true
        end
    end
    task.wait(0.5)
end
_G.CurrentStage = 6
return true
