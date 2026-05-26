local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 1.8, AgentHeight = 5, AgentCanJump = true})
local boxStuckCounter = 0

-- SỬA LỖI: Đổi từ "Power Box" có dấu cách sang "PowerBox" viết liền chuẩn theo game
local function getNearestPowerBox(rootPosition)
    local nearestBox = nil
    local minDistance = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "PowerBox" and obj:IsA("Model") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (rootPosition - part.Position).Magnitude
                if dist < minDistance then minDistance = dist; nearestBox = part end
            end
        end
    end
    return nearestBox
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
            task.wait(0.02)
        end
        return true
    else
        -- Nhích nhẹ tìm góc thoáng nếu kẹt đường vật lý công trình
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        TweenService:Create(rootPart, TweenInfo.new(3 / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y, nhichPos.Z)}):Play()
        task.wait(0.2)
        return false
    end
end

print("[STAGE 3] Đang định vị tiến tới PowerBox...")
local reached = false
while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local targetPowerBox = getNearestPowerBox(root.Position)
        if targetPowerBox then
            local distance = (root.Position - targetPowerBox.Position).Magnitude
            if distance > 4 then
                walkPathToTarget(root, targetPowerBox)
            else
                print("[🎉 STAGE 3 SUCCESS] Đã đứng sát cạnh PowerBox để sửa!")
                reached = true
            end
        else
            print("[-] Không tìm thấy PowerBox nào, đang quét lại...")
            task.wait(1)
        end
    end
    task.wait(0.1)
end

return true
