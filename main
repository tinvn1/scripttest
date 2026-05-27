local Workspace = game:GetService("Workspace")
local localPlayer = game:GetService("Players").LocalPlayer

print("[🛠️ STAGE 4] Chuẩn bị kích hoạt luồng tự động sửa máy...")
task.wait(0.5) -- 🌟 QUAN TRỌNG: Nghỉ 0.5s để giải tỏa nghẽn mạng (Event Queue Exhausted) từ Stage 3

-- =========================================================================
-- 🔥 HÀM TÌM CHÍNH XÁC PART "PROMPT" THEO CẤU TRÚC EXPLORER
-- =========================================================================
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
local checkAttempts = 0

-- Chủ động quét tìm khối Prompt (Thử tối đa 20 lần, mỗi lần cách nhau 0.2s để chống đứng script)
repeat
    promptPart = getPowerBoxPromptPart()
    if not promptPart then
        checkAttempts = checkAttempts + 1
        task.wait(0.2)
    end
until promptPart or checkAttempts >= 20

if not promptPart then
    warn("[❌ STAGE 4 ERROR] Không tìm thấy khối Prompt của Power Box sau 4 giây quét! Ép buộc chuyển Stage...")
    _G.CurrentStage = 5
    return false
end

print("[🖱️] Đã định vị thành công khối Prompt. Bắt đầu tiến trình giữ nút sửa máy...")

local repairStarted = true
local startTime = os.clock()

-- Chạy một luồng tương tác song song, giảm tần suất xuống 0.25s để không làm tràn hàng đợi của game
task.spawn(function()
    while repairStarted and promptPart and promptPart.Parent do
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            -- Tương tác bằng phương thức ClickDetector hoặc Touch
            local cd = promptPart:FindFirstChildOfClass("ClickDetector") or promptPart.Parent:FindFirstChildOfClass("ClickDetector")
            if cd and fireclickdetector then
                fireclickdetector(cd)
            elseif promptPart:FindFirstChildOfClass("ProximityPrompt") and fireproximityprompt then
                fireproximityprompt(promptPart:FindFirstChildOfClass("ProximityPrompt"))
            elseif firetouchinterest then
                firetouchinterest(root, promptPart, 0)
                task.wait(0.05)
                firetouchinterest(root, promptPart, 1)
            end
        end
        task.wait(0.25) -- 🌟 Tần suất an toàn, vừa đủ nhanh vừa chống lag/chống văng bảng Robux
    end
end)

-- Vòng lặp đếm giờ chính xác 16 giây để hoàn thành Stage 4
while (os.clock() - startTime) < 16 do
    -- Kiểm tra nếu trong lúc sửa mà máy phát điện bị biến mất hoàn toàn (Đồng đội sửa xong trước)
    if not promptPart or not promptPart.Parent then
        print("[🎯 STAGE 4 SUCCESS] Khối Prompt biến mất sớm. Sửa máy thành công!")
        break
    end
    task.wait(0.1)
end

-- =========================================================================
-- DỌN DẸP SẠCH SẼ & CHUYỂN GIAO THẦN TỐC
-- =========================================================================
repairStarted = false
print("[🎯 STAGE 4 SUCCESS] Đã sửa máy hoàn tất thời gian quy định!")

task.wait(0.2) -- Chờ một chút trước khi sang stage mới
print("[🚀] Kích hoạt chuyển giao sang Stage 5...");
_G.CurrentStage = 5
return true
