local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local localPlayer = game:GetService("Players").LocalPlayer

-- =========================================================================
-- 🔥 HÀM TÌM CHÍNH XÁC PART "PROMPT" THEO CẤU TRÚC ẢNH
-- =========================================================================
local function getPowerBoxPromptPart()
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- Tìm đúng Model "Power Box" có chứa Part tên là "Prompt"
        if obj:IsA("Model") and obj.Name == "Power Box" then
            local promptPart = obj:FindFirstChild("Prompt")
            if promptPart and promptPart:IsA("BasePart") then
                return promptPart
            end
        end
    end
    return nil
end

print("[🛠️ STAGE 4] Kích hoạt tự động sửa máy theo cấu trúc Explorer mới...")

local repairStarted = false
local startTime = 0
local stage4Connection

stage4Connection = RunService.Heartbeat:Connect(function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        local promptPart = getPowerBoxPromptPart()
        
        if promptPart then
            -- Tính khoảng cách thực tế giữa người chơi và khối "Prompt"
            local distance = (root.Position - promptPart.Position).Magnitude
            
            -- CHỈ TỰ ĐỘNG SỬA KHI LẠI GẦN (Dưới 12 studs cho chính xác)
            if distance <= 12 then
                if not repairStarted then
                    print("[🖱️] Đã đứng cạnh hộp điện! Đang kích hoạt tương tác...")
                    repairStarted = true
                    startTime = os.clock()
                    
                    -- Thực hiện tương tác an toàn tùy thuộc vào Executor của bạn hỗ trợ gì
                    task.spawn(function()
                        while repairStarted and promptPart and promptPart.Parent do
                            -- Cách 1: Nếu game có ClickDetector ẩn trong đó
                            local cd = promptPart:FindFirstChildOfClass("ClickDetector") or promptPart.Parent:FindFirstChildOfClass("ClickDetector")
                            if cd then
                                fireclickdetector(cd)
                            -- Cách 2: Nếu game dùng ProximityPrompt thật nằm trong Part này
                            elseif promptPart:FindFirstChildOfClass("ProximityPrompt") then
                                fireproximityprompt(promptPart:FindFirstChildOfClass("ProximityPrompt"))
                            else
                                -- Cách 3: Giả lập click chuột trực tiếp vào Part (Giải pháp tối ưu cho Custom Prompt)
                                if firetouchinterest then
                                    -- Đôi khi game check Touch (chạm chân vào)
                                    firetouchinterest(root, promptPart, 0)
                                    task.wait()
                                    firetouchinterest(root, promptPart, 1)
                                end
                            end
                            task.wait(0.2) -- Giảm tần suất xuống 0.2s để không bao giờ bị spam nhảy bảng Robux
                        end
                    end)
                end
                
                -- ĐẾM ĐỦ 16 GIÂY -> HOÀN THÀNH STAGE
                if repairStarted and (os.clock() - startTime) >= 16 then
                    print("[🎯 STAGE 4 SUCCESS] Đã sửa máy hoàn tất!")
                    stage4Connection:Disconnect()
                end
            else
                -- Nếu chạy ra xa thì dừng sửa (Tránh bug)
                if repairStarted then
                    print("[⚠️] Bạn đã rời xa hộp điện, tạm dừng tiến trình.")
                    repairStarted = false
                end
            end
        else
            -- Nếu sửa xong và Model/Part biến mất khỏi Map
            if repairStarted then
                print("[🎯 STAGE 4 SUCCESS] Máy phát điện đã biến mất. Thành công!")
                stage4Connection:Disconnect()
            end
        end
    end
end)

-- Đợi luồng chạy ngầm của Stage 4 kết thúc hoàn toàn
while stage4Connection and stage4Connection.Connected do task.wait() end

-- DỌN DẸP SẠCH SẼ
repairStarted = false

-- CHUYỂN GIAO SANG STAGE 5
print("[🚀] Stage 4 hoàn thành gọn gàng. Tiến lên Stage 5...");
_G.CurrentStage = 5
return true
