-- =========================================================================
-- 🛡️ CƠ CHẾ CHẶN ĐẦU TỰ ĐỘNG KIỂM TRA BIẾN SỐ CẤP ĐỘ MÁY PHÁT ĐIỆN
-- =========================================================================
print("[STAGE 3] Đang kiểm tra điều kiện mở map...")

if _G.GeneratorLevelUp ~= true then
    warn("[❌ STAGE 3 BLOCKED] Máy chưa lên cấp 2 / Map chưa mở hợp lệ! PHẠT: Quay về Stage 1.")
    _G.CurrentStage = 1
    return false -- Hủy bỏ toàn bộ luồng chạy của file Stage 3 ngay tại đây, không làm gì thêm
end

print("[🎯 STAGE 3 ALLOWED] Máy đã đạt cấp độ yêu cầu! Bắt đầu tiến trình chạy bộ sửa trạm điện.")

-- =========================================================================
-- 🏃‍♂️ TOÀN BỘ LOGIC CHẠY BỘ SỬA TRẠM ĐIỆN GỐC CỦA BẠN (GIỮ NGUYÊN)
-- =========================================================================
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local localPlayer = game:GetService("Players").LocalPlayer
local RUN_SPEED = 30 

local path = PathfindingService:CreatePath({
    AgentRadius = 2.2, 
    AgentHeight = 5, 
    AgentCanJump = true
})

local function getNearestPowerBox(rootPosition)
    local nearestBoxPart = nil
    local minDistance = math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Power Box" then
            local targetPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if not targetPart and obj:FindFirstChild("Prompt") then
                targetPart = obj:FindFirstChild("Prompt").Parent
            end
            if targetPart and targetPart:IsA("BasePart") then
                local dist = (rootPosition - targetPart.Position).Magnitude
                if dist < minDistance then 
                    minDistance = dist
                    nearestBoxPart = targetPart 
                end
            end
        end
    end
    return nearestBoxPart
end

-- ... (Giữ nguyên toàn bộ phần walkPathToTarget và vòng lặp vật lý phía sau của bạn)
