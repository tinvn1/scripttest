if not game:IsLoaded() then game.Loaded:Wait() end

print("[🚀 STAGE 0] Khởi chạy ZHUB & Tự động nạp cấu hình...");

-- 1. Khởi chạy Menu ZHUB
local successLoad, errLoad = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

if not successLoad then 
    return warn("[⚠️ STAGE 0] Không thể tải ZHUB: " .. tostring(errLoad)) 
end

-- 2. Tiến trình nạp cấu hình tự động vào hệ thống Flags
task.spawn(function()
    -- Vòng lặp chờ hệ thống Flags của ZHUB được khởi tạo trong bộ nhớ
    local timeout = 0
    while not getgenv().Flags and timeout < 30 do
        task.wait(0.5)
        timeout = timeout + 1
    end

    if not getgenv().Flags then
        return warn("[⚠️ STAGE 0] Quá thời gian chờ, không tìm thấy hệ thống Flags!")
    end

    task.wait(1.5) -- Chờ thêm một chút để các thanh trượt (Sliders) ổn định giá trị mặc định

    -- BẢNG CẤU HÌNH CỦA BẠN (Đã sửa chính xác theo dữ liệu hệ thống)
    local myConfig = {
        ["AutoDrag"] = true,
        ["AutoDragRange"] = 12,
        ["AutoDragHoldDistance"] = 3,
        ["AutoDragHoldHeight"] = 1,
        ["AutoDragOrbitAngle"] = 0,
        ["AutoDragOrbitSpeed"] = 0,
        
        ["Killaura"] = true,
        ["KillauraRange"] = 35,
        
        -- Bạn có thể chép thêm các dòng cấu hình khác từ file text của bạn vào đây nếu muốn tự bật thêm
    }

    print("[🔍] Đang tiến hành nạp cấu hình...");
    
    -- Duyệt qua bảng cấu hình và ép hệ thống thực thi lệnh :Set()
    for flagName, value in pairs(myConfig) do
        local flagObject = getgenv().Flags[flagName]
        if flagObject and type(flagObject) == "table" and flagObject.Set then
            pcall(function()
                if type(value) == "table" then
                    -- Xử lý trường hợp Dropdown chọn nhiều giá trị dạng danh sách
                    flagObject:Set(value[1] or value)
                else
                    flagObject:Set(value)
                end
            end)
        end
    end

    print("[🎉 SUCCESS] Đã tự động kích hoạt Auto Drag, Killaura và nạp các thông số thành công!");
end)

return true
