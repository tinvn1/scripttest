local localPlayer = game:GetService("Players").LocalPlayer

print("[💀 STAGE 5] Bắt đầu tác vụ: Tự động Reset nhân vật...")

local char = localPlayer.Character
if char then
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        -- Thực hiện hành động Reset nhân vật giống trong video
        humanoid.Health = 0
    end
end

-- Vòng lặp kiểm tra cho đến khi nhân vật thực sự chết hẳn mới cho qua Stage tiếp theo
print("[⏳ STAGE 5] Đang kiểm tra trạng thái... Đợi nhân vật tử trận hoàn toàn.")
while true do
    local currentChar = localPlayer.Character
    local currentHumanoid = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
    
    -- Nếu không còn nhân vật hoặc máu đã về 0, xác nhận hoàn thành Stage 5
    if not currentHumanoid or currentHumanoid.Health <= 0 then
        print("[🎯 STAGE 5 SUCCESS] Nhân vật đã reset thành công!")
        break
    end
    task.wait(0.5)
end

-- Chờ thêm 1 giây để bảng UI Game Over kịp tải ra trước khi sang Stage 6
task.wait(1)

print("[🚀] Stage 5 hoàn thành sạch sẽ. Kích hoạt chuyển giao sang Stage 6...");
_G.CurrentStage = 6
return true
