local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local WEAPON_NAME = "Bat" -- Kiểm tra kỹ tên vũ khí xem có đúng là "Bat" không nhé

print("[⚔️ SYSTEM] Đang khởi chạy Auto Equip - Chế độ bền bỉ cho Mobile...");

local function attemptEquip()
    pcall(function()
        local char = localPlayer.Character
        if not char then return end
        
        -- Nếu đã cầm vũ khí thì không làm gì cả
        if char:FindFirstChild(WEAPON_NAME) then return end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local backpack = localPlayer:FindFirstChild("Backpack")
        
        if humanoid and backpack then
            local weapon = backpack:FindFirstChild(WEAPON_NAME)
            if weapon and weapon:IsA("Tool") then
                -- Ép trang bị với độ trễ thấp để tránh xung đột với hệ thống game
                humanoid:EquipTool(weapon)
                print("[⚔️] Trang bị thành công: " .. WEAPON_NAME)
            end
        end
    end)
end

-- =========================================================================
-- LOGIC BẢO HIỂM: Tự động trang bị khi có bất kỳ thay đổi nào
-- =========================================================================

-- 1. Trang bị khi nhân vật vừa hồi sinh (Sử dụng task.delay để Mobile kịp load)
localPlayer.CharacterAdded:Connect(function(char)
    task.delay(2.5, attemptEquip) -- Chờ 2.5s sau khi hồi sinh
end)

-- 2. Trang bị khi vũ khí vừa xuất hiện trong Backpack (Trường hợp nhặt đồ)
if localPlayer:FindFirstChild("Backpack") then
    localPlayer.Backpack.ChildAdded:Connect(function(child)
        if child.Name == WEAPON_NAME then
            task.wait(0.5)
            attemptEquip()
        end
    end)
end

-- 3. Vòng lặp bảo hiểm (Chạy mỗi 5 giây) - Đây là chìa khóa để không bao giờ mất vũ khí khi Rejoin
task.spawn(function()
    while true do
        attemptEquip()
        task.wait(5) -- Kiểm tra lại mỗi 5 giây
    end
end)

-- Chạy thử lần đầu ngay khi script load
attemptEquip()

return true
