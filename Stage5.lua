local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local localPlayer = Players.LocalPlayer

-- 1. Hàm hỗ trợ click bằng cách kích hoạt kết nối sự kiện (Bypass UI)
local function bypassClick(button)
    if not button then return end
    print("[Action] Đang kích hoạt nút: " .. button.Name)
    if getconnections then
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do
            connection:Fire()
        end
    else
        button.MouseButton1Click:Fire()
    end
end

-- 2. Logic chính
print("[Stage 5] Bắt đầu quy trình ép chết và hồi sinh...")

local char = localPlayer.Character
if char then
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
    
    -- Xóa khớp cổ để đảm bảo cơ chế chết của server được kích hoạt
    local head = char:FindFirstChild("Head")
    if head then
        for _, v in pairs(head:GetChildren()) do
            if v:IsA("Weld") or v:IsA("Motor6D") then v:Destroy() end
        end
    end
    
    -- Xóa nhân vật ở Client để dọn dẹp
    task.delay(0.5, function()
        if char and char.Parent then char:Destroy() end
    end)
end

-- 3. Chờ giao diện hiện lên và thực hiện Rejoin
task.spawn(function()
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    
    print("[Wait] Đang đợi giao diện Play Again...")
    
    -- Lặp lại đến khi thấy nút
    while not foundButton do
        for _, obj in pairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                foundButton = obj
                break
            end
        end
        task.wait(0.5)
    end
    
    -- Thực hiện hành động
    if foundButton then
        bypassClick(foundButton)
        task.wait(1)
        
        -- Thực hiện Rejoin vào đúng server cũ
        print("[Final] Thực hiện Rejoin...")
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = game.JobId
        
        local success, err = pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
        end)
        
        if not success then warn("Lỗi Rejoin: " .. tostring(err)) end
    end
end)
