task.wait(3)
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera

-- Thông báo bắt đầu giữ
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Auto Hold",
    Text = "Bắt đầu giữ tâm màn hình trong 19 giây...",
    Duration = 3
})

-- Lấy tọa độ chính giữa màn hình điện thoại
local centerX = Camera.ViewportSize.X / 2
local centerY = Camera.ViewportSize.Y / 2

-- Kích hoạt vòng lặp giữ trong 19 giây
local startTime = tick()
task.spawn(function()
    while tick() - startTime < 19 do
        -- Giả lập hành động nhấn xuống (true) tại tâm màn hình
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.1) -- Duy trì lệnh nhấn liên tục để tránh bị tuột
    end
    
    -- Sau 19 giây, thực hiện nhấc ra (false)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    
    -- Thông báo hoàn thành
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Auto Hold",
        Text = "Đã giữ đủ 19 giây và tự động thả!",
        Duration = 3
    })
end)
