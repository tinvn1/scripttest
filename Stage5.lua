local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

print("[💀 STAGE 5] Đã vào phân đoạn nạp mạng. Tiến hành tắt Auto Equip...")

-- 🔥 BƯỚC 1: SẬP CÔNG TẮC TẮT LỆNH AUTO EQUIP TỪ XA
_G.AllowAutoEquip = false 

task.wait(0.2) -- Chờ một nhịp nhỏ để luồng AutoEquip dừng hẳn

-- 🔥 BƯỚC 2: RA LỆNH CẤT VŨ KHÍ VÀO BALO (SẴN CẤT ĐỒ LUÔN)
local char = localPlayer.Character
local humanoid = char and char:FindFirstChildOfClass("Humanoid")
if humanoid then
    humanoid:UnequipTools() -- Tắt vũ khí trên tay đưa về Balo
    print("[🎒 STAGE 5] Đã tắt và cất vũ khí vào balo thành công!")
end

-- =========================================================================
-- 🔥 DANH SÁCH CÁC LOẠI QUÁI ĐƯỢC PHÁT HIỆN TRONG MAP
-- =========================================================================
local targetMobNames = {
    ["crawler"] = true,
    ["phaser"] = true,
    ["runner"] = true,
    ["zombie"] = true
}

local function getNearestMob(rootPosition)
    local nearestMobPart = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local objNameLower = string.lower(obj.Name)
            
            if targetMobNames[objNameLower] then
                local mobRoot = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                local mobHumanoid = obj:FindFirstChildOfClass("Humanoid")
                
                if mobRoot and mobHumanoid and mobHumanoid.Health > 0 then
                    local dist = (rootPosition - mobRoot.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        nearestMobPart = mobRoot
                    end
                end
            end
        end
    end
    return nearestMobPart
end

-- =========================================================================
-- 🔄 VÒNG LẶP ÉP DÍNH VÀO QUÁI ĐỂ CHẾT (KHÔNG CẦN CHẠY VÒNG LẶP CẤT ĐỒ NỮA)
-- =========================================================================
local PlayerGui = localPlayer:WaitForChild("PlayerGui")
local gameOverVisible = false

task.spawn(function()
    while not gameOverVisible do
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and humanoid and humanoid.Health > 0 then
            local targetMob = getNearestMob(root.Position)
            if targetMob then
                -- Dịch chuyển dính chặt vào quái để nhận sát thương
                root.CFrame = targetMob.CFrame * CFrame.new(0, 0, 0.5)
            else
                local randomPos = root.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
                root.CFrame = CFrame.new(randomPos.X, root.Position.Y, randomPos.Z)
            end
        end
        task.wait(0.15)
    end
end)

-- =========================================================================
-- ⏳ ĐỢI BẢNG UI GAME OVER / REPLAY XUẤT HIỆN
-- =========================================================================
while not gameOverVisible do
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") and (string.find(string.lower(gui.Text), "play again") or gui.Name == "PlayAgain") then
            if gui.Visible then
                gameOverVisible = true
                print("[🎯 STAGE 5 SUCCESS] Đã chết xong!")
                break
            end
        end
    end
    task.wait(0.5)
end

task.wait(1)

_G.CurrentStage = 6
return true
