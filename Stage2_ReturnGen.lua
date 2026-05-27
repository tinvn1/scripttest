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
-- 🔥 HÀM CHECK ATTRIBUTE "STAGE" (SPY CHECK XEM MÁY LÊN CẤP 2 CHƯA)
-- =========================================================================
local function checkIsStage2(genPart)
    if not genPart then return false end
    
    -- Lấy Model gốc để đọc Attribute từ dữ liệu ngầm của Server
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    if genModel then
        local currentStage = genModel:GetAttribute("Stage")
        if currentStage then
            print("[🕵️ SPY CHECK] Thuộc tính máy phát điện hiện tại: " .. tostring(currentStage))
            if tonumber(currentStage) >= 2 then
                return true
            end
        end
    end
    return false
end

-- =========================================================================
-- ⚡ LUỒNG XỬ LÝ CHÍNH CỦA STAGE 2
-- =========================================================================
print("[⏳ STAGE 2] Tiếp cận máy phát điện để nạp Fuel...")

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local genPart = getGenerator()

if not root or not genPart then
    warn("[❌ STAGE 2 ERROR] Thất bại mục tiêu! Quay lại Stage 1.")
    _G.CurrentStage = 1
    return false
end

-- 1. 🏃‍♂️ TWEEN DI CHUYỂN MƯỢT ĐẾN MÁY PHÁT ĐIỆN
local dist = (root.Position - genPart.Position).Magnitude
local duration = dist / TWEEN_SPEED
local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(genPart.Position + Vector3.new(0, 2, 0))})

tween:Play()
tween.Completed:Wait()
task.wait(0.2)

-- 2. 🎒 KÍCH HOẠT CẤT FUEL (ĐỔ XĂNG)
print("[🎒] Đang thực hiện tương tác đổ nhiên liệu...")
local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
if prompt and fireproximityprompt then
    fireproximityprompt(prompt)
else
    root.CFrame = CFrame.new(genPart.Position) -- Ép chạm vật lý dự phòng
end

print("[⏳] Đợi 1.5 giây để Server xử lý và cập nhật dữ liệu...")
task.wait(1.5)

-- 3. 🕵️‍♂️ BỘ LỌC SPY CHECK ĐA TẦNG CHỐNG LAG PING SERVER
local isRealStage2 = false

-- Quét 3 lần liên tục (mỗi lần cách nhau 0.5s) để chống lỗi delay dữ liệu từ máy chủ
for attempt = 1, 3 do
    if checkIsStage2(genPart) then
        isRealStage2 = true
        break
    end
    print(string.format("[⚠️ ATTEMPT %d] Chưa nhận thông báo cấp 2 từ Spy, đợi tiếp...", attempt))
    task.wait(0.5)
end

-- 4. 🔀 ĐIỀU HƯỚNG THÔNG MINH THEO KẾT QUẢ SPY CHECK
if isRealStage2 then
    print("[🎯 STAGE 2 SUCCESS] Spy xác nhận: Máy phát điện ĐÃ LÊN CẤP 2! Chuyển tiếp Stage 3.")
    task.wait(0.2)
    _G.CurrentStage = 3 -- Chạy tiếp sang Stage 3
    return true
else
    warn("[❌ STAGE 2 FAILED] Máy vẫn Cấp 1! Thiếu nhiên liệu. Quay lại Stage 1...")
    task.wait(0.2)
    _G.CurrentStage = 1 -- Quay lại Stage 1 tìm thêm xăng
    return false
end
