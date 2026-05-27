local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Cấu hình Path chuẩn chống cọ tường vật lý
local path = PathfindingService:CreatePath({
    AgentRadius = 2.0, -- Giảm nhẹ một chút để đi qua các khe cửa dứt khoát hơn
    AgentHeight = 5.0,
    AgentCanJump = true,
    Costs = { Water = math.huge } -- Tránh các vùng lỗi nếu có
})

-- =========================================================================
-- HÀM ĐỊNH VỊ TRẠM ĐIỆN THEO ĐÚNG CẤU TRÚC MAP
-- =========================================================================
local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    local descendants = Workspace:GetDescendants()
    
    for i = 1, #descendants do
        local obj = descendants[i]
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
-- 🔥 HÀM DI CHUYỂN DỨT KHOÁT - KHÔNG KHỰNG - KHÔNG NOCLIP
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        for i = 1, totalWaypoints do
            local waypoint = waypoints[i]
            
            -- Kiểm tra an toàn mỗi waypoint
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- Ép tốc độ chạy liên tục
            if humanoid.WalkSpeed ~= RUN_SPEED then 
                humanoid.WalkSpeed = RUN_SPEED 
            end
            
            -- Nhảy dứt khoát nếu gặp chướng ngại vật
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                humanoid.Jump = true 
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local isStuck = false
            
            -- Vòng lặp chờ nén chặt thời gian để di chuyển mượt
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                -- Độ chuẩn xác khoảng cách cao hơn để không đi vòng vèo
                if i == totalWaypoints then
                    if currentDist < 2.5 then break end
                else
                    if currentDist < 3.0 then break end 
                end
                
                -- CẢM BIẾN GỠ KẸT SIÊU TỐC (0.25 giây thay vì 0.4 giây)
                if (os.clock() - startTime) > 0.25 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    -- Nếu dậm chân tại chỗ (bị cấn góc tường)
                    if movedDistance < 1.0 then
                        humanoid.Jump = true 
                        -- Ép nhân vật lao mạnh về phía trước waypoint thay vì đi hướng ngẫu nhiên
                        local pushDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.AssemblyLinearVelocity = pushDirection * RUN_SPEED
                        
                        -- Nhấp nhẹ sang bên cạnh để lách góc cấn
                        humanoid:MoveTo(waypoint.Position + Vector3.new(math.random(-1,1), 0, math.random(-1,1)))
                        task.wait(0.1)
                        
                        isStuck = true 
                        break -- Tính lại đường đi ngay lập tức
                    end
                    
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                task.wait() -- Chờ theo khung hình (Render) để mượt nhất có thể, tránh loopTimeout dài
            end
            
            if isStuck then break end
        end
        return true
    else
        -- Nếu lỗi Path, lùi lại 1 chút cực nhanh và nhảy lên để reset góc nhìn
        humanoid.Jump = true
        humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 3)
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Bắt đầu luồng chạy bộ dứt khoát (No Noclip)...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid and humanoid.Health > 0 then
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            -- Khoảng cách tiếp cận sát cạnh trạm điện (Dưới 4 studs là dừng)
            if distance > 4.0 then
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã đến sát trạm điện dứt khoát!");
                reached = true
            end
        else
            task.wait(0.2)
        end
    else
        task.wait(0.5) -- Chờ hồi sinh nếu chết
    end
    task.wait(0.05) -- Tối ưu hóa vòng lặp chính không gây lag game
end

task.wait(0.1)
_G.CurrentStage = 4
return true
