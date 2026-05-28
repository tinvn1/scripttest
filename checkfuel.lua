-- ====================================================================
-- BƯỚC ĐỆM: CHECK FUEL (CHẠY SAU STAGE 2 -> ĐỢI CƠ CHẾ HÒM -> CHUYỂN STAGE 3)
-- ====================================================================

local baseUrl = "https://raw.githubusercontent.com/tinvn1/scripttest/refs/heads/main/"
local hasTriggered = false
local signalConnection = nil

-- Hàm xử lý chuyển tiếp sang Stage 3 từ xa via GitHub
local function loadStage3()
	if hasTriggered then return end
	hasTriggered = true -- Khóa chặn vĩnh viễn, tránh trùng lặp luồng chạy
	
	print("🚨 [CHECK FUEL SUCCESS] Tìm thấy tín hiệu CrateOpened! Đang dọn dẹp bộ nhớ...");
	
	-- 1. Ngắt cổng lắng nghe ngay lập tức để tối ưu RAM cho Mobile/PC
	if signalConnection then 
		signalConnection:Disconnect() 
		signalConnection = nil
	end

	-- 2. Xóa UI thông báo trung gian (nếu có)
	local player = game:GetService("Players").LocalPlayer
	local ui = player.PlayerGui:FindFirstChild("CheckFuelUI")
	if ui then ui:Destroy() end

	-- 3. Tiến hành kích hoạt nạp Stage 3 vĩnh viễn từ GitHub
	print("📡 [LOAD] Đang tải Stage3_RepairBox.lua...");
	task.spawn(function()
		local success, err = pcall(function()
			loadstring(game:HttpGet(baseUrl .. "Stage3_RepairBox.lua"))()
		end)
		if not success then
			warn("⚠️ Lỗi tải Stage 3 từ GitHub: " .. tostring(err))
		end
	end)
end

-- Hàm tạo thông báo trạng thái nhỏ gọn trên màn hình
local function showStatusNotify(text, color)
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then return end

	local screenGui = playerGui:FindFirstChild("CheckFuelUI") or Instance.new("ScreenGui")
	screenGui.Name = "CheckFuelUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	local frame = screenGui:FindFirstChild("Frame") or Instance.new("Frame")
	frame.Size = UDim2.new(0, 240, 0, 40)
	frame.Position = UDim2.new(0.5, -120, 0.05, 0) -- Nằm gọn gàng phía trên cùng màn hình
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BorderSizePixel = 1
	frame.BorderColor3 = color
	frame.Parent = screenGui
	
	local label = frame:FindFirstChild("TextLabel") or Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.SourceSansBold
	label.BackgroundTransparency = 1
	label.Parent = frame
end

-- BẮT ĐẦU KÍCH HOẠT TIẾN TRÌNH THEO DÕI ĐA NỀN TẢNG
local rawmetatable = getrawmetatable or korruptmetatable or (debug and debug.getmetatable)

if rawmetatable and setreadonly and newcclosure then
	-- Phù hợp với Executor (PC / Mobile) - Không gây giọt fps
	local mt = rawmetatable(game)
	local oldNamecall = mt.__namecall
	
	setreadonly(mt, false)
	mt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		
		if not hasTriggered and self and tostring(self) == "CrateOpened" then
			task.spawn(loadStage3)
			
			-- Tự gỡ bỏ Hook Namecall ngay lập tức (Bypass lag hoàn toàn)
			setreadonly(mt, false)
			mt.__namecall = oldNamecall
			setreadonly(mt, true)
		end
		
		return oldNamecall(self, ...)
	end)
	setreadonly(mt, true)
	showStatusNotify("⛽ [CHECK FUEL]: Đang đợi mở hòm...", Color3.fromRGB(0, 170, 255))
else
	-- Phù hợp với LocalScript chạy Studio thuần (Chỉ quét trong thư mục hẹp Workspace.Map)
	local mapFolder = workspace:WaitForChild("Map", 10)
	if mapFolder then
		local function targetScanner(desc)
			if desc.Name == "CrateOpened" and not hasTriggered then
				local tempConn
				tempConn = desc.Changed:Connect(function()
					if not hasTriggered then
						tempConn:Disconnect()
						loadStage3()
					end
				end)
			end
		end

		-- Quét nhanh
		for _, desc in ipairs(mapFolder:GetDescendants()) do
			targetScanner(desc)
			if hasTriggered then break end
		end
		
		-- Đón đầu nếu hòm load trễ
		if not hasTriggered then
			signalConnection = mapFolder.DescendantAdded:Connect(function(desc)
				targetScanner(desc)
			end)
		end
		showStatusNotify("⛽ [CHECK FUEL]: Đang quét dữ liệu Map...", Color3.fromRGB(0, 255, 100))
	end
end
