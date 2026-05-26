local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 -- Đảm bảo tốc độ chạy nhanh là 30 giống Stage 3

-- Khởi tạo cấu hình Pathfinding gốc của Roblox giúp tính toán đường đi quanh tường
local path = PathfindingService:CreatePath({
    AgentRadius = 2, 
    AgentHeight = 5, 
    AgentCanJump = true
})

-- =========================================================================
-- 🔥 HÀM DÒ TÌM VẬT PHẨM/ĐỒ CẦN LẤY (Thay đổi tên Item cho đúng game của bạn)
-- =========================================================================
local function getTargetItem(rootPosition)
    local nearestItem = nil
    local minDistance = math.huge
    
    -- Vòng lặp quét tìm đồ vật cần lấy (Bạn có thể đổi tên "Item" hoặc "Tool" tùy map)
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Ví dụ: Tìm các vật thể có tên là "Item" hoặc chứa thuộc tính ClickDetector/Prompt để lấy
        if obj.Name == "Item" or obj:IsA("Tool") or obj.Name == "Loot" then
            local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            
            if targetPart and targetPart:IsA("BasePart") then
                local dist = (rootPosition - targetPart.Position).Magnitude
                if dist < minDistance then 
                    minDistance = dist
                    nearestItem = targetPart 
                end
            end
        end
    end
    return nearestItem
end

-- =========================================================================
-- 🔥 HÀM DÒ ĐƯỜNG DI CHUYỂN THÔNG MINH (CHỐNG XUYÊN TƯỜNG, TỰ XOAY XỞ KHI KẸT)
-- =========================================================================
local function walkPathToItem(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    -- Tính toán đường đi an toàn vòng qua các bức tường, không dùng Tween xuyên thấu
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            -- Luôn duy trì tốc độ chạy là 30
            if humanoid.WalkSpeed ~= RUN_SPEED then
                humanoid.WalkSpeed = RUN_SPEED
            end
            
            -- Tự động nhảy nếu điểm nút yêu cầu hành động Nhảy
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            -- Ra lệnh cho Humanoid tự đi bộ đến điểm nút một cách vật lý
            humanoid:MoveTo(waypoint.Position)
            
            local movedToFinished = false
            local startPos = rootPart.Position
            local startTime = os.clock()
            
            -- Lắng nghe sự kiện đi tới điểm nút thành công
            local connection
            connection = humanoid.MoveToFinished:Connect(function()
                movedToFinished = true
                connection:Disconnect()
            end)
            
            -- Vòng lặp bọc lót chống kẹt khi đi qua cửa hoặc góc tường khuất
            while not movedToFinished do
                -- Kiểm tra mỗi 0.35 giây xem nhân vật có dậm chân tại chỗ không
                if (os.clock() - startTime) > 0.35 then
                    -- Nếu chạy tốc độ 30 mà di chuyển chưa đầy 2 stud chứng tỏ bị kẹt góc tường
                    if (rootPart.Position - startPos).Magnitude < 2 then
                        print("[⚠️ STAGE 1] Phát hiện đi bộ bị vướng tường/cửa! Tự động nhảy bọc lót...")
                        
                        humanoid.Jump = true -- Ép nhân vật nhảy lên
                        
                        -- Nhếch nhẹ CFrame hướng về điểm nút tiếp theo để thoát kẹt
                        local lookDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.2, lookDirection.Z * 1.5)
                        
                        -- Ra lệnh di chuyển lại
                        humanoid:MoveTo(waypoint.Position)
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
        -- Dự phòng nếu điểm lấy đồ nằm ở vị trí quá kín quái, dịch chuyển nhẹ để tìm lại đường
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y + 1.5, nhichPos.Z)
        task.wait(0.3)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1
-- =========================================================================
print("[STAGE 1] Bắt đầu luồng dò đường tìm và gom vật phẩm (Tốc độ: 30)...")
local stage1Finished = false

while not stage1Finished do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        -- Ép tốc độ chạy 30
        if humanoid.WalkSpeed ~= RUN_SPEED then
            humanoid.WalkSpeed = RUN_SPEED
        end
        
        -- Dò tìm vật phẩm gần nhất
        local targetItem = getTargetItem(root.Position)
        
        if targetItem then
            local distance = (root.Position - targetItem.Position).Magnitude
            
            -- Nếu ở xa món đồ (> 3.5 stud), tiến hành dò đường đi bộ đến sát cạnh
            if distance > 3.5 then
                walkPathToItem(root, humanoid, targetItem)
            else
                print("[🎯 STAGE 1 SUCCESS] Đã tiếp cận sát vật phẩm an toàn bằng đường đi bộ!")
                
                -- Thực hiện hành động nhặt đồ ở đây (Ví dụ: kích hoạt ProximityPrompt hoặc chạm)
                local prompt = targetItem:FindFirstChildOfClass("ProximityPrompt") or targetItem.Parent:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                end
                
                stage1Finished = true -- Đánh dấu hoàn thành Stage 1
            end
        else
            -- Nếu không tìm thấy đồ trên map nữa, coi như hoàn thành Stage 1 để chuyển màn
            print("[🏁 STAGE 1] Không tìm thấy thêm đồ vật nào cần gom.")
            stage1Finished = true
        end
    end
    task.wait(0.2)
end

task.wait(1)

-- 🔥 CHUYỂN GIAO: Kích hoạt luồng chạy sang Stage 2
print("[🚀] Stage 1 kết thúc sạch sẽ. Chuyển giao luồng sang Stage 2...");
_G.CurrentStage = 2
return true
