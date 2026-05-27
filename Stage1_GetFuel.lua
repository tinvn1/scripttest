local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- Khởi tạo Pathfinding cấu hình chuẩn Roblox (Thu nhỏ bán kính để len lỏi ngách nhỏ tốt hơn)
local path = PathfindingService:CreatePath({
    AgentRadius = 1.6, 
    AgentHeight = 5, 
    AgentCanJump = true
})
local ignoredFuels = {}

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ FUEL CHÍNH XÁC VÀ AN TOÀN
-- =========================================================================
local function getNearestFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" and (obj:IsA("Model") or obj:IsA("BasePart")) and not ignoredFuels[obj] then
            local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
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
-- 🔥 HÀM TWEEN DÒ ĐƯỜNG KỸ LƯỠNG - CHỐNG KẸT GÓC KHUẤT TUYỆT ĐỐI
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- Tính toán tọa độ lướt mượt (cao hơn mặt sàn 1.8 stud chống ma sát lún chân)
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 1.8, waypoint.Position.Z)
            local distance = (rootPart.Position - waypoint.Position).Magnitude
            
            -- Khởi tạo Tween cho chặng nút hiện tại
            local tween = TweenService:Create(rootPart, TweenInfo.new(distance / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            
            local tweenCompleted = false
            local connection
            connection = tween.Completed:Connect(function()
                tweenCompleted = true
                if connection then connection:Disconnect() end
            end)
            
            -- Cảm biến theo dõi chống kẹt thời gian thực
            local lastPosition = rootPart.Position
            local checkTimer = os.clock()
            local loopTimeout = os.clock()
            
            while not tweenCompleted do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                -- Cơ chế gối đầu thông minh: Gần tới nút là chuyển tiếp ngay để không bị khựng chân
                if i < totalWaypoints and currentDist < 3.5 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    break
                elseif i == totalWaypoints and currentDist < 1.5 then
                    break
                end
                
                -- CỨ MỖI 0.15 GIÂY -> Kiểm tra xem có bị kẹt vào tường/cửa không
                if (os.clock() - checkTimer) > 0.15 then
                    local movedDistance = (rootPart.Position - lastPosition).Magnitude
                    
                    if movedDistance < 0.8 then -- Di chuyển quá ít chứng tỏ bị cạ tường kẹt góc
                        tween:Cancel() -- Hủy lệnh lướt cũ đang bị kẹt
                        if connection then connection:Disconnect() end
                        
                        -- KÍCH HOẠT HỆ THỐNG THOÁT KẸT: Nhếch CFrame lên cao và bọc sang hướng điểm nút
                        local lookDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.2, lookDirection.Z * 1.5)
                        task.wait(0.05)
                        break -- Thoát vòng lặp chặng này để ép tính toán lộ trình bọc lót
                    end
                    
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end
                
                -- Khóa bảo vệ chống treo luồng (Quá 5 giây cho 1 waypoint là tự hủy chặng)
                if (os.clock() - loopTimeout) > 5 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    break 
                end
                
                RunService.Heartbeat:Wait() -- Chờ theo tần số khung hình máy tính thay vì task.wait lề mề
            end
        end
        return true
    else
        -- Nếu bản đồ thay đổi đột ngột làm Pathfinding thất bại, nhếch ngẫu nhiên tìm góc quét mới
        local nhichPos = rootPart.Position + Vector3.new(math.random(-4, 4), 1.5, math.random(-4, 4))
        rootPart.CFrame = CFrame.new(nhichPos)
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1
-- =========================================================================
print("[STAGE 1] Bắt đầu quét tìm nhặt 2 bình Fuel (Dò đường kỹ lưỡng)...")
local cycle = 1
local stuckCounter = 0

while cycle <= 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        -- Nhận diện chính xác Model hoặc Part gốc để đưa vào danh sách bỏ qua khi xong việc
        local fuelObject = targetFuel.Parent:IsA("Model") and targetFuel.Parent or targetFuel
        local success = walkPathToTarget(root, targetFuel)
        
        if success then
            print(string.format("[🎉] Đã tiếp cận Fuel %d/2 thành công!", cycle))
            
            -- Chạm vật lý và kích hoạt ProximityPrompt (nếu có) để đảm bảo game nhận lệnh nhặt đồ
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            
            ignoredFuels[fuelObject] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.4)
        else
            stuckCounter = stuckCounter + 1
            if stuckCounter >= 3 then
                print("[⚠️] Bình xăng này nằm ở góc kẹt không thể giải toán đường đi, bỏ qua để tìm bình khác!")
                ignoredFuels[fuelObject] = true
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

print("[STAGE 1] HOÀN THÀNH XUẤT SẮC!")
_G.CurrentStage = 2
return true
