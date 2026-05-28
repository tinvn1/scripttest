-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 🕒 Ghi lại mốc thời gian bắt đầu chạy Script
local startTimeGlobal = os.clock()
local isForcedRejoining = false 

print("[⚡ SYSTEM] Khởi động Main Loader - Đã sửa lỗi nhấn phím E trên Mobile bằng FirePrompt!");

local baseUrl = "https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/"

-- =========================================================================
-- 🏰 KIỂM TRA VÀ XỬ LÝ LOBBY SẢNH CHỜ (PLACE ID: 90148635862803)
-- =========================================================================
if game.PlaceId == 90148635862803 then
    print("[🏰 LOBBY DETECTED] Đang chạy luồng cấu hình phòng Solo sảnh chờ...");
    
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local localPlayer = Players.LocalPlayer
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local LobbyRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Lobby")

    local function safeClick(button)
        if not button then return false end
        if getconnections then
            local clicked = false
            for _, connection in pairs(getconnections(button.MouseButton1Click)) do connection:Fire() clicked = true end
            for _, connection in pairs(getconnections(button.Activated)) do connection:Fire() clicked = true end
            if clicked then return true end
        end
        local success = pcall(function() button.MouseButton1Click:Fire() end)
        return success
    end

    -- 🏃 BƯỚC 1: TÌM Ô HOÀN TOÀN TRỐNG (0 NGƯỜI) ĐỂ CHIẾM PHÒNG
    local lobbiesFolder = Workspace:FindFirstChild("Lobbies")
    local targetHitbox = nil
    local selectedRoom = nil

    if lobbiesFolder then
        for i = 1, 10 do
            local lobby = lobbiesFolder:FindFirstChild(tostring(i))
            if lobby then
                local labelObj = lobby:FindFirstChildWhichIsA("TextLabel", true) or lobby:FindFirstChild("Status", true)
                if labelObj and (string.find(labelObj.Text, "0/") or string.find(labelObj.Text, "0 Players")) then
                    local hitbox = lobby:FindFirstChild("Hitbox") or lobby:FindFirstChildWhichIsA("BasePart")
                    if hitbox then
                        targetHitbox = hitbox
                        selectedRoom = i
                        break
                    end
                end
            end
        end
    end

    -- ⚡ BƯỚC 2: TIẾN HÀNH CHIẾM GIỮ PHÒNG VÀ KHÓA PHÒNG SOLO
    if targetHitbox then
        print("[💎] Tìm thấy phòng trống số " .. selectedRoom .. "! Tiến hành chiếm giữ phòng...")
        local char = localPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = targetHitbox.CFrame
            task.wait(0.3)
        end
        
        pcall(function() LobbyRemotes.CreateParty:InvokeServer() end)
        task.wait(1.2)
        
        print("[⚙️] Đang ép Server hạ giới hạn phòng xuống 1 người để khóa Solo...")
        pcall(function() LobbyRemotes.SetPartySize:InvokeServer(1) end)
        task.wait(0.5)
        
        local createButton = playerGui:FindFirstChild("Main") 
            and playerGui.Main:FindFirstChild("CreateParty") 
            and playerGui.Main.CreateParty:FindFirstChild("Create")
        
        if createButton then
            print("[🔥] Khóa phòng đơn thành công! Đang nhấn nút khởi động nạp map...")
            safeClick(createButton)
        else
            print("[⚠️] Không thấy nút giao diện UI, gửi Remote cưỡng chế chạy màn chơi đơn từ xa...")
            pcall(function() LobbyRemotes.JoinLobby:InvokeServer("") end)
        end
    else
        warn("[⚠️] Toàn bộ sảnh chờ đều kín phòng! Đang kích hoạt giao thức tạo phòng đơn cách ly khẩn cấp...")
        pcall(function()
            LobbyRemotes.CreateParty:InvokeServer()
            task.wait(0.5)
            LobbyRemotes.SetPartySize:InvokeServer(1)
            task.wait(0.5)
            LobbyRemotes.JoinLobby:InvokeServer("")
        end)
    end

    return true
end

-- =========================================================================
-- ⏱️ LUỒNG ÉP REJOIN KHẨN CẤP ĐÚNG 2 PHÚT (CHỈ CHẠY TRONG PHÒNG FARM)
-- =========================================================================
task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer

    while not isForcedRejoining do
        local elapsed = os.clock() - startTimeGlobal
        
        if elapsed >= 120 then
            isForcedRejoining = true
            print("[⚠️ TIMEOUT] Đã chạm mốc 2 phút khẩn cấp! Đang ép Rejoin...");
            
            local PlayerGui = localPlayer:WaitForChild("PlayerGui")
            for _, obj in pairs(PlayerGui:GetDescendants()) do
                if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                    if getconnections then
                        for _, connection in pairs(getconnections(obj.MouseButton1Click)) do connection:Fire() end
                    end
                    obj:Activate()
                    obj.MouseButton1Click:Fire()
                end
            end
            
            task.wait(0.5)
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ServerInstanceId = game.JobId
            pcall(function()
                TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
            end)
            break
        end
        task.wait(1)
    end
end)

-- =========================================================================
-- 🔄 LUỒNG TỪNG STAGE ĐƯỢC ĐÓNG GÓI CHUẨN ĐỂ GỌI CHUYỀN NHAU
-- =========================================================================
_G.CurrentStage = 0

task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet(baseUrl .. "AutoEquip.lua"))()
    end)
end)

local runOptimizedStage0, runOptimizedStage1, runOptimizedStage2, runOptimizedStage3, runOptimizedStage4, runOptimizedStage5

runOptimizedStage0 = function()
    if isForcedRejoining then return end
    print("[STAGE 0] Đang tải luồng tổng hợp Aura + Drag...");
    pcall(function()
        loadstring(game:HttpGet(baseUrl .. "Stage0_ZHUB.lua"))()
    end)
    _G.CurrentStage = 1
    runOptimizedStage1()
end

runOptimizedStage1 = function()
    if isForcedRejoining then return end
    print("[STAGE 1] Đang tiến hành lấy Xăng (Fuel)...");
    pcall(function()
        loadstring(game:HttpGet(baseUrl .. "Stage1_GetFuel.lua"))()
    end)
end

runOptimizedStage2 = function()
    if isForcedRejoining then return end
    print("[STAGE 2] Đang quay trở lại Máy Phát Điện...");
    pcall(function()
        loadstring(game:HttpGet(baseUrl .. "Stage2_ReturnGen.lua"))()
    end)
end

runOptimizedStage3 = function()
    if isForcedRejoining then return end
    print("[STAGE 3] Đang tiến hành đi sửa Trạm Điện Box...");
    pcall(function()
        loadstring(game:HttpGet(baseUrl .. "Stage3_RepairBox.lua"))()
    end)
end

-- 🔥 THAY THẾ TOÀN BỘ FILE STAGE 4 CŨ - SỬA LỖI INTERACTION TRÊN MOBILE
runOptimizedStage4 = function()
    if isForcedRejoining then return end
    print("[🛠️ STAGE 4 PROMPT] Khởi chạy luồng sửa Power Box tối ưu chuẩn Mobile...");
    _G.CurrentStage = 4
    task.wait(0.2)

    local Workspace = game:GetService("Workspace")
    local localPlayer = game:GetService("Players").LocalPlayer
    
    -- Định vị chính xác phần Prompt của Power Box giống như thiết kế gốc
    local function getPowerBoxPrompt()
        local descendants = Workspace:GetDescendants()
        for i = 1, #descendants do
            local obj = descendants[i]
            if obj:IsA("Model") and obj.Name == "Power Box" then
                -- Tìm ProximityPrompt ẩn sâu bên trong hộp điện
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or obj:FindFirstChild("Prompt", true)
                if prompt then
                    return prompt
                end
            end
        end
        return nil
    end

    local targetPrompt = nil
    local startTimeScan = os.clock()

    -- Quét mục tiêu ban đầu liên tục trong 15 giây
    while not targetPrompt do
        targetPrompt = getPowerBoxPrompt()
        if not targetPrompt then
            if (os.clock() - startTimeScan) > 15 then
                warn("[⚠️ STAGE 4 TIMEOUT] Không quét thấy Power Box. Chuyển cấp cứu sang Stage 5!");
                runOptimizedStage5()
                return false
            end
            task.wait(0.2)
        end
    end

    print("[🎯 STAGE 4] Đã bắt được Prompt của Power Box! Tiến hành cưỡng chế sửa...")
    
    -- Di chuyển CFrame nhân vật đứng khít vào trạm điện để thỏa mãn khoảng cách kiểm tra của trò chơi
    local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local parentPart = targetPrompt.Parent
    if root and parentPart and parentPart:IsA("BasePart") then
        root.CFrame = CFrame.new(parentPart.Position + Vector3.new(0, 1.5, 0))
        task.wait(0.2)
    end

    -- KÍCH HOẠT NHẤN GIỮ KHÔNG QUA PHÍM CƠ (Bypass hoàn toàn lỗi nuốt phím trên Mobile)
    if fireproximityprompt then
        task.spawn(function()
            -- Thực hiện gọi liên tiếp để giả lập hành động nhấn giữ (Hold) ổn định nhất
            while targetPrompt and targetPrompt.Parent and not isForcedRejoining do
                fireproximityprompt(targetPrompt)
                task.wait(0.15) -- Nhịp nhấp giữ bypass tốc độ cao
            end
        end)
    else
        -- Cơ chế dự phòng nếu chạy trên Executor đời cũ không có fireproximityprompt
        pcall(function()
            targetPrompt:InputHoldBegin()
        end)
    end

    -- Theo dõi cho đến khi Power Box được sửa xong hoàn toàn (Biến mất khỏi Map)
    local holdTime = 0
    while targetPrompt and targetPrompt.Parent and holdTime < 18 and not isForcedRejoining do
        holdTime = holdTime + 0.5
        task.wait(0.5)
    end

    -- Giải phóng lệnh giữ sau khi kết thúc nhiệm vụ
    pcall(function()
        if targetPrompt then targetPrompt:InputHoldEnd() end
    end)

    print("[💎 STAGE 4 SUCCESS] Sửa hộp điện hoàn tất trên thiết bị Mobile! Chuyển sang Stage 5...");
    runOptimizedStage5()
end

runOptimizedStage5 = function()
    if isForcedRejoining then return end
    print("[STAGE 5] Quét giao diện nút bấm kết thúc màn...");
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local RunService = game:GetService("RunService")
    local localPlayer = Players.LocalPlayer

    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local foundButton = nil
    local startTime = os.clock()
    
    while not foundButton and (os.clock() - startTime) < 15 and not isForcedRejoining do
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
    
    if foundButton and not isForcedRejoining then
        if getconnections then
            for _, connection in pairs(getconnections(foundButton.MouseButton1Click)) do connection:Fire() end
        end
        foundButton.MouseButton1Click:Fire()
        
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = game.JobId
        pcall(function()
            TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
        end)
    end
end

-- =========================================================================
-- ⚡ BỘ LẮNG NGHE SỰ KIỆN ĐỔI STAGE CHỦ ĐỘNG (ANTI-STUCK THẦN TỐC)
-- =========================================================================
task.spawn(function()
    local lastState = _G.CurrentStage
    while not isForcedRejoining do
        if _G.CurrentStage ~= lastState then
            local newState = _G.CurrentStage
            print("[🔄 STATE CHANGED] Stage chuyển từ " .. lastState .. " -> " .. newState)
            lastState = newState
            
            if newState == 2 then
                task.spawn(runOptimizedStage2)
            elseif newState == 3 then
                task.spawn(runOptimizedStage3)
            elseif newState == 4 then
                task.spawn(runOptimizedStage4)
            end
        end
        task.wait(0.05)
    end
end)

-- Khởi động chạy Stage đầu tiên
task.spawn(runOptimizedStage0)
