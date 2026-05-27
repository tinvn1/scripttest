local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({
    AgentRadius = 1.6, 
    AgentHeight = 5, 
    AgentCanJump = true
})
local ignoredFuels = {}

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ FUEL CHÍNH XÁC VÀ AN TOÀN
-- =========================================================================
local function getNearestFuel(rootPosition)
    local nearestFuel = nil
    local minDistance = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Fuel" and (obj:IsA("Model") or obj:IsA("BasePart")) and not ignoredFuels[obj] then
            local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (rootPosition - part.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    nearestFuel = part
                end
            end
        end
    end
    return nearestFuel
end

-- =========================================================================
-- 🔥 HÀM DÒ ĐƯỜNG VÀ DI CHUYỂN TỚI MỤC TIÊU (PATHFINDING + TWEEN)
-- =========================================================================
local function walkPathToTarget(root, targetPart)
    if not root or not targetPart then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(root.Position, targetPart.Position)
    end)
    
    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end
    
    local waypoints = path:GetWaypoints()
    for i = 1, math.min(#waypoints, 4) do
        local wp = waypoints[i]
        local dist = (root.Position - wp.Position).Magnitude
        local duration = dist / TWEEN_SPEED
        
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(wp.Position + Vector3.new(0, 2, 0))})
        tween:Play()
        tween.Completed:Wait()
    end
    return true
end

-- =========================================================================
-- 🔄 VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1
-- =========================================================================
print("[STAGE 1] Bắt đầu quét tìm nhặt 2 bình Fuel (Dò đường kỹ lưỡng)...")
local cycle = 1
local stuckCounter = 0

while cycle <= 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then task.wait(0.5) continue end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelObject = targetFuel.Parent:IsA("Model") and targetFuel.Parent or targetFuel
        local success = walkPathToTarget(root, targetFuel)
        
        if success then
            print(string.format("[🎉] Đã tiếp cận Fuel %d/2 thành công!", cycle))
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt and fireproximityprompt then fireproximityprompt(prompt) end
            
            ignoredFuels[fuelObject] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.4)
        else
            stuckCounter = stuckCounter + 1
            if stuckCounter >= 3 then
                print("[⚠️] Kẹt góc, bỏ qua tìm bình khác!")
                ignoredFuels[fuelObject] = true
                stuckCounter = 0
            end
            task.wait(0.1)
        end
    else
        print("[-] Đang quét tìm kiếm lại tài nguyên Fuel...")
        ignoredFuels = {}
        task.wait(0.5)
    end
end

print("[STAGE 1] HOÀN THÀNH XUẤT SẮC!")
task.wait(0.1)
_G.CurrentStage = 2 -- Đẩy trạng thái sang Stage 2
return true
