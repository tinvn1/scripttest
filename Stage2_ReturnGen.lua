local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30

local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})

-- Cấu hình vị trí đích của Stage 2 (Thay đổi Vector3 phù hợp với vị trí mong muốn của bạn)
local STAGE2_TARGET_POS = Vector3.new(100, 0, 100) 

local function walkToStage2Target(rootPart, humanoid)
    path:ComputeAsync(rootPart.Position, STAGE2_TARGET_POS)
    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            if humanoid.WalkSpeed ~= RUN_SPEED then humanoid.WalkSpeed = RUN_SPEED end
            if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            
            humanoid:MoveTo(waypoint.Position)
            
            local movedToFinished = false
            local startPos = rootPart.Position
            local startTime = os.clock()
            
            local connection = humanoid.MoveToFinished:Connect(function()
                movedToFinished = true
            end)
            
            while not movedToFinished do
                if (os.clock() - startTime) > 0.35 then
                    if (rootPart.Position - startPos).Magnitude < 2 then
                        humanoid.Jump = true
                        rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 3.2, 0)
                        humanoid:MoveTo(waypoint.Position)
                    end
                    startTime = os.clock()
                    startPos = rootPart.Position
                end
                task.wait(0.05)
            end
            if connection then connection:Disconnect() end
        end
        return true
    end
    return false
end

print("[STAGE 2] Khởi chạy di chuyển khu vực...")
local stage2Finished = false

while not stage2Finished do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if root and humanoid then
        humanoid.WalkSpeed = RUN_SPEED
        local dist = (root.Position - STAGE2_TARGET_POS).Magnitude
        if dist > 5 then
            walkToStage2Target(root, humanoid)
        else
            stage2Finished = true
        end
    end
    task.wait(0.1)
end

print("[🚀] Stage 2 xong. Qua Stage 3...");
_G.CurrentStage = 3
return true
