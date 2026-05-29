-- =========================================================================
-- 🚀 DISCORD WEBHOOK LOG INDEPENDENT (WEBHOOK.LUA)
-- =========================================================================
local request = http_request or request or syn.request
if request then
    task.spawn(function()
        local players = game:GetService("Players")
        local localPlayer = players.LocalPlayer
        
        while not localPlayer do
            task.wait(0.5)
            localPlayer = players.LocalPlayer
        end
        
        local playerGui = localPlayer:WaitForChild("PlayerGui", 20)
        if not playerGui then return end

        local mainUI = playerGui:WaitForChild("MainUI", 20)
        local gemCount = nil
        
        if mainUI then
            gemCount = mainUI:FindFirstChild("GemDisplay") and mainUI.GemDisplay:FindFirstChild("Count")
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

        local currentGem = "0"
        if gemCount then
            currentGem = gemCount.Text
        end

        local payload = {
            ["embeds"] = {{
                ["title"] = "💎 THÔNG BÁO SỐ LƯỢNG GEM",
                ["color"] = 65430,
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

        pcall(function()
            request({
                Url = _G.Customer_Webhook,
                Method = "POST",
                Headers = {["content-type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(payload)
            })
            print("[🚀 SYSTEM] Webhook độc lập đã tự kêu thành công!");
        end)
    end)
end
