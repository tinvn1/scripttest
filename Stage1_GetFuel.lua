local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- Cấu hình Pathfinding tối ưu né góc vật cản rộng hơn để giảm thiểu va quẹt
local path = PathfindingService:CreatePath({
    AgentRadius = 2.5, -- Tăng từ 1.6 lên 2.5 để thuật toán Roblox tự động vẽ đường xa rìa tường vỡ
    AgentHeight = 5, 
    AgentCanJump = true
})
local ignoredFuels = {}

-- =========================================================================
-- 🛡️ HÀM RAYCAST QUÉT CHECK VẬT CẢN VẬT LÝ CHÍNH XÁC
-- =========================================================================
local function isWallInFront(startPos, endPos, char)
    local direction = (endPos - startPos)
    local distance = direction.Magnitude
    
    if distance == 0 then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.IgnoreWater = true
    
    -- Hạ thấp gốc quét xuống -1 stud để quét trúng các mảnh Broken_Flat nằm sát đất
    local rayOrigin = startPos + Vector3.new(0, -1, 0)
    local raycastResult = Workspace:Raycast(rayOrigin, direction, raycastParams)
    
    if raycastResult and raycastResult.Instance then
        local hitObj = raycastResult.Instance
        local name = hitObj.Name
        
        -- Phát hiện các khối thuộc danh sách đen của bạn
        if string.find(name, "Broken") or string.find(name, "Wall") or string.find(name, "Flat") or hitObj.CanCollide == true then
            if raycastResult.Distance < 4.0 then -- Tầm quét bảo vệ an toàn
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
-- 🔥 HÀM TWEEN TỰ ĐỘNG DÒ ĐƯỜNG - FIX TRIỆT ĐỂ SPAM KẸT GÓC
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
        local stuckSpamCounter = 0 -- Bộ đếm kiểm soát chống spam vòng lặp kẹt
        
        while i <= totalWaypoints do
            if not rootPart.Parent or not targetPart.Parent then return false end
            local waypoint = waypoints[i]
            
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 1.2, waypoint.Position.Z)
            local distance = (rootPart.Position - waypoint.Position).Magnitude
            
            -- ĐOẠN FIX: XỬ LÝ KHI PHÁT HIỆN VẬT CẢN (KHÔNG ĐỂ SPAM LOG)
            if isWallInFront(rootPart.Position, waypoint.Position, char) then
                stuckSpamCounter = stuckSpamCounter + 1
                
                if stuckSpamCounter >= 3 then
                    -- Nếu bị kẹt liên tục tại 1 điểm, dùng biện pháp mạnh: Búng CFrame lên trời + bẻ lái ngẫu nhiên
                    print("[🚀 EMERGENCY] Phát hiện vùng gạch vỡ quá dày! Thực hiện bứt phá nhảy qua góc chết...")
                    local escapeAngle = math.rad(math.random(0, 360))
                    -- Nhấc bổng trục Y lên hẳn 3 studs để vượt qua chướng ngại vật phẳng, tránh cọ xát
                    local escapePos = rootPart.Position + Vector3.new(math.sin(escapeAngle) * 4, 3.0, math.cos(escapeAngle) * 4)
                    rootPart.CFrame = CFrame.new(escapePos)
                    stuckSpamCounter = 0
                else
                    print("[🛡️ ANTI-CHEAT] Phát hiện khối Broken phía trước! Lùi lại tìm hướng mới.")
                    -- Giật lùi ra sau 2 studs để thoát tầm quét
                    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, 2)
                end
                
                task.wait(0.2) -- Thời gian nghỉ vừa đủ để hệ thống vật lý đồng bộ
                
                -- Tính toán lại một lộ trình hoàn toàn mới từ vị trí vừa thoát kẹt
                local reSuccess = pcall(function()
                    path:ComputeAsync(rootPart.Position, targetPart.Position)
                end)
                if reSuccess and path.Status == Enum.PathStatus.Success then
                    waypoints = path:GetWaypoints()
                    totalWaypoints = #waypoints
                    i = 1 -- Reset chặng chạy về 1
                    continue
                else
                    return false
                end
            end
            
            -- Di chuyển bình thường -> Reset bộ đếm khẩn cấp
            stuckSpamCounter = 0
            
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
                
                -- SENSOR THEO DÕI TRONG KHI TWEEN TỐI ƯU HÓA TỐC ĐỘ ĐÁP ỨNG
                if (os.clock() - checkTimer) > 0.15 then
                    local movedDistance = (rootPart.Position - lastPosition).Magnitude
                    
                    -- Nếu đứng im không di chuyển được hoặc tia raycast báo có tường đổi hướng đột ngột
                    if movedDistance < 0.5 or isWallInFront(rootPart.Position, waypoint.Position, char) then 
                        tween:Cancel()
                        if connection then connection:Disconnect() end
                        
                        -- Nhấc nhẹ CFrame lên cao 2 studs để tránh bị kẹt các góc cạnh nhỏ dưới chân
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 2.0, 0)
                        needRecalculate = true
                        break
                    end
                    
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end
                
                if (os.clock() - loopTimeout) > 3.0 then -- Giảm thời gian chờ xuống 3s để giải kẹt nhanh hơn
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
        -- Phá kẹt ở luồng tổng nếu không tìm thấy đường đi ngay từ đầu
        local nhichPos = rootPart.Position + Vector3.new(math.random(-4, 4), 2.0, math.random(-4, 4))
        rootPart.CFrame = CFrame.new(nhichPos)
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1
-- =========================================================================
print("[STAGE 1] Bắt đầu quét tìm nhặt 2 bình Fuel (Chế độ Chống Xuyên Tường nâng cao)...")
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
                print("[⚠️ BỎ QUA] Bình xăng nằm ở vị trí bất khả thi / Góc kẹt quá hiểm, bỏ qua tìm bình khác!")
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
