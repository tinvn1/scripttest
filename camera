local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- CẤU HÌNH CAMERA (Khóa góc nhìn song song)
local CAMERA_DISTANCE = 10 -- Khoảng cách từ sau lưng đến nhân vật
local CAMERA_HEIGHT = 3.5    -- Chiều cao của camera so với nhân vật

-- Đặt chế độ camera thành Scriptable để tự điều khiển bằng code
camera.CameraType = Enum.CameraType.Scriptable

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if rootPart and humanoid and humanoid.Health > 0 then
		camera.CameraType = Enum.CameraType.Scriptable
		
		-- Lấy vị trí và hướng nhìn hiện tại của nhân vật
		local rootPos = rootPart.Position
		local rootLookVector = rootPart.CFrame.LookVector
		
		-- TÍNH TOÁN VỊ TRÍ SONG SONG TUYỆT ĐỐI:
		-- Ép vị trí camera dịch về sau lưng dựa trên góc xoay thực tế của nhân vật mà không dùng Lerp trễ
		local targetPos = rootPos - (rootLookVector * CAMERA_DISTANCE) + Vector3.new(0, CAMERA_HEIGHT, 0)
		
		-- Cập nhật CFrame trực tiếp giúp camera di chuyển đồng bộ, không bị khựng hay đuổi theo sau
		camera.CFrame = CFrame.lookAt(targetPos, rootPos + Vector3.new(0, 1.5, 0))
	else
		-- Nếu nhân vật chưa load xong hoặc chết, trả về camera mặc định của game
		camera.CameraType = Enum.CameraType.Custom
	end
end)
