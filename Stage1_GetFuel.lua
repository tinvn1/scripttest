local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 32 -- Tăng tốc độ lướt một chút cho mượt

local path = PathfindingService:CreatePath({
    AgentRadius = 1.4, -- Thu nhỏ bán kính hơn nữa để len lỏi sát mục tiêu
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
    -- Di chuyển qua các nút đường đi ban đầu
    for i = 1, math.min(#waypoints, 4) do
        local wp = waypoints[i]
        local dist = (root.Position - wp.Position).Magnitude
        local duration = dist / TWEEN_SPEED
        -- Offset Y hạ xuống 1 để chân chạm sát sàn, tiến gần hơn
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(wp.Position + Vector3.new(0, 1, 0))
        })
        tween:Play()
        tween.Completed:Wait()
    end
    
    -- 🔥 ĐOẠN ĐỘT PHÁ: Khi đã ở rất gần, ép CFrame lao thẳng vào tâm bình xăng
    local finalDist = (root.Position - targetPart.Position).Magnitude
    if finalDist < 15 then
        -- Ép thẳng vị trí nhân vật trùng dịch một chút sát bên cạnh bình xăng (cách 0.2 studs)
        local targetCFrame = CFrame.new(targetPart.Position + Vector3.new(0, 1, 0))
        local finalTween = TweenService:Create(root, TweenInfo.new(finalDist / TWEEN_SPEED, Enum.EasingStyle.Linear), {
            CFrame = targetCFrame
        })
        finalTween:Play()
        finalTween.Completed:Wait()
    end
    
    return true
end

-- =========================================================================
-- TIẾN TRÌNH KHÓA LUỒNG KIỂM TRA ĐỦ 2 BÌNH
-- =========================================================================
local cycle = 1
local stuckCounter = 0

while cycle <= 2 do
    if _G.CurrentStage ~= 1 then return false end 

    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local targetFuel = getNearestFuel(root.Position)
        if targetFuel then
            local fuelObject = targetFuel.Parent:IsA("Model") and targetFuel.Parent or targetFuel
            local success = walkPathToTarget(root, targetFuel)
            
            if success and _G.CurrentStage == 1 then
                -- Đứng khựng lại một chút siêu ngắn để Server đồng bộ vị trí sát cạnh
                task.wait(0.1) 
                
                print(string.format("[🎉 STAGE 1] Đã áp sát gốc! Nhặt bình xăng số %d/2!", cycle))
                
                -- Tìm và kích hoạt ProximityPrompt
                local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") 
                               or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
                               or (targetFuel.Parent:IsA("Model") and targetFuel.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
                
                if prompt and fireproximityprompt then 
                    fireproximityprompt(prompt) 
                else
                    -- Dự phòng: Nếu không có Prompt, ép CFrame dẫm thẳng lên vật phẩm để nhặt bằng chạm vật lý
                    root.CFrame = CFrame.new(targetFuel.Position)
                end
                
                ignoredFuels[fuelObject] = true
                cycle = cycle + 1
                stuckCounter = 0
                task.wait(0.5) -- Chờ server xóa vật phẩm khỏi map
            else
                stuckCounter = stuckCounter + 1
                if stuckCounter >= 3 then
                    ignoredFuels[fuelObject] = true
                    stuckCounter = 0
                end
                task.wait(0.2)
            end
        else
            -- Nếu không thấy bình xăng, dọn dẹp danh sách đen để quét diện rộng lại từ đầu
            ignoredFuels = {}
            task.wait(0.5)
        end
    else
        task.wait(0.5)
    end
end

print("[🎯 STAGE 1] Đã cầm chắc 2 bình xăng trên tay! Trả quyền điều khiển về Main.");
return true
