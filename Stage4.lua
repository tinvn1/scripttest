local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

-- =========================================================================
-- ⏳ CẤU HÌNH STAGE 4: CHỜ 3 GIÂY RỒI TỰ ĐỘNG GIỮ TÂM MÀN HÌNH
-- =========================================================================
task.spawn(function()
    -- Thông báo trạng thái chờ
    StarterGui:SetCore("SendNotification", {
        Title = "Stage 4 - Auto Hold",
        Text = "Đang chờ 3 giây để chuẩn bị giữ...",
        Duration = 3
    })
    
    task.wait(3) -- Chờ đúng 3 giây theo yêu cầu của bạn

    -- Lấy tọa độ chính giữa màn hình điện thoại/PC
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    -- Thông báo bắt đầu giữ
    StarterGui:SetCore("SendNotification", {
        Title = "Stage 4 - Auto Hold",
        Text = "Bắt đầu giữ tâm màn hình trong 19 giây!",
        Duration = 3
    })

    -- Kích hoạt vòng lặp giữ trong 19 giây
    local startTime = tick()
    while tick() - startTime < 19 do
        -- Giả lập hành động nhấn xuống (true) tại tâm màn hình
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.1) -- Duy trì lệnh nhấn liên tục để tránh bị tuột
    end
    
    -- Sau 19 giây, thực hiện nhấc ra (false)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    
    -- Thông báo hoàn thành
    StarterGui:SetCore("SendNotification", {
        Title = "Stage 4 - Auto Hold",
        Text = "Đã giữ đủ 19 giây và tự động thả!",
        Duration = 3
    })
end)

-- =========================================================================
-- 🔌 PHẦN LOGIC AUTO TRIGGER PROXIMITY PROMPT (GIỮ NGUYÊN CỦA BẠN)
-- =========================================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = Players.LocalPlayer

print("[📡 PROMPT DETECTOR] Đang khởi chạy trình dò và ép kích hoạt nút E tương tác (Cấu hình: Lặp 10 lần)...");

local function findPowerBoxPrompt()
    local descendants = Workspace:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
        
        if obj:IsA("Model") and obj.Name == "Power Box" then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if not prompt then
                local promptPart = obj:FindFirstChild("Prompt")
                if promptPart then
                    prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt")
                end
            end
            
            if prompt then
                return prompt, prompt.Parent
            end
        end
    end
    return nil, nil
end

-- Luồng thực thi quét Power Box 10 lần độc lập với luồng giữ màn hình ở trên
task.spawn(function()
    for loopCount = 1, 10 do
        print(string.format("\n[🔄 LƯỢT %d / 10] Đang tiến hành quét mục tiêu...", loopCount))
        
        local targetPrompt, parentPart = findPowerBoxPrompt()

        if targetPrompt and parentPart then
            print(string.format("[🎯 DETECTED - LƯỢT %d] Đã phát hiện nút E tại: %s", loopCount, targetPrompt:GetFullName()))
            
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and parentPart:IsA("BasePart") then
                root.CFrame = CFrame.new(parentPart.Position + Vector3.new(0, 1, 0))
                task.wait(0.1)
            end
            
            pcall(function()
                targetPrompt:InputHoldBegin()
            end)
            
            if fireproximityprompt then
                fireproximityprompt(targetPrompt)
                print("[⚡] Đã gửi lệnh fireproximityprompt thành công!")
            end
            
            pcall(function()
                ProximityPromptService:NotifyPromptTriggered(targetPrompt)
            end)
            
            local maxDuration = 15
            local elapsed = 0
            while targetPrompt and targetPrompt.Parent and elapsed < maxDuration do
                task.wait(0.2)
                elapsed = elapsed + 0.2
            end
            
            pcall(function()
                targetPrompt:InputHoldEnd()
            end)
            print(string.format("[🎉] Kết thúc tương tác lượt thứ %d!", loopCount));
        else
            warn(string.format("[⚠️ NOT FOUND - LƯỢT %d] Không thấy đối tượng Power Box nào xuất hiện.", loopCount));
        end
        
        task.wait(0.5)
    end
    print("\n[🏁 HOÀN THÀNH] Đã chạy đủ 10 lần lập định. Hệ thống tự động dừng script.");
end)
