print("[⚔️ SYSTEM] Khởi động luồng tự động cầm vũ khí độc lập...")

-- Khởi tạo công tắc toàn cục ban đầu cho phép chạy Auto Equip
if _G.AllowAutoEquip == nil then
    _G.AllowAutoEquip = true
end

local localPlayer = game:GetService("Players").LocalPlayer

task.spawn(function()
    while true do
        -- 🔥 CHỈ CẦM VŨ KHÍ KHI CÔNG TẮC ĐANG BẬT
        if _G.AllowAutoEquip then
            local char = localPlayer.Character
            local backpack = localPlayer:FindFirstChild("Backpack")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if char and backpack and humanoid and humanoid.Health > 0 then
                -- Tìm vũ khí trong balo để cầm lên tay (Ví dụ: cây Bat)
                local weapon = backpack:FindFirstChild("Bat") or backpack:FindFirstChildWhichIsA("Tool")
                if weapon then
                    humanoid:EquipTool(weapon)
                end
            end
        else
            -- Nếu công tắc tắt, lệnh Auto Equip sẽ tạm dừng quét để nhường sân cho Stage 5
            print("[💤 AUTO EQUIP] Đang tạm dừng theo lệnh từ Stage 5...")
            task.wait(1)
        end
        task.wait(0.5)
    end
end)
