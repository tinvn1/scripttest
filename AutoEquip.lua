local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local WEAPON_NAME = "Bat" -- Có thể thay đổi nếu game có vũ khí khác

local function equipWeapon()
    pcall(function()
        local char = localPlayer.Character
        if not char then return end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local backpack = localPlayer:FindFirstChild("Backpack")
        
        -- Nếu đã cầm vũ khí rồi thì bỏ qua
        if char:FindFirstChild(WEAPON_NAME) then return end
        
        if humanoid and backpack then
            local weapon = backpack:FindFirstChild(WEAPON_NAME)
            if weapon and weapon:IsA("Tool") then
                humanoid:EquipTool(weapon)
                print("[⚔️ MOBILE] Đã trang bị " .. WEAPON_NAME .. " thành công!")
            end
        end
    end)
end

-- =========================================================================
-- 🔥 LOGIC TRANG BỊ TỐI ƯU CHO MOBILE
-- =========================================================================

-- 1. Chạy thử ngay khi script bắt đầu
equipWeapon()

-- 2. Đảm bảo trang bị khi nhân vật hồi sinh (tăng delay nhẹ cho Mobile)
localPlayer.CharacterAdded:Connect(function()
    task.wait(1.5) -- Mobile cần thời gian load UI/Backpack lâu hơn PC
    equipWeapon()
end)

-- 3. BẮT SỰ KIỆN: Nếu vũ khí vừa rơi vào Backpack (do vừa nhặt được), trang bị ngay lập tức
localPlayer.Backpack.ChildAdded:Connect(function(child)
    if child.Name == WEAPON_NAME then
        task.wait(0.2)
        equipWeapon()
    end
end)

-- 4. BẢO HIỂM: Ép kiểm tra định kỳ 5 giây/lần (Chống kẹt vũ khí trong Backpack trên Mobile)
task.spawn(function()
    while true do
        task.wait(5)
        equipWeapon()
    end
end)

print("[⚔️ SYSTEM] Hệ thống Auto Equip Mobile đã khởi chạy tối ưu!");
return true
