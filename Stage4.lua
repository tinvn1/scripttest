local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

-- =========================================================================
-- 🔥 HÀM DÒ TÌM CHÍNH XÁC NÚT BẤM (PROXIMITYPROMPT) CỦA POWER PLANT
-- =========================================================================
local function getPowerBoxPrompt()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if obj.Parent and obj.Parent.Name == "Power Box" then [cite: 18, 19]
                return obj
            elseif string.find(string.lower(obj.ObjectText), "power plant") or string.find(string.lower(obj.ActionText), "repair") then [cite: 19]
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
    if promptTarget and promptTarget.Parent and promptTarget.Parent:IsA("BasePart") then [cite: 20]
        camera.CameraType = Enum.CameraType.Scriptable [cite: 20]
        local targetPos = promptTarget.Parent.Position [cite: 20]
        camera.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 7), targetPos) [cite: 20]
        task.wait(0.05) -- Giảm thời gian chờ camera xuống mức tối thiểu
        camera.CameraType = Enum.CameraType.Custom [cite: 21]
    end
end

print("[🛠️ STAGE 4] Kích hoạt sửa máy Power Plant (Bản Tốc Độ Cao)...") [cite: 21]

local repairStarted = false
local startTime = os.clock() -- Sử dụng os.clock() để tính chính xác mili-giây
local holdConnection = nil

-- Sử dụng liên kết Heartbeat để quét và xử lý với tốc độ khung hình (siêu nhanh)
local stage4Connection
stage4Connection = RunService.Heartbeat:Connect(function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local prompt = getPowerBoxPrompt()
        
        if prompt then
            -- Bypass thuộc tính che khuất tầm nhìn và tăng khoảng cách bấm
            if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end [cite: 22]
            if prompt.MaxActivationDistance < 15 then prompt.MaxActivationDistance = 25 end [cite: 23]

            if not repairStarted then
                print("[🖱️] Đã tìm thấy nút tương tác!") [cite: 23, 24]
                fixCameraForPrompt(prompt) [cite: 24]
                
                print("[⏳] Tiến hành ép giữ nút sửa máy liên tục...") [cite: 24, 25]
                repairStarted = true
                startTime = os.clock()
                
                -- Vòng lặp đè giữ nút siêu tốc chạy trên luồng phụ
                holdConnection = task.spawn(function()
                    while repairStarted and prompt and prompt.Parent do [cite: 26]
                        if prompt.HoldDuration > 0 then
                            prompt:InputHoldBegin() [cite: 26]
                        end
                        fireproximityprompt(prompt) [cite: 27]
                        task.wait(0.05) -- Tăng tốc độ gửi lệnh giữ (0.05s thay vì 0.1s)
                    end
                end)
            end
            
            -- KIỂM TRA THỜI GIAN THỰC CHÍNH XÁC CAO: Đủ 16 giây là ngắt lập tức
            if repairStarted and (os.clock() - startTime) >= 16 then
                print("[🎯 STAGE 4 SUCCESS] Đã giữ nút sửa máy hoàn tất thời gian!") [cite: 28]
                stage4Connection:Disconnect()
            end
        else
            if repairStarted then
                print("[🎯 STAGE 4 SUCCESS] Nút biến mất. Sửa máy thành công!") [cite: 29, 30]
                stage4Connection:Disconnect()
            end
        end
    end
end)

-- Đợi cho đến khi kết nối quét dứt điểm hoàn toàn Stage 4
while stage4Connection.Connected do task.wait() end

-- DỌN DẸP LẬP TỨC
repairStarted = false
if holdConnection then task.cancel(holdConnection) end [cite: 30, 31]
local finalPrompt = getPowerBoxPrompt() [cite: 31]
if finalPrompt then pcall(function() finalPrompt:InputHoldEnd() end) end [cite: 31]

print("[🚀] Stage 4 hoàn thành sạch sẽ. Kích hoạt chuyển giao sang Stage 5..."); [cite: 31]
_G.CurrentStage = 5
return true
