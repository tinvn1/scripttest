local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- =========================================================================
-- 🔍 HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN
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
-- 🕵️‍♂️ CƠ CHẾ 2.5: SPY CHECK CẬP NHẬT THẾ GIỚI (QUYẾT ĐỊNH ĐI TIẾP HOẶC BỊ PHẠT)
-- =========================================================================
local function verifyGeneratorUpdate(genPart)
    if not genPart then return false end
    
    -- Lấy Model gốc của máy phát điện để dò cấu trúc bên trong
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    local hasWorldUpdate = false
    
    print("[🕵️‍♂️ SPY 2.5] Đang bắt đầu dò thay đổi nhỏ của thế giới tại máy phát điện...")
    
    -- Lắng nghe xem thế giới có nhét thêm đồ hoặc xóa đồ gì trong máy không
    local connectionAdd = genModel.DescendantAdded:Connect(function(descendant)
        print("[⚡ SPY DETECTED] Thế giới cập nhật thêm: " .. descendant.Name)
        hasWorldUpdate = true
    end)
    
    local connectionRemove = genModel.DescendantRemoving:Connect(function(descendant)
        print("[⚡ SPY DETECTED] Thế giới cập nhật bớt: " .. descendant.Name)
        hasWorldUpdate = true
    end)
    
    -- Đợi 5 giây để dò "biến động" của thế giới game xung quanh cái máy
    local startTime = os.clock()
    while (os.clock() - startTime) < 5 do
        if hasWorldUpdate then break end
        task.wait(0.1)
    end
    
    -- Ngắt kết nối để tránh rò rỉ bộ nhớ (Memory Leak)
    connectionAdd:Disconnect()
    connectionRemove:Disconnect()
    
    return hasWorldUpdate
end

-- =========================================================================
-- 🚀 HÀM DI CHUYỂN TWEEN
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
-- 🎮 VÒNG LẶP ĐIỀU KHIỂN CHÍNH (MAIN LOGIC STAGE 2)
-- =========================================================================
print("[STAGE 2] Khởi động luồng kiểm tra di chuyển...")

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    if genPart then
        -- 1. Tiến hành di chuyển tiếp cận máy
        tweenToGenerator(root, genPart)
        
        -- Kích hoạt Prompt của máy phát điện
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
        task.wait(0.5)
        
        -- 2. KÍCH HOẠT CƠ CHẾ KIỂM TRA 2.5 
        local isUpdated = verifyGeneratorUpdate(genPart)
        
        if isUpdated then
            -- NẾU CÓ THAY ĐỔI -> ĐI TIẾP STAGE 3
            print("[🎯 STAGE 2 SUCCESS] Thế giới có Update nhỏ! Hợp lệ -> Chuyển sang Stage 3.")
            _G.CurrentStage = 3
        else
            -- KHÔNG CÓ THAY ĐỔI -> BỊ PHẠT QUAY VỀ STAGE 1
            warn("[❌ STAGE 2 FAILED] Máy im lìm không có update nào của thế giới! PHẠT: Quay về Stage 1.")
            _G.CurrentStage = 1
        end
        return true
    else
        print("[⚠️] Không tìm thấy máy phát điện, trả bot về Stage 1.")
        _G.CurrentStage = 1
    end
end
