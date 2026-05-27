local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local RUN_SPEED = 30 
local STUCK_TIMEOUT = 10 -- 10 giây tự đổi hướng

local path = PathfindingService:CreatePath({
    AgentRadius = 2.4,
    AgentHeight = 5, 
    AgentCanJump = true
})

local temporaryObstacles = {}

-- =========================================================================
-- HÀM TẠO VẬT CẢN ẢO (ĐẨY RA PHÍA TRƯỚC HƯỚNG BỊ KẸT, KHÔNG ĐẶT DƯỚI CHÂN)
-- =========================================================================
local function createTempObstacle(position, moveDirection)
    local part = Instance.new("Part")
    part.Size = Vector3.new(12, 15, 12)
    
    -- Đẩy khối chặn ra phía trước 4 studs theo hướng đang đi để chặn lối đi đó, tránh đè lên chân bot
    local spawnPos = position + (moveDirection * 4)
    part.Position = Vector3.new(spawnPos.X, position.Y, spawnPos.Z)
    
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1 -- Đã ẩn hoàn toàn block đỏ để không làm vướng mắt bạn
    part.Parent = Workspace
    
    local modifier = Instance.new("PathfindingModifier")
    modifier.Label = "Blocked"
    modifier.Passethrough = false
    modifier.Parent = part
    
    table.insert(temporaryObstacles, part)
end

local function clearTempObstacles()
    for i = 1, #temporaryObstacles do
        local part = temporaryObstacles[i]
        if part then part:Destroy() end
    end
    table.clear(temporaryObstacles)
end

-- =========================================================================
-- HÀM ĐỊNH VỊ TRẠM ĐIỆN
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
-- 🔥 HÀM DI CHUYỂN BỘ - KHÔNG KHỰNG - LÙI LẠI NGAY KHI ĐỔI ĐƯỜNG
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        local pathStartTime = os.clock()
        
        for i = 1, totalWaypoints do
            local waypoint = waypoints[i]
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- NẾU QUÁ 10 GIÂY KHÔNG ĐẾN ĐƯỢC ĐÍCH:
            if (os.clock() - pathStartTime) > STUCK_TIMEOUT then
                print("[⚠️ ĐỔI ĐƯỜNG] Quá 10 giây, ép đổi hướng lập tức!")
                
                -- Tạo block ẩn phía trước mặt để chặn lối kẹt này lại
                createTempObstacle(rootPart.Position, rootPart.CFrame.LookVector)
                
                -- ÉP NHÂN VẬT CHẠY LÙI LẠI PHÍA SAU NGAY LẬP TỨC (KHÔNG ĐỨNG IM CHỜ)
                humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 6)
                return false 
            end
            
            if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
            if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local loopTimeout = os.clock()
            local isStuck = false
            
            while true do
                if (os.clock() - pathStartTime) > STUCK_TIMEOUT then
                    createTempObstacle(rootPart.Position, rootPart.CFrame.LookVector)
                    humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 6)
                    return false
                end

                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                if i == totalWaypoints then
                    if currentDist < 3 then break end
                else
                    if currentDist < 4.5 then break end 
                end
                
                -- CẢM BIẾN GỠ KẸT NHANH TRONG KHI CHẠY (0.4 GIÂY)
                if (os.clock() - startTime) > 0.4 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    if movedDistance < 1.5 then
                        humanoid.Jump = true 
                        
                        local escapeAngle = math.rad(math.random(0, 360))
                        local escapeTarget = rootPart.Position + Vector3.new(math.sin(escapeAngle) * 5, 0, math.cos(escapeAngle) * 5)
                        humanoid:MoveTo(escapeTarget)
                        
                        isStuck = true 
                        break
                    end
                    
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                if (os.clock() - loopTimeout) > 3.5 then 
                    isStuck = true
                    break 
                end
                
                task.wait(0.05)
            end
            
            if isStuck then break end
        end
        return true
    else
        -- Nếu không tính được đường, lùi nhanh về sau
        humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 6)
        task.wait(0.1)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP CHÍNH
-- =========================================================================
print("[STAGE 3] Bắt đầu luồng chạy mượt - Đổi 3 hướng liên tục không đứng im...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
        
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            if distance > 4.5 then
                local currentAttempt = 0
                local isSuccess = false
                
                while currentAttempt < 3 and not isSuccess do
                    currentAttempt = currentAttempt + 1
                    isSuccess = walkPathToTarget(root, humanoid, targetBox)
                    
                    if isSuccess then
                        break
                    else
                        -- Đổi hướng ngay lập tức, chỉ nghỉ 0.05s để tránh quá tải luồng
                        task.wait(0.05) 
                    end
                end
                
                if not isSuccess and currentAttempt >= 3 then
                    print("[🔄 RESET MAP] Vẽ lại bản đồ ảo để thử vòng lặp mới...")
                    clearTempObstacles()
                    task.wait(0.1)
                end
            else
                print("[🎯 STAGE 3 SUCCESS] Đã chạm trạm điện thành công!");
                clearTempObstacles()
                reached = true
            end
        else
            task.wait(0.2)
        end
    end
    task.wait(0.05) -- Giảm thời gian chờ vòng lặp chính để tăng phản xạ của Bot
end

task.wait(0.2)
_G.CurrentStage = 4
return true
