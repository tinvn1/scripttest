-- =========================================================================
-- 🚀 DISCORD WEBHOOK LOG INDEPENDENT & RUN MAIN SCRIPT
-- =========================================================================

-- 1. TỰ ĐỘNG KÍCH HOẠT SCRIPT CHÍNH TRÊN GITHUB TRƯỚC ĐỂ GAME KHÔNG BỊ TRỄ
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/main.lua"))()
    end)
end)

-- 2. ĐỢI GAME VÀ UI TẢI XONG RỒI MỚI GỬI WEBHOOK
if _G.Customer_Webhook and _G.Customer_Webhook ~= "" and _G.Customer_Webhook ~= "DÁN_URL_WEBHOOK_DISCORD_CỦA_KHÁCH_HÀNG_VÀO_ĐÂY" then
    local request = http_request or request or syn.request
    if request then
        task.spawn(function()
            -- Vòng lặp đợi đến khi tìm thấy Player và PlayerGui thực sự trong game
            local players = game:GetService("Players")
            local localPlayer = players.LocalPlayer
            while not localPlayer do
                task.wait(0.5)
                localPlayer = players.LocalPlayer
            end
            
            local playerGui = localPlayer:WaitForChild("PlayerGui", 20)
            if not playerGui then return end

            -- Đợi hẳn giao diện MainUI của game xuất hiện (Tối đa 20 giây)
            local mainUI = playerGui:WaitForChild("MainUI", 20)
            local gemCount = nil
            
            -- Quét tìm đối tượng chứa số Gem thực tế
            if mainUI then
                gemCount = mainUI:FindFirstChild("GemDisplay") and mainUI.GemDisplay:FindFirstChild("Count")
                -- Vòng lặp quét dự phòng nếu UI tải chậm
                local timeout = 0
                while not gemCount and timeout < 10 do
                    pcall(function()
                        gemCount = playerGui.MainUI.GemDisplay.Count
                    end)
                    if gemCount then break end
                    task.wait(0.5)
                    timeout = timeout + 0.5
                end
            end

            -- Lấy giá trị Gem
            local currentGem = "Không tìm thấy UI"
            if gemCount then
                currentGem = gemCount.Text
            end

            -- Đóng gói dữ liệu gửi lên Discord
            local payload = {
                ["embeds"] = {{
                    ["title"] = "💎 THÔNG BÁO SỐ LƯỢNG GEM",
                    ["color"] = 65430, -- Màu xanh neon
                    ["fields"] = {
                        {
                            ["name"] = "👤 Tên nhân vật:",
                            ["value"] = "`" .. localPlayer.Name .. "`",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "💎 Số lượng Gem hiện tại:",
                            ["value"] = "**" .. tostring(currentGem) .. "**",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🎮 Game ID:",
                            ["value"] = "`" .. tostring(game.PlaceId) .. "`",
                            ["inline"] = true
                        }
                    },
                    ["timestamp"] = DateTime.now():ToIsoDate()
                }}
            }

            -- Gửi dữ liệu đi
            pcall(function()
                request({
                    Url = _G.Customer_Webhook,
                    Method = "POST",
                    Headers = {["content-type"] = "application/json"},
                    Body = game:GetService("HttpService"):JSONEncode(payload)
                })
                print("[🚀 SYSTEM] Webhook gửi dữ liệu thành công!")
            end)
        end)
    end
end
