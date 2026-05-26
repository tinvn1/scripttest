local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 

local path = PathfindingService:CreatePath({
    AgentRadius = 2, 
    AgentHeight = 5, 
    AgentCanJump = true
})

-- Hàm tìm vật phẩm thông minh dựa trên thuộc tính tương tác của game
local function getTargetItem(rootPosition)
    local nearestItem = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Kiểm tra các vật thể có thể nhặt được (Tools, Parts có Prompt hoặc ClickDetector)
        if obj:IsA("TouchTransmitter") or obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            local targetPart = obj.Parent
            if targetPart and targetPart:IsA("BasePart") and targetPart.Name ~= "HumanoidRootPart" then
                -- Loại trừ các trạm điện "Power Box" của Stage 3-4
                if targetPart.Name ~= "Power Box" and targetPart.Parent.Name ~= "Power Box" then
                    local dist = (rootPosition - targetPart.Position).Magnitude
                    if dist < minDistance and dist > 1 then 
                        minDistance = dist
                        nearestItem = targetPart 
                    end
                end
            end
        end
    end
    return nearestItem
end

local function walkPathToItem(rootPart, humanoid, targetPart)
    if not rootPart or not targetPart or not targetPart.Parent then return false end
    
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for i, waypoint in ipairs(waypoints) do
            if not rootPart.Parent or not targetPart.Parent then return false end
            if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
            if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            
            humanoid:MoveTo(waypoint.Position)
            
            local movedToFinished = false
            local startPos = rootPart.Position
            local startTime = os.clock()
            
            local connection
            connection = humanoid.MoveToFinished:Connect(function()
                movedToFinished = true
                connection:Disconnect()
            end)
            
            while not movedToFinished do
                if (os.clock() - startTime) > 0.35 then
                    if (rootPart.Position - startPos).Magnitude < 2 then
                        humanoid.Jump = true
                        local lookDirection = (waypoint.Position - rootPart.Position).Unit
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(lookDirection.X * 1.5, 3.2, lookDirection.Z * 1.5)
                        humanoid:MoveTo(waypoint.Position)
                    end
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                task.wait(0.05)
            end
        end
        return true
    else
        return false
    end
end

print("[STAGE 1] Khởi chạy dò đường nhặt đồ...")
local stage1Finished = false
local noItemCount = 0

while not stage1Finished do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        humanoid.WalkSpeed = RUN_SPEED
        local targetItem = getTargetItem(root.Position)
        
        if targetItem then
            noItemCount = 0
            local distance = (root.Position - targetItem.Position).Magnitude
            if distance > 4 then
                walkPathToItem(root, humanoid, targetItem)
            else
                -- Thực hiện nhặt đồ bằng cách kích hoạt sự kiện tương tác
                local prompt = targetItem:FindFirstChildOfClass("ProximityPrompt") or targetItem.Parent:FindFirstChildOfClass("ProximityPrompt")
                local cd = targetItem:FindFirstChildOfClass("ClickDetector") or targetItem.Parent:FindFirstChildOfClass("ClickDetector")
                
                if prompt then fireproximityprompt(prompt)
                elseif cd then fireclickdetector(cd)
                else
                    -- Di chuyển đè lên vật phẩm để nhặt tự động bằng Touch
                    root.CFrame = CFrame.new(targetItem.Position)
                end
                task.wait(0.2)
            end
        else
            noItemCount = noItemCount + 1
            if noItemCount > 5 then stage1Finished = true end -- Không thấy đồ sau 5 lần quét thì qua stage
        end
    end
    task.wait(0.1)
end

print("[🚀] Stage 1 xong. Qua Stage 2...");
_G.CurrentStage = 2
return true
