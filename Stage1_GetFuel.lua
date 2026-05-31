-- =========================================================================
-- [NEW MECHANICAL] STAGE 1: TÌM VÀ BÒ XUYÊN TƯỜNG LẤY 2 BÌNH FUEL
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

-- --- BACKGROUND SERVICE: PERMANENT NOCLIP ENGINE (MỚI) ---
local function StartPermanentNoclip()
    local noclipConnection = nil
    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then
                if noclipConnection then noclipConnection:Disconnect() end
                return
            end
            local char = localPlayer.Character
            if char then
                for _, child in ipairs(char:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        child.CanCollide = false
                    end
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

-- --- THUẬT TOÁN DI CHUYỂN XUYÊN TƯỜNG (ADAPTIVE CRAWL) ---
local function adaptiveCrawlTo(targetPos, hrp, char)
    local finalTarget = targetPos + Vector3.new(0, 3, 0)
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
        local nextPosition = currentPos + (direction * activeStepDistance)
        local flattenedPosition = Vector3.new(nextPosition.X, lockedYHeight, nextPosition.Z)
 
        hrp.CFrame = CFrame.new(flattenedPosition)
        task.wait(delayInterval)
    end
end

-- --- HÀM ĐỊNH VỊ FUEL CHÍNH XÁC ---
local function getNearestFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    
    if DroppedItemsFolder then
        for _, obj in pairs(DroppedItemsFolder:GetChildren()) do
            if obj.Name == "Fuel" and not ignoredFuels[obj] then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (rootPosition - part.Position).Magnitude
                    if dist < minDistance then
                        -- Kiểm tra loại bỏ Fuel lỗi độ cao quá lớn so với người
                        if math.abs(part.Position.Y - rootPosition.Y) <= 15 then
                            minDistance = dist
                            nearestFuel = part
                        end
                    end
                end
            end
        end
    end
    return nearestFuel
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH STAGE 1
-- =========================================================================
print("[STAGE 1] Khởi chạy cơ chế bò xuyên tường thu thập 2 bình Fuel...");
local cycle = 1

while cycle <= 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelModel = targetFuel.Parent
        print(string.format("[STAGE 1] Đang di chuyển thẳng tới Fuel (%d/2)...", cycle))
        
        -- Thực thi bò xuyên tường đến đích
        adaptiveCrawlTo(targetFuel.Position, root, char)
        
        -- Nhặt đồ bằng ProximityPrompt
        local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or fuelModel:FindFirstChildOfClass("ProximityPrompt")
        if prompt then 
            fireproximityprompt(prompt)
            print(string.format("[🎉] Đã nhặt xong Fuel %d/2 thành công!", cycle))
        end
        
        ignoredFuels[fuelModel] = true
        cycle = cycle + 1
        task.wait(0.5)
    else
        print("[-] Đang quét tìm kiếm lại tài nguyên Fuel trên mặt đất...")
        ignoredFuels = {}
        task.wait(0.5)
    end
end

print("[STAGE 1] HOÀN THÀNH - CHUYỂN SANG STAGE 2!")
_G.CurrentStage = 2
return true
