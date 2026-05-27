local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("[🛠️ STAGE 4] Kích hoạt luồng sửa máy thế hệ mới - Siêu mượt...");
task.wait(0.5) 

-- =========================================================================
-- 🔍 HÀM TÌM KIẾM PROMPT (ĐÃ TỐI ƯU HÓA)
-- =========================================================================
local function getPowerBoxPromptPart()
    -- Thay vì quét vô điều kiện, tìm kiếm trực tiếp mô hình mang tên Power Box
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            local promptPart = obj:FindFirstChild("Prompt") or obj:FindFirstChildWhichIsA("BasePart")
            if promptPart then return promptPart end
        end
    end
    return nil
end

local promptPart = nil
local startTimeScan = os.clock()

-- Tăng thời gian chờ lên 0.5s để giảm tải tối đa cho CPU tránh giật lag khi quét map
while not promptPart do
    promptPart = getPowerBoxPromptPart()
    if not promptPart then
        if (os.clock() - startTimeScan) > 15 then
            warn("[⚠️ STAGE 4 TIMEOUT] Không tìm thấy Power Box. Bỏ qua sang Stage 5!");
            _G.CurrentStage = 5
            return false
        end
        task.wait(0.5) -- Giảm tần suất quét xuống 0.5 giây/lần
    end
end

print("[🖱️] Đã khóa mục tiêu khối Prompt thành công: " .. promptPart:GetFullName())

local repairStarted = true
local startTime = os.clock()
local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

-- =========================================================================
-- ⚡ LUỒNG TƯƠNG TÁC CHỐNG GIẬT LAG (ANCHORED)
-- =========================================================================
task.spawn(function()
    if not root or not promptPart then return end
    
    -- 🔒 Băng cứng nhân vật tại điểm sửa để CHỐNG GIẬT LAG vật lý và chống văng
    root.CFrame = CFrame.new(promptPart.Position + Vector3.new(0, 2, 0))
    root.Anchored = true 

    while repairStarted and promptPart and promptPart.Parent do
        -- 1. Xử lý ProximityPrompt (Ưu tiên số 1)
        local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt") or promptPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            -- Mở khóa rào cản khoảng cách và tầm nhìn của game để bấm phát ăn ngay
            if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end
            if prompt.MaxActivationDistance < 30 then prompt.MaxActivationDistance = 50 end
            
            if fireproximityprompt then fireproximityprompt(prompt) end
        end
        
        -- 2. Xử lý ClickDetector (Nếu có)
        local cd = promptPart:FindFirstChildOfClass("ClickDetector") or promptPart.Parent:FindFirstChildOfClass("ClickDetector")
        if cd and fireclickdetector then
            fireclickdetector(cd)
        end
        
        -- 3. Gửi tín hiệu TouchInterest giả lập chạm vật lý (Nếu có)
        local touch = promptPart:FindFirstChildOfClass("TouchTransmitter") or promptPart.Parent:FindFirstChildOfClass("TouchTransmitter")
        if touch and firetouchinterest then
            pcall(function()
                firetouchinterest(root, promptPart, 0)
                task.wait()
                firetouchinterest(root, promptPart, 1)
            end)
        end
        
        task.wait(0.15) -- Giờ nghỉ nhỏ để tránh flood dữ liệu lên server
    end
    
    -- 🔓 Mở khóa nhân vật khi sửa xong để có thể di chuyển tiếp sang Stage 5
    if root then root.Anchored = false end
end)

-- =========================================================================
-- ⏱️ VÒNG LẶP KIỂM SOÁT THỜI GIAN HOÀN THÀNH
-- =========================================================================
while (os.clock() - startTime) < 16 do
    if not promptPart or not promptPart.Parent then
        print("[🎯 STAGE 4 SUCCESS] Khối Prompt biến mất sớm. Sửa máy thành công!")
        break
    end
    RunService.Heartbeat:Wait()
end

repairStarted = false
if root then root.Anchored = false end -- Đảm bảo luôn mở khóa khi kết thúc hàm

print("[🎯 STAGE 4 SUCCESS] Hoàn tất tiến trình Stage 4!")
task.wait(0.2)
_G.CurrentStage = 5
return true
