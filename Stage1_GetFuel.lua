-- =========================================================================
-- CHỈ DI CHUYỂN ĐẾN CỤC NHIÊN LIỆU (FUEL) GẦN NHẤT
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local DroppedItemsFolder = Workspace:WaitForChild("DroppedItems")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- 1. HÀM DI CHUYỂN XUYÊN TƯỜNG (ADAPTIVE CRAWL)
local function adaptiveCrawlTo(targetPos, humanoidRootPart, character)
    local finalTarget = targetPos + Vector3.new(0, 3, 0)
 
    local FAST_SPEED = 35     
    local SLOW_SPEED = 10     
    local STEP_DISTANCE = 0.25 
 
    local CLEARANCE_COOLDOWN = 0.5 
    local lastWallDetectedTime = 0
 
    local lockedYHeight = humanoidRootPart.Position.Y
 
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character} 
 
    while true do
        if not humanoidRootPart or not humanoidRootPart.Parent then break end
        local currentPos = humanoidRootPart.Position
        local flatTarget = Vector3.new(finalTarget.X, lockedYHeight, finalTarget.Z)
        local remainingVector = flatTarget - currentPos
        local totalDistance = remainingVector.Magnitude
 
        if totalDistance <= 2 or totalDistance <= STEP_DISTANCE then
            humanoidRootPart.CFrame = CFrame.new(finalTarget)
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, -5, 0) 
            humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
 
            humanoidRootPart.Anchored = true
            task.wait(0.05)
            humanoidRootPart.Anchored = false 
            break
        end
 
        local direction = remainingVector.Unit
        local lookAheadDistance = 5
        local rayResult = Workspace:Raycast(currentPos, direction * lookAheadDistance, raycastParams)
 
        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
            lastWallDetectedTime = os.clock()
        end
 
        local activeStepDistance = 0.25 
        local currentAllowedSpeed = SLOW_SPEED
        if os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN then
            activeStepDistance = 1.4  
            currentAllowedSpeed = FAST_SPEED
        end
 
        local delayInterval = activeStepDistance / currentAllowedSpeed
        local nextPosition = currentPos + (direction * activeStepDistance)
        local flattenedPosition = Vector3.new(nextPosition.X, lockedYHeight, nextPosition.Z)
 
        humanoidRootPart.CFrame = CFrame.new(flattenedPosition)
        task.wait(delayInterval)
    end
end

-- 2. HÀM QUÉT VÀ LỌC CỤC FUEL GẦN NHẤT
local excludeFuel = {}
local function getClosestFuelPosition(currentPos)
    local foundValidFuel = nil
    
    while not foundValidFuel do
        local bestTarget = nil
        local shortestDistance = math.huge
        
        if DroppedItemsFolder then
            for _, item in ipairs(DroppedItemsFolder:GetChildren()) do
                if item.Name == "Fuel" then
                    if not excludeFuel[item] then
                        local fuelPos = item:GetPivot().Position
                        local dist = (currentPos - fuelPos).Magnitude
                        
                        if dist < shortestDistance then
                            shortestDistance = dist
                            bestTarget = item
                        end
                    end
                end
            end
        end
        
        if not bestTarget then
            break
        end
        
        -- Kiểm tra độ cao để tránh kẹt ở những cục Fuel nằm trên vật thể quá cao
        local targetPosition = bestTarget:GetPivot().Position
        local heightDifference = targetPosition.Y - currentPos.Y
        
        if heightDifference <= 2 then
            foundValidFuel = bestTarget
        else
            print("[-] Phát hiện Fuel bất thường ở độ cao: " .. tostring(targetPosition.Y) .. ". Bỏ qua cục này.")
            excludeFuel[bestTarget] = true
        end
    end
    
    return foundValidFuel
end

-- 3. THỰC THI DI CHUYỂN TỚI FUEL
print("[Step 1] Đang tìm kiếm cục Fuel gần nhất...")
local targetFuel = getClosestFuelPosition(humanoidRootPart.Position)

if targetFuel then
    print("[Step 1] Đang di chuyển tới Fuel.")
    -- Thực hiện bò/bay xuyên tường đến cục Fuel
    adaptiveCrawlTo(targetFuel:GetPivot().Position, humanoidRootPart, character)
    print("[Complete] Đã đến vị trí cục Fuel!")
else
    warn("[Warning] Không tìm thấy cục Fuel nào hợp lệ trên map.")
end
