task.wait(1)
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

-- =========================================================================
-- CẤU HÌNH VÒNG LẶP VÀ TỌA ĐỘ
-- =========================================================================
local HOLD_DURATION = 19   -- Thời gian giữ (giây)
local COOLDOWN_TIME = 1    -- Thời gian nghỉ giữa mỗi lần lặp (giây)
local OFFSET_DOWN = 20     -- Độ thấp dưới tâm màn hình (pixel)

task.spawn(function()
    while true do
        pcall(function()
            -- Lấy lại tọa độ mỗi vòng lặp phòng trường hợp bạn xoay màn hình điện thoại
            local centerX = Camera.ViewportSize.X / 2
            local exactCenterY = Camera.ViewportSize.Y / 2
            local centerY = exactCenterY + OFFSET_DOWN

            -- Thông báo bắt đầu lượt giữ mới
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Hold Loop",
                Text = "Đang giữ tâm dưới... (" .. HOLD_DURATION .. "s)",
                Duration = 2
            })

            -- [BƯỚC 1]: BẮT ĐẦU GIỮ (Gửi lệnh 'true')
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)

            -- [BƯỚC 2]: Chờ hết thời gian hold
            task.wait(HOLD_DURATION)

            -- [BƯỚC 3]: THẢ RA (Gửi lệnh 'false')
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)

            -- Thông báo hoàn thành lượt
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Hold Loop",
                Text = "Đã thả! Nghỉ " .. COOLDOWN_TIME .. "s trước lượt tiếp theo.",
                Duration = 2
            })
        end)
        
        -- Thời gian nghỉ trước khi bắt đầu vòng lặp mới
        task.wait(COOLDOWN_TIME)
    end
end)
