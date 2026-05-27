local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 

-- Tăng bán kính AgentRadius lên một chút để nhân vật đi rộng vòng qua các góc tường, chống cạ người vào cạnh cửa
local path = PathfindingService:CreatePath({
    AgentRadius = 2.2, 
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
-- 🔥 HÀM DI CHUYỂN THUẦN CHẠY BỘ - KHÔNG TWEEN - GỠ KẸT BẰNG JUMP & RE-COMPUTE
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
            
            -- Đảm bảo tốc độ chạy luôn giữ vững mức tối đa
            if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
            
            -- Kích hoạt nhảy nếu điểm nút yêu cầu vượt địa hình
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                humanoid.Jump = true 
            end
            
            -- Ra lệnh chạy bộ thuần túy tới điểm nút
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local loopTimeout = os.clock()
            local isStuck = false
            
            -- Vòng lặp kiểm tra tiến độ chạy bộ của nhân vật
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                -- Xử lý gối đầu mượt mà giữa các điểm nút
                if i == totalWaypoints then
                    if currentDist < 3 then break end
                else
                    if currentDist < 4.5 then break end 
                end
                
                -- CẢM BIẾN THEO DÕI GỠ KẸT CHỈ DÙNG VẬT LÝ (KHÔNG TWEEN)
                if (os.clock() - startTime) > 0.35 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    -- Nếu sau 0.35 giây di chuyển không nổi 1.5 stud chứng tỏ đang cạ vào tường/góc kẹt
                    if movedDistance < 1.5 then
                        humanoid.Jump = true -- Ép nhân vật thực hiện lệnh nhảy qua chướng ngại vật thấp
                        
                        -- Thay vì dịch chuyển CFrame, ép humanoid quay sang hướng khác di chuyển ngẫu nhiên một nhịp ngắn
                        local escapeAngle = math.rad(math.random(0, 360))
                        local escapeTarget = rootPart.Position + Vector3.new(math.sin(escapeAngle) * 4, 0, math.cos(escapeAngle) * 4)
                        humanoid:MoveTo(escapeTarget)
                        task.wait(0.25)
                        
                        isStuck = true -- Đánh dấu bị kẹt để tính lại lộ trình sạch
                        break
                    end
                    
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                -- Khóa bảo vệ tránh treo luồng tại một điểm nút quá lâu
                if (os.clock() - loopTimeout) > 3.5 then 
                    isStuck = true
                    break 
                end
                
                task.wait(0.02)
            end
            
            -- Nếu bị kẹt, dừng ngay việc chạy theo danh sách nút cũ, ép tính toán lại sơ đồ đường đi mới hoàn toàn
            if isStuck then 
                break 
            end
        end
        return true
    else
        -- Nếu Pathfinding thất bại do map thay đổi, ép nhân vật nhảy và đi lùi một nhịp để tìm góc quét thông thoáng hơn
        humanoid.Jump = true
        humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 5)
        task.wait(0.4)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3 (CHẠY BỘ THUẦN TÚY)
-- =========================================================================
print("[STAGE 3] Bắt đầu luồng chạy bộ 1 mạch tới trạm điện (Không Tween)...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        humanoid.WalkSpeed = RUN_SPEED
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            -- Nếu cách xa mục tiêu trạm điện, tiến hành chạy bộ dò đường vật lý
            if distance > 4.5 then
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã đi bộ tiếp cận sát cạnh trạm điện thành công!");
                reached = true
            end
        else
            -- Đợi trạm điện xuất hiện nếu game tải chậm
            task.wait(0.4)
        end
    end
    task.wait(0.05)
end

task.wait(0.2)

-- 🔥 CHUYỂN GIAO SANG STAGE 4
_G.CurrentStage = 4
return true
