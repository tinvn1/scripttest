-- Chờ trò chơi tải xong xuôi
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Đang tải Menu ZHUB phụ trợ từ Github...")

-- 1. Khởi chạy Menu ZHUB từ đường dẫn hệ thống
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

-- 3. Tự động thiết lập cấu hình và kích hoạt "Auto Drag" + "Combat (Kill Aura)"
local configSuccess = pcall(function()
    task.wait(1.5) -- Chờ UI khởi tạo hoàn chỉnh cấu trúc các hàng nút
    
    ---------------------------------------------------------------------------
    -- KÍCH HOẠT AUTO DRAG (Sử dụng Flags hệ thống)
    ---------------------------------------------------------------------------
    if getgenv().Flags then
        if getgenv().Flags["Auto Drag"] ~= nil then
            getgenv().Flags["Auto Drag"]:Set(true)
        elseif getgenv().Flags["AutoDrag"] ~= nil then
            getgenv().Flags["AutoDrag"]:Set(true)
        end
    end
    
    -- Hàm hỗ trợ mô phỏng click chuột nhanh tần suất cao
    local function clickButton(btn)
        if btn then
            local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
            for _, event in ipairs(events) do
                if btn[event] then
                    if getconnections then
                        for _, connection in pairs(getconnections(btn[event])) do
                            connection:Fire()
                        end
                    else
                        btn[event]:Fire()
                    end
                end
            end
        end
    end

    if targetGui then
        -- Cách xử lý dự phòng cho Auto Drag nếu Flags không hoạt động
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Auto Drag" then
                local p = v.Parent
                if p then
                    local toggleBtn = p:FindFirstChildOfClass("TextButton") or p:FindFirstChildOfClass("ImageButton")
                    if toggleBtn then clickButton(toggleBtn) end
                end
            end
        end
        
        ---------------------------------------------------------------------------
        -- TỰ ĐỘNG MỞ TAB COMBAT & BẬT KILL AURA
        ---------------------------------------------------------------------------
        -- Bước A: Tìm và di chuyển vào tab "Combat" ở bảng điều khiển bên trái
        local combatTabBtn = nil
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Combat" then
                combatTabBtn = v:FindFirstAncestorOfClass("TextButton") or v:FindFirstAncestorOfClass("ImageButton") or v.Parent
                break
            end
        end
        
        if combatTabBtn then
            clickButton(combatTabBtn)
            task.wait(0.5) -- Nghỉ một nhịp nhỏ để menu kết xuất xong giao diện Combat
        end

        -- Bước B: Định vị hàng chức năng "Kill Aura" và kích hoạt công tắc gạt
        for _, v in pairs(targetGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == "Kill Aura" then
                local row = v.Parent
                if row then
                    local toggleBtn = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton")
                    if toggleBtn then
                        clickButton(toggleBtn)
                        print("[🎯 ZHUB CONFIG] Đã kích hoạt Kill Aura thành công!")
                        break
                    end
                end
            end
        end
    end
end)

if not configSuccess then
    warn("[⚠️ STAGE 0] Gặp lỗi trong quá trình cấu hình thiết lập nút bấm của ZHUB.")
end

task.wait(0.5)

-- 🔥 CHUYỂN GIAO LUỒNG AN TOÀN SANG STAGE 1 (NHẶT FUEL)
print("[🚀] Stage 0 (ZHUB) kết thúc gọn gàng. Tiến hành khởi chạy Stage 1 nhặt Fuel...");
_G.CurrentStage = 1
return true
