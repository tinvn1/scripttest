-- Chờ trò chơi tải xong xuôi hoàn toàn
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Khởi động luồng ZHUB - Sửa lỗi bấm quá nhanh gây nuốt nút!");

-- Khởi chạy Menu ZHUB bằng pcall bảo vệ luồng chính
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

-- 🕒 Đợi hẳn 5 giây ban đầu để ZHUB ổn định bộ nhớ và tạo đầy đủ các phần tử UI ngầm
task.wait(5) 

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Hàm mô phỏng click chuột vật lý an toàn và chậm rãi
local function safeClick(button)
    if not button then return end
    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
    for _, event in ipairs(events) do
        if button[event] then
            pcall(function()
                if getconnections then
                    for _, connection in pairs(getconnections(button[event])) do
                        connection:Fire()
                        task.wait(0.1) -- Giãn cách nhỏ giữa các kết nối ngầm
                    end
                else
                    button[event]:Fire()
                end
            end)
        end
    end
end

-- =========================================================================
-- 🔥 CHUỖI KÍCH HOẠT TUẦN TỰ CHẬM RÃI (BẤM XONG NÚT 1 MỚI SANG NÚT 2)
-- =========================================================================
local autoDragActivated = false
local killAuraActivated = false

task.spawn(function()
    local searchAreas = {CoreGui, PlayerGui}

    -- -------------------------------------------------------------------------
    -- ⚔️ PHẦN 1: TÌM VÀ BẬT "KILL AURA" TRƯỚC
    -- -------------------------------------------------------------------------
    for attempt = 1, 15 do
        if killAuraActivated then break end
        
        for _, area in ipairs(searchAreas) do
            for _, obj in pairs(area:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "Kill Aura" or string.find(obj.Text, "Kill Aura")) then
                    local row = obj.Parent
                    if row then
                        local toggleBtn = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggleBtn then
                            safeClick(toggleBtn)
                            killAuraActivated = true
                            print("[✔️ STAGE 0] Bước 1: Kích hoạt thành công Kill Aura!");
                            break
                        end
                    end
                end
            end
            if killAuraActivated then break end
        end
        task.wait(0.5) -- Đợi 0.5 giây giữa các lần quét thử lại nếu chưa tìm thấy
    end

    -- 🕒 ĐỘ TRỄ QUYẾT ĐỊNH: Nghỉ hẳn 1.5 giây sau khi bật Kill Aura để UI game xả nghẽn lệnh!
    print("[⏳ SYSTEM] Đang nghỉ 1.5 giây để tránh bị xung đột lệnh bấm nhanh...");
    task.wait(1.5)

    -- -------------------------------------------------------------------------
    -- 🚚 PHẦN 2: TÌM VÀ BẬT "AUTO DRAG" SAU KHI UI ĐÃ ỔN ĐỊNH
    -- -------------------------------------------------------------------------
    for attempt = 1, 15 do
        if autoDragActivated then break end
        
        for _, area in ipairs(searchAreas) do
            for _, obj in pairs(area:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "Auto Drag" or string.find(obj.Text, "Auto Drag")) then
                    local row = obj.Parent
                    if row then
                        local toggleBtn = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggleBtn then
                            safeClick(toggleBtn)
                            autoDragActivated = true
                            print("[✔️ STAGE 0] Bước 2: Kích hoạt thành công Auto Drag!");
                            break
                        end
                    end
                end
            end
            if autoDragActivated then break end
        end
        task.wait(0.5) -- Đợi 0.5 giây giữa các lần quét thử lại nếu chưa tìm thấy
    end

    -- 🛑 Kích hoạt bổ trợ bằng Flags môi trường (Nếu script ZHUB có hỗ trợ lưu trạng thái vào Flags)
    if getgenv().Flags then
        pcall(function()
            if getgenv().Flags["Kill Aura"] then getgenv().Flags["Kill Aura"]:Set(true) end
            if getgenv().Flags["KillAura"] then getgenv().Flags["KillAura"]:Set(true) end
            task.wait(0.2)
            if getgenv().Flags["Auto Drag"] then getgenv().Flags["Auto Drag"]:Set(true) end
            if getgenv().Flags["AutoDrag"] then getgenv().Flags["AutoDrag"]:Set(true) end
        end)
    end

    -- Đợi thêm một nhịp ngắn trước khi chuyển giao hoàn toàn
    task.wait(0.5)
    print("[🚀 SYSTEM] Đã mở thành công cả 2 chức năng một cách an toàn. Chuyển sang Stage 1!");
    
    _G.CurrentStage = 1
end)

return true
