local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local RUN_SPEED = 30

-- Hàm tìm mục tiêu gần nhất
local function getNearestPowerBox()
    local nearestBox = nil
    local minDistance = math.huge
    local myPos = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character.HumanoidRootPart.Position
    
    if not myPos then return nil end

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" then
            local targetPart = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if targetPart then
                local dist = (myPos - targetPart.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    nearestBox = targetPart
                end
            end
        end
    end
    return nearestBox
end

-- Hàm nhảy khi gặp vật cản
local function jumpIfBlocked(rootPart, humanoid)
    local ray = Ray.new(rootPart.Position, rootPart.CFrame.LookVector * 5)
    local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character})
    if hit then
        humanoid.Jump = true
    end
end

-- VÒNG LẶP CHÍNH (ĐƠN GIẢN HÓA)
print("[STAGE 3] Bắt đầu di chuyển siêu tốc...");

local target = getNearestPowerBox()
if target then
    local char = localPlayer.Character
    local root = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    humanoid.WalkSpeed = RUN_SPEED
    
    -- Di chuyển thẳng đến mục tiêu
    while target and (root.Position - target.Position).Magnitude > 4 do
        humanoid:MoveTo(target.Position)
        jumpIfBlocked(root, humanoid) -- Tự nhảy khi thấy vật cản trước mặt
        
        -- Cập nhật lại target nếu cần
        task.wait(0.1)
    end
end

print("[🎯 STAGE 3 SUCCESS] Đã tới nơi!");
_G.CurrentStage = 4
return true
