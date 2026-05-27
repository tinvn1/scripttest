local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("[🛠️ STAGE 4] Kích hoạt luồng sửa máy phát điện thế hệ mới...");

-- 🌟 FIX 1: Tăng thời gian nghỉ ban đầu để làm sạch bộ nhớ đệm (Clear Event Queue) từ Stage 3
task.wait(1.0) 

-- =========================================================================
-- 🔥 HÀM TÌM CHÍNH XÁC KHỐI PROMPT CỦA POWER BOX
-- =========================================================================
local function getPowerBoxPromptPart()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Power Box" then
            local promptPart = obj:FindFirstChild("Prompt")
            if promptPart and promptPart:IsA("BasePart") then
                return promptPart
            end
        end
    end
    return nil
end

local promptPart = nil
local startTimeScan = os.clock()

-- 🌟 FIX 2: Quét thông minh không giới hạn số lần (Chờ đến khi tìm thấy hoặc quá 15 giây)
while not promptPart do
    promptPart = getPowerBoxPromptPart()
    if not promptPart then
        -- Nếu quá 15 giây không thấy (Có thể đồng đội đã sửa xong từ trước), tự động chuyển tiếp
        if (os.clock() - startTimeScan) > 15 then
            warn("[⚠️ STAGE 4 TIMEOUT] Không tìm thấy Power Box sau 15 giây. Chuyển thẳng sang Stage 5!");
            _G.CurrentStage = 5
            return false
        end
        task.wait(0.2)
    end
end

print("[🖱️] Đã khóa mục tiêu khối Prompt thành công: " .. promptPart:GetFullName())

-- =========================================================================
-- ⚡ LUỒNG TƯƠNG TÁC LIÊN TỤC VỚI TẦN SUẤT CAO (CHỐNG NUỐT LỆNH)
-- =========================================================================
local repairStarted = true
local startTime = os.clock()

task.spawn(function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    while repairStarted do
        if promptPart and promptPart.Parent then
            -- Ép nhân vật đứng sát và nhìn thẳng vào khối Prompt để không bị hủy tương tác nửa chừng
            if root and root.Parent then
                root.CFrame = CFrame.new(promptPart.Position + Vector3.new(0, 1, i or 0)) * CFrame.Angles(0, 0, 0)
            end

            -- 🌟 FIX 3: Tương tác đa tầng liên tục (Bao gồm ProximityPrompt, ClickDetector và Touch)
            local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt") or promptPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt and fireproximityprompt then
                fireproximityprompt(prompt)
            end
            
            local cd = promptPart:FindFirstChildOfClass("ClickDetector") or promptPart.Parent:FindFirstChildOfClass("ClickDetector")
            if cd and fireclickdetector then
                fireclickdetector(cd)
            end
            
            if firetouchinterest and root then
                firetouchinterest(root, promptPart, 0)
                RunService.Heartbeat:Wait()
                firetouchinterest(root, promptPart, 1)
            end
        end
        -- Chạy tần suất cao bằng Heartbeat phối hợp wait ngắn để thanh tiến trình chạy mượt
        task.wait(0.1) 
    end
end)

-- =========================================================================
-- ⏳ THEO DÕI TIẾN TRÌNH HOÀN THÀNH SỬA MÁY
-- =========================================================================
-- Vòng lặp đếm giờ chính xác 16 giây để hoàn thành tiến trình sửa máy
while (os.clock() - startTime) < 16 do
    -- Nếu khối Prompt biến mất trước thời hạn (Đồng đội sửa xong hoặc mình vừa hoàn tất thanh tiến trình)
    if not promptPart or not promptPart.Parent then
        print("[🎯 STAGE 4 SUCCESS] Khối Prompt biến mất sớm. Sửa máy thành công!")
        break
    end
    RunService.Heartbeat:Wait()
end

-- Dọn dẹp luồng tương tác và bàn giao thần tốc cho Stage 5
repairStarted = false
print("[🎯 STAGE 4 SUCCESS] Hoàn tất thời gian sửa máy quy định!")

task.wait(0.2)
return true
