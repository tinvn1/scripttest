local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local localPlayer = Players.LocalPlayer

-- =========================================================================
-- 🔥 HÀM CLICK BỌC LÓT (ANTI-MISS CLICK & BYPASS UI)
-- =========================================================================
local function secureClick(button)
    if not button then return false end
    
    -- Điều kiện tiên quyết: Nút phải thực sự hiển thị trên màn hình
    if not button.Visible or button.AbsoluteSize.X == 0 or button.AbsoluteSize.Y == 0 then
        return false
    end

    print("[Action] Kích hoạt chuỗi click bọc lót cho: " .. button.Name)
    
    -- Thử kích hoạt 3 lần liên tiếp (kép cả Click và Down) để chống nuốt lệnh
    for i = 1, 3 do
        if getconnections then
            for _, connection in pairs(getconnections(button.MouseButton1Click)) do
                connection:Fire()
            end
            for _, connection in pairs(getconnections(button.MouseButton1Down)) do
                connection:Fire()
            end
        end
        -- Dự phòng cơ bản nếu Executor không có getconnections
        button.MouseButton1Click:Fire()
        task.wait(0.1)
    end
    return true
end

-- =========================================================================
-- ⏳ LUỒNG THEO DÕI GIAO DIỆN VÀ REJOIN
-- =========================================================================
print("[⏳ STAGE 5] Chỉ thực hiện quét UI và chuẩn bị Rejoin...")

task.spawn(function()
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    local timeout = 0
    
    print("[Wait] Đang đợi giao diện Play Again xuất hiện thực tế...")
    
    -- Vòng lặp quét nút mỗi 0.3 giây cho đến khi thấy nút HỢP LỆ (Tối đa ~20 giây)
    while not foundButton and timeout < 60 do 
        for _, obj in pairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                -- Kiểm tra xem nút đã hiển thị và có kích thước thật hay chưa
                if obj.Visible and obj.AbsolutePosition.Y > 0 then
                    foundButton = obj
                    break
                end
            end
        end
        timeout = timeout + 1
        task.wait(0.3)
    end
    
    -- Thực hiện hành động khi tìm thấy nút
    if foundButton then
        print("[🎯 SUCCESS] Tìm thấy nút Play Again. Tiến hành click...")
        task.wait(0.2) -- Đợi UI ổn định hẳn
        
        if secureClick(foundButton) then
            task.wait(1.2) -- Chờ game nhận tín hiệu phản hồi từ nút bấm
            
            -- Thực hiện Rejoin ép về đúng phòng (Server Instance) hiện tại
            print("[🚀] Thực hiện Rejoin Bypass...")
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ServerInstanceId = game.JobId
            
            local success, err = pcall(function()
                TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
            end)
            
            if not success then 
                warn("[Error] Lỗi Rejoin: " .. tostring(err)) 
            end
        end
    else
        warn("[Timeout] Hết thời gian chờ nhưng không thấy nút Play Again xuất hiện!")
    end
end)
