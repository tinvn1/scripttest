-- ====================================================================
-- BƯỚC ĐỆM: CHECK FUEL (CÓ CƠ CHẾ TIMEOUT QUAY LẠI STAGE 1)
-- ====================================================================

local TIMEOUT_DURATION = 10 -- Giới hạn thời gian chờ 60 giây
local hasTriggered = false
local startTime = tick()

-- Hàm xử lý quay lại Stage 1 khi hết thời gian
local function abortAndReturnToStage1()
    if hasTriggered then return end
    hasTriggered = true
    
    warn("⏳ [TIMEOUT] Không tìm thấy CrateOpened trong " .. TIMEOUT_DURATION .. "s. Quay lại STAGE 1...")
    
    -- Dọn dẹp UI
    local player = game:GetService("Players").LocalPlayer
    local ui = player.PlayerGui:FindFirstChild("CheckFuelUI")
    if ui then ui:Destroy() end
    
    -- Quay lại Stage 1
    _G.CurrentStage = 1
end

-- Hàm xử lý chuyển tiếp sang Stage 3 (Giữ nguyên như cũ)
local function loadStage3()
    if hasTriggered then return end
    hasTriggered = true 
    
    print("🚨 [CHECK FUEL SUCCESS] Tìm thấy tín hiệu CrateOpened!");
    -- ... (giữ nguyên đoạn code loadStage3 của bạn ở đây) ...
    task.spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/Stage3_RepairBox.lua"))()
        end)
        if not success then warn("Lỗi tải Stage 3: " .. tostring(err)) end
    end)
end

-- THÊM VÒNG LẶP KIỂM TRA THỜI GIAN (TIMEOUT MONITOR)
task.spawn(function()
    while not hasTriggered do
        task.wait(1)
        if (tick() - startTime) > TIMEOUT_DURATION then
            abortAndReturnToStage1()
            break
        end
    end
end)

-- ... (Phần logic Hook Metatable hoặc Quét Map giữ nguyên như cũ) ...
