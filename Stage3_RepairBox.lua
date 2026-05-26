local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- Khởi tạo Pathfinding với thông số chuẩn gốc của Roblox
local path = PathfindingService:CreatePath({
    AgentRadius = 2, 
    AgentHeight = 5, 
    AgentCanJump = true
})

-- =========================================================================
-- HÀM ĐỊNH VỊ TRẠM ĐIỆN THEO ĐÚNG CẤU TRÚC MAP
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
-- HÀM DI CHUYỂN CHUẨN: SỬ DỤNG VỊ TRÍ ĐỂ DI CHUYỂN VÀ TỰ NHẢY KHI KẸT RÀO
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    -- Tính toán đường đi từ vị trí hiện tại đến trạm điện
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- Kiểm tra hành động nếu hệ thống yêu cầu nhảy
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            local startPos = rootPart.Position
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            
            -- Tạo luồng di chuyển mượt mà tới điểm nút tiếp theo
            local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - waypoint.Position).Magnitude / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            
            local tweenCompleted = false
            local connection
            connection = tween.Completed:Connect(function()
                tweenCompleted = true
                connection:Disconnect()
            end)
            
            -- Vòng lặp kiểm tra thời gian thực xem có bị vướng hàng rào sắt nghĩa trang không
            local startTime = os.clock()
            while not tweenCompleted do
                -- Nếu đứng im một chỗ quá 0.3 giây tức là đang vướng rào
                if (os.clock() - startTime) > 0.3 and (rootPart.Position - startPos).Magnitude < 1 then
                    print("[⚠️ STAGE 3] Phát hiện kẹt rào nghĩa trang! Tự động nhảy bọc lót...")
                    
                    humanoid.Jump = true -- Ra lệnh nhảy
                    
                    -- Nhấc nhẹ nhân vật vượt lên trên và đẩy ra trước để phóng qua hàng rào
                    local lookDirection = (waypoint.Position - rootPart.Position).Unit
                    rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.5, lookDirection.Z * 1.5)
                    
                    tween:Cancel()
                    break
                end
                task.wait(0.05)
            end
            task.wait(0.01)
        end
        return true
    else
        -- Bẫy lỗi dự phòng nếu không tìm thấy đường (ví dụ bị kẹt trong góc khuất)
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y + 2, nhichPos.Z)
        task.wait(0.3)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Bắt đầu xử lý luồng định vị trạm điện...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            -- Nếu cách trạm điện xa hơn 4.5 stud thì tiếp tục di chuyển
            if distance > 4.5 then
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã đến vị trí đích sát cạnh trạm điện!")
                reached = true
            end
        else
            task.wait(1)
        end
    end
    task.wait(0.1)
end

task.wait(1)

-- 🔥 CHUYỂN GIAO: Kích hoạt Stage 4 thực hiện hành động đè nút sửa máy
_G.CurrentStage = 4
return true
