local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("[🛠️ STAGE 4] Kích hoạt luồng sửa máy phát điện thế hệ mới...");
task.wait(1.0) 

local function getPowerBoxPromptPart()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Power Box" then
            local promptPart = obj:FindFirstChild("Prompt")
            if promptPart and promptPart:IsA("BasePart") then
                return promptPart
            end
        end
    end
    return nil
end

local promptPart = nil
local startTimeScan = os.clock()

while not promptPart do
    promptPart = getPowerBoxPromptPart()
    if not promptPart then
        if (os.clock() - startTimeScan) > 15 then
            warn("[⚠️ STAGE 4 TIMEOUT] Không tìm thấy Power Box sau 15 giây. Chuyển thẳng sang Stage 5!");
            _G.CurrentStage = 5
            return false
        end
        task.wait(0.2)
    end
end

print("[🖱️] Đã khóa mục tiêu khối Prompt thành công: " .. promptPart:GetFullName())

local repairStarted = true
local startTime = os.clock()

task.spawn(function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    while repairStarted do
        if promptPart and promptPart.Parent then
            if root and root.Parent then
                -- FIXED: Removed undefined variable 'i' from Vector3
                root.CFrame = CFrame.new(promptPart.Position + Vector3.new(0, 1, 1)) * CFrame.Angles(0, 0, 0)
            end

            local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt") or promptPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if prompt and fireproximityprompt then
                fireproximityprompt(prompt)
            end
            
            local cd = promptPart:FindFirstChildOfClass("ClickDetector") or promptPart.Parent:FindFirstChildOfClass("ClickDetector")
            if cd and fireclickdetector then
                fireclickdetector(cd)
            end
            
            if firetouchinterest and root then
                firetouchinterest(root, promptPart, 0)
                RunService.Heartbeat:Wait()
                firetouchinterest(root, promptPart, 1)
            end
        end
        task.wait(0.1) 
    end
end)

while (os.clock() - startTime) < 16 do
    if not promptPart or not promptPart.Parent then
        print("[🎯 STAGE 4 SUCCESS] Khối Prompt biến mất sớm. Sửa máy thành công!")
        break
    end
    RunService.Heartbeat:Wait()
end

repairStarted = false
print("[🎯 STAGE 4 SUCCESS] Hoàn tất thời gian sửa máy quy định!")

task.wait(0.2)
_G.CurrentStage = 5
return true
