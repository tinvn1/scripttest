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
-- 🔥 HÀM DI CHUYỂN TWEEN ĐƯA NHIÊN LIỆU VỀ MÁY
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
-- VÒNG LẶP HÀNH ĐỘNG CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Đang di chuyển nạp nhiên liệu về máy phát điện...")

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    if genPart then
        -- 1. Chạy tới máy phát điện
        tweenToGenerator(root, genPart)
        task.wait(0.2)
        
        -- 2. Chỉ phụ trách tương tác đút nhiên liệu vào máy để kích hoạt mở map
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
            print("[⚡ STAGE 2] Đã nạp nhiên liệu thành công! Chuyển giao luồng check cấp cho Spy 2.5.")
        end
        
        -- 3. Gọi ngay cơ chế Check 2.5 chạy song song kiểm tra xem máy lên cấp mở map chưa
        _G.ActivateSpy25(genPart)
    else
        warn("[⚠️ STAGE 2] Không thấy máy phát điện! Hạ về Stage 1.")
        _G.CurrentStage = 1
    end
end

return true
