-- =========================================================================
-- [ANTI-LAG FIXED] STAGE 2: BÒ XUYÊN TƯỜNG ĐẾN TÂM GENERATOR
-- (TỐI ƯU HÓA GIẢM TẢI CPU - CHỐNG ĐƠ GAME - CHUYỂN MÀN MƯỢT MÀ)
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local PermanentNoclipEnabled = true

-- --- HỆ THỐNG NOCLIP KHÔNG GÂY LAG ---
local function StartPermanentNoclip()
    local noclipConnection = nil
    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then return end
            local char = localPlayer.Character
            if char then
                for _, child in ipairs(char:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then 
                        child.CanCollide = false 
                    end
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                -- Chỉ triệt tiêu vận tốc khi đang đứng yên để giải phóng băng thông mạng
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
    local finalTarget = targetPos + Vector3.new(0, 3.5, 0) 
    local FAST_SPEED, SLOW_SPEED, STEP_DISTANCE = 35, 10, 0.25
    local CLEARANCE_COOLDOWN, lastWallDetectedTime = 0.5, 0
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
 
        if totalDistance <= 2 or totalDistance <= STEP_DISTANCE then
            hrp.CFrame = CFrame.new(finalTarget)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.Anchored = true; task.wait(0.05); hrp.Anchored = false 
            break 
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
        
        -- 🔥 CHỐNG LAG: Thêm lệnh nghỉ siêu nhỏ để tránh tràn CPU gây đơ game
        task.wait(math.max(delayInterval, 0.01))
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
-- KHỞI CHẠY CHÍNH
-- =========================================================================
print("[STAGE 2] Đang di chuyển mượt mà tới Generator...");
local root = character:FindFirstChild("HumanoidRootPart")

if root then
    local generatorObj = getGeneratorInstance()
    if generatorObj then
        local genPart = generatorObj:IsA("BasePart") and generatorObj or generatorObj.PrimaryPart or generatorObj:FindFirstChildWhichIsA("BasePart")
        if genPart then
            adaptiveCrawlTo(genPart.Position, root, character)
            
            -- [🎯 FIX SUCCESS] Đến nơi ổn định không bị lag giật dữ liệu
            print("[🎯 STAGE 2 SUCCESS] Đã đến máy phát điện an toàn!")
            task.wait(0.2) -- Giãn cách thời gian nghỉ mượt mà trước khi chuyển màn
            
            _G.CurrentStage = 3 
            return true
        end
    end
end

_G.CurrentStage = 1
return false
