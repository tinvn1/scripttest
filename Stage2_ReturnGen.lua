local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 1.8, AgentHeight = 5, AgentCanJump = true})

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
            if not rootPart.Parent or not targetPart.Parent then return false end
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - waypoint.Position).Magnitude / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
            task.wait(0.01)
        end
        return true
    else
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        TweenService:Create(rootPart, TweenInfo.new(3 / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y, nhichPos.Z)}):Play()
        task.wait(0.2)
        return false
    end
end

print("[STAGE 2] Đang di chuyển về Generator...")
local arrivedGen = false

while not arrivedGen do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(1) continue end
    
    local targetGen = getGenerator()
    if targetGen then
        local success = walkPathToTarget(root, targetGen)
        if success then
            print("[STAGE 2] HOÀN THÀNH! Đã nạp xong nhiên liệu.")
            arrivedGen = true
            task.wait(1)
        else
            task.wait(0.1)
        end
    else
        print("[⚠️] Không tìm thấy trạm Generator trên bản đồ!")
        task.wait(1)
    end
end

return true
