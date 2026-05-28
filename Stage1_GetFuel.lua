local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer

-- Cấu hình tốc độ di chuyển vật lý khi đi nhặt đồ
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
-- 🔥 HÀM DI CHUYỂN ÁP SÁT (TỐC ĐỘ 30 - KHÔNG XUYÊN TƯỜNG)
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    local char = localPlayer.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    -- Thiết lập tốc độ chạy cho Humanoid bằng 30 như bạn yêu cầu
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
                
                -- Nút dọc đường: cách 3.5 studs thì rẽ tiếp. Nút sát đích: ép sát < 1.0 studs
                if not isLastWaypoint and currentDist < 3.5 then
                    break
                elseif isLastWaypoint and currentDist < 1.0 then
                    break
                end
                
                -- Phân tích kẹt cạ tường dựa trên tốc độ thực tế
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

                local maxWaitTime = isLastWaypoint and 5 or 3
                if (os.clock() - loopTimeout) > maxWaitTime then
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
        
        -- Cú rướn lực cuối: Ép sát dẫm hẳn lên vật phẩm
        humanoid:MoveTo(targetPart.Position)
        local forceTimeout = os.clock()
        while (rootPart.Position - targetPart.Position).Magnitude > 1.5 do
            if (os.clock() - forceTimeout) > 0.8 then break end
            RunService.Heartbeat:Wait()
        end
        
        local finalDist = (rootPart.Position - targetPart.Position).Magnitude
        return finalDist < 4.5
    else
        humanoid.Jump = true
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH (GOM ĐỦ 2 BÌNH RỒI CHUYỂN STAGE)
-- =========================================================================
print("[STAGE 1] Khởi chạy hệ thống quét gom đúng 2 bình Fuel với tốc độ 30...")

local completedFuels = 0
local stuckCounter = 0

while completedFuels < 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    -- Quét tìm 2 bình gần nhất
    local targetList = getTwoNearestFuels(root.Position)
    
    if #targetList > 0 then
        for index, fuelData in ipairs(targetList) do
            char = localPlayer.Character
            root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then break end
            
            local targetFuel = fuelData.Part
            local fuelModel = fuelData.Model
            
            print(string.format("[-->] Tiến tới bình Fuel %d/2 (Tốc độ: 30)", completedFuels + 1))
            
            local success = walkPathToTarget(root, targetFuel)
            if success then
                print(string.format("[🎉] Đã chạm bình Fuel thứ %d thành công thực tế!", completedFuels + 1))
                
                -- Kích hoạt ProximityPrompt nhặt đồ tại chỗ
                local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or fuelModel:FindFirstChildOfClass("ProximityPrompt")
                if prompt then fireproximityprompt(prompt) end
                
                ignoredFuels[fuelModel] = true 
                completedFuels = completedFuels + 1
                stuckCounter = 0
                task.wait(0.6) -- Chờ server cập nhật túi đồ
                
                -- Nếu đã nhặt đủ 2 bình, bẻ gãy vòng lặp ngay lập tức
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
        print("[-] Không tìm thấy Fuel, đang làm sạch danh sách chặn để quét lại...")
        ignoredFuels = {}
        task.wait(1)
    end
end

-- =========================================================================
-- ⚡ CHUYỂN THẲNG SANG STAGE 2
-- =========================================================================
print("[🚀] ĐÃ NHẶT ĐỦ 2 BÌNH FUEL! Thực hiện chuyển trạng thái...")
_G.CurrentStage = 2
return true
