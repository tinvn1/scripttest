-- =========================================================================
-- [CƠ CHẾ MỚI] STAGE 1: BÒ XUYÊN TƯỜNG (CAO 3.5M) & TỰ ĐỘNG NHẶT FUEL
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local DroppedItemsFolder = Workspace:WaitForChild("DroppedItems")
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local PermanentNoclipEnabled = true
local ignoredFuels = {}

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

-- --- HÀM QUÉT FUEL CHUẨN ---
local function getNearestFuel(rootPosition)
    local nearestFuel, minDistance = nil, math.huge
    if DroppedItemsFolder then
        for _, obj in pairs(DroppedItemsFolder:GetChildren()) do
            if obj.Name == "Fuel" and not ignoredFuels[obj] then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part and (part.Position - rootPosition).Magnitude < minDistance then
                    minDistance = (part.Position - rootPosition).Magnitude
                    nearestFuel = part
                end
            end
        end
    end
    return nearestFuel
end

-- --- MAIN CHẠY STAGE 1 ---
print("[STAGE 1] Đang thực hiện chu trình lấy Fuel...");
local cycle = 1

while cycle <= 2 do
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelModel = targetFuel.Parent
        adaptiveCrawlTo(targetFuel.Position, root, character)
        
        
        ignoredFuels[fuelModel] = true
        cycle = cycle + 1
        task.wait(0.5)
    else
        task.wait(0.5)
    end
end

_G.CurrentStage = 2
return true
