print("[HỆ THỐNG] Đang thiết lập cấu hình tối ưu Mobile... Vui lòng đợi 3 giây.")
task.wait(3)
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Cấu hình Path mở rộng bán kính tối đa cho Mobile để đi xa tường hẳn ra
local path = PathfindingService:CreatePath({
    AgentRadius = 2.8, -- Tăng mạnh để tạo khoảng cách an toàn tuyệt đối với bờ tường
    AgentHeight = 5.0,
    AgentCanJump = true,
    Costs = { Water = math.huge }
})

local lastJumpTime = 0
local JUMP_COOLDOWN = 0.25 

-- =========================================================================
-- 🔥 1. LOOP GIỮ CỐ ĐỊNH TỐC ĐỘ 30 
-- =========================================================================
local speedLoop = task.spawn(function()
    while true do
        pcall(function()
            if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
                localPlayer.Character.Humanoid.WalkSpeed = RUN_SPEED
            end
        end)
        task.wait(0.1)
    end
end)

-- =========================================================================
-- 🔥 2. NHẢY VÔ HẠN AN TOÀN CHỐNG SPAM
-- =========================================================================
local function triggerSafeInfJump(humanoid)
    local now = os.clock()
    if now - lastJumpTime >= JUMP_COOLDOWN then
        lastJumpTime = now
        pcall(function()
            if humanoid and humanoid.Health > 0 then
                humanoid:ChangeState("Jumping")
            end
        end)
    end
end

if _G.InfJumpHooked then _G.InfJumpHooked:Disconnect() end
_G.InfJumpHooked = UserInputService.JumpRequest:Connect(function()
    if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
        triggerSafeInfJump(localPlayer.Character:FindFirstChildOfClass("Humanoid"))
    end
end)

-- =========================================================================
-- HÀM ĐỊNH VỊ TRẠM ĐIỆN TỐI ƯU
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
-- 🔥 HÀM DI CHUYỂN FIXED CHO MOBILE - CHỐNG CỌ TƯỜNG, ÉP TÍNH ĐƯỜNG MỚI
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        local startIndex = 1
        if totalWaypoints > 2 and (rootPart.Position - waypoints[2].Position).Magnitude < 4 then
            startIndex = 2
        end
        
        for i = startIndex, totalWaypoints do
            local waypoint = waypoints[i]
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                triggerSafeInfJump(humanoid)
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local isStuck = false
            
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                -- Tăng bán kính nhận diện Waypoint lên một chút để bù trừ độ trễ FPS trên Mobile
                if i == totalWaypoints then
                    if currentDist < 3.5 then break end
                else
                    if currentDist < 5.0 then break end 
                end
                
                -- CẢM BIẾN QUÉT KẸT SIÊU NHẠY CHO MOBILE (0.12 Giây)
                if (os.clock() - startTime) > 0.12 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    -- Nếu dịch chuyển ít hơn 1.4 studs (Dấu hiệu đang bị vã mặt vào tường)
                    if movedDistance < 1.4 then
                        -- BƯỚC 1: Ép hủy di chuyển cũ để giải phóng cần gạt ảo trên Mobile
                        humanoid:MoveTo(rootPart.Position)
                        
                        -- BƯỚC 2: Tính toán hướng giật lùi khẩn cấp để thoát cọ tường vật lý
                        local escapeDirection = (rootPart.Position - waypoint.Position).Unit
                        if escapeDirection.Magnitude == 0 then
                            escapeDirection = -rootPart.CFrame.LookVector
                        end
                        
                        -- Kích hoạt nhảy và đẩy ngược nhân vật ra xa góc tường
                        triggerSafeInfJump(humanoid)
                        rootPart.AssemblyLinearVelocity = (escapeDirection * 20) + Vector3.new(0, 25, 0)
                        
                        task.wait(0.1) -- Thời gian ngắn để tách nhân vật khỏi chân tường
                        
                        isStuck = true
                        break -- Bẻ gãy vòng lặp hiện tại, buộc vòng lặp chính tính toán lại Path mới
                    end
                    
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                task.wait()
            end
            
            -- Nếu kẹt/cọ tường, trả về false ngay lập tức để làm mới lộ trình
            if isStuck then 
                return false 
            end
        end
        return true
    else
        -- Phục hồi khẩn cấp khi không tìm thấy đường đi ngắn nhất
        local backupDir = -rootPart.CFrame.LookVector
        rootPart.AssemblyLinearVelocity = (backupDir * 15) + Vector3.new(0, 20, 0)
        task.wait(0.15)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Luồng xử lý Mobile hoạt động - Chống cọ tường và đứng im thành công!");
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid and humanoid.Health > 0 then
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            if distance > 4.5 then
                -- Hàm walkPathToTarget nếu gặp tường sẽ thoát ra ngay với giá trị false, giúp vòng lặp while chạy lại tức thì để tìm đường mới
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã cập bến trạm điện dứt khoát!");
                
                -- DỌN DẸP LUỒNG
                task.cancel(speedLoop)
                _G.CheckerRunning = false 
                
                if _G.DisableChecker then 
                    _G.DisableChecker() 
                end
                
                reached = true
            end
        else
            task.wait(0.1)
        end
    else
        task.wait(0.3)
    end
    task.wait(0.01) -- Giảm tối đa thời gian chờ vòng lặp chính để tăng tốc quét tọa độ trên Mobile
end

task.wait(0.05)
_G.CurrentStage = 4
return true
