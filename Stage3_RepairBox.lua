local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer

local RUN_SPEED = 30 
local TWEEN_SPEED = 35 -- Tốc độ bay cứu viện khi bị kẹt nhảy

-- Khởi tạo Pathfinding cấu hình chuẩn
local path = PathfindingService:CreatePath({
    AgentRadius = 2.4,
    AgentHeight = 5,
    AgentCanJump = true
})

-- =========================================================================
-- 🛠️ HÀM ĐỊNH VỊ TRẠM ĐIỆN THEO ĐÚNG CẤU TRÚC MAP
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
-- 🛠️ HÀM SỬ DỤNG TWEEN ĐỂ BAY CỨU VIỆN KHI BỊ KẸT
-- =========================================================================
local function forceTweenToTarget(rootPart, targetPart)
    print("[🚀 STUCK BYPASS] Nhân vật bị kẹt nhảy! Kích hoạt Tween bay thẳng tới mục tiêu...")
    
    -- Tắt va chạm tạm thời để tránh bị đẩy ngược khi xuyên tường
    local char = localPlayer.Character
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    local targetPos = targetPart.Position + Vector3.new(0, 1.5, 0)
    local distance = (rootPart.Position - targetPos).Magnitude
    local duration = distance / TWEEN_SPEED

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPos)})
    
    tween:Play()
    tween.Completed:Wait()
    
    -- Bật lại va chạm sau khi bay tới nơi
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- =========================================================================
-- 🛠️ HÀM DI CHUYỂN PATHFINDING BÌNH THƯỜNG
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        -- Đi đến waypoint tiếp theo gần nhất
        if waypoints[2] then
            local wp = waypoints[2]
            if wp.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            humanoid:MoveTo(wp.Position)
            return true
        end
    end
    
    -- Phương án dự phòng nếu rớt tính toán đường đi
    humanoid:MoveTo(targetPart.Position)
    return false
end

-- =========================================================================
-- ⚡ VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Bắt đầu luồng chạy bộ tới trạm điện (Có hệ thống chống kẹt nhảy)...")
local reached = false

-- Các biến phục vụ việc theo dõi chống kẹt nhảy
local lastPosition = Vector3.new(0,0,0)
local stuckChecks = 0
local jumpCounter = 0

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            -- Nếu đã áp sát trạm điện thành công
            if distance <= 4.5 then
                print("[🎯 STAGE 3 SUCCESS] Đã tiếp cận sát cạnh trạm điện thành công!");
                reached = true
                break
            end

            -- 🛑 CƠ CHẾ KIỂM TRA CHỐNG KẸT NHẢY TỰ ĐỘNG
            -- Đo khoảng cách dịch chuyển thực tế sau mỗi nhịp xử lý
            local moveDistance = (root.Position - lastPosition).Magnitude
            
            -- Nếu đang nhảy liên tục và vị trí dầu như không thay đổi (bị chặn bởi chướng ngại vật)
            if humanoid.Jump == true or root.Velocity.Y > 5 then
                if moveDistance < 1.2 then
                    jumpCounter = jumpCounter + 1
                end
            else
                -- Nếu di chuyển mượt mà ổn định thì hạ nhiệt bộ đếm xuống từ từ
                if jumpCounter > 0 then jumpCounter = jumpCounter - 1 end
            end
            
            lastPosition = root.Position -- Cập nhật mốc tọa độ để so sánh lượt sau

            -- 🔥 Nếu đếm thấy nhảy vô nghĩa tại chỗ > 12 lần -> Ép dùng Tween cứu hộ ngay
            if jumpCounter >= 12 then
                forceTweenToTarget(root, targetBox)
                print("[🎯 STAGE 3 SUCCESS] Cứu hộ Tween đưa nhân vật cập bến an toàn!");
                reached = true
                break
            end

            -- Nếu không kẹt, tiếp tục đi bộ Pathfinding bình thường
            walkPathToTarget(root, humanoid, targetBox)
        else
            task.wait(0.5)
        end
    end
    task.wait(0.15) -- Nhịp nghỉ tối ưu vừa giữ mượt tọa độ vừa bảo vệ CPU
end

task.wait(0.2)
return true
