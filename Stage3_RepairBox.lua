-- =========================================================================
-- 🛡️ CƠ CHẾ KIỂM TRA ĐIỀU KIỆN ĐẦU FILE (CẤP ĐỘ MÁY PHÁT ĐIỆN)
-- =========================================================================
print("[STAGE 3] Đang kiểm tra điều kiện mở map từ Stage 2...")

if _G.GeneratorLevelUp ~= true then
    warn("[❌ STAGE 3 BLOCKED] Máy chưa đạt cấp 2 / Chưa mở map! PHẠT: Quay về Stage 1 lập tức.")
    _G.CurrentStage = 1
    return false -- Ngắt hoàn toàn file Stage 3 tại đây, không chạy bất cứ logic bên dưới nào
end

print("[🎯 STAGE 3 ALLOWED] Máy đã lên cấp 2! Mở khóa cho cơ chế hoạt động.")

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

-- ... (Giữ nguyên phần hàm walkPathToTarget và vòng lặp chính phía dưới của bạn)
