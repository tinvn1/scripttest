local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

print("[STAGE 4] Khởi động luồng bẻ khóa trạm điện tối ưu hóa chống lag...")

-- =========================================================================
-- 🔥 HÀM DÒ TÌM NÚT BẤM (CÓ CACHE TRÁNH QUÉT LIÊN TỤC GÂY LAG)
-- =========================================================================
local cachedPrompt = nil

local function getPowerBoxPrompt()
    -- Nếu đã tìm thấy từ trước và nút vẫn còn tồn tại thì dùng luôn, không quét lại
    if cachedPrompt and cachedPrompt:IsDescendantOf(Workspace) then
        return cachedPrompt
    end

    -- Chỉ quét toàn bộ map khi chưa có cache
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            -- Điều kiện 1: Nằm trực tiếp trong đối tượng tên "Power Box"
            if obj.Parent and obj.Parent.Name == "Power Box" then
                cachedPrompt = obj
                return obj
            -- Điều kiện 2: Kiểm tra Text hiển thị trên màn hình
            elseif string.find(string.lower(obj.ObjectText or ""), "power plant") or string.find(string.lower(obj.ActionText or ""), "repair") then
                cachedPrompt = obj
                return obj
            end
        end
    end
    return nil
end

-- =========================================================================
-- ĐIỀU CHỈNH CAMERA AN TOÀN
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
-- VÒNG LẶP THỰC THI CHÍNH
-- =========================================================================
local repairStarted = false
local startTime = os.clock()
local maxSafetyTimeout = os.clock()
local holdConnection = nil
local isFinished = false -- Cờ đánh dấu để thoát vòng lặp chính

local stage4Connection
stage4Connection = RunService.Heartbeat:Connect(function()
    -- QUÁ 25 GIÂY MÀ KHÔNG XONG -> ÉP BUỘC BYPASS
    if (os.clock() - maxSafetyTimeout) > 25 then
        print("[⚠️ DETECTED STUCK] Stage 4 quá thời gian! Ép buộc sang Stage 5...")
        isFinished = true
        stage4Connection:Disconnect()
        return
    end

    local prompt = getPowerBoxPrompt()
    if prompt and prompt:IsDescendantOf(Workspace) then
        -- Cấu hình thuộc tính hack khoảng cách
        if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end
        if prompt.MaxActivationDistance < 20 then prompt.MaxActivationDistance = 30 end
        
        fixCameraForPrompt(prompt)

        if not repairStarted then
            print("[🛠️] Tìm thấy nút trạm điện! Tiến hành kích hoạt...")
            repairStarted = true
            startTime = os.clock()
            
            -- Luồng phụ nhồi lệnh fire liên tục
            holdConnection = task.spawn(function()
                while repairStarted and prompt and prompt:IsDescendantOf(Workspace) do
                    if prompt.HoldDuration > 0 then
                        pcall(function() prompt:InputHoldBegin() end)
                    end
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                    task.wait(0.1) -- Tăng lên 100ms một chút để game kịp nhận lệnh, tránh tràn bộ đệm gây crash
                end
            end)
        end
        
        -- ĐỦ 16 GIÂY -> HOÀN THÀNH
        if repairStarted and (os.clock() - startTime) >= 16 then
            print("[🎯 STAGE 4 SUCCESS] Hoàn thành thời gian giữ nút!")
            isFinished = true
            stage4Connection:Disconnect()
        end
    else
        -- Nếu đang sửa mà nút biến mất (sửa xong sớm)
        if repairStarted then
            print("[🎯 STAGE 4 SUCCESS] Máy phát điện đã biến mất (Đã sửa xong)!")
            isFinished = true
            stage4Connection:Disconnect()
        end
    end
end)

-- Treo luồng chờ Heartbeat hoàn thành nhiệm vụ (Sử dụng biến cờ thay vì Connected để check chính xác)
while not isFinished do 
    task.wait(0.1) 
end

-- =========================================================================
-- DỌN DẸP SẠCH SẼ BỘ NHỚ & CHUYỂN STAGE
-- =========================================================================
repairStarted = false
if holdConnection then
    task.cancel(holdConnection)
end

resetCamera()

-- Thả nút bấm ra nếu còn tồn tại
local finalPrompt = getPowerBoxPrompt()
if finalPrompt and finalPrompt:IsDescendantOf(Workspace) then 
    pcall(function() finalPrompt:InputHoldEnd() end) 
end

task.wait(0.5)

-- 🔥 CHUYỂN GIAO SẠCH SẼ SANG STAGE 5
print("[🚀] Stage 4 hoàn tất an toàn. Chuyển giao luồng sang Stage 5...");
_G.CurrentStage = 5

-- Bạn có thể gọi code Stage 5 trực tiếp ở đây nếu cần thiết
-- Ví dụ: loadstring(game:HttpGet("link_script_stage_5"))()

return true
