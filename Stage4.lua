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

-- Luồng tương tác liên tục ( Spam click / giữ / touch )
task.spawn(function()
    while repairStarted do
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if promptPart and promptPart.Parent then
            if root and root.Parent then
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

--- NÂNG CẤP LOGIC GIỮ LẠI ĐỂ NHẬN KIM CƯƠNG ---
local maxWaitTime = 16 -- Thời gian sửa máy tối đa
local bonusDelay = 1.5 -- Thời gian "đợi thêm" sau khi biến mất để chắc chắn nhận kim cương
local promptDisappeared = false

while (os.clock() - startTime) < maxWaitTime do
    if not promptPart or not promptPart.Parent then
        if not promptDisappeared then
            print("[💎 INSURANCE] Prompt đã biến mất! Giữ lại luồng 1.5 giây để đợi Server trả Kim Cương...")
            promptDisappeared = true
            task.wait(bonusDelay) -- Đợi thêm 1.5 giây bảo hiểm
            break
        end
    end
    RunService.Heartbeat:Wait()
end

-- Tắt luồng sửa máy
repairStarted = false
print("[🎯 STAGE 4 SUCCESS] Hoàn tất thời gian sửa máy và nhận thưởng!")

task.wait(0.5)
_G.CurrentStage = 5
return true
