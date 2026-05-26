local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30 -- Tốc độ lướt Tween mặc định của bạn

-- =========================================================================
-- 🔥 HÀM DÒ TÌM VẬT PHẨM THEO KHOẢNG CÁCH (TWEEN GỐC)
-- =========================================================================
local function getTargetItem(rootPosition)
    local nearestItem = nil
    local minDistance = math.huge
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Tìm kiếm vật phẩm dựa trên tên hoặc thuộc tính Touch cơ bản
        if obj.Name == "Item" or obj.Name == "Loot" or obj:IsA("Tool") then
            local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            
            if targetPart and targetPart:IsA("BasePart") then
                local dist = (rootPosition - targetPart.Position).Magnitude
                if dist < minDistance then 
                    minDistance = dist
                    nearestItem = targetPart 
                end
            end
        end
    end
    return nearestItem
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 1 (TWEEN THẲNG KHÔNG DÒ ĐƯỜNG)
-- =========================================================================
print("[STAGE 1] Khởi chạy thu gom vật phẩm bằng Tween Service...")
local stage1Finished = false

while not stage1Finished do
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local targetItem = getTargetItem(root.Position)
        
        if targetItem then
            local distance = (root.Position - targetItem.Position).Magnitude
            
            -- Nếu ở xa, dùng TweenService dịch chuyển thẳng tới vị trí vật phẩm
            if distance > 3.5 then
                -- Tính toán thời gian di chuyển dựa trên khoảng cách và tốc độ cố định
                local duration = distance / TWEEN_SPEED
                local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                
                -- Tạo Tween dịch chuyển CFrame trực tiếp
                local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetItem.Position)})
                tween:Play()
                tween.Completed:Wait() -- Đợi cho đến khi lướt tới nơi
            else
                print("[🎯 STAGE 1 SUCCESS] Đã tiếp cận vật phẩm bằng Tween!")
                
                -- Thực hiện kích hoạt nhặt đồ (nếu có Prompt)
                local prompt = targetItem:FindFirstChildOfClass("ProximityPrompt") or targetItem.Parent:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                end
                
                stage1Finished = true -- Hoàn thành chặng 1
            end
        else
            -- Dự phòng nếu không tìm thấy đồ trên Map
            print("[🏁 STAGE 1] Không tìm thấy vật phẩm nào.")
            stage1Finished = true
        end
    end
    task.wait(0.2)
end

task.wait(0.5)

-- 🔥 CHUYỂN GIAO: Kích hoạt Stage 2
print("[🚀] Stage 1 hoàn tất sạch sẽ. Chuyển giao luồng sang Stage 2...");
_G.CurrentStage = 2
return true
