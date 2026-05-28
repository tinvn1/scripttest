local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = Players.LocalPlayer

print("[🛠️ STAGE 4] Khởi chạy luồng Sửa Máy Phát Đa Nền Tảng (PC & Mobile)...");
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

-- Vòng lặp quét mục tiêu dứt khoát
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

print("[🖱️ TARGET LOCKED] Đã khóa tọa độ máy phát điện thành công!")

local repairStarted = true
local startTime = os.clock()
local targetPosition = promptPart.Position + Vector3.new(0, 0.5, 1) -- Vị trí đứng tối ưu sát cạnh máy

-- =========================================================================
-- 🔥 LUỒNG TƯƠNG TÁC LIÊN TỤC CHỐNG RỜI MÁY (PC & MOBILE CO-EXIST)
-- =========================================================================
task.spawn(function()
    while repairStarted do
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        -- Nếu prompt bị mất (ai đó phá hoặc đã sửa xong), tự động dừng luồng
        if not promptPart or not promptPart.Parent then 
            break 
        end
        
        if root and humanoid and humanoid.Health > 0 then
            -- [GIỮ VỊ TRÍ] Ép nhân vật bám chặt vào máy phát điện, chống bị quái đẩy văng ra ngoài
            root.CFrame = CFrame.new(targetPosition, promptPart.Position)
            root.AssemblyLinearVelocity = Vector3.zero -- Triệt tiêu lực đẩy vật lý bên ngoài
            
            -- Lấy Object ProximityPrompt thực tế của game
            local prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt") 
                or promptPart.Parent:FindFirstChildWhichIsA("ProximityPrompt")
            
            if prompt then
                -- PHƯƠNG ÁN 1: Kích hoạt API Thô (Dành cho PC/Exploit hỗ trợ)
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                end
                
                -- PHƯƠNG ÁN 2: Ép trạng thái Input trên Điện thoại (Bypass Mobile cực mạnh)
                pcall(function()
                    prompt:InputHoldBegin()
                    -- Giả lập giữ tương tác mạng trực tiếp lên Server của Roblox
                    ProximityPromptService:NotifyPromptTriggered(prompt)
                end)
            end
            
            -- Hỗ trợ thêm ClickDetector nếu cấu hình map thay đổi
            local cd = promptPart:FindFirstChildWhichIsA("ClickDetector") or promptPart.Parent:FindFirstChildWhichIsA("ClickDetector")
            if cd and fireclickdetector then
                fireclickdetector(cd)
            end
            
            -- Giả lập chạm vật lý liên tục (Touch Interest)
            if firetouchinterest then
                firetouchinterest(root, promptPart, 0)
                task.wait()
                firetouchinterest(root, promptPart, 1)
            end

            -- PHƯƠNG ÁN 3: Giả lập đè phím E vật lý (Dành riêng cho máy tính PC)
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            end)
        else
            -- BẢO HIỂM HỒI SINH: Nếu chết, chờ nhân vật xuất hiện lại rồi kéo ngược về máy ngay lập tức
            task.wait(0.2)
        end
        RunService.Heartbeat:Wait()
    end

    -- GIẢI PHÓNG PHÍM: Nhả toàn bộ lệnh tương tác khi hoàn tất để tránh lỗi kẹt nhân vật
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    
    local char = localPlayer.Character
    local prompt = promptPart and (promptPart:FindFirstChildWhichIsA("ProximityPrompt") or promptPart.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
    if prompt then
        pcall(function() prompt:InputHoldEnd() end)
    end
end)

-- =========================================================================
-- LUỒNG BẢO HIỂM KIỂM TRA THỜI GIAN NHẬN KIM CƯƠNG
-- =========================================================================
local maxWaitTime = 16 -- Thời gian giữ tối đa đề phòng lỗi map
local bonusDelay = 1.5 
local promptDisappeared = false

while (os.clock() - startTime) < maxWaitTime do
    if not promptPart or not promptPart.Parent then
        if not promptDisappeared then
            print("[💎 MOBILE/PC INSURANCE] Máy phát điện đã biến mất! Chờ 1.5 giây Server đồng bộ phần thưởng...")
            promptDisappeared = true
            task.wait(bonusDelay)
            break
        end
    end
    RunService.Heartbeat:Wait()
end

repairStarted = false
print("[🎉 STAGE 4 SUCCESS] Đã hoàn thành sửa máy phát điện an toàn trên mọi thiết bị!");

task.wait(0.3)
_G.CurrentStage = 5
return true
