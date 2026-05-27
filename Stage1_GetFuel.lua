local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- Cấu hình Pathfinding tối ưu né góc vật cản
local path = PathfindingService:CreatePath({
    AgentRadius = 2.0, -- Tăng bán kính để nhân vật đi xa tường hơn
    AgentHeight = 5, 
    AgentCanJump = true
})
local ignoredFuels = {}

-- =========================================================================
-- 🛡️ HÀM KIỂM TRA CHỐNG XUYÊN TƯỜNG (RAYCAST SENSOR)
-- =========================================================================
local function isWallInFront(startPos, endPos, char)
    local direction = (endPos - startPos)
    local distance = direction.Magnitude
    
    if distance == 0 then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char} -- Bỏ qua chính bản thân nhân vật
    raycastParams.IgnoreWater = true
    
    -- Bắn một tia quét từ vị trí hiện tại đến điểm tiếp theo (Hạ thấp tia xuống tầm chân/ngực để quét gạch vụn)
    local rayOrigin = startPos + Vector3.new(0, -1, 0) 
    local raycastResult = Workspace:Raycast(rayOrigin, direction, raycastParams)
    
    if raycastResult and raycastResult.Instance then
        local hitObj = raycastResult.Instance
        local name = hitObj.Name
        
        -- Danh sách chặn tuyệt đối không cho phép xuyên qua (Dựa theo ảnh bạn gửi)
        if string.find(name, "Broken") or string.find(name, "Wall") or string.find(name, "Flat") or hitObj.CanCollide == true then
            -- Chỉ chặn nếu khoảng cách đến mảnh vỡ quá gần (dưới 3.5 studs), có nguy cơ đi xuyên
            if raycastResult.Distance < 3.5 then
                return true
            end
        end
    end
    return false
end

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ FUEL CHÍNH XÁC
-- =========================================================================
local function getNearestFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" and obj:IsA("Model") and not ignoredFuels[obj] then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (rootPosition - part.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    nearestFuel = part
                end
            end
        end
    end
    return nearestFuel
end

-- =========================================================================
-- 🔥 HÀM TWEEN TỰ ĐỘNG DÒ ĐƯỜNG VÀ CẤM XUYÊN TƯỜNG
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    local char = rootPart.Parent
    
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
            
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 1.2, waypoint.Position.Z)
            local distance = (rootPart.Position - waypoint.Position).Magnitude
            
            -- 🛑 KIỂM TRA TRƯỚC KHI TWEEN: Nếu phát hiện Tường/Mảnh vỡ chắn giữa đường -> Hủy Tween lập tức để đi vòng
            if isWallInFront(rootPart.Position, waypoint.Position, char) then
                print("[🛡️ ANTI-CHEAT] Phát hiện khối Broken/Tường phía trước! Ngừng di chuyển đâm xuyên.")
                -- Nhếch nhẹ lùi lại hoặc nảy lên để tìm góc thoát
                rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, 1) 
                task.wait(0.1)
                
                -- Ép tính toán lại đường đi mới vòng qua vật cản
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
            
            local tween = TweenService:Create(rootPart, TweenInfo.new(distance / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            
            local tweenCompleted = false
            local connection
            connection = tween.Completed:Connect(function()
                tweenCompleted = true
                if connection then connection:Disconnect() end
            end)
            
            local lastPosition = rootPart.Position
            local checkTimer = os.clock()
            local loopTimeout = os.clock()
            local needRecalculate = false
            
            while not tweenCompleted do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                if i < totalWaypoints and currentDist < 3.2 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    break
                elseif i == totalWaypoints and currentDist < 1.5 then
                    break
                end
                
                -- SENSOR CHECK CẠ TƯỜNG NỔI VÀ KHỐI VẬT LÝ BIẾN ĐỘNG
                if (os.clock() - checkTimer) > 0.12 then
                    local movedDistance = (rootPart.Position - lastPosition).Magnitude
                    
                    -- Nếu đang lướt mà bị khựng lại do đập vào các khối "Broken"
                    if movedDistance < 0.6 or isWallInFront(rootPart.Position, waypoint.Position, char) then 
                        tween:Cancel()
                        if connection then connection:Disconnect() end
                        
                        -- Nhấc nhẹ góc tọa độ lên để không dính chân vào gạch vụn phẳng (Broken_Flat)
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 1.8, 0)
                        needRecalculate = true
                        break
                    end
                    
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end
                
                if (os.clock() - loopTimeout) > 4 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    needRecalculate = true
                    break 
                end
                
                RunService.Heartbeat:Wait()
            end
            
            if needRecalculate then
                task.wait(0.1)
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
        
        local finalDist = (rootPart.Position - targetPart.Position).Magnitude
        return finalDist < 4.5
    else
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 1.5, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos)
        task.wait(0.15)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1
-- =========================================================================
print("[STAGE 1] Bắt đầu quét tìm nhặt 2 bình Fuel (Chế độ An Toàn Chống Xuyên Tường)...")
local cycle = 1
local stuckCounter = 0

while cycle <= 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelModel = targetFuel.Parent
        local success = walkPathToTarget(root, targetFuel)
        
        if success then
            print(string.format("[🎉] Đã tiếp cận Fuel %d/2 thành công an toàn!", cycle))
            
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or fuelModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            
            ignoredFuels[fuelModel] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.5)
        else
            stuckCounter = stuckCounter + 1
            if stuckCounter >= 3 then
                print("[⚠️] Bình xăng nằm ở góc khuất nguy hiểm, bỏ qua để bảo vệ Acc khỏi Anti-cheat!")
                ignoredFuels[fuelModel] = true
                stuckCounter = 0
            end
            task.wait(0.1)
        end
    else
        print("[-] Đang quét tìm kiếm lại tài nguyên Fuel...")
        ignoredFuels = {}
        task.wait(0.5)
    end
end

print("[STAGE 1] HOÀN THÀNH XUẤT SẮC - CHUYỂN SANG STAGE 2!")
_G.CurrentStage = 2
return true
