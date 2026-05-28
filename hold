task.wait(1)
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

-- Thông báo bắt đầu giữ
StarterGui:SetCore("SendNotification", {
    Title = "Auto Hold (PC/Mobile)",
    Text = "Bắt đầu giữ tâm màn hình trong 19 giây...",
    Duration = 3
})

-- Lấy tọa độ chính giữa màn hình (Tự động cập nhật chuẩn cho cả PC và Điện thoại)
local centerX = Camera.ViewportSize.X / 2
local centerY = Camera.ViewportSize.Y / 2

task.spawn(function()
    -- [BƯỚC 1]: Nhấn chuột xuống tại tâm màn hình (Số 0 đại diện cho Chuột trái/Touch)
    -- Gửi lệnh 'true' để BẮT ĐẦU GIỮ
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    
    -- [BƯỚC 2]: Chờ đúng 19 giây (Vẫn giữ nguyên trạng thái nhấn)
    task.wait(19)
    
    -- [BƯỚC 3]: Gửi lệnh 'false' để THẢ CHUỘT RA
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    
    -- Thông báo hoàn thành
    StarterGui:SetCore("SendNotification", {
        Title = "Auto Hold (PC/Mobile)",
        Text = "Đã giữ đủ 19 giây và tự động thả!",
        Duration = 3
    })
end)
