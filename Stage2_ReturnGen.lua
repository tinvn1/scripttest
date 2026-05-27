local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN (ĐÃ LƯỢC BỎ MỌI LOGIC GARA)
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
-- 🕵️‍♂️ CƠ CHẾ CHECK 2.5: DÒ BIẾN ĐỘNG NHỎ CỦA THẾ GIỚI
-- =========================================================================
local function checkWorldUpdate(genPart)
    if not genPart then return false end
    
    -- Lấy Model gốc chứa cục Part để lắng nghe các linh kiện bên trong
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    local isUpdated = false
    
    print("[🕵️‍♂️ SPY 2.5] Bắt đầu đứng rình biến động nhỏ của máy...")
    
    -- Theo dõi đệ quy xem thế giới có cập nhật thêm/bớt vật thể gì bên trong máy không
    local connAdd = genModel.DescendantAdded:Connect(function(descendant)
        print("[⚡ SPY UPDATE]: Thế giới vừa thêm vật thể mới -> " .. descendant.Name)
        isUpdated = true
    end)
    
    local connRemove = genModel.DescendantRemoving:Connect(function(descendant)
        print("[⚡ SPY UPDATE]: Thế giới vừa mất vật thể -> " .. descendant.Name)
        isUpdated = true
    end)
    
    -- Chờ tối đa 5 giây xem thế giới game có biến động gì không
    local startTime = os.clock()
    while (os.clock() - startTime) < 5 do
        if isUpdated then break end
        task.wait(0.1)
    end
    
    -- Ngắt kết nối để giải phóng bộ nhớ, tránh bị lag/giật máy
    connAdd:Disconnect()
    connRemove:Disconnect()
    
    return isUpdated
end

-- =========================================================================
-- 🔥 HÀM DI CHUYỂN
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
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH
-- =========================================================================
print("[STAGE 2] Bắt đầu di chuyển đến máy phát điện...")

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    if genPart then
        -- Tiến hành di chuyển tới máy
        tweenToGenerator(root, genPart)
        
        -- Kích hoạt nút tương tác (Prompt)
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
        
        task.wait(0.5) -- Đợi hiệu ứng tương tác kích hoạt dữ liệu game
        
        -- KÍCH HOẠT CƠ CHẾ 2.5: ĐỨNG CHECK BIẾN ĐỘNG THẾ GIỚI TẠI MÁY
        local hasChange = checkWorldUpdate(genPart)
        
        if hasChange then
            -- ĐI TIẾP STAGE 3 NẾU CÓ THAY ĐỔI NHỎ XẢY RA
            print("[🎯 STAGE 2 DONE] Phát hiện biến động thành công! Tiến hành lên Stage 3.")
            _G.CurrentStage = 3
        else
            -- PHẠT QUAY VỀ STAGE 1 NẾU MÁY IM LÌM KHÔNG ĐỔI TRẠNG THÁI
            warn("[❌ STAGE 2 FAILED] Máy im lìm không cập nhật cấu trúc! PHẠT: Lùi về Stage 1.")
            _G.CurrentStage = 1
        end
        
        return true
    else
        print("[⚠️] Không thấy máy phát điện... Lùi về Stage 1.")
        _G.CurrentStage = 1
    end
end
