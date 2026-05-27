-- =========================================================================
-- 🛡️ STAGE 0 HOÀN HẢO - ĐỘC LẬP VÀ CHỐNG NUỐT NÚT TUẦN TỰ SÂU
-- =========================================================================
print("[🚀 STAGE 0] Khởi chạy Stage 0 độc lập - Đang đợi ZHUB tải...");

-- 1. Khởi chạy Menu ZHUB từ link gốc (Bọc pcall an toàn)
local successLoad, errLoad = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

if not successLoad then
    warn("[⚠️ STAGE 0] Không thể tải ZHUB từ Github: " .. tostring(errLoad))
end

-- Đợi một khoảng ngắn ban đầu để menu kịp tạo dữ liệu nền
task.wait(4)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local targetGui = nil

-- 2. Vòng lặp tìm kiếm UI của ZHUB sâu tuần tự
for i = 1, 30 do
    targetGui = CoreGui:FindFirstChild("ZHUB") 
                or player.PlayerGui:FindFirstChild("ZHUB") 
                or CoreGui:FindFirstChildOfClass("ScreenGui") 
                or player.PlayerGui:FindFirstChildOfClass("ScreenGui")
    if targetGui and targetGui:FindFirstChildOfClass("Frame") then break end
    task.wait(0.5)
end

if not targetGui then
    targetGui = CoreGui -- Phương án dự phòng quét gốc
end

-- Hàm bổ trợ giả lập click chuột chuẩn sâu bọc lót getconnections
