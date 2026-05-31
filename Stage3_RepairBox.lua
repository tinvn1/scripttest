-- =========================================================================
-- [NEW MECHANICAL] STAGE 3: BÒ XUYÊN TƯỜNG ĐẾN TRẠM ĐIỆN (POWER BOX)
-- =========================================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local MapFolder = Workspace:FindFirstChild("Map")
local PermanentNoclipEnabled = true

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

-- --- HÀM ĐỊNH VỊ TRẠM ĐIỆN (POWER BOX) GẦN NHẤT ---
local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    
    -- Ưu tiên quét theo cấu hình Folder Map trước để tối ưu hiệu năng
    if MapFolder and MapFolder:FindFirstChild("Tiles") then
        for _, child in ipairs(MapFolder.Tiles:GetChildren()) do
            if child.Name == "Power Plant" then
                local powerBox = child:FindFirstChild("Power Box")
                if powerBox then
                    local part = powerBox:IsA("BasePart") and powerBox or powerBox.PrimaryPart or powerBox:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (rootPosition - part.Position).Magnitude
                        if dist < minDistance then
                            minDistance = dist; nearestBoxPart = part
                        end
                    end
                end
            end
        end
    end
    
    -- Quét diện rộng dự phòng nếu map không nằm trong thư mục Tiles
    if not nearestBoxPart then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Power Box" then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (rootPosition - part.Position).Magnitude
                    if dist < minDistance then 
                        minDistance = dist; nearestBoxPart = part 
                    end
                end
            end
        end
    end
    return nearestBoxPart
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH STAGE 3
-- =========================================================================
print("[STAGE 3] Khởi động hệ thống di chuyển xuyên tường tiến thẳng đến Trạm điện...");
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            if distance > 4.5 then
                print("[STAGE 3] Tiến hành bò xuyên qua mọi rào chắn đến Power Box...")
                adaptiveCrawlTo(targetBox.Position, root, char)
            else
                print("[🎯 STAGE 3 SUCCESS] Nhân vật đã vượt qua mọi vật cản và chạm đích Power Box thành công!");
                reached = true
            end
        else
            task.wait(0.2)
        end
    else
        task.wait(0.3)
    end
    task.wait(0.01)
end

task.wait(0.05)
_G.CurrentStage = 4
return true
