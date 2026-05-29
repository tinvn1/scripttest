-- =========================================================================
-- 🚀 ĐOẠN GỬI WEBHOOK TỰ ĐỘNG KHÔNG LÀM LOẠN UI
-- =========================================================================
if _G.Customer_Webhook and _G.Customer_Webhook ~= "" then
    local request = http_request or request or syn.request
    if request then
        task.spawn(function()
            pcall(function()
                -- Lấy số gem hiện tại từ UI đang hiển thị trên Hub của bạn
                local currentGem = GemValueLabel.Text or "0"
                
                local payload = {
                    ["embeds"] = {{
                        ["title"] = "💎 THÔNG BÁO SỐ LƯỢNG GEM",
                        ["color"] = 65430,
                        ["fields"] = {
                            {
                                ["name"] = "👤 Tên nhân vật:",
                                ["value"] = "`" .. LocalPlayer.Name .. "`",
                                ["inline"] = true
                            },
                            {
                                ["name"] = "💎 Thông số hiện tại:",
                                ["value"] = "**" .. tostring(currentGem) .. "**",
                                ["inline"] = true
                            }
                        },
                        ["timestamp"] = DateTime.now():ToIsoDate()
                    }}
                }

                request({
                    Url = _G.Customer_Webhook,
                    Method = "POST",
                    Headers = {["content-type"] = "application/json"},
                    Body = game:GetService("HttpService"):JSONEncode(payload)
                })
            end)
        end)
    end
end
