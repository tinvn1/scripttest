local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

local function getGenerator()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" or obj.Name == "Gen" or obj.Name == "MainGen" then
            return obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

local function localSpyCheck(genPart)
    if genPart then
        local genModel = genPart:IsA("Model") and genPart or genPart.Parent
        if genModel then
            local currentStage = genModel:GetAttribute("Stage")
            if currentStage and tonumber(currentStage) >= 2 then return true end
        end
    end
    if Workspace:FindFirstChild("GeneratorModel") then return true end
    return false
end

print("[STAGE 2] Đang di chuyển về máy phát điện nạp đồ...")

local genPart = getGenerator()
local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local finalResult = false

if root and genPart then
    local distance = (root.Position - genPart.Position).Magnitude
    if distance > 4 then
        local duration = distance / TWEEN_SPEED
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(genPart.Position + Vector3.new(0, 2, 0))})
        tween:Play()
        tween.Completed:Wait()
    end
    
    local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genPart.Parent:FindFirstChildOfClass("ProximityPrompt")
    if prompt then fireproximityprompt(prompt) else root.CFrame = CFrame.new(genPart.Position) end
    
    print("[⏳ STAGE 2] Đã đổ đồ vào máy! Đang Spy Check...")
    task.wait(1.0) 
    
    for attempt = 1, 6 do
        if localSpyCheck(genPart) then
            finalResult = true
            break 
        end
        task.wait(0.4)
    end
end

_G.StageCompleted = true 
return finalResult
