local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 

-- Increased agent radius slightly to prevent wall-rubbing
local path = PathfindingService:CreatePath({
    AgentRadius = 2.4, -- Slightly wider clearance to prevent bumping physics
    AgentHeight = 5, 
    AgentCanJump = true
})

-- =========================================================================
-- HÀM ĐỊNH VỊ TRẠM ĐIỆN THEO ĐÚNG CẤU TRÚC MAP
-- =========================================================================
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

-- =========================================================================
-- 🔥 HÀM DI CHUYỂN THUẦN CHẠY BỘ - TỐI ƯU HÓA TRÁNH SPAM NETWORK
-- =========================================================================
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
            
            -- FIX 1: Only change WalkSpeed if necessary to stop network replication spam!
            if humanoid.WalkSpeed ~= RUN_SPEED then 
                humanoid.WalkSpeed = RUN_SPEED 
            end
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then 
                humanoid.Jump = true 
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startPos = rootPart.Position
            local startTime = os.clock()
            local loopTimeout = os.clock()
            local isStuck = false
            
            while true do
                local currentDist = (rootPart.Position - waypoint.Position).Magnitude
                
                if i == totalWaypoints then
                    if currentDist < 3 then break end
                else
                    if currentDist < 4.5 then break end 
                end
                
                -- CẢM BIẾN THEO DÕI GỠ KẸT VẬT LÝ
                if (os.clock() - startTime) > 0.4 then -- Slightly increased check interval
                    local movedDistance = (rootPart.Position - startPos).Magnitude
                    
                    if movedDistance < 1.5 then
                        humanoid.Jump = true 
                        
                        local escapeAngle = math.rad(math.random(0, 360))
                        local escapeTarget = rootPart.Position + Vector3.new(math.sin(escapeAngle) * 4, 0, math.cos(escapeAngle) * 4)
                        humanoid:MoveTo(escapeTarget)
                        task.wait(0.3) -- Give physics time to resolve
                        
                        isStuck = true 
                        break
                    end
                    
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                
                if (os.clock() - loopTimeout) > 3.5 then 
                    isStuck = true
                    break 
                end
                
                task.wait(0.05) -- FIX 2: Increased from 0.02 to 0.05 to reduce packet fire rate
            end
            
            if isStuck then 
                break 
            end
        end
        return true
    else
        -- If path fails, step back and give the server 0.5s to cool down
        humanoid.Jump = true
        humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 5)
        task.wait(0.5)
        return false
    end
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 3
-- =========================================================================
print("[STAGE 3] Bắt đầu luồng chạy bộ 1 mạch tới trạm điện (Không Tween)...")
local reached = false

while not reached do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
        local targetBox = getNearestPowerBox(root.Position)
        
        if targetBox then
            local distance = (root.Position - targetBox.Position).Magnitude
            
            if distance > 4.5 then
                walkPathToTarget(root, humanoid, targetBox)
            else
                print("[🎯 STAGE 3 SUCCESS] Đã đi bộ tiếp cận sát cạnh trạm điện thành công!");
                reached = true
            end
        else
            task.wait(0.5)
        end
    end
    task.wait(0.1) -- FIX 3: Increased from 0.05 to 0.1 to ease the CPU/Network thread
end

task.wait(0.2)

_G.CurrentStage = 4
return true
