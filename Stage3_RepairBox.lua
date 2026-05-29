print("[HỆ THỐNG] Đang kích hoạt cấu hình Thoát Góc Kẹt Nâng Cao... Vui lòng đợi 3 giây.")
task.wait(3)
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Thu nhỏ AgentRadius để AI chịu lách vào hốc hẹp, khe tường
local path = PathfindingService:CreatePath({
    AgentRadius = 1.6, 
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
-- 🔥 2. NHẢY VÔ HẠN AN TOÀN CHỐNG SPAM (DÀNH CHO DI CHUYỂN THƯỜNG)
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
-- 🔥 3. THUẬT TOÁN SIÊU GỠ KẸT: LÙI XA + BẺ GÓC CHÉO + INFJUMP 1 MẠCH
-- =========================================================================
local function executeSmartEscape(rootPart, humanoid, targetPosition)
    pcall(function()
        -- Hủy lệnh di chuyển hiện tại để tránh bị hút ngược vào tường
        humanoid:MoveTo(rootPart.Position)
        
        -- 1. Tính hướng giật lùi hẳn ra xa mục tiêu để lấy khoảng trống
        local backwardDirection = (rootPart.Position - targetPosition).Unit
        if backwardDirection.Magnitude == 0 or backwardDirection ~= backwardDirection then
            backwardDirection = -rootPart.CFrame.LookVector
        end
        
        -- Ép nhân vật chạy lùi ra xa
        humanoid:MoveTo(rootPart.Position + (backwardDirection * 10))
        task.wait(0.25) -- Lùi xa hơn một chút để thoát hoàn toàn tầm cấn của lưới/mái nhà

        -- 2. Bẻ góc di chuyển (Tạo một hướng chéo ngẫu nhiên 45-90 độ để lách qua rào chắn)
        local randomAngle = math.rad(math.random(45, 90) * (math.random(1, 2) == 1 and 1 or -1))
        local escapeDirection = Vector3.new(
            backwardDirection.X * math.cos(randomAngle) - backwardDirection.Z * math.sin(randomAngle),
            0,
            backwardDirection.X * math.sin(randomAngle) + backwardDirection.Z * math.cos(randomAngle)
        ).Unit

        -- 3. Kích hoạt chuỗi InfJump gối đầu liên tiếp 5 phát một mạch không delay
        task.spawn(function()
            for _ = 1, 5 do
                if humanoid and humanoid.Health > 0 then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                task.wait(0.05) -- Tốc độ dậm nhảy siêu tốc để ép nhân vật bay lên
            end
        end)

        -- 4. Bơm lực đẩy xiên theo hướng chéo đã tính để quăng nhân vật ra khỏi góc rào
        rootPart.AssemblyLinearVelocity = (escapeDirection * (RUN_SPEED * 1.5)) + Vector3.new(0, 38, 0)
        task.wait(0.2)
    end)
end

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
-- 🔥 HÀM DI CHUYỂN CHUYÊN DỤNG CHO MOBILE CHỐNG CẤN HÀNG RÀO
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local distanceToTarget = (rootPart.Position - targetPart.Position).Magnitude
    
    -- CHIẾN THUẬT VÀO HỐC: Nếu đã ở gần (< 25 studs), ép đi thẳng trực tiếp vào mục tiêu
    if distanceToTarget < 25 then
        humanoid:MoveTo(targetPart.Position)
        
        local startPos = rootPart.Position
        local startTime = os.clock()
        
        while (rootPart.Position - targetPart.Position).Magnitude > 4.5 do
            if (os.clock() - startTime) > 0.15 then
                local moved = (rootPart.Position - startPos).Magnitude
                if moved < 1.4 then
                    -- Phát hiện kẹt góc rào: Thực hiện combo Giật lùi + Bẻ lái chéo + Nhảy một mạch
                    executeSmartEscape(rootPart, humanoid, targetPart.Position)
                end
                startTime = os.clock()
                startPos = rootPart.Position
            end
            task.wait()
            humanoid:MoveTo(targetPart.Position)
        end
        return true
    end

    -- ĐƯỜNG DÀI: Chạy bằng Pathfinding bình thường
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
            
            if (rootPart.Position - targetPart.Position).Magnitude < 25 then
                return false 
            end
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                triggerSafeInfJump(humanoid)
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local isStuck = false
            
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                if i == totalWaypoints then
                    if currentDist < 3.5 then break end
                else
                    if currentDist < 5.0 then break end 
                end
                
                if (os.clock() - startTime) > 0.15 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    if movedDistance < 1.4 then
                        -- Gỡ kẹt đường dài thông minh
                        executeSmartEscape(rootPart, humanoid, waypoint.Position)
                        isStuck = true
                        break 
                    end
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                task.wait()
            end
            
            if isStuck then return false end
        end
        return true
    else
        -- Phục hồi khẩn cấp khi lỗi lộ trình đường dài
        executeSmartEscape(rootPart, humanoid, targetPart.Position)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Hệ thống di chuyển tránh rào chắn thông minh đang hoạt động...");
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
                print("[🎯 STAGE 3 SUCCESS] Nhân vật đã vượt qua góc kẹt lưới sắt và chạm đích!");
                task.cancel(speedLoop) 
                reached = true
            end
        else
            task.wait(0.1)
        end
    else
        task.wait(0.3)
    end
    task.wait(0.01)
end

task.wait(0.05)
_G.CurrentStage = 4
return true
