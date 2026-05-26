local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 2.0, AgentHeight = 5, AgentCanJump = true})

local function getGenerator()
    local generator = Workspace:FindFirstChild("Generator", true)
    if generator then 
        return generator:FindFirstChild("MainPart") or generator.PrimaryPart or generator:FindFirstChildWhichIsA("BasePart") 
    end
    return nil
end

local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    path:ComputeAsync(rootPart.Position, targetPart.Position)
    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - waypoint.Position).Magnitude / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
        end
        return true
    end
    return false
end

print("[STAGE 2] Đang di chuyển về Generator...")
local arrived = false
while not arrived do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local targetGen = getGenerator()
        if targetGen then
            local success = walkPathToTarget(root, targetGen)
            if success then
                arrived = true
                task.wait(1.5) -- Chờ nạp nhiên liệu
            end
        end
    end
    task.wait(0.5)
end

print("[STAGE 2] HOÀN THÀNH!")
return true -- Trả về kết quả hoàn thành
