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
-- 🏃 LUỒNG DI CHUYỂN PHÁ ĐỊA HÌNH VÀ CHỐNG KẸT CẤP CAO
-- =========================================================================
local isRunning = true

local function startAutoMovement()
    task.spawn(function()
        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        
        local lastPosition = rootPart.Position
        local lastCheckTime = os.clock()
        -- Hướng ban đầu lấy theo hướng nhìn của nhân vật thay vì ngẫu nhiên hoàn toàn
        local moveDirection = rootPart.CFrame.LookVector 

        print("[🏃] Khởi động luồng di chuyển phá kẹt địa hình...")

        while isRunning and task.wait(0.05) do -- Tăng tốc độ quét (0.05s) để phản xạ nhanh hơn
            if not character or not character:IsDescendantOf(workspace) or not humanoid or not rootPart then
                character = localPlayer.Character
                if character then
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                    rootPart = character:FindFirstChild("HumanoidRootPart")
                end
            end

            if humanoid and rootPart then
                -- Bắt buộc đi theo hướng đã chọn
                humanoid:Move(moveDirection, true)

                -- 🛠️ CƠ CHẾ 1: DÙNG RAYCAST QUÉT VẬT CẢN TRƯỚC MẶT (Cây, Gờ tường, Terrain dốc)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterPlayers = true
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {character}

                -- Phóng 1 tia từ ngang hông ra phía trước 4 studs
                local rayOrigin = rootPart.Position - Vector3.new(0, 1, 0) 
                local rayDirection = moveDirection * 4
                local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

                if raycastResult then
                    -- Phát hiện vật cản trước mặt -> Nhảy lập tức để vượt gờ dốc
                    humanoid.Jump = true
                end

                -- 🛠️ CƠ CHẾ 2: KIỂM TRA TỌA ĐỘ PHÁ KẸT TUYỆT ĐỐI (Nếu kẹt quá 0.3 giây)
                if (os.clock() - lastCheckTime) >= 0.3 then
                    local distanceMoved = (rootPart.Position - lastPosition).Magnitude
                    
                    if distanceMoved < 0.6 then
                        -- Phát hiện bị dậm chân tại chỗ! Kích hoạt combo phá kẹt:
                        humanoid.Jump = true
                        
                        -- Ép nhân vật quay ngoắt một góc từ 90 đến 180 độ để thoát khỏi gốc cây/gờ đất
                        local angle = math.random(90, 180)
                        local rad = math.rad(angle)
                        local cos, sin = math.cos(rad), math.sin(rad)
                        
                        -- Tính toán hướng né mới
                        moveDirection = Vector3.new(
                            moveDirection.X * cos - moveDirection.Z * sin,
                            0,
                            moveDirection.X * sin + moveDirection.Z * cos
                        ).Unit
                    end
                    
                    -- Cập nhật dữ liệu cho chu kỳ quét tiếp theo
                    lastPosition = rootPart.Position
                    lastCheckTime = os.clock()
                end

                -- Tự động nhảy nhấp nhô liên tục (Rất hiệu quả trên Mobile/PC khi chạy trên địa hình Terrain)
                if math.random(1, 15) == 1 then
                    humanoid.Jump = true
                end
            end
        end
    end)
end

-- =========================================================================
-- ⏳ LUỒNG THEO DÕI GIAO DIỆN VÀ REJOIN SIÊU TỐC
-- =========================================================================
print("[⏳ STAGE 5] Kích hoạt quét UI và Rejoin siêu tốc...")

startAutoMovement()

task.spawn(function()
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    local startTime = os.clock()
    
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
    
    isRunning = false 
    
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
