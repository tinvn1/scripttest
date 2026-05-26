local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 1.8, AgentHeight = 5, AgentCanJump = true})

-- =========================================================================
-- 🔥 FIXED: HÀM QUÉT POWER BOX NÂNG CAO (CHỐNG CRASH PROXIMITYPROMPT)
-- =========================================================================
local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Tìm kiếm đúng vật thể có tên "Power Box" ẩn trong Power Plant
        if obj.Name == "Power Box" then
            local targetPart = nil
            
            -- Nếu cấu trúc là Model, bóc tách sâu linh kiện vật lý bên trong
            if obj:IsA("Model") then
                local foundChild = obj.PrimaryPart 
                    or obj:FindFirstChild("PB_HL") 
                    or obj:FindFirstChild("Prompt") 
                    or obj:FindFirstChildWhichIsA("BasePart")
                
                if foundChild then
                    -- BẪY LỖI AN TOÀN: Nếu là nút ấn ProximityPrompt, lấy khối Part cha của nó
                    if foundChild:IsA("ProximityPrompt") then
                        targetPart = foundChild.Parent
                    elseif foundChild:IsA("BasePart") then
                        targetPart = foundChild
                    end
                end
            elseif obj:IsA("BasePart") then
                targetPart = obj
            end
            
            -- Xác nhận linh kiện hợp lệ có thuộc tính .Position trước khi tính khoảng cách
            if targetPart and targetPart:IsA("BasePart") then
                local dist = (rootPosition - targetPart.Position).Magnitude
                if dist < minDistance then 
                    minDistance = dist
                    nearestBoxPart = targetPart 
                end
            end
        end
    end
    return nearestBoxPart
end

local function walkPathToTarget(rootPart, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    -- Tính toán đường đi an toàn bằng Pathfinding
    path:ComputeAsync(rootPart.Position, targetPart.Position)
    
    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - waypoint.Position).Magnitude / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
            task.wait(0.01)
        end
        return true
    else
        -- Cơ chế nhích nhẹ gỡ kẹt vật lý nếu bị chặn đường góc hẹp
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        TweenService:Create(rootPart, TweenInfo.new(3 / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y, nhichPos.Z)}):Play()
        task.wait(0.2)
        return false
    end
end

print("[STAGE 3] Đang định vị trạm điện an toàn sâu trong Power Plant...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            -- Nếu ở xa thì điều hướng di chuyển lại gần trạm điện
            if distance > 4.5 then
                walkPathToTarget(root, targetBox)
            else
                print("[🎉 STAGE 3 SUCCESS] Đã tiếp cận thành công sát cạnh Power Box!")
                reached = true
            end
        else
            -- Nhật ký báo chờ map tải cấu trúc
            print("[-] Đang quét tìm cấu trúc Power Box trong map...")
            task.wait(1)
        end
    end
    task.wait(0.1)
end

return true -- Trả về tín hiệu để file main của bạn tiếp tục lặp lại chu kỳ vòng chơi mới!
