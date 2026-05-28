local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer

-- Cấu hình tốc độ di chuyển vật lý
local TARGET_SPEED = 30 

-- Cấu hình Pathfinding an toàn chống cạ tường
local path = PathfindingService:CreatePath({
    AgentRadius = 2.4, 
    AgentHeight = 5, 
    AgentCanJump = true
})
local ignoredFuels = {}

-- =========================================================================
-- 🛡️ HÀM RAYCAST CHỐNG XUYÊN TƯỜNG
-- =========================================================================
local function isWallInFront(rootPart, targetPosition)
    local origin = rootPart.Position
    local direction = (targetPosition - origin).Unit * math.min(4, (targetPosition - origin).Magnitude)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local excludeList = {localPlayer.Character}
    for fuel, _ in pairs(ignoredFuels) do table.insert(excludeList, fuel) end
    raycastParams.FilterDescendantsInstances = excludeList
    
    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
    if raycastResult and raycastResult.Instance.CanCollide then
        return true
    end
    return false
end

-- =========================================================================
-- 🎯 HÀM LẤY DANH SÁCH BÌNH FUEL GẦN NHẤT
-- =========================================================================
local function getTwoNearestFuels(rootPosition)
    local fuelList = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" and obj:IsA("Model") and not ignoredFuels[obj] then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (rootPosition - part.Position).Magnitude
                table.insert(fuelList, {Part = part, Model = obj, Distance = dist})
            end
        end
    end
    
    table.sort(fuelList, function(a, b) return a.Distance < b.Distance end)
    
    local targets = {}
    if fuelList[1] then table.insert(targets, fuelList[1]) end
    if fuelList[2] then table.insert(targets, fuelList[2]) end
    return targets
end

-- =========================================================================
-- 🔥 HÀM DI CHUYỂN LẠI GẦN VÀ HỦY ĐĂNG KÝ Ở MỐC 3 STUDS (KHÔNG NHẶT ĐỒ)
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    local char = localPlayer.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    humanoid.WalkSpeed = TARGET_SPEED

    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        local i = 1
        while i <= totalWaypoints do
            if not rootPart.Parent or not targetPart.Parent then return false end
            local waypoint = waypoints[i]
            local isLastWaypoint = (i == totalWaypoints)
            
            -- Kiểm tra tường chắn dọc đường
            if not isLastWaypoint and isWallInFront(rootPart, waypoint.Position) then
                task.wait(0.05)
                local reSuccess = pcall(function()
                    path:ComputeAsync(rootPart.Position, targetPart.Position)
                end)
                if reSuccess and path.Status == Enum.PathStatus.Success then
                    waypoints = path:GetWaypoints()
                    totalWaypoints = #waypoints
                    i = 1 
                    continue
                else
                    return false
                end
            end

            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoint.Position)
            
            local checkTimer = os.clock()
            local loopTimeout = os.clock()
            local lastPosition = rootPart.Position
            local needRecalculate = false
            
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                -- Nút dọc đường: cách 3.5 studs rẽ tiếp. 
                -- Nút cuối: Cách đúng 3.0 studs là HỦY chặng ngay lập tức
                if not isLastWaypoint and currentDist < 3.5 then
                    break
                elseif isLastWaypoint and currentDist <= 3.0 then
                    break
                end
                
                -- Phân tích kẹt cạ tường vật lý
                if (os.clock() - checkTimer) > 0.15 then
                    local movedDistance = (rootPart.Position - lastPosition).Magnitude
                    if movedDistance < 0.5 then 
                        humanoid.Jump = true 
                        needRecalculate = true
                        break
                    end
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end

                if (os.clock() - loopTimeout) > 4 then
                    needRecalculate = true
                    break
                end

                RunService.Heartbeat:Wait()
            end
            
            if needRecalculate then
                task.wait(0.05)
                local reSuccess = pcall(function()
                    path:ComputeAsync(rootPart.Position, targetPart.Position)
                end)
                if reSuccess and path.Status == Enum.PathStatus.Success then
                    waypoints = path:GetWaypoints()
                    totalWaypoints = #waypoints
                    i = 1
                else
                    return false
                end
            else
                i = i + 1
            end
        end
        
        -- Dừng hẳn nhân vật tại mốc 3 studs, không cho bước tiếp
        humanoid:MoveTo(rootPart.Position) 
        
        local finalDist = (rootPart.Position - targetPart.Position).Magnitude
        return finalDist <= 3.5
    else
        humanoid.Jump = true
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH (TIẾP CẬN ĐỦ 2 BÌNH RỒI CHUYỂN STAGE)
-- =========================================================================
print("[STAGE 1] Khởi chạy hệ thống tiếp cận 2 bình Fuel (Tốc độ 30, dừng ở 3 studs)...")

local completedFuels = 0
local stuckCounter = 0

while completedFuels < 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetList = getTwoNearestFuels(root.Position)
    
    if #targetList > 0 then
        for index, fuelData in ipairs(targetList) do
            char = localPlayer.Character
            root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then break end
            
            local targetFuel = fuelData.Part
            local fuelModel = fuelData.Model
            
            print(string.format("[-->] Đang đi lại gần bình Fuel %d/2...", completedFuels + 1))
            
            local success = walkPathToTarget(root, targetFuel)
            if success then
                print(string.format("[🎉] Đã tiếp cận thành công ở khoảng cách 3 studs với mục tiêu %d!", completedFuels + 1))
                
                -- CHỈ HỦY ĐĂNG KÝ VÀ ĐÁNH DẤU HOÀN THÀNH (KHÔNG CÓ LỆNH FIREPROXIMITYPROMPT)
                ignoredFuels[fuelModel] = true 
                completedFuels = completedFuels + 1
                stuckCounter = 0
                task.wait(0.2) -- Giảm thời gian chờ xuống vì không cần đợi server đồng bộ nhặt đồ
                
                if completedFuels >= 2 then break end
            else
                stuckCounter = stuckCounter + 1
                if stuckCounter >= 3 then
                    ignoredFuels[fuelModel] = true
                    stuckCounter = 0
                    break 
                end
            end
        end
    else
        print("[-] Không tìm thấy Fuel nào khác, quét lại map...")
        ignoredFuels = {}
        task.wait(1)
    end
end

-- =========================================================================
-- ⚡ CHUYỂN THẲNG SANG STAGE 2
-- =========================================================================
print("[🚀] ĐÃ TIẾP CẬN ĐỦ 2 MỤC TIÊU! Chuyển thẳng hệ thống sang STAGE 2.")
_G.CurrentStage = 2
return true
