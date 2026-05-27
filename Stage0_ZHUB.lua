-- Chờ trò chơi tải xong xuôi hoàn toàn
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Khởi động luồng KIỂM SOÁT TRẠNG THÁI - Chống nuốt nút ZHUB!");

-- Khởi chạy Menu ZHUB bằng pcall bảo vệ luồng chính
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

-- Đợi 5 giây ban đầu để ZHUB khởi tạo cấu trúc và nạp các cài đặt cấu hình ngầm
task.wait(5)

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Hàm tìm công tắc gạt (Toggle) nằm cạnh nhãn chữ chỉ định
local function findToggle(buttonText)
    local searchAreas = {CoreGui, PlayerGui}
    for _, area in ipairs(searchAreas) do
        for _, obj in pairs(area:GetDescendants()) do
            if obj:IsA("TextLabel") and (obj.Text == buttonText or string.find(obj.Text, buttonText)) then
                local row = obj.Parent
                if row then
                    -- Định vị trực tiếp phần tử TextButton/ImageButton gạt nằm cùng khung dòng (Row/Frame)
                    local toggle = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                    if toggle then
                        return toggle
                    end
                end
            end
        end
    end
    return nil
end

-- Hàm mô phỏng kích hoạt chuột sâu an toàn, giãn cách nhịp kết nối
local function forceClick(button)
    if not button then return end
    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
    for _, event in ipairs(events) do
        if button[event] then
            pcall(function()
                if getconnections then
                    for _, connection in pairs(getconnections(button[event])) do
                        connection:Fire()
                        task.wait(0.05) -- Giãn cách cực nhỏ chống nghẽn bộ giải trình
                    end
                else
                    button[event]:Fire()
                end
            end)
        end
    end
end

-- =========================================================================
-- 🔥 LUỒNG KIỂM SOÁT TUẦN TỰ CHẶT CHẼ TRÁNH XUNG ĐỘT TỐC ĐỘ
-- =========================================================================
task.spawn(function()
    
    -- 🚚 BƯỚC 1: ƯU TIÊN ÉP BẬT VÀ KIỂM TRA "AUTO DRAG" TRƯỚC
    print("[⏳ ZHUB] Bắt đầu xử lý mục: Auto Drag...");
    local dragSuccess = false
    for attempt = 1, 15 do
        local dragToggle = findToggle("Auto Drag")
        if dragToggle then
            forceClick(dragToggle)
            
            -- Đợi một nhịp ngắn xem UI phản hồi trạng thái sáng đèn chưa
            task.wait(0.5)
            
            -- Thử đồng bộ qua cấu hình môi trường Flags nếu có
            if getgenv().Flags then
                pcall(function()
                    if getgenv().Flags["Auto Drag"] then getgenv().Flags["Auto Drag"]:Set(true) end
                    if getgenv().Flags["AutoDrag"] then getgenv().Flags["AutoDrag"]:Set(true) end
                end)
            end
            
            dragSuccess = true
            print("[✔️ STAGE 0] Đã hoàn tất kích hoạt: Auto Drag!");
            break
        end
        task.wait(0.5)
    end

    -- 🕒 KHOẢNG NGHỈ GIẢN CÁCH TUYỆT ĐỐI: Dừng hẳn 1.2 giây để UI xả sạch hàng đợi lệnh cũ
    print("[⏳ SYSTEM] Nghỉ 1.2 giây để đồng bộ bộ nhớ giao diện...");
    task.wait(1.2)

    -- ⚔️ BƯỚC 2: TIẾN HÀNH ÉP BẬT "KILL AURA" SAU KHI AUTO DRAG ỔN ĐỊNH
    print("[⏳ ZHUB] Bắt đầu xử lý mục: Kill Aura...");
    local auraSuccess = false
    for attempt = 1, 15 do
        local auraToggle = findToggle("Kill Aura")
        if auraToggle then
            forceClick(auraToggle)
            
            -- Đợi một nhịp ngắn xem UI phản hồi trạng thái sáng đèn chưa
            task.wait(0.5)
            
            -- Thử đồng bộ qua cấu hình môi trường Flags nếu có
            if getgenv().Flags then
                pcall(function()
                    if getgenv().Flags["Kill Aura"] then getgenv().Flags["Kill Aura"]:Set(true) end
                    if getgenv().Flags["KillAura"] then getgenv().Flags["KillAura"]:Set(true) end
                end)
            end
            
            auraSuccess = true
            print("[✔️ STAGE 0] Đã hoàn tất kích hoạt: Kill Aura!");
            break
        end
        task.wait(0.5)
    end

    -- Khóa bảo vệ nhịp cuối trước khi bàn giao luồng
    task.wait(0.8)
    print("[🚀 SYSTEM] Toàn bộ 2 chức năng đã mở thành công và an toàn! Chuyển giao sang Stage 1 nhặt Fuel...");
    
    _G.CurrentStage = 1
end)

return true
