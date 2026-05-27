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
-- 🔥 HÀM DÙNG DỮ LIỆU SPY ĐỂ CHECK XEM GENERATOR ĐÃ LÊN CẤP 2 CHƯA
-- =========================================================================
local function isGeneratorStage2(genPart)
    if not genPart then return false end
    
    -- Lấy Model gốc của máy phát điện (Thường là Parent của Part chính)
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    
    if genModel then
        -- Đọc dữ liệu thuộc tính ẩn "Stage" mà script Spy đã quét được
        local currentStage = genModel:GetAttribute("Stage")
        
        if currentStage then
            print("[🕵️ SYSTEM CHECK] Thuộc tính Stage hiện tại của Generator là: " .. tostring(currentStage))
            -- Nếu giá trị thuộc tính Stage từ 2 trở lên -> Máy đã lên cấp 2 thành công
            if tonumber(currentStage) >= 2 then
                return true
            end
        end
    end
    return false
end

-- =========================================================================
-- 🔥 HÀM DI CHUYỂN TWEEN AN TOÀN
-- =========================================================================
local function tweenToGenerator(root, targetPart)
    local targetPos = targetPart.Position + Vector3.new(0, 2, 0)
    local distance = (root.Position - targetPos).Magnitude
    local duration = distance / TWEEN_SPEED

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
    
    tween:Play()
    tween.Completed:Wait()
end

-- =========================================================================
-- ⚡ LUỒNG XỬ LÝ CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Đang di chuyển về máy phát điện để nạp tài nguyên...")

local genPart = getGenerator()
local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root and genPart then
    -- 1. Tween di chuyển mượt mà áp sát máy phát điện
    local distance = (root.Position - genPart.Position).Magnitude
    if distance > 4 then
        tweenToGenerator(root, genPart)
    end
    
    -- 2. Thực hiện hành động tương tác đổ vật phẩm vào máy
    local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
    else
        root.CFrame = CFrame.new(genPart.Position) -- Ép chạm vật lý để nạp đồ
    end
    
    task.wait(1.0) -- Chờ 1 giây để game xử lý cập nhật dữ liệu máy phát điện từ server
    
    -- 3. 🔥 KIỂM TRA ĐIỀU KIỆN CHUYỂN STAGE THEO DỮ LIỆU ĐÃ SPY
    if isGeneratorStage2(genPart) then
        -- Trường hợp máy ĐÃ LÊN CẤP 2 -> Chuyển sang đi trạm điện Stage 3
        print("[🎯 STAGE 2 SUCCESS] Xác nhận Máy phát điện đã đạt cấp 2! Chuyển sang Stage 3.")
        task.wait(0.2)
        _G.CurrentStage = 3
        return true
    else
        -- Trường hợp máy CHƯA LÊN CẤP 2 -> Quay đầu chạy lại Stage 1 lấy thêm Fuse/Fuel
        print("[⚠️ STAGE 2 FAILED] Máy chưa lên cấp 2! Tự động quay lại Stage 1 để lấy thêm Fuse...")
        task.wait(0.2)
        _G.CurrentStage = 1
        return false
    end
else
    -- Nếu không tìm thấy máy, tự động hồi quy về Stage 1 để chống kẹt acc
    warn("[❌ STAGE 2 ERROR] Không tìm thấy Generator trên bản đồ! Quay lại Stage 1...")
    _G.CurrentStage = 1
    return false
end
