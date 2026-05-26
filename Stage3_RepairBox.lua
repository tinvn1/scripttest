local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 -- Cấu hình tốc độ chạy mong muốn

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
-- HÀM DI CHUYỂN CHUẨN: TỰ CHẠY BẰNG MOVETO (TỐC ĐỘ 30) & PHÁT HIỆN KẸT
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
            
            -- Đảm bảo nhân vật luôn giữ tốc độ chạy là 30 suốt quãng đường
            if humanoid.WalkSpeed ~= RUN_SPEED then
                humanoid.WalkSpeed = RUN_SPEED
            end
            
            -- Kiểm tra hành động nếu hệ thống yêu cầu nhảy
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            -- Ra lệnh cho Humanoid tự chạy tới vị trí điểm nút tiếp theo
            humanoid:MoveTo(waypoint.Position)
            
            local movedToFinished = false
            local startPos = rootPart.Position
            local startTime = os.clock()
            
            -- Kết nối sự kiện khi chạy tới đích điểm nút thành công
            local connection
            connection = humanoid.MoveToFinished:Connect(function(reachedTarget)
                movedToFinished = true
                connection:Disconnect()
            end)
            
            -- Vòng lặp kiểm tra chống kẹt thời gian thực (Đã tối ưu cho tốc độ 30)
            while not movedToFinished do
                -- Vì chạy với tốc độ 30 (nhanh hơn), ta kiểm tra kẹt mỗi 0.35 giây
                if (os.clock() - startTime) > 0.35 then
                    -- Nếu chạy tốc độ 30 mà trong 0.35s di chuyển không quá 2.5 stud nghĩa là bị vướng
                    if (rootPart.Position - startPos).Magnitude < 2.5 then
                        print("[⚠️ STAGE 3] Phát hiện chạy bị kẹt vật cản! Tự động nhảy bọc lót...")
                        
                        humanoid.Jump = true -- Ép nhân vật nhảy lên vượt rào
                        
                        -- Nhấc nhẹ vị trí lên trên và hướng về phía trước để giải thoát khỏi điểm kẹt
                        local lookDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.2, lookDirection.Z * 1.5)
                        
                        -- Tiếp tục lệnh di chuyển đến điểm nút
                        humanoid:MoveTo(waypoint.Position)
                    end
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                task.wait(0.05)
            end
            task.wait(0.01)
        end
        return true
    else
        -- Dự phòng nếu không tìm thấy đường đi (Hồi sinh lỗi vị trí)
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y + 1.5, nhichPos.Z)
        task.wait(0.3)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Bắt đầu xử lý luồng chạy bộ định vị trạm điện (Tốc độ: 30)...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        -- Gán tốc độ 30 ngay từ vòng lặp chính
        if humanoid.WalkSpeed ~= RUN_SPEED then
            humanoid.WalkSpeed = RUN_SPEED
        end
        
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            -- Nếu cách trạm điện xa hơn 4.5 stud thì tiếp tục chạy bộ
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
