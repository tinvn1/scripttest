local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("[💀 STAGE 5] Phát hiện Anti-Reset trực tiếp! Kích hoạt phương thức phá hủy luồng nhân vật...")

local char = localPlayer.Character
if char then
    -- PHƯƠNG PHÁP 1: Xóa bỏ trực tiếp các bộ phận cốt lõi để ép Game Server phải xử lý Game Over
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    
    if humanoid then
        -- Thay vì trừ máu, ta ngắt kết nối trạng thái sống của Humanoid
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
    
    -- Phá hủy khớp nối đầu hoặc cổ để buộc nhân vật phải rã ra (Game tự tính là tử trận)
    if head and head:FindFirstChildOfClass("Weld") then
        head:FindFirstChildOfClass("Weld"):Destroy()
    elseif char:FindFirstChild("Torso") and char.Torso:FindFirstChild("Neck") then
        char.Torso.Neck:Destroy()
    elseif char:FindFirstChild("UpperTorso") and char.UpperTorso:FindFirstChild("Neck") then
        char.UpperTorso.Neck:Destroy()
    end
    
    -- Biện pháp bọc lót cuối cùng: Tự xóa vật thể cấu trúc nhân vật ở phía Client
    task.delay(0.2, function()
        if char and char.Parent then
            char:Destroy()
        end
    end)
end

-- =========================================================================
-- VÒNG LẶP KIỂM TRA TRẠNG THÁI ĐỂ CHUYỂN SANG BẤM PLAY AGAIN (STAGE 6)
-- =========================================================================
print("[⏳ STAGE 5] Đang đợi giao diện bảng Game Over (Play Again) xuất hiện...")

local PlayerGui = localPlayer:WaitForChild("PlayerGui")
local isGameOverReady = false

while not isGameOverReady do
    local gameOverVisible = false
    
    -- Dò tìm bảng UI hồi sinh / Play Again xuất hiện trên màn hình
    for _, gui in pairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") and (string.find(string.lower(gui.Text), "play again") or gui.Name == "PlayAgain") then
            if gui.Visible then
                gameOverVisible = true
                break
            end
        end
    end
    
    -- Khi bảng UI đã tải ra thành công, chứng tỏ nhân vật đã reset sạch sẽ
    if gameOverVisible then
        print("[🎯 STAGE 5 SUCCESS] Đã vượt qua Anti-Reset! Trận đấu đã kết thúc.")
        break
    end
    task.wait(0.5)
end

task.wait(1) -- Chờ thêm 1 giây để UI ổn định vị trí click

print("[🚀] Chuyển giao luồng sang Stage 6 để tự động bấm nút Replay...");
_G.CurrentStage = 6
return true
