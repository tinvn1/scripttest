-- Chờ trò chơi tải xong xuôi hoàn toàn
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Khởi động luồng SỬA LỖI - Ép lật Tab bật Auto Drag + Kill Aura...");

-- Khởi chạy Menu ZHUB bằng pcall bảo vệ luồng chính
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

task.wait(4) -- Đợi 4 giây để ZHUB nạp xong toàn bộ cấu trúc UI ban đầu

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Hàm mô phỏng click chuột chuẩn sâu (Kích hoạt mọi liên kết ẩn của Executor)
local function safeClick(button)
    if not button then return end
    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
    for _, event in ipairs(events) do
        if button[event] then
            pcall(function()
                if getconnections then
                    for _, connection in pairs(getconnections(button[event])) do
                        connection:Fire()
                    end
                else
                    button[event]:Fire()
                end
            end)
        end
    end
end

-- =========================================================================
-- 🔥 VÒNG LẶP TUẦN TỰ: ÉP MỞ TAB TRƯỚC -> KIỂM TRA BẬT NÚT SAU
-- =========================================================================
local dragActive = false
local auraActive = false
local maxLoops = 20

for currentLoop = 1, maxLoops do
    if dragActive and auraActive then break end
    print(string.format("[🔄 ZHUB] Tiến hành đợt quét kích hoạt thứ %d/%d...", currentLoop, maxLoops))

    local locations = {CoreGui, PlayerGui}

    -- -------------------------------------------------------------------------
    -- 🚚 BƯỚC 1: ÉP MỞ CÁC TAB TIỀM NĂNG (MISC / MAIN / DRAG) ĐỂ TÌM AUTO DRAG
    -- -------------------------------------------------------------------------
    if not dragActive then
        for _, area in ipairs(locations) do
            for _, obj in pairs(area:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "Misc" or obj.Text == "Main" or string.find(obj.Text, "Drag")) then
                    local tabBtn = obj:FindFirstAncestorOfClass("TextButton") or obj:FindFirstAncestorOfClass("ImageButton") or obj.Parent
                    if tabBtn and (tabBtn:IsA("TextButton") or tabBtn:IsA("ImageButton")) then
                        safeClick(tabBtn) -- Bấm lật sang Tab này
                    end
                end
            end
        end
        task.wait(0.5) -- Chờ nửa giây để giao diện lật kịp hiện các nút ẩn bên trong

        -- Bắt đầu quét tìm nút "Auto Drag" sau khi đã lật Tab
        for _, area in ipairs(locations) do
            for _, obj in pairs(area:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "Auto Drag" or string.find(obj.Text, "Auto Drag")) then
                    local row = obj.Parent
                    if row then
                        local toggle = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggle then
                            safeClick(toggle)
                            dragActive = true
                            print("[🎯 SUCCESS] Đã ép bật Auto Drag thành công!")
                            break
                        end
                    end
                end
            end
        end
    end

    task.wait(0.3)

    -- -------------------------------------------------------------------------
    -- ⚔️ BƯỚC 2: ÉP MỞ TAB COMBAT ĐỂ TÌM VÀ BẬT KILL AURA
    -- -------------------------------------------------------------------------
    if not auraActive then
        for _, area in ipairs(locations) do
            for _, obj in pairs(area:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "Combat" or string.find(obj.Text, "Combat")) then
                    local tabBtn = obj:FindFirstAncestorOfClass("TextButton") or obj:FindFirstAncestorOfClass("ImageButton") or obj.Parent
                    if tabBtn and (tabBtn:IsA("TextButton") or tabBtn:IsA("ImageButton")) then
                        safeClick(tabBtn) -- Bấm lật sang Tab Combat
                    end
                end
            end
        end
        task.wait(0.5) -- Chờ nửa giây để giao diện hiển thị các tính năng Combat

        -- Bắt đầu quét tìm nút "Kill Aura" sau khi đã lật sang Tab Combat
        for _, area in ipairs(locations) do
            for _, obj in pairs(area:GetDescendants()) do
                if obj:IsA("TextLabel") and (obj.Text == "Kill Aura" or string.find(obj.Text, "Kill Aura")) then
                    local row = obj.Parent
                    if row then
                        local toggle = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggle then
                            safeClick(toggle)
                            auraActive = true
                            print("[🎯 SUCCESS] Đã ép bật Kill Aura thành công!")
                            break
                        end
                    end
                end
            end
        end
    end

    -- 🛑 Kích hoạt song song bằng Flags của Hub (Nếu thư viện UIX có đăng ký biến môi trường)
    if getgenv().Flags then
        pcall(function()
            if getgenv().Flags["Auto Drag"] then getgenv().Flags["Auto Drag"]:Set(true) end
            if getgenv().Flags["AutoDrag"] then getgenv().Flags["AutoDrag"]:Set(true) end
            if getgenv().Flags["Kill Aura"] then getgenv().Flags["Kill Aura"]:Set(true) end
            if getgenv().Flags["KillAura"] then getgenv().Flags["KillAura"]:Set(true) end
        end)
    end

    task.wait(0.5) -- Đợi trước khi lặp lại vòng quét tiếp theo nếu có nút bị trượt
end

print("[🚀] Stage 0 kết thúc mỹ mãn. Hệ thống tự động kích hoạt luồng Stage 1 đi nhặt xăng...");
_G.CurrentStage = 1
return true
