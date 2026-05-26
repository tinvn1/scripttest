print("[⚔️ SYSTEM] Khởi động luồng Auto Equip...")

-- Đặt công tắc mặc định là BẬT
if _G.AllowAutoEquip == nil then _G.AllowAutoEquip = true end

local localPlayer = game:GetService("Players").LocalPlayer

task.spawn(function()
    while true do
        -- Nếu công tắc bị tắt (từ Stage 5), vòng lặp này sẽ bỏ qua toàn bộ việc cầm vũ khí
        if _G.AllowAutoEquip then
            local char = localPlayer.Character
            local backpack = localPlayer:FindFirstChild("Backpack")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if char and backpack and humanoid and humanoid.Health > 0 then
                local weapon = backpack:FindFirstChildWhichIsA("Tool")
                if weapon and not char:FindFirstChild(weapon.Name) then
                    humanoid:EquipTool(weapon)
                end
            end
        end
        task.wait(1)
    end
end)
