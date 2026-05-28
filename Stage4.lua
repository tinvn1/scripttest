local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = Players.LocalPlayer

print("[🛠️ STAGE 4] Kích hoạt luồng Sửa Máy Phát thế hệ mới - Chống chặn tương tác...");
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
local targetPosition = promptPart.Position + Vector3.new(0, 0, 1.2) -- Đứng cách máy 1.2 studs cực kỳ tự nhiên

-- =========================================================================
-- 🔥 LUỒNG TƯƠNG TÁC ỔN ĐỊNH CHỐNG CHẶN (ANTI-PATCH)
-- =========================================================================
task.spawn(function()
    -- Gửi lệnh đè phím E ban đầu (Dành cho PC)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    end)

    while repairStarted do
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if not promptPart or not promptPart.Parent then 
            break 
        end
        
        if root and humanoid and humanoid.Health > 0 then
            -- THAY THẾ KHÓA CỨNG: Di chuyển liên tục về hướng máy phát điện và quay mặt vào máy
            humanoid:MoveTo(targetPosition)
            root.CFrame = CFrame.lookAt(root.Position, promptPart.Position)
            root.AssemblyLinearVelocity = Vector3.zero -- Triệt tiêu lực đẩy để không bị lệch tâm
            
            local prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt") 
                or promptPart.Parent:FindFirstChildWhichIsA("ProximityPrompt")
            
            if prompt then
                -- PHƯƠNG ÁN CHUẨN: Giả lập nhấn đè thay vì spam liên tục để tránh Server từ chối lệnh
                pcall(function()
                    prompt:InputHoldBegin()
                end)
                
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                end
                
                -- Tạo độ trễ mạng tự nhiên cho Mobile
                pcall(function()
                    ProximityPromptService:NotifyPromptTriggered(prompt)
                end)
            end
            
            -- Chạm vật lý an toàn
            if firetouchinterest then
                firetouchinterest(root, promptPart, 0)
                task.wait(0.02)
                firetouchinterest(root, promptPart, 1)
            end
        else
            -- Đợi hồi sinh nếu bị quái đánh chết và tiếp tục kéo về máy sửa tiếp
            task.wait(0.5)
        end
        
        -- GIẢM TẦN SUẤT QUÉT: Thay vì chạy theo khung hình (Heartbeat), đổi sang 0.25 giây/lần
        -- Việc này giúp bypass hoàn toàn bộ lọc Spam tương tác của chống hack
        task.wait(0.25) 
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
local maxWaitTime = 18 -- Tăng nhẹ thời gian bảo hiểm sửa máy lên 18 giây do có delay chống chặn
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
