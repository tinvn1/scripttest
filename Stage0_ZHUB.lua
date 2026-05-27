-- Chờ trò chơi tải xong xuôi hoàn toàn
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Đang khởi tạo luồng càn quét DÀNH RIÊNG cho ZHUB...");

-- Khởi chạy Menu ZHUB bằng pcall bảo vệ luồng chính
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

task.wait(4) -- Đợi hẳn 4 giây để ZHUB tạo xong cấu trúc UI và nạp dữ liệu thành công

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Hàm mô phỏng click chuột chuẩn sâu (Chọc thủng cơ chế chặn của UI nâng cao)
local function safeClick(button)
    if not button then return end
    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
    for _, event in ipairs(events) do
        if button[event] then
            pcall(function()
                if getconnections then
                    for _, connection in pairs(getconnections(button[event])) do
                        connection:Fire()
                    end
                else
                    button[event]:Fire()
                end
            end)
        end
    end
end

-- =========================================================================
-- 🔥 VÒNG LẶP ÉP BUỘC TRẠNG THÁI: PHẢI BẬT THÀNH CÔNG MỚI CHO QUA STAGE 1
-- =========================================================================
local dragActive = false
local auraActive = false
local totalLoops = 25 -- Quét tối đa 25 lần lặp lại

for currentLoop = 1, totalLoops do
    if dragActive and auraActive then break end
    print(string.format("[🔄 ZHUB SCAN] Đợt kiểm tra và kích hoạt thứ %d/%d...", currentLoop, totalLoops))

    local locations = {CoreGui, PlayerGui}
    
    for _, area in ipairs(locations) do
        for _, obj in pairs(area:GetDescendants()) do
            if obj:IsA("TextLabel") then
                
                -- 🚚 1. XỬ LÝ NÚT "AUTO DRAG"
                if not dragActive and (obj.Text == "Auto Drag" or string.find(obj.Text, "Auto Drag")) then
                    -- Bật bằng biến môi trường Flags của Hub trước phòng hờ
                    if getgenv().Flags then
                        pcall(function()
                            if getgenv().Flags["Auto Drag"] then getgenv().Flags["Auto Drag"]:Set(true) end
                            if getgenv().Flags["AutoDrag"] then getgenv().Flags["AutoDrag"]:Set(true) end
                        end)
                    end
                    
                    -- Tìm nút gạt vật lý nằm chung khối cha (Row/Frame) với chữ Auto Drag
                    local row = obj.Parent
                    if row then
                        -- Thư viện UIX thường thiết kế Toggle là một TextButton/ImageButton nằm cùng cấp Frame
                        local toggle = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggle then
                            safeClick(toggle)
                            dragActive = true
                            print("[🎯 ZHUB] Kích hoạt thành công: Auto Drag vật lý!")
                        end
                    end
                end
                
                -- ⚔️ 2. XỬ LÝ NÚT "KILL AURA"
                if not auraActive and (obj.Text == "Kill Aura" or string.find(obj.Text, "Kill Aura")) then
                    -- Bật bằng biến môi trường Flags của Hub trước phòng hờ
                    if getgenv().Flags then
                        pcall(function()
                            if getgenv().Flags["Kill Aura"] then getgenv().Flags["Kill Aura"]:Set(true) end
                            if getgenv().Flags["KillAura"] then getgenv().Flags["KillAura"]:Set(true) end
                        end)
                    end
                    
                    -- Tìm nút gạt vật lý nằm chung khối cha với chữ Kill Aura
                    local row = obj.Parent
                    if row then
                        local toggle = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggle then
                            safeClick(toggle)
                            auraActive = true
                            print("[🎯 ZHUB] Kích hoạt thành công: Kill Aura vật lý!")
                        end
                    end
                end
                
            end
        end
    end

    -- 🛑 GIẢI PHÁP BỌC LÓT: Nếu chưa tìm thấy nút, chứng tỏ nút đang bị ẩn do chưa bấm đúng Tab
    -- Ép click vật lý vào các Tab điều hướng như "Combat", "Main", "Misc", "Drag" để UI render các nút ẩn ra ngoài.
    if not dragActive or not auraActive then
        for _, area in ipairs(locations) do
            for _, obj in pairs(area:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "Combat" or obj.Text == "Main" or obj.Text == "Misc" or string.find(obj.Text, "Drag")) then
                    local tabBtn = obj:FindFirstAncestorOfClass("TextButton") or obj:FindFirstAncestorOfClass("ImageButton") or obj.Parent
                    if tabBtn and (tabBtn:IsA("TextButton") or tabBtn:IsA("ImageButton")) then
                        safeClick(tabBtn)
                    end
                end
            end
        end
    end

    task.wait(1) -- Nghỉ 1 giây rồi lặp lại chu kỳ tiếp theo
end

print("[🚀] Stage 0 hoàn tất nhiệm vụ thiết lập ZHUB. Chuyển giao sang Stage 1 nhặt Fuel...");
_G.CurrentStage = 1
return true
