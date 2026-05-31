-- =========================================================================
-- [ANTI-LAG FIXED] STAGE 3: BÒ XUYÊN TƯỜNG ĐẾN TRẠM ĐIỆN (POWER BOX)
-- (SỬA LỖI TRÀN CPU - ĐỒNG BỘ CAO ĐỘ TRÁNH KẸT VÒNG LẶP - MƯỢT MÀ KHÔNG LAG)
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local PermanentNoclipEnabled = true

-- --- HỆ THỐNG NOCLIP AN TOÀN CHỐNG NGHẼN MẠNG ---
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
                -- Chỉ khóa vận tốc khi di chuyển quá nhanh tránh anti-cheat hoặc lag băng thông
                if hrp and hrp.Anchored == false and hrp.AssemblyLinearVelocity.Magnitude > 50 then 
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
                end
            end
        end)
    end
    ConnectNoclip()
    localPlayer.CharacterAdded:Connect(function() task.wait(0.2) ConnectNoclip() end)
end
StartPermanentNoclip()

-- --- THUẬT TOÁN DI CHUYỂN MƯỢT MÀ CHỐNG OVERLOAD ---
local function adaptiveCrawlTo(targetPos, hrp, char)
    -- Khóa độ cao đích đến cao hơn gốc 3.5 block theo yêu cầu
    local finalTarget = targetPos + Vector3.new(0, 3.5, 0) 
    local FAST_SPEED, SLOW_SPEED, STEP_DISTANCE = 35, 10, 0.25
    local CLEARANCE_COOLDOWN, lastWallDetectedTime = 0.5, 0
    
    -- [FIX LOGIC] Đồng bộ chiều cao người với chiều cao đích ngay từ đầu để vòng lặp kết thúc chính xác
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
 
        -- Kiểm tra chạm đích để giải phóng vòng lặp chính xác
        if totalDistance <= 2 or totalDistance <= STEP_DISTANCE then
            hrp.CFrame = CFrame.new(finalTarget)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.Anchored = true; task.wait(0.05); hrp.Anchored = false 
            break -- Thoát vòng lặp thành công
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
        
        -- 🔥 CHỐNG LAG: Ép luồng CPU nghỉ tối thiểu 0.01s để game chạy mượt, không đơ màn hình
        task.wait(math.max(delayInterval, 0.01))
    end
end

-- --- HÀM QUÉT TRẠM ĐIỆN (POWER BOX) ---
local function getNearestPowerBox(rootPosition)
    if MapFolder and MapFolder:FindFirstChild("Tiles") then
        for _, child in ipairs(MapFolder.Tiles:GetChildren()) do
            if child.Name == "Power Plant" then
                local powerBox = child:FindFirstChild("Power Box")
                if powerBox then
                    return powerBox:IsA("BasePart") and powerBox or powerBox.PrimaryPart or powerBox:FindFirstChildWhichIsA("BasePart")
                end
            end
        end
    end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" then 
            return obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

-- --- MAIN CHẠY STAGE 3 ---
print("[STAGE 3] Khởi chạy tiến trình sửa điện chống Lag...");
local reached = false

while not reached do
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local powerBoxModel = targetBox.Parent
            adaptiveCrawlTo(targetBox.Position, root, character)
            
            -- 🔥 TỰ ĐỘNG TÁC ĐỘNG MÁY (SỬA CHỮA) - Đã đến nơi mượt mà
            print("[🎯] Đã chạm đích Power Box. Tiến hành kích hoạt sửa máy...")
            local prompt = targetBox:FindFirstChildOfClass("ProximityPrompt") or powerBoxModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then 
                fireproximityprompt(prompt)
                print("[🎯 STAGE 3 SUCCESS] Tác động sửa điện thành công!")
                task.wait(1.5) -- Quãng nghỉ ngắn đồng bộ dữ liệu server
            end
            reached = true
        else
            task.wait(0.5)
        end
    else
        task.wait(0.3)
    end
    -- Giảm tần suất vòng lặp ngoài xuống 0.05s để tránh lag rác luồng
    task.wait(0.05)
end

task.wait(0.1)
_G.CurrentStage = 4
return true
