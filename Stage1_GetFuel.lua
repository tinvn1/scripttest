local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({
    AgentRadius = 1.6, 
    AgentHeight = 5, 
    AgentCanJump = true
})
local ignoredFuels = {}

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

local function walkPathToTarget(root, targetPart)
    if not root or not targetPart then return false end
    local success, err = pcall(function()
        path:ComputeAsync(root.Position, targetPart.Position)
    end)
    if not success or path.Status ~= Enum.PathStatus.Success then return false end
    
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
-- ⚡ TIẾN TRÌNH NHẶT XĂNG KHÓA LUỒNG
-- =========================================================================
print("[⛽ STAGE 1] Bắt đầu quét tìm nhặt đúng 2 bình Fuel...");
local cycle = 1
local stuckCounter = 0

-- Vòng lặp này giữ chân Script, GIỮ KHÔNG CHO MAIN CHẠY SANG STAGE 2
while cycle <= 2 do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not root then 
        task.wait(0.5) 
        continue 
    end
    
    local targetFuel = getNearestFuel(root.Position)
    if targetFuel then
        local fuelObject = targetFuel.Parent:IsA("Model") and targetFuel.Parent or targetFuel
        local success = walkPathToTarget(root, targetFuel)
        
        if success then
            print(string.format("[🎉 STAGE 1] Đã tiếp cận và nhặt bình Fuel %d/2 thành công!", cycle))
            local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt and fireproximityprompt then 
                fireproximityprompt(prompt) 
            end
            
            ignoredFuels[fuelObject] = true
            cycle = cycle + 1
            stuckCounter = 0
            task.wait(0.5) -- Đợi server nhận item
        else
            stuckCounter = stuckCounter + 1
            if stuckCounter >= 3 then
                print("[⚠️ STAGE 1] Bình này bị kẹt góc, bỏ qua tìm bình khác!")
                ignoredFuels[fuelObject] = true
                stuckCounter = 0
            end
            task.wait(0.2)
        end
    else
        print("[⛽ STAGE 1] Không tìm thấy bình xăng nào trống, đang quét lại map...")
        ignoredFuels = {}
        task.wait(1.0)
    end
end

-- CHỈ KHI CHẠY XUỐNG ĐÂY (ĐỦ 2 BÌNH) -> MỚI BÁO CÁO HOÀN THÀNH
print("[🎯 STAGE 1] Đã thu thập đủ 2 bình xăng! Giải phóng luồng...");
return true
