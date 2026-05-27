local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN (GENERATOR)
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
-- 🔥 HÀM TWEEN DÒ ĐƯỜNG AN TOÀN TỚI MÁY PHÁT ĐIỆN
-- =========================================================================
local function tweenToGenerator(rootPart, genPart)
    if not rootPart or not genPart then return false end
    
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local success, err = pcall(function()
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
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Tiến về máy phát điện để nạp Fuel...")

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    if genPart then
        -- 1. Di chuyển lướt Tween mượt mà đến sát cạnh máy phát điện
        local distance = (root.Position - genPart.Position).Magnitude
        if distance > 4 then
            tweenToGenerator(root, genPart)
        end
        
        -- 2. Thực hiện hành động tương tác đổ xăng vào máy
        local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        else
            root.CFrame = CFrame.new(genPart.Position) -- Ép chạm vật lý để nạp đồ
        end
        
        task.wait(0.8) -- Chờ game xử lý cập nhật trạng thái nhận vật phẩm
        
        -- 3. 🔥 ĐIỀU KIỆN QUYẾT ĐỊNH RẼ NHÁNH LUỒNG
        if isGeneratorFullyLoaded(genPart) then
            -- Trường hợp ĐỦ ĐỒ -> Chuyển giao thẳng lên Stage 3
            print("[🎯 STAGE 2 SUCCESS] Đã xác nhận đủ 2 Fuse/Fuel trên máy phát điện!")
            task.wait(0.2)
            _G.CurrentStage = 3
            return true
        else
            -- Trường hợp THIẾU ĐỒ -> Quay đầu chạy lại Stage 1 ngay lập tức
            print("[⚠️ STAGE 2 FAILED] Máy chưa đủ 2 bình xăng! Tự động kích hoạt lại Stage 1 để đi tìm kiếm tiếp...")
            task.wait(0.2)
            _G.CurrentStage = 1
            return false
        end
    else
        -- Nếu không tìm thấy máy, quay lại Stage 1 quét tài nguyên tránh treo acc
        print("[⚠️] Không tìm thấy máy phát điện, trả luồng về Stage 1...")
        _G.CurrentStage = 1
        return false
    end
end

task.wait(0.2)
