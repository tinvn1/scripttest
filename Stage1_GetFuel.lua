-- Stage1: Tìm và di chuyển đến cục Fuel gần nhất
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local DroppedItemsFolder = Workspace:WaitForChild("DroppedItems")
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local PermanentNoclipEnabled = true

-- --- BACKGROUND SERVICE: PERMANENT NOCLIP ENGINE ---
local function StartPermanentNoclip()
    local noclipConnection = nil
    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then
                if noclipConnection then noclipConnection:Disconnect() end
                return
            end
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

-- --- HÀM QUÉT FUEL ---
local excludeFuel = {}
local function getClosestFuelPosition(currentPos)
    local foundValidFuel = nil
    while not foundValidFuel do
        local bestTarget, shortestDistance = nil, math.huge
        if DroppedItemsFolder then
            for _, item in ipairs(DroppedItemsFolder:GetChildren()) do
                if item.Name == "Fuel" and not excludeFuel[item] then
                    local dist = (currentPos - item:GetPivot().Position).Magnitude
                    if dist < shortestDistance then shortestDistance = dist; bestTarget = item end
                end
            end
        end
        if not bestTarget then break end
        local targetPosition = bestTarget:GetPivot().Position
        if (targetPosition.Y - currentPos.Y) <= 2 then foundValidFuel = bestTarget else excludeFuel[bestTarget] = true end
    end
    return foundValidFuel
end

print("[Stage 1] Đang quét tìm Fuel...")
local targetFuel = getClosestFuelPosition(humanoidRootPart.Position)
if targetFuel then
    adaptiveCrawlTo(targetFuel:GetPivot().Position, humanoidRootPart, character)
    print("[Stage 1 Complete] Đã đứng ở vị trí Fuel!")
else
    warn("[Stage 1 Warning] Không tìm thấy Fuel.")
end
