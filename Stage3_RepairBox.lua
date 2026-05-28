local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Tìm Power Box gần nhất (cũ)
local function getNearestPowerBox()
    local nearest = nil
    local minDist = math.huge
    local myPos = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character.HumanoidRootPart.Position
    if not myPos then return nil end

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" then
            local targetPart = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if targetPart then
                local dist = (myPos - targetPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = targetPart
                end
            end
        end
    end
    return nearest
end

-- VÒNG LẶP DI CHUYỂN "THẲNG TIẾN"
print("[STAGE 3] Di chuyển siêu tốc (No Pathfinding)...");

local char = localPlayer.Character
local root = char and char:WaitForChild("HumanoidRootPart")
local humanoid = char and char:FindFirstChildOfClass("Humanoid")

if root and humanoid then
    humanoid.WalkSpeed = RUN_SPEED
    
    while true do
        local target = getNearestPowerBox()
        if not target then break end
        
        local dist = (root.Position - target.Position).Magnitude
        if dist < 4 then break end -- Đã tới nơi
        
        -- DI CHUYỂN THẲNG MỘT ĐƯỜNG
        humanoid:MoveTo(target.Position)
        
        -- DÒ VẬT CẢN TRƯỚC MẶT (Raycast)
        local ray = Ray.new(root.Position, root.CFrame.LookVector * 6)
        local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {char})
        
        if hit then
            -- Nếu có vật cản, nhảy ngay lập tức
            humanoid.Jump = true
        end
        
        task.wait(0.1) -- Tốc độ quét vật cản 0.1s - cực nhanh
    end
end

print("[🎯 STAGE 3 SUCCESS] Đã tới trạm điện!");
_G.CurrentStage = 4
return true
