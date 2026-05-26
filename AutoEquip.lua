print("[⚔️ SYSTEM] Khởi động Auto Equip cho vũ khí: Bat...")

-- Biến công tắc toàn cục
if _G.AllowAutoEquip == nil then _G.AllowAutoEquip = true end

local localPlayer = game:GetService("Players").LocalPlayer
local hasEquipped = false -- Công tắc trạng thái chạy 1 lần

task.spawn(function()
    while not hasEquipped do
        -- Nếu công tắc bị tắt (từ Stage 5), vòng lặp này sẽ bỏ qua
        if _G.AllowAutoEquip then
            local char = localPlayer.Character
            local backpack = localPlayer:FindFirstChild("Backpack")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if char and backpack and humanoid and humanoid.Health > 0 then
                -- Tìm đúng vũ khí có tên là "Bat"
                local weapon = backpack:FindFirstChild("Bat")
                if weapon then
                    humanoid:EquipTool(weapon)
                    hasEquipped = true -- Khóa lại, không quét nữa
                    print("[⚔️] Đã cầm Bat thành công, khóa Auto Equip.")
                end
            end
        end
        task.wait(1)
    end
end)
