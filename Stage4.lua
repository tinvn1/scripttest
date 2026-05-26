local Workspace = game:GetService("Workspace")
local localPlayer = game:GetService("Players").LocalPlayer

local function getPowerBoxPrompt()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Prompt" and obj:IsA("ProximityPrompt") then
            if obj.Parent and obj.Parent.Name == "Power Box" then
                return obj
            end
        end
    end
    return nil
end

print("[🛠️ STAGE 4] Bắt đầu tương tác sửa trạm điện thực tế...")

local repairStarted = false
local startTime = os.time()

while true do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local prompt = getPowerBoxPrompt()
        
        if prompt then
            if not repairStarted then
                print("[🖱️] Đã thấy nút Prompt! Tự động nhấn giữ để chạy thanh REPAIR...")
                task.spawn(function()
                    fireproximityprompt(prompt)
                end)
                repairStarted = true
                startTime = os.time()
            end
            
            -- Chờ vòng quay REPAIR chạy đủ thời gian (16 giây) giống video
            if repairStarted and (os.time() - startTime) >= 16 then
                print("[🎯 STAGE 4 HOÀN THÀNH] Đã sửa máy đủ thời gian ván đấu!")
                break
            end
        else
            if repairStarted then
                print("[🎯 STAGE 4 HOÀN THÀNH] Prompt biến mất, máy đã sửa xong!")
                break
            else
                print("[-] Đang chờ trạm điện xuất hiện Prompt sửa...")
            end
        end
    end
    task.wait(0.5)
end

-- 💡 Bạn có thể chèn thêm lệnh chỉnh sửa phụ của bạn ở ngay ĐÂY trước khi qua Stage 5

print("[🚀] Stage 4 XONG. Kích hoạt chuyển giao sang Stage 5 để Reset...");
_G.CurrentStage = 5
return true
