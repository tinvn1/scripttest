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
        -- Chỉ lọc đúng tên Generator, bỏ qua mọi logic gara
        if obj.Name == "Generator" or obj.Name == "Gen" or obj.Name == "MainGen" then
            return obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

-- =========================================================================
-- 🔥 HÀM KIỂM TRA MÁY (TỐI GIẢN)
-- =========================================================================

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
        for _, waypoint in ipairs(path:GetWaypoints()) do
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
        tweenToGenerator(root, genPart)
        
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
        
        task.wait(1)
        
        -- Chuyển Stage 3 thẳng sau khi tương tác
        print("[🎯 STAGE 2 DONE] Chuyển tiếp sang Stage 3.")
        _G.CurrentStage = 3
        return true
    else
        print("[⚠️] Không thấy máy phát điện.")
        _G.CurrentStage = 1
        return false
    end
end
