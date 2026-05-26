local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 -- Tốc độ chạy nhanh

-- Khởi tạo Pathfinding với thông số chuẩn giúp tính toán đường đi mượt hơn
local path = PathfindingService:CreatePath({
    AgentRadius = 3, -- Tăng nhẹ bán kính để nhân vật cua góc rộng hơn, không bị quẹt tường
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
-- 🔥 HÀM DI CHUYỂN CHẠY 1 MẠCH (KHÔNG KHỰNG, CHỐNG KẸT NÂNG CAO)
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- Luôn ép tốc độ chạy là 30
            if humanoid.WalkSpeed ~= RUN_SPEED then
                humanoid.WalkSpeed = RUN_SPEED
            end
            
            -- Tự động nhảy trước nếu hệ thống yêu cầu
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            -- Phát lệnh chạy đến điểm hiện tại
            humanoid:MoveTo(waypoint.Position)
            
            -- Bộ theo dõi chống kẹt
            local startPos = rootPart.Position
            local startTime = os.clock()
            local loopTimeout = os.clock()
            
            -- VÒNG LẶP CHẠY 1 MẠCH: Chuyển điểm sớm khi đến gần, không đợi dừng chân
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                -- NẾU LÀ ĐIỂM CUỐI CÙNG: Phải chạy sát sạt (< 3 stud)
                if i == totalWaypoints then
                    if currentDist < 3 then break end
                -- NẾU LÀ ĐIỂM TRUNG GIAN: Gần đến nơi (< 4.5 stud) là gối đầu sang điểm sau luôn để chạy 1 mạch
                else
                    if currentDist < 4.5 then break end
                end
                
                -- KIỂM TRA CHỐNG KẸT (Cứ mỗi 0.25 giây kiểm tra di chuyển)
                if (os.clock() - startTime) > 0.25 then
                    -- Nếu chạy tốc độ 30 mà trong 0.25s không tiến thêm được 2 stud chứng tỏ bị kẹt rào
                    if (rootPart.Position - startPos).Magnitude < 2 then
                        print("[⚠️ STAGE 3] Phát hiện kẹt rào/vật cản! Nhảy bọc lót chạy tiếp...")
                        humanoid.Jump = true
                        
                        -- Nhấc nhẹ góc để phóng qua vật cản
                        local lookDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.2, lookDirection.Z * 1.5)
                        
                        humanoid:MoveTo(waypoint.Position)
                    end
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                -- Bẫy lỗi quá thời gian (Nếu kẹt quá 4 giây ở 1 waypoint thì bỏ qua)
                if (os.clock() - loopTimeout) > 4 then
                    break
                end
                
                task.wait() -- Vòng lặp chạy cực nhanh theo khung hình để bắt khoảng cách chính xác
            end
        end
        return true
    else
        -- Dự phòng nếu lỗi tính toán đường đi
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y + 1.5, nhichPos.Z)
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Kích hoạt luồng CHẠY 1 MẠCH tới trạm điện (Speed 30)...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        if humanoid.WalkSpeed ~= RUN_SPEED then
            humanoid.WalkSpeed = RUN_SPEED
        end
        
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            -- Nếu cách xa hơn 4.5 stud thì kích hoạt luồng chạy mượt
            if distance > 4.5 then
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã cập bến sát cạnh trạm điện thành công!")
                reached = true
            end
        else
            task.wait(0.5)
        end
    end
    task.wait(0.05)
end

task.wait(0.5)

-- 🔥 CHUYỂN GIAO LUỒNG SANG STAGE 4
_G.CurrentStage = 4
return true
