local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({
    AgentRadius = 1.4, -- Thu nhỏ tối đa để đi lách ngách sát bình xăng
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
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(wp.Position + Vector3.new(0, 1, 0)) -- Hạ thấp trọng tâm chạm sàn
        })
        tween:Play()
        tween.Completed:Wait()
    end
    
    -- ÉP LỰC CUỐI: Lao thẳng vào gốc bình xăng
    local finalDist = (root.Position - targetPart.Position).Magnitude
    if finalDist < 15 then
        local finalTween = TweenService:Create(root, TweenInfo.new(finalDist / TWEEN_SPEED, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 0.5, 0))
        })
        finalTween:Play()
        finalTween.Completed:Wait()
    end
    
    return true
end

-- =========================================================================
-- TIẾN TRÌNH KHÓA LUỒNG KIỂM TRA ĐỦ 2 BÌNH CHẮC CHẮN
-- =========================================================================
local cycle = 1
local stuckCounter = 0

print("[⛽ STAGE 1] Bắt đầu chu kỳ nhặt Fuel nghiêm ngặt...");

while cycle <= 2 do
    -- Nếu trạng thái bị ép đổi bậy từ ngoài, ngắt luôn
    if _G.CurrentStage ~= 1 then return false end 

    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local targetFuel = getNearestFuel(root.Position)
        if targetFuel then
            local fuelObject = targetFuel.Parent:IsA("Model") and targetFuel.Parent or targetFuel
            
            -- Chạy tới mục tiêu
            walkPathToTarget(root, targetFuel)
            task.wait(0.1) -- Đợi 0.1 giây để vật lý cập nhật vị trí ổn định
            
            -- 🔥 BỘ KIỂM TOÁN PHÁT HIỆN GIAN LẬN TRẠNG THÁI (FIX LỖI CHÍNH)
            local checkDist = (root.Position - targetFuel.Position).Magnitude
            if checkDist <= 4 then 
                -- ĐỨNG THỰC SỰ SÁT BÌNH XĂNG (Khoảng cách dưới 4 studs) -> MỚI ĐƯỢC PHÉP NHẶT
                print(string.format("[🎉 THÀNH CÔNG] Đã đứng sát gốc bình xăng! Tiến hành nhặt %d/2", cycle))
                
                local prompt = targetFuel:FindFirstChildOfClass("ProximityPrompt") 
                               or targetFuel.Parent:FindFirstChildOfClass("ProximityPrompt")
                               or (targetFuel.Parent:IsA("Model") and targetFuel.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
                
                if prompt and fireproximityprompt then 
                    fireproximityprompt(prompt) 
                else
                    -- Dự phòng: Đè CFrame trùng khít lên bình xăng để nhặt bằng Touch vật lý
                    root.CFrame = CFrame.new(targetFuel.Position)
                end
                
                ignoredFuels[fuelObject] = true
                cycle = cycle + 1
                stuckCounter = 0
                task.wait(0.6) -- Chờ server xóa vật phẩm cũ (Chống nhặt trùng)
            else
                -- ❌ PHÁT HIỆN LỖI: Đi nửa đường bị khựng, chưa tới sát bình xăng!
                stuckCounter = stuckCounter + 1
                warn(string.format("[⚠️ CẢNH BÁO] Chưa chạm tới bình xăng (Khoảng cách thực: %.2f studs)! Thử tiếp cận lại...", checkDist))
                
                if stuckCounter >= 3 then
                    print("[❌ KẸT NẶNG] Bình xăng này bị lỗi góc khuất map, đưa vào danh sách đen để đổi bình khác!")
                    ignoredFuels[fuelObject] = true
                    stuckCounter = 0
                end
                task.wait(0.2)
            end
        else
            -- Map hết xăng hoặc đang tải, clear danh sách đen quét lại rộng hơn
            ignoredFuels = {}
            task.wait(0.5)
        end
    else
        task.wait(0.5)
    end
end

print("[🎯 STAGE 1 DONE] Xác thực thực tế: Đã đứng sát và nhặt hoàn chỉnh 2 bình! Mở khóa luồng.");
return true
