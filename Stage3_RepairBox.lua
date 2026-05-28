local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- =========================================================================
-- 🔥 HÀM CLICK THẦN TỐC (BYPASS HOÀN TOÀN TRỄ)
-- =========================================================================
local function secureClickThantoc(button)
    if not button then return false end
    if not button.Visible or button.AbsoluteSize.X == 0 or button.AbsoluteSize.Y == 0 then
        return false
    end

    print("[Action] Kích hoạt chuỗi click thần tốc cho: " .. button.Name)
    
    if getconnections then
        for _, connection in pairs(getconnections(button.MouseButton1Click)) do connection:Fire() end
        for _, connection in pairs(getconnections(button.MouseButton1Down)) do connection:Fire() end
    end
    button.MouseButton1Click:Fire()
    return true
end

-- =========================================================================
-- 🏃 LUỒNG DI CHUYỂN, NHẢY VÀ CHỐNG KẸT (PC & MOBILE)
-- =========================================================================
local isRunning = true

local function startAutoMovement()
    task.spawn(function()
        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        
        local lastPosition = rootPart.Position
        local lastStuckCheck = os.clock()
        local moveDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit

        print("[🏃] Khởi động luồng di chuyển chống kẹt...")

        while isRunning and task.wait(0.1) do
            -- Cập nhật lại nếu nhân vật bị reset/chết
            if not character or not character:IsDescendantOf(workspace) or not humanoid or not rootPart then
                character = localPlayer.Character
                if character then
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                    rootPart = character:FindFirstChild("HumanoidRootPart")
                end
            end

            if humanoid Cone and rootPart then
                -- Lệnh cho nhân vật di chuyển liên tục theo hướng đã định
                humanoid:Move(moveDirection, true)

                -- Kiểm tra xem có bị kẹt bởi vật cản không (Không đổi vị trí sau 0.5 giây)
                if (rootPart.Position - lastPosition).Magnitude < 0.5 then
                    if (os.clock() - lastStuckCheck) > 0.5 then
                        -- Gặp vật cản: Kích hoạt Nhảy
                        humanoid.Jump = true 
                        
                        -- Đổi hướng ngẫu nhiên mới để né vật cản
                        moveDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
                        lastStuckCheck = os.clock()
                    end
                else
                    -- Nếu vẫn di chuyển mượt mà thì cập nhật lại vị trí
                    lastPosition = rootPart.Position
                    lastStuckCheck = os.clock()
                    
                    -- Thi thoảng tự nhảy ngẫu nhiên để tăng tốc độ vượt địa hình
                    if math.random(1, 20) == 1 then
                        humanoid.Jump = true
                    end
                end
            end
        end
    end)
end

-- =========================================================================
-- ⏳ LUỒNG THEO DÕI GIAO DIỆN VÀ REJOIN SIÊU TỐC
-- =========================================================================
print("[⏳ STAGE 5] Kích hoạt quét UI và Rejoin siêu tốc...")

-- Kích hoạt di chuyển ngay khi bắt đầu quét UI
startAutoMovement()

task.spawn(function()
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    local startTime = os.clock()
    
    -- Quét tần suất cực cao bằng Heartbeat
    while not foundButton and (os.clock() - startTime) < 20 do
        for _, obj in pairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                if obj.Visible and obj.AbsolutePosition.Y > 0 then
                    foundButton = obj
                    break
                end
            end
        end
        if foundButton then break end
        RunService.Heartbeat:Wait()
    end
    
    -- Dừng luồng di chuyển khi đã tìm thấy nút hoặc hết thời gian
    isRunning = false 
    
    -- Xử lý Rejoin ngay lập tức khi phát hiện ra nút
    if foundButton then
        print("[🎯 SUCCESS] Tìm thấy nút Play Again. Nhấn và nhảy server tức thì...")
        
        secureClickThantoc(foundButton)
        
        print("[🚀] Thực hiện Rejoin Bypass...")
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = game.JobId
        
        local success, err = pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
        end)
        
        if not success then 
            warn("[Error] Lỗi Rejoin: " .. tostring(err)) 
        end
    else
        warn("[Timeout] Quá 20 giây chờ nhưng không thấy nút Play Again xuất hiện!")
    end
end)
