-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Khởi động luồng DÀNH RIÊNG ép bật 2 nút ZHUB...");

-- 1. Khởi chạy Menu ZHUB gốc từ tác giả
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

task.wait(3) -- Chờ 3 giây để ZHUB nạp xong toàn bộ cấu trúc UI ngầm vào game

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local PlayerGui = player:WaitForChild("PlayerGui")

-- Hàm click chuột cưỡng bức (Bypass mọi lớp chặn của Executor và UI thư viện)
local function forceClick(btn)
    if not btn then return end
    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
    for _, event in ipairs(events) do
        if btn[event] then
            pcall(function()
                if getconnections then
                    for _, connection in pairs(getconnections(btn[event])) do 
                        connection:Fire() 
                    end
                else
                    btn[event]:Fire()
                end
            end)
        end
    end
end

-- =========================================================================
-- 🔥 VÒNG LẶP THẦN TỐC: QUÉT TOÀN DIỆN ÉP BẬT HOÀN THÀNH MỚI CHO QUA
-- =========================================================================
local autoDragActivated = false
local killAuraActivated = false
local maxAttempts = 30 -- Thử đi thử lại tối đa 30 lần (30 giây)

task.spawn(function()
    for attempt = 1, maxAttempts do
        if autoDragActivated and killAuraActivated then break end
        
        print(string.format("[🔄 ZHUB SCAN] Đang càn quét ép bật nút đợt %d/%d...", attempt, maxAttempts))

        -- Danh sách các vùng chứa UI của Roblox mà script ngoài có thể ẩn náu
        local searchTargets = {CoreGui, PlayerGui}
        
        for _, location in ipairs(searchTargets) do
            for _, v in pairs(location:GetDescendants()) do
                if v:IsA("TextLabel") then
                    
                    -- 🚚 1. TÌM VÀ ÉP BẬT "AUTO DRAG"
                    if not autoDragActivated and string.find(v.Text, "Auto Drag") then
                        -- Lật mở Tab chứa nó trước (Quét các Tab Main/Misc/Drag xung quanh)
                        local p = v.Parent
                        if p then
                            -- Tìm công tắc gạt kế bên nhãn chữ
                            local toggleBtn = p:FindFirstChildOfClass("TextButton") or p:FindFirstChildOfClass("ImageButton") or p.Parent:FindFirstChildOfClass("TextButton")
                            if toggleBtn then
                                -- Thử bật bằng Flags toàn cục song song
                                if getgenv().Flags then
                                    pcall(function()
                                        if getgenv().Flags["Auto Drag"] then getgenv().Flags["Auto Drag"]:Set(true) end
                                        if getgenv().Flags["AutoDrag"] then getgenv().Flags["AutoDrag"]:Set(true) end
                                    end)
                                end
                                
                                -- Ép click vật lý vào nút gạt
                                forceClick(toggleBtn)
                                autoDragActivated = true
                                print("[🎯 STAGE 0 SUCCESS] Đã ép bật thành công nút: Auto Drag!")
                            end
                        end
                    end
                    
                    -- ⚔️ 2. TÌM VÀ ÉP BẬT "KILL AURA"
                    if not killAuraActivated and string.find(v.Text, "Kill Aura") then
                        -- Phát hiện thấy chữ Kill Aura, tiến hành xử lý hàng nút
                        local p = v.Parent
                        if p then
                            -- Tìm công tắc gạt của Kill Aura
                            local toggleBtn = p:FindFirstChildOfClass("TextButton") or p:FindFirstChildOfClass("ImageButton") or p.Parent:FindFirstChildOfClass("TextButton")
                            if toggleBtn then
                                -- Thử bật bằng Flags toàn cục song song
                                if getgenv().Flags then
                                    pcall(function()
                                        if getgenv().Flags["Kill Aura"] then getgenv().Flags["Kill Aura"]:Set(true) end
                                        if getgenv().Flags["KillAura"] then getgenv().Flags["KillAura"]:Set(true) end
                                    end)
                                end
                                
                                -- Ép click vật lý vào nút gạt
                                forceClick(toggleBtn)
                                killAuraActivated = true
                                print("[🎯 STAGE 0 SUCCESS] Đã ép bật thành công nút: Kill Aura!")
                            end
                        end
                    end
                    
                end
            end
        end

        -- Nếu chưa tìm thấy nút, có thể do Tab chưa được bấm mở nên nút bị ẩn (Parent = nil).
        -- Ta sẽ giả lập bấm vào các nút Tab lớn như "Combat", "Main", "Misc", "Drag" để bắt nó hiển thị.
        if not autoDragActivated or not killAuraActivated then
            for _, location in ipairs(searchTargets) do
                for _, v in pairs(location:GetDescendants()) do
                    if v:IsA("TextLabel") and (v.Text == "Combat" or v.Text == "Main" or v.Text == "Misc" or string.find(v.Text, "Drag")) then
                        local tabBtn = v:FindFirstAncestorOfClass("TextButton") or v:FindFirstAncestorOfClass("ImageButton") or v.Parent
                        if tabBtn and tabBtn:IsA("GuiButton") then
                            forceClick(tabBtn)
                        end
                    end
                end
            end
        end

        task.wait(1) -- Đợi 1 giây rồi lặp lại chu kỳ quét cho đến khi bật được cả 2 nút
    end

    print("[🚀] Kết thúc Stage 0. Hệ thống chuyển giao luồng tự động sang Stage 1 nhặt Fuel...");
    _G.CurrentStage = 1
end)

return true
