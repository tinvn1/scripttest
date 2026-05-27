if not game:IsLoaded() then game.Loaded:Wait() end

-- Hàm kiểm tra môi trường
local isMobile = (game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled)

print("[🚀] Khởi chạy cho: " .. (isMobile and "Mobile" or "PC"));

-- 1. Tải ZHUB
local successLoad, errLoad = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

if not successLoad then warn("Lỗi tải ZHUB: " .. tostring(errLoad)) return end

-- 2. Logic kích hoạt song song
task.spawn(function()
    task.wait(4) -- Đợi UI khởi tạo xong

    -- CÁCH 1: Sử dụng Flags (Ưu tiên PC và Executor hỗ trợ)
    if getgenv().Flags then
        local targetFlags = {"Auto Drag Body", "Auto Drag", "Kill Aura", "KillAura"}
        for _, flagName in pairs(targetFlags) do
            if getgenv().Flags[flagName] then
                pcall(function() getgenv().Flags[flagName]:Set(true) end)
            end
        end
    end

    -- CÁCH 2: Giả lập tương tác vật lý (Ưu tiên Mobile và dự phòng cho PC)
    local targetGui = game:GetService("CoreGui"):FindFirstChild("ZHUB") or game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ZHUB")
    
    if targetGui then
        local VirtualInputManager = game:GetService("VirtualInputManager")
        
        for _, obj in pairs(targetGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local text = string.lower(obj.Text)
                if string.find(text, "drag") or string.find(text, "kill aura") then
                    local parent = obj.Parent
                    local toggleBtn = parent:FindFirstChildWhichIsA("GuiButton") or parent.Parent:FindFirstChildWhichIsA("GuiButton")
                    
                    if toggleBtn then
                        -- Thực hiện click tùy theo thiết bị
                        if isMobile then
                            -- Dùng VirtualInputManager để mô phỏng chạm màn hình
                            local pos = toggleBtn.AbsolutePosition + (toggleBtn.AbsoluteSize / 2)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                            task.wait(0.1)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                        else
                            -- Dùng events cho PC
                            pcall(function() toggleBtn.MouseButton1Click:Fire() end)
                            pcall(function() toggleBtn.Activated:Fire() end)
                        end
                        print("[✅] Đã kích hoạt: " .. obj.Text)
                    end
                end
            end
        end
    end
end)
