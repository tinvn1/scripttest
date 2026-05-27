-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Khởi chạy Stage 0 - Tiến trình tự động cấu hình ZHUB...");

-- 1. Khởi chạy Menu ZHUB từ link Github của tác giả
local successLoad, errLoad = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

if not successLoad then
    warn("[⚠️ STAGE 0] Không thể tải ZHUB từ Github: " .. tostring(errLoad))
end

-- 2. Đợi giao diện Menu xuất hiện trong CoreGui hoặc PlayerGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local targetGui = nil

-- Vòng lặp tìm kiếm UI của ZHUB
for i = 1, 30 do
    targetGui = game:GetService("CoreGui"):FindFirstChild("ZHUB") 
                or player.PlayerGui:FindFirstChild("ZHUB") 
                or game:GetService("CoreGui"):FindFirstChildOfClass("ScreenGui")
    if targetGui and targetGui:FindFirstChildOfClass("Frame") then break end
    task.wait(0.5)
end

-- 3. Tự động tìm cấu hình và kích hoạt "Auto Drag Body" & "Kill Aura"
task.spawn(function()
    task.wait(3.5) -- Chờ UI khởi tạo hoàn chỉnh các hàng nút và nạp dữ liệu Flags
    
    ---------------------------------------------------------
    -- CÁCH 1: Kích hoạt thông qua hệ thống Flags cấu hình (Tối ưu nhất)
    ---------------------------------------------------------
    if getgenv().Flags then
        print("[🔍] Phát hiện hệ thống Flags. Đang ghi đè trạng thái kích hoạt...")
        
        -- Kích hoạt Auto Drag Body (Đúng tên Flag của ZHUB)
        if getgenv().Flags["Auto Drag Body"] ~= nil then
            getgenv().Flags["Auto Drag Body"]:Set(true)
            print("[🎯 FLAGS] Đã bật: Auto Drag Body")
        elseif getgenv().Flags["Auto Drag"] ~= nil then
            getgenv().Flags["Auto Drag"]:Set(true)
            print("[🎯 FLAGS] Đã bật: Auto Drag")
        end
        
        -- Kích hoạt Kill Aura
        if getgenv().Flags["Kill Aura"] ~= nil then
            getgenv().Flags["Kill Aura"]:Set(true)
            print("[🎯 FLAGS] Đã bật: Kill Aura")
        elseif getgenv().Flags["KillAura"] ~= nil then
            getgenv().Flags["KillAura"]:Set(true)
            print("[🎯 FLAGS] Đã bật: KillAura")
        end
    end
    
    ---------------------------------------------------------
    -- CÁCH 2: Phương án dự phòng (Quét chuyển Tab và giả lập Click vào nút Toggle)
    ---------------------------------------------------------
    task.wait(0.5)
    if targetGui then
        -- Hàm hỗ trợ click chuyển Tab/Nút phụ trợ
        local function secureClick(btn)
            if not btn then return end
            if getconnections then
                for _, connection in pairs(getconnections(btn.MouseButton1Click)) do connection:Fire() end
                for _, connection in pairs(getconnections(btn.MouseButton1Down)) do connection:Fire() end
            end
            btn.MouseButton1Click:Fire()
        end

        -- Quét chuyển Tab Combat để hỗ trợ kích hoạt trực quan trên UI nếu Cách 1 hụt
        for _, tab in pairs(targetGui:GetDescendants()) do
            if tab:IsA("TextButton") and (tab.Text == "Combat" or tab.Text == "Main") then
                secureClick(tab)
                task.wait(0.2)
            end
        end

        -- Quét sâu cấu trúc nút Toggle vật lý
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") then
                local text = string.lower(v.Text)
                -- Kiểm tra chính xác từ khóa theo UI thực tế
                if string.find(text, "kill aura") or string.find(text, "drag body") or string.find(text, "auto drag") then
                    local p = v.Parent
                    if p then
                        -- Tìm nút gạt (Toggle) tương tác trực tiếp
                        local toggleBtn = p:FindFirstChildOfClass("TextButton") 
                                       or p:FindFirstChildOfClass("ImageButton") 
                                       or p.Parent:FindFirstChildOfClass("TextButton")
                        
                        if toggleBtn then
                            local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
                            for _, event in ipairs(events) do
                                if toggleBtn[event] then
                                    for _, connection in pairs(getconnections(toggleBtn[event])) do
                                        connection:Fire()
                                    end
                                end
                            end
                            print("[🎯 UI CLICK] Đã gửi lệnh click dự phòng cho nút: " .. v.Text)
                        end
                    end
                end
            end
        end
    end
    print("[🎉 SUCCESS] Hoàn tất luồng xử lý kích hoạt Stage 0!")
end)

return true
