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
-- 🔥 HÀM CHECK ATTRIBUTE "STAGE" (XEM MÁY ĐÃ ĐẠT CẤP 2 THỰC SỰ CHƯA)
-- =========================================================================
local function checkIsStage2(genPart)
    if not genPart then return false end
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    if genModel then
        local currentStage = genModel:GetAttribute("Stage")
        if currentStage then
            print("[🕵️ SPY CHECK] Giá trị thuộc tính 'Stage' đọc được: " .. tostring(currentStage))
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
    
    print("[⏳] Đang đợi 1.5 giây để Server cập nhật và thẩm định dữ liệu nâng cấp...")
    task.wait(1.5) -- Tăng thời gian chờ ban đầu để animation đổ đồ chạy xong hoàn toàn
    
    -- 3. 🔥 BỘ LỌC KIỂM TRA ĐA TẦNG CHỐNG NHẢY VƯỢT STAGE LỖI
    local isRealStage2 = false
    
    -- Vòng lặp check lại 3 lần liên tục để tránh trường hợp nhận diện sai do lag ping
    for attempt = 1, 3 do
        if checkIsStage2(genPart) then
            isRealStage2 = true
            break -- Nếu thấy lên cấp thật thì thoát vòng lặp ngay
        end
        print(string.format("[⚠️ ATTEMPT %d] Chưa thấy máy lên cấp 2, kiểm tra lại sau 0.5s...", attempt))
        task.wait(0.5)
    end
    
    -- 4. QUYẾT ĐỊNH RẼ NHÁNH CHUẨN XÁC
    if isRealStage2 then
        print("[🎯 STAGE 2 SUCCESS] Xác nhận Máy phát điện ĐÃ LÊN CẤP 2! Bàn giao sang Stage 3.")
        task.wait(0.2)
        _G.CurrentStage = 3
        return true
    else
        print("[⚠️ STAGE 2 FAILED] Máy CHƯA lên cấp 2 thực sự! Ép luồng trả về Stage 1 lấy thêm Fuse.")
        task.wait(0.2)
        _G.CurrentStage = 1
        return false
    end
else
    warn("[❌ STAGE 2 ERROR] Không tìm thấy Generator! Quay lại Stage 1 để bảo vệ luồng...")
    _G.CurrentStage = 1
    return false
end
