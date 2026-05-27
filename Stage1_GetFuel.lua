-- =========================================================================
-- 🔥 HÀM TWEEN DÒ ĐƯỜNG THỜI GIAN THỰC - TỰ ĐỘNG BẺ LÁI NÉ TƯỜNG (TỐC ĐỘ 30)
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        -- Khởi tạo thông số Raycast nâng cao để phát hiện vật cản phía trước
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {rootPart.Parent, targetPart, targetPart.Parent}
        raycastParams.IgnoreWater = true

        local i = 1
        while i <= totalWaypoints do
            if not rootPart.Parent or not targetPart.Parent then return false end
            local waypoint = waypoints[i]
            
            -- Tối ưu độ cao lướt: Giảm xuống 1.2 stud giúp nhân vật không bị vướng phần đầu vào trần nhà/cửa sổ
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 1.2, waypoint.Position.Z)
            local distance = (rootPart.Position - waypoint.Position).Magnitude
            
            -- BẮT ĐẦU TWEEN CHẶNG NÚT
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
            local needRecalculate = false -- Biến đánh dấu cần tính toán lại bản đồ
            
            while not tweenCompleted do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                -- Cơ chế cuốn chiếu (gối đầu mượt): Gần tới nút là chuyển tiếp ngay không khựng chân
                if i < totalWaypoints and currentDist < 3.2 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    break
                elseif i == totalWaypoints and currentDist < 1.5 then
                    break
                end
                
                -- 🕵️ CẢM BIẾN KIỂM TRA VA CHẠM VÀ KẸT TƯỜNG (0.12 giây một lần)
                if (os.clock() - checkTimer) > 0.12 then
                    local movedDistance = (rootPart.Position - lastPosition).Magnitude
                    local moveDirection = (waypoint.Position - rootPart.Position).Unit
                    
                    -- Cách 1: Bắn tia quét tầm ngắn xem mặt có đang đập vào tường không
                    local wallCheck = Workspace:Raycast(rootPart.Position, moveDirection * 2.5, raycastParams)
                    
                    -- Cách 2: Hoặc dựa vào khoảng cách di chuyển thực tế quá thấp (bị cạ tường đứng yên)
                    if (wallCheck and wallCheck.Instance and wallCheck.Instance.CanCollide) or (movedDistance < 0.6) then
                        tween:Cancel()
                        if connection then connection:Disconnect() end
                        
                        -- Nhếch nhẹ nhẹ CFrame để thoát khỏi điểm ma sát của vách
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 1.5, 0)
                        needRecalculate = true -- Kích hoạt trạng thái tìm đường mới
                        break
                    end
                    
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end
                
                -- Khóa bảo vệ chống treo chặng
                if (os.clock() - loopTimeout) > 4 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    needRecalculate = true
                    break 
                end
                
                RunService.Heartbeat:Wait()
            end
            
            -- 🔀 ĐỘT PHÁ TỰ ĐỘNG DÒ LẠI ĐƯỜNG:
            -- Nếu phát hiện bị cản, lập tức vẽ lại một map đường đi mới ngay từ vị trí hiện tại
            if needRecalculate then
                task.wait(0.05) -- Nghỉ cực ngắn để tránh spam bộ nhớ
                local reSuccess = pcall(function()
                    path:ComputeAsync(rootPart.Position, targetPart.Position)
                end)
                if reSuccess and path.Status == Enum.PathStatus.Success then
                    waypoints = path:GetWaypoints()
                    totalWaypoints = #waypoints
                    i = 1 -- Reset vòng lặp về nút đầu tiên của lộ trình mới né tường
                else
                    return false -- Nếu không tìm được đường mới thì đổi mục tiêu
                end
            else
                i = i + 1 -- Đường thông thoáng thì đi tiếp nút tiếp theo
            end
        end
        return true
    else
        -- Nhếch ngẫu nhiên tìm góc quét mới nếu lỗi map ban đầu
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 1.2, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos)
        task.wait(0.15)
        return false
    end
end
