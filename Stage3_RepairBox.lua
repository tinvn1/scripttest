-- =========================================================================
-- CHỈ DI CHUYỂN ĐẾN MÁY ĐIỆN (POWER BOX) - ĐÃ BỎ PHẦN TƯƠNG TÁC
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
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

-- 2. QUÉT VÀ DI CHUYỂN ĐẾN MÁY ĐIỆN GẦN NHẤT
print("[Step 3] Scanning for closest Power Box model...")
local powerBoxData = {}

-- Tìm vị trí các Power Box trong map
if MapFolder and MapFolder:FindFirstChild("Tiles") then
    for _, child in ipairs(MapFolder.Tiles:GetChildren()) do
        if child.Name == "Power Plant" then
            local powerBox = child:FindFirstChild("Power Box")
            if powerBox and powerBox:IsA("Model") then
                table.insert(powerBoxData, {
                    Instance = powerBox,
                    Position = powerBox:GetPivot().Position
                })
            end
        end
    end
end

-- Nếu tìm thấy máy điện, tiến hành bay/di chuyển đến
if #powerBoxData > 0 then
    local currentPos = humanoidRootPart.Position
    -- Sắp xếp để chọn cái gần vị trí hiện tại của bạn nhất
    table.sort(powerBoxData, function(a, b)
        return (currentPos - a.Position).Magnitude < (currentPos - b.Position).Magnitude
    end)

    local finalBoxTarget = powerBoxData[1].Position

    print("[Step 3] Crawling directly to closest Power Box.")
    -- Thực hiện di chuyển đến đích
    adaptiveCrawlTo(finalBoxTarget, humanoidRootPart, character)
    print("[Complete] Arrived at Power Box!")
else
    warn("[Warning] No Power Box found on the map.")
end
