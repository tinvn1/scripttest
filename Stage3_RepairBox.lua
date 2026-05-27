local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local RUN_SPEED = 30 
local STUCK_TIMEOUT = 10 -- Thời gian tối đa cho một lối đi trước khi đổi đường

-- Cấu hình Pathfinding chống cọ tường vật lý
local path = PathfindingService:CreatePath({
    AgentRadius = 2.4,
    AgentHeight = 5, 
    AgentCanJump = true
})

-- Bảng chứa các khối chặn ảo dùng để ép Bot đổi hướng
local temporaryObstacles = {}

-- =========================================================================
-- HÀM TẠO VẬT CẢN ẢO ÉP ĐỔI HƯỚNG
-- =========================================================================
local function createTempObstacle(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(10, 15, 10) -- Khối chặn đủ rộng để bao quát lối đi bị kẹt
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1 -- Hoàn toàn tàng hình (chỉnh thành 0.7 nếu muốn nhìn thấy để debug)
    part.Parent = Workspace
    
    -- Gắn Modifier để công cụ Pathfinding chủ động né vùng này
    local modifier = Instance.new("PathfindingModifier")
    modifier.Label = "Blocked"
    modifier.Passethrough = false
    modifier.Parent = part
    
    table.insert(temporaryObstacles, part)
end

-- Dọn dẹp toàn bộ vật cản ảo khi đổi mục tiêu hoặc hoàn thành hành trình
local function clearTempObstacles()
    for i = 1, #temporaryObstacles do
        local part = temporaryObstacles[i]
        if part then part:Destroy() end
    end
    table.clear(temporaryObstacles)
end

-- =========================================================================
-- HÀM ĐỊNH VỊ TRẠM ĐIỆN GẦN NHẤT
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
-- 🔥 HÀM DI CHUYỂN BỘ - TỰ ĐỘNG NGẮT VÀ THẢ CẢN KHI QUÁ 10 GIÂY
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        -- Ghi nhận thời điểm bắt đầu đi của LỘ TRÌNH NÀY
        local pathStartTime = os.clock()
        
        for i = 1, totalWaypoints do
            local waypoint = waypoints[i]
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- KIỂM TRA ĐIỀU KIỆN 10 GIÂY: Nếu lối đi hiện tại tốn quá nhiều thời gian -> Hủy đường
            if (os.clock() - pathStartTime) > STUCK_TIMEOUT then
                print("[⚠️ STUCK DETECTED] Lối đi này bị kẹt quá 10s! Thả cản ảo để tìm hướng khác...")
                createTempObstacle(rootPart.Position)
                return false 
            end
            
            if humanoid.WalkSpeed ~= RUN_SPEED then 
                humanoid.WalkSpeed = RUN_SPEED 
            end
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                humanoid.Jump = true 
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local loopTimeout = os.clock()
            local isStuck = false
            
            while true do
                -- Kiểm tra 10 giây liên tục trong vòng lặp kiểm tra khoảng cách waypoint
                if (os.clock() - pathStartTime) > STUCK_TIMEOUT then
                    createTempObstacle(rootPart.Position)
                    return false
                end

                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                if i == totalWaypoints then
                    if currentDist < 3 then break end
                else
                    if currentDist < 4.5 then break end 
                end
                
                -- CẢM BIẾN VI MÔ (GỠ KẸT VẬT LÝ NHANH TRONG 0.4 GIÂY)
                if (os.clock() - startTime) > 0.4 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    if movedDistance < 1.5 then
                        humanoid.Jump = true 
                        
                        local escapeAngle = math.rad(math.random(0, 360))
                        local escapeTarget = rootPart.Position + Vector3.new(math.sin(escapeAngle) * 4, 0, math.cos(escapeAngle) * 4)
                        humanoid:MoveTo(escapeTarget)
                        task.wait(0.25)
                        
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
            
            if isStuck then 
                break 
            end
        end
        return true
    else
        -- Lỗi tính toán đường đi sơ bộ, lùi lại để tránh kẹt góc hình học
        humanoid.Jump = true
        humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 5)
        task.wait(0.4)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH (THỬ NGHIỆM TỐI ĐA 3 LỐI ĐI)
-- =========================================================================
print("[STAGE 3] Bắt đầu quét đường di chuyển (Hỗ trợ đổi tối đa 3 hướng đi nếu kẹt)...")
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
                
                -- Quét và chạy tối đa 3 hướng đi khác nhau tới cùng 1 trạm
                while currentAttempt < 3 and not isSuccess do
                    currentAttempt = currentAttempt + 1
                    print(string.format("[➔ LỐI ĐI KẾ THỪA] Đang chạy thử hướng thứ %d tới Trạm Điện...", currentAttempt))
                    
                    isSuccess = walkPathToTarget(root, humanoid, targetBox)
                    
                    if isSuccess then
                        break
                    else
                        if currentAttempt < 3 then
                            print(string.format("[❌ ĐỔI HƯỚNG] Lối thứ %d không khả thi hoặc hết thời gian 10s. Đang vẽ lại hướng đi mới...", currentAttempt))
                            task.wait(0.2)
                        end
                    end
                end
                
                -- Trường hợp xấu nhất: Cả 3 hướng đi đều bị bế tắc, dọn dẹp các khối chặn ẩn để tính lại từ đầu
                if not isSuccess and currentAttempt >= 3 then
                    print("[⚠️ HỆ THỐNG QUÁ TẢI] Toàn bộ 3 lối đi đều kẹt! Reset lại bản đồ ảo để thử lại...")
                    clearTempObstacles()
                    task.wait(0.8)
                end
            else
                print("[🎯 STAGE 3 SUCCESS] Đã tiếp cận sát cạnh trạm điện thành công!");
                clearTempObstacles() -- Xóa bỏ toàn bộ rác vật cản ảo để tránh lag map
                reached = true
            end
        else
            task.wait(0.5)
        end
    end
    task.wait(0.1)
end

task.wait(0.2)
_G.CurrentStage = 4
return true
