local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 2.0, AgentHeight = 5, AgentCanJump = true})
local ignoredFuels = {}
local fuelStuckCounter = 0

local function getNearestFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" and obj:IsA("Model") and not ignoredFuels[obj] then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (rootPosition - part.Position).Magnitude
                if dist < minDistance then minDistance = dist; nearestFuel = part end
            end
        end
    end
    return nearestFuel
end

local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    path:ComputeAsync(rootPart.Position, targetPart.Position)
    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - waypoint.Position).Magnitude / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
            if (rootPart.Position - expectedCFrame.Position).Magnitude > 4.5 then return false end
        end
        return true
    end
    return false
end

-- Vòng lặp thực hiện nhiệm vụ nhặt đủ 2 bình xăng
local currentFuelCount = 0
print("[STAGE 1] Đang tìm nhặt 2 bình Fuel...")

while currentFuelCount < 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local targetFuel = getNearestFuel(root.Position)
        if targetFuel then
            local success = walkPathToTarget(root, targetFuel)
            if success then
                currentFuelCount = currentFuelCount + 1
                ignoredFuels[targetFuel.Parent] = true
                fuelStuckCounter = 0
                task.wait(0.5)
            else
                fuelStuckCounter = fuelStuckCounter + 1
                if fuelStuckCounter >= 3 then
                    ignoredFuels[targetFuel.Parent] = true
                    fuelStuckCounter = 0
                end
            end
        end
    end
    task.wait(0.2)
end

print("[STAGE 1] HOÀN THÀNH!")
return true -- Trả về kết quả để hàm Main chạy tiếp file sau
