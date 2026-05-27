local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer

-- 🏃‍♂️ KHAI BÁO TỐC ĐỘ DI CHUYỂN CỦA BẠN Ở ĐÂY
local RUN_SPEED = 30    -- Tốc độ chạy bộ bình thường
local TWEEN_SPEED = 32  -- Tốc độ lướt Tween dọc theo Waypoint để chống ôm tường

-- Khởi tạo Pathfinding cấu hình mở rộng bán kính tối đa để ép đường đi ra giữa lộ trình
local path = PathfindingService:CreatePath({
    AgentRadius = 3.5, -- Tăng mạnh bán kính né vật cản, buộc đường đi phải nằm xa rìa tường
    AgentHeight = 5,
    AgentCanJump = false -- Tắt Jump của hệ thống để chống kích hoạt nhảy bậy
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
-- 🚀 HÀM TWEEN DỌC THEO MẮT XÍCH WAYPOINT (CHỐNG ÔM TƯỜNG & CHỐNG KẸT TUYỆT ĐỐI)
-- =========================================================================
local function moveSmoothAlongPath(rootPart, targetPart)
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        -- Duyệt qua từng tọa độ nút mà hệ thống vạch ra
        for i = 2, #waypoints do
            local wp = waypoints[i]
            
            -- Tọa độ đích nâng nhẹ lên 0.5 studs so với mặt đất để tránh ma sát chân vào ngách gạch
            local targetCFrame = CFrame.new(wp.Position + Vector3.new(0, 0.5, 0))
            local distance = (rootPart.Position - targetCFrame.Position).Magnitude
            
            -- 🎯 SỬ DỤNG TWEEN_SPEED ĐỂ TÍNH THỜI GIAN DI CHUYỂN MƯỢT MÀ
            local duration = distance / TWEEN_SPEED
            
            local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
            
            tween:Play()
            tween.Completed:Wait() -- Chờ đi tới điểm nút này rồi mới chuyển sang nút tiếp theo
            
            -- Kiểm tra an toàn: Nếu trong lúc đang đi mà đã áp sát trạm điện thì ngắt sớm luôn
            if (rootPart.Position - targetPart.Position).Magnitude <= 4.5 then
                return true
            end
        end
        return true
    else
        -- Phương án dự phòng cuối: Nếu Pathfinding lỗi không tính được đường đi, bay thẳng 1 mạch tới đích
        local distance = (rootPart.Position - targetPart.Position).Magnitude
        local duration = distance / TWEEN_SPEED
        local tween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetPart.CFrame + Vector3.new(0, 1.5, 0)})
        tween:Play()
        tween.Completed:Wait()
        return false
    end
end

-- =========================================================================
-- ⚡ LUỒNG XỬ LÝ CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Kích hoạt hệ thống chạy theo Waypoint-Tween chống ôm tường...")

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local humanoid = char and char:FindFirstChildOfClass("Humanoid")

if root and humanoid then
    -- Đảm bảo WalkSpeed dự phòng luôn được gán bằng RUN_SPEED
    if humanoid.WalkSpeed ~= RUN_SPEED then 
        humanoid.WalkSpeed = RUN_SPEED 
    end
    
    -- Tắt trạng thái tự động nhảy ngầm của Humanoid để không bị rồ dại nhảy tại chỗ
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    
    local targetBox = getNearestPowerBox(root.Position)
    
    if targetBox then
        -- Vòng lặp bám đuổi cho tới khi đứng sát cạnh trạm điện
        while (root.Position - targetBox.Position).Magnitude > 4.5 do
            moveSmoothAlongPath(root, targetBox)
            task.wait(0.1)
        end
        
        print("[🎯 STAGE 3 SUCCESS] Đã tiếp cận trạm điện an toàn mà không dính tường!");
        
        -- Bật lại trạng thái nhảy bình thường trả lại cho nhân vật trước khi sang stage sau
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        task.wait(0.2)
        return true
    else
        warn("[❌ STAGE 3 ERROR] Không tìm thấy trạm điện Power Box nào trên bản đồ!")
        task.wait(1)
        return false
    end
else
    task.wait(0.5)
    return false
end
