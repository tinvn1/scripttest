-- =========================================================================
-- 🔥 HÀM ĐỊNH VỊ MÁY PHÁT ĐIỆN (CẢI TIẾN)
-- =========================================================================
local function getGenerator()
    local targetNames = {"Generator", "Gen", "MainGen"}
    for _, obj in pairs(Workspace:GetDescendants()) do
        for _, name in ipairs(targetNames) do
            if obj.Name == name then
                -- Ưu tiên chọn Part chính hoặc Part đại diện
                if obj:IsA("BasePart") then return obj end
                if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") end
            end
        end
    end
    return nil
end

-- =========================================================================
-- VÒNG LẶP ĐIỀU KHIỂN CHÍNH CỦA STAGE 2
-- =========================================================================
print("[STAGE 2] Đang khởi động tìm kiếm máy phát điện...");

local char = localPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")

if root then
    local genPart = getGenerator()
    
    if genPart then
        print("[STAGE 2] Đã tìm thấy: " .. genPart:GetFullName())
        
        -- Tính khoảng cách
        local distance = (root.Position - genPart.Position).Magnitude
        
        -- Di chuyển nếu ở xa
        if distance > 6 then -- Tăng nhẹ khoảng cách dừng để tránh lỗi vật lý
            print("[STAGE 2] Khoảng cách là " .. math.floor(distance) .. ". Đang di chuyển...")
            local success = tweenToGenerator(root, genPart)
            if not success then
                warn("[⚠️ STAGE 2] Di chuyển thất bại, đang thử Teleport...")
                root.CFrame = CFrame.new(genPart.Position + Vector3.new(0, 3, 0))
            end
        end
        
        -- Đã đến nơi -> Chạy checkfuel.lua
        print("[🎯 STAGE 2 SUCCESS] Đã đến vị trí máy phát điện. Gọi checkfuel.lua...")
        
        if isfile and isfile("checkfuel.lua") then
            loadfile("checkfuel.lua")()
        elseif _G.RunCheckFuel then
            _G.RunCheckFuel()
        else
            warn("[❌ LỖI] Không tìm thấy file 'checkfuel.lua'!")
            _G.CurrentStage = 1 -- Quay lại stage 1 nếu không gọi được file
        end
        
        return true
    else
        warn("[⚠️ STAGE 2] Không thấy Generator trong Workspace! Quay lại Stage 1...")
        _G.CurrentStage = 1
        return false
    end
else
    warn("[⚠️ STAGE 2] Lỗi nhân vật (HumanoidRootPart not found)!")
    return false
end
