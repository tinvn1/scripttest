local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN
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
-- 🔥 HÀM DI CHUYỂN TWEEN
-- =========================================================================
local function tweenToGenerator(rootPart, genPart)
    if not rootPart or not genPart then return false end
    
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local success, _ = pcall(function()
        path:ComputeAsync(rootPart.Position, genPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        for _, waypoint in pairs(path:GetWaypoints()) do
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local dist = (rootPart.Position - waypoint.Position).Magnitude
            local tween = TweenService:Create(rootPart, TweenInfo.new(dist / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
        end
        return true
    else
        rootPart.CFrame = CFrame.new(genPart.Position + Vector3.new(0, 2, 0))
        return true
    end
end

-- =========================================================================
-- 🎮 KHỞI ĐỘNG CHẠY ĐỒNG THỜI STAGE 2 VÀ STAGE 2.5 SPY
-- =========================================================================
print("[STAGE 2 & 2.5] Khởi động luồng chạy song song đồng thời...")

local genPart = getGenerator()
if genPart then
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    local hasVariableChange = false
    local isStageFinished = false -- Cờ đánh dấu luồng chính đã kết thúc hay chưa
    
    -- ---------------------------------------------------------------------
    -- 🕵️‍♂️ [LUỒNG SPY 2.5 - CHẠY NGẦM SONG SONG NGAY LẬP TỨC]
    -- ---------------------------------------------------------------------
    local connAdd, connRemove
    
    task.spawn(function()
        print("[🕵️‍♂️ SPY 2.5 DIỄN RA] Đang rình biến số song song với tiến trình di chuyển...")
        
        connAdd = genModel.DescendantAdded:Connect(function(descendant)
            print("[⚡ SPY DETECTED] Thế giới cập nhật cấu trúc mới (Thêm): " .. descendant.Name)
            hasVariableChange = true
        end)
        
        connRemove = genModel.DescendantRemoving:Connect(function(descendant)
            print("[⚡ SPY DETECTED] Thế giới cập nhật cấu trúc mới (Xóa): " .. descendant.Name)
            hasVariableChange = true
        end)
        
        -- Vòng lặp rình biến số chạy liên tục song song với di chuyển
        while not hasVariableChange and not isStageFinished do
            task.wait(0.1)
        end
        
        -- Nếu phát hiện biến số trong lúc đang di chuyển hoặc đang tương tác
        if hasVariableChange and not isStageFinished then
            isStageFinished = true
            print("[🎯 SPY TRÚNG ĐÍCH] Phát hiện biến số thay đổi cấu trúc lập tức! Ép nhảy lên Stage 3.")
            
            -- Gỡ kết nối ngay để tránh lag
            if connAdd then connAdd:Disconnect() end
            if connRemove then connRemove:Disconnect() end
            
            _G.CurrentStage = 3
        end
    end)

    -- ---------------------------------------------------------------------
    -- 🏃‍♂️ [LUỒNG CHÍNH STAGE 2 - DI CHUYỂN VÀ TƯƠNG TÁC VẬT LÝ]
    -- ---------------------------------------------------------------------
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        -- 1. Tiến hành di chuyển song song tới vị trí máy
        tweenToGenerator(root, genPart)
        task.wait(0.2)
        
        -- 2. Thực hiện bấm tương tác vật lý nếu luồng spy chưa ép nhảy màn trước đó
        if not isStageFinished then
            local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                fireproximityprompt(prompt)
            end
            task.wait(1.5) -- Chờ một khoảng thời gian ngắn sau khi bấm để game nạp cập nhật
        end
    end
    
    -- ---------------------------------------------------------------------
    -- 📊 ĐÁNH GIÁ KẾT QUẢ ĐỂ PHẠT HOẶC ĐI TIẾP
    -- ---------------------------------------------------------------------
    -- Ngắt kết nối bảo vệ tài nguyên hệ thống
    if connAdd then connAdd:Disconnect() end
    if connRemove then connRemove:Disconnect() end
    
    if hasVariableChange or _G.CurrentStage == 3 then
        print("[🎯 STAGE 2 & 2.5 SUCCESS] Hệ thống đồng bộ thành công -> Lên Stage 3.")
        _G.CurrentStage = 3
    else
        -- PHẠT NẶNG: Nếu di chuyển tới nơi, bấm nút rồi mà máy vẫn im lìm hoàn toàn (Không có biến số)
        warn("[❌ STAGE 2 & 2.5 FAILED] Máy hoàn toàn trơ lỳ im lìm! PHẠT: Lùi thẳng về Stage 1.")
        isStageFinished = true
        _G.CurrentStage = 1
    end
else
    print("[⚠️] Không tìm thấy máy phát điện trong thế giới này... Trả về Stage 1.")
    _G.CurrentStage = 1
end

return true
