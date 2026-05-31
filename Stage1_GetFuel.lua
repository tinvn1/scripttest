-- =========================================================================
-- ⚙️ BẢNG CẤU HÌNH HỆ THỐNG (CONFIG) - CHỈNH SỬA TẠI ĐÂY
-- =========================================================================
local CONFIG = {
    -- [DANH SÁCH ĐEN CÁC KHU VỰC ĐỔ NÁT NÊN NÉ]
    RUINS_NAMES = {"Broken1", "Broken2", "Assets"}, -- Tên các Model đổ nát từ hình ảnh của bạn
    MIN_DISTANCE_FROM_RUINS = 8, -- Khoảng cách an toàn tối thiểu (studs) từ Fuel đến đống đổ nát

    -- [CƠ CHẾ TỰ ĐỔI HƯỚNG QUÁ GIỜ]
    MAX_TARGET_TIME = 10,      -- TỰ ĐỔI HƯỚNG: Sau 10 giây không nhặt được bình này thì bỏ qua ngay!

    -- [DI CHUYỂN & TWEEN]
    TWEEN_SPEED = 28,          -- Tốc độ di chuyển
    
    -- [PATHFINDING - NÉ VẬT CẢN]
    AGENT_RADIUS = 5.5,        -- Bán kính né vật cản (Tránh va quệt cạnh tường)
    AGENT_HEIGHT = 5.0,        -- Chiều cao giả lập của nhân vật
    AGENT_CAN_JUMP = true,     -- Cho phép nhảy khi tính toán đường đi
    
    -- [QUÉT RAYCAST CHỐNG ĐÂM TƯỜNG]
    RAY_CHECK_DISTANCE = 2.8,  -- Khoảng cách quét tường phía trước (studs)
    RAY_ANGLE = 25,            -- Góc mở rộng của 2 tia quét chéo trái/phải (độ)
    LEG_HEIGHT_LIMIT = 1.8,    -- Chiều cao nửa chân: Thấp hơn mức này sẽ cho phép đi lên
    
    -- [KHOẢNG CÁCH DỪNG NHẶT ĐỒ]
    STOP_DISTANCE = 3.3,       -- Khoảng cách đứng cách Fuel để dừng lại nhặt (studs)
    FINAL_REACH_DIST = 4.0,    -- Khoảng cách tối đa chấp nhận để tính là hoàn thành đường đi
    
    -- [VÒNG LẶP CHÍNH]
    TOTAL_CYCLES = 2,          -- Số lượng bình xăng cần thu thập
    MAX_STUCK_ATTEMPTS = 3,    -- Số lần kẹt tối đa tại 1 bình trước khi quyết định bỏ qua
}

-- =========================================================================
-- KHỞI TẠO DỊCH VỤ ROBLOX
-- =========================================================================
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local path = PathfindingService:CreatePath({
    AgentRadius = CONFIG.AGENT_RADIUS,    
    AgentHeight = CONFIG.AGENT_HEIGHT, 
    AgentCanJump = CONFIG.AGENT_CAN_JUMP
})
local ignoredFuels = {}

-- =========================================================================
-- 🛠️ HÀM KIỂM TRA FUEL CÓ NẰM TRONG KHU VỰC NGUY HIỂM / ĐỔ NÁT KHÔNG
-- =========================================================================
local function isInsideOrNearRuins(fuelPart)
    -- 1. Kiểm tra xem Fuel có phải là con cháu của đống đổ nát không
    for _, ruinName in ipairs(CONFIG.RUINS_NAMES) do
        if fuelPart:FindFirstAncestor(ruinName) then
            return true -- Nằm ngay trong mục lục của đống đổ nát -> BỎ QUA!
        end
    end
    
    -- 2. Kiểm tra khoảng cách vật lý xung quanh xem có đống đổ nát nào không
    for _, obj in pairs(Workspace:GetDescendants()) do
        for _, ruinName in ipairs(CONFIG.RUINS_NAMES) do
            if obj.Name == ruinName and (obj:IsA("Model") or obj:IsA("Folder")) then
                -- Tìm một Part trung tâm để tính khoảng cách
                local pivotPart = obj:IsA("Model") and obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if pivotPart then
                    local distToRuin = (fuelPart.Position - pivotPart.Position).Magnitude
                    if distToRuin <= CONFIG.MIN_DISTANCE_FROM_RUINS then
                        return true -- Quá gần khu vực gồ ghề nguy hiểm -> BỎ QUA!
                    end
                end
            end
        end
    end
    
    return false
end

-- Hàm định vị Fuel gần nhất (Đã tích hợp bộ lọc né đổ nát)
local function getNearestFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" and obj:IsA("Model") and not ignoredFuels[obj] then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                -- KIỂM TRA BỘ LỌC ĐỔ NÁT
                if not isInsideOrNearRuins(part) then
                    local dist = (rootPosition - part.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        nearestFuel = part
                    end
                else
                    -- Nếu phát hiện thuộc khu vực đổ nát, đưa vào danh sách đen luôn để đỡ quét lại
                    ignoredFuels[obj] = true
                    print("[-] Đã phát hiện và chủ động né một Fuel nằm trong vùng đổ nát gồ ghề!")
                end
            end
        end
    end
    return nearestFuel
end

-- =========================================================================
-- 🕵️ MẮT THẦN RAYCAST 3 TIA - LỌC VẬT CẢN THẤP HƠN NỬA CHÂN
-- =========================================================================
local function isWallInFront(rootPart, targetPosition, checkDistance)
    local origin = rootPart.Position + Vector3.new(0, CONFIG.LEG_HEIGHT_LIMIT - 2, 0)
    local mainDirection = (targetPosition - rootPart.Position).Unit
    
    local directions = {
        mainDirection,
        (CFrame.Angles(0, math.rad(CONFIG.RAY_ANGLE), 0) * mainDirection),
        (CFrame.Angles(0, math.rad(-CONFIG.RAY_ANGLE), 0) * mainDirection)
    }
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {rootPart.Parent}
    
    for _, dir in ipairs(directions) do
        local raycastResult = Workspace:Raycast(origin, dir * checkDistance, raycastParams)
        if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
            if raycastResult.Instance.Name ~= "Fuel" and raycastResult.Instance.Parent.Name ~= "Fuel" then
                local hitHeight = raycastResult.Position.Y - (rootPart.Position.Y - 2.5)
                if hitHeight > CONFIG.LEG_HEIGHT_LIMIT then
                    return true
                end
            end
        end
    end
    return false
end

-- =========================================================================
-- 🔥 HÀM DI CHUYỂN THÔNG MINH - TÍCH HỢP ĐẾM GIỜ KHẨN CẤP
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart, startTime)
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
            
            -- KIỂM TRA TIMEOUT TOÀN CỤC (10 GIÂY)
            if (os.clock() - startTime) >= CONFIG.MAX_TARGET_TIME then
                print("[⏳ TIMEOUT] Đã quá thời gian quy định cho bình này, đổi hướng ngay!")
                return false
            end
            
            -- ĐIỀU KIỆN 1: Kiểm tra khoảng cách dừng liên tục
            local distanceToFuel = (rootPart.Position - targetPart.Position).Magnitude
            if distanceToFuel <= CONFIG.STOP_DISTANCE then
                return true 
            end
            
            local waypoint = waypoints[i]
            local targetPos = Vector3.new(waypoint.Position.X, waypoint.Position.Y + 1.2, waypoint.Position.Z)
            local distance = (rootPart.Position - targetPos).Magnitude
            
            local expectedCFrame = CFrame.new(targetPos, Vector3.new(waypoint.Position.X, rootPart.Position.Y, waypoint.Position.Z))
            
            local tween = TweenService:Create(rootPart, TweenInfo.new(distance / CONFIG.TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
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
                if (os.clock() - startTime) >= CONFIG.MAX_TARGET_TIME then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    return false
                end

                local liveDist = (rootPart.Position - targetPart.Position).Magnitude
                if liveDist <= CONFIG.STOP_DISTANCE then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    return true
                end
                
                -- ĐIỀU KIỆN 2: Phát hiện tường chắn góc cua bằng Raycast giảm nhạy cảm
                if isWallInFront(rootPart, waypoint.Position, CONFIG.RAY_CHECK_DISTANCE) then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    
                    local escapeDirection = -rootPart.CFrame.LookVector
                    rootPart.CFrame = rootPart.CFrame + (escapeDirection * 1.8) + Vector3.new(0, 1.2, 0)
                    
                    needRecalculate = true
                    break
                end
                
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                if i < totalWaypoints and currentDist < 3.0 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    break
                end
                
                -- ĐIỀU KIỆN 3: Check kẹt cơ học
                if (os.clock() - checkTimer) > 0.15 then
                    if (rootPart.Position - lastPosition).Magnitude < 0.4 then 
                        tween:Cancel()
                        if connection then connection:Disconnect() end
                        rootPart.CFrame = rootPart.CFrame * CFrame.new(math.random(-1,1) * 2, 2.0, 1.5)
                        needRecalculate = true
                        break
                    end
                    checkTimer = os.clock()
                    lastPosition = rootPart.Position
                end
                
                if (os.clock() - loopTimeout) > 2.5 then
                    tween:Cancel()
                    if connection then connection:Disconnect() end
                    needRecalculate = true
                    break 
                end
                
                RunService.Heartbeat:Wait()
            end
            
            -- Xử lý rẽ hướng và tính toán lại lộ trình mới thông minh hơn
            if needRecalculate then
                task.wait(0.15) 
                local reSuccess = pcall(function()
                    path:ComputeAsync(rootPart.Position, targetPart.Position)
                end)
                if reSuccess and path.Status == Enum.PathStatus.Success then
                    waypoints = path:GetWaypoints()
                    totalWaypoints = #waypoints
                    i = 1 
                else
                    rootPart.CFrame = rootPart.CFrame * CFrame.new(math.random(-3, 3), 1.5, math.random(2, 4))
                    return false
                end
            else
                i = i + 1
            end
        end
        
        return (rootPart.Position - targetPart.Position).Magnitude <= CONFIG.FINAL_REACH_DIST
    else
        rootPart.CFrame = rootPart.CFrame * CFrame.new(math.random(-2, 2), 1.5, math.random(-2, 2))
        task.wait(0.15)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH
-- =========================================================================
print("[STAGE 1] Hệ thống đang chạy - Tự động định vị và né hoàn toàn khu vực đổ nát...")
local cycle = 1
local stuckCounter = 0

while cycle <= CONFIG.TOTAL_CYCLES do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelModel = targetFuel.Parent
        local startTime = os.clock()
        
        local success = walkPathToTarget(root, targetFuel, startTime)
        
        if success then
            local actualDist = (root.Position - targetFuel.Position).Magnitude
            print(string.format("[🎉] Thành công! Đã tiếp cận Fuel an toàn. Tiến hành nhặt %d/%d...", cycle, CONFIG.TOTAL_CYCLES))
            
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or fuelModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            
            ignoredFuels[fuelModel] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.5)
        else
            stuckCounter = stuckCounter + 1
            local timeElapsed = os.clock() - startTime
            if timeElapsed >= CONFIG.MAX_TARGET_TIME or stuckCounter >= CONFIG.MAX_STUCK_ATTEMPTS then
                print("[⚠️] TỰ ĐỔI HƯỚNG: Bỏ qua bình xăng kẹt/khó lấy này, bẻ lái tìm mục tiêu khác thoáng hơn!")
                ignoredFuels[fuelModel] = true
                stuckCounter = 0
            end
            task.wait(0.1)
        end
    else
        print("[-] Đang quét tìm kiếm vị trí các bình xăng ở khu vực an toàn...")
        ignoredFuels = {}
        task.wait(0.5)
    end
end

print("[STAGE 1] HOÀN THÀNH XUẤT SẮC - CHUYỂN SANG STAGE 2!")
_G.CurrentStage = 2
return true
