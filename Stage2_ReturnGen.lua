local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

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
        
        -- 2. Kích hoạt cổng Spy 2.5 rình cấu trúc thay đổi nhỏ
        local genModel = genPart:IsA("Model") and genPart or genPart.Parent
        local isLevelUp = false
        
        local connAdd = genModel.DescendantAdded:Connect(function() isLevelUp = true end)
        local connRemove = genModel.DescendantRemoving:Connect(function() isLevelUp = true end)
        
        -- 3. Thực hiện bấm nút nạp nhiên liệu mở map
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genModel:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
        
        -- 4. Chờ 4.5 giây xem thế giới game có phản hồi biến số nhỏ nào không
        local startCheck = os.clock()
        while (os.clock() - startCheck) < 4.5 do
            if isLevelUp then break end
            task.wait(0.05)
        end
        
        connAdd:Disconnect()
        connRemove:Disconnect()
        
        -- 5. Trả kết quả về biến toàn cục cho Stage sau check
        if isLevelUp then
            print("[🎯 SPY SUCCESS] Xác nhận máy phát điện đã lên cấp 2 thành công!")
            _G.GeneratorLevelUp = true
            _G.CurrentStage = 3
        else
            warn("[❌ SPY FAILED] Máy im lìm không lên cấp.")
            _G.GeneratorLevelUp = false
            _G.CurrentStage = 1
        end
    else
        _G.GeneratorLevelUp = false
        _G.CurrentStage = 1
    end
end
return true
