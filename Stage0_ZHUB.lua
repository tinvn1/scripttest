-- Chờ game tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Khởi chạy Stage 0 - Tận dụng quét UI sâu tuần tự chống nuốt nút!");

-- 1. Khởi chạy Menu ZHUB từ link Github của tác giả
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

-- Đợi một khoảng ngắn ban đầu để menu kịp tạo dữ liệu nền
task.wait(4)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Hàm bổ trợ giả lập click chuột chuẩn sâu từ script cũ của bạn
local function fireClickEvents(toggleBtn)
    if not toggleBtn then return end
    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
    for _, event in ipairs(events) do
        if toggleBtn[event] then
            pcall(function()
                if getconnections then
                    for _, connection in pairs(getconnections(toggleBtn[event])) do
                        connection:Fire()
                    end
                else
                    toggleBtn[event]:Fire()
                end
            end)
        end
    end
end

-- =========================================================================
-- 🔥 LUỒNG XỬ LÝ QUÉT VÀ ÉP KÍCH HOẠT TUẦN TỰ (XONG NÚT 1 MỚI SANG NÚT 2)
-- =========================================================================
task.spawn(function()
    local targetGui = nil
    
    -- Vòng lặp tìm kiếm UI của ZHUB (Quét cả CoreGui và PlayerGui theo diện rộng giống code cũ)
    for i = 1, 30 do
        targetGui = CoreGui:FindFirstChild("ZHUB") 
                    or player.PlayerGui:FindFirstChild("ZHUB") 
                    or CoreGui:FindFirstChildOfClass("ScreenGui") 
                    or player.PlayerGui:FindFirstChildOfClass("ScreenGui")
        if targetGui and targetGui:FindFirstChildOfClass("Frame") then break end
        task.wait(0.5)
    end

    if not targetGui then
        targetGui = CoreGui -- Phương án dự phòng cuối: Quét thẳng từ gốc CoreGui nếu không định vị được thẻ cha
    end

    -- -------------------------------------------------------------------------
    -- 🚚 BƯỚC 1: ƯU TIÊN PHÁT HIỆN VÀ ÉP BẬT "AUTO DRAG" TRƯỚC
    -- -------------------------------------------------------------------------
    print("[⏳ ZHUB] Đang tiến hành tìm và ép bật: Auto Drag...");
    local dragSuccess = false
    
    for attempt = 1, 20 do
        if dragSuccess then break end
        
        -- Thử kích hoạt bằng Flags hệ thống (Cách tối ưu của bạn)
        if getgenv().Flags then
            pcall(function()
                if getgenv().Flags["Auto Drag"] then getgenv().Flags["Auto Drag"]:Set(true) dragSuccess = true end
                if getgenv().Flags["AutoDrag"] then getgenv().Flags["AutoDrag"]:Set(true) dragSuccess = true end
            end)
        end
        
        -- Phương án quét vật lý tìm TextLabel giống đoạn code cũ
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text == "Auto Drag" or string.find(v.Text, "Auto Drag")) then
                local p = v.Parent
                if p then
                    local toggleBtn = p:FindFirstChildOfClass("TextButton") or p:FindFirstChildOfClass("ImageButton") or p.Parent:FindFirstChildOfClass("TextButton")
                    if toggleBtn then
                        fireClickEvents(toggleBtn)
                        dragSuccess = true
                        print("[✔️ SUCCESS] Đã ép bật Auto Drag thành công bằng cách quét UI!");
                        break
                    end
                end
            end
        end
        task.wait(0.5) -- Giãn cách quét vòng lặp để tránh tràn dữ liệu bộ nhớ
    end

    -- 🕒 ĐỘ TRỄ QUYẾT ĐỊNH: Nghỉ hẳn 1.5 giây sau khi xong Auto Drag để xả nghẽn hàng đợi lệnh!
    print("[⏳ SYSTEM] Nghỉ 1.5 giây để ổn định giao diện trước khi bật nút tiếp theo...");
    task.wait(1.5)

    -- -------------------------------------------------------------------------
    -- ⚔️ BƯỚC 2: TIẾN HÀNH PHÁT HIỆN VÀ ÉP BẬT "KILL AURA"
    -- -------------------------------------------------------------------------
    print("[⏳ ZHUB] Đang tiến hành tìm và ép bật: Kill Aura...");
    local auraSuccess = false
    
    for attempt = 1, 20 do
        if auraSuccess then break end
        
        -- Thử kích hoạt bằng Flags hệ thống
        if getgenv().Flags then
            pcall(function()
                if getgenv().Flags["Kill Aura"] then getgenv().Flags["Kill Aura"]:Set(true) auraSuccess = true end
                if getgenv().Flags["KillAura"] then getgenv().Flags["KillAura"]:Set(true) auraSuccess = true end
            end)
        end
        
        -- Phương án quét vật lý tìm TextLabel của Kill Aura
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text == "Kill Aura" or string.find(v.Text, "Kill Aura")) then
                local p = v.Parent
                if p then
                    local toggleBtn = p:FindFirstChildOfClass("TextButton") or p:FindFirstChildOfClass("ImageButton") or p.Parent:FindFirstChildOfClass("TextButton")
                    if toggleBtn then
                        fireClickEvents(toggleBtn)
                        auraSuccess = true
                        print("[✔️ SUCCESS] Đã ép bật Kill Aura thành công bằng cách quét UI!");
                        break
                    end
                end
            end
        end
        task.wait(0.5)
    end

    -- Bàn giao tiến trình chuyển tiếp sang Stage 1 nhặt xăng ổn định
    task.wait(0.5)
    print("[🚀 SYSTEM] Hoàn thành cấu hình Stage 0! Chuyển sang Stage 1 nhặt Fuel...");
    _G.CurrentStage = 1
end)

return true
