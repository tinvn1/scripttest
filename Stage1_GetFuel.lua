local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 35 -- Tốc độ lướt Tween mượt mà của bạn

-- Cấu hình Pathfinding chuẩn của Roblox để dò đường trống quanh tường
local stage1Path = PathfindingService:CreatePath({
    AgentRadius = 2, 
    AgentHeight = 5, 
    AgentCanJump = true
})

-- =========================================================================
-- 🔥 HÀM DÒ TÌM VẬT PHẨM CHÍNH XÁC THEO TÊN "Fuel" TRÊN MAP
-- =========================================================================
local function getTargetFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    
    -- Quét toàn bộ Workspace để định vị các cục "Fuel" dựa theo ảnh mẫu
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" then
            -- Xác định BasePart để lấy tọa độ Position chính xác
            local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            
            if targetPart and targetPart:IsA("BasePart") then
                local dist = (rootPosition - targetPart.Position).Magnitude
                if dist < minDistance then 
                    minDistance = dist
                    nearestFuel = targetPart 
                end
            end
        end
    end
    return nearestFuel
end

-- =========================================================================
-- 🔥 HÀM TWEEN THEO ĐƯỜNG DÒ (CHỐNG XUYÊN TƯỜNG, TỰ GỠ KẸT)
-- =========================================================================
local function tweenAlongPath(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    -- Tính toán lộ trình đi bộ an toàn vòng qua các chướng ngại vật vững chắc
    local success, err = pcall(function()
        stage1Path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and stage1Path.Status == Enum.PathStatus.Success then
        local waypoints = stage1Path:GetWaypoints()
        
        -- Duyệt qua từng điểm nút an toàn được vạch ra
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- Tự động kích hoạt lệnh nhảy nếu điểm nút yêu cầu vượt chướng ngại vật thấp
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            local startPos = rootPart.Position
            -- Tạo tọa độ đích cao hơn mặt đất 2 stud để lướt Tween không bị ma sát lún sàn
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local distance = (rootPart.Position - waypoint.Position).Magnitude
            
            -- Thực hiện lướt Tween mượt mà đến điểm nút tiếp theo
            local tween = TweenService:Create(rootPart, TweenInfo.new(distance / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            
            local tweenCompleted = false
            local connection
            connection = tween.Completed:Connect(function()
                tweenCompleted = true
                connection:Disconnect()
            end)
            
            local startTime = os.clock()
            -- Vòng lặp bọc lót thời gian thực đề phòng trường hợp bị vướng mép cửa hoặc góc khuất
            while not tweenCompleted do
                if (os.clock() - startTime) > 0.3 then
                    -- Nếu sau 0.3 giây lướt Tween mà nhân vật dịch chuyển chưa đầy 1 stud chứng tỏ bị vướng vật cản
                    if (rootPart.Position - startPos).Magnitude < 1 then
                        humanoid.Jump = true -- Ép nhân vật nhảy lên
                        
                        -- Nhếch nhẹ CFrame hướng về phía trước theo vector điểm nút để thoát kẹt
                        local lookDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.5, lookDirection.Z * 1.5)
                        
                        tween:Cancel() -- Hủy lệnh Tween cũ đang bị kẹt để nạp chặng mới
                        break
                    end
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                task.wait(0.05)
            end
            task.wait(0.01)
        end
        return true
    else
        -- Dự phòng nếu cục Fuel rơi vào vị trí quá hiểm hóc không dò được đường, nhích nhẹ CFrame để tìm lại góc quét
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y + 2, nhichPos.Z)
        task.wait(0.2)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1 (CHẠY ĐỘC LẬP HOÀN TOÀN)
-- =========================================================================
print("[STAGE 1] Khởi chạy luồng Tween dò đường lấy Fuel thông minh...")
local stage1Finished = false
local emptyScanCount = 0

while not stage1Finished do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        -- Dò tìm cục Fuel gần nhất dựa trên vị trí nhân vật
        local targetFuel = getTargetFuel(root.Position)
        
        if targetFuel then
            emptyScanCount = 0 -- Reset bộ đếm khi tìm thấy đồ
            local distance = (root.Position - targetFuel.Position).Magnitude
            
            -- Nếu ở xa, tiến hành lướt Tween men theo đường đi an toàn đã dò sẵn
            if distance > 4 then
                tweenAlongPath(root, humanoid, targetFuel)
            else
                print("[🎯 STAGE 1 SUCCESS] Đã tiếp cận sát Fuel bằng đường lướt Tween an toàn!")
                
                -- Kích hoạt nhặt vật phẩm thông qua ProximityPrompt hoặc cơ chế chạm của game
                local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                else
                    -- Nếu không dùng prompt, ép sát CFrame để chạm vật lý (Touch) tự động nhặt
                    root.CFrame = CFrame.new(targetFuel.Position)
                end
                
                stage1Finished = true -- Đánh dấu hoàn thành xong chặng 1
            end
        else
            -- Bộ đếm dự phòng nếu không nhìn thấy cục Fuel nào trên map
            emptyScanCount = emptyScanCount + 1
            if emptyScanCount >= 5 then
                print("[🏁 STAGE 1] Không tìm thấy thêm Fuel nào trên Map. Tự động chuyển màn.")
                stage1Finished = true
            end
        end
    end
    task.wait(0.2)
end

task.wait(0.5)

-- 🔥 CHUYỂN GIAO SẠCH SẼ SANG STAGE 2
print("[🚀] Stage 1 kết thúc hoàn hảo. Chuyển giao luồng sang Stage 2...");
_G.CurrentStage = 2
return true
