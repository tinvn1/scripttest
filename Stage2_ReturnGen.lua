local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 32

local path = PathfindingService:CreatePath({
    AgentRadius = 1.6, 
    AgentHeight = 5, 
    AgentCanJump = true
})

-- =========================================================================
-- 🛠️ HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN (GENERATOR)
-- =========================================================================
local function getGenerator()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" or obj.Name == "Gen" or obj.Name == "MainGen" then
            return obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

-- =========================================================================
-- 🕵️‍♂️ HÀM KIỂM TRA THUỘC TÍNH SERVER (SPY CHECK)
-- =========================================================================
local function checkIsStage2(genPart)
    if not genPart then return false end
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    if genModel then
        local currentStage = genModel:GetAttribute("Stage")
        if currentStage then
            print("[🕵️ SPY CHECK] Máy phát điện thực tế từ Server đang ở Cấp: " .. tostring(currentStage))
            if tonumber(currentStage) >= 2 then
                return true
            end
        end
    end
    return false
end

-- =========================================================================
-- 🏃‍♂️ HÀM DI CHUYỂN DÒ ĐƯỜNG TIẾP CẬN MÁY PHÁT ĐIỆN
-- =========================================================================
local function walkPathToGenerator(root, genPart)
    if not root or not genPart then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(root.Position, genPart.Position)
    end)
    if not success or path.Status ~= Enum.PathStatus.Success then return false end
    
    local waypoints = path:GetWaypoints()
    for i = 1, math.min(#waypoints, 5) do
        local wp = waypoints[i]
        local dist = (root.Position - wp.Position).Magnitude
        local duration = dist / TWEEN_SPEED
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(wp.Position + Vector3.new(0, 1, 0)) -- Hạ thấp trọng tâm lướt sát sàn
        })
        tween:Play()
        tween.Completed:Wait()
    end
    
    -- ÉP LỰC CUỐI: Lao thẳng vào tâm máy phát điện
    local finalDist = (root.Position - genPart.Position).Magnitude
    if finalDist < 15 then
        local finalTween = TweenService:Create(root, TweenInfo.new(finalDist / TWEEN_SPEED, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(genPart.Position + Vector3.new(0, 0.5, 0))
        })
        finalTween:Play()
        finalTween.Completed:Wait()
    end
    
    return true
end

-- =========================================================================
-- TIẾN TRÌNH THỰC THI CHÍNH CỦA STAGE 2
-- =========================================================================
print("[🎒 STAGE 2] Bắt đầu luồng tiếp cận Generator...");

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local genPart = getGenerator()

if root and genPart and _G.CurrentStage == 2 then
    -- Thực hiện di chuyển sát vào Generator
    walkPathToGenerator(root, genPart)
    task.wait(0.1) -- Đợi vật lý nhân vật ổn định vị trí
    
    -- 🔥 BỘ KIỂM TOÁN KHOẢNG CÁCH THỰC TẾ (CHỐNG ĐỔ XĂNG HỤT)
    local checkDist = (root.Position - genPart.Position).Magnitude
    if checkDist <= 5 then
        print(string.format("[🎉 TIẾP CẬN] Đã đứng sát sạt Máy phát điện (Khoảng cách: %.2f studs). Tiến hành đổ xăng!", checkDist))
        
        -- Kích hoạt đổ xăng
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") 
                       or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
                       or (genPart.Parent:IsA("Model") and genPart.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
        
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
        else
            -- Dự phòng nếu không tìm thấy Prompt: Ép CFrame dẫm thẳng vào để Touch vật lý nạp nhiên liệu
            root.CFrame = CFrame.new(genPart.Position)
        end
        
        print("[⏳] Đợi 1.5 giây để Server cập nhật trạng thái hoạt ảnh...")
        task.wait(1.5)
        
        -- Spy Check 3 lần chống lag ping cao từ Server
        local isRealStage2 = false
        for attempt = 1, 3 do
            if checkIsStage2(genPart) then 
                isRealStage2 = true
                break 
            end
            task.wait(0.5)
        end
        
        if isRealStage2 then
            print("[🎯 STAGE 2 SUCCESS] Xác nhận nâng cấp lên cấp 2 hoàn tất! Chuyển giao sang Stage 3.")
            _G.CurrentStage = 3
        else
            warn("[❌ STAGE 2 LỖI] Đã nạp nhưng máy không lên cấp (có thể hụt bình xăng hoặc server lag)! Ép về Stage 1 để kiểm tra.")
            _G.CurrentStage = 1
        end
    else
        -- ❌ PHÁT HIỆN LỖI: Chưa tới nơi mà hàm di chuyển đã dừng (Kẹt góc, ôm tường)
        warn(string.format("[❌ TIẾP CẬN LỖI] Đứng quá xa Máy phát điện (Khoảng cách: %.2f studs)! Ép về Stage 1 đi nhặt lại để làm mới luồng.", checkDist))
        _G.CurrentStage = 1
    end
else
    warn("[⚠️ STAGE 2 ABORT] Không tìm thấy Generator hoặc nhân vật chưa sẵn sàng. Trở lại Stage 1.")
    _G.CurrentStage = 1
end

return true
