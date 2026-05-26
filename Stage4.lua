local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local localPlayer = Players.LocalPlayer

-- Hàm Bypass Click cải tiến: Thử lại nhiều lần để đảm bảo nút được kích hoạt
local function bypassClick(button)
    if not button then return false end
    
    local success = false
    -- Thử lại 5 lần nếu không thành công
    for i = 1, 5 do
        if button and button.Visible then
            print("[Action] Đang thử nhấn nút lần: " .. i)
            if getconnections then
                for _, connection in pairs(getconnections(button.MouseButton1Click)) do
                    connection:Fire()
                end
            end
            button.MouseButton1Click:Fire()
            success = true
            task.wait(0.2)
        end
    end
    return success
end

-- Logic xử lý chính
print("[Stage 5] Bắt đầu quy trình...")

-- 1. Ép chết nhân vật
local char = localPlayer.Character
if char then
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Dead) end
    task.delay(0.5, function() if char then char:Destroy() end end)
end

-- 2. Logic chờ và Click (Cải tiến tính ổn định)
task.spawn(function()
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    
    print("[Wait] Đang chờ UI xuất hiện...")
    
    -- Đợi đến khi nút tồn tại VÀ Visible là true
    while not foundButton do
        for _, obj in pairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                if obj.Visible then -- Kiểm tra trạng thái hiển thị
                    foundButton = obj
                    break
                end
            end
        end
        task.wait(0.5)
    end
    
    -- Thực hiện click với cơ chế thử lại
    if bypassClick(foundButton) then
        print("[Success] Đã nhấn nút thành công. Chờ Rejoin...")
        task.wait(1.5)
        
        -- Rejoin
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = game.JobId
        pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
        end)
    else
        warn("[Error] Không thể kích hoạt nút!")
    end
end)
