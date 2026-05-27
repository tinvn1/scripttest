-- 1. Khởi chạy Script gốc trước
loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()

-- 2. Đợi Hub mở ra rồi tự động tìm và bấm nút Load config
task.spawn(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Chuỗi JSON cấu hình thân thiện Mobile/PC của bạn
    local jsonConfig = [[{"Flags":{"Killaura":true,"KillauraRange":25,"AutoEat":true,"AutoEatThreshold":50,"AutoHeal":true,"AutoHealThreshold":50,"AutoDrag":true,"AutoDragRange":15,"DragPriorityItems":["Gas Mask","Emerald"],"PriorityPickupItems":["Gas Mask","Emerald"],"AntiAFK":true,"FPSBoost":true,"RemoveFog":true,"Fullbright":true,"NoRecoil":true,"NoSpread":true,"AutoReload":true,"SpeedEnabled":false,"SpeedValue":16,"ESPCombat":false,"ChestsESP":false},"Version":"5.5.2","GameId":"sta","ConfigVersion":1,"Script":"ZHUB"}]]
    
    -- Sao chép sẵn vào Clipboard hệ thống đề phòng script yêu cầu đọc clipboard
    if setclipboard then
        setclipboard(jsonConfig)
    end

    print("Đang chờ giao diện ZHUB xuất hiện...")
    
    -- Vòng lặp quét tìm giao diện UIX trên màn hình
    local screenGui = nil
    for i = 1, 30 do -- Đợi tối đa 30 giây
        for _, gui in pairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui:FindFirstChild("Toggled") and gui:FindFirstChild("Background") then
                screenGui = gui
                break
            end
        end
        if screenGui then break end
        task.wait(1)
    end

    if screenGui then
        task.wait(1.5) -- Đợi UI mượt mà ổn định hẳn
        print("Đã tìm thấy giao diện! Tiến hành ép tự động load config...")
        
        pcall(function()
            -- Tìm đến ô nhập "Paste Settings JSON" và điền config vào
            local background = screenGui:FindFirstChild("Background")
            local container = background and background:FindFirstChild("Container")
            local pages = container and container:FindFirstChild("Pages")
            
            -- Quét qua các tab để tìm đúng tab Settings và các nút bấm
            if pages then
                for _, page in pairs(pages:GetChildren()) do
                    -- Tìm ô TextBox dùng để paste JSON
                    local textBox = page:FindFirstChild("TextBox", true) or page:FindFirstChild("Input", true)
                    if textBox and textBox:IsA("TextBox") then
                        textBox.Text = jsonConfig
                        task.wait(0.3)
                    end
                    
                    -- Tìm và kích hoạt nút "Load Pasted Settings"
                    for _, child in pairs(page:GetDescendants()) do
                        if child:IsA("TextLabel") and (child.Text == "Load Pasted Settings" or child.Text:find("Pasted")) then
                            -- Tìm nút bấm bọc bên ngoài chữ này
                            local button = child:FindFirstAncestorOfClass("TextButton") or child.Parent:FindFirstChildOfClass("TextButton") or child
                            
                            -- Giả lập hành động bấm nút
                            if button:IsA("TextButton") then
                                button:Activate()
                            elseif button:IsA("GuiButton") then
                                table.foreach(getconnections(button.MouseButton1Click), function(_, v) v:Fire() end)
                                table.foreach(getconnections(button.MouseButton1Down), function(_, v) v:Fire() end)
                            end
                            print("🚀 Đã tự động kích hoạt nút Load Pasted Settings thành công!")
                            return
                        end
                    end
                end
            end
        end)
    else
        print("Không tìm thấy giao diện ZHUB, vui lòng thử lại.")
    end
end)
