-- Chờ trò chơi tải xong xuôi hoàn toàn
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[🚀 STAGE 0] Khởi động luồng ÉP BẬT ĐỒNG THỜI - Không lật trang!");

-- Khởi chạy Menu ZHUB bằng pcall bảo vệ luồng chính
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Notzephyr/UIX/refs/heads/main/Zombie.lua"))()
end)

task.wait(3.5) -- Đợi 3.5 giây để ZHUB nạp và dựng sẵn toàn bộ các thành phần nút bấm ngầm

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Hàm mô phỏng kích hoạt nút bấm sâu, chọc thủng mọi lớp chặn bảo mật của UI Library
local function forceClick(button)
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
-- 🔥 VÒNG LẶP CÀN QUÉT SONG SONG: BẬT CÙNG LÚC 2 NÚT THẦN TỐC
-- =========================================================================
local autoDragActivated = false
local killAuraActivated = false
local maxScanAttempts = 20

for scanRound = 1, maxScanAttempts do
    if autoDragActivated and killAuraActivated then break end
    print(string.format("[🔄 ZHUB PARALLEL] Đang quét ép bật song song đợt %d/%d...", scanRound, maxScanAttempts))

    -- Kích hoạt bằng Flags hệ thống song song (Nếu ZHUB đăng ký biến môi trường toàn cục)
    if getgenv().Flags then
        pcall(function()
            if getgenv().Flags["Auto Drag"] then getgenv().Flags["Auto Drag"]:Set(true) end
            if getgenv().Flags["AutoDrag"] then getgenv().Flags["AutoDrag"]:Set(true) end
            if getgenv().Flags["Kill Aura"] then getgenv().Flags["Kill Aura"]:Set(true) end
            if getgenv().Flags["KillAura"] then getgenv().Flags["KillAura"]:Set(true) end
        end)
    end

    -- Càn quét vật lý toàn bộ khu vực CoreGui và PlayerGui cùng một lúc
    local searchAreas = {CoreGui, PlayerGui}
    for _, area in ipairs(searchAreas) do
        for _, obj in pairs(area:GetDescendants()) do
            if obj:IsA("TextLabel") then
                
                -- 🚚 Kiểm tra và ép kích hoạt mục "Auto Drag"
                if not autoDragActivated and (obj.Text == "Auto Drag" or string.find(obj.Text, "Auto Drag")) then
                    local row = obj.Parent
                    if row then
                        local toggleBtn = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggleBtn then
                            forceClick(toggleBtn)
                            autoDragActivated = true
                            print("[✔️ SUCCESS] Đã ép bật đồng thời: Auto Drag!")
                        end
                    end
                end

                -- ⚔️ Kiểm tra và ép kích hoạt mục "Kill Aura"
                if not killAuraActivated and (obj.Text == "Kill Aura" or string.find(obj.Text, "Kill Aura")) then
                    local row = obj.Parent
                    if row then
                        local toggleBtn = row:FindFirstChildOfClass("TextButton") or row:FindFirstChildOfClass("ImageButton") or row.Parent:FindFirstChildOfClass("TextButton")
                        if toggleBtn then
                            forceClick(toggleBtn)
                            killAuraActivated = true
                            print("[✔️ SUCCESS] Đã ép bật đồng thời: Kill Aura!")
                        end
                    end
                end

            end
        end
    end

    task.wait(0.5) -- Nghỉ nửa giây rồi quét lại nếu có nút chưa nhận lệnh
end

print("[🚀] Stage 0 hoàn tất cấu hình đồng thời cho ZHUB. Chuyển giao luồng sang Stage 1 nhặt Fuel...");
_G.CurrentStage = 1
return true
