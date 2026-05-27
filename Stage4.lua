local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("[🛠️ STAGE 4] Kích hoạt luồng sửa máy thế hệ mới - Siêu mượt, không lag...");
task.wait(0.2) 

-- =========================================================================
-- 🔍 HÀM TÌM KIẾM MỤC TIÊU TỐI ƯU (KHÔNG DÙNG GETDESCENDANTS TOÀN MAP)
-- =========================================================================
local function getPowerBoxPromptPart()
    -- Cách 1: Tìm kiếm nhanh trong các thư mục chính của Workspace trước
    local topLevels = {"Map", "Models", "Debris", "Workspace"}
    for _, name in ipairs(topLevels) do
        local container = (name == "Workspace") and Workspace or Workspace:FindFirstChild(name)
        if container then
            -- Chỉ tìm những vật thể có tên "Power Box" ở tầng nông trước
            for _, obj in ipairs(container:GetChildren()) do
                if obj.Name == "Power Box" then
                    local promptPart = obj:FindFirstChild("Prompt") or obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
                    if promptPart then return promptPart end
                end
            end
        end
    end

    -- Cách 2: Dự phòng (Fallback) quét hẹp bằng GetDescendants nhưng giới hạn thời gian qua vòng lặp ngoài
    local items = Workspace:GetChildren()
    for i = 1, #items do
        local item = items[i]
        if item.Name == "Power Box" then
            local promptPart = item:FindFirstChild("Prompt") or item:FindFirstChildWhichIsA("BasePart")
            if promptPart then return promptPart end
        elseif not item:IsA("Terrain") and not item:IsA("Camera") then
            -- Quét sâu hơn ở các Model lớn cụ thể
            local pBox = item:FindFirstChild("Power Box", true)
            if pBox then
                local promptPart = pBox:FindFirstChild("Prompt") or pBox:FindFirstChildWhichIsA("BasePart")
                if promptPart then return promptPart end
            end
        end
    end
    return nil
end

local promptPart = nil
local startTimeScan = os.clock()

-- Vòng lặp chờ khóa mục tiêu (tăng thời gian nghỉ để CPU không bị quá tải)
while not promptPart do
    promptPart = getPowerBoxPromptPart()
    if not promptPart then
        if (os.clock() - startTimeScan) > 12 then
            warn("[⚠️ STAGE 4 TIMEOUT] Không tìm thấy Power Box. Chuyển cấp tốc sang Stage 5!");
            _G.CurrentStage = 5
            return false
        end
        task.wait(0.5) -- Nghỉ hẳn 0.5 giây để hạ nhiệt CPU
    end
end

print("[🖱️] Khóa mục tiêu thành công: " .. promptPart:GetName())

local repairStarted = true
local startTime = os.clock()
local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

-- =========================================================================
-- ⚡ LUỒNG TƯƠNG TÁC THÔNG MINH - CHỐNG FLOOD NETWORK
-- =========================================================================
task.spawn(function()
    if not root or not promptPart then return end
    
    -- 🔒 Di chuyển mượt và Neo nhân vật tại vị trí an toàn (Cách trạm điện một khoảng ngắn)
    local targetPos = promptPart.Position + Vector3.new(0, 1.5, 0)
    root.CFrame = CFrame.new(targetPos)
    task.wait(0.1) -- Chờ 0.1 giây để Server đồng bộ vị trí xong rồi mới Neo
    root.Anchored = true 

    -- Tìm sẵn các Instance tương tác để không phải gọi hàm FindFirstChild liên tục trong vòng lặp
    local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt") or promptPart.Parent:FindFirstChildOfClass("ProximityPrompt")
    local cd = promptPart:FindFirstChildOfClass("ClickDetector") or promptPart.Parent:FindFirstChildOfClass("ClickDetector")
    local touch = promptPart:FindFirstChildOfClass("TouchTransmitter") or promptPart.Parent:FindFirstChildOfClass("TouchTransmitter")

    -- Cấu hình trước các thông số của Prompt để bẻ khóa giới hạn khoảng cách
    if prompt then
        if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end
        if prompt.MaxActivationDistance < 40 then prompt.MaxActivationDistance = 60 end
    end

    -- Vòng lặp kích hoạt chính
    while repairStarted and promptPart and promptPart.Parent do
        
        -- 1. Ưu tiên số 1: ProximityPrompt
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
        end
        
        -- 2. Ưu tiên số 2: ClickDetector
        if cd and fireclickdetector then
            fireclickdetector(cd)
        end
        
        -- 3. Ưu tiên số 3: TouchInterest (Giãn cách thời gian hợp lý tránh Lag)
        if touch and firetouchinterest then
            pcall(function()
                firetouchinterest(root, promptPart, 0)
                runService.Heartbeat:Wait() -- Chờ khung hình vật lý thay vì task.wait() tránh nghẽn luồng
                firetouchinterest(root, promptPart, 1)
            end)
        end
        
        task.wait(0.2) -- Tăng nhẹ lên 0.2s: Vừa đủ nhanh để hoàn thành QTE/Sửa máy, vừa triệt tiêu hiện tượng lag mạng
    end
    
    -- 🔓 Giải phóng nhân vật
    if root then root.Anchored = false end
end)

-- =========================================================================
-- ⏱️ VÒNG LẶP THEO DÕI TIẾN ĐỘ SỬA MÁY
-- =========================================================================
while (os.clock() - startTime) < 15 do
    if not promptPart or not promptPart.Parent then
        print("[🎯 STAGE 4 SUCCESS] Trạm điện đã biến mất/Đã sửa xong!")
        break
    end
    task.wait(0.1) -- Sử dụng task.wait(0.1) thay cho Heartbeat:Wait() giúp giải phóng tối đa tài nguyên render cho máy yếu
end

repairStarted = false
if root then root.Anchored = false end

print("[🎯 STAGE 4 SUCCESS] Hoàn tất tiến trình Stage 4 mượt mà!");
task.wait(0.1)
_G.CurrentStage = 5
return true
