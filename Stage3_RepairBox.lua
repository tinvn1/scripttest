print("[HỆ THỐNG] Đang thiết lập... Vui lòng đợi 3 giây.")
task.wait(3)
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Cấu hình Path tối ưu chống cọ tường vật lý
local path = PathfindingService:CreatePath({
    AgentRadius = 2.0, -- Tăng nhẹ bán kính để nhân vật đi xa tường hơn, tránh kẹt kịch khung
    AgentHeight = 5.0,
    AgentCanJump = true,
    Costs = { Water = math.huge }
})

-- Biến kiểm soát Cooldown nhảy tránh bị spam dậm chân tại chỗ
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
-- 🔥 2. NHẢY VÔ HẠN AN TOÀN (CÓ CHỐNG SPAM NHẢY MỘT CHỖ)
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
-- 🔥 HÀM DI CHUYỂN CẢI TIẾN - SỬA LỖI NHẢY LẶP LẠI MỘT CHỖ
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
            
            -- Nếu waypoint yêu cầu nhảy, chỉ kích hoạt nhảy hợp lý
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                triggerSafeInfJump(humanoid)
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local isStuck = false
            local jumpCountThisWaypoint = 0 -- Đếm số lần nhảy tại waypoint hiện tại
            
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                if i == totalWaypoints then
                    if currentDist < 3.0 then break end
                else
                    if currentDist < 4.5 then break end 
                end
                
                -- CẢM BIẾN GỠ KẸT VÀ PHÁ Ổ NHẢY MỘT CHỖ (0.2 Giây)
                if (os.clock() - startTime) > 0.2 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    -- Nếu không di chuyển được đáng kể (Bị kẹt hoặc đang nhảy nhấp nhô 1 chỗ)
                    if movedDistance < 1.2 then
                        jumpCountThisWaypoint = jumpCountThisWaypoint + 1
                        
                        -- CHỐNG NHẢY HOÀI KHÔNG ĐI: Nếu đã nhảy cố quá 3 lần tại chỗ này, bỏ qua waypoint lỗi ngay lập tức
                        if jumpCountThisWaypoint > 3 then
                            isStuck = true
                            break
                        end
                        
                        local pushDirection = (waypoint.Position - rootPart.Position).Unit
                        
                        task.spawn(function()
                            triggerSafeInfJump(humanoid)
                        end)
                        
                        -- Lực đẩy nhẹ về phía trước kết hợp lách góc ngẫu nhiên
                        rootPart.AssemblyLinearVelocity = (pushDirection * (RUN_SPEED * 1.2)) + Vector3.new(0, 28, 0)
                        humanoid:MoveTo(waypoint.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3)))
                        task.wait(0.2)
                        
                        isStuck = true 
                        break 
                    end
                    
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                task.wait()
            end
            
            -- Nếu phát hiện lỗi nhảy/kẹt, thoát ra để tính lại đường đi hoàn toàn mới
            if isStuck then 
                return false 
            end
        end
        return true
    else
        -- Phục hồi khẩn cấp né anti-cheat khi lỗi đường đi
        rootPart.AssemblyLinearVelocity = (-rootPart.CFrame.LookVector * 10) + Vector3.new(0, 15, 0)
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Khởi chạy luồng di chuyển thông minh ổn định - Đã chống nhảy một chỗ...");
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
    task.wait(0.02)
end

task.wait(0.05)
_G.CurrentStage = 4
return true
