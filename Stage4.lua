local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = Players.LocalPlayer

print("[🛠️ STAGE 4] Kích hoạt luồng Sửa Máy Phát thế hệ mới - Đã FIX LỖI MOBILE...");
task.wait(0.5) 

-- =========================================================================
-- HÀM ĐỊNH VỊ KHỐI PROMPT CỦA MÁY PHÁT ĐIỆN
-- =========================================================================
local function getPowerBoxPromptPart()
    local descendants = Workspace:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
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

-- Vòng lặp quét mục tiêu dứt khoát ban đầu
while not promptPart do
    promptPart = getPowerBoxPromptPart()
    if not promptPart then
        if (os.clock() - startTimeScan) > 15 then
            warn("[⚠️ STAGE 4 TIMEOUT] Không tìm thấy Power Box sau 15 giây. Nhảy Stage!");
            _G.CurrentStage = 5
            return false
        end
        task.wait(0.1)
    end
end

print("[🖱️ TARGET LOCKED] Đã khóa tọa độ máy phát điện!")

local repairStarted = true
local startTime = os.clock()
-- Đứng sát phía trên mục tiêu một chút để đảm bảo khoảng cách tương tác luôn chuẩn xác
local targetPosition = promptPart.Position + Vector3.new(0, 1.2, 0) 

-- =========================================================================
-- 🔥 LUỒNG TƯƠNG TÁC ỔN ĐỊNH CHO CẢ PC VÀ MOBILE (ANTI-PATCH)
-- =========================================================================
task.spawn(function()
    -- Cố định vị trí nhân vật ngay lập tức bằng CFrame để tránh bị MoveTo làm khựng hành động
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.lookAt(targetPosition, promptPart.Position)
        task.wait(0.1)
    end

    -- Gửi lệnh đè phím E ban đầu (Dành cho PC)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    end)

    while repairStarted do
        char = localPlayer.Character
        root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if not promptPart or not promptPart.Parent then 
            break 
        end
        
        if root and humanoid and humanoid.Health > 0 then
            -- Giữ CFrame quay mặt vào máy mà không dùng MoveTo gây kẹt phím trên Mobile
            root.CFrame = CFrame.lookAt(targetPosition, promptPart.Position)
            root.AssemblyLinearVelocity = Vector3.zero 
            
            local prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt") 
                or promptPart.Parent:FindFirstChildWhichIsA("ProximityPrompt")
            
            if prompt then
                -- Gọi lệnh giữ phím hệ thống
                pcall(function()
                    prompt:InputHoldBegin()
                end)
                
                -- Kích nổ tín hiệu Prompt (Bypass Mobile cực mạnh)
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                end
                
                pcall(function()
                    ProximityPromptService:NotifyPromptTriggered(prompt)
                end)
            end
            
            -- Chạm vật lý an toàn chống Check-Distance từ Server
            if firetouchinterest then
                firetouchinterest(root, promptPart, 0)
                task.wait(0.02)
                firetouchinterest(root, promptPart, 1)
            end
        else
            task.wait(0.5)
        end
        
        -- Nhịp chờ 0.2 giây vừa đủ nhanh để nạp tiến trình nhưng không làm quá tải băng thông
        task.wait(0.2) 
    end

    -- GIẢI PHÓNG TOÀN BỘ PHÍM KHI XONG VIỆC
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    
    local prompt = promptPart and (promptPart:FindFirstChildWhichIsA("ProximityPrompt") or promptPart.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
    if prompt then
        pcall(function() prompt:InputHoldEnd() end)
    end
end)

-- =========================================================================
-- VÒNG LẶP KIỂM TRA ĐỒNG BỘ THƯỞNG
-- =========================================================================
local maxWaitTime = 18 
local bonusDelay = 1.5 
local promptDisappeared = false

while (os.clock() - startTime) < maxWaitTime do
    if not promptPart or not promptPart.Parent then
        if not promptDisappeared then
            print("[💎 INSURANCE] Máy phát đã biến mất! Chờ Server trả kim cương...")
            promptDisappeared = true
            task.wait(bonusDelay)
            break
        end
    end
    RunService.Heartbeat:Wait()
end

repairStarted = false
print("[🎉 STAGE 4 SUCCESS] Sửa máy phát điện hoàn tất!");

task.wait(0.3)
_G.CurrentStage = 5
return true
