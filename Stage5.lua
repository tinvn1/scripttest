local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- =========================================================================
-- 🔥 HÀM CLICK THẦN TỐC (CHẠY KHÔNG DELAY)
-- =========================================================================
local function secureClickThantoc(button)
    if not button then return false end
    if not button.Visible or button.AbsoluteSize.X == 0 or button.AbsoluteSize.Y == 0 then [cite: 32]
        return false
    end

    print("[Action] Kích hoạt chuỗi click thần tốc cho: " .. button.Name) [cite: 32]
    
    -- Kích hoạt ngay lập tức tất cả kết nối mà không dùng vòng lặp chờ giây
    if getconnections then
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do connection:Fire() end [cite: 33]
        for _, connection in pairs(getconnections(button.MouseButton1Down)) do connection:Fire() end [cite: 33, 34]
    end
    button.MouseButton1Click:Fire() [cite: 34]
    return true
end

-- =========================================================================
-- ⏳ LUỒNG THEO DÕI GIAO DIỆN VÀ REJOIN THẦN TỐC
-- =========================================================================
print("[⏳ STAGE 5] Kích hoạt quét UI và Rejoin siêu tốc...") [cite: 34, 35]

task.spawn(function()
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    local startTime = os.clock()
    
    -- Vòng lặp quét tần suất cực cao bằng Heartbeat (Thay vì chờ 0.3 giây lề mề)
    while not foundButton and (os.clock() - startTime) < 20 do
        for _, obj in pairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then [cite: 36]
                if obj.Visible and obj.AbsolutePosition.Y > 0 then [cite: 36]
                    foundButton = obj
                    break
                end
            end
        end
        if foundButton then break end
        RunService.Heartbeat:Wait() -- Chờ theo khung hình (mili-giây) để tìm thấy nút sớm nhất có thể
    end
    
    -- Xử lý Rejoin ngay khi thấy nút
    if foundButton then
        print("[🎯 SUCCESS] Tìm thấy nút Play Again. Thực hiện nhấn và nhảy server tức thì...") [cite: 37, 38]
        
        -- Kích hoạt click thần tốc
        secureClickThantoc(foundButton)
        
        -- Ép luồng Teleport chạy ngay lập tức không trì hoãn 1.2 giây như cũ
        print("[🚀] Thực hiện Rejoin Bypass...") [cite: 39]
        local teleportOptions = Instance.new("TeleportOptions") [cite: 39]
        teleportOptions.ServerInstanceId = game.JobId [cite: 39]
        
        local success, err = pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions) [cite: 39]
        end)
        
        if not success then 
            warn("[Error] Lỗi Rejoin: " .. tostring(err))  [cite: 40]
        end
    else
        warn("[Timeout] Quá thời gian chờ nhưng không thấy nút Play Again xuất hiện!") [cite: 40]
    end
end)
