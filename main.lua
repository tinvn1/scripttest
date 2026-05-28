-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 🕒 Ghi lại mốc thời gian bắt đầu chạy Script (Tính bằng os.clock chính xác cao)
local startTimeGlobal = os.clock()
local isForcedRejoining = false -- Biến trạng thái chặn chạy tiếp khi đang Rejoin

print("[⚡ SYSTEM] Khởi động Main Loader - Đã tách biệt Stage 0 chạy loadstring từ xa!");

local baseUrl = "https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/"

-- =========================================================================
-- ⏱️ LUỒNG ÉP REJOIN KHẨN CẤP ĐÚNG 2 PHÚT (CHẠY SONG SONG)
-- =========================================================================
task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer

    while not isForcedRejoining do
        local elapsed = os.clock() - startTimeGlobal
        
        -- 🔥 Nếu quá mốc 2 phút (120 giây) -> Ép Rejoin server mới lập tức để tránh treo máy
        if elapsed >= 120 then
            isForcedRejoining = true
            print("[⚠️ TIMEOUT] Đã chạm mốc 2 phút khẩn cấp! Đang ép Rejoin...");
            
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
            
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions.ServerInstanceId = game.JobId
            while true do
                pcall(function()
                    TeleportService:TeleportAsync(game.PlaceId, {localPlayer}, teleportOptions)
                end)
                task.wait(1)
            end
            break
        end
        task.wait(0.1)
    end
end)

-- Hàm nạp file từ GitHub có sửa lỗi ký tự hệ thống tự động
local function runFile(fileName)
    if isForcedRejoining then return end

    local success, content = pcall(function() 
        return game:HttpGet(baseUrl .. fileName) 
    end)
    
    if success and content then
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
-- 🛡️ CHẠY STAGE 0 HOÀN HẢO RIÊNG BIỆT QUA LOADSTRING TỪ GITHUB
-- =========================================================================
task.spawn(function()
    -- Tự động gọi file Stage 0 xử lý ZHUB riêng biệt từ xa
    runFile("Stage0_ZHUB.lua") 
end)

-- =========================================================================
-- ⚔️ LUỒNG TỰ ĐỘNG CẦM VŨ KHÍ SONG SONG
-- =========================================================================
task.spawn(function()
    runFile("AutoEquip.lua")
end)
task.spawn(function()
    runFile("join map.lua")
end)

-- =========================================================================
-- 🔄 HỆ THỐNG VẬN HÀNH TUẦN TỰ QUA CÁC STAGE GỐC (CHỐNG LỖI LOGIC)
-- =========================================================================
runFile("Stage1_GetFuel.lua")   
runFile("Stage2_ReturnGen.lua") 
runFile("Stage3_RepairBox.lua") 

-- =========================================================================
-- 🛠️ STAGE 4 VÀ STAGE 5 (XỬ LÝ CUỐI TRẬN ĐỒNG BỘ CHUẨN)
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
        if isForcedRejoining then
            if stage4Connection then stage4Connection:Disconnect() end
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

runOptimizedStage4()
runOptimizedStage5()
