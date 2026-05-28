local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = Players.LocalPlayer

print("[📡 STAGE 4] Khởi động trình dò Prompt bền bỉ (Anti-Rejoin Bug)...");

-- HÀM QUÉT ĐỢI (WAITING LOOPS) - CỐ ĐỊNH ĐỂ CHỐNG LỖI REJOIN
local function getPowerBoxPromptReliable()
    local startTime = os.clock()
    -- Chờ tối đa 20 giây cho đến khi Power Box xuất hiện hoàn toàn
    while (os.clock() - startTime) < 20 do
        local descendants = Workspace:GetDescendants()
        for _, obj in pairs(descendants) do
            if obj:IsA("Model") and obj.Name == "Power Box" then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local promptPart = obj:FindFirstChild("Prompt")
                if not prompt and promptPart then
                    prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt")
                end
                
                if prompt then return prompt, prompt.Parent end
            end
        end
        task.wait(0.5) -- Đợi 0.5s giữa các lần quét để không gây lag Mobile
    end
    return nil, nil
end

-- =========================================================================
-- 🔥 LUỒNG THỰC THI CHÍNH
-- =========================================================================
task.spawn(function()
    -- Gọi hàm quét với cơ chế chờ đợi
    local targetPrompt, parentPart = getPowerBoxPromptReliable()

    if targetPrompt and parentPart then
        print("[🎯 DETECTED] Đã thấy Prompt sau khi load: " .. targetPrompt:GetFullName())
        
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        
        if root and parentPart:IsA("BasePart") then
            root.CFrame = CFrame.new(parentPart.Position + Vector3.new(0, 1, 0))
            task.wait(0.5) -- Đợi 1 chút để nhân vật đứng vững
        end
        
        -- Kích hoạt
        pcall(function() targetPrompt:InputHoldBegin() end)
        
        if fireproximityprompt then
            fireproximityprompt(targetPrompt)
        end
        
        pcall(function() ProximityPromptService:NotifyPromptTriggered(targetPrompt) end)
        
        -- Theo dõi sự biến mất của vật thể
        local timeout = 0
        while targetPrompt and targetPrompt.Parent and timeout < 30 do
            task.wait(0.5)
            timeout = timeout + 0.5
        end
        
        pcall(function() targetPrompt:InputHoldEnd() end)
        print("[🎉] STAGE 4 hoàn tất!");
    else
        warn("[⚠️ FAILED] Quá 20 giây vẫn không tìm thấy Power Box. Cần Rejoin hoặc kiểm tra Map.");
    end
end)
