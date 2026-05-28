local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local WEAPON_NAME = "Bat"

local function equipWeapon()
    pcall(function()
        local char = localPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local backpack = localPlayer:FindFirstChild("Backpack")
        
        if humanoid and backpack and not char:FindFirstChild(WEAPON_NAME) then
            local weapon = backpack:FindFirstChild(WEAPON_NAME)
            if weapon and weapon:IsA("Tool") then
                humanoid:EquipTool(weapon)
                print("[⚔️] Đã trang bị " .. WEAPON_NAME .. " thành công!")
            end
        end
    end)
end

print("[⚔️ SYSTEM] Đã kích hoạt luồng tự động cầm vũ khí 1 lần duy nhất!");

-- Chạy ngay lập tức 1 lần khi script khởi động
equipWeapon()

-- Khi nhân vật hồi sinh, tự động trang bị lại 1 lần duy nhất
localPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    equipWeapon()
end)

return true
