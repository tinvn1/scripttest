local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local localPlayer = game:GetService("Players").LocalPlayer
local TWEEN_SPEED = 30

-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN (QUÉT TOÀN BỘ MAP)
-- =========================================================================
local function getGenerator()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "Generator" or obj.Name == "Gen" or obj.Name == "MainGen" then
            return obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        end
    end
    return nil
end

-- =========================================================================
-- 🔥 HÀM DI CHUYỂN TWEEN
-- =========================================================================
local function tweenToGenerator(rootPart, genPart)
    if not rootPart or not genPart then return false end
    
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local success, _ = pcall(function()
        path:ComputeAsync(rootPart.Position, genPart.Position)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        for _, waypoint in pairs(path:GetWaypoints()) do
            local expectedCFrame = CFrame.new(waypoint.Position.X, waypoint.Position.Y + 2, waypoint.Position.Z)
            local dist = (rootPart.Position - waypoint.Position).Magnitude
            local tween = TweenService:Create(rootPart, TweenInfo.new(dist / TWEEN_SPEED, Enum.EasingStyle.Linear), {CFrame = expectedCFrame})
            tween:Play()
            tween.Completed:Wait()
        end
        return true
    else
        rootPart.CFrame = CFrame.new(genPart.Position + Vector3.new(0, 2, 0))
        return true
    end
end

-- =========================================================================
-- 🎮 VÒNG LẶP ĐIỀU KHIỂN CHÍNH (ĐÃ ĐƯA SPY 2.5 LÊN ĐẦU)
-- =========================================================================
print("[STAGE 2] Khởi động luồng kiểm tra Stage 2...")

local genPart = getGenerator()
if genPart then
    -- ---------------------------------------------------------------------
    -- 🕵️‍♂️ [BƯỚC 1] KÍCH HOẠT NGAY LẬP TỨC CƠ CHẾ SPY 2.5 TRƯỚC KHI LÀM BẤT CỨ GÌ
    -- ---------------------------------------------------------------------
    local genModel = genPart:IsA("Model") and genPart or genPart.Parent
    local hasVariableChange = false
    
    print("[🕵️‍♂️ SPY 2.5] Đang đứng rình biến số thế giới tại máy phát điện...")
    
    -- Lắng nghe xem thế giới game có nạp thêm hoặc xóa bớt vật thể/linh kiện nào của máy không
    local connAdd = genModel.DescendantAdded:Connect(function(descendant)
        print("[⚡ SPY DETECTED] Thế giới cập nhật biến số mới (Thêm): " .. descendant.Name)
        hasVariableChange = true
    end)
    
    local connRemove = genModel.DescendantRemoving:Connect(function(descendant)
        print("[⚡ SPY DETECTED] Thế giới cập nhật biến số mới (Xóa): " .. descendant.Name)
        hasVariableChange = true
    end)
    
    -- Treo luồng chờ tối đa 4 giây để bắt trọn các cập nhật cấu trúc nhỏ của game
    local startTime = os.clock()
    while (os.clock() - startTime) < 4 do
        if hasVariableChange then break end
        task.wait(0.1)
    end
    
    -- Ngắt kết nối ngay để giải phóng bộ nhớ, tránh rò rỉ và gây lag game
    connAdd:Disconnect()
    connRemove:Disconnect()
    
    -- ---------------------------------------------------------------------
    -- 📊 [BƯỚC 2] XỬ LÝ KẾT QUẢ CHECK SPY
    -- ---------------------------------------------------------------------
    if hasVariableChange then
        -- NẾU CÓ BIẾN SỐ TRUYỀN VỀ -> CHO PHÉP CHẠY TIẾP
        print("[🎯 SPY SUCCESS] Phát hiện máy có biến số đổi cấu trúc! Tiến hành di chuyển...")
        
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root then
            -- Thực hiện di chuyển tới máy phát điện
            tweenToGenerator(root, genPart)
            task.wait(0.2)
            
            -- Bấm nút tương tác kích nổ tiến trình
            local prompt = genPart:FindFirstChildOfClass("ProximityPrompt") or genModel:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                fireproximityprompt(prompt)
            end
            task.wait(0.5)
            
            -- Đẩy Stage lên Stage 3 thành công
            print("[🎯 STAGE 2 DONE] Tương tác hoàn tất! Lên Stage 3.")
            _G.CurrentStage = 3
        end
    else
        -- NẾU MÁY IM LÌM (KHÔNG CÓ BIẾN SỐ) -> PHẠT LẬP TỨC
        warn("[❌ SPY FAILED] Không phát hiện bất kỳ biến số nào! PHẠT: Lùi thẳng về Stage 1.")
        _G.CurrentStage = 1
    end
else
    print("[⚠️] Không tìm thấy máy phát điện trong map... Quay về Stage 1.")
    _G.CurrentStage = 1
end

return true
