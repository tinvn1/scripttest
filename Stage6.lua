local localPlayer = game:GetService("Players").LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

print("[🔄 STAGE 6] Bắt đầu tác vụ: Tự động tìm nút Play Again để làm mới trận đấu...")

local clicked = false

while not clicked do
    -- Quét toàn bộ các đối tượng UI trên màn hình để tìm nút Play Again
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        -- Lọc tìm TextButton có chữ "play again" hoặc tên đối tượng là PlayAgain
        if gui:IsA("TextButton") and (string.find(string.lower(gui.Text), "play again") or gui.Name == "PlayAgain") then
            if gui.Visible then
                print("[🖱️ STAGE 6] Đã tìm thấy nút Play Again trên giao diện! Đang giả lập click...")
                
                -- Kích hoạt hành động click chuột vào nút
                gui:MouseButton1Click()
                if firesignal then
                    firesignal(gui.MouseButton1Click) -- Lệnh fire nâng cao để chắc chắn Executor nhận lệnh
                end
                
                clicked = true
                break
            end
        end
    end
    task.wait(0.5) -- Quét mỗi nửa giây để tránh gây đứng/lag màn hình game
end

print("[🎉 STAGE 6 SUCCESS] Đã kích hoạt Replay trận đấu mới thành công!")
task.wait(2)

-- Trận đấu quay về Day 1, đưa mạch code quay ngược trở lại Stage 1 để đi nhặt xăng từ đầu
_G.CurrentStage = 1
return true
