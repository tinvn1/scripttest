local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- Khởi tạo biến toàn cục ngay tại đây để file Main không cần can thiệp
_G.GeneratorLevelUp = false

local function getGenerator()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" or obj.Name == "Gen" or obj.Name == "MainGen" then
            return obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

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

print("[STAGE 2] Đang di chuyển nạp nhiên liệu về máy...")
local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    if genPart then
        -- 1. Tiếp cận máy phát điện
        tweenToGenerator(root, genPart)
        task.wait(0.1)
        
        -- 2. Đăng ký cổng Spy 2.5 lắng nghe thay đổi cấu trúc của Object máy
        local genModel = genPart:IsA("Model") and genPart or genPart.Parent
        local isLevelUp = false
        
        local connAdd = genModel.DescendantAdded:Connect(function() isLevelUp = true end)
        local connRemove = genModel.DescendantRemoving:Connect(function() isLevelUp = true end)
        
        -- 3. Bấm nút tương tác nạp nhiên liệu vật lý
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genModel:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
        
        -- 4. Đứng rình 4.5 giây xem máy có phản hồi biến động cấu trúc lên cấp 2 mở map không
        local startCheck = os.clock()
        while (os.clock() - startCheck) < 4.5 do
            if isLevelUp then break end
            task.wait(0.05)
        end
        
        -- Ngắt kết nối để giải phóng bộ nhớ
        connAdd:Disconnect()
        connRemove:Disconnect()
        
        -- 5. Định đoạt trạng thái và gán vào biến toàn cục truyền tải dữ liệu đi tiếp
        if isLevelUp then
            print("[🎯 SPY SUCCESS] Xác nhận máy đã biến đổi lên cấp thành công!")
            _G.GeneratorLevelUp = true
            _G.CurrentStage = 3
        else
            warn("[❌ SPY FAILED] Máy im lìm không có biến số đổi cấu trúc.")
            _G.GeneratorLevelUp = false
            _G.CurrentStage = 1
        end
    else
        _G.GeneratorLevelUp = false
        _G.CurrentStage = 1
    end
end
return true
