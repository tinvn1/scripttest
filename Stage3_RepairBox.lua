-- =========================================================================
-- [CẢI TIẾN] BỘ VÁ LỖI HỆ THỐNG AN TOÀN TRÁNH CRASH METATABLE
-- =========================================================================
local function patchCharacterModel(char)
    if not char then return end
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if root then
        local mt = getmetatable(char) or {}
        local oldIndex = mt.__index

        mt.__index = function(self, key)
            if key == "Position" then
                return root.Position
            end
            if type(oldIndex) == "function" then
                local success, result = pcall(oldIndex, self, key)
                if success then return result end
            elseif type(oldIndex) == "table" then
                return oldIndex[key]
            end
            return nil
        end
        setmetatable(char, mt)
    end
end

if game:GetService("Players").LocalPlayer.Character then
    task.spawn(patchCharacterModel, game:GetService("Players").LocalPlayer.Character)
end
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(patchCharacterModel, char)
end)
-- =========================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

local localPlayer = Players.LocalPlayer
local TWEEN_SPEED = 30 -- Giữ nguyên tốc độ mặc định 30 theo yêu cầu

local path = PathfindingService:CreatePath({
    AgentRadius = 1.8,     -- Giảm xuống 1.8 để dễ lách qua khe cửa hẹp của Power Plant
    AgentHeight = 5,
    AgentCanJump = true    -- Bật nhảy hợp lệ để vượt qua các chướng ngại vật thấp
})

local ignoredFuels = {}

-- ==========================================
-- AUTO CẦM VŨ KHÍ AN TOÀN
-- ==========================================
local function autoEquipWeapon()
    pcall(function()
        local char = localPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local backpack = localPlayer:FindFirstChild("Backpack")
        
        local weaponName = "Bat" 
        
        if humanoid and backpack and not char:FindFirstChild(weaponName) then
            local weapon = backpack:FindFirstChild(weaponName)
            if weapon and weapon:IsA("Tool") then
                humanoid:EquipTool(weapon)
            end
        end
    end)
end

-- ==========================================
-- CÁC HÀM TÌM KIẾM VẬT THỂ (STAGE 1 & 2)
-- ==========================================
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

local function getGenerator()
    local generator = Workspace:FindFirstChild("Generator", true)
    if generator then
        return generator:FindFirstChild("MainPart") or generator.PrimaryPart or generator:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

-- =========================================================================
-- 🔥 FIXED STAGE 3: HÀM QUÉT POWER BOX NÂNG CAO (CHỐNG CRASH PROXIMITYPROMPT)
-- =========================================================================
local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Tìm kiếm vật thể có tên "Power Box" (Quét sâu trong Power Plant)
        if obj.Name == "Power Box" then
            local targetPart = nil
            
            -- Nếu cấu trúc là Model, bóc tách sâu linh kiện vật lý bên trong
            if obj:IsA("Model") then
                local foundChild = obj.PrimaryPart 
                    or obj:FindFirstChild("PB_HL") 
                    or obj:FindFirstChild("Prompt") 
                    or obj:FindFirstChildWhichIsA("BasePart")
                
                if foundChild then
                    -- BẪY LỖI AN TOÀN: Nếu là nút ấn ProximityPrompt, lấy khối gạch Parent chứa nó
                    if foundChild:IsA("ProximityPrompt") then
                        targetPart = foundChild.Parent
                    elseif foundChild:IsA("BasePart") then
                        targetPart = foundChild
                    end
                end
            elseif obj:IsA("BasePart") then
                targetPart = obj
            end
            
            -- Xác nhận linh kiện hợp lệ có thuộc tính .Position trước khi tính khoảng cách
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
-- HÀM QUÉT TÌM VỊ TRÍ ĐỨNG AN TOÀN KHÔNG VƯỚNG TƯỜNG (RAYCAST GROUND)
-- =========================================================================
local function findSafeBypassPoint(targetPos)
    local char = localPlayer.Character
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char, Workspace:FindFirstChild("Generator", true)}
    
    -- Quét vòng tròn xung quanh vật phẩm bán kính 2.5 studs để tìm điểm thoáng bám đất
    local angles = {0, 45, 90, 135, 180, 225, 270, 315}
    for _, angle in ipairs(angles) do
        local rad = math.rad(angle)
        local offset = Vector3.new(math.cos(rad) * 2.5, 10, math.sin(rad) * 2.5)
        local scanOrigin = targetPos + offset
        
        -- Bắn tia dọc xuống đất
        local raycastResult = Workspace:Raycast(scanOrigin, Vector3.new(0, -20, 0), raycastParams)
        
        if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
            if raycastResult.Position.Y < targetPos.Y + 3 then
                return raycastResult.Position + Vector3.new(0, 2, 0)
            end
        end
    end
    return targetPos + Vector3.new(0, 2, 0)
end

-- =========================================================================
-- HÀM DI CHUYỂN THÔNG MINH TUYỆT ĐỐI KHÔNG XUYÊN TƯỜNG
-- =========================================================================
local function walkPathToTarget(rootPart, targetPart, isEmergency)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local destination = targetPart.Position
    if isEmergency then
        destination = findSafeBypassPoint(targetPart.Position)
    end

    path:ComputeAsync(rootPart.Position, destination)
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            autoEquipWeapon()
            
            local targetPos = waypoint.Position
            local startPos = rootPart.Position
            local distance = (startPos - targetPos).Magnitude
            local duration = distance / TWEEN_SPEED
            
            local expectedCFrame = CFrame.new(targetPos.X, targetPos.Y + 2, targetPos.Z)
            
            local tween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
            
            task.wait(0.01)
            
            -- Kiểm tra nếu bị dội ngược vật lý do húc phải tường cứng
            local actualDistance = (rootPart.Position - expectedCFrame.Position).Magnitude
            if actualDistance > 4.5 then
                return false
            end
        end
        return true 
    else
        -- Thất bại do bị kẹt góc hẹp: Nhích nhẹ tìm góc tính đường mới
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        local tweenNhich = TweenService:Create(rootPart, TweenInfo.new(3 / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y, nhichPos.Z)})
        tweenNhich:Play()
        tweenNhich.Completed:Wait()
        task.wait(0.1)
        return false
    end
end

-- ==========================================
-- TIẾN TRÌNH KHỞI CHẠY CHÍNH THỨC
-- ==========================================
local function startUltimateAutoProcess()
    print("[Ultimate-Auto] Đang chờ nhân vật xuất hiện...")
    local char = localPlayer.Character
    while not char or not char:FindFirstChild("HumanoidRootPart") do 
        task.wait(0.5) 
        char = localPlayer.Character 
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    
    autoEquipWeapon()
    repeat task.wait(1) until getNearestFuel(root.Position) and getGenerator()
    
    print("[Ultimate-Auto] KHỞI CHẠY HỆ THỐNG AN TOÀN TUYỆT ĐỐI - KHÔNG XUYÊN TƯỜNG!")
    task.wait(0.5)
    ignoredFuels = {}

    -- GIAI ĐOẠN 1: THU THẬP ĐỦ 2 BÌNH FUEL
    local cycle = 1
    local fuelStuckCounter = 0
    while cycle <= 2 do
        char = localPlayer.Character
        root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then break end
        
        local targetFuel = getNearestFuel(root.Position)
        if targetFuel then
            local fuelModel = targetFuel.Parent
            local isEmergency = (fuelStuckCounter > 1)
            local success = walkPathToTarget(root, targetFuel, isEmergency)
            
            if success then
                print(string.format("[🎉] Đã nhặt an toàn Fuel %d/2! Đi tiếp thôi...", cycle))
                ignoredFuels[fuelModel] = true
                cycle = cycle + 1
                fuelStuckCounter = 0
                task.wait(0.5)
            else
                fuelStuckCounter = fuelStuckCounter + 1
                if fuelStuckCounter >= 4 then
                    print("[❌] Bình Fuel bị kẹt cứng trong tường, bỏ qua để an toàn!")
                    ignoredFuels[fuelModel] = true
                    fuelStuckCounter = 0
                end
                task.wait(0.1)
            end
        else
            print("[-] Đang quét lại danh sách nhiên liệu...")
            ignoredFuels = {}
            task.wait(1.5)
        end
    end
    
    -- GIAI ĐOẠN 2: CHẠY BỘ VỀ GENERATOR ĐỂ NẠP NHIÊN LIỆU
    print("[⚡ TRẢ ĐỒ] Đang tìm đường di chuyển về trạm Generator...")
    local arrivedGen = false
    local genStuckCounter = 0
    while not arrivedGen do
        char = localPlayer.Character
        root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then break end
        
        local targetGen = getGenerator()
        if targetGen then
            local isEmergency = (genStuckCounter > 1)
            local success = walkPathToTarget(root, targetGen, isEmergency)
            if success then
                print("[🎉] Đã đến Generator thành công! Đang nạp nhiên liệu...")
                arrivedGen = true
                task.wait(1.5) 
            else
                genStuckCounter = genStuckCounter + 1
                task.wait(0.1)
            end
        else
            break
        end
    end
    
    -- GIAI ĐOẠN 3: SỬA TRẠM ĐIỆN POWER BOX (ĐÃ ĐƯỢC FIX AN TOÀN)
    print("[Ultimate-Auto] Chuyển trạng thái sang sửa Power Box...")
    task.wait(1.0)
    
    local reached = false
    local boxStuckCounter = 0
    
    while not reached do
        char = localPlayer.Character
        root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then task.wait(1) continue end
        
        -- Gọi hàm quét sửa lỗi cấu trúc bẫy tên vật thể của map
        local targetPowerBox = getNearestPowerBox(root.Position)
        if not targetPowerBox then 
            print("[⚠️] Đang quét cấu trúc, chờ Power Box xuất hiện...")
            task.wait(1)
            continue 
        end
        
        local distance = (root.Position - targetPowerBox.Position).Magnitude
        
        if distance > 4.5 then
            print(string.format("[🔍] Cách trạm điện: %.1f studs. Đang điều hướng tiến tới mục tiêu...", distance))
            
            local isEmergency = (boxStuckCounter > 1)
            local success = walkPathToTarget(root, targetPowerBox, isEmergency)
            
            if not success then
                boxStuckCounter = boxStuckCounter + 1
                task.wait(0.2)
            else
                boxStuckCounter = 0
            end
            task.wait(0.05) 
        else
            print("[🎉 SUCCESS] Hoàn tất hoàn hảo: Đã đứng sát cạnh Power Box để sửa!")
            reached = true
        end
    end
end

localPlayer.CharacterAdded:Connect(function() 
    task.wait(1) 
    autoEquipWeapon() 
end)

task.spawn(startUltimateAutoProcess)
