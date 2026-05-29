-- =========================================================================
-- 💎 ULTIMATE SCI-FI FULLSCREEN HUB (GITHUB EXTERNAL IMAGE VERSION)
-- =========================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Đường dẫn link ảnh RAW trực tiếp từ kho lưu trữ GitHub của bạn
local GitHub_Image_URL = "https://raw.githubusercontent.com/tinvn1/scripttest/main/anhnen.jpg"
local Local_File_Name = "tinvn_hub_background.jpg"
local Asset_ID = ""

-- [XỬ LÝ TẢI ẢNH NGOÀI ROBLOX] 
-- Kiểm tra xem Executor của bạn có hỗ trợ tải file internet hay không
local success, err = pcall(function()
    if writefile and readfile and getcustomasset and syn then
        -- Tải dữ liệu ảnh từ GitHub và lưu tạm vào thư mục workspace của Executor
        if not isfile(Local_File_Name) then
            writefile(Local_File_Name, game:HttpGet(GitHub_Image_URL))
        end
        -- Chuyển đổi file vừa tải thành định dạng tài nguyên mà Roblox đọc được
        Asset_ID = getcustomasset(Local_File_Name)
    elseif writefile and readfile and getcustomasset then -- Cho các bản Exploit tiêu chuẩn khác
        if not isfile(Local_File_Name) then
            writefile(Local_File_Name, game:HttpGet(GitHub_Image_URL))
        end
        Asset_ID = getcustomasset(Local_File_Name)
    else
        -- Nếu Executor không hỗ trợ, tự động dùng lại ID dự phòng trên hệ thống Roblox
        Asset_ID = "rbxassetid://16441589139" 
    end
end)

if not success or Asset_ID == "" then
    Asset_ID = "rbxassetid://16441589139" -- ID dự phòng nếu lỗi tải file
end

-- 1. TẠO KHUNG CHÍNH TRÀN MÀN HÌNH (FULLSCREEN HUB)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Gemini_UltimateExternalHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true -- Bỏ qua thanh công cụ của Roblox để tràn viền hoàn toàn
ScreenGui.Parent = PlayerGui

-- Khung nền bao phủ toàn bộ màn hình
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.Position = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

-- 2. HÌNH NỀN FULLSCREEN (Sử dụng asset vừa tải từ GitHub về)
local AnimeBackground = Instance.new("ImageLabel")
AnimeBackground.Size = UDim2.new(1, 0, 1, 0)
AnimeBackground.Position = UDim2.new(0, 0, 0, 0)
AnimeBackground.Image = Asset_ID -- Gán link ảnh ngoài đã chuyển đổi ở đây
AnimeBackground.ScaleType = Enum.ScaleType.Crop -- Tự động co giãn chuẩn tỉ lệ mọi màn hình
AnimeBackground.Parent = MainFrame

-- Lớp phủ tối (Overlay) giúp làm dịu ảnh nền, làm nổi bật các thông số hiển thị
local DarkOverlay = Instance.new("Frame")
DarkOverlay.Size = UDim2.new(1, 0, 1, 0)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
DarkOverlay.BackgroundTransparency = 0.4
DarkOverlay.BorderSizePixel = 0
DarkOverlay.Parent = MainFrame

-- 3. TRUNG TÂM ĐIỀU KHIỂN & THEO DÕI THÔNG SỐ (CENTER PANEL)
local InfoArea = Instance.new("Frame")
InfoArea.Size = UDim2.new(0, 400, 0, 150)
InfoArea.Position = UDim2.new(0.5, -200, 0.75, -75) -- Đặt ở nửa dưới màn hình để không che mặt nhân vật
InfoArea.BackgroundColor3 = Color3.fromRGB(15, 22, 28)
InfoArea.BackgroundTransparency = 0.25 -- Hiệu ứng kính mờ Cyberpunk
InfoArea.BorderSizePixel = 0
InfoArea.Parent = MainFrame

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 12)
InfoCorner.Parent = InfoArea

local InfoStroke = Instance.new("UIStroke")
InfoStroke.Color = Color3.fromRGB(0, 230, 255)
InfoStroke.Thickness = 1.5
InfoStroke.Parent = InfoArea

-- Tiêu đề hệ thống
local SystemTag = Instance.new("TextLabel")
SystemTag.Size = UDim2.new(1, -30, 0, 25)
SystemTag.Position = UDim2.new(0, 20, 0, 15)
SystemTag.Text = "♦ ENDFIELD MONITOR SYSTEM // EXT_IMAGE_MODE"
SystemTag.TextColor3 = Color3.fromRGB(140, 160, 180)
SystemTag.TextSize = 11
SystemTag.Font = Enum.Font.Code
SystemTag.TextXAlignment = Enum.TextXAlignment.Left
SystemTag.BackgroundTransparency = 1
SystemTag.Parent = InfoArea

-- Ô hiển thị lượng Gem số lớn
local GemValueLabel = Instance.new("TextLabel")
GemValueLabel.Size = UDim2.new(1, -30, 0, 50)
GemValueLabel.Position = UDim2.new(0, 20, 0, 40)
GemValueLabel.Text = "💎 Loading..."
GemValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
GemValueLabel.TextSize = 36
GemValueLabel.Font = Enum.Font.GothamBold
GemValueLabel.TextXAlignment = Enum.TextXAlignment.Left
GemValueLabel.BackgroundTransparency = 1
GemValueLabel.Parent = InfoArea

local TextStroke = Instance.new("UIStroke")
TextStroke.Color = Color3.fromRGB(0, 230, 255)
TextStroke.Thickness = 0.5
TextStroke.Transparency = 0.5
TextStroke.Parent = GemValueLabel

-- Thanh trạng thái Neon trang trí
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -40, 0, 3)
StatusBar.Position = UDim2.new(0, 20, 0, 95)
StatusBar.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = InfoArea

local BarCorner = Instance.new("UICorner")
BarCorner.CornerRadius = UDim.new(0, 2)
BarCorner.Parent = StatusBar

-- Dòng chữ trạng thái kết nối
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -30, 0, 20)
StatusText.Position = UDim2.new(0, 20, 0, 105)
StatusText.Text = "STATUS: ACTIVE // OVERLAY_CONNECTED"
StatusText.TextColor3 = Color3.fromRGB(0, 230, 255)
StatusText.TextSize = 10
StatusText.Font = Enum.Font.Code
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.BackgroundTransparency = 1
StatusText.Parent = InfoArea

-- =========================================================================
-- LOGIC KIỂM TRA VÀ ĐỒNG BỘ GEM THEO THỜI GIAN THỰC
-- =========================================================================

local function updateGemDisplay(text)
    GemValueLabel.Text = "💎 " .. tostring(text)
end

task.spawn(function()
    local mainUI = PlayerGui:WaitForChild("MainUI", 15)
    local gemDisplay = mainUI and mainUI:WaitForChild("GemDisplay", 15)
    local gemCountObject = gemDisplay and gemDisplay:WaitForChild("Count", 15)

    while not gemCountObject do
        pcall(function()
            gemCountObject = PlayerGui.MainUI.GemDisplay.Count
        end)
        if gemCountObject then break end
        task.wait(0.5)
    end

    if gemCountObject then
        updateGemDisplay(gemCountObject.Text)
        gemCountObject:GetPropertyChangedSignal("Text"):Connect(function()
            updateGemDisplay(gemCountObject.Text)
        end)
        print("[🚀 SYSTEM] Đã kích hoạt Fullscreen Hub bằng ảnh GitHub thành công!");
    else
        GemValueLabel.Text = "💎 ERROR";
        GemValueLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
    end
end)
