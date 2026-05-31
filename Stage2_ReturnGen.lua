-- Stage2: Di chuyển quay về vị trí Generator
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local PermanentNoclipEnabled = true
local cachedGeneratorLocation = nil

-- --- BACKGROUND SERVICE: PERMANENT NOCLIP ENGINE ---
local function StartPermanentNoclip()
    local noclipConnection = nil
    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then if noclipConnection then noclipConnection:Disconnect() end return end
            local char = LocalPlayer.Character
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
    LocalPlayer.CharacterAdded:Connect(function() task.wait(0.1) ConnectNoclip() end)
end
StartPermanentNoclip()

-- --- HÀM DI CHUYỂN CRAWL GỐC ---
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
            hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.new(0, -5, 0), Vector3.new(0, 0, 0)
            hrp.Anchored = true; task.wait(0.05); hrp.Anchored = false
            break
        end

        local direction = remainingVector.Unit
        local rayResult = Workspace:Raycast(currentPos, direction * 5, raycastParams)
        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then lastWallDetectedTime = os.clock() end

        local activeStepDistance = (os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN) and 1.4 or 0.25
        local currentAllowedSpeed = (os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN) and FAST_SPEED or SLOW_SPEED
        local delayInterval = activeStepDistance / currentAllowedSpeed
        local flattenedPosition = Vector3.new((currentPos + (direction * activeStepDistance)).X, lockedYHeight, (currentPos + (direction * activeStepDistance)).Z)

        hrp.CFrame = CFrame.new(flattenedPosition)
        task.wait(delayInterval)
    end
end

-- --- HÀM QUÉT GENERATOR ---
local function getGeneratorPosition()
    if cachedGeneratorLocation then return cachedGeneratorLocation end
    if MapFolder and MapFolder:FindFirstChild("Tiles") then
        for _, child in ipairs(MapFolder.Tiles:GetChildren()) do
            if child.Name == "Generator" or child:FindFirstChild("Generator") then
                cachedGeneratorLocation = child:GetPivot().Position; return cachedGeneratorLocation
            end
        end
    end
    local fallbackGen = Workspace:FindFirstChild("Generator", true)
    if fallbackGen then cachedGeneratorLocation = fallbackGen:GetPivot().Position; return cachedGeneratorLocation end
    return nil
end

print("[Stage 2] Đang quét Generator...")
local generatorTarget = getGeneratorPosition()
if generatorTarget then
    adaptiveCrawlTo(generatorTarget, humanoidRootPart, character)
    print("[Stage 2 Complete] Đã quay về Generator!")
else
    warn("[Stage 2 Warning] Không tìm thấy Generator.")
end
