local Workspace = game:GetService("Workspace")
local localPlayer = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

-- =========================================================================
-- 🔥 HÀM DÒ TÌM CHÍNH XÁC NÚT BẤM (PROXIMITYPROMPT) CỦA POWER PLANT
-- =========================================================================
local function getPowerBoxPrompt()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            -- Điều kiện 1: Nằm trực tiếp trong đối tượng tên "Power Box"
            if obj.Parent and obj.Parent.Name == "Power Box" then
                return obj
            -- Điều kiện 2: Kiểm tra Text hiển thị trên màn hình có chữ "Power Plant" or "Repair"
            elseif string.find(string.lower(obj.ObjectText), "power plant") or string.find(string.lower(obj.ActionText), "repair") then
                return obj
            end
        end
    end
    return nil
end

-- =========================================================================
-- ĐIỀU CHỈNH CAMERA NGANG ĐỂ KHÔNG BỊ LỖI GÓC NHÌN TỪ TRÊN XUỐNG
-- =========================================================================
local function fixCameraForPrompt(promptTarget)
    if promptTarget and promptTarget.Parent and promptTarget.Parent:IsA("BasePart") then
        camera.CameraType = Enum.CameraType.Scriptable
        -- Ép camera nhìn ngang thẳng vào Power Box thay vì chúi đầu từ trên xuống
        local targetPos = promptTarget.Parent.Position
        camera.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 7), targetPos)
        task.wait(0.1)
        camera.CameraType = Enum.CameraType.Custom
    end
end

print("[🛠️ STAGE 4] Kích hoạt sửa máy Power Plant + Fix góc nhìn Camera...")

local repairStarted = false
local startTime = os.time()
local holdConnection = nil

while true do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local prompt = getPowerBoxPrompt()
        
        if prompt then
            -- BẺ KHÓA PROXIMITYPROMPT: Tắt kiểm tra góc nhìn (Line of Sight)
            -- Điều này giúp nút luôn luôn tương tác được bất kể camera đang ở góc nào
            if prompt.RequiresLineOfSight then
                prompt.RequiresLineOfSight = false
            end
            
            -- Ép khoảng cách tương tác lớn hơn để tránh bị hụt khi đứng xa
            if prompt.MaxActivationDistance < 15 then
                prompt.MaxActivationDistance = 25
            end

            if not repairStarted then
                print("[🖱️] Đã tìm thấy nút tương tác!")
                
                -- Sửa góc camera ngay lập tức để nút không bị kẹt ẩn
                fixCameraForPrompt(prompt)
                
                print("[⏳] Tiến hành ép giữ nút sửa máy liên tục...")
                repairStarted = true
                startTime = os.time()
                
                -- Vòng lặp đè giữ nút siêu tốc
                holdConnection = task.spawn(function()
                    while repairStarted and prompt and prompt.Parent do
                        if prompt.HoldDuration > 0 then
                            prompt:InputHoldBegin()
                        end
                        fireproximityprompt(prompt) 
                        task.wait(0.1)
                    end
                end)
            end
            
            -- Chờ chạy hết 16 giây
            if repairStarted and (os.time() - startTime) >= 16 then
                print("[🎯 STAGE 4 SUCCESS] Đã giữ nút sửa máy hoàn tất thời gian!")
                break
            end
        else
            if repairStarted then
                print("[🎯 STAGE 4 SUCCESS] Nút tương tác biến mất. Sửa máy thành công!")
                break
            else
                print("[-] Đang chờ nhân vật đứng sát hoặc chờ nút sửa máy xuất hiện...")
            end
        end
    end
    task.wait(0.2)
end

-- DỌN DẸP
if holdConnection then
    task.cancel(holdConnection)
    local finalPrompt = getPowerBoxPrompt()
    if finalPrompt then pcall(function() finalPrompt:InputHoldEnd() end) end
end

print("[🚀] Stage 4 hoàn thành sạch sẽ. Kích hoạt chuyển giao sang Stage 5...");
_G.CurrentStage = 5
return true
