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
            if obj.Parent and obj.Parent.Name == "Power Box" then
                return obj
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
        local targetPos = promptTarget.Parent.Position
        camera.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 7), targetPos)
        task.wait(0.05) -- Thời gian chờ tối thiểu để game render nút
        camera.CameraType = Enum.CameraType.Custom
    end
end

print("[🛠️ STAGE 4] Kích hoạt sửa máy Power Plant (Luồng Cô Lập)...")

local repairStarted = false
local startTime = os.clock() -- Tính toán chính xác mili-giây
local holdConnection = nil

-- Khởi tạo liên kết quét cục bộ (Local Connection) để tự hủy hoàn toàn khi xong việc
local stage4Connection
stage4Connection = RunService.Heartbeat:Connect(function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local prompt = getPowerBoxPrompt()
        
        if prompt then
            -- Bypass kiểm tra góc nhìn từ trên xuống của game lên ProximityPrompt
            if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end
            if prompt.MaxActivationDistance < 15 then prompt.MaxActivationDistance = 25 end

            if not repairStarted then
                print("[🖱️] Đã tìm thấy nút tương tác!")
                fixCameraForPrompt(prompt)
                
                print("[⏳] Tiến hành ép giữ nút sửa máy liên tục...")
                repairStarted = true
                startTime = os.clock()
                
                -- Luồng ép giữ nút chạy song song tần suất cao
                holdConnection = task.spawn(function()
                    while repairStarted and prompt and prompt.Parent do
                        if prompt.HoldDuration > 0 then
                            prompt:InputHoldBegin()
                        end
                        fireproximityprompt(prompt)
                        task.wait(0.05) -- Nhấn giữ siêu tốc chống tuột phím
                    end
                end)
            end
            
            -- ĐÚNG 16 GIÂY (Tính theo os.clock) -> NGẮT KẾT NỐI NGAY TỨC THÌ
            if repairStarted and (os.clock() - startTime) >= 16 then
                print("[🎯 STAGE 4 SUCCESS] Đã giữ nút sửa máy hoàn tất thời gian!")
                stage4Connection:Disconnect()
            end
        else
            -- Nếu đang sửa mà nút biến mất trước (Do đồng đội sửa xong hoặc game nhận lệnh sớm)
            if repairStarted then
                print("[🎯 STAGE 4 SUCCESS] Nút biến mất. Sửa máy thành công!")
                stage4Connection:Disconnect()
            end
        end
    end
end)

-- Treo luồng script Stage 4 tạm thời cho đến khi Connection phía trên tự hủy hoàn toàn
while stage4Connection.Connected do task.wait() end

-- DỌN DẸP SẠCH SẼ BỘ NHỚ LẬP TỨC
repairStarted = false
if holdConnection then task.cancel(holdConnection) end
local finalPrompt = getPowerBoxPrompt()
if finalPrompt then pcall(function() finalPrompt:InputHoldEnd() end) end

-- CHUYỂN GIAO THẦN TỐC SANG STAGE 5
print("[🚀] Stage 4 hoàn thành sạch sẽ. Kích hoạt chuyển giao sang Stage 5...");
_G.CurrentStage = 5
return true
