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
-- 🔄 LUỒNG CHẠY NGẦM ĐỘC LẬP (LOOP LIÊN TỤC KHÔNG DỪNG)
-- =========================================================================
task.spawn(function()
    print("[⛽ ASYNC] Luồng tìm kiếm Fuel độc lập đã được thiết lập thành công!");
    local cycle = 1
    local stuckCounter = 0

    while true do
        -- CHỈ CHẠY khi hệ thống yêu cầu Stage 1
        if _G.CurrentStage == 1 then
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and cycle <= 2 then
                local targetFuel = getNearestFuel(root.Position)
                if targetFuel then
                    local fuelObject = targetFuel.Parent:IsA("Model") and targetFuel.Parent or targetFuel
                    local success = walkPathToTarget(root, targetFuel)
                    
                    if success then
                        print(string.format("[🎉 Fuel Độc Lập] Đã nhặt Fuel %d/2!", cycle))
                        local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                        
                        ignoredFuels[fuelObject] = true
                        cycle = cycle + 1
                        stuckCounter = 0
                        task.wait(0.4)
                    else
                        stuckCounter = stuckCounter + 1
                        if stuckCounter >= 3 then
                            ignoredFuels[fuelObject] = true
                            stuckCounter = 0
                        end
                        task.wait(0.1)
                    end
                else
                    print("[⛽] Không thấy bình xăng, làm sạch danh sách quét lại...")
                    ignoredFuels = {}
                    task.wait(1.0)
                end
            elseif cycle > 2 then
                -- Đã gom đủ 2 bình xăng thành công!
                print("[🎯 Fuel Độc Lập] Gom xong xuôi 2 bình. Bàn giao trạng thái cho Stage 2!");
                cycle = 1 -- Reset bộ đếm sẵn sàng cho chu kỳ sau (nếu bị lùi stage)
                ignoredFuels = {}
                _G.CurrentStage = 2 -- Chuyển trạng thái phát tín hiệu cho file main
                task.wait(1.0)
            end
        else
            -- Nếu đang ở các Stage khác (2, 3, 4, 5), luồng này sẽ ngủ ngầm để tiết kiệm CPU
            task.wait(0.5)
        end
    end
end)

return true
