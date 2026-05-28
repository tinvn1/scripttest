local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local jumpCount = 0
local stage5Activated = false -- Biến cờ chặn việc kích hoạt trùng lặp

-- Link base dẫn tới repo của bạn (đồng bộ với main.lua)
local baseUrl = "https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/"

local function onCharacterAdded(character)
    -- Đợi cho Humanoid tải xong hoàn toàn
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end
    
    -- FIX LỖI CHÍNH TẢ: đổi "humanid" thành "humanoid" để tránh crash script
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Jumping then
            jumpCount = jumpCount + 1
            
            -- Thông báo số lần nhảy hiện tại
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Jump Counter",
                Text = "Bạn đã nhảy: " .. tostring(jumpCount) .. "/30 lần!",
                Duration = 1.5
            })
            
            -- Kiểm tra nếu nhảy từ đủ 25 lần trở lên và Stage 5 chưa từng được bật
            if jumpCount >= 30 and not stage5Activated then
                stage5Activated = true
                
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "SYSTEM",
                    Text = "Đã đủ 25 lần nhảy! Đang kích hoạt Stage 5...",
                    Duration = 3
                })
                
                -- Thực thi Stage5.lua từ xa qua loadstring
                task.spawn(function()
                    local success, err = pcall(function()
                        return loadstring(game:HttpGet(baseUrl .. "Stage5.lua"))()
                    end)
                    
                    if not success then
                        warn("[ERROR] Không thể tải Stage5: " .. tostring(err))
                        -- Nếu lỗi, reset cờ để có thể thử lại ở lần nhảy tiếp theo
                        stage5Activated = false 
                    end
                end)
            end
        end
    end)
end

-- Khởi chạy kiểm tra nhân vật hiện tại và các lần hồi sinh sau
if localPlayer.Character then
    task.spawn(onCharacterAdded, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
