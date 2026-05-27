-- Chờ game tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 1. Khởi chạy Menu ZHUB từ link Github của tác giả
loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()

-- 2. Đợi giao diện Menu xuất hiện trong CoreGui hoặc PlayerGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local targetGui = nil

-- Vòng lặp tìm kiếm UI của ZHUB
for i = 1, 20 do
    targetGui = game:GetService("CoreGui"):FindFirstChild("ZHUB") or player.PlayerGui:FindFirstChild("ZHUB") or game:GetService("CoreGui"):FindFirstChildOfClass("ScreenGui")
    if targetGui then break end
    task.wait(0.5)
end

-- 3. Tự động tìm cấu hình và kích hoạt "Auto Drag" & "Kill Aura"
task.spawn(function()
    task.wait(2.0) -- Chờ UI khởi tạo hoàn chỉnh các hàng nút
    
    ---------------------------------------------------------
    -- CÁCH 1: Kích hoạt thông qua hệ thống Flags cấu hình (Tối ưu nhất)
    ---------------------------------------------------------
    if getgenv().Flags then
        -- Kích hoạt Auto Drag
        if getgenv().Flags["Auto Drag"] ~= nil then
            getgenv().Flags["Auto Drag"]:Set(true)
        elseif getgenv().Flags["AutoDrag"] ~= nil then
            getgenv().Flags["AutoDrag"]:Set(true)
        end
        
        -- Kích hoạt Kill Aura
        if getgenv().Flags["Kill Aura"] ~= nil then
            getgenv().Flags["Kill Aura"]:Set(true)
        elseif getgenv().Flags["KillAura"] ~= nil then
            getgenv().Flags["KillAura"]:Set(true)
        end
    end
    
    ---------------------------------------------------------
    -- CÁCH 2: Phương án dự phòng (Quét và giả lập Click vào nút Toggle)
    ---------------------------------------------------------
    if targetGui then
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") then
                -- Kiểm tra nếu là nút "Auto Drag" hoặc "Kill Aura"
                if v.Text == "Auto Drag" or v.Text == "Kill Aura" then
                    local p = v.Parent
                    if p then
                        -- Tìm nút gạt (Toggle) nằm cạnh dòng chữ
                        local toggleBtn = p:FindFirstChildOfClass("TextButton") 
                                       or p:FindFirstChildOfClass("ImageButton") 
                                       or p.Parent:FindFirstChildOfClass("TextButton")
                        
                        if toggleBtn then
                            -- Giả lập bấm nút kích hoạt
                            local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
                            for _, event in ipairs(events) do
                                if toggleBtn[event] then
                                    for _, connection in pairs(getconnections(toggleBtn[event])) do
                                        connection:Fire()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
