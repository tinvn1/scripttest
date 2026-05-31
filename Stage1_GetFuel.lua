-- =========================================================================
-- ĐOẠN CODE DI CHUYỂN QUA MÁY PHÁT ĐIỆN (GENERATOR) THEO CƠ CHẾ MỚI
-- =========================================================================

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")

local cachedGeneratorLocation = nil
local PermanentNoclipEnabled = true

-- --- BACKGROUND SERVICE: PERMANENT NOCLIP ENGINE (Theo cơ chế script gốc) ---
local function StartPermanentNoclip()
    local noclipConnection = nil

    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end

        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then
                if noclipConnection then noclipConnection:Disconnect() end
                return
            end

            local character = LocalPlayer.Character
            if character then
                -- Loại bỏ va chạm vật lý
                for _, child in ipairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        child.CanCollide = false
                    end
                end

                -- Triệt tiêu gia tốc để tránh bị giật ngược (Anti-cheat rubberbanding)
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
        end)
    end

    ConnectNoclip()

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.1)
        ConnectNoclip()
    end)
end

StartPermanentNoclip()

-- --- HÀM QUÉT ĐỊNH VỊ MÁY PHÁT ĐIỆN (Theo cơ chế script gốc) ---
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

-- --- THUẬT TOÁN DI CHUYỂN ADAPTIVE CRAWL (Giữ nguyên cấu trúc mượt mà chống lag) ---
local function adaptiveCrawlTo(targetPos, humanoidRootPart, character)
    -- Giữ nguyên cấu trúc cộng cao độ (Trong code gốc của bạn là +3)
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

-- --- THỰC THI CHẠY ĐẾN MÁY ĐIỆN ---
local function movePlayerToGenerator()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    print("[HỆ THỐNG] Đang tìm kiếm Máy phát điện...")
    local generatorLocation = getGeneratorPosition()

    if generatorLocation then
        print("[HỆ THỐNG] Đã tìm thấy vị trí. Bắt đầu di chuyển xuyên tường...")
        adaptiveCrawlTo(generatorLocation, humanoidRootPart, character)
        print("[🎯 THÀNH CÔNG] Nhân vật đã đến Generator an toàn bằng cơ chế mới!")
    else
        warn("[⚠️ LỖI] Không tìm thấy Máy phát điện (Generator) nào trên bản đồ!")
    end
end

-- Kích hoạt lệnh di chuyển
movePlayerToGenerator()
