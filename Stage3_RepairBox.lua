local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 

local path = PathfindingService:CreatePath({
    AgentRadius = 3, 
    AgentHeight = 5, 
    AgentCanJump = true
})

local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" then
            local targetPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not targetPart and obj:FindFirstChild("Prompt") then
                targetPart = obj:FindFirstChild("Prompt").Parent
            end
            
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

local function walkPathToTarget(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local totalWaypoints = #waypoints
        
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
            if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            
            -- Thực hiện MoveTo liên tục
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local loopTimeout = os.clock()
            
            -- Vòng lặp chạy gối đầu không khựng chân
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                if i == totalWaypoints then
                    if currentDist < 3 then break end
                else
                    if currentDist < 4.5 then break end -- Đạt khoảng cách tối ưu là chuyển waypoint ngay
                end
                
                -- Theo dõi gỡ kẹt vật cản
                if (os.clock() - startTime) > 0.25 then
                    if (rootPart.Position - startPos).Magnitude < 2 then
                        humanoid.Jump = true
                        local lookDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.2, lookDirection.Z * 1.5)
                        humanoid:MoveTo(waypoint.Position)
                    end
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                if (os.clock() - loopTimeout) > 4 then break end
                task.wait()
            end
        end
        return true
    else
        local nhichPos = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
        rootPart.CFrame = CFrame.new(nhichPos.X, rootPart.Position.Y + 1.5, nhichPos.Z)
        task.wait(0.2)
        return false
    end
end

print("[STAGE 3] Bắt đầu luồng chạy bộ 1 mạch tới trạm điện...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        humanoid.WalkSpeed = RUN_SPEED
        local targetBox = getNearestPowerBox(root.Position)
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            if distance > 4.5 then
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã đến sát cạnh trạm điện!");
                reached = true
            end
        else
            task.wait(0.5)
        end
    end
    task.wait(0.05)
end

task.wait(0.2)
_G.CurrentStage = 4
return true
