local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Cấu hình Path tối ưu chống cọ tường vật lý
local path = PathfindingService:CreatePath({
    AgentRadius = 1.8, 
    AgentHeight = 5.0,
    AgentCanJump = true,
    Costs = { Water = math.huge }
})

-- =========================================================================
-- 🔥 TÍNH NĂNG INF JUMP AN TOÀN (CHỐNG ANTI-CHEAT BAY)
-- =========================================================================
local function triggerSafeInfJump(humanoid)
    if humanoid and humanoid.Health > 0 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- Tự động kích hoạt khi bấm nút Space thủ công
if _G.InfJumpHooked then _G.InfJumpHooked:Disconnect() end
_G.InfJumpHooked = UserInputService.JumpRequest:Connect(function()
    local char = localPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- =========================================================================
-- HÀM ĐỊNH VỊ TRẠM ĐIỆN TỐI ƯU
-- =========================================================================
local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    local descendants = Workspace:GetDescendants()
    
    for i = 1, #descendants do
        local obj = descendants[i]
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
-- 🔥 HÀM DI CHUYỂN CẢI TIẾN - THOÁT KẸT LÀ TÍNH LẠI ĐƯỜNG MỚI NGAY
-- =========================================================================
local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        local startIndex = 1
        if totalWaypoints > 2 and (rootPart.Position - waypoints[2].Position).Magnitude < 4 then
            startIndex = 2
        end
        
        for i = startIndex, totalWaypoints do
            local waypoint = waypoints[i]
            if not rootPart.Parent or not targetPart.Parent then return false end
            
            humanoid.WalkSpeed = RUN_SPEED
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                triggerSafeInfJump(humanoid)
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local isStuck = false
            
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                if i == totalWaypoints then
                    if currentDist < 3.0 then break end
                else
                    if currentDist < 4.5 then break end 
                end
                
                -- CẢM BIẾN PHÁ RÀO / GỠ KẸT SIÊU TỐC (0.15 Giây)
                if (os.clock() - startTime) > 0.15 then
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    -- Nếu dậm chân tại chỗ quá 0.15s (bị cấn góc rào/tường)
                    if movedDistance < 1.2 then
                        local pushDirection = (waypoint.Position - rootPart.Position).Unit
                        
                        -- Kích hoạt chuỗi nhảy phá kẹt dứt khoát
                        task.spawn(function()
                            for _ = 1, 3 do
                                triggerSafeInfJump(humanoid)
                                task.wait(0.06)
                            end
                        end)
                        
                        -- Tăng nhẹ lực đẩy lên Y = 32 và kéo dài thời gian chờ thoát kẹt lên 0.15 giây
                        rootPart.AssemblyLinearVelocity = (pushDirection * (RUN_SPEED * 1.3)) + Vector3.new(0, 32, 0)
                        
                        -- Đi chệch hướng ngẫu nhiên để lách góc cấn
                        humanoid:MoveTo(waypoint.Position + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)))
                        task.wait(0.15) -- Chờ đủ thời gian để lực vật lý đẩy nhân vật ra khỏi góc kẹt
                        
                        isStuck = true 
                        break -- Thoát khỏi vòng lặp kiểm tra khoảng cách waypoint
                    end
                    
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                task.wait()
            end
            
            -- ĐIỂM SỬA LỖI MẤT CHỐT: Nếu kẹt, trả về false ngay lập tức để ép vòng lặp chính tính toán lại từ đầu
            if isStuck then 
                return false 
            end
        end
        return true
    else
        -- Phục hồi khẩn cấp khi lỗi Path
        triggerSafeInfJump(humanoid)
        rootPart.AssemblyLinearVelocity = (-rootPart.CFrame.LookVector * 15) + Vector3.new(0, 20, 0)
        task.wait(0.15)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Khởi chạy luồng di chuyển thông minh - Tự động tái định vị khi kẹt...");
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid and humanoid.Health > 0 then
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            if distance > 4.5 then
                -- Gọi hàm di chuyển, nếu hàm trả về false (do bị kẹt), vòng lặp while sẽ tự quét lại tọa độ và tính Path mới ở lượt sau
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã cập bến trạm điện dứt khoát!");
                reached = true
            end
        else
            task.wait(0.1)
        end
    else
        task.wait(0.3)
    end
    task.wait(0.02)
end

task.wait(0.05)
_G.CurrentStage = 4
return true
