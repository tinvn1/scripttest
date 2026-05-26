local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

print("[STAGE 4] Khởi động luồng bẻ khóa trạm điện chống treo đơ...")

-- =========================================================================
-- 🔥 HÀM DÒ TÌM CHÍNH XÁC NÚT BẤM (PROXIMITYPROMPT) CỦA POWER PLANT
-- =========================================================================
local function getPowerBoxPrompt()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            -- Điều kiện 1: Nằm trực tiếp trong đối tượng tên "Power Box"
            if obj.Parent and obj.Parent.Name == "Power Box" then
                return obj
            -- Điều kiện 2: Kiểm tra Text hiển thị trên màn hình có chữ "Power Plant" hoặc "Repair"
            elseif string.find(string.lower(obj.ObjectText), "power plant") or string.find(string.lower(obj.ActionText), "repair") then
                return obj
            end
        end
    end
    return nil
end

-- =========================================================================
-- ĐIỀU CHỈNH CAMERA AN TOÀN (CÓ CƠ CHẾ TỰ RESET NẾU LỖI)
-- =========================================================================
local function fixCameraForPrompt(promptTarget)
    if promptTarget and promptTarget.Parent and promptTarget.Parent:IsA("BasePart") then
        pcall(function()
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = CFrame.new(promptTarget.Parent.Position + Vector3.new(0, 5, 12), promptTarget.Parent.Position)
        end)
    end
end

local function resetCamera()
    pcall(function()
        camera.CameraType = Enum.CameraType.Custom
    end)
end

-- =========================================================================
-- VÒNG LẶP THỰC THI CHÍNH - KHÓA THỜI GIAN CHỐNG TREO ACC
-- =========================================================================
local repairStarted = false
local startTime = os.clock()
local maxSafetyTimeout = os.clock() -- Bộ đếm bảo hiểm tổng thể
local holdConnection = nil

-- Sử dụng kết nối Heartbeat để quét liên tục theo khung hình máy tính, loại bỏ trễ
local stage4Connection
stage4Connection = RunService.Heartbeat:Connect(function()
    -- QUÁ 25 GIÂY MÀ KHÔNG XONG -> ÉP BUỘC HOÀN THÀNH ĐỂ SANG STAGE 5 (CHỐNG TREO ACC)
    if (os.clock() - maxSafetyTimeout) > 25 then
        print("[⚠️ DETECTED STUCK] Stage 4 chạy quá lâu hoặc bị lỗi map! Ép buộc Bypass sang Stage 5...")
        stage4Connection:Disconnect()
        return
    end

    local prompt = getPowerBoxPrompt()
    if prompt then
        -- Tối ưu cấu hình nút bấm để hack khoảng cách tương tác rộng hơn
        if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end
        if prompt.MaxActivationDistance < 20 then prompt.MaxActivationDistance = 30 end
        
        fixCameraForPrompt(prompt)

        if not repairStarted then
            print("[🛠️] Tìm thấy nút trạm điện! Tiến hành kích hoạt luồng giữ nút liên tục...")
            repairStarted = true
            startTime = os.clock() -- Ghi nhận mốc bắt đầu giữ nút chuẩn mili-giây
            
            -- Vòng lặp đè giữ nút siêu tốc chạy trên luồng phụ độc lập
            holdConnection = task.spawn(function()
                while repairStarted and prompt and prompt.Parent do
                    if prompt.HoldDuration > 0 then
                        prompt:InputHoldBegin()
                    end
                    fireproximityprompt(prompt) 
                    task.wait(0.05) -- Tốc độ nhồi lệnh (50ms) giúp sửa máy nhanh hơn
                end
            end)
        end
        
        -- ĐÚNG TRÒN 16 GIÂY (Đo bằng os.clock cực kỳ chuẩn xác) -> Hoàn thành nhiệm vụ
        if repairStarted and (os.clock() - startTime) >= 16 then
            print("[🎯 STAGE 4 SUCCESS] Đã giữ nút sửa máy hoàn tất thời gian lý tưởng!")
            stage4Connection:Disconnect()
        end
    else
        -- Nếu đang sửa mà nút biến mất chứng tỏ máy đã được sửa xong sớm hơn dự kiến
        if repairStarted then
            print("[🎯 STAGE 4 SUCCESS] Máy phát điện đã được sửa xong xuôi!")
            stage4Connection:Disconnect()
        end
    end
end)

-- Treo luồng script chính đợi cho đến khi kết nối Heartbeat phía trên xử lý xong nhiệm vụ
while stage4Connection.Connected do 
    task.wait(0.1) 
end

-- =========================================================================
-- DỌN DẸP SẠCH SẼ BỘ NHỚ KHI KẾT THÚC
-- =========================================================================
repairStarted = false
if holdConnection then
    task.cancel(holdConnection)
end

-- Trả lại Camera bình thường cho game và nhả nút bấm ra
resetCamera()
local finalPrompt = getPowerBoxPrompt()
if finalPrompt then 
    pcall(function() finalPrompt:InputHoldEnd() end) 
end

task.wait(0.3)

-- 🔥 CHUYỂN GIAO SẠCH SẼ SANG STAGE 5 REJOIN
print("[🚀] Stage 4 hoàn tất an toàn. Chuyển giao luồng sang Stage 5...");
_G.CurrentStage = 5
return true
