if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

-- 🕒 Ghi lại mốc thời gian bắt đầu chạy Script (Tính bằng os.clock chính xác cao)
local startTimeGlobal = os.clock()
local isForcedRejoining = false -- Biến trạng thái chặn chạy tiếp khi đang Rejoin

print("[⚡ CRITICAL SYSTEM] Khởi động Main Loader - Ép giới hạn cứng Rejoin đúng 2 phút!");

local baseUrl = "https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/"

-- =========================================================================
-- ⏱️ LUỒNG ÉP REJOIN KHẨN CẤP ĐÚNG 2 PHÚT (CHẠY SONG SONG NGAY TỪ ĐẦU)
-- =========================================================================
task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer

    -- Vòng lặp kiểm tra liên tục mỗi 0.1 giây để bắt trúng mốc thời gian
    while not isForcedRejoining do
        local elapsed = os.clock() - startTimeGlobal
        
        -- 🔥 NẾU CHẠM HOẶC VƯỢT QUÁ 2 PHÚT (120 GIÂY) -> ÉP REJOIN LẬP TỨC
        if elapsed >= 120 then
            isForcedRejoining = true
            print("[⚠️ CRITICAL TIMEOUT] Đã chạm mốc 2 phút! Ép kích hoạt Rejoin Stage 5 ngay lập tức...");
            
            -- Thực hiện kích click bọc lót nếu nút Play Again có sẵn trên màn hình
            local PlayerGui = localPlayer:WaitForChild("PlayerGui")
            for _, obj in pairs(PlayerGui:GetDescendants()) do
                if obj:IsA("TextButton") and (string.find(string.lower(obj.Text), "play again") or obj.Name == "PlayAgain") then
                    if obj.Visible and obj.AbsolutePosition.Y > 0 then
                        if getconnections then
                            for _, connection in pairs(getconnections(obj.MouseButton1Click)) do connection:Fire() end
                        end
                        obj.MouseButton1Click:Fire()
                        break
                    end
                end
            end
            
            -- Lệnh ép nhảy Server khẩn cấp Bypass qua mọi tiến trình khác
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ServerInstanceId = game.JobId
            
            -- Thực hiện vòng lặp ép Teleport cho tới khi thành công (đề phòng lỗi mạng)
            while true do
                pcall(function()
                    TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
                end)
                task.wait(1) -- Chờ 1 giây rồi thử lại nếu chưa bay Server
            end
            break
        end
        task.wait(0.1)
    end
end)

-- Hàm nạp file từ GitHub có kiểm tra trạng thái ép Rejoin
local function runFile(fileName)
    if isForcedRejoining then return end -- Nếu đã quá 2 phút thì không nạp file mới nữa

    local success, content = pcall(function() 
        return game:HttpGet(baseUrl .. fileName) 
    end)
    
    if success and content then
        -- Khắc phục lỗi chính tả hệ thống gốc của bạn
        content = string.gsub(content, "Enum%.PathJointAction", "Enum.PathWaypointAction")
        content = string.gsub(content, "PathJointAction", "PathWaypointAction")
        
        local func, err = loadstring(content)
        if func then
            print("[▶️ RUNNING] Cấu phần: " .. fileName)
            func()
        else
            warn("Lỗi biên dịch cấu phần: " .. fileName .. " | " .. tostring(err))
        end
    else
        warn("Không thể tải file từ GitHub: " .. fileName)
    end
end

-- =========================================================================
-- 🛡️ GIAI ĐOẠN 0: KHỞI CHẠY ZHUB VÀ THIẾT LẬP MENU PHỤ TRỢ
-- =========================================================================
local function initializeZHub()
    if isForcedRejoining then return end
    
    local successLoad, errLoad = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
    end)
    
    if not successLoad then return end

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local targetGui = nil

    for i = 1, 15 do
        if isForcedRejoining then return end
        targetGui = game:GetService("CoreGui"):FindFirstChild("ZHUB") or player.PlayerGui:FindFirstChild("ZHUB") or game:GetService("CoreGui"):FindFirstChildOfClass("ScreenGui")
        if targetGui then break end
        task.wait(0.2)
    end

    local function clickButton(btn)
        if btn then
            local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
            for _, event in ipairs(events) do
                if btn[event] then
                    if getconnections then
                        for _, connection in pairs(getconnections(btn[event])) do connection:Fire() end
                    else
                        btn[event]:Fire()
                    end
                end
            end
        end
    end

    if getgenv().Flags then
        if getgenv().Flags["Auto Drag"] ~= nil then getgenv().Flags["Auto Drag"]:Set(true)
        elseif getgenv().Flags["AutoDrag"] ~= nil then getgenv().Flags["AutoDrag"]:Set(true) end
    end

    if targetGui then
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Auto Drag" then
                local p = v.Parent
                if p then
                    local toggleBtn = p:FindFirstChildOfClass("TextButton") or p:FindFirstChildOfClass("ImageButton")
                    if toggleBtn then clickButton(toggleBtn) end
                end
            end
        end
        
        local combatTabBtn = nil
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Combat" then
                combatTabBtn = v:FindFirstAncestorOfClass("TextButton") or v:FindFirstAncestorOfClass("ImageButton") or v.Parent
                break
            end
        end
        
        if combatTabBtn then
            clickButton(combatTabBtn)
            task.wait(0.2)
        end

        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Kill Aura" then
                local row = v.Parent
                if row then
                    local toggleBtn = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton")
                    if toggleBtn then
                        clickButton(toggleBtn)
                        print("[🎯 ZHUB] Đã đồng bộ bật Auto Drag + Kill Aura!");
                        break
                    end
                end
            end
        end
    end
end

-- Chạy ZHUB
initializeZHub()

-- =========================================================================
-- ⚔️ LUỒNG TỰ ĐỘNG CẦM VŨ KHÍ SONG SONG
-- =========================================================================
task.spawn(function()
    runFile("AutoEquip.lua")
end)

-- =========================================================================
-- 🔄 LUỒNG TỰ ĐỘNG CHẠY CÁC STAGE TUẦN TỰ (SẼ BỊ CẮT NGANG NẾU QUÁ 2 PHÚT)
-- =========================================================================
runFile("Stage1_GetFuel.lua")   
runFile("Stage2_ReturnGen.lua") 
runFile("Stage3_RepairBox.lua") 

-- =========================================================================
-- 🛠️ STAGE 4 VÀ STAGE 5 KHÔNG ĐỘ TRỄ (NẾU CHƯA QUÁ 2 PHÚT THÌ CHẠY TIẾP)
-- =========================================================================

local function runOptimizedStage4()
    if isForcedRejoining then return end
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local localPlayer = game:GetService("Players").LocalPlayer

    local function getPowerBoxPrompt()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if obj.Parent and obj.Parent.Name == "Power Box" then return obj
                elseif string.find(string.lower(obj.ObjectText), "power plant") or string.find(string.lower(obj.ActionText), "repair") then return obj end
            end
        end
        return nil
    end

    local repairStarted = false
    local startTime = os.clock()
    local holdConnection = nil

    local stage4Connection
    stage4Connection = RunService.Heartbeat:Connect(function()
        -- Kiểm tra nếu luồng tổng đếm giờ ra lệnh ép Rejoin thì lập tức hủy kết nối Stage 4
        if isForcedRejoining then
            stage4Connection:Disconnect()
            return
        end

        local prompt = getPowerBoxPrompt()
        if prompt then
            if prompt.RequiresLineOfSight then prompt.RequiresLineOfSight = false end
            if prompt.MaxActivationDistance < 15 then prompt.MaxActivationDistance = 25 end

            if not repairStarted then
                repairStarted = true
                startTime = os.clock()
                
                holdConnection = task.spawn(function()
                    while repairStarted and prompt and prompt.Parent and not isForcedRejoining do
                        if prompt.HoldDuration > 0 then prompt:InputHoldBegin() end
                        fireproximityprompt(prompt)
                        task.wait(0.04) 
                    end
                end)
            end
            
            if repairStarted and (os.clock() - startTime) >= 16 then
                stage4Connection:Disconnect()
            end
        else
            if repairStarted then stage4Connection:Disconnect() end
        end
    end)

    while stage4Connection.Connected do task.wait() end

    repairStarted = false
    if holdConnection then task.cancel(holdConnection) end
    local finalPrompt = getPowerBoxPrompt()
    if finalPrompt then pcall(function() finalPrompt:InputHoldEnd() end) end
end

local function runOptimizedStage5()
    if isForcedRejoining then return end
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

-- Thực thi giai đoạn cuối bình thường nếu chưa bị quá giờ
runOptimizedStage4()
runOptimizedStage5()
