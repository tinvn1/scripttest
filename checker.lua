-- =========================================================================
-- 🍊 ORANGE STATS CHECKER - ĐOẠN MẠCH RIÊNG BIỆT (CÓ CẬP NHẬT STATUS MAIN)
-- =========================================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Xóa Gui cũ nếu có trùng lặp
if playerGui:FindFirstChild("OrangeCheckerGui") then playerGui.OrangeCheckerGui:Destroy() end
if Lighting:FindFirstChild("OrangeCheckerBlur") then Lighting.OrangeCheckerBlur:Destroy() end

-- 1. Khởi tạo Giao diện (Mờ nền + Khung Cam)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OrangeCheckerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Background = Instance.new("Frame")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Background.BackgroundTransparency = 1
Background.BorderSizePixel = 0
Background.Parent = ScreenGui

local Blur = Instance.new("BlurEffect")
Blur.Name = "OrangeCheckerBlur"
Blur.Size = 0
Blur.Parent = Lighting

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 120, 0)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "Orange Stats Checker"
Title.TextColor3 = Color3.fromRGB(255, 120, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0.85, 0, 0, 1)
Divider.Position = UDim2.new(0.075, 0, 0, 45)
Divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -40, 1, -65)
Content.Position = UDim2.new(0, 20, 0, 55)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- 2. Đổ dữ liệu tĩnh lên bảng (Giống trong ảnh của bạn)
local function addStatLabel(text, posY, isHeader)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 23)
    label.Position = UDim2.new(0, 0, 0, posY)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = isHeader and Enum.Font.GothamBold or Enum.Font.GothamMedium
    label.TextSize = isHeader and 14 or 13
    label.TextColor3 = isHeader and Color3.fromRGB(255, 120, 0) or Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Content
    return label
end

addStatLabel("Account Stats", 0, true)
addStatLabel("Level: 2601   Third Sea : ✅", 25)
addStatLabel("Race: Fishman", 45)
addStatLabel("Beli: 347.5K", 65)
addStatLabel("Frag: 6632", 85)

-- =========================================================================
-- 🛠️ KHU VỰC ĐỘNG: THEO DÕI TRẠNG THÁI SCRIPT MAIN (SCRIPT STATUS)
-- =========================================================================
local StatusHeader = addStatLabel("Script Status", 115, true)
local MainStatusLabel = addStatLabel("Đang đợi Script Main kết nối...", 140)
MainStatusLabel.TextColor3 = Color3.fromRGB(255, 235, 59) -- Chữ màu vàng cảnh báo ban đầu

local TimerLabel = addStatLabel("Thời gian chạy: 0s | Đếm ngược Rejoin: 120s", 160)
TimerLabel.TextColor3 = Color3.fromRGB(170, 170, 170)

-- Chấm đỏ item phía dưới cùng
local function addStatusItem(text, posX, posY)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 140, 0, 25)
    container.Position = UDim2.new(0, posX, 0, posY)
    container.BackgroundTransparency = 1
    container.Parent = Content
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 0, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(255, 45, 45)
    dot.BorderSizePixel = 0
    dot.Parent = container
    local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(1,0) dc.Parent = dot

    local il = Instance.new("TextLabel")
    il.Size = UDim2.new(1, -15, 1, 0)
    il.Position = UDim2.new(0, 15, 0, 0)
    il.BackgroundTransparency = 1
    il.Text = text
    il.TextColor3 = Color3.fromRGB(200, 200, 200)
    il.Font = Enum.Font.GothamMedium
    il.TextSize = 12
    il.TextXAlignment = Enum.TextXAlignment.Left
    il.Parent = container
end

addStatusItem("GodHuman", 0, 200)
addStatusItem("Skull Guitar", 0, 230)
addStatusItem("Curse Dual Katana", 150, 200)
addStatusItem("Mirror Fractal", 150, 230)
addStatusItem("Valkyrie Helm", 310, 200)
addStatusItem("Pull Lever", 310, 230)

-- Hiệu ứng mở bảng mượt
local tInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
TweenService:Create(Background, tInfo, {BackgroundTransparency = 0.55}):Play()
TweenService:Create(Blur, tInfo, {Size = 18}):Play()
TweenService:Create(MainFrame, tInfo, { Size = UDim2.new(0, 500, 0, 360), Position = UDim2.new(0.5, -250, 0.5, -180) }):Play()

-- 🔄 VÒNG LẶP LIÊN TỤC CẬP NHẬT TRẠNG THÁI TỪ SCRIPT MAIN
task.spawn(function()
    while true do
        -- Lấy dữ liệu từ biến toàn cục _G được truyền từ script main sang
        if _G.MainScriptStatus then
            MainStatusLabel.Text = "Trạng thái: " .. tostring(_G.MainScriptStatus)
            MainStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Đổi sang màu xanh khi hoạt động ổn
        end
        
        if _G.MainScriptTimeElapsed then
            local elapsed = math.floor(_G.MainScriptTimeElapsed)
            local timeLeft = math.max(0, 120 - elapsed)
            TimerLabel.Text = string.format("Thời gian chạy: %ds | Đếm ngược Rejoin: %ds", elapsed, timeLeft)
            
            if timeLeft <= 10 then
                TimerLabel.TextColor3 = Color3.fromRGB(255, 75, 75) -- Chuyển đỏ nếu sắp bị ép Rejoin
            end
        end
        task.wait(0.2) -- Cập nhật mượt mà 5 lần/giây
    end
end)
