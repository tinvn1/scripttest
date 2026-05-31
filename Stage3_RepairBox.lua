-- =========================================================================
-- [CƠ CHẾ MỚI] STAGE 3: BÒ XUYÊN TƯỜNG (CAO 3.5M) & TỰ ĐỘNG SỬA POWER BOX
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

-- --- THUẬT TOÁN BÒ XUYÊN TƯỜNG KHÓA CAO 3.5M ---
local function adaptiveCrawlTo(targetPos, hrp, char)
    -- [NÂNG CAO] Khóa độ cao đích đến cao hơn gốc 3.5m tránh lọt sàn
    local finalTarget = targetPos + Vector3.new(0, 3.5, 0) 
    local FAST_SPEED, SLOW_SPEED, STEP_DISTANCE = 35, 10, 0.25
    local CLEARANCE_COOLDOWN, lastWallDetectedTime = 0.5, 0
    local lockedYHeight = hrp.Position.Y
 
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
            hrp.AssemblyLinearVelocity = Vector3.new(0, -5, 0) 
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
        local flattenedPosition = Vector3.new((currentPos + (direction * activeStepDistance)).X, lockedYHeight, (currentPos + (direction * activeStepDistance)).Z)
 
        hrp.CFrame = CFrame.new(flattenedPosition)
        task.wait(delayInterval)
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
print("[STAGE 3] Đang tiến tới Trạm điện (Power Box)...");
local reached = false

while not reached do
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local powerBoxModel = targetBox.Parent
            adaptiveCrawlTo(targetBox.Position, root, character)
            
            -- 🔥 TỰ ĐỘNG TÁC ĐỘNG MÁY (SỬA CHỮA)
            local prompt = targetBox:FindFirstChildOfClass("ProximityPrompt") or powerBoxModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then 
                fireproximityprompt(prompt)
                print("[🎯 STAGE 3 SUCCESS] Đã sửa chữa điện thành công!")
                task.wait(2)
            end
            reached = true
        else
            task.wait(0.5)
        end
    else
        task.wait(0.3)
    end
    task.wait(0.01)
end

task.wait(0.05)
_G.CurrentStage = 4
return true
