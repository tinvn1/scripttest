local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- Cấu hình Pathfinding tối ưu né vật cản xung quanh khu vực nghĩa trang
local path = PathfindingService:CreatePath({
    AgentRadius = 2.5, 
    AgentHeight = 5, 
    AgentCanJump = true
})

-- =========================================================================
-- HÀM TÌM TRẠM ĐIỆN THEO ĐÚNG CẤU TRÚC MAP
-- =========================================================================
local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" then
            local targetPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not targetPart and obj:FindFirstChild("Prompt") then
                targetPart = obj:FindFirstChild("Prompt").Parent
            end
            
            if targetPart and targetPart:IsA("BasePart") then
                local dist = (rootPosition - targetPart.Position).Magnitude
                if dist < minDistance then 
                    minDistance = dist
                    nearestBoxPart = targetPart 
                end
            end
        end
    end
    return nearestBoxPart
end

-- =========================================================================
-- HÀM DI CHUYỂN CÓ CƠ CHẾ TỰ ĐỘNG NHẢY KHI VƯỚNG HÀNG RÀO SẮT
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    path:ComputeAsync(rootPart.Position, targetPart.Position)
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- 🔥 ĐÃ VÁ LỖI CÚ PHÁP: Sử dụng đúng Enum.PathWaypointAction của Roblox
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            local startPos = rootPart.Position
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            
            local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - waypoint.Position).Magnitude / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            
            local tweenCompleted = false
            local connection
            connection = tween.Completed:Connect(function()
                tweenCompleted = true
                connection:Disconnect()
            end)
            
            -- Bộ kiểm tra thời gian thực chống kẹt tại hàng rào
            local startTime = os.clock()
            while not tweenCompleted do
                -- Nếu đứng im tại một chỗ quá 0.3 giây tức là đang vướng hàng rào sắt
                if (os.clock() - startTime) > 0.3 and (rootPart.Position - startPos).Magnitude < 1 then
                    print("[⚠️ DETECTION] Vướng vật cản nghĩa trang! Kích hoạt bổ trợ nhảy vượt rào...")
                    
                    humanoid.Jump = true
                    
                    -- Nhấc bổng nhân vật vượt qua lưới sắt bảo vệ
                    local lookDirection = (waypoint.Position - rootPart.Position).Unit
                    rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3, lookDirection.Z * 1.5)
                    
                    tween:Cancel()
                    break
                end
                task.wait(0.05)
            end
            
            task.wait(0.01)
        end
        return true
    else
        local nhichPos = rootPart.Position + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
        TweenService:Create(rootPart, TweenInfo.new(3 / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y + 2, nhichPos.Z)}):Play()
        task.wait(0.3)
        return false
    end
end

-- =========================================================================
-- LUỒNG CHẠY CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Đang định vị trạm điện an toàn từ hệ thống Power Plant...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            if distance > 4.5 then
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎉 STAGE 3 SUCCESS] Đã đến sát cạnh trạm điện an toàn!")
                reached = true
            end
        else
            task.wait(1)
        end
    end
    task.wait(0.1)
end

-- Chuyển tiếp luồng an toàn sang Stage 4 để đè nút sửa máy
_G.CurrentStage = 4
return true
