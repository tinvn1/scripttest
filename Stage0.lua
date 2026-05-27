-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Đang tải Menu ZHUB phụ trợ từ Github...")

-- 1. Khởi chạy Menu ZHUB từ đường dẫn hệ thống (Bọc pcall độc lập hoàn toàn)
local successLoad, errLoad = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

if not successLoad then
    warn("[⚠️ STAGE 0] Không thể tải ZHUB từ Github: " .. tostring(errLoad))
end

-- 2. Đợi giao diện Menu xuất hiện trong CoreGui hoặc PlayerGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local targetGui = nil

-- Vòng lặp tìm kiếm UI của ZHUB (Tối đa 10 giây để tránh treo luồng)
for i = 1, 20 do
    targetGui = game:GetService("CoreGui"):FindFirstChild("ZHUB") or player.PlayerGui:FindFirstChild("ZHUB") or game:GetService("CoreGui"):FindFirstChildOfClass("ScreenGui")
    if targetGui then break end
    task.wait(0.5)
end

-- Hàm hỗ trợ mô phỏng click chuột nhanh tần suất cao (Bọc lót getconnections)
local function clickButton(btn)
    if btn then
        local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
        for _, event in ipairs(events) do
            if btn[event] then
                if getconnections then
                    local fired = false
                    for _, connection in pairs(getconnections(btn[event])) do
                        connection:Fire()
                        fired = true
                    end
                    if not fired then btn[event]:Fire() end
                else
                    btn[event]:Fire()
                end
            end
        end
    end
end

-- 3. Tự động thiết lập cấu hình và kích hoạt "Auto Drag" + "Combat (Kill Aura)"
local configSuccess = pcall(function()
    task.wait(2.5) -- Chờ UI khởi tạo hoàn chỉnh cấu trúc các hàng nút ban đầu
    
    if targetGui then
        ---------------------------------------------------------------------------
        -- 🚚 PHẦN 1: BẤM TAB DRAG & KÍCH HOẠT AUTO DRAG
        ---------------------------------------------------------------------------
        -- Bước A: Tìm và bấm vào Tab chứa chữ "Drag" hoặc "Auto Drag" ở thanh Menu bên cạnh
        local dragTabBtn = nil
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and (string.find(v.Text, "Drag") or string.find(v.Text, "Main") or string.find(v.Text, "Misc")) then
                dragTabBtn = v:FindFirstAncestorOfClass("TextButton") or v:FindFirstAncestorOfClass("ImageButton") or v.Parent
                break
            end
        end
        
        if dragTabBtn then
            clickButton(dragTabBtn)
            task.wait(0.4) -- Chờ lật giao diện hiển thị các nút gạt Auto Drag
        end

        -- Bước B: Ưu tiên dùng Flags kích hoạt ngầm
        if getgenv().Flags then
            if getgenv().Flags["Auto Drag"] ~= nil then getgenv().Flags["Auto Drag"]:Set(true)
            elseif getgenv().Flags["AutoDrag"] ~= nil then getgenv().Flags["AutoDrag"]:Set(true) end
        end
        
        -- Bước C: Quét UI vật lý để gạt công tắc Auto Drag lên On
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Auto Drag" then
                local p = v.Parent
                if p then
                    local toggleBtn = p:FindFirstChildOfClass("TextButton") or p:FindFirstChildOfClass("ImageButton") or p.Parent:FindFirstChildOfClass("TextButton")
                    if toggleBtn then 
                        clickButton(toggleBtn)
                        print("[✔️ ZHUB] Đã click kích hoạt Auto Drag thành công!")
                        break
                    end
                end
            end
        end
        
        task.wait(0.3) -- Nghỉ một nhịp trước khi đổi Tab tiếp theo

        ---------------------------------------------------------------------------
        -- ⚔️ PHẦN 2: BẤM TAB COMBAT & KÍCH HOẠT KILL AURA
        ---------------------------------------------------------------------------
        -- Bước A: Tìm và di chuyển lật sang tab "Combat" ở bảng điều khiển
        local combatTabBtn = nil
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Combat" then
                combatTabBtn = v:FindFirstAncestorOfClass("TextButton") or v:FindFirstAncestorOfClass("ImageButton") or v.Parent
                break
            end
        end
        
        if combatTabBtn then
            clickButton(combatTabBtn)
            task.wait(0.4) -- Chờ menu kết xuất xong các tính năng chiến đấu bên trong tab Combat
        end

        -- Bước B: Ưu tiên bật bằng Flags hệ thống
        if getgenv().Flags then
            if getgenv().Flags["Kill Aura"] ~= nil then getgenv().Flags["Kill Aura"]:Set(true)
            elseif getgenv().Flags["KillAura"] ~= nil then getgenv().Flags["KillAura"]:Set(true) end
        end

        -- Bước C: Định vị hàng chức năng "Kill Aura" và kích hoạt công tắc gạt
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Kill Aura" then
                local row = v.Parent
                if row then
                    local toggleBtn = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                    if toggleBtn then
                        clickButton(toggleBtn)
                        print("[✔️ ZHUB] Đã click kích hoạt Kill Aura thành công!")
                        break
                    end
                end
            end
        end
    end
end)

if not configSuccess then
    warn("[⚠️ STAGE 0] Luồng ZHUB có lỗi phát sinh nhưng đã được cô lập an toàn để treo game tiếp.")
end

task.wait(0.3)

-- 🔥 CHUYỂN GIAO LUỒNG AN TOÀN SANG STAGE 1 (NHẶT FUEL)
print("[🚀] Stage 0 (ZHUB) hoàn tất thiết lập nút. Bắt đầu chuyển tuần tự sang Stage 1 nhặt Fuel...");
_G.CurrentStage = 1
return true
