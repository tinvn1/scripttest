-- =========================================================================
-- DI CHUYỂN TỚI MÁY PHÁT ĐIỆN (GENERATOR) - THUẬT TOÁN CRAWL GỐC
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local cachedGeneratorLocation = nil

-- 1. HÀM DI CHUYỂN CRAWL GỐC CỦA SCRIPT
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

-- 2. HÀM QUÉT VỊ TRÍ MÁY PHÁT ĐIỆN (GENERATOR) TỪ SCRIPT GỐC
local function getGeneratorPosition()
    if cachedGeneratorLocation then return cachedGeneratorLocation end
    if MapFolder then
        local tiles = MapFolder:FindFirstChild("Tiles")
        if tiles then
            for _, child in ipairs(tiles:GetChildren()) do
                if child.Name == "Generator" or child:FindFirstChild("Generator") then
                    cachedGeneratorLocation = child:GetPivot().Position
                    return cachedGeneratorLocation
                end
            end
        end
    end
    local fallbackGen = Workspace:FindFirstChild("Generator", true)
    if fallbackGen then
        cachedGeneratorLocation = fallbackGen:GetPivot().Position
        return cachedGeneratorLocation
    end
    return nil
end

-- 3. THỰC THI DI CHUYỂN ĐẾN GENERATOR
print("[Pipeline] Đang quét vị trí Generator...")
local generatorTarget = getGeneratorPosition()

if generatorTarget then
    print("[Pipeline] Đang tiến hành bò xuyên tường tới Generator.")
    -- Gọi thuật toán di chuyển gốc hướng thẳng đến Máy Phát Điện
    adaptiveCrawlTo(generatorTarget, humanoidRootPart, character)
    print("[Complete] Đã đến vị trí Generator thành công!")
else
    warn("[Warning] Không tìm thấy Generator nào trên Map.")
end
