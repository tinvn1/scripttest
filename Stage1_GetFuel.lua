local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30
-- Cấu hình Pathfinding tối ưu né góc vật cản
local path = PathfindingService:CreatePath({
    AgentRadius = 1.6, 
    AgentHeight = 5, 
    AgentCanJump = true
})
local ignoredFuels = {}

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
-- 🔥 HÀM TWEEN TỰ ĐỘNG DÒ ĐƯỜNG VÀ KIỂM TRA ĐÍCH THỰC TẾ
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
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
            
            -- Trọng tâm Y + 1.2 vừa đủ tầm trung để không bị vướng đầu vào trần vách
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 1.2, waypoint.Position.Z)
            local distance = (rootPart.Position - waypoint.Position).Magnitude
            
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
                
                -- Cuốn chiếu chặng nút mượt không khựng chân
                if i < totalWaypoints and currentDist < 3.2 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    break
                elseif i == totalWaypoints and currentDist < 1.5 then
                    break
                end
                
                -- 🕵️ SENSOR CHECK CẠ TƯỜNG (0.12s phản hồi một lần)
                if (os.clock() - checkTimer) > 0.12 then
                    local movedDistance = (rootPart.Position - lastPosition).Magnitude
                    
                    if movedDistance < 0.6 then -- Nhân vật đứng im hoặc cạ tường di chuyển quá ít
                        tween:Cancel()
                        if connection then connection:Disconnect() end
                        
                        -- Nhếch nhẹ CFrame lên hỗ trợ thoát ma sát mặt sàn/vách góc
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 1.5, 0)
                        needRecalculate = true
                        break
                    end
                    
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end
                
                -- Anti-stuck treo luồng cứng
                if (os.clock() - loopTimeout) > 4 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    needRecalculate = true
                    break 
                end
                
                RunService.Heartbeat:Wait()
            end
            
            -- ĐỘT PHÁ TỰ DÒ ĐƯỜNG LẠI KHI KẸT
            if needRecalculate then
                task.wait(0.05)
                local reSuccess = pcall(function()
                    path:ComputeAsync(rootPart.Position, targetPart.Position)
                end)
                if reSuccess and path.Status == Enum.PathStatus.Success then
                    waypoints = path:GetWaypoints()
                    totalWaypoints = #waypoints
                    i = 1 -- Đặt lại luồng chạy từ đầu lộ trình mới để bẻ lái né tường
                else
                    return false
                end
            else
                i = i + 1
            end
        end
        
        -- 🛑 CHỐT CHẶN CUỐI: Kiểm tra khoảng cách thực tế đến Fuel sau khi đi hết map
        -- Khoảng cách phải < 4.5 studs thì mới tính là tiếp cận thành công và nhặt được đồ
        local finalDist = (rootPart.Position - targetPart.Position).Magnitude
        return finalDist < 4.5
    else
        -- Nhếch ngẫu nhiên tìm góc quét mới nếu lỗi tính toán map ban đầu
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 1.2, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos)
        task.wait(0.15)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1
-- =========================================================================
print("[STAGE 1] Bắt đầu quét tìm nhặt 2 bình Fuel...")
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
            print(string.format("[🎉] Đã tiếp cận Fuel %d/2 thành công thực tế!", cycle))
            
            -- Tự động kích hoạt ProximityPrompt để đảm bảo nhặt được đồ
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or fuelModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            
            ignoredFuels[fuelModel] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.5)
        else
            -- Nếu thất bại (do kẹt góc nặng hoặc không chạm được đồ)
            stuckCounter = stuckCounter + 1
            if stuckCounter >= 3 then
                print("[⚠️] Bình xăng bị kẹt góc không thể xử lý giải toán, bỏ qua tìm bình khác!")
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

-- KHOÁ BẢO VỆ CHẮC CHẮN ĐÃ QUA MÀN
print("[STAGE 1] HOÀN THÀNH XUẤT SẮC - CHUYỂN SANG STAGE 2!")
_G.CurrentStage = 2
return true
