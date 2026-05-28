local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local WEAPON_NAME = "Bat" -- Kiểm tra kỹ tên vũ khí xem có đúng là "Bat" không nhé
local HP_THRESHOLD_PERCENT = 40 -- Ngưỡng máu để tự động cầm vũ khí (40%)

print("[⚔️ SYSTEM] Đang khởi chạy Auto Equip - Chế độ bảo vệ khi thấp HP...");

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
                print("[⚔️] Trang bị thành công do khẩn cấp: " .. WEAPON_NAME)
            end
        end
    end)
end

-- Hàm thiết lập theo dõi HP của Nhân vật
local function monitorHealth(char)
    local humanoid = char:WaitForChild("Humanoid", 10)
    if humanoid then
        -- Lắng nghe sự thay đổi máu liên tục
        humanoid.HealthChanged:Connect(function(currentHealth)
            local maxHealth = humanoid.MaxHealth
            local healthPercent = (currentHealth / maxHealth) * 100
            
            -- Nếu máu hiện tại dưới ngưỡng 40% và nhân vật chưa chết
            if healthPercent <= HP_THRESHOLD_PERCENT and currentHealth > 0 then
                attemptEquip()
            end
        end)
    end
end

-- =========================================================================
-- LOGIC BẢO HIỂM TỰ ĐỘNG
-- =========================================================================

-- 1. Xử lý khi nhân vật hồi sinh hoặc đổi Character
localPlayer.CharacterAdded:Connect(function(char)
    monitorHealth(char)            -- Bật chế độ theo dõi HP cho nhân vật mới
    task.delay(2.5, attemptEquip) -- Vẫn giữ chế độ chờ 2.5s để hồi sinh cầm vũ khí
end)

-- Kích hoạt theo dõi HP ngay lập tức nếu nhân vật đã load sẵn
if localPlayer.Character then
    monitorHealth(localPlayer.Character)
end

-- 2. Trang bị khi vũ khí vừa xuất hiện trong Backpack (Trường hợp nhặt đồ)
if localPlayer:FindFirstChild("Backpack") then
    localPlayer.Backpack.ChildAdded:Connect(function(child)
        if child.Name == WEAPON_NAME then
            task.wait(0.5)
            attemptEquip()
        end
    end)
end

-- 3. Vòng lặp bảo hiểm (Chạy mỗi 5 giây)
task.spawn(function()
    while true do
        attemptEquip()
        task.wait(5)
    end
end)

-- Chạy thử lần đầu ngay khi script load
attemptEquip()

return true
