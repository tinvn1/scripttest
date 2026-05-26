local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 1.8, AgentHeight = 5, AgentCanJump = true})

-- THAY THẾ HÀM QUÉT THÔNG MINH: Tìm kiếm trạm điện theo từ khóa chống sót tên Model
local function getNearestPowerBox(rootPosition)
    local nearestBox = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Kiểm tra nếu vật thể là Model hoặc BasePart và có tên chứa cụm từ khóa liên quan
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local objName = string.lower(obj.Name)
            if string.find(objName, "power") and string.find(objName, "box") then
                -- Lấy phần linh kiện chính để di chuyển tới
                local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                if part then
                    local dist = (rootPosition - part.Position).Magnitude
                    if dist < minDistance then 
                        minDistance = dist
                        nearestBox = part 
                    end
                end
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
            task.wait(0.01)
        end
        return true
    else
        -- Cơ chế nhích nhẹ thông minh để tự gỡ kẹt vật lý
        local nhichPos = rootPart.Position + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
        TweenService:Create(rootPart, TweenInfo.new(3 / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y, nhichPos.Z)}):Play()
        task.wait(0.3)
        return false
    end
end

print("[STAGE 3] Hệ thống quét thông minh bắt đầu hoạt động...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local targetPowerBox = getNearestPowerBox(root.Position)
        if targetPowerBox then
            local distance = (root.Position - targetPowerBox.Position).Magnitude
            if distance > 4.5 then
                walkPathToTarget(root, targetPowerBox)
            else
                print("[🎉 STAGE 3 SUCCESS] Đã tiếp cận thành công sát cạnh trạm điện!")
                reached = true
            end
        else
            -- Nếu chưa thấy (có thể do map chưa load kịp hoặc chưa xuất hiện), đợi 1 giây rồi quét lại
            task.wait(1)
        end
    end
    task.wait(0.1)
end

return true
