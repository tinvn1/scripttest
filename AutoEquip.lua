local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local WEAPON_NAME = "Bat" -- Bạn có thể đổi tên vũ khí tại đây nếu muốn

local function equipWeapon()
    pcall(function()
        local char = localPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local backpack = localPlayer:FindFirstChild("Backpack")
        
        -- Nếu nhân vật chưa cầm vũ khí trên tay thì mới tìm trong Backpack để cầm lên
        if humanoid and backpack and not char:FindFirstChild(WEAPON_NAME) then
            local weapon = backpack:FindFirstChild(WEAPON_NAME)
            if weapon and weapon:IsA("Tool") then
                humanoid:EquipTool(weapon)
            end
        end
    end)
end

print("[⚔️ SYSTEM] Đã kích hoạt luồng tự động cầm vũ khí an toàn độc lập!");

-- Tạo vòng lặp chạy liên tục xuyên suốt cả game để giữ vũ khí luôn trên tay
task.spawn(function()
    while true do
        equipWeapon()
        task.wait(1) -- Quét mỗi giây một lần để tránh nặng máy/lag game
    end
end)

-- Khi nhân vật hồi sinh (reset/chết), tự động trang bị lại sau 1 giây
localPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    equipWeapon()
end)

return true
