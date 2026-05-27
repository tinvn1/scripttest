-- Chờ trò chơi tải xong
if not game:IsLoaded() then game.Loaded:Wait() end

print("[🚀 STAGE 0] Khởi chạy cho Mobile...");

-- Tải ZHUB
local successLoad, errLoad = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

if not successLoad then warn("Lỗi tải: " .. tostring(errLoad)) return end

task.spawn(function()
    task.wait(5) -- Đợi lâu hơn một chút cho mobile load UI
    
    local UserInputService = game:GetService("UserInputService")
    
    -- Hàm Click tương thích cả PC và Mobile
    local function touchClick(button)
        if not button then return end
        
        -- Thử các sự kiện click thông thường
        pcall(function() button.MouseButton1Click:Fire() end)
        
        -- Kích hoạt sự kiện cảm ứng cho mobile
        if button:IsA("GuiButton") then
            button.Activated:Fire()
        end
        
        -- Nếu executor có hỗ trợ VirtualInputManager
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local pos = button.AbsolutePosition + (button.AbsoluteSize / 2)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
    end

    -- Quét tìm nút và kích hoạt
    local targetGui = game:GetService("CoreGui"):FindFirstChild("ZHUB") or game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ZHUB")
    
    if targetGui then
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") then
                local text = string.lower(v.Text)
                if string.find(text, "drag body") or string.find(text, "kill aura") then
                    -- Tìm nút cha hoặc nút cùng cấp gần nhất
                    local p = v.Parent
                    local toggleBtn = p:FindFirstChildWhichIsA("GuiButton") or p.Parent:FindFirstChildWhichIsA("GuiButton")
                    
                    if toggleBtn then
                        touchClick(toggleBtn)
                        print("[✅] Đã kích hoạt trên mobile: " .. v.Text)
                    end
                end
            end
        end
    end
end)
