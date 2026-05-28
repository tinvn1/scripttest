local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Hàm tìm Power Box gần nhất
local function getNearestPowerBox()
    local nearest, minDist = nil, math.huge
    local myPos = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character.HumanoidRootPart.Position
    if not myPos then return nil end

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" then
            local target = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if target then
                local dist = (myPos - target.Position).Magnitude
                if dist < minDist then
                    minDist, nearest = dist, target
                end
            end
        end
    end
    return nearest
end

-- VÒNG LẶP DI CHUYỂN "TỰ HỌC ĐƯỜNG ĐI"
print("[STAGE 3] Bắt đầu tìm đường đi thông minh...");

local char = localPlayer.Character
local root = char and char:WaitForChild("HumanoidRootPart")
local humanoid = char and char:FindFirstChildOfClass("Humanoid")

if root and humanoid then
    humanoid.WalkSpeed = RUN_SPEED
    
    while true do
        local target = getNearestPowerBox()
        if not target then break end
        
        -- Nếu khoảng cách quá gần, dừng lại
        if (root.Position - target.Position).Magnitude < 4 then break end
        
        -- ĐIỂM SÁNG TẠO: Kiểm tra vật cản trước mặt và cả phía trên đầu (để nhảy qua tường cao)
        local rayFront = Ray.new(root.Position, root.CFrame.LookVector * 5)
        local rayUp = Ray.new(root.Position + Vector3.new(0, 3, 0), root.CFrame.LookVector * 5)
        
        local hitFront, _ = Workspace:FindPartOnRayWithIgnoreList(rayFront, {char})
        local hitUp, _ = Workspace:FindPartOnRayWithIgnoreList(rayUp, {char})
        
        -- Nếu thấy vật cản, thực hiện nhảy "vượt rào"
        if hitFront or hitUp then
            humanoid.Jump = true
        end
        
        -- Hướng nhân vật thẳng tới mục tiêu (Giúp nhân vật không bị lạc đường)
        root.CFrame = CFrame.new(root.Position, Vector3.new(target.Position.X, root.Position.Y, target.Position.Z))
        humanoid:MoveTo(target.Position)
        
        task.wait(0.1)
    end
end

print("[🎯 STAGE 3 SUCCESS] Đã tới nơi!");
_G.CurrentStage = 4
return true
