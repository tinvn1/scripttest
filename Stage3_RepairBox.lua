local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 1.8, AgentHeight = 5, AgentCanJump = true})

-- HÀM QUÉT NÂNG CAO: Lục lọi cấu trúc tầng và kiểm tra kiểu dữ liệu an toàn
local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Tìm kiếm Model hoặc Part có tên chính xác là "Power Box"
        if obj.Name == "Power Box" then
            local targetPart = nil
            
            -- Nếu là Model, tìm linh kiện vật lý bên trong
            if obj:IsA("Model") then
                local foundChild = obj.PrimaryPart 
                    or obj:FindFirstChild("PB_HL") 
                    or obj:FindFirstChild("Prompt") 
                    or obj:FindFirstChildWhichIsA("BasePart")
                
                if foundChild then
                    -- BẪY LỖI: Nếu tìm trúng ProximityPrompt, phải lấy khối Part cha của nó
                    if foundChild:IsA("ProximityPrompt") then
                        targetPart = foundChild.Parent
                    elseif foundChild:IsA("BasePart") then
                        targetPart = foundChild
                    end
                end
            elseif obj:IsA("BasePart") then
                targetPart = obj
            end
            
            -- Tính toán khoảng cách an toàn từ khối BasePart hợp lệ
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
    
    -- Tính toán đường đi bằng Pathfinding
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
        -- Cơ chế nhích nhẹ gỡ kẹt vật lý nếu góc hẹp bị vướng công trình
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        TweenService:Create(rootPart, TweenInfo.new(3 / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y, nhichPos.Z)}):Play()
        task.wait(0.2)
        return false
    end
end

print("[STAGE 3] Đang quét vị trí Power Box an toàn...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            -- Nếu ở xa thì di chuyển lại gần trạm điện
            if distance > 4.5 then
                walkPathToTarget(root, targetBox)
            else
                print("[🎉 STAGE 3 SUCCESS] Đã tiếp cận sát cạnh Power Box thành công!")
                reached = true
            end
        else
            print("[-] Đang đợi cấu phần Power Box xuất hiện trên bản đồ...")
            task.wait(1)
        end
    end
    task.wait(0.1)
end

return true -- Trả về tín hiệu kết thúc để Main lặp lại vòng mới
