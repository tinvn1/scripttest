local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 

-- Khấu hao cấu hình Path ban đầu
local path = PathfindingService:CreatePath({
    AgentRadius = 2.4, 
    AgentHeight = 5, 
    AgentCanJump = true
})

-- Vùng cản ảo dùng để ép Bot đổi đường khi bị kẹt
local temporaryObstacles = {}

local function createTempObstacle(position)
    local part = Instance.new("Part")
    part.Size = Vector3.new(12, 15, 12) -- Tạo một khối hộp đủ lớn để chặn lối đi cũ
    part.Position = position
    part.Anchored = true
    part.CanCollide = false -- Không cần va chạm vật lý
    part.Transparency = 0.7 -- Nhìn mờ mờ để bạn dễ debug (có thể chỉnh thành 1 để tàng hình)
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Parent = Workspace
    
    -- Thêm Modifier để Pathfinding né vùng này ra
    local modifier = Instance.new("PathfindingModifier")
    modifier.Label = "Blocked"
    modifier.Passethrough = false
    modifier.Parent = part
    
    table.insert(temporaryObstacles, part)
end

local function clearTempObstacles()
    for _, part in ipairs(temporaryObstacles) do
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
-- 🔥 HÀM DI CHUYỂN - GIỚI HẠN 10 GIÂY/ĐƯỜNG
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        -- Đếm thời gian bắt đầu chạy của đường này
        local pathStartTime = os.clock()
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- KIỂM TRA QUÁ 10 GIÂY
            if (os.clock() - pathStartTime) > 10 then
                print("[⚠️ STUCK 10S] Lối đi này bị kẹt quá 10 giây! Thả vật cản để ép đổi đường khác...")
                -- Tạo vật cản ngay tại vị trí bot đang đứng kẹt để ép nó tìm đường vòng
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
                -- Kiểm tra 10s liên tục bên trong vòng lặp
                if (os.clock() - pathStartTime) > 10 then
                    createTempObstacle(rootPart.Position)
                    return false
                end

                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                if i == totalWaypoints then
                    if currentDist < 3 then break end
                else
                    if currentDist < 4.5 then break end 
                end
                
                -- CẢM BIẾN GỠ KẸT NHANH (NHẢY)
                if (os.clock() - startTime) > 0.4 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    if movedDistance < 1.5 then
                        humanoid.Jump = true 
                        local escapeAngle = math.rad(math.random(0, 360))
                        local escapeTarget = rootPart.Position + Vector3.new(math.sin(escapeAngle) * 4, 0, math.cos(escapeAngle) * 4)
                        humanoid:MoveTo(escapeTarget)
                        task.wait(0.3)
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
        humanoid.Jump = true
        humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 5)
        task.wait(0.5)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH (1 TRẠM - THỬ 3 ĐƯỜNG)
-- =========================================================================
print("[STAGE 3] Bắt đầu tiếp cận trạm điện (Thử tối đa 3 lối đi nếu kẹt)...")
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
                local pathAttempts = 0
                local pathSuccess = false
                
                -- Vòng lặp cho phép thử tối đa 3 đường khác nhau tới cùng 1 trạm này
                while pathAttempts < 3 and not pathSuccess do
                    pathAttempts = pathAttempts + 1
                    print(string.format("[➔ STAGE 3] Đang thử đi lối thứ %d tới trạm điện...", pathAttempts))
                    
                    pathSuccess = walkPathToTarget(root, humanoid, targetBox)
                    
                    if pathSuccess then
                        break
                    else
                        if pathAttempts < 3 then
                            print(string.format("[❌ ĐỔI ĐƯỜNG] Lối thứ %d thất bại (Hết 10s). Đang tính toán lối đi mới...", pathAttempts))
                            task.wait(0.2)
                        end
                    end
                end
                
                -- Nếu đã thử cả 3 lối đi mà vẫn không tới được, reset lại các vật cản ẩn để tìm lại từ đầu
                if not pathSuccess and pathAttempts >= 3 then
                    print("[⚠️ RESET] Cả 3 lối đi đều bị kẹt! Đang dọn dẹp chướng ngại vật ảo để thử lại...")
                    clearTempObstacles()
                    task.wait(1)
                end
                
            else
                print("[🎯 STAGE 3 SUCCESS] Đã tiếp cận sát cạnh trạm điện thành công!");
                clearTempObstacles() -- Dọn dẹp rác khi hoàn thành
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
