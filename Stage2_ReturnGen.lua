-- =========================================================================
-- [FIXED] STAGE 2: BÒ XUYÊN TƯỜNG (CAO 3.5M) ĐẾN THẲNG TÂM GENERATOR
-- (SỬA LỖI KẸT CAO ĐỘ VÒNG LẶP - ĐẢM BẢO CHUYỂN QUA STAGE 3 THÀNH CÔNG)
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local PermanentNoclipEnabled = true

-- --- HỆ THỐNG NOCLIP ĐI XUYÊN VẬT CẢN ---
local function StartPermanentNoclip()
    local noclipConnection = nil
    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then return end
            local char = localPlayer.Character
            if char then
                for _, child in ipairs(char:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then child.CanCollide = false end
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
            end
        end)
    end
    ConnectNoclip()
    localPlayer.CharacterAdded:Connect(function() task.wait(0.1) ConnectNoclip() end)
end
StartPermanentNoclip()

-- --- THUẬT TOÁN BÒ XUYÊN TƯỜNG KHÓA CAO 3.5M (ĐÃ FIX) ---
local function adaptiveCrawlTo(targetPos, hrp, char)
    -- Khóa độ cao đích đến cao hơn gốc máy phát điện 3.5m chống lọt sàn
    local finalTarget = targetPos + Vector3.new(0, 3.5, 0) 
    local FAST_SPEED, SLOW_SPEED, STEP_DISTANCE = 35, 10, 0.25
    local CLEARANCE_COOLDOWN, lastWallDetectedTime = 0.5, 0
    
    -- FIX: Đồng bộ chiều cao người với chiều cao đích nâng lên ngay từ đầu để không bị lệch Y
    local lockedYHeight = finalTarget.Y 
 
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char} 
 
    while true do
        if not hrp or not hrp.Parent then break end
        local currentPos = hrp.Position
        local flatTarget = Vector3.new(finalTarget.X, lockedYHeight, finalTarget.Z)
        local remainingVector = flatTarget - currentPos
        local totalDistance = remainingVector.Magnitude
 
        -- Nếu khoảng cách tới tâm máy nhỏ hơn 2 block -> Ép tọa độ đích để ngắt vòng lặp chính xác
        if totalDistance <= 2 or totalDistance <= STEP_DISTANCE then
            hrp.CFrame = CFrame.new(finalTarget)
            hrp.AssemblyLinearVelocity = Vector3.new(0, -5, 0) 
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.Anchored = true; task.wait(0.05); hrp.Anchored = false 
            break -- Thoát vòng lặp để xuống code chuyển Stage bên dưới
        end
 
        local direction = remainingVector.Unit
        local rayResult = Workspace:Raycast(currentPos, direction * 5, raycastParams)
        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
            lastWallDetectedTime = os.clock()
        end
 
        local activeStepDistance = (os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN) and 1.4 or 0.25
        local currentAllowedSpeed = (os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN) and FAST_SPEED or SLOW_SPEED
        local delayInterval = activeStepDistance / currentAllowedSpeed
        local nextPosition = currentPos + (direction * activeStepDistance)
        local flattenedPosition = Vector3.new(nextPosition.X, lockedYHeight, nextPosition.Z)
 
        hrp.CFrame = CFrame.new(flattenedPosition)
        task.wait(delayInterval)
    end
end

-- --- HÀM QUÉT MÁY PHÁT ĐIỆN (GENERATOR) ---
local function getGeneratorInstance()
    if MapFolder and MapFolder:FindFirstChild("Tiles") then
        for _, child in ipairs(MapFolder.Tiles:GetChildren()) do
            if child.Name == "Generator" or child:FindFirstChild("Generator") then
                return child:FindFirstChild("Generator") or child
            end
        end
    end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" or obj.Name == "Gen" then return obj end
    end
    return nil
end

-- =========================================================================
-- LUỒNG THỰC THI CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Thực thi di chuyển xuyên tường nâng cao thẳng tới tâm Generator...");
local root = character:FindFirstChild("HumanoidRootPart")

if root then
    local generatorObj = getGeneratorInstance()
    if generatorObj then
        local genPart = generatorObj:IsA("BasePart") and generatorObj or generatorObj.PrimaryPart or generatorObj:FindFirstChildWhichIsA("BasePart")
        if genPart then
            -- Tiến hành bò thẳng xuyên vật cản đến vùng đích
            adaptiveCrawlTo(genPart.Position, root, character)
            
            -- [FIX SUCCESS] Chạm vùng đích thành công, chạy xuống đây để chuyển Stage!
            print("[🎯 STAGE 2 SUCCESS] Đã đến vị trí Generator an toàn. Ép lệnh nhảy sang STAGE 3!")
            task.wait(0.5)
            
            _G.CurrentStage = 3 -- Chuyển màn chuẩn xác sang Stage 3
            return true
        end
    end
end

-- Nếu lỗi không tìm thấy máy phát, quay về tìm xăng lại để tránh kẹt logic mạng
warn("[⚠️ STAGE 2 FAIL] Không tìm thấy mục tiêu, quay lại Stage 1...")
_G.CurrentStage = 1
return false
